import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';
import 'knowledge_card.dart';

/// 来源视图组件
///
/// 按 Topic 分组展示知识条目
/// 支持展开/折叠
class KnowledgeSourceView extends StatefulWidget {
  final Map<String?, List<KnowledgeItem>> groupedItems;
  final Map<String, String> topicNames; // topicId -> topicName
  final void Function(KnowledgeItem) onItemTap;
  final void Function(KnowledgeItem)? onSourceTap;
  final void Function(KnowledgeItem) onDelete;
  final VoidCallback? onCreateNote;

  const KnowledgeSourceView({
    super.key,
    required this.groupedItems,
    required this.topicNames,
    required this.onItemTap,
    this.onSourceTap,
    required this.onDelete,
    this.onCreateNote,
  });

  @override
  State<KnowledgeSourceView> createState() => _KnowledgeSourceViewState();
}

class _KnowledgeSourceViewState extends State<KnowledgeSourceView> {
  final Set<String?> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    // 默认展开第一个分组
    if (widget.groupedItems.isNotEmpty) {
      _expandedGroups.add(widget.groupedItems.keys.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupedItems.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: KnowledgeEmptyState(onCreateNote: widget.onCreateNote ?? () {}),
      );
    }

    final groups = widget.groupedItems.entries.toList();
    // 将独立笔记（null topicId）放在最后
    groups.sort((a, b) {
      if (a.key == null) return 1;
      if (b.key == null) return -1;
      return 0;
    });

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
    String? topicId,
    List<KnowledgeItem> items,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expandedGroups.contains(topicId);
    final topicName = topicId != null
        ? widget.topicNames[topicId] ?? items.first.sourceTopicName ?? '未知话题'
        : '独立笔记';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组头部
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedGroups.remove(topicId);
              } else {
                _expandedGroups.add(topicId);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: topicId != null
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    topicId != null ? Icons.chat_bubble_outline : Icons.edit_note,
                    size: 18,
                    color: topicId != null
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topicName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${items.length} 条记录',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.25 : 0,
                  child: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 条目列表（可折叠）
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        child: KnowledgeCard(
                          item: item,
                          onTap: () => widget.onItemTap(item),
                          onSourceTap: item.hasSource && widget.onSourceTap != null
                              ? () => widget.onSourceTap!(item)
                              : null,
                          onDelete: () => widget.onDelete(item),
                          compact: true, // 使用紧凑模式
                        ),
                      ))
                  .toList(),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
