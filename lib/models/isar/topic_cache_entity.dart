import 'package:isar/isar.dart';

part 'topic_cache_entity.g.dart';

/// Isar 话题缓存实体
///
/// 存储话题的轻量级元数据，用于快速加载列表
/// 完整的话题数据按需加载，避免一次性加载所有数据
@collection
class TopicCacheEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 话题 ID（建立索引）
  @Index(unique: true)
  late String topicId;

  /// 话题名称
  late String name;

  /// 所属 Assistant ID
  @Index()
  late String assistantId;

  /// 消息数量
  late int messageCount;

  /// 创建时间（毫秒时间戳）
  late int createdAt;

  /// 更新时间
  late int updatedAt;

  /// 完整的话题数据（JSON 字符串）
  /// 只在需要时才反序列化
  late String dataJson;

  /// 数据版本号（用于缓存失效检测）
  late int version;

  /// 构造函数
  TopicCacheEntity();

  /// 从 Map 创建
  factory TopicCacheEntity.fromTopicData(
    String topicId,
    String name,
    String assistantId,
    int messageCount,
    String dataJson,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TopicCacheEntity()
      ..topicId = topicId
      ..name = name
      ..assistantId = assistantId
      ..messageCount = messageCount
      ..createdAt = now
      ..updatedAt = now
      ..dataJson = dataJson
      ..version = 1;
  }
}
