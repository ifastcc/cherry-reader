import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_db.dart';
import '../drift/app_database.dart';

/// Cherry Sync Server 增量同步服务
///
/// 从自建同步服务器增量拉取 Topic 数据，写入本地 Drift DB。
/// 每次同步只拉取上次同步时间之后的变更。
class ServerSyncService {
  static const String _lastSyncKey = 'server_sync_last_timestamp';
  static const String _serverUrlKey = 'server_sync_url';
  static const String _serverTokenKey = 'server_sync_token';

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
    await prefs.setString(_serverUrlKey, serverUrl.replaceAll(RegExp(r'/+$'), ''));
    await prefs.setString(_serverTokenKey, token);
  }

  static Future<bool> get isConfigured async {
    final url = await getServerUrl();
    return url.isNotEmpty;
  }

  // ── 增量同步 ──────────────────────────────────────────────────────

  /// 执行增量同步
  ///
  /// 返回 (新增/更新数, 删除数)
  Future<({int upserted, int deleted})> incrementalSync({
    void Function(String message)? onStatus,
  }) async {
    await _appDb.init();
    final db = _appDb.importDb;

    final serverUrl = await getServerUrl();
    final token = await getServerToken();
    if (serverUrl.isEmpty) {
      throw StateError('同步服务器未配置');
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;

    onStatus?.call('正在查询变更...');

    // 1. 拉取变更列表
    final syncResp = await http.get(
      Uri.parse('$serverUrl/api/sync?since=$lastSync'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (syncResp.statusCode == 401) {
      throw StateError('认证失败，请检查 Token');
    }
    if (syncResp.statusCode != 200) {
      throw StateError('同步服务器返回 ${syncResp.statusCode}');
    }

    final syncData = jsonDecode(syncResp.body) as Map<String, dynamic>;
    final upserts = (syncData['upserts'] as List).cast<String>();
    final deletes = (syncData['deletes'] as List).cast<String>();
    final serverTime = syncData['serverTime'] as int;

    if (upserts.isEmpty && deletes.isEmpty) {
      onStatus?.call('已是最新');
      await prefs.setInt(_lastSyncKey, serverTime);
      return (upserted: 0, deleted: 0);
    }

    onStatus?.call('发现 ${upserts.length} 个新增/更新, ${deletes.length} 个删除');

    // 2. 拉取并写入新增/更新的 Topic
    int upsertedCount = 0;
    for (final topicId in upserts) {
      try {
        onStatus?.call('正在同步 ${upsertedCount + 1}/${upserts.length}...');

        final topicResp = await http.get(
          Uri.parse('$serverUrl/api/topics/$topicId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (topicResp.statusCode != 200) continue;

        final row = jsonDecode(topicResp.body) as Map<String, dynamic>;
        final topicData = row['data'] as Map<String, dynamic>;

        await _importTopicFromServer(db, topicData);
        upsertedCount++;
      } catch (e) {
        // 单个 Topic 失败不影响整体同步
        print('[ServerSync] Failed to sync topic $topicId: $e');
      }
    }

    // 3. 删除已删除的 Topic
    int deletedCount = 0;
    for (final topicId in deletes) {
      try {
        await db.transaction(() async {
          await (db.delete(db.messageBlocks)..where((t) => t.topicId.equals(topicId))).go();
          await (db.delete(db.messages)..where((t) => t.topicId.equals(topicId))).go();
          await (db.delete(db.topicAssistants)..where((t) => t.topicId.equals(topicId))).go();
          await (db.delete(db.topics)..where((t) => t.topicId.equals(topicId))).go();
        });
        deletedCount++;
      } catch (e) {
        print('[ServerSync] Failed to delete topic $topicId: $e');
      }
    }

    // 4. 保存同步时间戳
    await prefs.setInt(_lastSyncKey, serverTime);

    onStatus?.call('同步完成: +$upsertedCount -$deletedCount');

    return (upserted: upsertedCount, deleted: deletedCount);
  }

  /// 重置同步状态（强制全量重新拉取）
  static Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
  }

  // ── 数据写入 ──────────────────────────────────────────────────────
  //
  // 复用 DriftDataImportService._importTopic 的逻辑，但适配服务端 API 格式。
  // 服务端返回的数据中 blocks 已内联在 messages 中，无需外部 blockMap。

  Future<void> _importTopicFromServer(
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

    await db.transaction(() async {
      // 写入 Assistant（如果有）
      if (assistantId != null && assistantId.isNotEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.into(db.assistants).insertOnConflictUpdate(
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
      await (db.delete(db.messageBlocks)..where((t) => t.topicId.equals(topicId))).go();
      await (db.delete(db.messages)..where((t) => t.topicId.equals(topicId))).go();

      // 写入 Topic
      await db.into(db.topics).insertOnConflictUpdate(
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
      await (db.delete(db.topicAssistants)..where((t) => t.topicId.equals(topicId))).go();
      if (assistantId != null && assistantId.isNotEmpty) {
        await db.into(db.topicAssistants).insertOnConflictUpdate(
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
            usageJson: Value(msg['usage'] != null ? jsonEncode(msg['usage']) : null),
            metricsJson: Value(msg['metrics'] != null ? jsonEncode(msg['metrics']) : null),
            mentionsJson: Value(msg['mentions'] != null ? jsonEncode(msg['mentions']) : null),
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
              thinkingMillsec: Value((block['thinking_millsec'] as num?)?.toDouble()),
              url: Value(block['url'] as String?),
              fileJson: Value(block['file'] != null ? jsonEncode(block['file']) : null),
              toolJson: Value(
                block['toolId'] != null || block['toolName'] != null
                    ? jsonEncode({
                        'toolId': block['toolId'],
                        'toolName': block['toolName'],
                        'arguments': block['arguments'],
                      })
                    : null,
              ),
              errorJson: Value(block['error'] != null ? jsonEncode(block['error']) : null),
              targetLanguage: Value(block['targetLanguage'] as String?),
              responseJson: Value(block['response'] != null ? jsonEncode(block['response']) : null),
              knowledgeJson: Value(block['knowledge'] != null ? jsonEncode(block['knowledge']) : null),
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
          b.insertAll(db.messageBlocks, blockRows, mode: InsertMode.insertOrReplace);
        }
      });
    });
  }

  int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}
