import '../../repository_provider.dart';
import 'mcp_tool_base.dart';

/// 获取活动摘要
///
/// 统计指定时间范围内的活动情况
class GetActivitySummaryTool extends MCPTool {
  @override
  String get name => 'get_activity_summary';

  @override
  String get description => '''获取指定时间范围的活动摘要。

适用于：
- 了解最近一段时间的活跃情况
- 分析关注的领域分布
- 回顾每天的讨论数量

返回内容包括：
- 话题数量统计
- 每日活动分布
- 最活跃的助手排名''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'days': {
            'type': 'integer',
            'description': '统计最近 N 天，默认 7',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final days = arguments['days'] as int? ?? 7;
    final topicRepo = RepositoryProvider.instance.topicRepository;
    final assistantRepo = RepositoryProvider.instance.assistantRepository;

    final now = DateTime.now();
    final startTime = now.subtract(Duration(days: days));
    final startTs = startTime.millisecondsSinceEpoch;

    final allTopics = await topicRepo.getAllTopics();

    // 按天统计
    final dailyStats = <String, int>{};
    final assistantStats = <String, int>{};
    var totalRounds = 0;
    var totalInRange = 0;

    for (final topic in allTopics) {
      if (topic.updatedAt >= startTs) {
        totalInRange++;
        totalRounds += topic.roundCount;

        final date = DateTime.fromMillisecondsSinceEpoch(topic.updatedAt);
        final dayKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyStats[dayKey] = (dailyStats[dayKey] ?? 0) + 1;

        assistantStats[topic.assistantId] =
            (assistantStats[topic.assistantId] ?? 0) + 1;
      }
    }

    // 获取助手名称
    final assistants = await assistantRepo.getAllAssistants();
    final assistantNames = {for (final a in assistants) a.assistantId: a.name};

    // 排序
    final sortedDays = dailyStats.keys.toList()..sort();
    final sortedAssistants = assistantStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'period_days': days,
      'total_active_topics': totalInRange,
      'total_rounds': totalRounds,
      'average_rounds_per_topic':
          totalInRange > 0 ? (totalRounds / totalInRange).toStringAsFixed(1) : '0',
      'daily_activity': sortedDays
          .map((d) => {
                'date': d,
                'count': dailyStats[d],
              })
          .toList(),
      'top_assistants': sortedAssistants.take(5).map((e) {
        return {
          'assistant_id': e.key,
          'assistant_name': assistantNames[e.key] ?? '未知助手',
          'count': e.value,
        };
      }).toList(),
    };
  }
}
