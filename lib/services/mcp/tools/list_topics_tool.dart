import '../../repository_provider.dart';
import 'mcp_tool_base.dart';

/// 获取话题列表
///
/// 支持按时间范围和助手过滤
class ListTopicsTool extends MCPTool {
  @override
  String get name => 'list_topics';

  @override
  String get description => '''获取话题列表，支持按时间范围和助手过滤。

可以用于：
- 查看最近的话题
- 按时间范围筛选（如"本周"、"本月"）
- 按助手分类查看''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'assistant_id': {
            'type': 'string',
            'description': '按助手 ID 过滤（可选）',
          },
          'start_date': {
            'type': 'string',
            'description': '开始日期，格式 YYYY-MM-DD（可选）',
          },
          'end_date': {
            'type': 'string',
            'description': '结束日期，格式 YYYY-MM-DD（可选）',
          },
          'limit': {
            'type': 'integer',
            'description': '返回数量限制，默认 50',
          },
          'offset': {
            'type': 'integer',
            'description': '偏移量，用于分页，默认 0',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final topicRepo = RepositoryProvider.instance.topicRepository;

    final assistantId = arguments['assistant_id'] as String?;
    final limit = arguments['limit'] as int? ?? 50;
    final offset = arguments['offset'] as int? ?? 0;

    // 获取话题列表
    List topics;
    if (assistantId != null) {
      topics = await topicRepo.getTopicsByAssistant(assistantId);
    } else {
      topics = await topicRepo.getAllTopics();
    }

    // 应用日期过滤
    final startDate = _parseDate(arguments['start_date']);
    final endDate = _parseDate(arguments['end_date']);

    if (startDate != null || endDate != null) {
      topics = topics.where((t) {
        final date = DateTime.fromMillisecondsSinceEpoch(t.updatedAt);
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null &&
            date.isAfter(endDate.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    final total = topics.length;

    // 分页
    final paged = topics.skip(offset).take(limit).toList();

    return {
      'total': total,
      'offset': offset,
      'limit': limit,
      'topics': paged
          .map((t) => {
                'id': t.topicId,
                'name': t.name,
                'assistant_id': t.assistantId,
                'message_count': t.messageCount,
                'round_count': t.roundCount,
                'created_at':
                    DateTime.fromMillisecondsSinceEpoch(t.createdAt).toIso8601String(),
                'updated_at':
                    DateTime.fromMillisecondsSinceEpoch(t.updatedAt).toIso8601String(),
              })
          .toList(),
    };
  }

  /// 解析日期字符串
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
