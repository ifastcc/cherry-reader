import 'package:flutter/material.dart';

/// 双 FAB 样式枚举
enum DualFabStyle {
  /// 垂直主次：大朗读按钮 + 小讨论按钮
  verticalStack,

  /// 药丸合体：一个药丸形状，两个功能区
  pill,

  /// 斜向排列：45度斜向
  diagonal,

  /// 圆环组合：大圆 + 右下角小圆
  orbital,

  /// 胶囊徽章：朗读按钮 + 讨论徽章
  capsuleBadge,

  /// 水平并排：两个相同大小的圆形按钮
  horizontal,

  /// 弧形菜单：展开的弧形
  arc,

  /// 紧凑堆叠：小间距垂直排列
  compactStack,

  /// 浮动卡片：卡片式设计
  floatingCard,

  /// 极简线条：线条风格
  minimal,
}

/// 双 FAB 组件
/// 支持多种布局样式，滚动自动隐藏
class DualFab extends StatefulWidget {
  final DualFabStyle style;
  final VoidCallback onPlayPressed;
  final VoidCallback onDiscussPressed;
  final VoidCallback? onDiscussLongPressed; // 长按讨论按钮（选择当前轮）
  final int discussionCount;
  final bool isPlaying;
  final bool visible;
  final VoidCallback? onStyleChange; // 长按切换样式

  const DualFab({
    super.key,
    required this.style,
    required this.onPlayPressed,
    required this.onDiscussPressed,
    this.onDiscussLongPressed,
    this.discussionCount = 0,
    this.isPlaying = false,
    this.visible = true,
    this.onStyleChange,
  });

  @override
  State<DualFab> createState() => _DualFabState();
}

class _DualFabState extends State<DualFab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // 缩放：从 0.85 到 1.0，更微妙的变化
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // 淡入淡出
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    // 滑动：从底部 20px 滑入
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    if (widget.visible) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(DualFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: _buildFabByStyle(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFabByStyle() {
    switch (widget.style) {
      case DualFabStyle.verticalStack:
        return _buildVerticalStack();
      case DualFabStyle.pill:
        return _buildPill();
      case DualFabStyle.diagonal:
        return _buildDiagonal();
      case DualFabStyle.orbital:
        return _buildOrbital();
      case DualFabStyle.capsuleBadge:
        return _buildCapsuleBadge();
      case DualFabStyle.horizontal:
        return _buildHorizontal();
      case DualFabStyle.arc:
        return _buildArc();
      case DualFabStyle.compactStack:
        return _buildCompactStack();
      case DualFabStyle.floatingCard:
        return _buildFloatingCard();
      case DualFabStyle.minimal:
        return _buildMinimal();
    }
  }

  // ============ 样式 1：垂直主次 ============
  Widget _buildVerticalStack() {
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主按钮：朗读
          FloatingActionButton.extended(
            heroTag: 'play_fab',
            onPressed: widget.onPlayPressed,
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            icon: Icon(widget.isPlaying ? Icons.pause : Icons.headphones),
            label: Text(widget.isPlaying ? '暂停' : '朗读'),
          ),
          const SizedBox(height: 12),
          // 次按钮：讨论
          GestureDetector(
            onLongPress: widget.onDiscussLongPressed,
            child: FloatingActionButton.small(
              heroTag: 'discuss_fab',
              onPressed: widget.onDiscussPressed,
              backgroundColor: widget.discussionCount > 0
                  ? const Color(0xFF8B5CF6)
                  : Colors.white,
              foregroundColor: widget.discussionCount > 0
                  ? Colors.white
                  : const Color(0xFF8B5CF6),
              child: Badge(
                isLabelVisible: widget.discussionCount > 0,
                label: Text('${widget.discussionCount}'),
                child: const Icon(Icons.chat_bubble_outline, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 样式 2：药丸合体 ============
  Widget _buildPill() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 朗读按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPlayPressed,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isPlaying ? Icons.pause : Icons.headphones,
                        color: const Color(0xFF8B5CF6),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isPlaying ? '暂停' : '朗读',
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 分隔线
            Container(
              width: 1,
              height: 28,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            // 讨论按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onDiscussPressed,
                onLongPress: widget.onDiscussLongPressed,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Badge(
                    isLabelVisible: widget.discussionCount > 0,
                    backgroundColor: const Color(0xFF8B5CF6),
                    label: Text(
                      '${widget.discussionCount}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: Icon(
                      widget.discussionCount > 0
                          ? Icons.chat_bubble
                          : Icons.chat_bubble_outline,
                      color: widget.discussionCount > 0
                          ? const Color(0xFF8B5CF6)
                          : Colors.grey[600],
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 样式 3：斜向排列 ============
  Widget _buildDiagonal() {
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          children: [
            // 朗读按钮（右上）
            Positioned(
              right: 0,
              top: 0,
              child: FloatingActionButton(
                heroTag: 'play_fab',
                onPressed: widget.onPlayPressed,
                backgroundColor: const Color(0xFF8B5CF6),
                child: Icon(
                  widget.isPlaying ? Icons.pause : Icons.headphones,
                  color: Colors.white,
                ),
              ),
            ),
            // 讨论按钮（左下）
            Positioned(
              left: 0,
              bottom: 0,
              child: GestureDetector(
                onLongPress: widget.onDiscussLongPressed,
                child: FloatingActionButton.small(
                  heroTag: 'discuss_fab',
                  onPressed: widget.onDiscussPressed,
                  backgroundColor: widget.discussionCount > 0
                      ? const Color(0xFFEC4899)
                      : Colors.white,
                  child: Badge(
                    isLabelVisible: widget.discussionCount > 0,
                    label: Text('${widget.discussionCount}'),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: widget.discussionCount > 0
                          ? Colors.white
                          : const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 样式 4：圆环组合 ============
  Widget _buildOrbital() {
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          children: [
            // 主按钮（大圆）
            Positioned.fill(
              child: FloatingActionButton.large(
                heroTag: 'play_fab',
                onPressed: widget.onPlayPressed,
                backgroundColor: const Color(0xFF8B5CF6),
                child: Icon(
                  widget.isPlaying ? Icons.pause : Icons.headphones,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            // 讨论按钮（右下角小圆）
            Positioned(
              right: -4,
              bottom: -4,
              child: GestureDetector(
                onTap: widget.onDiscussPressed,
                onLongPress: widget.onDiscussLongPressed,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.discussionCount > 0
                        ? const Color(0xFFEC4899)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.discussionCount > 0
                        ? Text(
                            '${widget.discussionCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 样式 5：胶囊徽章 ============
  Widget _buildCapsuleBadge() {
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 朗读按钮（胶囊形状）
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPlayPressed,
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isPlaying ? '暂停' : '朗读',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 讨论徽章（点击可进入讨论）
          Transform.translate(
            offset: const Offset(0, -8),
            child: GestureDetector(
              onTap: widget.onDiscussPressed,
              onLongPress: widget.onDiscussLongPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.discussionCount > 0
                      ? const Color(0xFFEC4899)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      size: 14,
                      color: widget.discussionCount > 0
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    if (widget.discussionCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${widget.discussionCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 样式 6：水平并排 ============
  Widget _buildHorizontal() {
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 朗读按钮
          FloatingActionButton(
            heroTag: 'play_fab',
            onPressed: widget.onPlayPressed,
            backgroundColor: const Color(0xFF8B5CF6),
            child: Icon(
              widget.isPlaying ? Icons.pause : Icons.headphones,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // 讨论按钮
          GestureDetector(
            onLongPress: widget.onDiscussLongPressed,
            child: FloatingActionButton(
              heroTag: 'discuss_fab',
              onPressed: widget.onDiscussPressed,
              backgroundColor: widget.discussionCount > 0
                  ? const Color(0xFFEC4899)
                  : Colors.white,
              child: Badge(
                isLabelVisible: widget.discussionCount > 0,
                label: Text('${widget.discussionCount}'),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: widget.discussionCount > 0
                      ? Colors.white
                      : const Color(0xFF8B5CF6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 样式 7：弧形菜单 ============
  Widget _buildArc() {
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // 讨论按钮（弧形位置1）
            Positioned(
              left: 0,
              bottom: 20,
              child: GestureDetector(
                onLongPress: widget.onDiscussLongPressed,
                child: FloatingActionButton.small(
                  heroTag: 'discuss_fab',
                  onPressed: widget.onDiscussPressed,
                  backgroundColor: widget.discussionCount > 0
                      ? const Color(0xFFEC4899)
                      : Colors.white,
                  elevation: 4,
                  child: Badge(
                    isLabelVisible: widget.discussionCount > 0,
                    label: Text('${widget.discussionCount}'),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: widget.discussionCount > 0
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            // 朗读按钮（主按钮）
            Positioned(
              right: 0,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: 'play_fab',
                onPressed: widget.onPlayPressed,
                backgroundColor: const Color(0xFF8B5CF6),
                child: Icon(
                  widget.isPlaying ? Icons.pause : Icons.headphones,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 样式 8：紧凑堆叠 ============
  Widget _buildCompactStack() {
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 朗读按钮
          FloatingActionButton.small(
            heroTag: 'play_fab',
            onPressed: widget.onPlayPressed,
            backgroundColor: const Color(0xFF8B5CF6),
            child: Icon(
              widget.isPlaying ? Icons.pause : Icons.headphones,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          // 讨论按钮
          GestureDetector(
            onLongPress: widget.onDiscussLongPressed,
            child: FloatingActionButton.small(
              heroTag: 'discuss_fab',
              onPressed: widget.onDiscussPressed,
              backgroundColor: widget.discussionCount > 0
                  ? const Color(0xFFEC4899)
                  : Colors.white,
              child: Badge(
                isLabelVisible: widget.discussionCount > 0,
                label: Text('${widget.discussionCount}'),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: widget.discussionCount > 0
                      ? Colors.white
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 样式 9：浮动卡片 ============
  Widget _buildFloatingCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 朗读按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPlayPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.isPlaying ? Icons.pause : Icons.headphones,
                          color: const Color(0xFF8B5CF6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.isPlaying ? '暂停' : '朗读',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
            // 讨论按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onDiscussPressed,
                onLongPress: widget.onDiscussLongPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.discussionCount > 0
                              ? const Color(0xFFEC4899).withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: widget.discussionCount > 0
                              ? const Color(0xFFEC4899)
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '讨论',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.discussionCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.discussionCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 样式 10：极简线条 ============
  Widget _buildMinimal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: widget.onStyleChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 朗读按钮
            IconButton(
              onPressed: widget.onPlayPressed,
              icon: Icon(
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFF8B5CF6),
              ),
              tooltip: widget.isPlaying ? '暂停' : '朗读',
            ),
            Container(
              width: 24,
              height: 1,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
            // 讨论按钮
            GestureDetector(
              onLongPress: widget.onDiscussLongPressed,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: widget.onDiscussPressed,
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: widget.discussionCount > 0
                          ? const Color(0xFFEC4899)
                          : Colors.grey[600],
                    ),
                    tooltip: '讨论',
                  ),
                  if (widget.discussionCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEC4899),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.discussionCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 样式名称映射
extension DualFabStyleExtension on DualFabStyle {
  String get displayName {
    switch (this) {
      case DualFabStyle.verticalStack:
        return '垂直主次';
      case DualFabStyle.pill:
        return '药丸合体';
      case DualFabStyle.diagonal:
        return '斜向排列';
      case DualFabStyle.orbital:
        return '圆环组合';
      case DualFabStyle.capsuleBadge:
        return '胶囊徽章';
      case DualFabStyle.horizontal:
        return '水平并排';
      case DualFabStyle.arc:
        return '弧形菜单';
      case DualFabStyle.compactStack:
        return '紧凑堆叠';
      case DualFabStyle.floatingCard:
        return '浮动卡片';
      case DualFabStyle.minimal:
        return '极简线条';
    }
  }

  String get description {
    switch (this) {
      case DualFabStyle.verticalStack:
        return '大朗读按钮在上，小讨论按钮在下';
      case DualFabStyle.pill:
        return '一个药丸形状，左朗读右讨论';
      case DualFabStyle.diagonal:
        return '45度斜向排列，朗读右上讨论左下';
      case DualFabStyle.orbital:
        return '大圆朗读按钮，右下角小圆讨论';
      case DualFabStyle.capsuleBadge:
        return '渐变胶囊朗读按钮，下方讨论徽章';
      case DualFabStyle.horizontal:
        return '两个相同大小的圆形按钮并排';
      case DualFabStyle.arc:
        return '弧形展开，主按钮在右下';
      case DualFabStyle.compactStack:
        return '两个小按钮紧凑垂直排列';
      case DualFabStyle.floatingCard:
        return '卡片式设计，带图标和文字';
      case DualFabStyle.minimal:
        return '极简线条风格，轻盈透明';
    }
  }
}
