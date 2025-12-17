import '../../repository_provider.dart';
import 'mcp_tool_base.dart';

/// 获取相关话题
///
/// 基于助手和时间找到相关的话题
class GetRelatedTopicsTool extends MCPTool {
  @override
  String get name => 'get_related_topics';

  @override
  String get description => '''获取与指定话题相关的其他话题。

关联规则：
- 同一助手下的话题
- 按时间接近度排序

适用于：
- 找到同一主题的历史讨论
- 发现相关上下文''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'topic_id': {
            'type': 'string',
            'description': '参考话题 ID',
          },
          'limit': {
            'type': 'integer',
            'description': '返回数量，默认 5',
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

    final limit = arguments['limit'] as int? ?? 5;
    final topicRepo = RepositoryProvider.instance.topicRepository;

    // 获取参考话题
    final topic = await topicRepo.getTopic(topicId);
    if (topic == null) {
      throw Exception('Topic not found: $topicId');
    }

    // 获取同助手的话题
    final sameAssistant = await topicRepo.getTopicsByAssistant(topic.assistantId);

    // 按时间接近度排序（排除自身）
    final related = sameAssistant.where((t) => t.topicId != topicId).toList()
      ..sort((a, b) {
        final diffA = (a.updatedAt - topic.updatedAt).abs();
        final diffB = (b.updatedAt - topic.updatedAt).abs();
        return diffA.compareTo(diffB);
      });

    return {
      'reference_topic': {
        'id': topic.topicId,
        'name': topic.name,
        'assistant_id': topic.assistantId,
      },
      'related_topics': related.take(limit).map((t) {
        final timeDiff = t.updatedAt - topic.updatedAt;
        final daysDiff = (timeDiff / (1000 * 60 * 60 * 24)).abs().round();

        return {
          'id': t.topicId,
          'name': t.name,
          'message_count': t.messageCount,
          'round_count': t.roundCount,
          'days_diff': daysDiff,
          'relation': timeDiff > 0 ? 'after' : 'before',
          'updated_at':
              DateTime.fromMillisecondsSinceEpoch(t.updatedAt).toIso8601String(),
        };
      }).toList(),
    };
  }
}
