import 'package:flutter/material.dart';

import '../models/domain/insight_models.dart';
import '../services/insight_service.dart';

/// 精简版 Query 选择器
///
/// 设计原则：
/// - 话题作为最小选择单位（不展开到每个轮次）
/// - 显示话题的总字数
/// - 统计信息集成到底部
/// - 时间格式极简化
class QuerySelectorCompactStyle extends StatefulWidget {
  final void Function(List<QueryItem> selectedQueries)? onSelectionChanged;
  final void Function(Set<String>? assistantFilters)? onAssistantFilterChanged;
  final Set<String>? initialAssistantFilters;

  const QuerySelectorCompactStyle({
    super.key,
    this.onSelectionChanged,
    this.onAssistantFilterChanged,
    this.initialAssistantFilters,
  });

  @override
  State<QuerySelectorCompactStyle> createState() =>
      _QuerySelectorCompactStyleState();
}

class _QuerySelectorCompactStyleState extends State<QuerySelectorCompactStyle> {
  final _service = InsightService.instance;

  List<MonthGroup> _monthGroups = [];
  List<Map<String, String>> _assistants = [];
  Set<String> _selectedAssistants = {};
  bool _isLoading = true;

  // 选中的话题ID（话题作为最小单位）
  final Set<String> _selectedTopicIds = {};
  final Set<String> _expandedMonths = {};

  String? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    setState(() => _isLoading = true);

    try {
      final assistants = await _service.getAssistantList();
      Set<String> initialSelected;
      if (widget.initialAssistantFilters != null &&
          widget.initialAssistantFilters!.isNotEmpty) {
        initialSelected = widget.initialAssistantFilters!;
      } else {
        initialSelected = assistants
            .map((a) => a['name'] ?? '')
            .where((n) => n.isNotEmpty)
            .toSet();
      }

      setState(() {
        _assistants = assistants;
        _selectedAssistants = initialSelected;
      });

      await _loadData();
    } catch (e) {
      print('❌ 初始化失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 如果没有选中任何助手，直接设置空数据
      if (_selectedAssistants.isEmpty) {
        setState(() {
          _monthGroups = [];
          _selectedTopicIds.clear();
          _expandedMonths.clear();
          _isLoading = false;
        });
        _notifyChange();
        return;
      }

      final allNames = _assistants
          .map((a) => a['name'] ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
      final filterSet = _selectedAssistants.length == allNames.length
          ? null
          : _selectedAssistants;

      final monthGroups = await _service.getQueriesGroupedByMonth(
        assistantFilters: filterSet,
      );

      setState(() {
        _monthGroups = monthGroups;
        _expandedMonths.clear();
        if (monthGroups.isNotEmpty) {
          _expandedMonths.add(monthGroups.first.label);
        }
        _isLoading = false;
      });

      // 加载完成后，如果有活跃的时间选择，自动重新应用
      if (_selectedPeriod != null) {
        _applyPeriodSelection(_selectedPeriod!);
      } else {
        _notifyChange();
      }
    } catch (e) {
      print('❌ 加载数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 根据时间周期应用选择（内部方法，不会触发加载）
  void _applyPeriodSelection(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime startDate;
    switch (period) {
      case 'today':
        startDate = today;
        break;
      case 'week':
        startDate = today.subtract(Duration(days: today.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
        startDate = DateTime(2020, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    setState(() {
      _selectedTopicIds.clear();
      for (final monthGroup in _monthGroups) {
        for (final topicGroup in monthGroup.topicGroups) {
          // 只要话题的最新时间在范围内就选中
          if (topicGroup.latestTime.isAfter(startDate) ||
              topicGroup.latestTime.isAtSameMomentAs(startDate)) {
            _selectedTopicIds.add(topicGroup.topicId);
          }
        }
      }
    });
    _notifyChange();
  }

  // ============ 选择操作（以话题为最小单位） ============

  void _toggleTopicSelection(TopicGroup topicGroup) {
    setState(() {
      if (_selectedTopicIds.contains(topicGroup.topicId)) {
        _selectedTopicIds.remove(topicGroup.topicId);
      } else {
        _selectedTopicIds.add(topicGroup.topicId);
      }
      _selectedPeriod = null;  // 手动选择时清除时间快捷选择状态
    });
    _notifyChange();
  }

  void _toggleMonthSelection(MonthGroup group) {
    setState(() {
      final monthTopicIds = group.topicGroups.map((t) => t.topicId).toSet();
      final allSelected =
          monthTopicIds.every((id) => _selectedTopicIds.contains(id));

      if (allSelected) {
        _selectedTopicIds.removeAll(monthTopicIds);
      } else {
        _selectedTopicIds.addAll(monthTopicIds);
      }
      _selectedPeriod = null;  // 手动选择时清除时间快捷选择状态
    });
    _notifyChange();
  }

  void _selectByPeriod(String period) {
    setState(() => _selectedPeriod = period);
    _applyPeriodSelection(period);
  }

  void _clearSelection() {
    setState(() {
      _selectedTopicIds.clear();
      _selectedPeriod = null;
    });
    _notifyChange();
  }

  void _notifyChange() {
    if (widget.onSelectionChanged != null) {
      // 收集所有选中话题下的 queries
      final selectedQueries = <QueryItem>[];
      for (final monthGroup in _monthGroups) {
        for (final topicGroup in monthGroup.topicGroups) {
          if (_selectedTopicIds.contains(topicGroup.topicId)) {
            selectedQueries.addAll(topicGroup.queries);
          }
        }
      }
      widget.onSelectionChanged!(selectedQueries);
    }
  }

  // ============ 展开/折叠 ============

  void _toggleMonthExpanded(String monthLabel) {
    setState(() {
      if (_expandedMonths.contains(monthLabel)) {
        _expandedMonths.remove(monthLabel);
      } else {
        _expandedMonths.add(monthLabel);
      }
    });
  }

  // ============ 统计 ============

  int get _totalTopicCount {
    int count = 0;
    for (final monthGroup in _monthGroups) {
      count += monthGroup.topicGroups.length;
    }
    return count;
  }

  int get _selectedQueryCount {
    int count = 0;
    for (final monthGroup in _monthGroups) {
      for (final topicGroup in monthGroup.topicGroups) {
        if (_selectedTopicIds.contains(topicGroup.topicId)) {
          count += topicGroup.queries.length;
        }
      }
    }
    return count;
  }

  int get _selectedCharCount {
    int count = 0;
    for (final monthGroup in _monthGroups) {
      for (final topicGroup in monthGroup.topicGroups) {
        if (_selectedTopicIds.contains(topicGroup.topicId)) {
          count += topicGroup.totalCharCount;
        }
      }
    }
    return count;
  }

  String _formatCharCount(int count) {
    if (count < 1000) return '$count';
    if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 10000).toStringAsFixed(1)}w';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return '今天';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else if (date.year == now.year) {
      return '${date.month}/${date.day}';
    } else {
      return '${date.year}/${date.month}';
    }
  }

  // ============ UI 构建 ============

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 快捷选择按钮
        _buildQuickSelectButtons(theme, colorScheme),
        const SizedBox(height: 12),

        // 列表
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _monthGroups.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildCompactList(theme, colorScheme),
        ),

        // 底部统计条
        _buildBottomStatsBar(theme, colorScheme),
      ],
    );
  }

  /// 快捷选择按钮
  Widget _buildQuickSelectButtons(ThemeData theme, ColorScheme colorScheme) {
    final buttons = [
      ('今天', 'today', Icons.today),
      ('本周', 'week', Icons.date_range),
      ('本月', 'month', Icons.calendar_month),
      ('今年', 'year', Icons.calendar_today),
      ('全部', 'all', Icons.all_inclusive),
    ];

    return Row(
      children: buttons.map((b) {
        final isSelected = _selectedPeriod == b.$2;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: b.$2 == 'all' ? 0 : 8,
            ),
            child: Material(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _selectByPeriod(b.$2),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        b.$3,
                        size: 20,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无提问记录',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactList(ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      itemCount: _monthGroups.length,
      itemBuilder: (context, index) {
        final monthGroup = _monthGroups[index];
        return _buildMonthSection(monthGroup, theme, colorScheme);
      },
    );
  }

  // 布局常量
  static const double _topicIndent = 52.0;  // 子项缩进，对齐到月份标签文字左侧
  static const double _topicSelectWidth = 24.0;

  Widget _buildMonthSection(
    MonthGroup monthGroup,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isExpanded = _expandedMonths.contains(monthGroup.label);
    final monthTopicIds = monthGroup.topicGroups.map((t) => t.topicId).toSet();
    final selectedInMonth =
        monthTopicIds.where((id) => _selectedTopicIds.contains(id)).length;
    final totalInMonth = monthTopicIds.length;
    final allSelected = selectedInMonth == totalInMonth && totalInMonth > 0;
    final partialSelected = selectedInMonth > 0 && !allSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月份标题行
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: InkWell(
            onTap: () => _toggleMonthExpanded(monthGroup.label),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: selectedInMonth > 0
                  ? colorScheme.primaryContainer.withValues(alpha: 0.12)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedInMonth > 0
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                // 展开/折叠图标
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                // 选择图标
                GestureDetector(
                  onTap: () => _toggleMonthSelection(monthGroup),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      allSelected
                          ? Icons.check_circle_rounded
                          : partialSelected
                              ? Icons.remove_circle_rounded
                              : Icons.circle_outlined,
                      size: 20,
                      color: selectedInMonth > 0
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 月份标签
                Text(
                  monthGroup.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                // 选中数量标签
                if (selectedInMonth > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$selectedInMonth',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // 话题总数
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$totalInMonth 话题',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            ),
          ),
        ),
        // 话题列表
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: _topicIndent),
            child: Column(
              children: monthGroup.topicGroups
                  .map((tg) => _buildTopicRow(tg, theme, colorScheme))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTopicRow(
    TopicGroup topicGroup,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedTopicIds.contains(topicGroup.topicId);
    final firstQuery =
        topicGroup.queries.isNotEmpty ? topicGroup.queries.first : null;

    // 为不同助手生成不同的颜色
    final assistantName = topicGroup.assistantNames.join(', ');
    final assistantColor = _getAssistantColor(assistantName, colorScheme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _toggleTopicSelection(topicGroup),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.2)
                : colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 选择图标
            SizedBox(
              width: _topicSelectWidth,
              child: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
            // 主内容区
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    topicGroup.topicName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.85),
                      height: 1.45,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 预览文本
                  if (firstQuery != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      firstQuery.preview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline.withValues(alpha: 0.45),
                        height: 1.35,
                        fontSize: 12,
                        letterSpacing: 0.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 右侧统计列
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 轮数 + 字数
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${topicGroup.roundCount}轮',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatCharCount(topicGroup.totalCharCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.8),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 助手标签 + 日期
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 100),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: assistantColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        topicGroup.assistantNames.join(', '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: assistantColor.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(topicGroup.latestTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        ),
      ),
    );
  }

  /// 根据助手名称生成一致的颜色
  Color _getAssistantColor(String assistantName, ColorScheme colorScheme) {
    final hash = assistantName.hashCode;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.teal,
      Colors.indigo,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }

  /// 截断过长的助手名称
  String _truncateAssistantName(String name, [int maxLength = 8]) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 1)}…';
  }

  Widget _buildBottomStatsBar(ThemeData theme, ColorScheme colorScheme) {
    final hasSelection = _selectedTopicIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // 统计信息
          Expanded(
            child: hasSelection
                ? Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedTopicIds.length} 话题',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($_selectedQueryCount 轮)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 12,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatCharCount(_selectedCharCount)} 字',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // 清空按钮
          if (hasSelection)
            TextButton(
              onPressed: _clearSelection,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '清空',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
