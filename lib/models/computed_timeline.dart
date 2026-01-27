// 首页时间线预计算数据模型
//
// 这些数据在 Isolate 中计算完成后传回主线程，
// build() 方法只读取这些预计算结果，不做任何计算。

/// 时间分组
enum TimeGroup {
  today,
  yesterday,
  thisWeek,
  earlier;

  String get title => switch (this) {
        TimeGroup.today => '今天',
        TimeGroup.yesterday => '昨天',
        TimeGroup.thisWeek => '本周',
        TimeGroup.earlier => '更早',
      };
}

/// 话题卡片所需的所有数据（在 Isolate 中预计算）
class TopicItem {
  final String topicId;
  final String name;
  final String assistantId;
  final String assistantName;
  final int roundCount;
  final int messageCount;
  final DateTime updatedAt;
  final String timeDisplay;
  final String? userPreview;
  final String? aiPreview;

  const TopicItem({
    required this.topicId,
    required this.name,
    required this.assistantId,
    required this.assistantName,
    required this.roundCount,
    required this.messageCount,
    required this.updatedAt,
    required this.timeDisplay,
    this.userPreview,
    this.aiPreview,
  });

  /// 用于排序比较（按更新时间倒序）
  int compareTo(TopicItem other) => other.updatedAt.compareTo(updatedAt);
}

/// 时间线分组
class TimelineGroup {
  final TimeGroup type;
  final List<TopicItem> topics;

  TimelineGroup({
    required this.type,
    List<TopicItem>? topics,
  }) : topics = topics ?? [];

  /// 复制并添加话题
  TimelineGroup copyWithTopic(TopicItem topic) {
    return TimelineGroup(
      type: type,
      topics: [...topics, topic],
    );
  }
}

/// 预计算的完整时间线数据
class ComputedTimeline {
  final int version;
  List<TimelineGroup> groups;
  final Map<String, TopicItem> topicsMap;
  int totalCount;
  final DateTime computedAt;

  ComputedTimeline({
    required this.version,
    required this.groups,
    required this.topicsMap,
    required this.computedAt,
  }) : totalCount = topicsMap.length;

  /// 空的时间线
  factory ComputedTimeline.empty(int version) => ComputedTimeline(
        version: version,
        groups: [],
        topicsMap: {},
        computedAt: DateTime.now(),
      );

  /// 获取展平的话题列表（用于 SliverList）
  List<dynamic> get flatItems {
    final items = <dynamic>[];
    for (final group in groups) {
      if (group.topics.isEmpty) continue;
      items.add(group); // 分组标题
      items.addAll(group.topics); // 话题卡片
    }
    return items;
  }

  /// 【增量更新】添加话题
  void addTopic(TopicItem topic) {
    topicsMap[topic.topicId] = topic;
    totalCount = topicsMap.length;
    _insertIntoGroups(topic);
  }

  /// 【增量更新】删除话题
  void removeTopic(String topicId) {
    topicsMap.remove(topicId);
    totalCount = topicsMap.length;
    for (final group in groups) {
      group.topics.removeWhere((t) => t.topicId == topicId);
    }
    // 移除空分组
    groups.removeWhere((g) => g.topics.isEmpty);
  }

  /// 【增量更新】更新话题
  void updateTopic(TopicItem topic) {
    // 先删除旧的
    removeTopic(topic.topicId);
    // 再添加新的
    addTopic(topic);
  }

  /// 将话题插入到正确的分组（按时间排序）
  void _insertIntoGroups(TopicItem topic) {
    final now = DateTime.now();
    final groupType = _getTimeGroup(topic.updatedAt, now);
    
    // 找到对应分组
    var group = groups.cast<TimelineGroup?>().firstWhere(
      (g) => g!.type == groupType,
      orElse: () => null,
    );
    
    if (group == null) {
      // 创建新分组并插入正确位置
      group = TimelineGroup(type: groupType, topics: [topic]);
      final insertIndex = groups.indexWhere((g) => g.type.index > groupType.index);
      if (insertIndex == -1) {
        groups.add(group);
      } else {
        groups.insert(insertIndex, group);
      }
    } else {
      // 插入到已排序列表的正确位置
      final insertIndex = group.topics.indexWhere(
        (t) => topic.compareTo(t) <= 0,
      );
      if (insertIndex == -1) {
        group.topics.add(topic);
      } else {
        group.topics.insert(insertIndex, topic);
      }
    }
  }

  /// 获取时间分组
  static TimeGroup _getTimeGroup(DateTime dt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return TimeGroup.today;
    if (date == yesterday) return TimeGroup.yesterday;
    if (date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
      return TimeGroup.thisWeek;
    }
    return TimeGroup.earlier;
  }

  /// 【增量更新】重新分组（当时间跨越边界时）
  void regroup() {
    final now = DateTime.now();
    final allTopics = topicsMap.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    final newGroups = <TimeGroup, List<TopicItem>>{};
    for (final topic in allTopics) {
      final type = _getTimeGroup(topic.updatedAt, now);
      newGroups.putIfAbsent(type, () => []).add(topic);
    }
    
    groups = [
      if (newGroups[TimeGroup.today]?.isNotEmpty ?? false)
        TimelineGroup(type: TimeGroup.today, topics: newGroups[TimeGroup.today]!),
      if (newGroups[TimeGroup.yesterday]?.isNotEmpty ?? false)
        TimelineGroup(type: TimeGroup.yesterday, topics: newGroups[TimeGroup.yesterday]!),
      if (newGroups[TimeGroup.thisWeek]?.isNotEmpty ?? false)
        TimelineGroup(type: TimeGroup.thisWeek, topics: newGroups[TimeGroup.thisWeek]!),
      if (newGroups[TimeGroup.earlier]?.isNotEmpty ?? false)
        TimelineGroup(type: TimeGroup.earlier, topics: newGroups[TimeGroup.earlier]!),
    ];
  }
}

/// Isolate 计算参数
class TimelineComputeParams {
  final int version;
  final Map<String, dynamic> rawData;
  final Map<String, Map<String, dynamic>> assistantMap;
  final DateTime now;

  const TimelineComputeParams({
    required this.version,
    required this.rawData,
    required this.assistantMap,
    required this.now,
  });
}
