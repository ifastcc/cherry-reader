/// 助手领域模型（与数据库无关）
///
/// 用于 Repository 层和 UI 层的数据传输
class AssistantModel {
  final String assistantId;
  final String name;
  final String? description;
  final String? avatar;
  final String? prompt;
  final int topicCount;
  final int createdAt;
  final int updatedAt;

  const AssistantModel({
    required this.assistantId,
    required this.name,
    this.description,
    this.avatar,
    this.prompt,
    required this.topicCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建副本
  AssistantModel copyWith({
    String? assistantId,
    String? name,
    String? description,
    String? avatar,
    String? prompt,
    int? topicCount,
    int? createdAt,
    int? updatedAt,
  }) {
    return AssistantModel(
      assistantId: assistantId ?? this.assistantId,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      prompt: prompt ?? this.prompt,
      topicCount: topicCount ?? this.topicCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'AssistantModel(id: $assistantId, name: $name, topicCount: $topicCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantModel &&
          runtimeType == other.runtimeType &&
          assistantId == other.assistantId;

  @override
  int get hashCode => assistantId.hashCode;
}
