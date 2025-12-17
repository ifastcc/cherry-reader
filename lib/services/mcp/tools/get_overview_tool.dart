import '../../repository_provider.dart';
import '../../../services/version_service.dart';
import 'mcp_tool_base.dart';

/// 获取数据库总览
///
/// 返回：话题数、消息数、助手列表等
class GetOverviewTool extends MCPTool {
  @override
  String get name => 'get_overview';

  @override
  String get description => '''获取数据库总览信息。

返回内容包括：
- 话题总数
- 消息总数
- 助手列表及其话题数量
- 数据库大小
- 当前数据版本''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final topicRepo = RepositoryProvider.instance.topicRepository;
    final assistantRepo = RepositoryProvider.instance.assistantRepository;
    final db = RepositoryProvider.instance.database;

    // 并行获取统计数据
    final results = await Future.wait([
      topicRepo.getTopicCount(),
      assistantRepo.getAllAssistants(),
      db.getStatistics(),
    ]);

    final topicCount = results[0] as int;
    final assistants = results[1] as List;
    final stats = results[2] as Map<String, dynamic>;

    // 获取时间范围
    final allTopics = await topicRepo.getAllTopics();
    int? earliestTime;
    int? latestTime;

    if (allTopics.isNotEmpty) {
      earliestTime = allTopics
          .map((t) => t.createdAt)
          .reduce((a, b) => a < b ? a : b);
      latestTime = allTopics
          .map((t) => t.updatedAt)
          .reduce((a, b) => a > b ? a : b);
    }

    return {
      'topic_count': topicCount,
      'message_count': stats['messages'] ?? 0,
      'assistant_count': assistants.length,
      'assistants': assistants
          .map((a) => {
                'id': a.assistantId,
                'name': a.name,
                'topic_count': a.topicCount,
              })
          .toList(),
      'database_size_mb': stats['database_size_mb'] ?? 0,
      'version': VersionService.instance.activeVersionId ?? 'unknown',
      'time_range': earliestTime != null && latestTime != null
          ? {
              'earliest': DateTime.fromMillisecondsSinceEpoch(earliestTime)
                  .toIso8601String(),
              'latest': DateTime.fromMillisecondsSinceEpoch(latestTime)
                  .toIso8601String(),
            }
          : null,
    };
  }
}
