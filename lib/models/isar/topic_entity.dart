import 'package:isar_community/isar.dart';

part 'topic_entity.g.dart';

/// 话题 Isar 实体（新架构）
///
/// 存储话题的轻量级元数据，不存储消息内容
/// 替代旧的 TopicCacheEntity，不再使用 dataJson
@collection
class TopicEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 话题 ID（唯一索引）
  @Index(unique: true)
  late String topicId;

  /// 话题名称
  late String name;

  /// 所属 Assistant IDs（支持多归属）
  /// Isar 会为列表中的每个元素创建索引
  @Index()
  late List<String> assistantIds;

  /// 消息数量
  late int messageCount;

  /// 对话轮数
  late int roundCount;

  /// 创建时间（毫秒时间戳）
  @Index()
  late int createdAt;

  /// 更新时间
  late int updatedAt;

  /// 构造函数
  TopicEntity();

  /// 从数据创建
  factory TopicEntity.fromData({
    required String topicId,
    required String name,
    required List<String> assistantIds,
    required int messageCount,
    required int roundCount,
    int? createdAt,
    int? updatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TopicEntity()
      ..topicId = topicId
      ..name = name
      ..assistantIds = assistantIds
      ..messageCount = messageCount
      ..roundCount = roundCount
      ..createdAt = createdAt ?? now
      ..updatedAt = updatedAt ?? now;
  }
}
