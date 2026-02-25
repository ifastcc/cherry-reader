import 'package:drift/drift.dart';

import '../app_db.dart';
import '../drift/app_database.dart';
import '../../models/domain/insight_models.dart';
import '../../models/isar/insight_entity.dart';
import '../../models/isar/perspective_entity.dart';
import 'i_insight_store.dart';

class DriftInsightStore implements IInsightStore {
  final AppDb _db;

  DriftInsightStore(this._db);

  ImportDatabase get _importDb => _db.importDb;
  UserDatabase get _userDb => _db.userDb;

  PerspectiveEntity _toPerspectiveEntity(Perspective row) {
    return PerspectiveEntity()
      ..perspectiveId = row.perspectiveId
      ..name = row.name
      ..icon = row.icon
      ..description = row.description
      ..category = row.category
      ..promptTemplate = row.promptTemplate
      ..isBuiltin = row.isBuiltin
      ..isEnabled = row.isEnabled
      ..sortOrder = row.sortOrder
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt;
  }

  InsightEntity _toInsightEntity(Insight row) {
    return InsightEntity()
      ..insightId = row.insightId
      ..perspectiveId = row.perspectiveId
      ..perspectiveName = row.perspectiveName
      ..perspectiveIcon = row.perspectiveIcon
      ..timeRangeLabel = row.timeRangeLabel
      ..assistantFilter = row.assistantFilter
      ..queryCount = row.queryCount
      ..charCount = row.charCount
      ..content = row.content
      ..createdAt = row.createdAt;
  }

  @override
  Future<List<PerspectiveEntity>> getAllPerspectives() async {
    final rows = await (_userDb.select(_userDb.perspectives)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map(_toPerspectiveEntity).toList();
  }

  @override
  Future<List<PerspectiveEntity>> getEnabledPerspectives() async {
    final rows = await (_userDb.select(_userDb.perspectives)
          ..where((t) => t.isEnabled.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map(_toPerspectiveEntity).toList();
  }

  @override
  Future<PerspectiveEntity?> getPerspective(String perspectiveId) async {
    final row = await (_userDb.select(_userDb.perspectives)
          ..where((t) => t.perspectiveId.equals(perspectiveId))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toPerspectiveEntity(row);
  }

  @override
  Future<void> upsertPerspective(PerspectiveEntity perspective) async {
    perspective.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _userDb.into(_userDb.perspectives).insertOnConflictUpdate(
          PerspectivesCompanion(
            perspectiveId: Value(perspective.perspectiveId),
            name: Value(perspective.name),
            icon: Value(perspective.icon),
            description: Value(perspective.description),
            category: Value(perspective.category),
            promptTemplate: Value(perspective.promptTemplate),
            isBuiltin: Value(perspective.isBuiltin),
            isEnabled: Value(perspective.isEnabled),
            sortOrder: Value(perspective.sortOrder),
            createdAt: Value(perspective.createdAt),
            updatedAt: Value(perspective.updatedAt),
          ),
        );
  }

  @override
  Future<void> togglePerspectiveEnabled(
    String perspectiveId,
    bool isEnabled,
  ) async {
    await (_userDb.update(_userDb.perspectives)
          ..where((t) => t.perspectiveId.equals(perspectiveId)))
        .write(
      PerspectivesCompanion(
        isEnabled: Value(isEnabled),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<bool> deleteCustomPerspective(String perspectiveId) async {
    final row = await (_userDb.select(_userDb.perspectives)
          ..where((t) => t.perspectiveId.equals(perspectiveId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null || row.isBuiltin) return false;
    await (_userDb.delete(_userDb.perspectives)
          ..where((t) => t.perspectiveId.equals(perspectiveId)))
        .go();
    return true;
  }

  @override
  Future<List<PerspectiveEntity>> getCustomPerspectives() async {
    final rows = await (_userDb.select(_userDb.perspectives)
          ..where((t) => t.isBuiltin.equals(false)))
        .get();
    return rows.map(_toPerspectiveEntity).toList();
  }

  @override
  Future<List<Map<String, String>>> getAssistantList() async {
    final assistants = await (_importDb.select(_importDb.assistants)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return assistants.map((a) => {'id': a.assistantId, 'name': a.name}).toList();
  }

  @override
  Future<({
    List<Map<String, String>> assistantList,
    Map<String, String> assistantIdToName,
    List<TopicGroup> topicGroups,
  })> preloadTopicGroups() async {
    final assistants = await (_importDb.select(_importDb.assistants)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();

    final topics = await (_importDb.select(_importDb.topics)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    final topicAssistantRows = await _importDb.select(_importDb.topicAssistants).get();
    final topicToAssistantIds = <String, List<String>>{};
    for (final row in topicAssistantRows) {
      topicToAssistantIds.putIfAbsent(row.topicId, () => []).add(row.assistantId);
    }

    final messages = await (_importDb.select(_importDb.messages)
          ..where((t) => t.role.equals('user'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    final blocks = await (_importDb.select(_importDb.messageBlocks)
          ..where((t) => t.type.equals('main_text')))
        .get();

    final assistantIdToName = {for (final a in assistants) a.assistantId: a.name};
    final assistantList =
        assistants.map((a) => {'id': a.assistantId, 'name': a.name}).toList();

    final blockContentMap = <String, String>{};
    for (final block in blocks) {
      blockContentMap.putIfAbsent(block.messageId, () => block.content ?? '');
    }

    final messagesByTopic = <String, List<Message>>{};
    for (final msg in messages) {
      messagesByTopic.putIfAbsent(msg.topicId, () => []).add(msg);
    }

    final topicGroups = <TopicGroup>[];
    for (final topic in topics) {
      final topicMessages = messagesByTopic[topic.topicId] ?? const <Message>[];
      if (topicMessages.isEmpty) continue;

      final queries = <QueryItem>[];
      var totalChars = 0;

      for (final msg in topicMessages) {
        final content = blockContentMap[msg.messageId] ?? '';
        final preview = content.length > 100 ? '${content.substring(0, 100)}...' : content;
        totalChars += content.length;
        queries.add(
          QueryItem(
            topicId: topic.topicId,
            topicName: topic.name,
            messageId: msg.messageId,
            preview: preview,
            charCount: content.length,
            timestamp: DateTime.fromMillisecondsSinceEpoch(msg.createdAt),
          ),
        );
      }

      if (queries.isEmpty) continue;

      final assistantIds = topicToAssistantIds[topic.topicId] ?? const <String>[];
      final assistantNames = assistantIds
          .map((id) => assistantIdToName[id] ?? '未知助手')
          .toList();

      topicGroups.add(
        TopicGroup(
          topicId: topic.topicId,
          topicName: topic.name,
          assistantIds: assistantIds,
          assistantNames: assistantNames,
          queries: queries,
          totalCharCount: totalChars,
          roundCount: queries.length,
          latestTime: queries.last.timestamp,
        ),
      );
    }

    return (
      assistantList: assistantList,
      assistantIdToName: assistantIdToName,
      topicGroups: topicGroups,
    );
  }

  @override
  Future<void> saveInsight(InsightEntity insight) async {
    await _userDb.into(_userDb.insights).insertOnConflictUpdate(
          InsightsCompanion(
            insightId: Value(insight.insightId),
            perspectiveId: Value(insight.perspectiveId),
            perspectiveName: Value(insight.perspectiveName),
            perspectiveIcon: Value(insight.perspectiveIcon),
            timeRangeLabel: Value(insight.timeRangeLabel),
            assistantFilter: Value(insight.assistantFilter),
            queryCount: Value(insight.queryCount),
            charCount: Value(insight.charCount),
            content: Value(insight.content),
            createdAt: Value(insight.createdAt),
          ),
        );
  }

  @override
  Future<List<InsightEntity>> getAllInsights() async {
    final rows = await (_userDb.select(_userDb.insights)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toInsightEntity).toList();
  }

  @override
  Future<void> deleteInsight(String insightId) async {
    await (_userDb.delete(_userDb.insights)
          ..where((t) => t.insightId.equals(insightId)))
        .go();
  }

  @override
  Stream<List<InsightEntity>> watchInsights() {
    return (_userDb.select(_userDb.insights)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toInsightEntity).toList());
  }
}
