import 'package:flutter/material.dart';
import '../models/isar/insight_entity.dart';
import '../services/insight_service.dart';
import 'unified_markdown_renderer.dart';

/// 历史洞察页面
///
/// 独立页面显示历史生成的洞察记录
class InsightHistoryView extends StatefulWidget {
  const InsightHistoryView({super.key});

  @override
  State<InsightHistoryView> createState() => _InsightHistoryViewState();
}

class _InsightHistoryViewState extends State<InsightHistoryView> {
  final _service = InsightService.instance;

  List<InsightEntity> _insights = [];
  bool _isLoading = true;
  InsightEntity? _selectedInsight;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    try {
      final insights = await _service.getAllInsights();
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 加载历史洞察失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteInsight(InsightEntity insight) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${insight.perspectiveName}」的洞察记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteInsight(insight.insightId);

      if (mounted) {
        setState(() {
          _insights.removeWhere((i) => i.insightId == insight.insightId);
          if (_selectedInsight?.insightId == insight.insightId) {
            _selectedInsight = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (targetDate == today) {
      dateStr = '今天';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      dateStr = '昨天';
    } else if (date.year == now.year) {
      dateStr = '${date.month}/${date.day}';
    } else {
      dateStr = '${date.year}/${date.month}/${date.day}';
    }

    return '$dateStr ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 如果选中了某个洞察，显示详情
    if (_selectedInsight != null) {
      return _buildDetailView(theme, colorScheme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史洞察'),
        actions: [
          if (_insights.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '共 ${_insights.length} 条',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights.isEmpty
              ? _buildEmptyState(theme)
              : _buildList(theme, colorScheme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 56,
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无历史洞察',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _insights.length,
      itemBuilder: (context, index) {
        final insight = _insights[index];
        return _buildInsightCard(insight, theme, colorScheme);
      },
    );
  }

  Widget _buildInsightCard(
    InsightEntity insight,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // 提取内容预览（前100个字符）
    final preview = insight.content.length > 100
        ? '${insight.content.substring(0, 100)}...'
        : insight.content;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedInsight = insight),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Text(
                    insight.perspectiveIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.perspectiveName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(insight.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteInsight(insight),
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                    ),
                    tooltip: '删除',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 预览
              Text(
                preview,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // 统计信息
              Row(
                children: [
                  _buildStatChip(
                    '${insight.queryCount} 条提问',
                    colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    insight.assistantFilter,
                    colorScheme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildDetailView(ThemeData theme, ColorScheme colorScheme) {
    final insight = _selectedInsight!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedInsight = null),
          tooltip: '返回列表',
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              insight.perspectiveIcon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  insight.perspectiveName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(insight.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _deleteInsight(insight),
            icon: Icon(
              Icons.delete_outline,
              color: colorScheme.error,
            ),
            tooltip: '删除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: UnifiedMarkdownRenderer(
          data: insight.content,
          selectable: true,
        ),
      ),
    );
  }
}
