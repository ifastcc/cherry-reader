import '../../search_service.dart';
import 'mcp_tool_base.dart';

/// 搜索对话内容
///
/// 支持关键词搜索话题名称和消息内容
class SearchConversationsTool extends MCPTool {
  @override
  String get name => 'search_conversations';

  @override
  String get description => '''搜索对话内容，支持关键词搜索。

搜索范围：
- 话题名称
- 消息内容（仅主要文本）

返回匹配的话题和消息片段，包含上下文。''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'keyword': {
            'type': 'string',
            'description': '搜索关键词',
          },
          'limit': {
            'type': 'integer',
            'description': '返回结果数量限制，默认 20',
          },
        },
        'required': ['keyword'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final keyword = arguments['keyword'] as String?;
    if (keyword == null || keyword.isEmpty) {
      throw ArgumentError('keyword is required');
    }

    final limit = arguments['limit'] as int? ?? 20;

    // 初始化搜索服务
    SearchService.instance.init();

    // 执行搜索
    final groups = await SearchService.instance.search(keyword);

    // 扁平化结果
    final results = <Map<String, dynamic>>[];
    for (final group in groups) {
      for (final result in group.results) {
        if (results.length >= limit) break;

        results.add({
          'type': result.type.name,
          'topic_id': result.topicId,
          'topic_name': result.topicName,
          'assistant_name': result.assistantName,
          'message_id': result.messageId,
          'snippet': result.matchSnippet,
          'match_start': result.matchStart,
          'match_end': result.matchEnd,
          'role': result.role,
          'model_name': result.modelName,
          'created_at': result.dateTime.toIso8601String(),
        });
      }
      if (results.length >= limit) break;
    }

    return {
      'keyword': keyword,
      'total': results.length,
      'results': results,
    };
  }
}
