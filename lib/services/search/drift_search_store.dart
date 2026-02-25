import 'package:drift/drift.dart';

import '../app_db.dart';
import '../drift/app_database.dart';
import '../../models/domain/search_hits.dart';
import 'i_search_store.dart';

class DriftSearchStore implements ISearchStore {
  final AppDb _db;

  DriftSearchStore(this._db);

  ImportDatabase get _sql => _db.importDb;

  @override
  Future<List<TopicNameHit>> searchTopicNames(
    String keyword, {
    int limit = 50,
  }) async {
    final lowerKeyword = keyword.toLowerCase();

    final topics = await (_sql.select(_sql.topics)
          ..where((t) => t.name.lower().like('%$lowerKeyword%'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();

    if (topics.isEmpty) return [];

    final topicIds = topics.map((t) => t.topicId).toList();
    final topicToAssistantIds = await _getTopicAssistantIds(topicIds);
    final assistantIds =
        topicToAssistantIds.values.expand((e) => e).toSet().toList();
    final assistantNameMap = await _getAssistantNameMap(assistantIds);
    final contentPreviews = await _getTopicContentPreviews(topicIds);

    return topics.map((topic) {
      final assistantIdsForTopic =
          topicToAssistantIds[topic.topicId] ?? const <String>[];
      final assistantNames = assistantIdsForTopic
          .map((id) => assistantNameMap[id] ?? '未知助手')
          .toList();

      return TopicNameHit(
        topicId: topic.topicId,
        topicName: topic.name,
        createdAt: topic.createdAt,
        assistantIds: assistantIdsForTopic,
        assistantNames: assistantNames,
        contentPreview: contentPreviews[topic.topicId],
      );
    }).toList();
  }

  @override
  Future<List<MessageContentHit>> searchMessageContent(
    String keyword, {
    int limit = 100,
  }) async {
    final lowerKeyword = keyword.toLowerCase();

    final blocks = await (_sql.select(_sql.messageBlocks)
          ..where(
            (t) =>
                t.type.equals('main_text') &
                t.content.isNotNull() &
                t.content.lower().like('%$lowerKeyword%'),
          )
          ..limit(limit))
        .get();

    if (blocks.isEmpty) return [];

    final messageIds = blocks.map((b) => b.messageId).toSet().toList();
    final messages = await (_sql.select(_sql.messages)
          ..where((t) => t.messageId.isIn(messageIds)))
        .get();
    final messageMap = {for (final m in messages) m.messageId: m};

    final topicIds = blocks.map((b) => b.topicId).toSet().toList();
    final topics = await (_sql.select(_sql.topics)
          ..where((t) => t.topicId.isIn(topicIds)))
        .get();
    final topicMap = {for (final t in topics) t.topicId: t};

    final topicToAssistantIds = await _getTopicAssistantIds(topicIds);
    final assistantIds =
        topicToAssistantIds.values.expand((e) => e).toSet().toList();
    final assistantNameMap = await _getAssistantNameMap(assistantIds);

    final hits = <MessageContentHit>[];
    for (final block in blocks) {
      final content = block.content ?? '';
      if (content.isEmpty) continue;

      final message = messageMap[block.messageId];
      final topic = topicMap[block.topicId];
      if (topic == null) continue;

      final assistantIdsForTopic =
          topicToAssistantIds[topic.topicId] ?? const <String>[];
      final assistantNames = assistantIdsForTopic
          .map((id) => assistantNameMap[id] ?? '未知助手')
          .toList();

      hits.add(
        MessageContentHit(
          blockId: block.blockId,
          topicId: block.topicId,
          topicName: topic.name,
          messageId: block.messageId,
          role: message?.role,
          modelName: message?.modelName,
          roundIndex: message?.roundIndex,
          createdAt: block.createdAt,
          content: content,
          assistantIds: assistantIdsForTopic,
          assistantNames: assistantNames,
        ),
      );
    }

    hits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return hits;
  }

  Future<Map<String, String>> _getTopicContentPreviews(
    List<String> topicIds,
  ) async {
    if (topicIds.isEmpty) return {};

    final previews = <String, String>{};

    for (final topicId in topicIds) {
      final firstMessage = await (_sql.select(_sql.messages)
            ..where((t) => t.topicId.equals(topicId))
            ..orderBy([(t) => OrderingTerm.asc(t.roundIndex)])
            ..limit(1))
          .getSingleOrNull();

      if (firstMessage == null) continue;

      final blocks = await (_sql.select(_sql.messageBlocks)
            ..where((t) =>
                t.messageId.equals(firstMessage.messageId) &
                t.type.equals('main_text'))
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

      if (blocks.isEmpty) continue;

      final content = blocks.map((b) => b.content ?? '').join().trim();
      if (content.isEmpty) continue;

      previews[topicId] = content.length > 100 ? '${content.substring(0, 100)}...' : content;
    }

    return previews;
  }

  Future<Map<String, List<String>>> _getTopicAssistantIds(
    List<String> topicIds,
  ) async {
    if (topicIds.isEmpty) return {};
    final rows = await (_sql.select(_sql.topicAssistants)
          ..where((t) => t.topicId.isIn(topicIds)))
        .get();
    final out = <String, List<String>>{};
    for (final row in rows) {
      out.putIfAbsent(row.topicId, () => []).add(row.assistantId);
    }
    return out;
  }

  Future<Map<String, String>> _getAssistantNameMap(
    List<String> assistantIds,
  ) async {
    if (assistantIds.isEmpty) return {};
    final rows = await (_sql.select(_sql.assistants)
          ..where((t) => t.assistantId.isIn(assistantIds)))
        .get();
    return {for (final a in rows) a.assistantId: a.name};
  }
}
