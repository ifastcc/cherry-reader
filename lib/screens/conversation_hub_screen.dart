import 'package:flutter/material.dart';
import 'dart:async';
import '../services/repository_provider.dart';
import 'conversation_screen.dart';
import 'home_screen.dart';

/// 对话主屏（单页 + 左侧抽屉列表）
///
/// - 主区域显示话题详情
/// - 左侧抽屉显示助手/话题列表
class ConversationHubScreen extends StatefulWidget {
  const ConversationHubScreen({super.key});

  @override
  State<ConversationHubScreen> createState() => ConversationHubScreenState();
}

class ConversationHubScreenState extends State<ConversationHubScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _drawerDuration = Duration(milliseconds: 240);
  static const double _drawerMaxWidth = 360;
  static const double _drawerWidthRatio = 0.86;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  late final AnimationController _drawerController;
  double _drawerDragWidth = _drawerMaxWidth;
  bool _isDrawerDragging = false;

  String? _activeTopicId;
  String? _activeTopicName;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: _drawerDuration,
    );
    _loadInitialTopic();
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  double _resolveDrawerWidth(double screenWidth) {
    final preferred = screenWidth * _drawerWidthRatio;
    return preferred.clamp(280.0, _drawerMaxWidth);
  }

  Duration _settleDurationTo(double target) {
    final distance = (target - _drawerController.value).abs();
    if (distance <= 0.0001) {
      return Duration.zero;
    }
    final ms = (_drawerDuration.inMilliseconds * distance)
        .clamp(90, _drawerDuration.inMilliseconds)
        .round();
    return Duration(milliseconds: ms);
  }

  Future<void> _animateDrawerTo(double target) async {
    final current = _drawerController.value;
    if ((current - target).abs() <= 0.001) {
      _drawerController.value = target;
      return;
    }
    if (mounted) {
      setState(() {});
    }
    await _drawerController.animateTo(
      target,
      duration: _settleDurationTo(target),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleDrawerDragStart(DragStartDetails details) {
    if (!_isDrawerDragging && mounted) {
      setState(() {
        _isDrawerDragging = true;
      });
    } else {
      _isDrawerDragging = true;
    }
    _drawerController.stop();
  }

  void _handleDrawerDragUpdate(DragUpdateDetails details) {
    final width = _drawerDragWidth <= 0 ? _drawerMaxWidth : _drawerDragWidth;
    final next = (_drawerController.value + details.delta.dx / width).clamp(
      0.0,
      1.0,
    );
    _drawerController.value = next;
  }

  void _settleAfterDrag({double velocityX = 0}) {
    if (_isDrawerDragging && mounted) {
      setState(() {
        _isDrawerDragging = false;
      });
    } else {
      _isDrawerDragging = false;
    }
    const velocityThreshold = 380.0;
    if (_drawerController.value <= 0.001) {
      _closeDrawer();
      return;
    }
    if (_drawerController.value >= 0.999) {
      _openDrawer();
      return;
    }

    if (velocityX > velocityThreshold) {
      _openDrawer();
      return;
    }
    if (velocityX < -velocityThreshold) {
      _closeDrawer();
      return;
    }
    if (_drawerController.value >= 0.5) {
      _openDrawer();
    } else {
      _closeDrawer();
    }
  }

  void _handleDrawerDragEnd(DragEndDetails details) {
    _settleAfterDrag(velocityX: details.primaryVelocity ?? 0);
  }

  void _handleDrawerDragCancel() {
    _settleAfterDrag();
  }

  Future<void> _loadInitialTopic() async {
    try {
      final topics = await RepositoryProvider.instance.topicRepository
          .getAllTopics();
      if (topics.isNotEmpty) {
        topics.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final latest = topics.first;
        if (!mounted) return;
        setState(() {
          _activeTopicId = latest.topicId;
          _activeTopicName = latest.name;
          _isLoadingInitial = false;
        });
        return;
      }
    } catch (_) {
      // 忽略错误，降级为空状态
    }

    if (!mounted) return;
    setState(() {
      _isLoadingInitial = false;
    });
  }

  void _selectTopic(String topicId, String topicName) {
    setState(() {
      _activeTopicId = topicId;
      _activeTopicName = topicName;
    });
    _closeDrawer();
  }

  void _openDrawer() {
    if (_isDrawerDragging) {
      return;
    }
    if (_drawerController.value >= 0.999 &&
        _drawerController.status != AnimationStatus.reverse) {
      return;
    }
    unawaited(_animateDrawerTo(1.0));
  }

  void _closeDrawer() {
    if (_isDrawerDragging) {
      return;
    }
    if (_drawerController.value <= 0.001 &&
        _drawerController.status != AnimationStatus.forward) {
      return;
    }
    unawaited(_animateDrawerTo(0.0));
  }

  /// 处理主按钮点击（由 MainScreen 触发）
  void handleMainAction() {
    _homeKey.currentState?.handleMainAction();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _drawerController.value == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _drawerController.value > 0) {
          _closeDrawer();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 将主内容隔离到单独图层，降低侧栏动画期间的重绘开销
            RepaintBoundary(child: _buildBody()),
            // 关闭状态下，保留左侧边缘手势用于侧滑打开
            _buildOpenEdgeGestureArea(),
            _buildAnimatedDrawerLayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenEdgeGestureArea() {
    return AnimatedBuilder(
      animation: _drawerController,
      builder: (context, _) {
        // 关键：拖拽进行中即使 value>0 也不能把手势层移除，
        // 否则 recognizer 可能在中途被销毁，导致停在半开状态
        final shouldShow =
            _drawerController.value <= 0.001 || _isDrawerDragging;
        if (!shouldShow) return const SizedBox.shrink();

        return Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _handleDrawerDragStart,
            onHorizontalDragUpdate: _handleDrawerDragUpdate,
            onHorizontalDragEnd: _handleDrawerDragEnd,
            onHorizontalDragCancel: _handleDrawerDragCancel,
            child: const SizedBox(width: 24, height: double.infinity),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDrawerLayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final drawerWidth = _resolveDrawerWidth(constraints.maxWidth);
        _drawerDragWidth = drawerWidth;
        final drawerPanel = RepaintBoundary(
          child: SizedBox(
            width: drawerWidth,
            child: Material(
              elevation: 12,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _handleDrawerDragStart,
                onHorizontalDragUpdate: _handleDrawerDragUpdate,
                onHorizontalDragEnd: _handleDrawerDragEnd,
                onHorizontalDragCancel: _handleDrawerDragCancel,
                child: HomeScreen(
                  key: _homeKey,
                  embedMode: true,
                  onSelectTopic: _selectTopic,
                ),
              ),
            ),
          ),
        );

        return AnimatedBuilder(
          animation: _drawerController,
          child: drawerPanel,
          builder: (context, child) {
            final value = Curves.easeOutCubic.transform(
              _drawerController.value,
            );
            final dx = (value - 1) * drawerWidth;
            final isInteractive = _drawerController.value > 0;

            return IgnorePointer(
              ignoring: !isInteractive,
              child: SizedBox.expand(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeDrawer,
                      onHorizontalDragStart: _handleDrawerDragStart,
                      onHorizontalDragUpdate: _handleDrawerDragUpdate,
                      onHorizontalDragEnd: _handleDrawerDragEnd,
                      onHorizontalDragCancel: _handleDrawerDragCancel,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.22 * value),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeTopicId == null) {
      return _buildEmptyState();
    }

    return ConversationScreen(
      key: ValueKey(_activeTopicId),
      topicId: _activeTopicId!,
      topicName: _activeTopicName ?? '未命名话题',
      onOpenDrawer: _openDrawer,
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text('暂无话题'),
            const SizedBox(height: 8),
            Text(
              '从左侧抽屉选择话题，或先导入数据。',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openDrawer,
              icon: const Icon(Icons.menu),
              label: const Text('打开助手列表'),
            ),
          ],
        ),
      ),
    );
  }
}
