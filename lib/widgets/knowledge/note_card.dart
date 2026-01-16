import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// 笔记卡片数据模型
class NoteCardData {
  final String id;
  final String highlightText;
  final String? prefix;
  final String? suffix;
  final String? note;
  final Color highlightColor;
  final String? sourceTopicName;
  final String? sourceMessageId;
  final DateTime createdAt;
  final List<String> tags;

  const NoteCardData({
    required this.id,
    required this.highlightText,
    this.prefix,
    this.suffix,
    this.note,
    required this.highlightColor,
    this.sourceTopicName,
    this.sourceMessageId,
    required this.createdAt,
    this.tags = const [],
  });
}

/// 笔记卡片组件
/// 
/// 特性：
/// - 头部：来源信息 + 跳转按钮
/// - prefix 渲染：淡化 + ShaderMask 渐隐
/// - 高亮文本渲染：背景色高亮
/// - suffix 渲染：淡化 + ShaderMask 渐隐
/// - 笔记区（可选）
/// - 时间戳
class NoteCard extends StatelessWidget {
  final NoteCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onSourceTap;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.data,
    this.onTap,
    this.onSourceTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: data.highlightColor.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：来源信息 + 操作按钮
                _buildHeader(context),
                const SizedBox(height: 12),
                // 引用区：prefix + highlight + suffix
                _buildQuoteSection(context),
                // 笔记区（如果有）
                if (data.note != null && data.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildNoteSection(context),
                ],
                // 标签（如果有）
                if (data.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildTags(context),
                ],
                // 时间戳
                const SizedBox(height: 12),
                _buildTimestamp(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 头部区域
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // 颜色指示器
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: data.highlightColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        // 来源信息
        Expanded(
          child: data.sourceTopicName != null
              ? InkWell(
                  onTap: onSourceTap,
                  borderRadius: BorderRadius.circular(4),
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
                          data.sourceTopicName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // 删除按钮
        if (onDelete != null)
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _showMenu(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  /// 引用区域：prefix + highlight + suffix
  Widget _buildQuoteSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prefix（渐隐效果）
          if (data.prefix != null && data.prefix!.isNotEmpty)
            _buildFadedText(
              context,
              data.prefix!,
              fadeDirection: FadeDirection.start,
            ),
          // 高亮文本
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: data.highlightColor.withOpacity(isDark ? 0.3 : 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              data.highlightText,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
          // Suffix（渐隐效果）
          if (data.suffix != null && data.suffix!.isNotEmpty)
            _buildFadedText(
              context,
              data.suffix!,
              fadeDirection: FadeDirection.end,
            ),
        ],
      ),
    );
  }

  /// 渐隐文本（用于 prefix/suffix）
  Widget _buildFadedText(
    BuildContext context,
    String text, {
    required FadeDirection fadeDirection,
  }) {
    final theme = Theme.of(context);

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return ui.Gradient.linear(
          fadeDirection == FadeDirection.start
              ? Offset(0, bounds.height / 2)
              : Offset(bounds.width * 0.7, bounds.height / 2),
          fadeDirection == FadeDirection.start
              ? Offset(bounds.width * 0.3, bounds.height / 2)
              : Offset(bounds.width, bounds.height / 2),
          [
            fadeDirection == FadeDirection.start
                ? Colors.transparent
                : Colors.white,
            fadeDirection == FadeDirection.start
                ? Colors.white
                : Colors.transparent,
          ],
        );
      },
      blendMode: BlendMode.dstIn,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 笔记区域
  Widget _buildNoteSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '笔记',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.note!,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 标签列表
  Widget _buildTags(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: data.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 时间戳
  Widget _buildTimestamp(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      _formatTime(data.createdAt),
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';

    return '${time.month}月${time.day}日';
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条笔记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 渐隐方向
enum FadeDirection { start, end }
