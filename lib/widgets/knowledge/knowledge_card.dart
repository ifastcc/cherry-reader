import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';

/// 统一知识卡片组件
///
/// 用于显示所有知识条目（不区分类型）
/// 特性：
/// - 渐变卡面 + 类型徽标
/// - Dismissible 滑动删除
/// - 引用原文样式（柔和高亮 + 斜体）
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
    final cardColor = _getCardColor();

    Widget cardContent = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.withOpacity(0.18), theme.colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, cardColor),
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
      ),
    );

    // 如果有删除回调，包装 Dismissible
    if (onDelete != null) {
      return Dismissible(
        key: Key('knowledge_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.error.withOpacity(0.85),
                theme.colorScheme.error.withOpacity(0.65),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
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
    return item.displayColor;
  }

  /// 头部：时间 + 更多按钮
  Widget _buildHeader(BuildContext context, Color accent) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _buildTypeBadge(context, accent),
        const SizedBox(width: 8),
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
    final hasQuotedText =
        item.quotedText != null && item.quotedText!.isNotEmpty;
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _getCardColor().withOpacity(0.08),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.35),
            ),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
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

  /// 类型标签
  Widget _buildTypeBadge(BuildContext context, Color accent) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.typeIcon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            item.typeName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// 空状态占位组件
class KnowledgeEmptyState extends StatelessWidget {
  final VoidCallback? onCreateNote;

  const KnowledgeEmptyState({super.key, this.onCreateNote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.85),
                    theme.colorScheme.secondaryContainer.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_mosaic_outlined,
                size: 44,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '还没有任何知识积累',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在对话中选中文本可添加记录，\n或点击右下角快速记下一条灵感。',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onCreateNote != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreateNote,
                icon: const Icon(Icons.add),
                label: const Text('开始第一条记录'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
