import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';
import 'knowledge_card.dart';

/// 时间线视图组件
///
/// 按日期分组展示知识条目
/// - 今天
/// - 昨天
/// - 本周
/// - 更早
class KnowledgeTimelineView extends StatelessWidget {
  final List<KnowledgeItem> items;
  final void Function(KnowledgeItem) onItemTap;
  final void Function(KnowledgeItem)? onSourceTap;
  final void Function(KnowledgeItem) onDelete;
  final VoidCallback? onCreateNote;

  const KnowledgeTimelineView({
    super.key,
    required this.items,
    required this.onItemTap,
    this.onSourceTap,
    required this.onDelete,
    this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: KnowledgeEmptyState(onCreateNote: onCreateNote ?? () {}),
      );
    }

    final grouped = _groupByDate(items);
    final groups = grouped.entries.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final group = groups[index];
          return _buildGroup(context, group.key, group.value);
        },
        childCount: groups.length,
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String label,
    List<KnowledgeItem> groupItems,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${groupItems.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        // 条目列表
        ...groupItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: KnowledgeCard(
                item: item,
                onTap: () => onItemTap(item),
                onSourceTap:
                    item.hasSource && onSourceTap != null ? () => onSourceTap!(item) : null,
                onDelete: () => onDelete(item),
              ),
            )),
      ],
    );
  }

  Map<String, List<KnowledgeItem>> _groupByDate(List<KnowledgeItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final grouped = <String, List<KnowledgeItem>>{
      '今天': [],
      '昨天': [],
      '本周': [],
      '更早': [],
    };

    for (final item in items) {
      final date = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );

      if (date == today) {
        grouped['今天']!.add(item);
      } else if (date == yesterday) {
        grouped['昨天']!.add(item);
      } else if (date.isAfter(weekAgo)) {
        grouped['本周']!.add(item);
      } else {
        grouped['更早']!.add(item);
      }
    }

    // 移除空分组
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }
}
