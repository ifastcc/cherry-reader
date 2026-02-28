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
  final ServerPushResult push;
  final ServerSyncMode mode;
  final ServerSyncConflictPolicy conflictPolicy;

  const ServerSyncResult({
    required this.pulledUpserted,
    required this.pulledDeleted,
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
  static const String _pushSnapshotKeyPrefix = 'server_sync_push_topic_ids';
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const int defaultSyncIntervalSeconds = 30 * 60;
  static const int minSyncIntervalSeconds = 5;
  static const int maxSyncIntervalSeconds = 24 * 60 * 60;
  static const int _changePageSize = 200;
  static const int _topicWriteBatchSize = 20;
  static const int _topicDeleteBatchSize = 100;

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
    }

    final result = ServerSyncResult(
      pulledUpserted: pulledUpserted,
      pulledDeleted: pulledDeleted,
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

      final snap = _readPushedTopicIdsSnapshot(
        prefs,
        serverUrl: config.serverUrl,
        token: config.token,
      );
      snap.remove(conflict.topicId);
      await _writePushedTopicIdsSnapshot(
        prefs,
        serverUrl: config.serverUrl,
        token: config.token,
        topicIds: snap,
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

    final snap = _readPushedTopicIdsSnapshot(
      prefs,
      serverUrl: config.serverUrl,
      token: config.token,
    );
    snap.add(conflict.topicId);
    await _writePushedTopicIdsSnapshot(
      prefs,
      serverUrl: config.serverUrl,
      token: config.token,
      topicIds: snap,
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
    return _pullIncremental(
      serverUrl: config.serverUrl,
      token: config.token,
      onStatus: onStatus,
    );
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

  Future<({int upserted, int deleted})> _pullIncremental({
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
          return (upserted: upsertedCount, deleted: deletedCount);
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

      for (var i = 0; i < upsertPayloads.length; i += _topicWriteBatchSize) {
        final end = (i + _topicWriteBatchSize).clamp(0, upsertPayloads.length);
        final chunk = upsertPayloads.sublist(i, end);

        try {
          await db.transaction(() async {
            for (final topicData in chunk) {
              await _importTopicFromServerInTransaction(db, topicData);
            }
          });
          upsertedCount += chunk.length;
        } catch (e) {
          for (final topicData in chunk) {
            final topicId = topicData['topicId'] as String? ?? '';
            try {
              await _importTopicFromServer(db, topicData);
              upsertedCount++;
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
        } catch (e) {
          for (final topicId in chunk) {
            try {
              await _deleteTopicsBatch(db, [topicId]);
              deletedCount++;
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
        return (upserted: upsertedCount, deleted: deletedCount);
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
    final topics = await _buildAllTopicPayloads(db);
    final payloadById = <String, Map<String, dynamic>>{};
    for (final topic in topics) {
      final topicId = topic['topicId'] as String?;
      if (topicId != null && topicId.isNotEmpty) {
        payloadById[topicId] = topic;
      }
    }
    final currentTopicIds = payloadById.keys.toSet();

    final prefs = await SharedPreferences.getInstance();
    final pendingMap = <String, ServerSyncPendingConflict>{
      for (final c in _readPendingConflicts(
        prefs,
        serverUrl: serverUrl,
        token: token,
      ))
        _conflictKey(c.topicId, c.operation): c,
    };
    final previousTopicIds = _readPushedTopicIdsSnapshot(
      prefs,
      serverUrl: serverUrl,
      token: token,
    );
    final deletedTopicIds = previousTopicIds
        .difference(currentTopicIds)
        .toList();

    if (topics.isEmpty && deletedTopicIds.isEmpty) {
      onStatus?.call('本地暂无可推送变更');
      return const ServerPushResult.zero();
    }

    if (topics.isNotEmpty) {
      onStatus?.call('准备推送 ${topics.length} 个本地话题...');
    } else {
      onStatus?.call('未发现新增/更新，正在同步删除...');
    }

    var applied = 0;
    var noop = 0;
    var stale = 0;
    var conflict = 0;
    var failed = 0;

    final allowForce =
        mode == ServerSyncMode.autoFull &&
        conflictPolicy == ServerSyncConflictPolicy.localWins;
    final retryUpsertIds = <String>{};
    final retryDeleteIds = <String>{};

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

    if (failed == 0) {
      await _writePushedTopicIdsSnapshot(
        prefs,
        serverUrl: serverUrl,
        token: token,
        topicIds: currentTopicIds,
      );
    }

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
    final topic = decoded['data'];
    if (topic is! Map<String, dynamic>) {
      throw StateError('拉取服务端话题失败：缺少 topic data');
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
    final all = await _buildAllTopicPayloads(db);
    for (final topic in all) {
      if (topic['topicId'] == topicId) {
        return topic;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _buildAllTopicPayloads(
    ImportDatabase db,
  ) async {
    final topics = await (db.select(
      db.topics,
    )..orderBy([(t) => OrderingTerm.asc(t.updatedAt)])).get();
    if (topics.isEmpty) return const [];

    final assistants = await db.select(db.assistants).get();
    final assistantNameById = {
      for (final row in assistants) row.assistantId: row.name,
    };

    final links =
        await (db.select(db.topicAssistants)..orderBy([
              (t) => OrderingTerm.asc(t.topicId),
              (t) => OrderingTerm.asc(t.assistantId),
            ]))
            .get();
    final topicAssistantByTopicId = <String, String>{};
    for (final link in links) {
      topicAssistantByTopicId.putIfAbsent(link.topicId, () => link.assistantId);
    }

    final messages =
        await (db.select(db.messages)..orderBy([
              (t) => OrderingTerm.asc(t.topicId),
              (t) => OrderingTerm.asc(t.orderIndex),
            ]))
            .get();
    final blocks =
        await (db.select(db.messageBlocks)..orderBy([
              (t) => OrderingTerm.asc(t.messageId),
              (t) => OrderingTerm.asc(t.orderIndex),
            ]))
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

      payloads.add({
        'topicId': topic.topicId,
        'name': topic.name,
        'assistantId': assistantId,
        'assistantName': assistantName,
        'createdAt': topic.createdAt,
        'updatedAt': topic.updatedAt,
        'messages': messagePayloads,
      });
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

  Set<String> _readPushedTopicIdsSnapshot(
    SharedPreferences prefs, {
    required String serverUrl,
    required String token,
  }) {
    final raw = prefs.getString(
      _buildScopedPushSnapshotKey(serverUrl: serverUrl, token: token),
    );
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

  Future<void> _writePushedTopicIdsSnapshot(
    SharedPreferences prefs, {
    required String serverUrl,
    required String token,
    required Set<String> topicIds,
  }) async {
    await prefs.setString(
      _buildScopedPushSnapshotKey(serverUrl: serverUrl, token: token),
      jsonEncode(topicIds.toList()..sort()),
    );
  }

  String _conflictKey(String topicId, String operation) {
    return '$operation::$topicId';
  }

  String _buildScopedPendingConflictKey({
    required String serverUrl,
    required String token,
  }) {
    final scope = sha1
        .convert(
          utf8.encode('${serverUrl.trim().toLowerCase()}|${token.trim()}'),
        )
        .toString();
    return '$_pendingConflictsKeyPrefix:$scope';
  }

  String _buildScopedPushSnapshotKey({
    required String serverUrl,
    required String token,
  }) {
    final scope = sha1
        .convert(
          utf8.encode('${serverUrl.trim().toLowerCase()}|${token.trim()}'),
        )
        .toString();
    return '$_pushSnapshotKeyPrefix:$scope';
  }

  String _buildScopedLastSyncKey({
    required String serverUrl,
    required String token,
  }) {
    final scope = sha1
        .convert(
          utf8.encode('${serverUrl.trim().toLowerCase()}|${token.trim()}'),
        )
        .toString();
    return '$_lastSyncKey:$scope';
  }
}
