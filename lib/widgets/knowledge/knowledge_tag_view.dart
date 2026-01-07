import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';
import 'knowledge_card.dart';

/// 标签视图组件
///
/// 顶部标签云 + 筛选后的条目列表
class KnowledgeTagView extends StatefulWidget {
  final List<KnowledgeItem> items;
  final Map<String, int> tagStatistics;
  final void Function(KnowledgeItem) onItemTap;
  final void Function(KnowledgeItem)? onSourceTap;
  final void Function(KnowledgeItem) onDelete;
  final VoidCallback? onCreateNote;

  const KnowledgeTagView({
    super.key,
    required this.items,
    required this.tagStatistics,
    required this.onItemTap,
    this.onSourceTap,
    required this.onDelete,
    this.onCreateNote,
  });

  @override
  State<KnowledgeTagView> createState() => _KnowledgeTagViewState();
}

class _KnowledgeTagViewState extends State<KnowledgeTagView> {
  String? _selectedTag;

  List<KnowledgeItem> get _filteredItems {
    if (_selectedTag == null) return widget.items;
    return widget.items.where((item) => item.tags.contains(_selectedTag)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasNoTags = widget.tagStatistics.isEmpty;

    if (widget.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: KnowledgeEmptyState(onCreateNote: widget.onCreateNote ?? () {}),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        // 标签云
        SliverToBoxAdapter(
          child: hasNoTags ? _buildNoTagsHint(context) : _buildTagCloud(context),
        ),
        // 条目列表
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _filteredItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: KnowledgeCard(
                    item: item,
                    onTap: () => widget.onItemTap(item),
                    onSourceTap: item.hasSource && widget.onSourceTap != null
                        ? () => widget.onSourceTap!(item)
                        : null,
                    onDelete: () => widget.onDelete(item),
                  ),
                );
              },
              childCount: _filteredItems.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoTagsHint(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '尝试添加标签',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '在笔记中使用 #标签 来组织内容',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCloud(BuildContext context) {
    final theme = Theme.of(context);
    
    // 按使用频率排序
    final sortedTags = widget.tagStatistics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '标签',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_selectedTag != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedTag = null),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('清除筛选'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedTags.map((entry) {
              final tag = entry.key;
              final count = entry.value;
              final isSelected = _selectedTag == tag;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTag = isSelected ? null : tag;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag,
                        size: 14,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.2)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
