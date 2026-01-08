import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 消息操作工具栏
///
/// 显示在每条消息底部，提供常用操作：
/// - 复制：复制消息内容
/// - 讨论：进入 AI 讨论
/// - 重新生成：重新调用模型生成
/// - 更多：展开更多操作（编辑、删除、翻译、朗读）
class MessageActionBar extends StatelessWidget {
  /// 消息内容（用于复制）
  final String content;

  /// 消息 ID
  final String messageId;

  /// 模型名称
  final String modelName;

  /// 点击讨论回调
  final VoidCallback? onDiscuss;

  /// 点击重新生成回调
  final VoidCallback? onRegenerate;

  /// 点击编辑回调
  final VoidCallback? onEdit;

  /// 点击删除回调
  final VoidCallback? onDelete;

  /// 点击翻译回调
  final VoidCallback? onTranslate;

  /// 点击朗读回调
  final VoidCallback? onSpeak;

  /// 是否显示重新生成按钮
  final bool showRegenerate;

  /// 是否显示朗读按钮
  final bool showSpeak;

  /// 讨论数量（用于角标显示）
  final int discussionCount;

  const MessageActionBar({
    super.key,
    required this.content,
    required this.messageId,
    required this.modelName,
    this.onDiscuss,
    this.onRegenerate,
    this.onEdit,
    this.onDelete,
    this.onTranslate,
    this.onSpeak,
    this.showRegenerate = true,
    this.showSpeak = true,
    this.discussionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final activeColor = const Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 复制
          _ActionButton(
            icon: Icons.copy_rounded,
            label: '复制',
            color: iconColor!,
            onTap: () => _copyContent(context),
          ),
          const SizedBox(width: 4),

          // 讨论（带数量角标）


          // 重新生成
          if (showRegenerate) ...[
            _ActionButton(
              icon: Icons.refresh_rounded,
              label: '重新生成',
              color: onRegenerate != null ? iconColor : Colors.grey[400]!,
              onTap: onRegenerate,
            ),
            const SizedBox(width: 4),
          ],

          const Spacer(),

          // 更多操作
          _ActionButton(
            icon: Icons.more_horiz_rounded,
            label: '',
            color: iconColor,
            onTap: () => _showMoreActions(context, isDark),
          ),
        ],
      ),
    );
  }

  void _copyContent(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMoreActions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示条
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 18,
                      color: _getModelColor(modelName),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      modelName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // 操作列表


              if (onTranslate != null)
                _MoreActionItem(
                  icon: Icons.translate_rounded,
                  label: '翻译',
                  onTap: () {
                    Navigator.pop(context);
                    onTranslate?.call();
                  },
                ),

              if (onEdit != null)
                _MoreActionItem(
                  icon: Icons.edit_rounded,
                  label: '编辑',
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call();
                  },
                ),

              if (onDelete != null)
                _MoreActionItem(
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                  color: Colors.red[400],
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context);
                  },
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条回复吗？此操作不可撤销。'),
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

  Color _getModelColor(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (name.contains('gpt') || name.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (name.contains('gemini') || name.contains('google')) {
      return const Color(0xFF4285F4);
    } else if (name.contains('qwen') || name.contains('通义')) {
      return const Color(0xFF6366F1);
    } else if (name.contains('deepseek')) {
      return const Color(0xFF06B6D4);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }
}

/// 操作按钮（工具栏内）
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 带角标的操作按钮（用于显示讨论数量）
class _ActionButtonWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badgeCount;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _ActionButtonWithBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.badgeCount,
    required this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标带角标
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 16, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (label.isNotEmpty) ...[
              SizedBox(width: badgeCount > 0 ? 10 : 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 更多操作项（底部弹窗内）
class _MoreActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MoreActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.black87;

    return ListTile(
      leading: Icon(icon, color: color ?? defaultColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? defaultColor,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
