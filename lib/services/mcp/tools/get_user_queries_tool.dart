import '../../repository_provider.dart';
import '../../../models/domain/block_model.dart';
import 'mcp_tool_base.dart';

/// 获取用户问题列表
///
/// 按时间范围返回用户提出的所有问题，按话题分组
/// 用于回答"我最近在关注什么"
class GetUserQueriesTool extends MCPTool {
  @override
  String get name => 'get_user_queries';

  @override
  String get description => '''获取指定时间范围内用户提出的所有问题，按话题分组。

用于回答"我最近在关注什么"类型的问题。

特点：
- 只返回用户问题（不返回 AI 回复）
- 按话题分组，保持上下文
- 按投入深度（round_count）降序排序''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'period': {
            'type': 'string',
            'enum': [
              'today',
              'yesterday',
              'this_week',
              'this_month',
              'last_7_days',
              'last_30_days',
              'custom'
            ],
            'description': '时间范围，默认 today',
          },
          'start_date': {
            'type': 'string',
            'description': '自定义开始日期（period=custom 时），格式 YYYY-MM-DD',
          },
          'end_date': {
            'type': 'string',
            'description': '自定义结束日期（period=custom 时），格式 YYYY-MM-DD',
          },
          'min_rounds': {
            'type': 'integer',
            'description': '最小轮次，默认 1',
          },
          'assistant_ids': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '只看指定助手（可选）',
          },
          'limit': {
            'type': 'integer',
            'description': '返回话题数量，默认 50，最大 500',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final period = arguments['period'] as String? ?? 'today';
    final minRounds = arguments['min_rounds'] as int? ?? 1;
    var limit = arguments['limit'] as int? ?? 50;
    if (limit > 500) limit = 500;
    final assistantIds = (arguments['assistant_ids'] as List?)?.cast<String>();

    final topicRepo = RepositoryProvider.instance.topicRepository;
    final messageRepo = RepositoryProvider.instance.messageRepository;
    final assistantRepo = RepositoryProvider.instance.assistantRepository;

    // 计算时间范围
    final range = _calculateTimeRange(
      period,
      arguments['start_date'] as String?,
      arguments['end_date'] as String?,
    );

    // 获取助手名称映射
    final assistants = await assistantRepo.getAllAssistants();
    final assistantNames = {for (final a in assistants) a.assistantId: a.name};

    // 获取所有话题
    var allTopics = await topicRepo.getAllTopics();

    // 按时间过滤
    allTopics = allTopics.where((t) {
      final updatedAt = DateTime.fromMillisecondsSinceEpoch(t.updatedAt);
      return updatedAt.isAfter(range.start) &&
          updatedAt.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();

    // 按助手过滤
    if (assistantIds != null && assistantIds.isNotEmpty) {
      allTopics =
          allTopics.where((t) => assistantIds.contains(t.assistantId)).toList();
    }

    // 按轮次过滤
    allTopics = allTopics.where((t) => t.roundCount >= minRounds).toList();

    // 按 roundCount 降序排序（投入多的排前面）
    allTopics.sort((a, b) => b.roundCount.compareTo(a.roundCount));

    // 限制数量
    final topics = allTopics.take(limit).toList();

    // 构建结果
    final topicResults = <Map<String, dynamic>>[];

    for (final topic in topics) {
      // 获取该话题的所有消息
      final messages = await messageRepo.loadAllMessages(topic.topicId);

      // 只取用户消息
      final userMessages = messages.where((m) => m.isUser).toList();

      // 按 roundIndex 排序
      userMessages.sort((a, b) => a.roundIndex.compareTo(b.roundIndex));

      // 获取用户消息的 blocks
      final userMessageIds = userMessages.map((m) => m.messageId).toList();
      final blocksMap = await messageRepo.batchLoadBlocks(userMessageIds);

      // 提取用户问题
      final userQueries = <Map<String, dynamic>>[];
      for (final msg in userMessages) {
        final blocks = blocksMap[msg.messageId] ?? [];
        final content = _extractContent(blocks);
        if (content.isNotEmpty) {
          userQueries.add({
            'round': msg.roundIndex,
            'query': content,
          });
        }
      }

      topicResults.add({
        'topic_id': topic.topicId,
        'topic_name': topic.name,
        'assistant_name': assistantNames[topic.assistantId] ?? '未知助手',
        'round_count': topic.roundCount,
        'user_queries': userQueries,
      });
    }

    return {
      'period': period,
      'topics': topicResults,
    };
  }

  /// 计算时间范围
  _TimeRange _calculateTimeRange(
    String period,
    String? startDateStr,
    String? endDateStr,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case 'today':
        return _TimeRange(today, today);

      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return _TimeRange(yesterday, yesterday);

      case 'this_week':
        // 本周一到今天
        final weekday = today.weekday;
        final monday = today.subtract(Duration(days: weekday - 1));
        return _TimeRange(monday, today);

      case 'this_month':
        // 本月第一天到今天
        final firstDay = DateTime(now.year, now.month, 1);
        return _TimeRange(firstDay, today);

      case 'last_7_days':
        final start = today.subtract(const Duration(days: 6));
        return _TimeRange(start, today);

      case 'last_30_days':
        final start = today.subtract(const Duration(days: 29));
        return _TimeRange(start, today);

      case 'custom':
        final start = startDateStr != null
            ? DateTime.parse(startDateStr)
            : today.subtract(const Duration(days: 7));
        final end = endDateStr != null ? DateTime.parse(endDateStr) : today;
        return _TimeRange(start, end);

      default:
        return _TimeRange(today, today);
    }
  }

  /// 提取消息内容
  String _extractContent(List<BlockModel> blocks) {
    final buffer = StringBuffer();
    for (final block in blocks) {
      if (block.isMainText && block.content != null) {
        buffer.write(block.content);
      }
    }
    return buffer.toString().trim();
  }
}

/// 时间范围
class _TimeRange {
  final DateTime start;
  final DateTime end;

  _TimeRange(this.start, this.end);
}
