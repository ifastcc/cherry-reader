import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';

/// 统一知识卡片组件
///
/// 用于显示所有知识条目（不区分类型）
/// 特性：
/// - 左侧色带（根据内容自动着色）
/// - Dismissible 滑动删除
/// - 引用原文样式（左边框 + 斜体）
/// - 标签和来源指示器
class KnowledgeCard extends StatelessWidget {
  final KnowledgeItem item;
  final VoidCallback? onTap;
  final VoidCallback? onSourceTap;
  final VoidCallback? onDelete;

  const KnowledgeCard({
    super.key,
    required this.item,
    this.onTap,
    this.onSourceTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧色带（根据内容类型自动着色）
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _getCardColor(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // 主内容区
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 12),
                      _buildContent(context),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildTags(context),
                      ],
                      if (item.hasSource) ...[
                        const SizedBox(height: 12),
                        _buildSourceIndicator(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 如果有删除回调，包装 Dismissible
    if (onDelete != null) {
      return Dismissible(
        key: Key('knowledge_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.onError,
          ),
        ),
        confirmDismiss: (direction) => _confirmDelete(context),
        onDismissed: (direction) => onDelete?.call(),
        child: cardContent,
      );
    }

    return cardContent;
  }

  /// 根据内容类型获取颜色
  Color _getCardColor() {
    // 有引用 + 有评论 = 蓝色（标注）
    // 有引用 + 无评论 = 黄色（高亮）
    // 无引用 = 紫色（笔记）
    if (item.quotedText != null && item.quotedText!.isNotEmpty) {
      if (item.hasComment) {
        return const Color(0xFF81D4FA); // 蓝色
      } else {
        return const Color(0xFFFFF176); // 黄色
      }
    }
    return const Color(0xFFCE93D8); // 紫色
  }

  /// 头部：时间 + 更多按钮
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // 时间
        Text(
          item.formattedTime,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        // 更多按钮
        if (onDelete != null)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18),
                    SizedBox(width: 8),
                    Text('删除'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context).then((confirmed) {
                  if (confirmed == true) {
                    onDelete?.call();
                  }
                });
              }
            },
          ),
      ],
    );
  }

  /// 内容区域
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuotedText = item.quotedText != null && item.quotedText!.isNotEmpty;
    final hasContent = item.content.isNotEmpty;

    // 有引用文本
    if (hasQuotedText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 引用原文
          _buildQuotedText(context, item.quotedText!),
          // 评论（如果有）
          if (hasContent && item.hasComment) ...[
            const SizedBox(height: 12),
            Text(
              item.content,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    }

    // 纯笔记
    return Text(
      item.content,
      style: TextStyle(
        fontSize: 15,
        color: theme.colorScheme.onSurface,
        height: 1.5,
      ),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 引用原文样式
  Widget _buildQuotedText(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: _getCardColor(),
            width: 3,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 标签列表
  Widget _buildTags(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: item.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 来源指示器
  Widget _buildSourceIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final sourceName = item.sourceTopicName ?? '对话';

    return InkWell(
      onTap: onSourceTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '来自《$sourceName》',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// 删除确认对话框
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 空状态占位组件
class KnowledgeEmptyState extends StatelessWidget {
  final VoidCallback? onCreateNote;

  const KnowledgeEmptyState({
    super.key,
    this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_mosaic_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有任何知识积累',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在对话中选中文本可添加记录\n或点击下方按钮直接创建',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (onCreateNote != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateNote,
              icon: const Icon(Icons.add),
              label: const Text('开始记录'),
            ),
          ],
        ],
      ),
    );
  }
}
