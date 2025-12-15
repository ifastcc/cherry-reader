/// 搜索结果类型
enum SearchResultType {
  /// 匹配话题名称
  topic,
  /// 匹配消息内容
  message,
}

/// 搜索结果领域模型
class SearchResultModel {
  /// 结果唯一标识（用于 ListView key）
  final String id;

  /// 结果类型
  final SearchResultType type;

  /// 匹配的文本片段（已截取上下文）
  final String matchSnippet;

  /// 关键词在 snippet 中的位置（用于高亮渲染）
  final int matchStart;
  final int matchEnd;

  /// 来源话题信息
  final String topicId;
  final String topicName;

  /// 所属助手信息
  final String assistantId;
  final String assistantName;

  /// 消息元数据（仅 type == message 时有值）
  final String? messageId;
  final String? role; // user / assistant
  final String? modelName; // AI 模型名称
  final int? roundIndex; // 对话轮次

  /// 时间戳（毫秒）
  final int createdAt;

  const SearchResultModel({
    required this.id,
    required this.type,
    required this.matchSnippet,
    required this.matchStart,
    required this.matchEnd,
    required this.topicId,
    required this.topicName,
    required this.assistantId,
    required this.assistantName,
    this.messageId,
    this.role,
    this.modelName,
    this.roundIndex,
    required this.createdAt,
  });

  /// 是否为用户消息
  bool get isUserMessage => role == 'user';

  /// 是否为助手消息
  bool get isAssistantMessage => role == 'assistant';

  /// 获取 DateTime 对象
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  /// 格式化显示时间（月/日 时:分）
  String get formattedTime {
    final dt = dateTime;
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化相对时间（今天显示时分，否则显示日期）
  String get relativeTime {
    final dt = dateTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    if (dateOnly == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.month}/${dt.day}';
    }
  }
}

/// 搜索结果分组（用于视图展示）
class SearchResultGroup {
  /// 分组键（日期字符串或 assistantId）
  final String groupKey;

  /// 分组标题（如 "今天"、"本周" 或助手名称）
  final String groupTitle;

  /// 该分组下的搜索结果
  final List<SearchResultModel> results;

  const SearchResultGroup({
    required this.groupKey,
    required this.groupTitle,
    required this.results,
  });

  /// 结果数量
  int get count => results.length;
}

/// 搜索视图类型
enum SearchViewType {
  /// 时间视图（按日期分组）
  time,
  /// 助手视图（按助手分组）
  assistant,
}
