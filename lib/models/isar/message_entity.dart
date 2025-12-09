import 'package:isar_community/isar.dart';

part 'message_entity.g.dart';

/// 消息 Isar 实体
///
/// 存储消息的元数据和关联信息，不存储实际文本内容
/// 实际内容存储在 MessageBlockEntity 中
@collection
class MessageEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 消息 ID（唯一索引）
  @Index(unique: true)
  late String messageId;

  /// 所属话题 ID（复合索引：topicId + orderIndex）
  @Index(composite: [CompositeIndex('orderIndex')])
  late String topicId;

  /// 在话题中的顺序（0, 1, 2, 3...）
  late int orderIndex;

  /// 所属轮次索引（用于按轮次分页）
  @Index()
  late int roundIndex;

  /// 角色：user / assistant
  late String role;

  /// 同一问题的回复分组 ID
  @Index()
  String? askId;

  /// 是否为主线回复
  late bool useful;

  /// 模型 ID
  String? modelId;

  /// 模型名称
  String? modelName;

  /// Token 统计 (JSON)
  String? usageJson;

  /// 性能指标 (JSON)
  String? metricsJson;

  /// @mention 列表 (JSON)
  String? mentionsJson;

  /// 创建时间（毫秒时间戳）
  @Index()
  late int createdAt;

  /// 消息状态
  late String status;

  /// 构造函数
  MessageEntity();

  /// 从数据创建
  factory MessageEntity.fromData({
    required String messageId,
    required String topicId,
    required int orderIndex,
    required int roundIndex,
    required String role,
    String? askId,
    bool useful = true,
    String? modelId,
    String? modelName,
    String? usageJson,
    String? metricsJson,
    String? mentionsJson,
    required int createdAt,
    required String status,
  }) {
    return MessageEntity()
      ..messageId = messageId
      ..topicId = topicId
      ..orderIndex = orderIndex
      ..roundIndex = roundIndex
      ..role = role
      ..askId = askId
      ..useful = useful
      ..modelId = modelId
      ..modelName = modelName
      ..usageJson = usageJson
      ..metricsJson = metricsJson
      ..mentionsJson = mentionsJson
      ..createdAt = createdAt
      ..status = status;
  }

  /// 是否为用户消息
  bool get isUser => role == 'user';

  /// 是否为助手消息
  bool get isAssistant => role == 'assistant';
}
