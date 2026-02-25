import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_db.dart';
import '../drift/app_database.dart';
import '../../models/domain/assistant_model.dart';
import '../../models/domain/block_model.dart';
import '../../models/domain/export_snapshot.dart';
import '../../models/domain/message_model.dart';
import '../../models/domain/topic_model.dart';
import '../../models/isar/file_entity.dart';
import 'i_export_store.dart';

class DriftExportStore implements IExportStore {
  final AppDb _db;

  DriftExportStore(this._db);

  ImportDatabase get _sql => _db.importDb;

  @override
  Future<ExportSnapshot> loadSnapshot() async {
    final assistants = await _loadAssistants();
    final topics = await _loadTopics();
    final topicAssistantLinks = await _loadTopicAssistantLinks();
    final messages = await _loadMessages();
    final blocks = await _loadBlocks();
    final files = await _loadFiles();

    return ExportSnapshot(
      assistants: assistants,
      topics: topics,
      topicAssistantLinks: topicAssistantLinks,
      messages: messages,
      blocks: blocks,
      files: files,
    );
  }

  Future<List<AssistantModel>> _loadAssistants() async {
    final rows = await (_sql.select(_sql.assistants)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows
        .map(
          (r) => AssistantModel(
            assistantId: r.assistantId,
            name: r.name,
            description: r.description,
            avatar: r.avatar,
            prompt: r.prompt,
            topicCount: r.topicCount,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
  }

  Future<List<TopicModel>> _loadTopics() async {
    final rows = await (_sql.select(_sql.topics)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows
        .map(
          (r) => TopicModel(
            topicId: r.topicId,
            name: r.name,
            assistantIds: const [],
            messageCount: r.messageCount,
            roundCount: r.roundCount,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
  }

  Future<List<TopicAssistantLink>> _loadTopicAssistantLinks() async {
    final rows = await _sql.select(_sql.topicAssistants).get();
    return rows
        .map(
          (r) => TopicAssistantLink(topicId: r.topicId, assistantId: r.assistantId),
        )
        .toList();
  }

  Future<List<MessageModel>> _loadMessages() async {
    final rows = await (_sql.select(_sql.messages)
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    return rows
        .map(
          (r) => MessageModel(
            messageId: r.messageId,
            topicId: r.topicId,
            orderIndex: r.orderIndex,
            roundIndex: r.roundIndex,
            role: r.role,
            askId: r.askId,
            useful: r.useful,
            modelId: r.modelId,
            modelName: r.modelName,
            createdAt: r.createdAt,
            status: r.status,
            usage: MessageModel.parseUsageJson(r.usageJson),
            metrics: MessageModel.parseMetricsJson(r.metricsJson),
            mentions: MessageModel.parseMentionsJson(r.mentionsJson),
          ),
        )
        .toList();
  }

  Future<List<BlockModel>> _loadBlocks() async {
    final rows = await (_sql.select(_sql.messageBlocks)
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    return rows
        .map((r) {
          final tool = BlockModel.parseToolJson(r.toolJson);
          final rawArguments = tool?['arguments'];
          final arguments =
              rawArguments is Map ? rawArguments.cast<String, dynamic>() : null;
          return BlockModel(
            blockId: r.blockId,
            topicId: r.topicId,
            messageId: r.messageId,
            orderIndex: r.orderIndex,
            type: r.type,
            createdAt: r.createdAt,
            content: r.content,
            thinkingMillsec: r.thinkingMillsec,
            url: r.url,
            file: BlockModel.parseFileJson(r.fileJson),
            toolId: tool?['toolId']?.toString(),
            toolName: tool?['toolName']?.toString(),
            arguments: arguments,
            error: BlockModel.parseErrorJson(r.errorJson),
            targetLanguage: r.targetLanguage,
            response: _parseJsonMap(r.responseJson),
            knowledge: _parseJsonMap(r.knowledgeJson),
          );
        })
        .toList();
  }

  Future<List<FileEntity>> _loadFiles() async {
    final rows = await _sql.select(_sql.files).get();
    return rows
        .map(
          (r) => FileEntity.fromData(
            fileId: r.fileId,
            fileName: r.fileName,
            mimeType: r.mimeType,
            fileSize: r.fileSize,
            sha256: r.sha256,
            localPath: r.localPath,
            url: null,
            referenceCount: r.referenceCount,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }

  Map<String, dynamic>? _parseJsonMap(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
