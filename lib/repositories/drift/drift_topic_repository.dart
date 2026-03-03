import 'package:drift/drift.dart';

import '../../models/domain/topic_model.dart';
import '../../services/drift/app_database.dart';
import '../i_topic_repository.dart';

class DriftTopicRepository implements ITopicRepository {
  final ImportDatabase _db;

  DriftTopicRepository(this._db);

  Future<List<String>> _getAssistantIdsForTopic(String topicId) async {
    final rows = await (_db.select(_db.topicAssistants)
          ..where((t) => t.topicId.equals(topicId)))
        .get();
    return rows.map((r) => r.assistantId).toList();
  }

  TopicModel _toModel(Topic row, List<String> assistantIds) {
    return TopicModel(
      topicId: row.topicId,
      name: row.name,
      assistantIds: assistantIds,
      messageCount: row.messageCount,
      roundCount: row.roundCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<TopicModel?> getTopic(String topicId) async {
    final topic = await (_db.select(_db.topics)
          ..where((t) => t.topicId.equals(topicId))
          ..limit(1))
        .getSingleOrNull();
    if (topic == null) return null;
    final assistantIds = await _getAssistantIdsForTopic(topicId);
    return _toModel(topic, assistantIds);
  }

  @override
  Future<List<TopicModel>> getAllTopics() async {
    final topics = await (_db.select(_db.topics)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    if (topics.isEmpty) return [];

    final topicIds = topics.map((t) => t.topicId).toList();
    final links = await (_db.select(_db.topicAssistants)
          ..where((t) => t.topicId.isIn(topicIds)))
        .get();
    final topicToAssistantIds = <String, List<String>>{};
    for (final link in links) {
      topicToAssistantIds
          .putIfAbsent(link.topicId, () => [])
          .add(link.assistantId);
    }

    return topics
        .map((t) => _toModel(t, topicToAssistantIds[t.topicId] ?? const []))
        .toList();
  }

  @override
  Future<List<TopicModel>> getTopicsByIds(List<String> topicIds) async {
    if (topicIds.isEmpty) return [];

    final topics = await (_db.select(_db.topics)
          ..where((t) => t.topicId.isIn(topicIds))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    if (topics.isEmpty) return [];

    final links = await (_db.select(_db.topicAssistants)
          ..where((t) => t.topicId.isIn(topicIds)))
        .get();
    final topicToAssistantIds = <String, List<String>>{};
    for (final link in links) {
      topicToAssistantIds
          .putIfAbsent(link.topicId, () => [])
          .add(link.assistantId);
    }

    return topics
        .map((t) => _toModel(t, topicToAssistantIds[t.topicId] ?? const []))
        .toList();
  }

  @override
  Future<List<TopicModel>> getTopicsByAssistant(String assistantId) async {
    final linkRows = await (_db.select(_db.topicAssistants)
          ..where((t) => t.assistantId.equals(assistantId)))
        .get();
    if (linkRows.isEmpty) return [];

    final topicIds = linkRows.map((e) => e.topicId).toList();
    final topics = await (_db.select(_db.topics)
          ..where((t) => t.topicId.isIn(topicIds))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    final topicToAssistantIds = <String, List<String>>{};
    for (final link in linkRows) {
      topicToAssistantIds
          .putIfAbsent(link.topicId, () => [])
          .add(link.assistantId);
    }

    return topics
        .map((t) => _toModel(t, topicToAssistantIds[t.topicId] ?? const []))
        .toList();
  }

  @override
  Future<int> getTopicCount() async {
    final countExp = _db.topics.topicId.count();
    final row = await (_db.selectOnly(_db.topics)..addColumns([countExp]))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<int> getTopicCountByAssistant(String assistantId) async {
    final countExp = _db.topicAssistants.topicId.count(distinct: true);
    final row = await (_db.selectOnly(_db.topicAssistants)
          ..addColumns([countExp])
          ..where(_db.topicAssistants.assistantId.equals(assistantId)))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> _replaceTopicAssistants(
    String topicId,
    List<String> assistantIds,
  ) async {
    await (_db.delete(_db.topicAssistants)
          ..where((t) => t.topicId.equals(topicId)))
        .go();
    if (assistantIds.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(
        _db.topicAssistants,
        assistantIds
            .map(
              (aid) => TopicAssistantsCompanion(
                topicId: Value(topicId),
                assistantId: Value(aid),
              ),
            )
            .toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  @override
  Future<void> saveTopic(TopicModel topic) async {
    await _db.transaction(() async {
      await _db.into(_db.topics).insertOnConflictUpdate(
            TopicsCompanion(
              topicId: Value(topic.topicId),
              name: Value(topic.name),
              messageCount: Value(topic.messageCount),
              roundCount: Value(topic.roundCount),
              createdAt: Value(topic.createdAt),
              updatedAt: Value(topic.updatedAt),
            ),
          );
      await _replaceTopicAssistants(topic.topicId, topic.assistantIds);
    });
  }

  @override
  Future<void> saveTopics(List<TopicModel> topics) async {
    if (topics.isEmpty) return;
    await _db.transaction(() async {
      await _db.batch((b) {
        b.insertAll(
          _db.topics,
          topics
              .map(
                (t) => TopicsCompanion(
                  topicId: Value(t.topicId),
                  name: Value(t.name),
                  messageCount: Value(t.messageCount),
                  roundCount: Value(t.roundCount),
                  createdAt: Value(t.createdAt),
                  updatedAt: Value(t.updatedAt),
                ),
              )
              .toList(),
          mode: InsertMode.insertOrReplace,
        );
      });

      for (final topic in topics) {
        await _replaceTopicAssistants(topic.topicId, topic.assistantIds);
      }
    });
  }

  @override
  Future<void> deleteTopic(String topicId) async {
    await (_db.delete(_db.topics)..where((t) => t.topicId.equals(topicId)))
        .go();
  }

  @override
  Future<void> deleteTopicsByAssistant(String assistantId) async {
    final links = await (_db.select(_db.topicAssistants)
          ..where((t) => t.assistantId.equals(assistantId)))
        .get();
    if (links.isEmpty) return;
    final topicIds = links.map((e) => e.topicId).toSet().toList();
    await (_db.delete(_db.topics)..where((t) => t.topicId.isIn(topicIds))).go();
  }

  @override
  Future<void> clearAllTopics() async {
    await _db.delete(_db.topics).go();
  }

  @override
  Future<List<TopicModel>> searchTopics(String keyword) async {
    if (keyword.isEmpty) return [];

    final lower = keyword.toLowerCase();
    final topics = await (_db.select(_db.topics)
          ..where((t) => t.name.lower().like('%$lower%'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    if (topics.isEmpty) return [];

    final topicIds = topics.map((t) => t.topicId).toList();
    final links = await (_db.select(_db.topicAssistants)
          ..where((t) => t.topicId.isIn(topicIds)))
        .get();
    final topicToAssistantIds = <String, List<String>>{};
    for (final link in links) {
      topicToAssistantIds
          .putIfAbsent(link.topicId, () => [])
          .add(link.assistantId);
    }

    return topics
        .map((t) => _toModel(t, topicToAssistantIds[t.topicId] ?? const []))
        .toList();
  }
}
