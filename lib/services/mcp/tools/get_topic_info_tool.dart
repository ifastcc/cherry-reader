import '../../repository_provider.dart';
import 'mcp_tool_base.dart';

/// 获取单个话题的详细元数据
class GetTopicInfoTool extends MCPTool {
  @override
  String get name => 'get_topic_info';

  @override
  String get description => '''获取单个话题的详细元数据。

返回内容包括：
- 话题基本信息（名称、创建时间等）
- 关联的助手信息
- 消息统计（轮次数、消息数）
- 首条消息预览''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'topic_id': {
            'type': 'string',
            'description': '话题 ID',
          },
        },
        'required': ['topic_id'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final topicId = arguments['topic_id'] as String?;
    if (topicId == null || topicId.isEmpty) {
      throw ArgumentError('topic_id is required');
    }

    final topicRepo = RepositoryProvider.instance.topicRepository;
    final assistantRepo = RepositoryProvider.instance.assistantRepository;
    final messageRepo = RepositoryProvider.instance.messageRepository;

    // 获取话题
    final topic = await topicRepo.getTopic(topicId);
    if (topic == null) {
      throw Exception('Topic not found: $topicId');
    }

    // 获取助手信息
    final assistant = await assistantRepo.getAssistant(topic.assistantId);

    // 获取首轮消息预览
    final firstRound =
        await messageRepo.loadRounds(topicId, startRound: 0, roundCount: 1);

    // 统计使用的模型
    final allMessages = await messageRepo.loadAllMessages(topicId);
    final modelSet = <String>{};
    for (final msg in allMessages) {
      if (msg.modelName != null && msg.modelName!.isNotEmpty) {
        modelSet.add(msg.modelName!);
      }
    }

    return {
      'id': topic.topicId,
      'name': topic.name,
      'assistant': assistant != null
          ? {
              'id': assistant.assistantId,
              'name': assistant.name,
              'description': assistant.description,
            }
          : null,
      'message_count': topic.messageCount,
      'round_count': topic.roundCount,
      'models_used': modelSet.toList(),
      'created_at':
          DateTime.fromMillisecondsSinceEpoch(topic.createdAt).toIso8601String(),
      'updated_at':
          DateTime.fromMillisecondsSinceEpoch(topic.updatedAt).toIso8601String(),
      'first_message_preview': firstRound.isNotEmpty
          ? {
              'role': firstRound.first.role,
              'model': firstRound.first.displayModelName,
            }
          : null,
    };
  }
}
