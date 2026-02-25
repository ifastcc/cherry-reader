class TopicNameHit {
  final String topicId;
  final String topicName;
  final int createdAt;
  final List<String> assistantIds;
  final List<String> assistantNames;
  final String? contentPreview;

  const TopicNameHit({
    required this.topicId,
    required this.topicName,
    required this.createdAt,
    required this.assistantIds,
    required this.assistantNames,
    this.contentPreview,
  });
}

class MessageContentHit {
  final String blockId;
  final String topicId;
  final String topicName;
  final String messageId;
  final String? role;
  final String? modelName;
  final int? roundIndex;
  final int createdAt;
  final String content;
  final List<String> assistantIds;
  final List<String> assistantNames;

  const MessageContentHit({
    required this.blockId,
    required this.topicId,
    required this.topicName,
    required this.messageId,
    required this.createdAt,
    required this.content,
    required this.assistantIds,
    required this.assistantNames,
    this.role,
    this.modelName,
    this.roundIndex,
  });
}
