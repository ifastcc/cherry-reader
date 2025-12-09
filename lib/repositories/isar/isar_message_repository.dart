import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../models/domain/message_model.dart';
import '../../models/domain/block_model.dart';
import '../../models/isar/message_entity.dart';
import '../../models/isar/message_block_entity.dart';
import '../../models/isar/topic_entity.dart';
import '../../services/isar_database.dart';
import '../i_message_repository.dart';

/// 消息仓库 Isar 实现
///
/// 支持分页加载和按轮次查询，解决大话题的性能问题
class IsarMessageRepository implements IMessageRepository {
  final IsarDatabase _db;

  IsarMessageRepository(this._db);

  // ========== 转换方法 ==========

  MessageModel _toMessageModel(MessageEntity entity) {
    return MessageModel(
      messageId: entity.messageId,
      topicId: entity.topicId,
      orderIndex: entity.orderIndex,
      roundIndex: entity.roundIndex,
      role: entity.role,
      askId: entity.askId,
      useful: entity.useful,
      modelId: entity.modelId,
      modelName: entity.modelName,
      createdAt: entity.createdAt,
      status: entity.status,
      usage: MessageModel.parseUsageJson(entity.usageJson),
      metrics: MessageModel.parseMetricsJson(entity.metricsJson),
      mentions: MessageModel.parseMentionsJson(entity.mentionsJson),
    );
  }

  MessageEntity _toMessageEntity(MessageModel model) {
    return MessageEntity.fromData(
      messageId: model.messageId,
      topicId: model.topicId,
      orderIndex: model.orderIndex,
      roundIndex: model.roundIndex,
      role: model.role,
      askId: model.askId,
      useful: model.useful,
      modelId: model.modelId,
      modelName: model.modelName,
      usageJson: model.usage != null ? jsonEncode(model.usage) : null,
      metricsJson: model.metrics != null ? jsonEncode(model.metrics) : null,
      mentionsJson: model.mentions != null ? jsonEncode(model.mentions) : null,
      createdAt: model.createdAt,
      status: model.status,
    );
  }

  BlockModel _toBlockModel(MessageBlockEntity entity) {
    // 解析 toolJson
    final toolData = BlockModel.parseToolJson(entity.toolJson);
    // 解析 citation 字段
    final responseData = BlockModel.parseFileJson(entity.responseJson);
    final knowledgeData = BlockModel.parseFileJson(entity.knowledgeJson);

    return BlockModel(
      blockId: entity.blockId,
      topicId: entity.topicId,
      messageId: entity.messageId,
      orderIndex: entity.orderIndex,
      type: entity.type,
      createdAt: entity.createdAt,
      content: entity.content,
      thinkingMillsec: entity.thinkingMillsec,
      url: entity.url,
      file: BlockModel.parseFileJson(entity.fileJson),
      error: BlockModel.parseErrorJson(entity.errorJson),
      targetLanguage: entity.targetLanguage,
      // tool 块字段
      toolId: toolData?['toolId'] as String?,
      toolName: toolData?['toolName'] as String?,
      arguments: toolData?['arguments'] as Map<String, dynamic>?,
      // citation 块字段
      response: responseData,
      knowledge: knowledgeData,
    );
  }

  MessageBlockEntity _toBlockEntity(BlockModel model) {
    return MessageBlockEntity.fromData(
      blockId: model.blockId,
      topicId: model.topicId,
      messageId: model.messageId,
      orderIndex: model.orderIndex,
      type: model.type,
      content: model.content,
      thinkingMillsec: model.thinkingMillsec,
      url: model.url,
      fileJson: model.file != null ? jsonEncode(model.file) : null,
      toolJson: model.toolId != null || model.toolName != null
          ? jsonEncode({
              'toolId': model.toolId,
              'toolName': model.toolName,
              'arguments': model.arguments,
            })
          : null,
      errorJson: model.error != null ? jsonEncode(model.error) : null,
      targetLanguage: model.targetLanguage,
      // citation 块字段
      responseJson: model.response != null ? jsonEncode(model.response) : null,
      knowledgeJson: model.knowledge != null ? jsonEncode(model.knowledge) : null,
      createdAt: model.createdAt,
    );
  }

  // ========== 消息查询 ==========

  @override
  Future<int> getMessageCount(String topicId) async {
    try {
      final isar = await _db.instance;
      return isar.messageEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .count();
    } on IsarError catch (e) {
      print('❌ 获取消息数量失败: $e');
      return 0;
    }
  }

  @override
  Future<List<MessageModel>> loadMessages(
    String topicId, {
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final isar = await _db.instance;
      final entities = await isar.messageEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .sortByOrderIndex()
          .offset(offset)
          .limit(limit)
          .findAll();
      return entities.map(_toMessageModel).toList();
    } on IsarError catch (e) {
      print('❌ 加载消息失败: $e');
      return [];
    }
  }

  @override
  Future<List<MessageModel>> loadRounds(
    String topicId, {
    int startRound = 0,
    int roundCount = 5,
  }) async {
    try {
      final isar = await _db.instance;
      final entities = await isar.messageEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .roundIndexBetween(startRound, startRound + roundCount - 1)
          .sortByOrderIndex()
          .findAll();
      return entities.map(_toMessageModel).toList();
    } on IsarError catch (e) {
      print('❌ 按轮次加载失败: $e');
      return [];
    }
  }

  @override
  Future<int> getRoundCount(String topicId) async {
    try {
      final isar = await _db.instance;
      final topic = await isar.topicEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .findFirst();
      return topic?.roundCount ?? 0;
    } on IsarError catch (e) {
      print('❌ 获取轮次数量失败: $e');
      return 0;
    }
  }

  @override
  Future<MessageModel?> getMessage(String messageId) async {
    try {
      final isar = await _db.instance;
      final entity = await isar.messageEntitys
          .filter()
          .messageIdEqualTo(messageId)
          .findFirst();
      return entity != null ? _toMessageModel(entity) : null;
    } on IsarError catch (e) {
      print('❌ 获取消息失败: $e');
      return null;
    }
  }

  @override
  Future<List<MessageModel>> loadAllMessages(String topicId) async {
    try {
      final sw = Stopwatch()..start();
      final isar = await _db.instance;
      debugPrint('⏱️ [Isar] loadAllMessages - 获取实例: ${sw.elapsedMilliseconds}ms');

      sw.reset();
      final entities = await isar.messageEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .sortByOrderIndex()
          .findAll();
      debugPrint('⏱️ [Isar] loadAllMessages - 查询 (${entities.length}条): ${sw.elapsedMilliseconds}ms');

      sw.reset();
      final result = entities.map(_toMessageModel).toList();
      debugPrint('⏱️ [Isar] loadAllMessages - 转换Model: ${sw.elapsedMilliseconds}ms');

      return result;
    } on IsarError catch (e) {
      print('❌ 加载所有消息失败: $e');
      return [];
    }
  }

  // ========== Block 查询 ==========

  @override
  Future<List<BlockModel>> loadBlocks(String messageId) async {
    try {
      final isar = await _db.instance;
      final entities = await isar.messageBlockEntitys
          .filter()
          .messageIdEqualTo(messageId)
          .sortByOrderIndex()
          .findAll();
      return entities.map(_toBlockModel).toList();
    } on IsarError catch (e) {
      print('❌ 加载 Block 失败: $e');
      return [];
    }
  }

  @override
  Future<Map<String, List<BlockModel>>> batchLoadBlocks(
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return {};

    try {
      final sw = Stopwatch()..start();
      final isar = await _db.instance;
      debugPrint('⏱️ [Isar] batchLoadBlocks - 获取实例: ${sw.elapsedMilliseconds}ms');

      sw.reset();
      final entities = await isar.messageBlockEntitys
          .filter()
          .anyOf(messageIds, (q, id) => q.messageIdEqualTo(id))
          .findAll();
      debugPrint('⏱️ [Isar] batchLoadBlocks - 查询 (${entities.length}个Block): ${sw.elapsedMilliseconds}ms');

      sw.reset();
      final grouped = <String, List<BlockModel>>{};
      for (final entity in entities) {
        grouped
            .putIfAbsent(entity.messageId, () => [])
            .add(_toBlockModel(entity));
      }
      debugPrint('⏱️ [Isar] batchLoadBlocks - 分组+转换Model: ${sw.elapsedMilliseconds}ms');

      // 按 orderIndex 排序
      sw.reset();
      for (final list in grouped.values) {
        list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      }
      debugPrint('⏱️ [Isar] batchLoadBlocks - 排序: ${sw.elapsedMilliseconds}ms');

      return grouped;
    } on IsarError catch (e) {
      print('❌ 批量加载 Block 失败: $e');
      return {};
    }
  }

  @override
  Future<Map<String, List<BlockModel>>> loadBlocksByTopic(String topicId) async {
    try {
      final sw = Stopwatch()..start();
      final isar = await _db.instance;
      debugPrint('⏱️ [Isar] loadBlocksByTopic - 获取实例: ${sw.elapsedMilliseconds}ms');

      // 【优化】直接通过 topicId 查询，避免 anyOf 的 O(n²) 问题
      sw.reset();
      final entities = await isar.messageBlockEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .findAll();
      debugPrint('⏱️ [Isar] loadBlocksByTopic - 查询 (${entities.length}个Block): ${sw.elapsedMilliseconds}ms');

      sw.reset();
      final grouped = <String, List<BlockModel>>{};
      for (final entity in entities) {
        grouped
            .putIfAbsent(entity.messageId, () => [])
            .add(_toBlockModel(entity));
      }
      debugPrint('⏱️ [Isar] loadBlocksByTopic - 分组+转换Model: ${sw.elapsedMilliseconds}ms');

      // 按 orderIndex 排序
      sw.reset();
      for (final list in grouped.values) {
        list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      }
      debugPrint('⏱️ [Isar] loadBlocksByTopic - 排序: ${sw.elapsedMilliseconds}ms');

      return grouped;
    } on IsarError catch (e) {
      print('❌ 通过 topicId 加载 Block 失败: $e');
      return {};
    }
  }

  // ========== 消息写入 ==========

  @override
  Future<void> saveMessage(MessageModel message) async {
    try {
      final isar = await _db.instance;
      final entity = _toMessageEntity(message);
      await isar.writeTxn(() async {
        await isar.messageEntitys.put(entity);
      });
    } on IsarError catch (e) {
      print('❌ 保存消息失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveMessages(List<MessageModel> messages) async {
    if (messages.isEmpty) return;

    try {
      final isar = await _db.instance;
      final entities = messages.map(_toMessageEntity).toList();
      await isar.writeTxn(() async {
        await isar.messageEntitys.putAll(entities);
      });
    } on IsarError catch (e) {
      print('❌ 批量保存消息失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.messageEntitys
            .filter()
            .messageIdEqualTo(messageId)
            .deleteFirst();
      });
    } on IsarError catch (e) {
      print('❌ 删除消息失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessagesByTopic(String topicId) async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.messageEntitys
            .filter()
            .topicIdEqualTo(topicId)
            .deleteAll();
      });
    } on IsarError catch (e) {
      print('❌ 删除话题消息失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAllMessages() async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.messageEntitys.clear();
      });
    } on IsarError catch (e) {
      print('❌ 清空消息失败: $e');
      rethrow;
    }
  }

  // ========== Block 写入 ==========

  @override
  Future<void> saveBlock(BlockModel block) async {
    try {
      final isar = await _db.instance;
      final entity = _toBlockEntity(block);
      await isar.writeTxn(() async {
        await isar.messageBlockEntitys.put(entity);
      });
    } on IsarError catch (e) {
      print('❌ 保存 Block 失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveBlocks(List<BlockModel> blocks) async {
    if (blocks.isEmpty) return;

    try {
      final isar = await _db.instance;
      final entities = blocks.map(_toBlockEntity).toList();
      await isar.writeTxn(() async {
        await isar.messageBlockEntitys.putAll(entities);
      });
    } on IsarError catch (e) {
      print('❌ 批量保存 Block 失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.messageBlockEntitys
            .filter()
            .blockIdEqualTo(blockId)
            .deleteFirst();
      });
    } on IsarError catch (e) {
      print('❌ 删除 Block 失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBlocksByMessage(String messageId) async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.messageBlockEntitys
            .filter()
            .messageIdEqualTo(messageId)
            .deleteAll();
      });
    } on IsarError catch (e) {
      print('❌ 删除消息 Block 失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAllBlocks() async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.messageBlockEntitys.clear();
      });
    } on IsarError catch (e) {
      print('❌ 清空 Block 失败: $e');
      rethrow;
    }
  }

  // ========== 监听 ==========

  @override
  Stream<List<MessageModel>> watchMessages(String topicId) {
    return _db.instanceSync.messageEntitys
        .filter()
        .topicIdEqualTo(topicId)
        .sortByOrderIndex()
        .watch(fireImmediately: true)
        .map((entities) => entities.map(_toMessageModel).toList());
  }
}
