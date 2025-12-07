import 'package:flutter/material.dart';

/// 横向滚动卡片容器 - 带 Snap 效果
///
/// 特点：
/// - 卡片横向排列，滚动后自动对齐到卡片边缘（snap）
/// - 响应式宽度：根据屏幕宽度自动计算，支持 1-4 列显示
/// - 平滑的翻页动画
/// - 支持外部控制翻页（通过 initialPage 变化）
class HorizontalScrollView extends StatefulWidget {
  final List<Widget> cards;
  final Widget? trailing;
  final int columnsPerView; // 一屏显示几个卡片 (1-4)
  final double cardHeight;
  final ValueChanged<int>? onPageChanged; // 页面变化回调
  final int? initialPage; // 初始页码（变化时会触发翻页动画）

  const HorizontalScrollView({
    Key? key,
    required this.cards,
    this.trailing,
    this.columnsPerView = 2, // 默认一屏显示2个
    this.cardHeight = 600,
    this.onPageChanged,
    this.initialPage,
  }) : super(key: key);

  /// 计算总页数
  static int calculateTotalPages(int totalCards, int columnsPerView) {
    if (totalCards == 0) return 0;
    return (totalCards / columnsPerView).ceil();
  }

  @override
  State<HorizontalScrollView> createState() => _HorizontalScrollViewState();
}

class _HorizontalScrollViewState extends State<HorizontalScrollView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ?? 0;
    _pageController = PageController(
      initialPage: _currentPage,
      // viewportFraction 1.0 让每页占满宽度
      viewportFraction: 1.0,
    );
  }

  @override
  void didUpdateWidget(HorizontalScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部 initialPage 变化时，触发翻页动画
    final newPage = widget.initialPage ?? 0;
    if (newPage != _currentPage && _pageController.hasClients) {
      _currentPage = newPage;
      _pageController.animateToPage(
        newPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
    final totalCards = widget.cards.length;
    if (totalCards == 0) {
      return const SizedBox.shrink();
    }

    // 获取屏幕宽度计算卡片尺寸
    final cardSpacing = 12.0;

    // 计算总页数（每页显示 columnsPerView 个卡片）
    final totalPages = (totalCards / widget.columnsPerView).ceil();

    return SizedBox(
      height: widget.cardHeight,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          _currentPage = page;
          widget.onPageChanged?.call(page);
        },
        itemCount: totalPages,
        itemBuilder: (context, pageIndex) {
          // 计算当前页应该显示的卡片范围
          final startIdx = pageIndex * widget.columnsPerView;
          final endIdx = (startIdx + widget.columnsPerView)
              .clamp(0, totalCards);
          final pageCards = widget.cards.sublist(startIdx, endIdx);

          // 如果是多列显示，用 Row 排列
          if (widget.columnsPerView > 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  for (var i = 0; i < pageCards.length; i++) ...[
                    Expanded(child: pageCards[i]),
                    if (i < pageCards.length - 1)
                      SizedBox(width: cardSpacing),
                  ],
                  // 如果这页卡片不满，补充空白
                  for (var i = pageCards.length;
                      i < widget.columnsPerView;
                      i++) ...[
                    SizedBox(width: cardSpacing),
                    const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            );
          } else {
            // 单列显示 - 无 padding，占满宽度
            return pageCards.first;
          }
        },
      ),
    );
  }
}
