import 'assistant_model.dart';
import 'topic_model.dart';
import 'message_model.dart';
import 'block_model.dart';
import '../isar/file_entity.dart';

class TopicAssistantLink {
  final String topicId;
  final String assistantId;

  const TopicAssistantLink({
    required this.topicId,
    required this.assistantId,
  });
}

class ExportSnapshot {
  final List<AssistantModel> assistants;
  final List<TopicModel> topics;
  final List<TopicAssistantLink> topicAssistantLinks;
  final List<MessageModel> messages;
  final List<BlockModel> blocks;
  final List<FileEntity> files;

  const ExportSnapshot({
    required this.assistants,
    required this.topics,
    required this.topicAssistantLinks,
    required this.messages,
    required this.blocks,
    required this.files,
  });
}
