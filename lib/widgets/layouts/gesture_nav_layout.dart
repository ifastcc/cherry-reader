import 'package:flutter/material.dart';
import 'layout_scheme.dart';
import '../keep_alive_wrapper.dart';

/// 方案 D: 手势导航布局
/// 
/// 左右滑动手势切换页面，极简沉浸体验
/// - 顶部浮动页面指示器显示当前位置
/// - FAB 用于执行主操作
/// 
/// 注意：此布局不添加额外的 AppBar，子页面保留自己的导航结构
class GestureNavLayout extends LayoutScheme {
  const GestureNavLayout({
    super.key,
    required super.context,
  });

  @override
  LayoutSchemeType get type => LayoutSchemeType.gestureNav;

  @override
  Widget build(BuildContext buildContext) {
    final colorScheme = Theme.of(buildContext).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // 手势页面切换
          _GesturePageView(
            selectedIndex: context.selectedIndex,
            onPageChanged: context.onDestinationSelected,
            pages: [
              context.homeScreen,
              context.knowledgeScreen,
            ],
          ),
          // 顶部浮动页面指示器
          Positioned(
            top: MediaQuery.of(buildContext).padding.top + 12,
            left: 0,
            right: 0,
            child: Center(
              child: _buildPageIndicator(colorScheme),
            ),
          ),
        ],
      ),
      // 只在对话页面显示FAB，知识库页面由子页面自己处理
      floatingActionButton: context.selectedIndex == 0 
          ? _buildFAB(colorScheme)
          : null,
    );
  }

  Widget _buildPageIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(colorScheme, isActive: context.selectedIndex == 0, label: '对话', index: 0),
          const SizedBox(width: 16),
          _buildDot(colorScheme, isActive: context.selectedIndex == 1, label: '知识库', index: 1),
        ],
      ),
    );
  }

  Widget _buildDot(ColorScheme colorScheme, {required bool isActive, required String label, required int index}) {
    return GestureDetector(
      onTap: () {
        // Find the PageView controller via the context structure we built? 
        // Actually layouts.dart context has onDestinationSelected.
        // We need to access the callback passed to _GesturePageView or the one in LayoutSchemeContext.
        // The _buildPageIndicator is inside GestureNavLayout which has access to `context` (LayoutSchemeContext).
        context.onDestinationSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(ColorScheme colorScheme) {
    return FloatingActionButton(
      onPressed: context.onMainAction,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 4,
      child: Icon(
        context.selectedIndex == 0 
            ? Icons.auto_awesome_rounded 
            : Icons.add_rounded,
      ),
    );
  }
}

/// 手势滑动页面视图
class _GesturePageView extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;
  final List<Widget> pages;

  const _GesturePageView({
    required this.selectedIndex,
    required this.onPageChanged,
    required this.pages,
  });

  @override
  State<_GesturePageView> createState() => _GesturePageViewState();
}

class _GesturePageViewState extends State<_GesturePageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(_GesturePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _pageController.animateToPage(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: widget.onPageChanged,
      physics: const BouncingScrollPhysics(),
      // 使用 KeepAliveWrapper 保持子页面状态，避免切换时重建
      children: widget.pages.map((page) => KeepAliveWrapper(child: page)).toList(),
    );
  }
}

