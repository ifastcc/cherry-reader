import 'package:flutter/material.dart';

/// 高亮样式数据
class HighlightStyle {
  final Color color;
  final String type; // 'background' | 'underline'
  final String name;

  const HighlightStyle({
    required this.color,
    required this.type,
    this.name = '',
  });
}

/// 预定义的高亮样式列表（5个背景色 + 删除按钮，类似微信读书）
const List<HighlightStyle> kHighlightStyles = [
  HighlightStyle(color: Color(0xFFFFF176), type: 'background', name: '黄色'),
  HighlightStyle(color: Color(0xFF81D4FA), type: 'background', name: '蓝色'),
  HighlightStyle(color: Color(0xFFA5D6A7), type: 'background', name: '绿色'),
  HighlightStyle(color: Color(0xFFFFAB91), type: 'background', name: '橙色'),
  HighlightStyle(color: Color(0xFFCE93D8), type: 'background', name: '紫色'),
  HighlightStyle(color: Color(0xFFEF5350), type: 'underline', name: '红线'),
  HighlightStyle(color: Color(0xFF42A5F5), type: 'underline', name: '蓝线'),
];

/// 高亮样式菜单（仿微信读书风格）
///
/// 紧凑的胶囊形状，颜色圆点 + 删除按钮一行排列
class HighlightStyleMenuController {
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;
  String? _currentHighlightId;

  bool get isVisible => _isVisible;

  /// 显示菜单
  void show({
    required BuildContext context,
    required Offset position,
    required String highlightId,
    required int currentColor,
    required String currentStyleType,
    Function(String highlightId, int newColor, String newType)? onStyleChanged,
    Function(String highlightId)? onDelete,
    VoidCallback? onDismiss,
  }) {
    if (_isVisible) hide();

    _currentHighlightId = highlightId;

    final screenSize = MediaQuery.of(context).size;
    // 计算菜单宽度：7个颜色按钮(28*7) + 分割线(1+16) + 删除按钮(28) + 左右padding(24) + 间距(4*6)
    const menuWidth = 280.0;
    const menuHeight = 52.0;

    double left = position.dx - menuWidth / 2;
    double top = position.dy - menuHeight - 12; // 显示在点击位置上方

    // 边界检查
    if (left < 8) left = 8;
    if (left + menuWidth > screenSize.width - 8) {
      left = screenSize.width - menuWidth - 8;
    }
    if (top < 50) {
      top = position.dy + 12; // 如果上方空间不够，显示在下方
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _CompactHighlightMenu(
        left: left,
        top: top,
        currentColor: currentColor,
        currentStyleType: currentStyleType,
        onStyleSelected: (color, type) {
          if (_currentHighlightId != null) {
            onStyleChanged?.call(_currentHighlightId!, color, type);
          }
          hide();
        },
        onDelete: () {
          if (_currentHighlightId != null) {
            onDelete?.call(_currentHighlightId!);
          }
          hide();
        },
        onDismiss: () {
          hide();
          onDismiss?.call();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
    _currentHighlightId = null;
  }

  void dispose() => hide();
}

/// 紧凑型高亮菜单组件（仿微信读书）
class _CompactHighlightMenu extends StatelessWidget {
  final double left;
  final double top;
  final int currentColor;
  final String currentStyleType;
  final Function(int color, String type) onStyleSelected;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const _CompactHighlightMenu({
    required this.left,
    required this.top,
    required this.currentColor,
    required this.currentStyleType,
    required this.onStyleSelected,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 透明背景点击关闭
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        // 菜单
        Positioned(
          left: left,
          top: top,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.92 + 0.08 * value,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E), // 深色背景，类似微信读书
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 颜色选择按钮
                    ...kHighlightStyles.map((style) {
                      final isSelected =
                          currentColor == style.color.value &&
                          currentStyleType == style.type;
                      return _buildColorButton(style, isSelected);
                    }),
                    // 分隔线
                    Container(
                      width: 1,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    // 删除按钮
                    _buildDeleteButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorButton(HighlightStyle style, bool isSelected) {
    return GestureDetector(
      onTap: () => onStyleSelected(style.color.value, style.type),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: style.type == 'background' ? style.color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : (style.type == 'underline'
                      ? style.color.withValues(alpha: 0.6)
                      : Colors.transparent),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : (style.type == 'underline'
                  ? Center(
                      child: Container(
                        width: 14,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: style.color,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    )
                  : null),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.white.withValues(alpha: 0.85),
          size: 20,
        ),
      ),
    );
  }
}

/// 便捷的静态方法
class HighlightStyleMenu {
  static HighlightStyleMenuController? _controller;

  static void show({
    required BuildContext context,
    required Offset position,
    required String highlightId,
    required int currentColor,
    required String currentStyleType,
    Function(String highlightId, int newColor, String newType)? onStyleChanged,
    Function(String highlightId)? onDelete,
    VoidCallback? onDismiss,
  }) {
    _controller ??= HighlightStyleMenuController();
    _controller!.show(
      context: context,
      position: position,
      highlightId: highlightId,
      currentColor: currentColor,
      currentStyleType: currentStyleType,
      onStyleChanged: onStyleChanged,
      onDelete: onDelete,
      onDismiss: onDismiss,
    );
  }

  static void hide() => _controller?.hide();

  static bool get isVisible => _controller?.isVisible ?? false;
}
