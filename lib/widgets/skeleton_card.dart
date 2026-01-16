import 'package:flutter/material.dart';

/// 骨架屏卡片
/// 
/// 在内容加载或解析时显示，提供视觉反馈
class SkeletonCard extends StatelessWidget {
  /// 预估高度
  final double estimatedHeight;
  
  /// 是否启用 shimmer 动画
  final bool animate;
  
  /// 卡片类型（影响骨架屏样式）
  final SkeletonCardType type;

  const SkeletonCard({
    super.key,
    this.estimatedHeight = 200,
    this.animate = true,
    this.type = SkeletonCardType.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: estimatedHeight.clamp(100.0, 600.0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: animate 
          ? _AnimatedSkeleton(isDark: isDark, type: type)
          : _StaticSkeleton(isDark: isDark, type: type),
    );
  }
}

/// 骨架屏类型
enum SkeletonCardType {
  /// 内容卡片（多行文本）
  content,
  /// 用户问题（单行或少量行）
  userQuery,
  /// 代码块
  codeBlock,
}

/// 静态骨架屏（无动画）
class _StaticSkeleton extends StatelessWidget {
  final bool isDark;
  final SkeletonCardType type;

  const _StaticSkeleton({required this.isDark, required this.type});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark 
        ? Colors.grey[800]! 
        : Colors.grey[200]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildLines(baseColor),
    );
  }
  
  List<Widget> _buildLines(Color color) {
    switch (type) {
      case SkeletonCardType.userQuery:
        return [
          _SkeletonLine(widthFactor: 0.8, color: color),
        ];
      case SkeletonCardType.codeBlock:
        return [
          _SkeletonLine(widthFactor: 0.5, color: color, height: 14),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ];
      case SkeletonCardType.content:
        return [
          _SkeletonLine(widthFactor: 0.6, color: color, height: 20), // 标题
          const SizedBox(height: 12),
          _SkeletonLine(widthFactor: 1.0, color: color),
          const SizedBox(height: 8),
          _SkeletonLine(widthFactor: 0.95, color: color),
          const SizedBox(height: 8),
          _SkeletonLine(widthFactor: 0.88, color: color),
          const SizedBox(height: 8),
          _SkeletonLine(widthFactor: 0.7, color: color),
        ];
    }
  }
}

/// 带 shimmer 动画的骨架屏
class _AnimatedSkeleton extends StatefulWidget {
  final bool isDark;
  final SkeletonCardType type;

  const _AnimatedSkeleton({required this.isDark, required this.type});

  @override
  State<_AnimatedSkeleton> createState() => _AnimatedSkeletonState();
}

class _AnimatedSkeletonState extends State<_AnimatedSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark 
        ? Colors.grey[800]! 
        : Colors.grey[200]!;
    final highlightColor = widget.isDark 
        ? Colors.grey[700]! 
        : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: _StaticSkeleton(
            isDark: widget.isDark,
            type: widget.type,
          ),
        );
      },
    );
  }
}

/// 骨架屏行
class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final Color color;
  final double height;

  const _SkeletonLine({
    required this.widthFactor,
    required this.color,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
