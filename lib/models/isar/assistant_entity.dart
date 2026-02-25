/// 助手 Isar 实体
///
/// 存储 Cherry Studio 导入的助手元数据
class AssistantEntity {
  /// 助手 ID（唯一索引）
  late String assistantId;

  /// 助手名称
  late String name;

  /// 助手描述
  String? description;

  /// 头像 URL 或 Base64
  String? avatar;

  /// 系统提示词
  String? prompt;

  /// 话题数量（冗余字段，提升查询性能）
  late int topicCount;

  /// 创建时间（毫秒时间戳）
  late int createdAt;

  /// 更新时间
  late int updatedAt;

  /// 构造函数
  AssistantEntity();

  /// 从数据创建
  factory AssistantEntity.fromData({
    required String assistantId,
    required String name,
    String? description,
    String? avatar,
    String? prompt,
    int topicCount = 0,
    int? createdAt,
    int? updatedAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return AssistantEntity()
      ..assistantId = assistantId
      ..name = name
      ..description = description
      ..avatar = avatar
      ..prompt = prompt
      ..topicCount = topicCount
      ..createdAt = createdAt ?? now
      ..updatedAt = updatedAt ?? now;
  }
}
