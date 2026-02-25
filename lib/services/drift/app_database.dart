import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class AiAnalyses extends Table {
  TextColumn get topicId => text()();
  IntColumn get groupIndex => integer()();
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {topicId, groupIndex, createdAt};
}

class Assistants extends Table {
  TextColumn get assistantId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get avatar => text().nullable()();
  TextColumn get prompt => text().nullable()();
  IntColumn get topicCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {assistantId};
}

class Topics extends Table {
  TextColumn get topicId => text()();
  TextColumn get name => text()();
  IntColumn get messageCount => integer()();
  IntColumn get roundCount => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {topicId};
}

class TopicAssistants extends Table {
  TextColumn get topicId => text().references(Topics, #topicId)();
  TextColumn get assistantId => text().references(Assistants, #assistantId)();

  @override
  Set<Column<Object>> get primaryKey => {topicId, assistantId};
}

class Messages extends Table {
  TextColumn get messageId => text()();
  TextColumn get topicId => text().references(Topics, #topicId)();
  IntColumn get orderIndex => integer()();
  IntColumn get roundIndex => integer()();
  TextColumn get role => text()();
  TextColumn get askId => text().nullable()();
  BoolColumn get useful => boolean()();
  TextColumn get modelId => text().nullable()();
  TextColumn get modelName => text().nullable()();
  TextColumn get usageJson => text().nullable()();
  TextColumn get metricsJson => text().nullable()();
  TextColumn get mentionsJson => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {messageId};
}

class MessageBlocks extends Table {
  TextColumn get blockId => text()();
  TextColumn get topicId => text().references(Topics, #topicId)();
  TextColumn get messageId => text().references(Messages, #messageId)();
  IntColumn get orderIndex => integer()();
  TextColumn get type => text()();
  TextColumn get content => text().nullable()();
  RealColumn get thinkingMillsec => real().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get fileJson => text().nullable()();
  TextColumn get toolJson => text().nullable()();
  TextColumn get errorJson => text().nullable()();
  TextColumn get targetLanguage => text().nullable()();
  TextColumn get responseJson => text().nullable()();
  TextColumn get knowledgeJson => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {blockId};
}

class Files extends Table {
  TextColumn get fileId => text()();
  TextColumn get fileName => text().nullable()();
  TextColumn get localPath => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get sha256 => text().nullable()();
  IntColumn get referenceCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {fileId};
}

class ImportArtifacts extends Table {
  TextColumn get artifactId => text()();
  TextColumn get sourceType => text()();
  TextColumn get fileName => text().nullable()();
  TextColumn get sourcePath => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get sha256 => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {artifactId};
}

class ImportJobs extends Table {
  TextColumn get jobId => text()();
  TextColumn get artifactId => text().references(ImportArtifacts, #artifactId)();
  TextColumn get sourceType => text()();
  TextColumn get status => text()();
  IntColumn get startedAt => integer()();
  IntColumn get finishedAt => integer().nullable()();
  TextColumn get statsJson => text().nullable()();
  TextColumn get error => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {jobId};
}

class ProvenanceRecords extends Table {
  TextColumn get sourceType => text()();
  TextColumn get entityType => text()();
  TextColumn get externalId => text()();
  TextColumn get entityId => text()();
  TextColumn get parentExternalId => text().nullable()();
  TextColumn get fingerprint => text().nullable()();
  IntColumn get firstSeenAt => integer()();
  IntColumn get lastSeenAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {sourceType, entityType, externalId};
}

@DataClassName('KnowledgeEntryRow')
class KnowledgeEntries extends Table {
  TextColumn get entryId => text()();
  TextColumn get content => text().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('plain'))();
  TextColumn get plainText => text().nullable()();
  TextColumn get quotedText => text().nullable()();
  IntColumn get color => integer().nullable()();
  TextColumn get styleType => text().nullable()();
  TextColumn get messageId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  TextColumn get topicName => text().nullable()();
  TextColumn get prefix => text().nullable()();
  TextColumn get suffix => text().nullable()();
  IntColumn get start => integer().nullable()();
  IntColumn get end => integer().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get blockIndex => integer().nullable()();
  TextColumn get blockContentHash => text().nullable()();
  IntColumn get blockInternalStart => integer().nullable()();
  IntColumn get blockInternalEnd => integer().nullable()();
  TextColumn get groupId => text().nullable()();
  TextColumn get selections => text().nullable()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get lastReviewedAt => integer().nullable()();
  IntColumn get importance => integer().withDefault(const Constant(0))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {entryId};
}

class Discussions extends Table {
  TextColumn get discussionId => text()();
  TextColumn get messageId => text()();
  TextColumn get title => text()();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {discussionId};
}

class DiscussionMessages extends Table {
  TextColumn get messageId => text()();
  TextColumn get discussionId =>
      text().references(Discussions, #discussionId, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {messageId};
}

class UnifiedConversations extends Table {
  TextColumn get conversationId => text()();
  TextColumn get title => text()();
  TextColumn get contextType => text()();
  TextColumn get contextId => text()();
  TextColumn get contextSnapshot => text().nullable()();
  TextColumn get providerId => text().nullable()();
  TextColumn get modelId => text().nullable()();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  IntColumn get roundCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {conversationId};
}

class UnifiedMessages extends Table {
  TextColumn get messageId => text()();
  TextColumn get conversationId => text()
      .references(UnifiedConversations, #conversationId, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get modelId => text().nullable()();
  TextColumn get modelName => text().nullable()();
  TextColumn get askId => text().nullable()();
  BoolColumn get isMainline => boolean().withDefault(const Constant(false))();
  TextColumn get usageJson => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get status => text()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get templateId => text().nullable()();
  TextColumn get templateName => text().nullable()();
  TextColumn get templateSnapshot => text().nullable()();
  TextColumn get contextSummary => text().nullable()();
  TextColumn get contextContent => text().nullable()();
  TextColumn get userQuery => text().nullable()();
  TextColumn get contextDataJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {messageId};
}

class UserPreferences extends Table {
  TextColumn get preferenceId => text()();
  TextColumn get name => text()();
  TextColumn get systemPrompt => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get defaultTemplateId => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {preferenceId};
}

class TaskTemplates extends Table {
  TextColumn get templateId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get content => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  TextColumn get targetType => text().withDefault(const Constant('any'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {templateId};
}

class Perspectives extends Table {
  TextColumn get perspectiveId => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  TextColumn get promptTemplate => text()();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {perspectiveId};
}

class Insights extends Table {
  TextColumn get insightId => text()();
  TextColumn get perspectiveId => text()();
  TextColumn get perspectiveName => text()();
  TextColumn get perspectiveIcon => text()();
  TextColumn get timeRangeLabel => text()();
  TextColumn get assistantFilter => text()();
  IntColumn get queryCount => integer()();
  IntColumn get charCount => integer()();
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {insightId};
}

class TopicEmbeddings extends Table {
  TextColumn get topicId => text()();
  TextColumn get firstQueryText => text()();
  TextColumn get embeddingJson => text()();
  TextColumn get modelName => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {topicId};
}

@DriftDatabase(
  tables: [
    Assistants,
    Topics,
    TopicAssistants,
    Messages,
    MessageBlocks,
    Files,
    ImportArtifacts,
    ImportJobs,
    ProvenanceRecords,
    TopicEmbeddings,
  ],
)
class ImportDatabase extends _$ImportDatabase {
  ImportDatabase() : super(_openImportConnection());

  @override
  int get schemaVersion => 1;
}

@DriftDatabase(
  tables: [
    AiAnalyses,
    KnowledgeEntries,
    Discussions,
    DiscussionMessages,
    UnifiedConversations,
    UnifiedMessages,
    UserPreferences,
    TaskTemplates,
    Perspectives,
    Insights,
  ],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase() : super(_openUserConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openImportConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/cherry_import.sqlite');
    return driftDatabase(
      name: file.path,
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  });
}

QueryExecutor _openUserConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/cherry_user.sqlite');
    return driftDatabase(
      name: file.path,
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  });
}
