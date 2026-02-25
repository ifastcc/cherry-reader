class QueryItem {
  final String topicId;
  final String topicName;
  final String messageId;
  final String preview;
  final int charCount;
  final DateTime timestamp;

  QueryItem({
    required this.topicId,
    required this.topicName,
    required this.messageId,
    required this.preview,
    required this.charCount,
    required this.timestamp,
  });
}

class TopicGroup {
  final String topicId;
  final String topicName;
  final List<String> assistantIds;
  final List<String> assistantNames;
  final List<QueryItem> queries;
  final int totalCharCount;
  final int roundCount;
  final DateTime latestTime;

  TopicGroup({
    required this.topicId,
    required this.topicName,
    required this.assistantIds,
    required this.assistantNames,
    required this.queries,
    required this.totalCharCount,
    required this.roundCount,
    required this.latestTime,
  });
}

class MonthGroup {
  final String label;
  final List<TopicGroup> topicGroups;

  MonthGroup({
    required this.label,
    required this.topicGroups,
  });
}

class AssistantStats {
  final String id;
  final String name;
  final int topicCount;
  final int messageCount;
  final DateTime? latestTime;

  AssistantStats({
    required this.id,
    required this.name,
    required this.topicCount,
    required this.messageCount,
    this.latestTime,
  });
}
