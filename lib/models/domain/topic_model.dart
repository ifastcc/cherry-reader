/// 话题领域模型（与数据库无关）
///
/// 用于 Repository 层和 UI 层的数据传输
/// 只存储元数据，不存储消息内容
class TopicModel {
  final String topicId;
  final String name;
  final String assistantId;
  final int messageCount;
  final int roundCount;
  final int createdAt;
  final int updatedAt;

  const TopicModel({
    required this.topicId,
    required this.name,
    required this.assistantId,
    required this.messageCount,
    required this.roundCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建副本
  TopicModel copyWith({
    String? topicId,
    String? name,
    String? assistantId,
    int? messageCount,
    int? roundCount,
    int? createdAt,
    int? updatedAt,
  }) {
    return TopicModel(
      topicId: topicId ?? this.topicId,
      name: name ?? this.name,
      assistantId: assistantId ?? this.assistantId,
      messageCount: messageCount ?? this.messageCount,
      roundCount: roundCount ?? this.roundCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'TopicModel(id: $topicId, name: $name, messages: $messageCount, rounds: $roundCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicModel &&
          runtimeType == other.runtimeType &&
          topicId == other.topicId;

  @override
  int get hashCode => topicId.hashCode;
}
