import 'package:flutter/material.dart';

/// 浮动选择工具栏 - 类似微信读书的文字选择体验
///
/// 当用户选中文字时,在选中区域附近弹出浮动工具栏
/// 提供复制、添加笔记等操作
class FloatingSelectionToolbar extends StatelessWidget {
  final Offset position;
  final VoidCallback? onCopy;
  final VoidCallback? onHighlight;
  final Color? highlightColor;

  const FloatingSelectionToolbar({
    Key? key,
    required this.position,
    this.onCopy,
    this.onHighlight,
    this.highlightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 计算工具栏应该显示的位置
    double left = position.dx;
    double top = position.dy;

    const toolbarWidth = 180.0;
    const toolbarHeight = 44.0;

    // 水平边界检查
    if (left + toolbarWidth > screenSize.width - 16) {
      left = screenSize.width - toolbarWidth - 16;
    }
    if (left < 16) {
      left = 16;
    }

    // 垂直边界检查 - 默认显示在选中文字上方
    if (top < toolbarHeight + 60) {
      top = top + 60;
    } else {
      top = top - toolbarHeight - 8;
    }

    return Positioned(
      left: left,
      top: top,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3a3a48),
              Color(0xFF2a2a34),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCopy != null)
                    _ToolbarButton(
                      icon: Icons.copy_rounded,
                      label: '复制',
                      onPressed: onCopy!,
                    ),
                  if (onHighlight != null)
                    _ToolbarButton(
                      icon: Icons.edit_rounded,
                      label: '添加笔记',
                      onPressed: onHighlight!,
                      iconColor: const Color(0xFFFFD54F),
                      labelColor: const Color(0xFFFFD54F),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 工具栏按钮
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? labelColor;

  const _ToolbarButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.labelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor ?? Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: labelColor ?? Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 笔记颜色选择器 - 弹出式面板
class HighlightColorPicker extends StatelessWidget {
  final Offset position;
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onClose;

  static const List<Color> highlightColors = [
    Color(0x80FFEB3B), // 黄色 (50%透明度)
    Color(0x804CAF50), // 绿色
    Color(0x802196F3), // 蓝色
    Color(0x80E91E63), // 粉色
    Color(0x80FF9800), // 橙色
    Color(0x809C27B0), // 紫色
    Color(0x809E9E9E), // 灰色
  ];

  const HighlightColorPicker({
    Key? key,
    required this.position,
    required this.currentColor,
    required this.onColorSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    double left = position.dx;
    double top = position.dy + 60;

    const pickerWidth = 240.0;

    // 水平边界检查
    if (left + pickerWidth > screenSize.width - 16) {
      left = screenSize.width - pickerWidth - 16;
    }
    if (left < 16) {
      left = 16;
    }

    return Stack(
      children: [
        // 透明背景 - 点击关闭
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),

        // 颜色选择面板
        Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF2a2a34),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: pickerWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择笔记颜色',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: highlightColors.map((color) {
                      final isSelected = color == currentColor;
                      return GestureDetector(
                        onTap: () => onColorSelected(color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
