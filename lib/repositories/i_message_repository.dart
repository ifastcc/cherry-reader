import '../models/domain/message_model.dart';
import '../models/domain/block_model.dart';

/// 消息仓库抽象接口
///
/// 定义消息数据的访问接口，支持分页加载和按轮次查询
/// 与具体数据库实现无关
abstract class IMessageRepository {
  // ========== 消息查询 ==========

  /// 获取话题的消息数量
  Future<int> getMessageCount(String topicId);

  /// 分页加载消息
  ///
  /// [topicId] 话题 ID
  /// [offset] 起始位置
  /// [limit] 每页数量
  Future<List<MessageModel>> loadMessages(
    String topicId, {
    int offset = 0,
    int limit = 20,
  });

  /// 按轮次分页加载（推荐：与 UI 展示逻辑一致）
  ///
  /// 一个轮次 = 一个用户问题 + 所有 AI 回复
  /// 这样分页不会截断多模型回复
  ///
  /// [topicId] 话题 ID
  /// [startRound] 起始轮次
  /// [roundCount] 加载轮次数
  Future<List<MessageModel>> loadRounds(
    String topicId, {
    int startRound = 0,
    int roundCount = 5,
  });

  /// 获取话题的轮次总数
  Future<int> getRoundCount(String topicId);

  /// 根据 ID 获取单条消息
  Future<MessageModel?> getMessage(String messageId);

  /// 获取话题的所有消息（慎用：可能数据量大）
  Future<List<MessageModel>> loadAllMessages(String topicId);

  // ========== Block 查询 ==========

  /// 加载消息的所有 Block
  Future<List<BlockModel>> loadBlocks(String messageId);

  /// 批量加载多条消息的 Block（避免 N+1 问题）
  ///
  /// 返回 Map<messageId, List<BlockModel>>
  Future<Map<String, List<BlockModel>>> batchLoadBlocks(
    List<String> messageIds,
  );

  /// 【优化】通过 topicId 加载所有 Block（比 anyOf 更快）
  ///
  /// 返回 Map<messageId, List<BlockModel>>
  Future<Map<String, List<BlockModel>>> loadBlocksByTopic(String topicId);

  // ========== 消息写入 ==========

  /// 保存消息
  Future<void> saveMessage(MessageModel message);

  /// 批量保存消息
  Future<void> saveMessages(List<MessageModel> messages);

  /// 删除消息
  Future<void> deleteMessage(String messageId);

  /// 删除话题的所有消息
  Future<void> deleteMessagesByTopic(String topicId);

  /// 清空所有消息
  Future<void> clearAllMessages();

  // ========== Block 写入 ==========

  /// 保存 Block
  Future<void> saveBlock(BlockModel block);

  /// 批量保存 Block
  Future<void> saveBlocks(List<BlockModel> blocks);

  /// 删除 Block
  Future<void> deleteBlock(String blockId);

  /// 删除消息的所有 Block
  Future<void> deleteBlocksByMessage(String messageId);

  /// 清空所有 Block
  Future<void> clearAllBlocks();

  // ========== 监听 ==========

  /// 监听消息变化
  Stream<List<MessageModel>> watchMessages(String topicId);
}
