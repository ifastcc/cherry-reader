import 'dart:convert';
import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/isar/ai_analysis_entity.dart';
import '../models/isar/discussion_entity.dart';
import '../models/isar/discussion_message_entity.dart';
import '../models/isar/knowledge_entry.dart';
import '../models/isar/perspective_entity.dart';
import '../models/isar/prompt_template_entity.dart';
import '../models/isar/topic_embedding_entity.dart';
import '../models/isar/unified_conversation_entity.dart';
import 'drift/app_database.dart';
import 'perspective_storage.dart';

class AppDb {
  static final AppDb _instance = AppDb._internal();
  factory AppDb() => _instance;
  AppDb._internal();

  ImportDatabase? _importDb;
  UserDatabase? _userDb;

  ImportDatabase get importDb {
    final d = _importDb;
    if (d == null) {
      throw StateError('AppDb not initialized. Call init() first.');
    }
    return d;
  }

  UserDatabase get userDb {
    final d = _userDb;
    if (d == null) {
      throw StateError('AppDb not initialized. Call init() first.');
    }
    return d;
  }

  Future<void> init() async {
    if (_importDb != null && _userDb != null) return;
    _importDb ??= ImportDatabase();
    _userDb ??= UserDatabase();
    await initBuiltinPerspectives();
    await _deleteLegacySingleDbIfExists();
  }

  Future<void> _deleteLegacySingleDbIfExists() async {
    final dir = await getApplicationDocumentsDirectory();
    final legacyFile = io.File('${dir.path}/cherry.sqlite');
    if (await legacyFile.exists()) {
      await legacyFile.delete();
    }
  }

  Future<void> close() async {
    final importDb = _importDb;
    final userDb = _userDb;
    if (importDb != null) await importDb.close();
    if (userDb != null) await userDb.close();
    _importDb = null;
    _userDb = null;
  }

  Future<void> clearAll() async {
    await clearImportedData();
    await clearUserData();
  }

  Future<void> clearImportedData() async {
    final d = importDb;
    await d.transaction(() async {
      await d.delete(d.provenanceRecords).go();
      await d.delete(d.importJobs).go();
      await d.delete(d.importArtifacts).go();
      await d.delete(d.topicEmbeddings).go();
      await d.delete(d.messageBlocks).go();
      await d.delete(d.messages).go();
      await d.delete(d.topicAssistants).go();
      await d.delete(d.topics).go();
      await d.delete(d.files).go();
      await d.delete(d.assistants).go();
    });
  }

  Future<int> getImportDbSizeBytes() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/cherry_import.sqlite');
    return await file.exists() ? await file.length() : 0;
  }

  Future<void> reclaimImportDbSpace() async {
    final d = importDb;
    try {
      await d.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {}
    try {
      await d.customStatement('VACUUM');
    } catch (_) {}
  }

  Future<void> clearUserData() async {
    final d = userDb;
    await d.transaction(() async {
      await d.delete(d.unifiedMessages).go();
      await d.delete(d.unifiedConversations).go();

      await d.delete(d.discussionMessages).go();
      await d.delete(d.discussions).go();

      await d.delete(d.knowledgeEntries).go();

      await d.delete(d.insights).go();
      await d.delete(d.perspectives).go();

      await d.delete(d.taskTemplates).go();
      await d.delete(d.userPreferences).go();

      await d.delete(d.aiAnalyses).go();
    });
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final import = importDb;
    final user = userDb;

    final topicCount = (await import
            .customSelect('SELECT COUNT(*) AS c FROM topics')
            .getSingle())
        .read<int>('c');
    final messageCount = (await import
            .customSelect('SELECT COUNT(*) AS c FROM messages')
            .getSingle())
        .read<int>('c');

    final knowledgeCount = (await user
            .customSelect('SELECT COUNT(*) AS c FROM knowledge_entries')
            .getSingle())
        .read<int>('c');
    final analysisCount = (await user
            .customSelect('SELECT COUNT(*) AS c FROM ai_analyses')
            .getSingle())
        .read<int>('c');

    final docDir = await getApplicationDocumentsDirectory();
    final importFile = io.File('${docDir.path}/cherry_import.sqlite');
    final userFile = io.File('${docDir.path}/cherry_user.sqlite');
    final importBytes = await importFile.exists() ? await importFile.length() : 0;
    final userBytes = await userFile.exists() ? await userFile.length() : 0;

    return {
      'knowledge_entries': knowledgeCount,
      'topics': topicCount,
      'messages': messageCount,
      'analyses': analysisCount,
      'import_db_size_mb': (importBytes / 1024 / 1024).toStringAsFixed(2),
      'user_db_size_mb': (userBytes / 1024 / 1024).toStringAsFixed(2),
      'database_size_mb': ((importBytes + userBytes) / 1024 / 1024).toStringAsFixed(2),
    };
  }

  Future<({Map<String, String> userPreviews, Map<String, String> aiPreviews})>
      getTopicCardPreviews(List<String> topicIds) async {
    final import = importDb;
    if (topicIds.isEmpty) {
      return (userPreviews: <String, String>{}, aiPreviews: <String, String>{});
    }

    final placeholders = List.filled(topicIds.length, '?').join(', ');
    final vars = topicIds.map((id) => Variable<String>(id)).toList();

    final lastUserRows = await import.customSelect(
      '''
SELECT m.topic_id AS topicId, m.message_id AS messageId
FROM messages m
WHERE m.role = 'user'
  AND m.topic_id IN ($placeholders)
  AND m.order_index = (
    SELECT MAX(m2.order_index)
    FROM messages m2
    WHERE m2.topic_id = m.topic_id AND m2.role = 'user'
  )
''',
      variables: vars,
    ).get();

    final firstAiRows = await import.customSelect(
      '''
SELECT m.topic_id AS topicId, m.message_id AS messageId
FROM messages m
WHERE m.role = 'assistant'
  AND m.topic_id IN ($placeholders)
  AND m.order_index = (
    SELECT MIN(m2.order_index)
    FROM messages m2
    WHERE m2.topic_id = m.topic_id AND m2.role = 'assistant'
  )
''',
      variables: vars,
    ).get();

    final lastUserMessageIdByTopic = <String, String>{};
    for (final row in lastUserRows) {
      final topicId = row.read<String>('topicId');
      final messageId = row.read<String>('messageId');
      lastUserMessageIdByTopic[topicId] = messageId;
    }

    final firstAiMessageIdByTopic = <String, String>{};
    for (final row in firstAiRows) {
      final topicId = row.read<String>('topicId');
      final messageId = row.read<String>('messageId');
      firstAiMessageIdByTopic[topicId] = messageId;
    }

    final allMessageIds = <String>{
      ...lastUserMessageIdByTopic.values,
      ...firstAiMessageIdByTopic.values,
    }.toList();

    if (allMessageIds.isEmpty) {
      return (userPreviews: <String, String>{}, aiPreviews: <String, String>{});
    }

    final msgPlaceholders = List.filled(allMessageIds.length, '?').join(', ');
    final msgVars = allMessageIds.map((id) => Variable<String>(id)).toList();

    final blockRows = await import.customSelect(
      '''
SELECT mb.message_id AS messageId, mb.content AS content, mb.order_index AS orderIndex
FROM message_blocks mb
WHERE mb.type = 'main_text'
  AND mb.content IS NOT NULL
  AND mb.message_id IN ($msgPlaceholders)
ORDER BY mb.message_id ASC, mb.order_index ASC
''',
      variables: msgVars,
    ).get();

    final firstMainTextByMessageId = <String, String>{};
    for (final row in blockRows) {
      final messageId = row.read<String>('messageId');
      if (firstMainTextByMessageId.containsKey(messageId)) continue;
      final content = row.read<String>('content');
      firstMainTextByMessageId[messageId] = content;
    }

    final userPreviews = <String, String>{};
    for (final entry in lastUserMessageIdByTopic.entries) {
      final content = firstMainTextByMessageId[entry.value];
      final preview = content == null ? null : _compactPreview(content, 80);
      if (preview != null && preview.isNotEmpty) {
        userPreviews[entry.key] = preview;
      }
    }

    final aiPreviews = <String, String>{};
    for (final entry in firstAiMessageIdByTopic.entries) {
      final content = firstMainTextByMessageId[entry.value];
      final preview = content == null ? null : _compactPreview(content, 80);
      if (preview != null && preview.isNotEmpty) {
        aiPreviews[entry.key] = preview;
      }
    }

    return (userPreviews: userPreviews, aiPreviews: aiPreviews);
  }

  String _compactPreview(String content, int maxLength) {
    final cleaned = content
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*'), '')
        .trim();
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength)}...';
  }

  Future<void> saveAnalysis(AIAnalysisEntity analysis) async {
    final d = userDb;
    await d.into(d.aiAnalyses).insert(
          AiAnalysesCompanion(
            topicId: Value(analysis.topicId),
            groupIndex: Value(analysis.groupIndex),
            content: Value(analysis.content),
            createdAt: Value(analysis.createdAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<AIAnalysisEntity>> getAnalyses(String topicId) async {
    final d = userDb;
    final rows = await (d.select(d.aiAnalyses)
          ..where((t) => t.topicId.equals(topicId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.groupIndex),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    return rows
        .map(
          (r) => AIAnalysisEntity()
            ..topicId = r.topicId
            ..groupIndex = r.groupIndex
            ..content = r.content
            ..createdAt = r.createdAt,
        )
        .toList();
  }

  Future<List<AIAnalysisEntity>> getAllAnalyses() async {
    final d = userDb;
    final rows = await (d.select(d.aiAnalyses)
          ..orderBy([
            (t) => OrderingTerm.asc(t.topicId),
            (t) => OrderingTerm.asc(t.groupIndex),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    return rows
        .map(
          (r) => AIAnalysisEntity()
            ..topicId = r.topicId
            ..groupIndex = r.groupIndex
            ..content = r.content
            ..createdAt = r.createdAt,
        )
        .toList();
  }

  Future<List<AIAnalysisEntity>> getAnalysisForGroup(
    String topicId,
    int groupIndex,
  ) async {
    final d = userDb;
    final rows = await (d.select(d.aiAnalyses)
          ..where((t) =>
              t.topicId.equals(topicId) & t.groupIndex.equals(groupIndex))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows
        .map(
          (r) => AIAnalysisEntity()
            ..topicId = r.topicId
            ..groupIndex = r.groupIndex
            ..content = r.content
            ..createdAt = r.createdAt,
        )
        .toList();
  }

  Future<void> deleteAnalysisAt(
    String topicId,
    int groupIndex,
    int analysisIndex,
  ) async {
    final analyses = await getAnalysisForGroup(topicId, groupIndex);
    if (analysisIndex < 0 || analysisIndex >= analyses.length) return;
    final target = analyses[analysisIndex];
    final d = userDb;
    await (d.delete(d.aiAnalyses)
          ..where((t) =>
              t.topicId.equals(topicId) &
              t.groupIndex.equals(groupIndex) &
              t.createdAt.equals(target.createdAt)))
        .go();
  }

  Future<void> clearAnalyses(String topicId) async {
    final d = userDb;
    await (d.delete(d.aiAnalyses)..where((t) => t.topicId.equals(topicId))).go();
  }

  Future<void> saveDiscussion(DiscussionEntity discussion) async {
    final d = userDb;
    await d.into(d.discussions).insertOnConflictUpdate(
          DiscussionsCompanion(
            discussionId: Value(discussion.discussionId),
            messageId: Value(discussion.messageId),
            title: Value(discussion.title),
            messageCount: Value(discussion.messageCount),
            createdAt: Value(discussion.createdAt),
            updatedAt: Value(discussion.updatedAt),
          ),
        );
  }

  Future<List<DiscussionEntity>> getDiscussions(String messageId) async {
    final d = userDb;
    final rows = await (d.select(d.discussions)
          ..where((t) => t.messageId.equals(messageId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (r) => DiscussionEntity()
            ..discussionId = r.discussionId
            ..messageId = r.messageId
            ..title = r.title
            ..messageCount = r.messageCount
            ..createdAt = r.createdAt
            ..updatedAt = r.updatedAt,
        )
        .toList();
  }

  Future<DiscussionEntity?> getDiscussion(String discussionId) async {
    final d = userDb;
    final row = await (d.select(d.discussions)
          ..where((t) => t.discussionId.equals(discussionId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return DiscussionEntity()
      ..discussionId = row.discussionId
      ..messageId = row.messageId
      ..title = row.title
      ..messageCount = row.messageCount
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt;
  }

  Future<void> updateDiscussion(String discussionId, int messageCount) async {
    final d = userDb;
    await (d.update(d.discussions)
          ..where((t) => t.discussionId.equals(discussionId)))
        .write(
      DiscussionsCompanion(
        messageCount: Value(messageCount),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteDiscussion(String discussionId) async {
    final d = userDb;
    await (d.delete(d.discussions)
          ..where((t) => t.discussionId.equals(discussionId)))
        .go();
  }

  Future<void> saveDiscussionMessage(DiscussionMessageEntity message) async {
    final d = userDb;
    await d.into(d.discussionMessages).insertOnConflictUpdate(
          DiscussionMessagesCompanion(
            messageId: Value(message.messageId),
            discussionId: Value(message.discussionId),
            role: Value(message.role),
            content: Value(message.content),
            createdAt: Value(message.createdAt),
          ),
        );
  }

  Future<List<DiscussionMessageEntity>> getDiscussionMessages(
    String discussionId,
  ) async {
    final d = userDb;
    final rows = await (d.select(d.discussionMessages)
          ..where((t) => t.discussionId.equals(discussionId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows
        .map(
          (r) => DiscussionMessageEntity()
            ..messageId = r.messageId
            ..discussionId = r.discussionId
            ..role = r.role
            ..content = r.content
            ..createdAt = r.createdAt,
        )
        .toList();
  }

  Stream<List<DiscussionMessageEntity>> watchDiscussionMessages(
    String discussionId,
  ) {
    final d = userDb;
    return (d.select(d.discussionMessages)
          ..where((t) => t.discussionId.equals(discussionId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) => DiscussionMessageEntity()
                  ..messageId = r.messageId
                  ..discussionId = r.discussionId
                  ..role = r.role
                  ..content = r.content
                  ..createdAt = r.createdAt,
              )
              .toList(),
        );
  }

  UnifiedConversationEntity _toUnifiedConversation(UnifiedConversation r) {
    return UnifiedConversationEntity()
      ..conversationId = r.conversationId
      ..title = r.title
      ..contextType = ConversationContextType.values
          .firstWhere((e) => e.name == r.contextType)
      ..contextId = r.contextId
      ..contextSnapshot = r.contextSnapshot
      ..providerId = r.providerId
      ..modelId = r.modelId
      ..messageCount = r.messageCount
      ..roundCount = r.roundCount
      ..createdAt = r.createdAt
      ..updatedAt = r.updatedAt
      ..isArchived = r.isArchived
      ..isPinned = r.isPinned;
  }

  UnifiedMessageEntity _toUnifiedMessage(UnifiedMessage r) {
    return UnifiedMessageEntity()
      ..messageId = r.messageId
      ..conversationId = r.conversationId
      ..role = r.role
      ..content = r.content
      ..modelId = r.modelId
      ..modelName = r.modelName
      ..askId = r.askId
      ..isMainline = r.isMainline
      ..usageJson = r.usageJson
      ..createdAt = r.createdAt
      ..status = r.status
      ..errorMessage = r.errorMessage
      ..templateId = r.templateId
      ..templateName = r.templateName
      ..templateSnapshot = r.templateSnapshot
      ..contextSummary = r.contextSummary
      ..contextContent = r.contextContent
      ..userQuery = r.userQuery
      ..contextDataJson = r.contextDataJson;
  }

  Future<void> saveUnifiedConversation(UnifiedConversationEntity conv) async {
    final d = userDb;
    await d.into(d.unifiedConversations).insertOnConflictUpdate(
          UnifiedConversationsCompanion(
            conversationId: Value(conv.conversationId),
            title: Value(conv.title),
            contextType: Value(conv.contextType.name),
            contextId: Value(conv.contextId),
            contextSnapshot: Value(conv.contextSnapshot),
            providerId: Value(conv.providerId),
            modelId: Value(conv.modelId),
            messageCount: Value(conv.messageCount),
            roundCount: Value(conv.roundCount),
            createdAt: Value(conv.createdAt),
            updatedAt: Value(conv.updatedAt),
            isArchived: Value(conv.isArchived),
            isPinned: Value(conv.isPinned),
          ),
        );
  }

  Future<List<UnifiedConversationEntity>> getUnifiedConversations({
    ConversationContextType? contextType,
    bool includeArchived = false,
  }) async {
    final d = userDb;
    final query = d.select(d.unifiedConversations);
    if (contextType != null) {
      query.where((t) => t.contextType.equals(contextType.name));
    }
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_toUnifiedConversation).toList();
  }

  Future<List<UnifiedConversationEntity>> getUnifiedConversationsByContextId(
    String contextId,
  ) async {
    final d = userDb;
    final rows = await (d.select(d.unifiedConversations)
          ..where((t) => t.contextId.equals(contextId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_toUnifiedConversation).toList();
  }

  Future<List<UnifiedConversationEntity>> getUnifiedConversationsByContextIds(
    List<String> contextIds,
  ) async {
    if (contextIds.isEmpty) return [];
    final d = userDb;
    final rows = await (d.select(d.unifiedConversations)
          ..where((t) => t.contextId.isIn(contextIds)))
        .get();
    return rows.map(_toUnifiedConversation).toList();
  }

  Future<List<UnifiedConversationEntity>> getUnifiedConversationsByTopicPrefix(
    String topicId,
  ) async {
    final d = userDb;
    final rows = await (d.select(d.unifiedConversations)
          ..where((t) => t.contextId.like('$topicId:%'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_toUnifiedConversation).toList();
  }

  Future<UnifiedConversationEntity?> getUnifiedConversation(
    String conversationId,
  ) async {
    final d = userDb;
    final row = await (d.select(d.unifiedConversations)
          ..where((t) => t.conversationId.equals(conversationId))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toUnifiedConversation(row);
  }

  Future<void> deleteUnifiedConversation(String conversationId) async {
    final d = userDb;
    await (d.delete(d.unifiedConversations)
          ..where((t) => t.conversationId.equals(conversationId)))
        .go();
  }

  Future<void> saveUnifiedMessage(UnifiedMessageEntity message) async {
    final d = userDb;
    await d.into(d.unifiedMessages).insertOnConflictUpdate(
          UnifiedMessagesCompanion(
            messageId: Value(message.messageId),
            conversationId: Value(message.conversationId),
            role: Value(message.role),
            content: Value(message.content),
            modelId: Value(message.modelId),
            modelName: Value(message.modelName),
            askId: Value(message.askId),
            isMainline: Value(message.isMainline),
            usageJson: Value(message.usageJson),
            createdAt: Value(message.createdAt),
            status: Value(message.status),
            errorMessage: Value(message.errorMessage),
            templateId: Value(message.templateId),
            templateName: Value(message.templateName),
            templateSnapshot: Value(message.templateSnapshot),
            contextSummary: Value(message.contextSummary),
            contextContent: Value(message.contextContent),
            userQuery: Value(message.userQuery),
            contextDataJson: Value(message.contextDataJson),
          ),
        );
  }

  Future<UnifiedMessageEntity?> getUnifiedMessage(String messageId) async {
    final d = userDb;
    final row = await (d.select(d.unifiedMessages)
          ..where((t) => t.messageId.equals(messageId))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toUnifiedMessage(row);
  }

  Future<bool> deleteUnifiedMessage(String messageId) async {
    final d = userDb;
    final deleted = await (d.delete(d.unifiedMessages)
          ..where((t) => t.messageId.equals(messageId)))
        .go();
    return deleted > 0;
  }

  Future<List<UnifiedMessageEntity>> getUnifiedMessages(
    String conversationId,
  ) async {
    final d = userDb;
    final rows = await (d.select(d.unifiedMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_toUnifiedMessage).toList();
  }

  Stream<List<UnifiedMessageEntity>> watchUnifiedMessages(
    String conversationId,
  ) {
    final d = userDb;
    return (d.select(d.unifiedMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toUnifiedMessage).toList());
  }

  Future<void> initBuiltinPerspectives() async {
    final d = userDb;
    final existingBuiltins = await (d.select(d.perspectives)
          ..where((t) => t.isBuiltin.equals(true)))
        .get();

    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt('builtin_perspectives_version') ?? 0;
    final currentVersion = BuiltinPerspectives.version;

    if (existingBuiltins.isEmpty || storedVersion < currentVersion) {
      await (d.delete(d.perspectives)..where((t) => t.isBuiltin.equals(true)))
          .go();

      final builtins = BuiltinPerspectives.getAll();
      await d.batch((b) {
        b.insertAll(
          d.perspectives,
          builtins
              .map(
                (p) => PerspectivesCompanion(
                  perspectiveId: Value(p.perspectiveId),
                  name: Value(p.name),
                  icon: Value(p.icon),
                  description: Value(p.description),
                  category: Value(p.category),
                  promptTemplate: Value(p.promptTemplate),
                  isBuiltin: Value(p.isBuiltin),
                  isEnabled: Value(p.isEnabled),
                  sortOrder: Value(p.sortOrder),
                  createdAt: Value(p.createdAt),
                  updatedAt: Value(p.updatedAt),
                ),
              )
              .toList(),
          mode: InsertMode.insertOrReplace,
        );
      });

      await prefs.setInt('builtin_perspectives_version', currentVersion);
    }
  }

  Future<void> saveTopicEmbedding(TopicEmbeddingEntity entity) async {
    final d = importDb;
    await d.into(d.topicEmbeddings).insertOnConflictUpdate(
          TopicEmbeddingsCompanion(
            topicId: Value(entity.topicId),
            firstQueryText: Value(entity.firstQueryText),
            embeddingJson: Value(jsonEncode(entity.embedding)),
            modelName: Value(entity.modelName),
            createdAt: Value(entity.createdAt),
          ),
        );
  }

  Future<List<TopicEmbeddingEntity>> getAllTopicEmbeddings() async {
    final d = importDb;
    final rows = await d.select(d.topicEmbeddings).get();
    return rows
        .map(
          (r) => TopicEmbeddingEntity()
            ..topicId = r.topicId
            ..firstQueryText = r.firstQueryText
            ..embedding = _decodeDoubleList(r.embeddingJson)
            ..modelName = r.modelName
            ..createdAt = r.createdAt,
        )
        .toList();
  }

  Future<void> upsertKnowledgeEntry(KnowledgeEntry entry) async {
    final d = userDb;
    await d.into(d.knowledgeEntries).insertOnConflictUpdate(
          KnowledgeEntriesCompanion(
            entryId: Value(entry.entryId),
            content: Value(entry.content),
            contentType: Value(entry.contentType),
            plainText: Value(entry.plainText),
            quotedText: Value(entry.quotedText),
            color: Value(entry.color),
            styleType: Value(entry.styleType),
            messageId: Value(entry.messageId),
            topicId: Value(entry.topicId),
            topicName: Value(entry.topicName),
            prefix: Value(entry.prefix),
            suffix: Value(entry.suffix),
            start: Value(entry.start),
            end: Value(entry.end),
            tagsJson: Value(jsonEncode(entry.tags)),
            createdAt: Value(entry.createdAt),
            updatedAt: Value(entry.updatedAt),
            blockIndex: Value(entry.blockIndex),
            blockContentHash: Value(entry.blockContentHash),
            blockInternalStart: Value(entry.blockInternalStart),
            blockInternalEnd: Value(entry.blockInternalEnd),
            groupId: Value(entry.groupId),
            selections: Value(entry.selections),
            reviewCount: Value(entry.reviewCount),
            lastReviewedAt: Value(entry.lastReviewedAt),
            importance: Value(entry.importance),
            isPinned: Value(entry.isPinned),
          ),
        );
  }

  KnowledgeEntry _toKnowledgeEntry(KnowledgeEntryRow r) {
    final entry = KnowledgeEntry()
      ..entryId = r.entryId
      ..content = r.content
      ..contentType = r.contentType
      ..plainText = r.plainText
      ..quotedText = r.quotedText
      ..color = r.color
      ..styleType = r.styleType
      ..messageId = r.messageId
      ..topicId = r.topicId
      ..topicName = r.topicName
      ..prefix = r.prefix
      ..suffix = r.suffix
      ..start = r.start
      ..end = r.end
      ..createdAt = r.createdAt
      ..updatedAt = r.updatedAt
      ..blockIndex = r.blockIndex
      ..blockContentHash = r.blockContentHash
      ..blockInternalStart = r.blockInternalStart
      ..blockInternalEnd = r.blockInternalEnd
      ..groupId = r.groupId
      ..selections = r.selections
      ..reviewCount = r.reviewCount
      ..lastReviewedAt = r.lastReviewedAt
      ..importance = r.importance
      ..isPinned = r.isPinned;
    entry.tags = _decodeStringList(r.tagsJson);
    return entry;
  }

  List<double> _decodeDoubleList(String json) {
    try {
      final list = jsonDecode(json);
      if (list is List) {
        return list.map((e) => (e as num).toDouble()).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  List<String> _decodeStringList(String json) {
    try {
      final list = jsonDecode(json);
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Stream<List<KnowledgeEntry>> watchAllKnowledgeEntries() {
    final d = userDb;
    return (d.select(d.knowledgeEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toKnowledgeEntry).toList());
  }

  Future<List<KnowledgeEntry>> getKnowledgeEntriesByGroupId(String groupId) async {
    final d = userDb;
    final rows = await (d.select(d.knowledgeEntries)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toKnowledgeEntry).toList();
  }

  Future<KnowledgeEntry?> getKnowledgeEntryByMessageAndQuotedText(
    String messageId,
    String quotedText,
  ) async {
    final d = userDb;
    final row = await (d.select(d.knowledgeEntries)
          ..where((t) =>
              t.messageId.equals(messageId) & t.quotedText.equals(quotedText))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toKnowledgeEntry(row);
  }

  Future<void> upsertKnowledgeEntries(List<KnowledgeEntry> entries) async {
    if (entries.isEmpty) return;
    final d = userDb;
    await d.batch((b) {
      b.insertAll(
        d.knowledgeEntries,
        entries
            .map(
              (entry) => KnowledgeEntriesCompanion(
                entryId: Value(entry.entryId),
                content: Value(entry.content),
                contentType: Value(entry.contentType),
                plainText: Value(entry.plainText),
                quotedText: Value(entry.quotedText),
                color: Value(entry.color),
                styleType: Value(entry.styleType),
                messageId: Value(entry.messageId),
                topicId: Value(entry.topicId),
                topicName: Value(entry.topicName),
                prefix: Value(entry.prefix),
                suffix: Value(entry.suffix),
                start: Value(entry.start),
                end: Value(entry.end),
                tagsJson: Value(jsonEncode(entry.tags)),
                createdAt: Value(entry.createdAt),
                updatedAt: Value(entry.updatedAt),
                blockIndex: Value(entry.blockIndex),
                blockContentHash: Value(entry.blockContentHash),
                blockInternalStart: Value(entry.blockInternalStart),
                blockInternalEnd: Value(entry.blockInternalEnd),
                groupId: Value(entry.groupId),
                selections: Value(entry.selections),
                reviewCount: Value(entry.reviewCount),
                lastReviewedAt: Value(entry.lastReviewedAt),
                importance: Value(entry.importance),
                isPinned: Value(entry.isPinned),
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<KnowledgeEntry?> getKnowledgeEntry(String entryId) async {
    final d = userDb;
    final row = await (d.select(d.knowledgeEntries)
          ..where((t) => t.entryId.equals(entryId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _toKnowledgeEntry(row);
  }

  Future<List<KnowledgeEntry>> getKnowledgeEntriesByMessage(
    String messageId,
  ) async {
    final d = userDb;
    final rows = await (d.select(d.knowledgeEntries)
          ..where((t) => t.messageId.equals(messageId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toKnowledgeEntry).toList();
  }

  Stream<List<KnowledgeEntry>> watchKnowledgeEntriesByMessage(
    String messageId,
  ) {
    final d = userDb;
    return (d.select(d.knowledgeEntries)
          ..where((t) => t.messageId.equals(messageId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toKnowledgeEntry).toList());
  }

  Future<List<KnowledgeEntry>> getAllKnowledgeEntries() async {
    final d = userDb;
    final rows = await (d.select(d.knowledgeEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toKnowledgeEntry).toList();
  }

  Future<List<KnowledgeEntry>> getKnowledgeEntriesByTopic(String topicId) async {
    final d = userDb;
    final rows = await (d.select(d.knowledgeEntries)
          ..where((t) => t.topicId.equals(topicId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toKnowledgeEntry).toList();
  }

  Future<void> deleteKnowledgeEntry(String entryId) async {
    final d = userDb;
    await (d.delete(d.knowledgeEntries)..where((t) => t.entryId.equals(entryId)))
        .go();
  }

  Future<void> deleteKnowledgeEntriesByMessage(String messageId) async {
    final d = userDb;
    await (d.delete(d.knowledgeEntries)
          ..where((t) => t.messageId.equals(messageId)))
        .go();
  }

  Future<void> deleteKnowledgeEntriesByTopic(String topicId) async {
    final d = userDb;
    await (d.delete(d.knowledgeEntries)..where((t) => t.topicId.equals(topicId)))
        .go();
  }

  Future<void> deleteKnowledgeEntriesByGroupId(String groupId) async {
    final d = userDb;
    await (d.delete(d.knowledgeEntries)..where((t) => t.groupId.equals(groupId)))
        .go();
  }

  Future<int> getKnowledgeEntryCount() async {
    final d = userDb;
    final countExp = d.knowledgeEntries.entryId.count();
    final row = await (d.selectOnly(d.knowledgeEntries)..addColumns([countExp]))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<UserPreferenceEntity?> getActivePreference() async {
    final d = userDb;
    final row = await (d.select(d.userPreferences)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return UserPreferenceEntity()
      ..preferenceId = row.preferenceId
      ..name = row.name
      ..systemPrompt = row.systemPrompt
      ..isActive = row.isActive
      ..defaultTemplateId = row.defaultTemplateId
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt;
  }

  Future<List<UserPreferenceEntity>> getAllPreferences() async {
    final d = userDb;
    final rows = await (d.select(d.userPreferences)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (row) => UserPreferenceEntity()
            ..preferenceId = row.preferenceId
            ..name = row.name
            ..systemPrompt = row.systemPrompt
            ..isActive = row.isActive
            ..defaultTemplateId = row.defaultTemplateId
            ..createdAt = row.createdAt
            ..updatedAt = row.updatedAt,
        )
        .toList();
  }

  Future<void> upsertPreference(UserPreferenceEntity entity) async {
    final d = userDb;
    await d.into(d.userPreferences).insertOnConflictUpdate(
          UserPreferencesCompanion(
            preferenceId: Value(entity.preferenceId),
            name: Value(entity.name),
            systemPrompt: Value(entity.systemPrompt),
            isActive: Value(entity.isActive),
            defaultTemplateId: Value(entity.defaultTemplateId),
            createdAt: Value(entity.createdAt),
            updatedAt: Value(entity.updatedAt),
          ),
        );
  }

  Future<void> deactivateAllPreferences() async {
    final d = userDb;
    await (d.update(d.userPreferences)..where((t) => t.isActive.equals(true)))
        .write(const UserPreferencesCompanion(isActive: Value(false)));
  }

  Future<int> getPreferenceCount() async {
    final d = userDb;
    final countExp = d.userPreferences.preferenceId.count();
    final row = await (d.selectOnly(d.userPreferences)..addColumns([countExp]))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> deletePreference(String preferenceId) async {
    final d = userDb;
    await (d.delete(d.userPreferences)
          ..where((t) => t.preferenceId.equals(preferenceId)))
        .go();
  }

  Future<TaskTemplateEntity?> getTemplate(String templateId) async {
    final d = userDb;
    final row = await (d.select(d.taskTemplates)
          ..where((t) => t.templateId.equals(templateId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return TaskTemplateEntity()
      ..templateId = row.templateId
      ..name = row.name
      ..description = row.description
      ..content = row.content
      ..isBuiltIn = row.isBuiltIn
      ..usageCount = row.usageCount
      ..targetType = TemplateTargetType.values.firstWhere((e) => e.name == row.targetType)
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt;
  }

  Future<List<TaskTemplateEntity>> getAllTemplates() async {
    final d = userDb;
    final rows = await (d.select(d.taskTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (row) => TaskTemplateEntity()
            ..templateId = row.templateId
            ..name = row.name
            ..description = row.description
            ..content = row.content
            ..isBuiltIn = row.isBuiltIn
            ..usageCount = row.usageCount
            ..targetType = TemplateTargetType.values
                .firstWhere((e) => e.name == row.targetType)
            ..createdAt = row.createdAt
            ..updatedAt = row.updatedAt,
        )
        .toList();
  }

  Future<void> upsertTemplate(TaskTemplateEntity entity) async {
    final d = userDb;
    await d.into(d.taskTemplates).insertOnConflictUpdate(
          TaskTemplatesCompanion(
            templateId: Value(entity.templateId),
            name: Value(entity.name),
            description: Value(entity.description),
            content: Value(entity.content),
            isBuiltIn: Value(entity.isBuiltIn),
            usageCount: Value(entity.usageCount),
            targetType: Value(entity.targetType.name),
            createdAt: Value(entity.createdAt),
            updatedAt: Value(entity.updatedAt),
          ),
        );
  }

  Future<void> deleteTemplate(String templateId) async {
    final d = userDb;
    await (d.delete(d.taskTemplates)
          ..where((t) => t.templateId.equals(templateId)))
        .go();
  }

  Future<void> incrementTemplateUsage(String templateId) async {
    final d = userDb;
    await d.customUpdate(
      'UPDATE task_templates SET usage_count = usage_count + 1, updated_at = ? WHERE template_id = ?',
      variables: [
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
        Variable<String>(templateId),
      ],
      updates: {d.taskTemplates},
    );
  }
}
