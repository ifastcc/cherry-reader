import 'package:flutter/material.dart';

/// 横向滚动卡片容器
///
/// 对应 Streamlit 中的 components.html 横向滚动效果
/// 特点：
/// - 卡片横向排列，可滚动
/// - 末尾有 trailing 按钮（如"生成分析"）
/// - 支持流畅的触摸滚动
/// - 响应式宽度：根据屏幕宽度自动计算，支持 1-4 列显示
class HorizontalScrollView extends StatelessWidget {
  final List<Widget> cards;
  final Widget? trailing;
  final int columnsPerView; // 一屏显示几个卡片 (1-4)
  final double cardHeight;

  const HorizontalScrollView({
    Key? key,
    required this.cards,
    this.trailing,
    this.columnsPerView = 2, // 默认一屏显示2个
    this.cardHeight = 600,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;

    // 计算卡片宽度：(屏幕宽度 - 左右padding - 卡片间距) / 列数
    // padding: 16 (左) + 16 (右) = 32
    // spacing: 16 * (列数 - 1)
    final totalPadding = 32.0;
    final totalSpacing = 16.0 * (columnsPerView - 1);
    final cardWidth =
        (screenWidth - totalPadding - totalSpacing) / columnsPerView;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length + (trailing != null ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index < cards.length) {
            return SizedBox(width: cardWidth, child: cards[index]);
          } else {
            // Trailing 按钮
            return Center(child: trailing);
          }
        },
      ),
    );
  }
}
