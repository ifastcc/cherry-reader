import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_db.dart';
import '../drift/app_database.dart';

enum ServerSyncMode {
  pullOnly('pull_only', '仅拉取'),
  autoSafe('auto_safe', '双向自动（安全）'),
  autoFull('auto_full', '双向自动（冲突自动处理）');

  final String id;
  final String label;
  const ServerSyncMode(this.id, this.label);

  static ServerSyncMode fromId(String? value) {
    for (final mode in ServerSyncMode.values) {
      if (mode.id == value) return mode;
    }
    return ServerSyncMode.pullOnly;
  }
}

enum ServerSyncConflictPolicy {
  serverWins('server_wins', '服务端优先'),
  localWins('local_wins', '本地优先');

  final String id;
  final String label;
  const ServerSyncConflictPolicy(this.id, this.label);

  static ServerSyncConflictPolicy fromId(String? value) {
    for (final policy in ServerSyncConflictPolicy.values) {
      if (policy.id == value) return policy;
    }
    return ServerSyncConflictPolicy.serverWins;
  }
}

class ServerPushResult {
  final int applied;
  final int noop;
  final int stale;
  final int conflict;
  final int failed;

  const ServerPushResult({
    required this.applied,
    required this.noop,
    required this.stale,
    required this.conflict,
    required this.failed,
  });

  const ServerPushResult.zero()
    : applied = 0,
      noop = 0,
      stale = 0,
      conflict = 0,
      failed = 0;

  int get total => applied + noop + stale + conflict + failed;
}

class ServerSyncResult {
  final int pulledUpserted;
  final int pulledDeleted;
  final Set<String> pulledUpsertedTopicIds;
  final Set<String> pulledDeletedTopicIds;
  final ServerPushResult push;
  final ServerSyncMode mode;
  final ServerSyncConflictPolicy conflictPolicy;

  const ServerSyncResult({
    required this.pulledUpserted,
    required this.pulledDeleted,
    required this.pulledUpsertedTopicIds,
    required this.pulledDeletedTopicIds,
    required this.push,
    required this.mode,
    required this.conflictPolicy,
  });

  String get summaryLine {
    if (mode == ServerSyncMode.pullOnly) {
      if (pulledUpserted == 0 && pulledDeleted == 0) return '已是最新';
      return '同步完成: 拉取 +$pulledUpserted -$pulledDeleted';
    }
    return '同步完成: 拉取 +$pulledUpserted -$pulledDeleted, '
        '推送 应用${push.applied}/无变更${push.noop}/'
        '旧版本${push.stale}/冲突${push.conflict}/失败${push.failed}';
  }
}

class ServerSyncPendingConflict {
  final String topicId;
  final String operation;
  final String status;
  final int detectedAt;
  final String? reason;
  final int? localUpdatedAt;
  final int? serverRevision;
  final int? serverUpdatedAt;
  final int? serverClientUpdatedAt;

  const ServerSyncPendingConflict({
    required this.topicId,
    required this.operation,
    required this.status,
    required this.detectedAt,
    this.reason,
    this.localUpdatedAt,
    this.serverRevision,
    this.serverUpdatedAt,
    this.serverClientUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'operation': operation,
    'status': status,
    'detectedAt': detectedAt,
    'reason': reason,
    'localUpdatedAt': localUpdatedAt,
    'serverRevision': serverRevision,
    'serverUpdatedAt': serverUpdatedAt,
    'serverClientUpdatedAt': serverClientUpdatedAt,
  };

  static ServerSyncPendingConflict? fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final topicId = raw['topicId']?.toString() ?? '';
    if (topicId.isEmpty) return null;
    final operation = raw['operation']?.toString() ?? 'upsert';
    final status = raw['status']?.toString() ?? 'conflict';
    final detectedAt = (raw['detectedAt'] is num)
        ? (raw['detectedAt'] as num).toInt()
        : DateTime.now().millisecondsSinceEpoch;
    final reason = raw['reason']?.toString();
    final localUpdatedAt = _parseOptionalInt(raw['localUpdatedAt']);
    final serverRevision = _parseOptionalInt(raw['serverRevision']);
    final serverUpdatedAt = _parseOptionalInt(raw['serverUpdatedAt']);
    final serverClientUpdatedAt = _parseOptionalInt(
      raw['serverClientUpdatedAt'],
    );
    return ServerSyncPendingConflict(
      topicId: topicId,
      operation: operation,
      status: status,
      detectedAt: detectedAt,
      reason: reason,
      localUpdatedAt: localUpdatedAt,
      serverRevision: serverRevision,
      serverUpdatedAt: serverUpdatedAt,
      serverClientUpdatedAt: serverClientUpdatedAt,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ServerSyncConflictResolveResult {
  final bool resolved;
  final String message;

  const ServerSyncConflictResolveResult({
    required this.resolved,
    required this.message,
  });
}

class _ServerTopicWriteResult {
  final String topicId;
  final String status;
  final bool ok;
  final String? error;
  final int? seq;
  final int? revision;
  final int? serverUpdatedAt;
  final int? serverClientUpdatedAt;
  final int? serverDeletedAt;
  final int? localUpdatedAt;

  const _ServerTopicWriteResult({
    required this.topicId,
    required this.status,
    required this.ok,
    this.error,
    this.seq,
    this.revision,
    this.serverUpdatedAt,
    this.serverClientUpdatedAt,
    this.serverDeletedAt,
    this.localUpdatedAt,
  });

  _ServerTopicWriteResult withLocalUpdatedAt(int? value) {
    return _ServerTopicWriteResult(
      topicId: topicId,
      status: status,
      ok: ok,
      error: error,
      seq: seq,
      revision: revision,
      serverUpdatedAt: serverUpdatedAt,
      serverClientUpdatedAt: serverClientUpdatedAt,
      serverDeletedAt: serverDeletedAt,
      localUpdatedAt: value,
    );
  }

  bool get isConflictLike => status == 'stale' || status == 'conflict';

  bool get isTerminalSuccess =>
      status == 'applied' || status == 'noop' || status == 'not_found';
}

class _ManifestEntry {
  final int revision;
  final int? deletedAt;

  const _ManifestEntry({required this.revision, this.deletedAt});
}

class _ManifestResponse {
  final int changeSeq;
  final int topicCount;
  final Map<String, _ManifestEntry> entries;

  const _ManifestResponse({
    required this.changeSeq,
    required this.topicCount,
    required this.entries,
  });
}

/// Cherry Sync Server 同步服务（基于 Manifest 协调）
///
/// 支持：
/// 1. 基于 manifest（topicId → revision）做协调
/// 2. 双向推送（批量 upsert）
/// 3. 冲突策略（服务端优先 / 本地优先）
class ServerSyncService {
  static const String _lastSyncKey = 'server_sync_last_timestamp';
  static const String _serverUrlKey = 'server_sync_url';
  static const String _serverTokenKey = 'server_sync_token';
  static const String _syncModeKey = 'server_sync_mode';
  static const String _conflictPolicyKey = 'server_sync_conflict_policy';
  static const String _syncIntervalSecondsKey = 'server_sync_interval_seconds';
  static const String _syncIntervalMinutesLegacyKey =
      'server_sync_interval_minutes';
  static const String _pendingConflictsKeyPrefix =
      'server_sync_pending_conflicts';
  static const String _syncedRevisionsKeyPrefix = 'server_sync_revisions';
  static const String _dirtyTopicsKeyPrefix = 'server_sync_dirty_topics';
  // 旧版快照 key，仅用于迁移
  static const String _pushSnapshotKeyPrefix = 'server_sync_push_topic_ids';
  static const String _pushSnapshotVersionKeyPrefix =
      'server_sync_push_topic_versions';
  static const String _pushSnapshotTable = 'server_sync_topic_snapshots';
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const int defaultSyncIntervalSeconds = 30 * 60;
  static const int minSyncIntervalSeconds = 5;
  static const int maxSyncIntervalSeconds = 24 * 60 * 60;
  static const int _topicWriteBatchSize = 20;
  static const int _topicDeleteBatchSize = 100;
  static const int _batchGetThreshold = 5;

  final AppDb _appDb;

  ServerSyncService(this._appDb);

  // ── 配置管理 ──────────────────────────────────────────────────────

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? '';
  }

  static Future<String> getServerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverTokenKey) ?? '';
  }

  static Future<void> saveConfig({
    required String serverUrl,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _serverUrlKey,
      serverUrl.replaceAll(RegExp(r'/+$'), ''),
    );
    await prefs.setString(_serverTokenKey, token);
  }

  static Future<bool> get isConfigured async {
    final url = await getServerUrl();
    return url.isNotEmpty;
  }

  static Future<ServerSyncMode> getSyncMode() async {
    final prefs = await SharedPreferences.getInstance();
    return ServerSyncMode.fromId(prefs.getString(_syncModeKey));
  }

  static Future<ServerSyncConflictPolicy> getConflictPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return ServerSyncConflictPolicy.fromId(prefs.getString(_conflictPolicyKey));
  }

  static Future<int> getSyncIntervalSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSeconds = prefs.getInt(_syncIntervalSecondsKey);
    if (rawSeconds != null) {
      return rawSeconds.clamp(minSyncIntervalSeconds, maxSyncIntervalSeconds);
    }

    final rawMinutes = prefs.getInt(_syncIntervalMinutesLegacyKey);
    if (rawMinutes != null) {
      final migratedSeconds = (rawMinutes.clamp(5, 1440) * 60).clamp(
        minSyncIntervalSeconds,
        maxSyncIntervalSeconds,
      );
      await prefs.setInt(_syncIntervalSecondsKey, migratedSeconds);
      return migratedSeconds;
    }

    return defaultSyncIntervalSeconds;
  }

  static Future<void> saveSyncBehavior({
    required ServerSyncMode mode,
    required ServerSyncConflictPolicy conflictPolicy,
    int? intervalSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncModeKey, mode.id);
    await prefs.setString(_conflictPolicyKey, conflictPolicy.id);
    if (intervalSeconds != null) {
      await prefs.setInt(
        _syncIntervalSecondsKey,
        intervalSeconds.clamp(minSyncIntervalSeconds, maxSyncIntervalSeconds),
      );
    }
  }

  Future<List<ServerSyncPendingConflict>> getPendingConflicts() async {
    final config = await _tryResolveConfig();
    if (config == null) return const [];
    final prefs = await SharedPreferences.getInstance();
    final cached = _readPendingConflicts(
      prefs,
      serverUrl: config.serverUrl,
      token: config.token,
    );
    return cached;
  }

  Future<void> clearPendingConflicts() async {
    final config = await _tryResolveConfig();
    if (config == null) return;
    final prefs = await SharedPreferences.getInstance();
    await _writePendingConflicts(
      prefs,
      serverUrl: config.serverUrl,
      token: config.token,
      conflicts: const [],
    );
  }

  // ── Synced Revisions 存储层 ────────────────────────────────────────

  String _syncedRevisionsKeyScoped(String scope) =>
      '$_syncedRevisionsKeyPrefix:$scope';

  String _dirtyTopicsKeyScoped(String scope) =>
      '$_dirtyTopicsKeyPrefix:$scope';

  Future<Map<String, int>> _loadSyncedRevisions({
    required String serverUrl,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    final raw = prefs.getString(_syncedRevisionsKeyScoped(scope));
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      final out = <String, int>{};
      decoded.forEach((key, value) {
        final topicId = key.toString().trim();
        if (topicId.isEmpty) return;
        final rev = _toOptionalInt(value);
        if (rev != null) out[topicId] = rev;
      });
      return out;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _saveSyncedRevisions({
    required String serverUrl,
    required String token,
    required Map<String, int> revisions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    await prefs.setString(
      _syncedRevisionsKeyScoped(scope),
      jsonEncode(revisions),
    );
  }

  Future<Set<String>> _loadDirtyTopicIds({
    required String serverUrl,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    final raw = prefs.getString(_dirtyTopicsKeyScoped(scope));
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded
          .map((item) => item.toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _saveDirtyTopicIds({
    required String serverUrl,
    required String token,
    required Set<String> ids,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    if (ids.isEmpty) {
      await prefs.remove(_dirtyTopicsKeyScoped(scope));
      return;
    }
    await prefs.setString(
      _dirtyTopicsKeyScoped(scope),
      jsonEncode(ids.toList()),
    );
  }

  // ── Manifest API ──────────────────────────────────────────────────

  Future<_ManifestResponse> _fetchManifest({
    required String serverUrl,
    required String token,
  }) async {
    final resp = await _getWithTimeout(
      Uri.parse('$serverUrl/api/sync/manifest'),
      headers: {'Authorization': 'Bearer $token'},
      timeoutMessage: '拉取 Manifest 超时，请检查网络或服务器状态',
    );

    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw StateError('认证失败，请检查 Token');
    }
    if (resp.statusCode != 200) {
      throw StateError('拉取 Manifest 失败（HTTP ${resp.statusCode}）');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Manifest 格式错误');
    }

    final changeSeq = (decoded['changeSeq'] as num?)?.toInt() ?? 0;
    final topicCount = (decoded['topicCount'] as num?)?.toInt() ?? 0;
    final rawEntries = decoded['entries'];
    final entries = <String, _ManifestEntry>{};

    if (rawEntries is Map<String, dynamic>) {
      rawEntries.forEach((topicId, value) {
        if (value is! Map<String, dynamic>) return;
        entries[topicId] = _ManifestEntry(
          revision: (value['revision'] as num?)?.toInt() ?? 0,
          deletedAt: value['deletedAt'] != null
              ? (value['deletedAt'] as num?)?.toInt()
              : null,
        );
      });
    }

    return _ManifestResponse(
      changeSeq: changeSeq,
      topicCount: topicCount,
      entries: entries,
    );
  }

  Future<Map<String, dynamic>?> _fetchTopicById({
    required String serverUrl,
    required String token,
    required String topicId,
  }) async {
    final resp = await _getWithTimeout(
      Uri.parse('$serverUrl/api/topics/$topicId'),
      headers: {'Authorization': 'Bearer $token'},
      timeoutMessage: '拉取话题超时',
    );
    if (resp.statusCode == 404) return null;
    if (resp.statusCode != 200) return null;
    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) return null;
    return (decoded['topic'] ?? decoded['data'] ?? decoded)
        as Map<String, dynamic>?;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchTopicsBatch({
    required String serverUrl,
    required String token,
    required List<String> topicIds,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    if (topicIds.isEmpty) return out;

    if (topicIds.length <= _batchGetThreshold) {
      for (final id in topicIds) {
        final data = await _fetchTopicById(
          serverUrl: serverUrl,
          token: token,
          topicId: id,
        );
        if (data != null) out[id] = data;
      }
      return out;
    }

    try {
      final resp = await _postWithTimeout(
        Uri.parse('$serverUrl/api/topics/batch-get'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'topicIds': topicIds}),
        timeoutMessage: '批量拉取话题超时',
      );

      if (resp.statusCode != 200) {
        // fallback to individual fetches
        for (final id in topicIds) {
          final data = await _fetchTopicById(
            serverUrl: serverUrl,
            token: token,
            topicId: id,
          );
          if (data != null) out[id] = data;
        }
        return out;
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) return out;
      final topics = decoded['topics'];
      if (topics is! List) return out;

      for (final item in topics) {
        if (item is! Map<String, dynamic>) continue;
        final topicId = item['topicId']?.toString() ?? '';
        final topicData = item['topic'] ?? item;
        if (topicId.isNotEmpty && topicData is Map<String, dynamic>) {
          out[topicId] = topicData;
        }
      }
    } catch (e) {
      debugPrint('[ServerSync] batch-get failed, falling back: $e');
      for (final id in topicIds) {
        final data = await _fetchTopicById(
          serverUrl: serverUrl,
          token: token,
          topicId: id,
        );
        if (data != null) out[id] = data;
      }
    }

    return out;
  }

  // ── 迁移 ──────────────────────────────────────────────────────────

  Future<void> _migrateFromSnapshotIfNeeded({
    required String serverUrl,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    final revisionsKey = _syncedRevisionsKeyScoped(scope);

    // 如果已有 syncedRevisions，说明已迁移过
    if (prefs.getString(revisionsKey) != null) return;

    final db = _appDb.importDb;
    final currentVersions = await _loadCurrentTopicVersions(db);

    // 初始化：所有 topic revision 设为 0，标记为 dirty
    final revisions = <String, int>{};
    final dirtyIds = <String>{};
    for (final topicId in currentVersions.keys) {
      revisions[topicId] = 0;
      dirtyIds.add(topicId);
    }

    await _saveSyncedRevisions(
      serverUrl: serverUrl,
      token: token,
      revisions: revisions,
    );
    await _saveDirtyTopicIds(
      serverUrl: serverUrl,
      token: token,
      ids: dirtyIds,
    );

    // 清理旧快照数据
    final legacyVersionKey = _buildScopedPushVersionSnapshotKey(
      serverUrl: serverUrl,
      token: token,
    );
    final legacyIdsKey = _buildScopedPushSnapshotKey(
      serverUrl: serverUrl,
      token: token,
    );
    await prefs.remove(legacyVersionKey);
    await prefs.remove(legacyIdsKey);

    // 清理 DB 中的旧快照表
    try {
      final userDb = _appDb.userDb;
      await userDb.customStatement(
        'DELETE FROM $_pushSnapshotTable WHERE scope = ?',
        [scope],
      );
    } catch (_) {
      // 旧表可能不存在，忽略
    }

    debugPrint(
      '[ServerSync] Migrated to manifest-based sync: '
      '${currentVersions.length} topics marked dirty',
    );
  }

  // ── 同步入口 ───────────────────────────────────────────────────────

  Future<ServerSyncResult> syncNow({
    void Function(String message)? onStatus,
  }) async {
    await _appDb.init();
    final config = await _resolveConfig();
    final mode = await getSyncMode();
    final conflictPolicy = await getConflictPolicy();

    onStatus?.call('检查同步服务器连接...');
    await _probeServer(config.serverUrl, config.token);

    // 迁移检查
    await _migrateFromSnapshotIfNeeded(
      serverUrl: config.serverUrl,
      token: config.token,
    );

    onStatus?.call('拉取服务端清单...');
    final manifest = await _fetchManifest(
      serverUrl: config.serverUrl,
      token: config.token,
    );

    final db = _appDb.importDb;
    final localVersions = await _loadCurrentTopicVersions(db);
    final localTopicIds = localVersions.keys.toSet();
    final syncedRevisions = await _loadSyncedRevisions(
      serverUrl: config.serverUrl,
      token: config.token,
    );
    final dirtyTopicIds = await _loadDirtyTopicIds(
      serverUrl: config.serverUrl,
      token: config.token,
    );

    // 协调
    final toFetch = <String>[];
    final toDeleteLocal = <String>[];
    final toPush = <String>[];
    final toDeleteRemote = <String>[];
    var conflictCount = 0;
    final newConflicts = <ServerSyncPendingConflict>[];

    for (final entry in manifest.entries.entries) {
      final topicId = entry.key;
      final mEntry = entry.value;
      final localHas = localTopicIds.contains(topicId);
      final syncedRev = syncedRevisions[topicId] ?? -1;
      final isDirty = dirtyTopicIds.contains(topicId);
      final serverDeleted = mEntry.deletedAt != null;

      if (serverDeleted) {
        if (localHas && !isDirty) {
          toDeleteLocal.add(topicId);
        } else if (localHas && isDirty) {
          if (mode == ServerSyncMode.autoFull) {
            if (conflictPolicy == ServerSyncConflictPolicy.serverWins) {
              toDeleteLocal.add(topicId);
            } else {
              toPush.add(topicId);
            }
          } else if (mode == ServerSyncMode.autoSafe) {
            conflictCount++;
            newConflicts.add(ServerSyncPendingConflict(
              topicId: topicId,
              operation: 'upsert',
              status: 'conflict',
              detectedAt: DateTime.now().millisecondsSinceEpoch,
              reason: 'server_deleted_local_dirty',
              serverRevision: mEntry.revision,
            ));
          }
        }
        continue;
      }

      if (!localHas) {
        if (isDirty) {
          toDeleteRemote.add(topicId);
        } else {
          // 所有模式都拉取新 topic（Flutter 端没有 push_only 模式）
          toFetch.add(topicId);
        }
        continue;
      }

      if (mEntry.revision > syncedRev) {
        if (!isDirty) {
          toFetch.add(topicId);
        } else {
          if (mode == ServerSyncMode.autoFull) {
            if (conflictPolicy == ServerSyncConflictPolicy.serverWins) {
              toFetch.add(topicId);
            } else {
              toPush.add(topicId);
            }
          } else if (mode == ServerSyncMode.autoSafe) {
            conflictCount++;
            newConflicts.add(ServerSyncPendingConflict(
              topicId: topicId,
              operation: 'upsert',
              status: 'conflict',
              detectedAt: DateTime.now().millisecondsSinceEpoch,
              reason: 'both_modified',
              serverRevision: mEntry.revision,
            ));
          }
        }
      }
    }

    // dirty topics → push
    for (final topicId in dirtyTopicIds) {
      if (localTopicIds.contains(topicId)) {
        if (!toFetch.contains(topicId) && !toPush.contains(topicId)) {
          toPush.add(topicId);
        }
      } else {
        if (!toDeleteRemote.contains(topicId)) {
          toDeleteRemote.add(topicId);
        }
      }
    }

    // 本地有、服务端没有且 dirty → push
    for (final topicId in localTopicIds) {
      if (!manifest.entries.containsKey(topicId) &&
          dirtyTopicIds.contains(topicId)) {
        if (!toPush.contains(topicId)) {
          toPush.add(topicId);
        }
      }
    }

    if (conflictCount > 0) {
      debugPrint(
        '[ServerSync] Manifest reconcile: $conflictCount conflicts (auto_safe mode, skipping)',
      );
    }

    var pulledUpserted = 0;
    var pulledDeleted = 0;
    final pulledUpsertedTopicIds = <String>{};
    final pulledDeletedTopicIds = <String>{};
    var pushApplied = 0;
    var pushNoop = 0;
    var pushStale = 0;
    var pushConflict = 0;
    var pushFailed = 0;

    // Pull
    if (toFetch.isNotEmpty) {
      onStatus?.call('拉取 ${toFetch.length} 个话题...');
      final fetched = await _fetchTopicsBatch(
        serverUrl: config.serverUrl,
        token: config.token,
        topicIds: toFetch,
      );

      for (final topicId in toFetch) {
        final topicData = fetched[topicId];
        if (topicData == null) continue;

        try {
          await _importTopicFromServer(db, topicData);
          pulledUpserted++;
          pulledUpsertedTopicIds.add(topicId);

          final serverEntry = manifest.entries[topicId];
          if (serverEntry != null) {
            syncedRevisions[topicId] = serverEntry.revision;
          }
          dirtyTopicIds.remove(topicId);
        } catch (e) {
          debugPrint('[ServerSync] Failed to import topic $topicId: $e');
        }
      }
    }

    // Local delete
    if (toDeleteLocal.isNotEmpty) {
      onStatus?.call('删除 ${toDeleteLocal.length} 个本地话题...');
      for (final topicId in toDeleteLocal) {
        try {
          await _deleteTopicsBatch(db, [topicId]);
          pulledDeleted++;
          pulledDeletedTopicIds.add(topicId);
          syncedRevisions.remove(topicId);
          dirtyTopicIds.remove(topicId);
        } catch (e) {
          debugPrint('[ServerSync] Failed to delete local topic $topicId: $e');
        }
      }
    }

    // Push
    if (mode != ServerSyncMode.pullOnly && toPush.isNotEmpty) {
      final topics = await _buildTopicPayloadsByIds(db, toPush);
      if (topics.isNotEmpty) {
        onStatus?.call('推送 ${topics.length} 个话题...');
      }

      final forceWrite = mode == ServerSyncMode.autoFull &&
          conflictPolicy == ServerSyncConflictPolicy.localWins;

      for (var i = 0; i < topics.length; i += _topicWriteBatchSize) {
        final end = (i + _topicWriteBatchSize).clamp(0, topics.length);
        final chunk = topics.sublist(i, end);
        onStatus?.call('推送中... $end/${topics.length}');
        final results = await _postTopicBatch(
          serverUrl: config.serverUrl,
          token: config.token,
          topics: chunk,
          force: forceWrite,
        );

        for (final result in results) {
          if (result.isTerminalSuccess) {
            if (result.revision != null) {
              syncedRevisions[result.topicId] = result.revision!;
            }
            dirtyTopicIds.remove(result.topicId);
          }

          switch (result.status) {
            case 'applied':
              pushApplied++;
              break;
            case 'noop':
            case 'not_found':
              pushNoop++;
              break;
            case 'stale':
              pushStale++;
              break;
            case 'conflict':
              pushConflict++;
              break;
            default:
              pushFailed++;
          }
        }
      }
    }

    // Remote delete
    if (mode != ServerSyncMode.pullOnly && toDeleteRemote.isNotEmpty) {
      onStatus?.call('远程删除 ${toDeleteRemote.length} 个话题...');
      for (var i = 0; i < toDeleteRemote.length; i += _topicDeleteBatchSize) {
        final end =
            (i + _topicDeleteBatchSize).clamp(0, toDeleteRemote.length);
        final chunk = toDeleteRemote.sublist(i, end);
        final results = await _postDeleteBatch(
          serverUrl: config.serverUrl,
          token: config.token,
          topicIds: chunk,
          force: false,
        );
        for (final result in results) {
          if (result.isTerminalSuccess) {
            syncedRevisions.remove(result.topicId);
            dirtyTopicIds.remove(result.topicId);
          }
          switch (result.status) {
            case 'applied':
              pushApplied++;
              break;
            case 'noop':
            case 'not_found':
              pushNoop++;
              break;
            default:
              pushFailed++;
          }
        }
      }
    }

    // 持久化
    await _saveSyncedRevisions(
      serverUrl: config.serverUrl,
      token: config.token,
      revisions: syncedRevisions,
    );
    await _saveDirtyTopicIds(
      serverUrl: config.serverUrl,
      token: config.token,
      ids: dirtyTopicIds,
    );

    // 写入 pending conflicts
    if (newConflicts.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final existing = _readPendingConflicts(
        prefs,
        serverUrl: config.serverUrl,
        token: config.token,
      );
      await _writePendingConflicts(
        prefs,
        serverUrl: config.serverUrl,
        token: config.token,
        conflicts: [...existing, ...newConflicts],
      );
    }

    // 设置 cursor
    final prefs = await SharedPreferences.getInstance();
    final syncCursorKey = _buildScopedLastSyncKey(
      serverUrl: config.serverUrl,
      token: config.token,
    );
    await prefs.setInt(syncCursorKey, manifest.changeSeq);

    final pushResult = ServerPushResult(
      applied: pushApplied,
      noop: pushNoop,
      stale: pushStale,
      conflict: pushConflict,
      failed: pushFailed,
    );

    final result = ServerSyncResult(
      pulledUpserted: pulledUpserted,
      pulledDeleted: pulledDeleted,
      pulledUpsertedTopicIds: pulledUpsertedTopicIds,
      pulledDeletedTopicIds: pulledDeletedTopicIds,
      push: pushResult,
      mode: mode,
      conflictPolicy: conflictPolicy,
    );
    onStatus?.call(result.summaryLine);
    return result;
  }

  Future<ServerSyncConflictResolveResult> resolvePendingConflict({
    required ServerSyncPendingConflict conflict,
    required ServerSyncConflictPolicy policy,
    void Function(String message)? onStatus,
  }) async {
    await _appDb.init();
    final config = await _resolveConfig();
    final prefs = await SharedPreferences.getInstance();
    final pending = _readPendingConflicts(
      prefs,
      serverUrl: config.serverUrl,
      token: config.token,
    );

    final key = _conflictKey(conflict.topicId, conflict.operation);
    final map = {
      for (final item in pending)
        _conflictKey(item.topicId, item.operation): item,
    };
    if (!map.containsKey(key)) {
      return const ServerSyncConflictResolveResult(
        resolved: true,
        message: '冲突已不存在',
      );
    }

    final syncedRevisions = await _loadSyncedRevisions(
      serverUrl: config.serverUrl,
      token: config.token,
    );
    final dirtyTopicIds = await _loadDirtyTopicIds(
      serverUrl: config.serverUrl,
      token: config.token,
    );

    if (policy == ServerSyncConflictPolicy.serverWins) {
      onStatus?.call('按服务端版本处理冲突...');
      await _refreshTopicFromServer(
        serverUrl: config.serverUrl,
        token: config.token,
        topicId: conflict.topicId,
      );
      if (conflict.reason == 'server_deleted_local_dirty' ||
          conflict.operation == 'delete') {
        syncedRevisions.remove(conflict.topicId);
      } else if (conflict.serverRevision != null) {
        syncedRevisions[conflict.topicId] = conflict.serverRevision!;
      }
      dirtyTopicIds.remove(conflict.topicId);
      await _saveSyncedRevisions(
        serverUrl: config.serverUrl,
        token: config.token,
        revisions: syncedRevisions,
      );
      await _saveDirtyTopicIds(
        serverUrl: config.serverUrl,
        token: config.token,
        ids: dirtyTopicIds,
      );
      map.remove(key);
      await _writePendingConflicts(
        prefs,
        serverUrl: config.serverUrl,
        token: config.token,
        conflicts: map.values.toList(),
      );
      return const ServerSyncConflictResolveResult(
        resolved: true,
        message: '已按服务端版本解决',
      );
    }

    onStatus?.call('按本地版本回写冲突...');
    if (conflict.operation == 'delete') {
      final results = await _postDeleteBatch(
        serverUrl: config.serverUrl,
        token: config.token,
        topicIds: [conflict.topicId],
        force: true,
      );
      final first = results.isNotEmpty ? results.first : null;
      if (first == null || !first.isTerminalSuccess) {
        return ServerSyncConflictResolveResult(
          resolved: false,
          message: '本地删除回写失败：${first?.status ?? 'error'}',
        );
      }

      syncedRevisions.remove(conflict.topicId);
      dirtyTopicIds.remove(conflict.topicId);
      await _saveSyncedRevisions(
        serverUrl: config.serverUrl,
        token: config.token,
        revisions: syncedRevisions,
      );
      await _saveDirtyTopicIds(
        serverUrl: config.serverUrl,
        token: config.token,
        ids: dirtyTopicIds,
      );
      map.remove(key);
      await _writePendingConflicts(
        prefs,
        serverUrl: config.serverUrl,
        token: config.token,
        conflicts: map.values.toList(),
      );
      return const ServerSyncConflictResolveResult(
        resolved: true,
        message: '已按本地删除回写',
      );
    }

    final topic = await _buildTopicPayloadById(
      _appDb.importDb,
      conflict.topicId,
    );
    if (topic == null) {
      return const ServerSyncConflictResolveResult(
        resolved: false,
        message: '本地话题不存在，无法回写',
      );
    }

    final results = await _postTopicBatch(
      serverUrl: config.serverUrl,
      token: config.token,
      topics: [topic],
      force: true,
    );
    final first = results.isNotEmpty ? results.first : null;
    if (first == null || !first.isTerminalSuccess) {
      return ServerSyncConflictResolveResult(
        resolved: false,
        message: '本地回写失败：${first?.status ?? 'error'}',
      );
    }

    if (first.revision != null) {
      syncedRevisions[conflict.topicId] = first.revision!;
    }
    dirtyTopicIds.remove(conflict.topicId);
    await _saveSyncedRevisions(
      serverUrl: config.serverUrl,
      token: config.token,
      revisions: syncedRevisions,
    );
    await _saveDirtyTopicIds(
      serverUrl: config.serverUrl,
      token: config.token,
      ids: dirtyTopicIds,
    );

    map.remove(key);
    await _writePendingConflicts(
      prefs,
      serverUrl: config.serverUrl,
      token: config.token,
      conflicts: map.values.toList(),
    );
    return const ServerSyncConflictResolveResult(
      resolved: true,
      message: '已按本地版本回写',
    );
  }

  /// 执行增量同步（简化版，直接调用 syncNow 的拉取部分）
  Future<({int upserted, int deleted})> incrementalSync({
    void Function(String message)? onStatus,
  }) async {
    final result = await syncNow(onStatus: onStatus);
    return (upserted: result.pulledUpserted, deleted: result.pulledDeleted);
  }

  /// 重置同步状态（强制全量重新拉取）
  static Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key == _lastSyncKey || key.startsWith('$_lastSyncKey:')) {
        await prefs.remove(key);
      }
      if (key.startsWith('$_syncedRevisionsKeyPrefix:') ||
          key.startsWith('$_dirtyTopicsKeyPrefix:')) {
        await prefs.remove(key);
      }
    }
  }

  Future<({String serverUrl, String token})> _resolveConfig() async {
    final serverUrl = (await getServerUrl()).trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    final token = (await getServerToken()).trim();
    if (serverUrl.isEmpty) {
      throw StateError('同步服务器未配置');
    }
    if (token.isEmpty) {
      throw StateError('同步 Token 为空，请先配置');
    }
    return (serverUrl: serverUrl, token: token);
  }

  Future<({String serverUrl, String token})?> _tryResolveConfig() async {
    try {
      return await _resolveConfig();
    } catch (_) {
      return null;
    }
  }

  Future<void> _probeServer(String serverUrl, String token) async {
    final resp = await _getWithTimeout(
      Uri.parse(
        '$serverUrl/api/sync/changes?cursor=0&limit=1&includePayload=0',
      ),
      headers: {'Authorization': 'Bearer $token'},
      timeoutMessage: '连接同步服务器超时，请检查网络或服务器状态',
    );

    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw StateError('认证失败，请检查 Token');
    }
    if (resp.statusCode != 200) {
      throw StateError('同步服务器不可用（HTTP ${resp.statusCode}）');
    }
  }

  Future<List<_ServerTopicWriteResult>> _postTopicBatch({
    required String serverUrl,
    required String token,
    required List<Map<String, dynamic>> topics,
    required bool force,
  }) async {
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (force) 'X-Sync-Force': '1',
    };

    final resp = await _postWithTimeout(
      Uri.parse('$serverUrl/api/topics/batch'),
      headers: headers,
      body: jsonEncode({'topics': topics}),
      timeoutMessage: '推送到同步服务器超时，请检查网络或服务器状态',
    );

    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw StateError('认证失败，请检查 Token');
    }
    if (resp.statusCode != 200) {
      throw StateError('推送失败：服务器返回 ${resp.statusCode}');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('推送失败：服务器响应格式错误');
    }

    final rawResults = decoded['results'];
    if (rawResults is! List) {
      throw StateError('推送失败：服务器未返回结果列表');
    }

    final localUpdatedById = <String, int?>{};
    for (final topic in topics) {
      final topicId = topic['topicId']?.toString() ?? '';
      if (topicId.isEmpty) continue;
      localUpdatedById[topicId] = _toOptionalInt(topic['updatedAt']);
    }

    final outById = <String, _ServerTopicWriteResult>{};
    for (final item in rawResults) {
      if (item is! Map<String, dynamic>) continue;
      final topicId = item['topicId']?.toString() ?? '';
      if (topicId.isEmpty) continue;
      outById[topicId] = _ServerTopicWriteResult(
        topicId: topicId,
        status: item['status']?.toString() ?? 'error',
        ok: item['ok'] == true,
        error: item['error']?.toString(),
        seq: _toOptionalInt(item['seq']),
        revision: _toOptionalInt(item['revision']),
        serverUpdatedAt: _toOptionalInt(
          item['serverUpdatedAt'] ?? item['updatedAt'],
        ),
        serverClientUpdatedAt: _toOptionalInt(
          item['serverClientUpdatedAt'] ?? item['clientUpdatedAt'],
        ),
        serverDeletedAt: _toOptionalInt(
          item['serverDeletedAt'] ?? item['deletedAt'],
        ),
        localUpdatedAt: localUpdatedById[topicId],
      );
    }

    final out = <_ServerTopicWriteResult>[];
    for (final topic in topics) {
      final topicId = topic['topicId']?.toString() ?? '';
      if (topicId.isEmpty) continue;
      out.add(
        (outById[topicId] ??
                _ServerTopicWriteResult(
                  topicId: topicId,
                  status: 'error',
                  ok: false,
                ))
            .withLocalUpdatedAt(localUpdatedById[topicId]),
      );
    }

    return out;
  }

  Future<List<_ServerTopicWriteResult>> _postDeleteBatch({
    required String serverUrl,
    required String token,
    required List<String> topicIds,
    required bool force,
  }) async {
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (force) 'X-Sync-Force': '1',
    };

    final resp = await _postWithTimeout(
      Uri.parse('$serverUrl/api/topics/delete-batch'),
      headers: headers,
      body: jsonEncode({'topicIds': topicIds}),
      timeoutMessage: '删除回写到同步服务器超时，请检查网络或服务器状态',
    );

    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw StateError('认证失败，请检查 Token');
    }
    if (resp.statusCode != 200) {
      throw StateError('删除回写失败：服务器返回 ${resp.statusCode}');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('删除回写失败：服务器响应格式错误');
    }

    final rawResults = decoded['results'];
    if (rawResults is! List) {
      throw StateError('删除回写失败：服务器未返回结果列表');
    }

    final outById = <String, _ServerTopicWriteResult>{};
    for (final item in rawResults) {
      if (item is! Map<String, dynamic>) continue;
      final topicId = item['topicId']?.toString() ?? '';
      if (topicId.isEmpty) continue;
      outById[topicId] = _ServerTopicWriteResult(
        topicId: topicId,
        status: item['status']?.toString() ?? 'error',
        ok: item['ok'] == true,
        error: item['error']?.toString(),
        seq: _toOptionalInt(item['seq']),
        revision: _toOptionalInt(item['revision']),
        serverUpdatedAt: _toOptionalInt(
          item['serverUpdatedAt'] ?? item['updatedAt'],
        ),
        serverClientUpdatedAt: _toOptionalInt(
          item['serverClientUpdatedAt'] ?? item['clientUpdatedAt'],
        ),
        serverDeletedAt: _toOptionalInt(
          item['serverDeletedAt'] ?? item['deletedAt'],
        ),
      );
    }

    final out = <_ServerTopicWriteResult>[];
    for (final topicId in topicIds) {
      if (topicId.isEmpty) continue;
      out.add(
        outById[topicId] ??
            _ServerTopicWriteResult(
              topicId: topicId,
              status: 'error',
              ok: false,
            ),
      );
    }
    return out;
  }

  Future<void> _refreshTopicFromServer({
    required String serverUrl,
    required String token,
    required String topicId,
  }) async {
    final resp = await _getWithTimeout(
      Uri.parse('$serverUrl/api/topics/$topicId'),
      headers: {'Authorization': 'Bearer $token'},
      timeoutMessage: '拉取服务端话题超时，请检查网络或服务器状态',
    );

    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw StateError('认证失败，请检查 Token');
    }

    final db = _appDb.importDb;
    if (resp.statusCode == 404) {
      await _deleteTopicsBatch(db, [topicId]);
      return;
    }
    if (resp.statusCode != 200) {
      throw StateError('拉取服务端话题失败：HTTP ${resp.statusCode}');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('拉取服务端话题失败：响应格式错误');
    }
    final topic = decoded['topic'] ?? decoded['data'];
    if (topic is! Map<String, dynamic>) {
      throw StateError('拉取服务端话题失败：缺少 topic 数据');
    }

    await db.transaction(() async {
      await _importTopicFromServerInTransaction(db, topic);
    });
  }

  Future<Map<String, dynamic>?> _buildTopicPayloadById(
    ImportDatabase db,
    String topicId,
  ) async {
    if (topicId.isEmpty) return null;
    final all = await _buildTopicPayloadsByIds(db, [topicId]);
    return all.isEmpty ? null : all.first;
  }

  Future<List<Map<String, dynamic>>> _buildTopicPayloadsByIds(
    ImportDatabase db,
    List<String> topicIds,
  ) async {
    if (topicIds.isEmpty) return const [];
    final normalizedTopicIds = topicIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedTopicIds.isEmpty) return const [];

    final topics =
        await (db.select(db.topics)
              ..where((t) => t.topicId.isIn(normalizedTopicIds))
              ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
            .get();
    if (topics.isEmpty) return const [];

    final links =
        await (db.select(db.topicAssistants)
              ..orderBy([
                (t) => OrderingTerm.asc(t.topicId),
                (t) => OrderingTerm.asc(t.assistantId),
              ])
              ..where((t) => t.topicId.isIn(normalizedTopicIds)))
            .get();
    final topicAssistantByTopicId = <String, String>{};
    final assistantIds = <String>{};
    for (final link in links) {
      topicAssistantByTopicId.putIfAbsent(link.topicId, () => link.assistantId);
      assistantIds.add(link.assistantId);
    }

    final assistantNameById = <String, String>{};
    if (assistantIds.isNotEmpty) {
      final assistants = await (db.select(
        db.assistants,
      )..where((t) => t.assistantId.isIn(assistantIds.toList()))).get();
      for (final row in assistants) {
        assistantNameById[row.assistantId] = row.name;
      }
    }

    final messages =
        await (db.select(db.messages)
              ..orderBy([
                (t) => OrderingTerm.asc(t.topicId),
                (t) => OrderingTerm.asc(t.orderIndex),
              ])
              ..where((t) => t.topicId.isIn(normalizedTopicIds)))
            .get();
    final blocks =
        await (db.select(db.messageBlocks)
              ..orderBy([
                (t) => OrderingTerm.asc(t.messageId),
                (t) => OrderingTerm.asc(t.orderIndex),
              ])
              ..where((t) => t.topicId.isIn(normalizedTopicIds)))
            .get();

    final blocksByMessageId = <String, List<MessageBlock>>{};
    for (final block in blocks) {
      blocksByMessageId.putIfAbsent(block.messageId, () => []).add(block);
    }

    final messagesByTopicId = <String, List<Message>>{};
    for (final message in messages) {
      messagesByTopicId.putIfAbsent(message.topicId, () => []).add(message);
    }

    final payloads = <Map<String, dynamic>>[];
    for (final topic in topics) {
      final assistantId = topicAssistantByTopicId[topic.topicId];
      final assistantName = assistantId == null
          ? ''
          : (assistantNameById[assistantId] ?? '');
      final topicMessages =
          messagesByTopicId[topic.topicId] ?? const <Message>[];

      final messagePayloads = <Map<String, dynamic>>[];
      for (final message in topicMessages) {
        final messageBlocks =
            blocksByMessageId[message.messageId] ?? const <MessageBlock>[];

        final blockPayloads = <Map<String, dynamic>>[];
        for (final block in messageBlocks) {
          final blockPayload = <String, dynamic>{
            'id': block.blockId,
            'type': block.type,
            'createdAt': block.createdAt,
          };
          if (block.content != null) {
            blockPayload['content'] =
                _tryDecodeJson(block.content!) ?? block.content!;
          }
          if (block.thinkingMillsec != null) {
            blockPayload['thinking_millsec'] = block.thinkingMillsec;
          }
          if (block.url != null) blockPayload['url'] = block.url;
          final file = _tryDecodeJson(block.fileJson);
          if (file != null) blockPayload['file'] = file;
          final tool = _tryDecodeJson(block.toolJson);
          if (tool is Map) {
            blockPayload['toolId'] = tool['toolId'];
            blockPayload['toolName'] = tool['toolName'];
            blockPayload['arguments'] = tool['arguments'];
          }
          final error = _tryDecodeJson(block.errorJson);
          if (error != null) blockPayload['error'] = error;
          if (block.targetLanguage != null) {
            blockPayload['targetLanguage'] = block.targetLanguage;
          }
          final response = _tryDecodeJson(block.responseJson);
          if (response != null) blockPayload['response'] = response;
          final knowledge = _tryDecodeJson(block.knowledgeJson);
          if (knowledge != null) blockPayload['knowledge'] = knowledge;

          blockPayloads.add(blockPayload);
        }

        final messagePayload = <String, dynamic>{
          'id': message.messageId,
          'role': message.role,
          'createdAt': message.createdAt,
          'status': message.status,
          'useful': message.useful,
          'blocks': blockPayloads,
        };
        if (message.askId != null) messagePayload['askId'] = message.askId;
        if (message.modelId != null || message.modelName != null) {
          messagePayload['model'] = <String, dynamic>{
            'id': message.modelId,
            'name': message.modelName,
          };
          messagePayload['modelId'] = message.modelId;
          messagePayload['modelName'] = message.modelName;
        }
        final usage = _tryDecodeJson(message.usageJson);
        if (usage != null) messagePayload['usage'] = usage;
        final metrics = _tryDecodeJson(message.metricsJson);
        if (metrics != null) messagePayload['metrics'] = metrics;
        final mentions = _tryDecodeJson(message.mentionsJson);
        if (mentions != null) messagePayload['mentions'] = mentions;

        messagePayloads.add(messagePayload);
      }

      final topicPayload = <String, dynamic>{
        'topicId': topic.topicId,
        'name': topic.name,
        'assistantId': assistantId,
        'assistantName': assistantName,
        'createdAt': topic.createdAt,
        'updatedAt': topic.updatedAt,
        'messages': messagePayloads,
      };
      if (topic.pinned) topicPayload['pinned'] = true;
      if (topic.prompt != null && topic.prompt!.isNotEmpty) {
        topicPayload['prompt'] = topic.prompt;
      }
      if (topic.topicType != null && topic.topicType!.isNotEmpty) {
        topicPayload['type'] = topic.topicType;
      }
      if (topic.isNameManuallyEdited) {
        topicPayload['isNameManuallyEdited'] = true;
      }
      payloads.add(topicPayload);
    }

    return payloads;
  }

  dynamic _tryDecodeJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  int? _toOptionalInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // ── 数据写入 ──────────────────────────────────────────────────────

  Future<void> _importTopicFromServer(
    ImportDatabase db,
    Map<String, dynamic> topicData,
  ) async {
    await db.transaction(() async {
      await _importTopicFromServerInTransaction(db, topicData);
    });
  }

  Future<void> _importTopicFromServerInTransaction(
    ImportDatabase db,
    Map<String, dynamic> topicData,
  ) async {
    final topicId = topicData['topicId'] as String? ?? '';
    if (topicId.isEmpty) return;

    final topicName = topicData['name'] as String? ?? '未命名';
    final assistantId = topicData['assistantId'] as String?;
    final assistantName = topicData['assistantName'] as String?;
    final messages = topicData['messages'] as List<dynamic>? ?? [];

    final createdAt = _parseTimestamp(topicData['createdAt']);
    final updatedAt = _parseTimestamp(topicData['updatedAt']);

    // 计算 roundIndex
    var roundIndex = -1;
    final roundMap = <int, int>{};
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m is! Map<String, dynamic>) continue;
      if (m['role'] == 'user') roundIndex++;
      roundMap[i] = roundIndex.clamp(0, 1 << 30);
    }

    // 写入 Assistant（如果有）
    if (assistantId != null && assistantId.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.assistants)
          .insertOnConflictUpdate(
            AssistantsCompanion(
              assistantId: Value(assistantId),
              name: Value(assistantName ?? '未命名'),
              topicCount: const Value(0),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }

    // 先清除旧数据
    await (db.delete(
      db.messageBlocks,
    )..where((t) => t.topicId.equals(topicId))).go();
    await (db.delete(
      db.messages,
    )..where((t) => t.topicId.equals(topicId))).go();

    // 解析额外元数据
    final pinned = topicData['pinned'] == true;
    final prompt = topicData['prompt'] as String?;
    final topicType = topicData['type'] as String?;
    final isNameManuallyEdited = topicData['isNameManuallyEdited'] == true;

    // 写入 Topic
    await db
        .into(db.topics)
        .insertOnConflictUpdate(
          TopicsCompanion(
            topicId: Value(topicId),
            name: Value(topicName),
            messageCount: Value(messages.length),
            roundCount: Value(roundIndex + 1),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
            pinned: Value(pinned),
            prompt: Value(prompt),
            topicType: Value(topicType),
            isNameManuallyEdited: Value(isNameManuallyEdited),
          ),
        );

    // 写入 TopicAssistants 关联
    await (db.delete(
      db.topicAssistants,
    )..where((t) => t.topicId.equals(topicId))).go();
    if (assistantId != null && assistantId.isNotEmpty) {
      await db
          .into(db.topicAssistants)
          .insertOnConflictUpdate(
            TopicAssistantsCompanion(
              topicId: Value(topicId),
              assistantId: Value(assistantId),
            ),
          );
    }

    // 批量写入 Messages 和 Blocks
    final messageRows = <MessagesCompanion>[];
    final blockRows = <MessageBlocksCompanion>[];

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg is! Map<String, dynamic>) continue;

      final messageId = msg['id'] as String? ?? '';
      if (messageId.isEmpty) continue;

      final role = msg['role'] as String? ?? '';
      final model = msg['model'] as Map<String, dynamic>?;
      final modelId = (model?['id'] ?? msg['modelId']) as String?;
      final modelName = (model?['name'] ?? msg['modelName']) as String?;

      messageRows.add(
        MessagesCompanion(
          messageId: Value(messageId),
          topicId: Value(topicId),
          orderIndex: Value(i),
          roundIndex: Value(roundMap[i] ?? 0),
          role: Value(role),
          askId: Value(msg['askId'] as String?),
          useful: Value((msg['useful'] as bool?) ?? true),
          modelId: Value(modelId),
          modelName: Value(modelName),
          usageJson: Value(
            msg['usage'] != null ? jsonEncode(msg['usage']) : null,
          ),
          metricsJson: Value(
            msg['metrics'] != null ? jsonEncode(msg['metrics']) : null,
          ),
          mentionsJson: Value(
            msg['mentions'] != null ? jsonEncode(msg['mentions']) : null,
          ),
          createdAt: Value(_parseTimestamp(msg['createdAt'])),
          status: Value(msg['status'] as String? ?? 'success'),
        ),
      );

      // Blocks 已内联在 message 中
      final blocks = msg['blocks'] as List<dynamic>? ?? [];
      for (var j = 0; j < blocks.length; j++) {
        final block = blocks[j];
        if (block is! Map<String, dynamic>) continue;

        final blockId = block['id'] as String? ?? '';
        if (blockId.isEmpty) continue;

        final type = block['type'] as String? ?? 'main_text';
        final content = block['content'] is String
            ? block['content'] as String
            : (block['content'] != null ? jsonEncode(block['content']) : null);

        blockRows.add(
          MessageBlocksCompanion(
            blockId: Value(blockId),
            topicId: Value(topicId),
            messageId: Value(messageId),
            orderIndex: Value(j),
            type: Value(type),
            content: Value(content),
            thinkingMillsec: Value(
              (block['thinking_millsec'] as num?)?.toDouble(),
            ),
            url: Value(block['url'] as String?),
            fileJson: Value(
              block['file'] != null ? jsonEncode(block['file']) : null,
            ),
            toolJson: Value(
              block['toolId'] != null || block['toolName'] != null
                  ? jsonEncode({
                      'toolId': block['toolId'],
                      'toolName': block['toolName'],
                      'arguments': block['arguments'],
                    })
                  : null,
            ),
            errorJson: Value(
              block['error'] != null ? jsonEncode(block['error']) : null,
            ),
            targetLanguage: Value(block['targetLanguage'] as String?),
            responseJson: Value(
              block['response'] != null ? jsonEncode(block['response']) : null,
            ),
            knowledgeJson: Value(
              block['knowledge'] != null
                  ? jsonEncode(block['knowledge'])
                  : null,
            ),
            createdAt: Value(_parseTimestamp(block['createdAt'])),
          ),
        );
      }
    }

    // 批量插入
    await db.batch((b) {
      if (messageRows.isNotEmpty) {
        b.insertAll(db.messages, messageRows, mode: InsertMode.insertOrReplace);
      }
      if (blockRows.isNotEmpty) {
        b.insertAll(
          db.messageBlocks,
          blockRows,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _deleteTopicsBatch(
    ImportDatabase db,
    List<String> topicIds,
  ) async {
    if (topicIds.isEmpty) return;
    await db.transaction(() async {
      await (db.delete(
        db.messageBlocks,
      )..where((t) => t.topicId.isIn(topicIds))).go();
      await (db.delete(
        db.messages,
      )..where((t) => t.topicId.isIn(topicIds))).go();
      await (db.delete(
        db.topicAssistants,
      )..where((t) => t.topicId.isIn(topicIds))).go();
      await (db.delete(db.topics)..where((t) => t.topicId.isIn(topicIds))).go();
    });
  }

  int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) {
      final numeric = int.tryParse(value);
      if (numeric != null) return numeric;
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<http.Response> _getWithTimeout(
    Uri uri, {
    required Map<String, String> headers,
    required String timeoutMessage,
  }) async {
    try {
      return await http.get(uri, headers: headers).timeout(_requestTimeout);
    } on TimeoutException {
      throw StateError(timeoutMessage);
    }
  }

  Future<http.Response> _postWithTimeout(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    required String timeoutMessage,
  }) async {
    try {
      return await http
          .post(uri, headers: headers, body: body)
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw StateError(timeoutMessage);
    }
  }

  Future<Map<String, int>> _loadCurrentTopicVersions(ImportDatabase db) async {
    final rows = await db
        .customSelect(
          'SELECT topic_id AS topicId, updated_at AS updatedAt FROM topics',
        )
        .get();
    final out = <String, int>{};
    for (final row in rows) {
      final topicId = row.read<String>('topicId');
      final updatedAt = _toOptionalInt(row.read<dynamic>('updatedAt'));
      if (topicId.isEmpty || updatedAt == null) continue;
      out[topicId] = updatedAt;
    }
    return out;
  }

  List<ServerSyncPendingConflict> _readPendingConflicts(
    SharedPreferences prefs, {
    required String serverUrl,
    required String token,
  }) {
    final raw = prefs.getString(
      _buildScopedPendingConflictKey(serverUrl: serverUrl, token: token),
    );
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <ServerSyncPendingConflict>[];
      for (final item in decoded) {
        final parsed = ServerSyncPendingConflict.fromJson(item);
        if (parsed != null) out.add(parsed);
      }
      out.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writePendingConflicts(
    SharedPreferences prefs, {
    required String serverUrl,
    required String token,
    required List<ServerSyncPendingConflict> conflicts,
  }) async {
    final unique = <String, ServerSyncPendingConflict>{};
    for (final conflict in conflicts) {
      unique[_conflictKey(conflict.topicId, conflict.operation)] = conflict;
    }
    final sorted = unique.values.toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    await prefs.setString(
      _buildScopedPendingConflictKey(serverUrl: serverUrl, token: token),
      jsonEncode(sorted.map((item) => item.toJson()).toList()),
    );
  }

  String _conflictKey(String topicId, String operation) {
    return '$operation::$topicId';
  }

  String _buildScopedPendingConflictKey({
    required String serverUrl,
    required String token,
  }) {
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    return '$_pendingConflictsKeyPrefix:$scope';
  }

  String _buildScopedPushSnapshotKey({
    required String serverUrl,
    required String token,
  }) {
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    return '$_pushSnapshotKeyPrefix:$scope';
  }

  String _buildScopedPushVersionSnapshotKey({
    required String serverUrl,
    required String token,
  }) {
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    return '$_pushSnapshotVersionKeyPrefix:$scope';
  }

  String _buildScopedLastSyncKey({
    required String serverUrl,
    required String token,
  }) {
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    return '$_lastSyncKey:$scope';
  }

  String _buildSyncScope({required String serverUrl, required String token}) {
    final scope = sha1
        .convert(
          utf8.encode('${serverUrl.trim().toLowerCase()}|${token.trim()}'),
        )
        .toString();
    return scope;
  }
}
