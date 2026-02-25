import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/domain/block_model.dart';
import '../../models/domain/message_model.dart';
import '../../services/drift/app_database.dart';
import '../i_message_repository.dart';

class DriftMessageRepository implements IMessageRepository {
  final ImportDatabase _db;

  DriftMessageRepository(this._db);

  MessageModel _toMessageModel(Message row) {
    return MessageModel(
      messageId: row.messageId,
      topicId: row.topicId,
      orderIndex: row.orderIndex,
      roundIndex: row.roundIndex,
      role: row.role,
      askId: row.askId,
      useful: row.useful,
      modelId: row.modelId,
      modelName: row.modelName,
      createdAt: row.createdAt,
      status: row.status,
      usage: MessageModel.parseUsageJson(row.usageJson),
      metrics: MessageModel.parseMetricsJson(row.metricsJson),
      mentions: MessageModel.parseMentionsJson(row.mentionsJson),
    );
  }

  MessagesCompanion _toMessageCompanion(MessageModel model) {
    return MessagesCompanion(
      messageId: Value(model.messageId),
      topicId: Value(model.topicId),
      orderIndex: Value(model.orderIndex),
      roundIndex: Value(model.roundIndex),
      role: Value(model.role),
      askId: Value(model.askId),
      useful: Value(model.useful),
      modelId: Value(model.modelId),
      modelName: Value(model.modelName),
      usageJson: Value(model.usage != null ? jsonEncode(model.usage) : null),
      metricsJson:
          Value(model.metrics != null ? jsonEncode(model.metrics) : null),
      mentionsJson:
          Value(model.mentions != null ? jsonEncode(model.mentions) : null),
      createdAt: Value(model.createdAt),
      status: Value(model.status),
    );
  }

  BlockModel _toBlockModel(MessageBlock row) {
    final toolData = BlockModel.parseToolJson(row.toolJson);
    final responseData = BlockModel.parseFileJson(row.responseJson);
    final knowledgeData = BlockModel.parseFileJson(row.knowledgeJson);

    return BlockModel(
      blockId: row.blockId,
      topicId: row.topicId,
      messageId: row.messageId,
      orderIndex: row.orderIndex,
      type: row.type,
      createdAt: row.createdAt,
      content: row.content,
      thinkingMillsec: row.thinkingMillsec,
      url: row.url,
      file: BlockModel.parseFileJson(row.fileJson),
      error: BlockModel.parseErrorJson(row.errorJson),
      targetLanguage: row.targetLanguage,
      toolId: toolData?['toolId'] as String?,
      toolName: toolData?['toolName'] as String?,
      arguments: toolData?['arguments'] as Map<String, dynamic>?,
      response: responseData,
      knowledge: knowledgeData,
    );
  }

  MessageBlocksCompanion _toBlockCompanion(BlockModel model) {
    return MessageBlocksCompanion(
      blockId: Value(model.blockId),
      topicId: Value(model.topicId),
      messageId: Value(model.messageId),
      orderIndex: Value(model.orderIndex),
      type: Value(model.type),
      content: Value(model.content),
      thinkingMillsec: Value(model.thinkingMillsec),
      url: Value(model.url),
      fileJson: Value(model.file != null ? jsonEncode(model.file) : null),
      toolJson: Value(
        model.toolId != null || model.toolName != null
            ? jsonEncode({
                'toolId': model.toolId,
                'toolName': model.toolName,
                'arguments': model.arguments,
              })
            : null,
      ),
      errorJson: Value(model.error != null ? jsonEncode(model.error) : null),
      targetLanguage: Value(model.targetLanguage),
      responseJson:
          Value(model.response != null ? jsonEncode(model.response) : null),
      knowledgeJson:
          Value(model.knowledge != null ? jsonEncode(model.knowledge) : null),
      createdAt: Value(model.createdAt),
    );
  }

  @override
  Future<int> getMessageCount(String topicId) async {
    final countExp = _db.messages.messageId.count();
    final row = await (_db.selectOnly(_db.messages)
          ..addColumns([countExp])
          ..where(_db.messages.topicId.equals(topicId)))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<List<MessageModel>> loadMessages(
    String topicId, {
    int offset = 0,
    int limit = 20,
  }) async {
    final query = _db.select(_db.messages)
      ..where((t) => t.topicId.equals(topicId))
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])
      ..limit(limit, offset: offset);
    final rows = await query.get();
    return rows.map(_toMessageModel).toList();
  }

  @override
  Future<List<MessageModel>> loadRounds(
    String topicId, {
    int startRound = 0,
    int roundCount = 5,
  }) async {
    final endRound = startRound + roundCount - 1;
    final query = _db.select(_db.messages)
      ..where((t) =>
          t.topicId.equals(topicId) &
          t.roundIndex.isBetweenValues(startRound, endRound))
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    final rows = await query.get();
    return rows.map(_toMessageModel).toList();
  }

  @override
  Future<int> getRoundCount(String topicId) async {
    final query = _db.select(_db.topics)
      ..where((t) => t.topicId.equals(topicId))
      ..limit(1);
    final topic = await query.getSingleOrNull();
    return topic?.roundCount ?? 0;
  }

  @override
  Future<MessageModel?> getMessage(String messageId) async {
    final query = _db.select(_db.messages)
      ..where((t) => t.messageId.equals(messageId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toMessageModel(row);
  }

  @override
  Future<List<MessageModel>> loadAllMessages(String topicId) async {
    final query = _db.select(_db.messages)
      ..where((t) => t.topicId.equals(topicId))
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    final rows = await query.get();
    return rows.map(_toMessageModel).toList();
  }

  @override
  Future<Map<String, List<MessageModel>>> getAllUserMessages() async {
    final query = _db.select(_db.messages)
      ..where((t) => t.role.equals('user'))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    final rows = await query.get();
    final grouped = <String, List<MessageModel>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.topicId, () => []).add(_toMessageModel(row));
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.roundIndex.compareTo(b.roundIndex));
    }
    return grouped;
  }

  @override
  Future<List<BlockModel>> loadBlocks(String messageId) async {
    final query = _db.select(_db.messageBlocks)
      ..where((t) => t.messageId.equals(messageId))
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    final rows = await query.get();
    return rows.map(_toBlockModel).toList();
  }

  @override
  Future<Map<String, List<BlockModel>>> batchLoadBlocks(
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return {};
    final rows = await (_db.select(_db.messageBlocks)
          ..where((t) => t.messageId.isIn(messageIds))
          ..orderBy([
            (t) => OrderingTerm.asc(t.messageId),
            (t) => OrderingTerm.asc(t.orderIndex),
          ]))
        .get();
    final grouped = <String, List<BlockModel>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.messageId, () => []).add(_toBlockModel(row));
    }
    return grouped;
  }

  @override
  Future<Map<String, List<BlockModel>>> loadBlocksByTopic(String topicId) async {
    final rows = await (_db.select(_db.messageBlocks)
          ..where((t) => t.topicId.equals(topicId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.messageId),
            (t) => OrderingTerm.asc(t.orderIndex),
          ]))
        .get();
    final grouped = <String, List<BlockModel>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.messageId, () => []).add(_toBlockModel(row));
    }
    return grouped;
  }

  @override
  Future<void> saveMessage(MessageModel message) async {
    await _db.into(_db.messages).insertOnConflictUpdate(_toMessageCompanion(message));
  }

  @override
  Future<void> saveMessages(List<MessageModel> messages) async {
    if (messages.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(
        _db.messages,
        messages.map(_toMessageCompanion).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await (_db.delete(_db.messages)..where((t) => t.messageId.equals(messageId)))
        .go();
  }

  @override
  Future<void> deleteMessagesByTopic(String topicId) async {
    await (_db.delete(_db.messages)..where((t) => t.topicId.equals(topicId)))
        .go();
  }

  @override
  Future<void> clearAllMessages() async {
    await _db.delete(_db.messages).go();
  }

  @override
  Future<void> saveBlock(BlockModel block) async {
    await _db.into(_db.messageBlocks).insertOnConflictUpdate(_toBlockCompanion(block));
  }

  @override
  Future<void> saveBlocks(List<BlockModel> blocks) async {
    if (blocks.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(
        _db.messageBlocks,
        blocks.map(_toBlockCompanion).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    await (_db.delete(_db.messageBlocks)..where((t) => t.blockId.equals(blockId)))
        .go();
  }

  @override
  Future<void> deleteBlocksByMessage(String messageId) async {
    await (_db.delete(_db.messageBlocks)
          ..where((t) => t.messageId.equals(messageId)))
        .go();
  }

  @override
  Future<void> clearAllBlocks() async {
    await _db.delete(_db.messageBlocks).go();
  }

  @override
  Stream<List<MessageModel>> watchMessages(String topicId) {
    final query = _db.select(_db.messages)
      ..where((t) => t.topicId.equals(topicId))
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    return query.watch().map((rows) => rows.map(_toMessageModel).toList());
  }
}
