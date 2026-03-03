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

class _BatchWriteOutcome {
  final int applied;
  final int noop;
  final int stale;
  final int conflict;
  final int failed;
  final Set<String> retryIds;

  const _BatchWriteOutcome({
    required this.applied,
    required this.noop,
    required this.stale,
    required this.conflict,
    required this.failed,
    required this.retryIds,
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

class _TopicRevisionMeta {
  final int revision;
  final int? updatedAt;
  final int? clientUpdatedAt;

  const _TopicRevisionMeta({
    required this.revision,
    required this.updatedAt,
    required this.clientUpdatedAt,
  });
}

/// Cherry Sync Server 同步服务
///
/// 支持：
/// 1. 增量拉取（cursor）
/// 2. 双向推送（批量 upsert）
/// 3. 冲突策略（服务端优先 / 本地优先）
class ServerSyncService {
  static const String _lastSyncKey = 'server_sync_last_timestamp';
  static const String _serverUrlKey = 'server_sync_url';
  static const String _serverTokenKey = 'server_sync_token';
  static const String _syncModeKey = 'server_sync_mode';
  static const String _conflictPolicyKey = 'server_sync_conflict_policy';
  static const String _syncIntervalSecondsKey = 'server_sync_interval_seconds';
  // 旧版本字段（分钟）保留用于迁移
  static const String _syncIntervalMinutesLegacyKey =
      'server_sync_interval_minutes';
  static const String _pendingConflictsKeyPrefix =
      'server_sync_pending_conflicts';
  // 仅用于旧版本 SharedPreferences 快照迁移。
  static const String _pushSnapshotKeyPrefix = 'server_sync_push_topic_ids';
  // 仅用于旧版本 SharedPreferences 快照迁移。
  static const String _pushSnapshotVersionKeyPrefix =
      'server_sync_push_topic_versions';
  static const String _pushSnapshotTable = 'server_sync_topic_snapshots';
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const int defaultSyncIntervalSeconds = 30 * 60;
  static const int minSyncIntervalSeconds = 5;
  static const int maxSyncIntervalSeconds = 24 * 60 * 60;
  static const int _changePageSize = 200;
  static const int _topicWriteBatchSize = 20;
  static const int _topicDeleteBatchSize = 100;
  static final Map<String, Map<String, int>>
  _pushTopicVersionsSnapshotMemoryCache = {};

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

    // 兼容旧版本：分钟字段迁移为秒
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
    if (cached.isEmpty) return cached;

    final enriched = await _enrichPendingConflictsFromServer(
      serverUrl: config.serverUrl,
      token: config.token,
      conflicts: cached,
    );
    if (_hasPendingConflictDiff(cached, enriched)) {
      await _writePendingConflicts(
        prefs,
        serverUrl: config.serverUrl,
        token: config.token,
        conflicts: enriched,
      );
    }
    return enriched;
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

    var pulledUpserted = 0;
    var pulledDeleted = 0;
    final pulledUpsertedTopicIds = <String>{};
    final pulledDeletedTopicIds = <String>{};
    var pushResult = const ServerPushResult.zero();

    final preferLocalFirst =
        mode == ServerSyncMode.autoFull &&
        conflictPolicy == ServerSyncConflictPolicy.localWins;

    if (!preferLocalFirst) {
      final pulled = await _pullIncremental(
        serverUrl: config.serverUrl,
        token: config.token,
        onStatus: onStatus,
      );
      pulledUpserted += pulled.upserted;
      pulledDeleted += pulled.deleted;
      pulledUpsertedTopicIds.addAll(pulled.upsertedTopicIds);
      pulledDeletedTopicIds.addAll(pulled.deletedTopicIds);
    }

    if (mode != ServerSyncMode.pullOnly) {
      pushResult = await _pushLocalTopics(
        serverUrl: config.serverUrl,
        token: config.token,
        mode: mode,
        conflictPolicy: conflictPolicy,
        onStatus: onStatus,
      );
    }

    if (preferLocalFirst) {
      final pulled = await _pullIncremental(
        serverUrl: config.serverUrl,
        token: config.token,
        onStatus: onStatus,
      );
      pulledUpserted += pulled.upserted;
      pulledDeleted += pulled.deleted;
      pulledUpsertedTopicIds.addAll(pulled.upsertedTopicIds);
      pulledDeletedTopicIds.addAll(pulled.deletedTopicIds);
    }

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

    if (policy == ServerSyncConflictPolicy.serverWins) {
      onStatus?.call('按服务端版本处理冲突...');
      await _refreshTopicFromServer(
        serverUrl: config.serverUrl,
        token: config.token,
        topicId: conflict.topicId,
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

      final versionSnap = await _readPushedTopicVersionsSnapshot(
        serverUrl: config.serverUrl,
        token: config.token,
      );
      versionSnap.remove(conflict.topicId);
      await _writePushedTopicVersionsSnapshot(
        serverUrl: config.serverUrl,
        token: config.token,
        topicVersions: versionSnap,
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

    final versionSnap = await _readPushedTopicVersionsSnapshot(
      serverUrl: config.serverUrl,
      token: config.token,
    );
    final localUpdatedAt = _toOptionalInt(topic['updatedAt']);
    if (localUpdatedAt != null) {
      versionSnap[conflict.topicId] = localUpdatedAt;
    }
    await _writePushedTopicVersionsSnapshot(
      serverUrl: config.serverUrl,
      token: config.token,
      topicVersions: versionSnap,
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

  /// 执行增量同步
  ///
  /// 返回 (新增/更新数, 删除数)
  Future<({int upserted, int deleted})> incrementalSync({
    void Function(String message)? onStatus,
  }) async {
    await _appDb.init();
    final config = await _resolveConfig();
    onStatus?.call('检查同步服务器连接...');
    await _probeServer(config.serverUrl, config.token);
    final pulled = await _pullIncremental(
      serverUrl: config.serverUrl,
      token: config.token,
      onStatus: onStatus,
    );
    return (upserted: pulled.upserted, deleted: pulled.deleted);
  }

  /// 重置同步状态（强制全量重新拉取）
  static Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key == _lastSyncKey || key.startsWith('$_lastSyncKey:')) {
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

  Future<
    ({
      int upserted,
      int deleted,
      Set<String> upsertedTopicIds,
      Set<String> deletedTopicIds,
    })
  >
  _pullIncremental({
    required String serverUrl,
    required String token,
    void Function(String message)? onStatus,
  }) async {
    final db = _appDb.importDb;
    final prefs = await SharedPreferences.getInstance();
    final syncCursorKey = _buildScopedLastSyncKey(
      serverUrl: serverUrl,
      token: token,
    );
    final headers = {'Authorization': 'Bearer $token'};
    var cursor = prefs.getInt(syncCursorKey) ?? 0;
    var upsertedCount = 0;
    var deletedCount = 0;
    final upsertedTopicIds = <String>{};
    final deletedTopicIds = <String>{};

    while (true) {
      onStatus?.call('正在查询变更...');
      final syncResp = await _getWithTimeout(
        Uri.parse(
          '$serverUrl/api/sync/changes?cursor=$cursor&limit=$_changePageSize&includePayload=1',
        ),
        headers: headers,
        timeoutMessage: '查询变更超时，请检查网络或服务器状态',
      );

      if (syncResp.statusCode == 401 || syncResp.statusCode == 403) {
        throw StateError('认证失败，请检查 Token');
      }
      if (syncResp.statusCode != 200) {
        throw StateError('同步服务器返回 ${syncResp.statusCode}');
      }

      final syncData = jsonDecode(syncResp.body) as Map<String, dynamic>;
      final items = (syncData['items'] as List<dynamic>? ?? const []);
      final hasMore = syncData['hasMore'] == true;
      final nextCursor = (syncData['nextCursor'] as num?)?.toInt() ?? cursor;

      if (items.isEmpty) {
        await prefs.setInt(syncCursorKey, nextCursor);
        if (!hasMore) {
          onStatus?.call(
            upsertedCount == 0 && deletedCount == 0
                ? '已是最新'
                : '拉取完成: +$upsertedCount -$deletedCount',
          );
          return (
            upserted: upsertedCount,
            deleted: deletedCount,
            upsertedTopicIds: upsertedTopicIds,
            deletedTopicIds: deletedTopicIds,
          );
        }
        cursor = nextCursor;
        continue;
      }

      final upsertPayloads = <Map<String, dynamic>>[];
      final deleteIds = <String>[];
      final failedUpserts = <String>{};
      final failedDeletes = <String>{};

      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final op = item['op'] as String? ?? '';
        final topicId = item['topicId'] as String? ?? '';
        if (topicId.isEmpty) continue;

        if (op == 'upsert') {
          final payload = item['topic'];
          if (payload is Map<String, dynamic>) {
            upsertPayloads.add(payload);
          } else {
            failedUpserts.add(topicId);
          }
        } else if (op == 'delete') {
          deleteIds.add(topicId);
        }
      }

      if (upsertPayloads.isNotEmpty || deleteIds.isNotEmpty) {
        onStatus?.call(
          '拉取到 ${upsertPayloads.length} 个新增/更新, ${deleteIds.length} 个删除',
        );
      }

      final filteredUpsertPayloads = upsertPayloads.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _filterUnchangedUpsertPayloads(db, upsertPayloads);
      final skippedUnchangedCount =
          upsertPayloads.length - filteredUpsertPayloads.length;
      if (skippedUnchangedCount > 0) {
        debugPrint(
          '[ServerSync] 跳过 $skippedUnchangedCount 个未变化话题（updatedAt/messageCount/roundCount 一致）',
        );
      }

      for (
        var i = 0;
        i < filteredUpsertPayloads.length;
        i += _topicWriteBatchSize
      ) {
        final end = i + _topicWriteBatchSize > filteredUpsertPayloads.length
            ? filteredUpsertPayloads.length
            : i + _topicWriteBatchSize;
        final chunk = filteredUpsertPayloads.sublist(i, end);

        try {
          await db.transaction(() async {
            for (final topicData in chunk) {
              await _importTopicFromServerInTransaction(db, topicData);
            }
          });
          upsertedCount += chunk.length;
          for (final topicData in chunk) {
            final topicId = topicData['topicId'] as String?;
            if (topicId != null && topicId.isNotEmpty) {
              upsertedTopicIds.add(topicId);
            }
          }
        } catch (e) {
          for (final topicData in chunk) {
            final topicId = topicData['topicId'] as String? ?? '';
            try {
              await _importTopicFromServer(db, topicData);
              upsertedCount++;
              if (topicId.isNotEmpty) {
                upsertedTopicIds.add(topicId);
              }
            } catch (inner) {
              if (topicId.isNotEmpty) failedUpserts.add(topicId);
              debugPrint('[ServerSync] Failed to write topic $topicId: $inner');
            }
          }
        }
      }

      for (var i = 0; i < deleteIds.length; i += _topicDeleteBatchSize) {
        final end = (i + _topicDeleteBatchSize).clamp(0, deleteIds.length);
        final chunk = deleteIds.sublist(i, end);
        try {
          await _deleteTopicsBatch(db, chunk);
          deletedCount += chunk.length;
          deletedTopicIds.addAll(chunk);
        } catch (e) {
          for (final topicId in chunk) {
            try {
              await _deleteTopicsBatch(db, [topicId]);
              deletedCount++;
              deletedTopicIds.add(topicId);
            } catch (inner) {
              failedDeletes.add(topicId);
              debugPrint(
                '[ServerSync] Failed to delete topic $topicId: $inner',
              );
            }
          }
        }
      }

      if (failedUpserts.isNotEmpty || failedDeletes.isNotEmpty) {
        throw StateError(
          '部分拉取失败：新增/更新失败 ${failedUpserts.length} 条，删除失败 ${failedDeletes.length} 条',
        );
      }

      cursor = nextCursor;
      await prefs.setInt(syncCursorKey, cursor);
      onStatus?.call('拉取中: +$upsertedCount -$deletedCount');

      if (!hasMore) {
        onStatus?.call('拉取完成: +$upsertedCount -$deletedCount');
        return (
          upserted: upsertedCount,
          deleted: deletedCount,
          upsertedTopicIds: upsertedTopicIds,
          deletedTopicIds: deletedTopicIds,
        );
      }
    }
  }

  Future<ServerPushResult> _pushLocalTopics({
    required String serverUrl,
    required String token,
    required ServerSyncMode mode,
    required ServerSyncConflictPolicy conflictPolicy,
    void Function(String message)? onStatus,
  }) async {
    final db = _appDb.importDb;
    final currentTopicVersions = await _loadCurrentTopicVersions(db);
    final currentTopicIds = currentTopicVersions.keys.toSet();

    final prefs = await SharedPreferences.getInstance();
    final pendingMap = <String, ServerSyncPendingConflict>{
      for (final c in _readPendingConflicts(
        prefs,
        serverUrl: serverUrl,
        token: token,
      ))
        _conflictKey(c.topicId, c.operation): c,
    };
    final previousTopicVersions = await _readPushedTopicVersionsSnapshot(
      serverUrl: serverUrl,
      token: token,
      currentTopicVersionsForLegacy: currentTopicVersions,
    );

    final changedTopicIds = currentTopicIds.where((topicId) {
      final previous = previousTopicVersions[topicId];
      final current = currentTopicVersions[topicId];
      return previous == null || previous != current;
    }).toList();
    final deletedTopicIds = previousTopicVersions.keys
        .where((topicId) => !currentTopicIds.contains(topicId))
        .toList();

    if (changedTopicIds.isEmpty && deletedTopicIds.isEmpty) {
      onStatus?.call('本地暂无可推送变更');
      return const ServerPushResult.zero();
    }

    final topics = await _buildTopicPayloadsByIds(db, changedTopicIds);
    final payloadById = <String, Map<String, dynamic>>{
      for (final topic in topics)
        if ((topic['topicId'] as String?)?.isNotEmpty ?? false)
          topic['topicId'] as String: topic,
    };

    if (topics.isNotEmpty) {
      onStatus?.call('准备推送 ${topics.length} 个本地变更话题...');
    } else {
      onStatus?.call('未发现新增/更新，正在同步删除...');
    }

    var applied = 0;
    var noop = 0;
    var stale = 0;
    var conflict = 0;
    var failed = 0;
    // 逐 topic 跟踪成功推送的 topicId，用于精细化更新快照
    final succeededUpsertTopicIds = <String>{};
    final succeededDeleteTopicIds = <String>{};

    final allowForce =
        mode == ServerSyncMode.autoFull &&
        conflictPolicy == ServerSyncConflictPolicy.localWins;
    final retryUpsertIds = <String>{};
    final retryDeleteIds = <String>{};
    final missingTopicCount = changedTopicIds.length - topics.length;
    if (missingTopicCount > 0) {
      failed += missingTopicCount;
      debugPrint('[ServerSync] $missingTopicCount 个变更话题构建 payload 失败，将计入失败项');
    }

    for (var i = 0; i < topics.length; i += _topicWriteBatchSize) {
      final end = (i + _topicWriteBatchSize).clamp(0, topics.length);
      final chunk = topics.sublist(i, end);
      onStatus?.call('推送中... $end/${topics.length}');
      final results = await _postTopicBatch(
        serverUrl: serverUrl,
        token: token,
        topics: chunk,
        force: false,
      );
      final parsed = _analyzeBatchResults(results, allowForce: allowForce);
      applied += parsed.applied;
      noop += parsed.noop;
      stale += parsed.stale;
      conflict += parsed.conflict;
      failed += parsed.failed;
      retryUpsertIds.addAll(parsed.retryIds);
      for (final result in results) {
        if (result.isTerminalSuccess) {
          succeededUpsertTopicIds.add(result.topicId);
        }
      }
      _applyResultsToPendingMap(
        pendingMap,
        results: results,
        operation: 'upsert',
        queueConflicts: !allowForce,
      );
    }

    if (deletedTopicIds.isNotEmpty) {
      onStatus?.call('正在同步 ${deletedTopicIds.length} 个本地删除...');
    }
    for (var i = 0; i < deletedTopicIds.length; i += _topicDeleteBatchSize) {
      final end = (i + _topicDeleteBatchSize).clamp(0, deletedTopicIds.length);
      final chunk = deletedTopicIds.sublist(i, end);
      final results = await _postDeleteBatch(
        serverUrl: serverUrl,
        token: token,
        topicIds: chunk,
        force: false,
      );
      final parsed = _analyzeBatchResults(results, allowForce: allowForce);
      applied += parsed.applied;
      noop += parsed.noop;
      stale += parsed.stale;
      conflict += parsed.conflict;
      failed += parsed.failed;
      retryDeleteIds.addAll(parsed.retryIds);
      for (final result in results) {
        if (result.isTerminalSuccess) {
          succeededDeleteTopicIds.add(result.topicId);
        }
      }
      _applyResultsToPendingMap(
        pendingMap,
        results: results,
        operation: 'delete',
        queueConflicts: !allowForce,
      );
    }

    if (allowForce && retryUpsertIds.isNotEmpty) {
      onStatus?.call('发现冲突，按本地优先自动回写...');
      final retryTopics = <Map<String, dynamic>>[];
      for (final id in retryUpsertIds) {
        final payload = payloadById[id];
        if (payload != null) {
          retryTopics.add(payload);
        } else {
          failed += 1;
        }
      }

      stale = 0;
      conflict = 0;
      for (var i = 0; i < retryTopics.length; i += _topicWriteBatchSize) {
        final end = (i + _topicWriteBatchSize).clamp(0, retryTopics.length);
        final chunk = retryTopics.sublist(i, end);
        final results = await _postTopicBatch(
          serverUrl: serverUrl,
          token: token,
          topics: chunk,
          force: true,
        );
        final parsed = _analyzeBatchResults(results, allowForce: false);
        applied += parsed.applied;
        noop += parsed.noop;
        stale += parsed.stale;
        conflict += parsed.conflict;
        failed += parsed.failed;
        for (final result in results) {
          if (result.isTerminalSuccess) {
            succeededUpsertTopicIds.add(result.topicId);
          }
        }
        _applyResultsToPendingMap(
          pendingMap,
          results: results,
          operation: 'upsert',
          queueConflicts: true,
        );
      }
    }

    if (allowForce && retryDeleteIds.isNotEmpty) {
      onStatus?.call('发现删除冲突，按本地优先自动回写...');
      final retryDeleteList = retryDeleteIds.toList();
      for (var i = 0; i < retryDeleteList.length; i += _topicDeleteBatchSize) {
        final end = (i + _topicDeleteBatchSize).clamp(
          0,
          retryDeleteList.length,
        );
        final chunk = retryDeleteList.sublist(i, end);
        final results = await _postDeleteBatch(
          serverUrl: serverUrl,
          token: token,
          topicIds: chunk,
          force: true,
        );
        final parsed = _analyzeBatchResults(results, allowForce: false);
        applied += parsed.applied;
        noop += parsed.noop;
        stale += parsed.stale;
        conflict += parsed.conflict;
        failed += parsed.failed;
        for (final result in results) {
          if (result.isTerminalSuccess) {
            succeededDeleteTopicIds.add(result.topicId);
          }
        }
        _applyResultsToPendingMap(
          pendingMap,
          results: results,
          operation: 'delete',
          queueConflicts: true,
        );
      }
    }

    await _writePendingConflicts(
      prefs,
      serverUrl: serverUrl,
      token: token,
      conflicts: pendingMap.values.toList(),
    );

    // 按 topic 粒度更新快照：成功推送的条目记录新版本，
    // 成功删除的条目从快照中移除。即使部分失败也保留成功部分。
    final updatedSnapshot = <String, int>{...previousTopicVersions};
    for (final topicId in succeededUpsertTopicIds) {
      final version = currentTopicVersions[topicId];
      if (version != null) {
        updatedSnapshot[topicId] = version;
      }
    }
    for (final topicId in succeededDeleteTopicIds) {
      updatedSnapshot.remove(topicId);
    }
    await _writePushedTopicVersionsSnapshot(
      serverUrl: serverUrl,
      token: token,
      topicVersions: updatedSnapshot,
      previousTopicVersions: previousTopicVersions,
    );

    onStatus?.call('推送完成: 应用$applied/无变更$noop/旧版本$stale/冲突$conflict/失败$failed');

    return ServerPushResult(
      applied: applied,
      noop: noop,
      stale: stale,
      conflict: conflict,
      failed: failed,
    );
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

  Future<List<Map<String, dynamic>>> _filterUnchangedUpsertPayloads(
    ImportDatabase db,
    List<Map<String, dynamic>> payloads,
  ) async {
    if (payloads.isEmpty) return const [];
    final topicIds = payloads
        .map((payload) => payload['topicId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (topicIds.isEmpty) return const [];

    final localTopics = await (db.select(
      db.topics,
    )..where((t) => t.topicId.isIn(topicIds))).get();
    final localById = <String, Topic>{
      for (final topic in localTopics) topic.topicId: topic,
    };

    final filtered = <Map<String, dynamic>>[];
    for (final payload in payloads) {
      final topicId = payload['topicId']?.toString() ?? '';
      if (topicId.isEmpty) {
        filtered.add(payload);
        continue;
      }

      final local = localById[topicId];
      if (local == null) {
        filtered.add(payload);
        continue;
      }

      final incomingUpdatedAt = _parseSyncTimestampOrNull(payload['updatedAt']);
      final incomingMessages = payload['messages'];
      final incomingMessageCount = incomingMessages is List
          ? incomingMessages.length
          : null;
      final incomingRoundCount = incomingMessages is List
          ? _countPayloadRounds(incomingMessages)
          : null;
      final incomingName = payload['name']?.toString();

      final unchanged =
          incomingUpdatedAt != null &&
          incomingUpdatedAt == local.updatedAt &&
          incomingMessageCount != null &&
          incomingMessageCount == local.messageCount &&
          incomingRoundCount != null &&
          incomingRoundCount == local.roundCount &&
          (incomingName == null || incomingName == local.name);

      if (!unchanged) {
        filtered.add(payload);
      }
    }

    return filtered;
  }

  int _countPayloadRounds(List<dynamic> messages) {
    var roundCount = 0;
    for (final message in messages) {
      if (message is Map<String, dynamic> && message['role'] == 'user') {
        roundCount++;
      }
    }
    return roundCount;
  }

  int? _parseSyncTimestampOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final numeric = int.tryParse(value);
      if (numeric != null) return numeric;
      final dt = DateTime.tryParse(value);
      if (dt != null) return dt.millisecondsSinceEpoch;
    }
    return null;
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

  void _applyResultsToPendingMap(
    Map<String, ServerSyncPendingConflict> pendingMap, {
    required List<_ServerTopicWriteResult> results,
    required String operation,
    required bool queueConflicts,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in results) {
      final key = _conflictKey(item.topicId, operation);
      if (item.isTerminalSuccess) {
        pendingMap.remove(key);
        continue;
      }
      if (item.isConflictLike && queueConflicts) {
        final previous = pendingMap[key];
        pendingMap[key] = ServerSyncPendingConflict(
          topicId: item.topicId,
          operation: operation,
          status: item.status,
          detectedAt: previous?.detectedAt ?? now,
          reason:
              item.error ??
              previous?.reason ??
              (item.status == 'stale' ? 'stale' : 'conflict'),
          localUpdatedAt: item.localUpdatedAt ?? previous?.localUpdatedAt,
          serverRevision: item.revision ?? previous?.serverRevision,
          serverUpdatedAt: item.serverUpdatedAt ?? previous?.serverUpdatedAt,
          serverClientUpdatedAt:
              item.serverClientUpdatedAt ?? previous?.serverClientUpdatedAt,
        );
      }
    }
  }

  Future<List<ServerSyncPendingConflict>> _enrichPendingConflictsFromServer({
    required String serverUrl,
    required String token,
    required List<ServerSyncPendingConflict> conflicts,
  }) async {
    final out = <ServerSyncPendingConflict>[];
    for (final conflict in conflicts) {
      if (conflict.serverRevision != null && conflict.serverUpdatedAt != null) {
        out.add(conflict);
        continue;
      }

      try {
        final revision = await _getTopicRevision(
          serverUrl: serverUrl,
          token: token,
          topicId: conflict.topicId,
        );
        if (revision == null) {
          out.add(conflict);
          continue;
        }
        out.add(
          ServerSyncPendingConflict(
            topicId: conflict.topicId,
            operation: conflict.operation,
            status: conflict.status,
            detectedAt: conflict.detectedAt,
            reason: conflict.reason,
            localUpdatedAt: conflict.localUpdatedAt,
            serverRevision: revision.revision,
            serverUpdatedAt: revision.updatedAt,
            serverClientUpdatedAt: revision.clientUpdatedAt,
          ),
        );
      } catch (_) {
        out.add(conflict);
      }
    }
    return out;
  }

  bool _hasPendingConflictDiff(
    List<ServerSyncPendingConflict> a,
    List<ServerSyncPendingConflict> b,
  ) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (_conflictKey(a[i].topicId, a[i].operation) !=
          _conflictKey(b[i].topicId, b[i].operation)) {
        return true;
      }
      if (a[i].serverRevision != b[i].serverRevision ||
          a[i].serverUpdatedAt != b[i].serverUpdatedAt ||
          a[i].serverClientUpdatedAt != b[i].serverClientUpdatedAt ||
          a[i].reason != b[i].reason ||
          a[i].status != b[i].status ||
          a[i].localUpdatedAt != b[i].localUpdatedAt) {
        return true;
      }
    }
    return false;
  }

  _BatchWriteOutcome _analyzeBatchResults(
    List<_ServerTopicWriteResult> results, {
    required bool allowForce,
  }) {
    var applied = 0;
    var noop = 0;
    var stale = 0;
    var conflict = 0;
    var failed = 0;
    final retryIds = <String>{};

    for (final item in results) {
      switch (item.status) {
        case 'applied':
          applied += 1;
          break;
        case 'noop':
        case 'not_found':
          noop += 1;
          break;
        case 'stale':
          if (allowForce) {
            retryIds.add(item.topicId);
          } else {
            stale += 1;
          }
          break;
        case 'conflict':
          if (allowForce) {
            retryIds.add(item.topicId);
          } else {
            conflict += 1;
          }
          break;
        default:
          failed += 1;
      }
    }

    return _BatchWriteOutcome(
      applied: applied,
      noop: noop,
      stale: stale,
      conflict: conflict,
      failed: failed,
      retryIds: retryIds,
    );
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

  Future<_TopicRevisionMeta?> _getTopicRevision({
    required String serverUrl,
    required String token,
    required String topicId,
  }) async {
    final resp = await _getWithTimeout(
      Uri.parse('$serverUrl/api/topics/$topicId/revision'),
      headers: {'Authorization': 'Bearer $token'},
      timeoutMessage: '读取服务端版本超时，请检查网络或服务器状态',
    );

    if (resp.statusCode == 404) return null;
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw StateError('认证失败，请检查 Token');
    }
    if (resp.statusCode != 200) {
      throw StateError('读取服务端版本失败：HTTP ${resp.statusCode}');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) return null;
    return _TopicRevisionMeta(
      revision: _toOptionalInt(decoded['revision']) ?? 0,
      updatedAt: _toOptionalInt(decoded['updatedAt']),
      clientUpdatedAt: _toOptionalInt(decoded['clientUpdatedAt']),
    );
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
  //
  // 复用 DriftDataImportService._importTopic 的逻辑，但适配服务端 API 格式。
  // 服务端返回的数据中 blocks 已内联在 messages 中，无需外部 blockMap。

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

    // 先清除旧数据（因为是 Topic 级别整体覆盖）
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

  Future<Map<String, int>> _readPushedTopicVersionsSnapshot({
    required String serverUrl,
    required String token,
    Map<String, int>? currentTopicVersionsForLegacy,
  }) async {
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    final cached = _pushTopicVersionsSnapshotMemoryCache[scope];
    if (cached != null) return {...cached};

    final db = _appDb.userDb;
    final rows = await db
        .customSelect(
          'SELECT topic_id AS topicId, updated_at AS updatedAt '
          'FROM $_pushSnapshotTable WHERE scope = ?',
          variables: [Variable<String>(scope)],
        )
        .get();
    if (rows.isNotEmpty) {
      final out = <String, int>{};
      for (final row in rows) {
        final topicId = row.read<String>('topicId');
        final updatedAt = _toOptionalInt(row.read<dynamic>('updatedAt'));
        if (topicId.isEmpty || updatedAt == null) continue;
        out[topicId] = updatedAt;
      }
      _pushTopicVersionsSnapshotMemoryCache[scope] = {...out};
      return out;
    }

    final migrated = await _migrateLegacyPushedSnapshotFromPrefs(
      scope: scope,
      serverUrl: serverUrl,
      token: token,
      currentTopicVersionsForLegacy: currentTopicVersionsForLegacy,
    );
    _pushTopicVersionsSnapshotMemoryCache[scope] = {...migrated};
    return migrated;
  }

  Future<Map<String, int>> _migrateLegacyPushedSnapshotFromPrefs({
    required String scope,
    required String serverUrl,
    required String token,
    Map<String, int>? currentTopicVersionsForLegacy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final legacyVersionKey = _buildScopedPushVersionSnapshotKey(
      serverUrl: serverUrl,
      token: token,
    );
    final legacyIdsKey = _buildScopedPushSnapshotKey(
      serverUrl: serverUrl,
      token: token,
    );

    final parsedVersions = _readLegacyPushedTopicVersionsFromPrefs(
      prefs,
      scopedVersionKey: legacyVersionKey,
    );
    if (parsedVersions.isNotEmpty) {
      await _replacePushedTopicVersionsSnapshot(
        scope: scope,
        topicVersions: parsedVersions,
      );
      await prefs.remove(legacyVersionKey);
      await prefs.remove(legacyIdsKey);
      return parsedVersions;
    }

    final legacyIds = _readLegacyPushedTopicIdsFromPrefs(
      prefs,
      scopedIdsKey: legacyIdsKey,
    );
    if (legacyIds.isEmpty) {
      await prefs.remove(legacyVersionKey);
      await prefs.remove(legacyIdsKey);
      return const <String, int>{};
    }

    final migrated = <String, int>{};
    for (final topicId in legacyIds) {
      final currentVersion = currentTopicVersionsForLegacy?[topicId];
      migrated[topicId] = currentVersion ?? 0;
    }
    await _replacePushedTopicVersionsSnapshot(
      scope: scope,
      topicVersions: migrated,
    );
    await prefs.remove(legacyVersionKey);
    await prefs.remove(legacyIdsKey);
    return migrated;
  }

  Map<String, int> _readLegacyPushedTopicVersionsFromPrefs(
    SharedPreferences prefs, {
    required String scopedVersionKey,
  }) {
    final raw = prefs.getString(scopedVersionKey);
    if (raw == null || raw.isEmpty) return const <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, int>{};
      final out = <String, int>{};
      decoded.forEach((key, value) {
        final topicId = key.toString().trim();
        if (topicId.isEmpty) return;
        final version = _toOptionalInt(value);
        if (version != null) {
          out[topicId] = version;
        }
      });
      return out;
    } catch (_) {
      return const <String, int>{};
    }
  }

  Set<String> _readLegacyPushedTopicIdsFromPrefs(
    SharedPreferences prefs, {
    required String scopedIdsKey,
  }) {
    final raw = prefs.getString(scopedIdsKey);
    if (raw == null || raw.isEmpty) return const <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>{};
      return decoded
          .map((item) => item.toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return const <String>{};
    }
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

  Future<void> _writePushedTopicVersionsSnapshot({
    required String serverUrl,
    required String token,
    required Map<String, int> topicVersions,
    Map<String, int>? previousTopicVersions,
  }) async {
    final scope = _buildSyncScope(serverUrl: serverUrl, token: token);
    final normalized = <String, int>{
      for (final entry in topicVersions.entries)
        if (entry.key.trim().isNotEmpty) entry.key.trim(): entry.value,
    };
    final previous =
        previousTopicVersions ??
        await _readPushedTopicVersionsSnapshot(
          serverUrl: serverUrl,
          token: token,
        );
    final removedTopicIds = previous.keys
        .where((topicId) => !normalized.containsKey(topicId))
        .toList();
    final changedEntries = normalized.entries
        .where((entry) => previous[entry.key] != entry.value)
        .toList(growable: false);

    if (removedTopicIds.isEmpty && changedEntries.isEmpty) {
      _pushTopicVersionsSnapshotMemoryCache[scope] = {...normalized};
      return;
    }

    final db = _appDb.userDb;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction(() async {
      await _deletePushedTopicVersionRows(
        db: db,
        scope: scope,
        topicIds: removedTopicIds,
      );
      if (changedEntries.isNotEmpty) {
        await db.batch((batch) {
          for (final entry in changedEntries) {
            batch.customStatement(
              'INSERT INTO $_pushSnapshotTable(scope, topic_id, updated_at, synced_at) '
              'VALUES (?, ?, ?, ?) '
              'ON CONFLICT(scope, topic_id) DO UPDATE SET '
              'updated_at = excluded.updated_at, synced_at = excluded.synced_at',
              [scope, entry.key, entry.value, now],
            );
          }
        });
      }
    });
    _pushTopicVersionsSnapshotMemoryCache[scope] = {...normalized};
  }

  Future<void> _replacePushedTopicVersionsSnapshot({
    required String scope,
    required Map<String, int> topicVersions,
  }) async {
    final db = _appDb.userDb;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction(() async {
      await db.customStatement(
        'DELETE FROM $_pushSnapshotTable WHERE scope = ?',
        [scope],
      );
      if (topicVersions.isEmpty) return;
      await db.batch((batch) {
        for (final entry in topicVersions.entries) {
          if (entry.key.trim().isEmpty) continue;
          batch.customStatement(
            'INSERT INTO $_pushSnapshotTable(scope, topic_id, updated_at, synced_at) '
            'VALUES (?, ?, ?, ?)',
            [scope, entry.key.trim(), entry.value, now],
          );
        }
      });
    });
  }

  Future<void> _deletePushedTopicVersionRows({
    required UserDatabase db,
    required String scope,
    required List<String> topicIds,
  }) async {
    if (topicIds.isEmpty) return;
    const chunkSize = 300;
    for (var i = 0; i < topicIds.length; i += chunkSize) {
      final end = i + chunkSize > topicIds.length
          ? topicIds.length
          : i + chunkSize;
      final chunk = topicIds.sublist(i, end);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      await db.customStatement(
        'DELETE FROM $_pushSnapshotTable '
        'WHERE scope = ? AND topic_id IN ($placeholders)',
        [scope, ...chunk],
      );
    }
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
