import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:async';
import '../services/cherry_extractor.dart';
import '../services/analysis_cache_manager.dart';
import '../services/highlight_service.dart';
import '../services/topic_service.dart';
import '../services/markdown_isolate_parser.dart';
import '../widgets/highlightable_card.dart';
import '../widgets/message_action_bar.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../models/tts_item.dart';
import '../widgets/tts_mini_player.dart';

class ConversationScreen extends StatefulWidget {
  final CherryExtractor? extractor;
  final String topicId;
  final String topicName;
  final VoidCallback? onOpenDrawer;

  /// 【搜索定位】初始滚动到的轮次索引（从 0 开始）
  final int? scrollToRoundIndex;

  /// 【跳转定位】初始滚动到的消息 ID
  final String? scrollToMessageId;

  /// 【精确定位】跳转到的高亮 ID（配合 scrollToMessageId 使用）
  final String? scrollToHighlightId;

  final int? scrollToTextStart;

  final int? scrollToTextEnd;

  final String? scrollToQuotedText;

  final int? scrollToQuotedTextOccurrence;

  /// 【搜索高亮】要高亮的搜索关键词
  final String? highlightKeyword;

  const ConversationScreen({
    super.key,
    this.extractor,
    required this.topicId,
    required this.topicName,
    this.onOpenDrawer,
    this.scrollToRoundIndex,
    this.scrollToMessageId,
    this.scrollToHighlightId,
    this.scrollToTextStart,
    this.scrollToTextEnd,
    this.scrollToQuotedText,
    this.scrollToQuotedTextOccurrence,
    this.highlightKeyword,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  static const bool _enableTopicDebugLog = false;
  static const int _backgroundWarmupInitialDelayMs = 260;
  static const int _warmupCollectYieldInterval = 24;
  static const int _highlightWarmupChunkSize = 40;
  static const int _highlightWarmupMaxEntries = 200;
  static const int _preParseImmediateCount = 10;
  static const int _preParseChunkSize = 6;
  static const int _preParseMaxBackgroundEntries = 120;

  late final AnalysisCacheManager _cacheManager;
  late final TopicService _topicService;

  Map<String, dynamic>? _conversation;
  // _cacheData 已移除，Isar 自动管理持久化
  Map<int, List<String>> _aiAnalyses = {};

  // 【性能优化】缓存对话分组结果
  List<Map<String, dynamic>>? _cachedGroups;

  // 【轮次导航】使用 scroll_to_index 实现精确跳转
  late AutoScrollController _scrollController;

  // 【性能优化】使用 ValueNotifier 避免整个页面重建
  final ValueNotifier<int> _currentVisibleGroupNotifier = ValueNotifier(0);
  final ValueNotifier<double> _currentGroupProgressNotifier = ValueNotifier(
    0.0,
  );

  // 【Sticky Tab 可见性】- 使用 ValueNotifier 优化
  final ValueNotifier<bool> _currentGroupTabVisibleNotifier = ValueNotifier(
    true,
  );
  int _preParseTaskToken = 0;

  // 【内联 Tab 位置追踪】
  final Map<int, GlobalKey> _inlineTabKeys = {};

  // 【卡片翻页】每个轮次的当前卡片页码 - 使用 ValueNotifier 避免整页重建
  final Map<int, ValueNotifier<int>> _cardPageNotifiers = {};

  // 【滑动切换】每个轮次的 PageController
  final Map<int, PageController> _pageControllers = {};

  // 【Tab联动】每个轮次的 Tab ScrollController
  final Map<int, ScrollController> _tabScrollControllers = {};

  // Tab 项的 GlobalKey，用于计算位置
  final Map<String, GlobalKey> _tabKeys = {};

  // 【性能优化】记录上次处理的 Tab 页码，避免重复注册 postFrameCallback
  final Map<int, int> _lastProcessedTabPage = {};

  /// 获取或创建指定轮次的页码 ValueNotifier
  ValueNotifier<int> _getCardPageNotifier(int groupIndex) {
    return _cardPageNotifiers.putIfAbsent(groupIndex, () => ValueNotifier(0));
  }

  /// 【精确定位】目标高亮 ID（用于闪烁提示）
  String? _targetHighlightId;

  /// 【快速定位】滚动到指定轮次的顶部
  void _scrollToGroupTop(int groupIndex) {
    _scrollController.scrollToIndex(
      groupIndex,
      preferPosition: AutoScrollPosition.begin,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// 【快速定位】滚动到指定轮次的 Tab 栏顶部
  /// 让 Tab 栏正好位于 AppBar 下方，用户可以直接看到回复内容
  void _scrollToTabTop(int groupIndex) {
    final tabKey = _inlineTabKeys[groupIndex];
    if (tabKey?.currentContext == null) {
      // Tab 还未渲染，回退到轮次顶部
      _scrollToGroupTop(groupIndex);
      return;
    }

    final RenderBox? tabBox =
        tabKey!.currentContext!.findRenderObject() as RenderBox?;
    if (tabBox == null || !tabBox.hasSize) {
      _scrollToGroupTop(groupIndex);
      return;
    }

    // 获取 Tab 栏在屏幕上的当前位置
    final tabPosition = tabBox.localToGlobal(Offset.zero);

    // 计算目标位置：让 Tab 栏顶部位于 AppBar 下方
    // viewportTop = 状态栏高度 + AppBar 高度
    final viewportTop = MediaQuery.of(context).padding.top + kToolbarHeight;

    // 需要滚动的距离 = Tab 当前位置 - 目标位置
    final scrollDelta = tabPosition.dy - viewportTop;

    // 计算新的滚动位置
    final targetOffset = (_scrollController.offset + scrollDelta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();

    _cacheManager = AnalysisCacheManager();
    _topicService = TopicService();

    // 初始化 AutoScrollController
    _scrollController = AutoScrollController(
      axis: Axis.vertical,
      // 估算的平均行高，帮助快速定位未渲染的 item
      suggestedRowHeight: 400,
    );

    _loadData();

    // 监听滚动变化
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _preParseTaskToken++;
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _currentVisibleGroupNotifier.dispose();
    _currentGroupProgressNotifier.dispose();
    _currentGroupTabVisibleNotifier.dispose();
    // 释放所有 PageController
    for (final controller in _pageControllers.values) {
      controller.dispose();
    }
    _pageControllers.clear();
    // 释放所有 Tab ScrollController
    for (final controller in _tabScrollControllers.values) {
      controller.dispose();
    }
    _tabScrollControllers.clear();
    // 释放所有卡片页码 ValueNotifier
    for (final notifier in _cardPageNotifiers.values) {
      notifier.dispose();
    }
    _cardPageNotifiers.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果话题 ID 变化，需要重新加载数据
    if (oldWidget.topicId != widget.topicId) {
      debugPrint(
        '🔄 [ConversationScreen] topicId 变化: ${oldWidget.topicId} → ${widget.topicId}',
      );

      // 清空所有缓存
      _conversation = null;
      _cachedGroups = null;
      _aiAnalyses = {};

      // 重新加载数据
      _loadData();
    }
  }

  /// 滚动变化回调：更新当前轮次和滚动进度
  ///
  /// 核心逻辑：
  /// 1. 找到当前与视口顶部相交或最接近的轮次
  /// 2. 判断该轮次的内联 Tab 是否可见
  /// 3. 计算滚动进度
  void _onScrollChanged() {
    // 【性能优化】节流：限制计算频率（32ms ≈ 30fps，足够流畅且降低计算开销）
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastScrollUpdate < 32) return;
    _lastScrollUpdate = now;

    final groups = _getConversationGroups();
    if (groups.isEmpty) return;

    // 获取视口信息
    final viewportTop = MediaQuery.of(context).padding.top + kToolbarHeight;
    final viewportHeight = MediaQuery.of(context).size.height - viewportTop;

    // 通过 AutoScrollController 的 tagMap 获取已渲染的 items
    final tagMap = _scrollController.tagMap;

    // 【性能优化】从上次可见位置开始搜索，减少遍历次数
    final lastVisible = _currentVisibleGroupNotifier.value;
    final searchStart = (lastVisible - 1).clamp(0, groups.length - 1);

    // 查找结果
    int visibleGroup = _currentVisibleGroupNotifier.value; // 保持上次值作为默认
    double progress = 0.0;
    bool tabVisible = true;
    for (var i = searchStart; i < groups.length; i++) {
      final tagState = tagMap[i];
      if (tagState == null) continue;

      final ctx = tagState.context;
      final RenderBox? box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      // 获取 item 相对于屏幕的位置
      final itemPosition = box.localToGlobal(Offset.zero);
      final itemTop = itemPosition.dy;
      final itemHeight = box.size.height;
      final itemBottom = itemTop + itemHeight;

      // 情况 1：item 与视口顶部相交（主要可见区域）
      if (itemBottom > viewportTop && itemTop < viewportTop + 100) {
        visibleGroup = i;
        tabVisible = _isInlineTabVisibleForGroup(i, viewportTop);

        final scrolledDistance = viewportTop - itemTop;
        final isLastItem = i == groups.length - 1;

        double effectiveHeight;
        if (isLastItem && itemHeight > viewportHeight) {
          // 最后一项比视口高：滚动到底部时还要保留在视口内
          effectiveHeight = itemHeight - viewportHeight;
          progress = (scrolledDistance / effectiveHeight).clamp(0.0, 1.0);
        } else if (isLastItem && itemHeight <= viewportHeight) {
          // 最后一项比视口矮：按实际高度渐进计算
          effectiveHeight = itemHeight;
          progress = (scrolledDistance / effectiveHeight).clamp(0.0, 1.0);
        } else {
          effectiveHeight = itemHeight;
          progress = (scrolledDistance / effectiveHeight).clamp(0.0, 1.0);
        }

        break;
      }

      // 情况 2：item 完全在视口上方（已滚过）
      if (itemBottom <= viewportTop) {
        visibleGroup = i;
        progress = 1.0;
        tabVisible = false;
        // 不 break，继续找下一个（可能有更接近视口的 item）
        continue;
      }

      // 情况 3：item 顶部刚好在视口顶部下方（即将进入）
      // 这是从上一个轮次切换到这个轮次的过渡期
      if (itemTop > viewportTop && itemTop <= viewportTop + 200) {
        // 上一个轮次已滚出，这个轮次即将进入
        // 切换到这个轮次，它的内联 Tab 应该是可见的
        visibleGroup = i;
        tabVisible = _isInlineTabVisibleForGroup(i, viewportTop);
        progress = 0.0;
        break;
      }

      // 情况 4：item 还在视口下方太远，跳出
      if (itemTop > viewportTop + 200) {
        break;
      }
    }

    // 【性能优化】只更新 ValueNotifier，不触发整个页面重建
    if (visibleGroup != _currentVisibleGroupNotifier.value) {
      _currentVisibleGroupNotifier.value = visibleGroup;
    }
    if ((progress - _currentGroupProgressNotifier.value).abs() > 0.01) {
      _currentGroupProgressNotifier.value = progress;
    }
    if (tabVisible != _currentGroupTabVisibleNotifier.value) {
      _currentGroupTabVisibleNotifier.value = tabVisible;
    }
  }

  /// 【新增】精确判断指定轮次的内联 Tab 是否可见
  /// 使用 GlobalKey 获取内联 Tab 的实际位置，而非估算
  bool _isInlineTabVisibleForGroup(int groupIndex, double viewportTop) {
    final tabKey = _inlineTabKeys[groupIndex];
    if (tabKey?.currentContext == null) {
      // Tab 还没渲染，默认可见（避免闪烁）
      return true;
    }

    final RenderBox? tabBox =
        tabKey!.currentContext!.findRenderObject() as RenderBox?;
    if (tabBox == null || !tabBox.hasSize) {
      return true;
    }

    // 获取内联 Tab 相对于屏幕的位置
    final tabPosition = tabBox.localToGlobal(Offset.zero);
    final tabTop = tabPosition.dy;
    final tabHeight = tabBox.size.height;
    final tabBottom = tabTop + tabHeight;

    // 如果 Tab 的底部还在视口顶部以下，说明 Tab 还可见
    // 留 8px 的缓冲区，让切换更平滑
    return tabBottom > viewportTop + 8;
  }

  int _lastScrollUpdate = 0; // 节流用

  /// 处理滚动通知
  bool _handleScrollNotification(ScrollNotification notification) {
    return false;
  }

  /// 跳转到指定轮次（使用 scroll_to_index 的两阶段滚动）
  Future<void> _scrollToGroup(int groupIndex) async {
    final groups = _getConversationGroups();
    if (groupIndex < 0 || groupIndex >= groups.length) return;

    // 第一阶段：快速滚动到目标位置附近
    await _scrollController.scrollToIndex(
      groupIndex,
      preferPosition: AutoScrollPosition.begin,
      duration: const Duration(milliseconds: 300),
    );

    // 第二阶段：等待一帧后，再次调用 scrollToIndex 确保精确定位
    // scroll_to_index 在 ListView.separated 中有时会因为分隔符高度而定位不准
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    // 第二次调用可以校准位置（此时目标元素已渲染完成）
    await _scrollController.scrollToIndex(
      groupIndex,
      preferPosition: AutoScrollPosition.begin,
      duration: const Duration(milliseconds: 100),
    );
  }

  /// 【搜索定位】延迟滚动到指定轮次
  ///
  /// 用于页面初始加载后的自动定位，需要等待 ListView 完全渲染
  Future<void> _scrollToGroupWithDelay(int groupIndex) async {
    // 等待 ListView 完全构建
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    await _scrollToGroup(groupIndex);

    // 滚动完成后，短暂高亮提示用户
    debugPrint('🎯 [搜索定位] 已滚动到第 ${groupIndex + 1} 轮');
  }

  /// 【跳转定位】延迟滚动到指定消息
  Future<void> _scrollToMessageWithDelay(String messageId) async {
    // 等待 ListView 完全构建
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final groups = _getConversationGroups();
    int targetGroup = -1;
    int targetCardIndex = 0;

    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      // Check user message
      final userMsg = group['user_message'] as Map<String, dynamic>;
      if (userMsg['id'] == messageId) {
        targetGroup = i;
        targetCardIndex =
            0; // User message is usually visible or part of the group header/content
        break;
      }

      // Check assistant replies
      final replies = group['assistant_replies'] as List;
      for (int j = 0; j < replies.length; j++) {
        final reply = replies[j] as Map<String, dynamic>;
        if (reply['id'] == messageId) {
          targetGroup = i;
          // Calculate card index (AI analyses + reply index)
          final aiAnalyses = _aiAnalyses[i] ?? [];
          targetCardIndex = aiAnalyses.length + j;
          break;
        }
      }
      if (targetGroup != -1) break;
    }

    if (targetGroup != -1) {
      // 【精确定位】设置目标高亮 ID，触发闪烁动画
      if (widget.scrollToHighlightId != null) {
        setState(() {
          _targetHighlightId = widget.scrollToHighlightId;
        });
        debugPrint('🎯 [精确定位] 设置目标高亮: $_targetHighlightId');

        // 5 秒后自动清除目标高亮（闪烁动画结束）
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _targetHighlightId == widget.scrollToHighlightId) {
            setState(() {
              _targetHighlightId = null;
            });
          }
        });
      }

      await _scrollToGroup(targetGroup);

      // If it's a specific card index (for replies), switch to it
      // Note: User message usually doesn't need card switching as it's the main content or part of the flow.
      // But if we are in card mode, we might want to ensure the right card is shown.
      if (targetCardIndex > 0) {
        _getCardPageNotifier(targetGroup).value = targetCardIndex;
        // Sync PageController
        final pageController = _pageControllers[targetGroup];
        if (pageController != null && pageController.hasClients) {
          pageController.jumpToPage(targetCardIndex);
        }
      }

      debugPrint('🎯 [跳转定位] 已滚动到消息 $messageId (所在第 ${targetGroup + 1} 轮)');
    } else {
      debugPrint('⚠️ [跳转定位] 未找到消息 $messageId');
    }
  }

  Future<void> _loadData() async {
    final preParseTaskToken = ++_preParseTaskToken;
    final totalSw = Stopwatch()..start();
    final sw = Stopwatch()..start();

    // 【性能优化】并行加载独立数据源
    final topicFuture = _topicService.getTopicFullData(widget.topicId);
    final analysesFuture = _cacheManager.getTopicAnalyses(widget.topicId);

    // 并行等待（比串行快 30-50%）
    final results = await Future.wait([topicFuture, analysesFuture]);
    var conv = results[0] as Map<String, dynamic>?;
    final analyses = results[1] as Map<int, List<String>>;
    debugPrint('⏱️ [ConversationScreen] 并行加载数据: ${sw.elapsedMilliseconds}ms');

    // 如果缓存中没有数据，使用 extractor（fallback）
    if (conv == null && widget.extractor != null) {
      sw.reset();
      conv = widget.extractor!.extractTopicConversation(widget.topicId);
      debugPrint(
        '⏱️ [ConversationScreen] fallback到extractor: ${sw.elapsedMilliseconds}ms',
      );
    }

    debugPrint(
      '⏱️ [ConversationScreen] _loadData 总耗时: ${totalSw.elapsedMilliseconds}ms',
    );

    // 【修复】检查 widget 是否仍然挂载
    if (!mounted) return;

    final renderSw = Stopwatch()..start();
    setState(() {
      _conversation = conv;
      _aiAnalyses = analyses;
      _cachedGroups = null; // 清除缓存，触发重新计算
    });

    // 将重型预热延后到空闲窗口，避免与首屏交互/抽屉动画竞争主线程
    if (conv != null) {
      unawaited(_runBackgroundWarmups(conv, taskToken: preParseTaskToken));
    }

    // 测量首帧渲染时间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        '⏱️ [ConversationScreen] 首帧渲染完成: ${renderSw.elapsedMilliseconds}ms',
      );

      // 【搜索定位】如果有指定的轮次，自动滚动到该位置
      if (widget.scrollToRoundIndex != null) {
        _scrollToGroupWithDelay(widget.scrollToRoundIndex!);
      } else if (widget.scrollToMessageId != null) {
        // 【跳转定位】如果指定了消息 ID，滚动到对应位置
        _scrollToMessageWithDelay(widget.scrollToMessageId!);
      }
    });

    // ========== 调试信息：打印 Topic 详情 ==========
    if (kDebugMode && _enableTopicDebugLog) {
      _printTopicDebugInfo();
    }
  }

  Future<void> _runBackgroundWarmups(
    Map<String, dynamic> conv, {
    required int taskToken,
  }) async {
    // 给首帧和抽屉手势留出窗口，降低“打开时中段顿一下”的概率
    await Future<void>.delayed(
      const Duration(milliseconds: _backgroundWarmupInitialDelayMs),
    );
    if (!_shouldContinuePreParse(taskToken)) return;

    final messages = conv['messages'] as List<dynamic>? ?? [];
    final messageIds = <String>[];

    for (var i = 0; i < messages.length; i++) {
      if (!_shouldContinuePreParse(taskToken)) return;

      final msg = messages[i];
      if (msg is! Map<String, dynamic>) continue;
      final messageId = msg['id'] as String?;
      if (messageId != null && messageId.isNotEmpty) {
        messageIds.add(messageId);
        if (messageIds.length >= _highlightWarmupMaxEntries) break;
      }

      // 分片收集，避免一次性遍历占满主线程
      if (i > 0 && i % _warmupCollectYieldInterval == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    if (messageIds.isNotEmpty) {
      await _warmUpHighlights(messageIds, taskToken: taskToken);
    }
    if (!_shouldContinuePreParse(taskToken)) return;

    await _preParseAllContent(conv, taskToken: taskToken);
  }

  Future<void> _warmUpHighlights(
    List<String> messageIds, {
    required int taskToken,
  }) async {
    final sw = Stopwatch()..start();
    final preloadIds = messageIds
        .take(_highlightWarmupMaxEntries)
        .toList(growable: false);
    if (preloadIds.isEmpty) return;

    try {
      final highlightService = HighlightService();
      for (var i = 0; i < preloadIds.length; i += _highlightWarmupChunkSize) {
        if (!_shouldContinuePreParse(taskToken)) return;

        final end = i + _highlightWarmupChunkSize > preloadIds.length
            ? preloadIds.length
            : i + _highlightWarmupChunkSize;
        final chunk = preloadIds.sublist(i, end);
        await highlightService.batchPreload(chunk);

        if (!_shouldContinuePreParse(taskToken)) return;
        if (end < preloadIds.length) {
          await Future<void>.delayed(const Duration(milliseconds: 8));
        }
      }
      debugPrint(
        '⏱️ [ConversationScreen] 后台标注预加载 (${preloadIds.length}条): ${sw.elapsedMilliseconds}ms',
      );
    } catch (e) {
      debugPrint('⚠️ [ConversationScreen] 标注预加载失败: $e');
    }
  }

  /// 【性能优化】Isolate 预解析所有轮次的 Markdown 内容
  ///
  /// 在后台线程完成解析，为首屏渲染做准备
  Future<void> _preParseAllContent(
    Map<String, dynamic> conv, {
    required int taskToken,
  }) async {
    final messages = conv['messages'] as List<dynamic>? ?? [];
    final entries = <MapEntry<String, String>>[];
    const maxEntries = _preParseImmediateCount + _preParseMaxBackgroundEntries;

    // 收集所有需要解析的内容
    for (var i = 0; i < messages.length; i++) {
      if (!_shouldContinuePreParse(taskToken)) return;

      final msg = messages[i];
      if (msg is! Map<String, dynamic>) continue;
      final messageId = msg['id'] as String?;
      if (messageId == null || messageId.isEmpty) continue;

      // 提取 Markdown 内容
      final blocks = msg['blocks'] as List<dynamic>? ?? [];
      final buffer = StringBuffer();
      for (final block in blocks) {
        if (block is Map<String, dynamic>) {
          final type = block['type'] as String?;
          if (type == 'main_text' || type == 'thinking' || type == 'code') {
            buffer.write(block['content'] as String? ?? '');
          }
        }
      }

      final content = buffer.toString();
      if (content.isNotEmpty) {
        entries.add(MapEntry(messageId, content));
        if (entries.length >= maxEntries) break;
      }

      // 大会话分片收集，避免一次性遍历造成卡顿
      if (i > 0 && i % _warmupCollectYieldInterval == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    if (entries.isEmpty || !_shouldContinuePreParse(taskToken)) return;

    final firstBatch = entries
        .take(_preParseImmediateCount)
        .toList(growable: false);
    try {
      await MarkdownIsolateParser.instance.batchPreParse(
        Map<String, String>.fromEntries(firstBatch),
      );
    } catch (e) {
      debugPrint('⚠️ [ConversationScreen] 首批 Markdown 预解析失败: $e');
      return;
    }

    if (!_shouldContinuePreParse(taskToken) ||
        entries.length <= _preParseImmediateCount) {
      return;
    }

    final remaining = entries
        .skip(_preParseImmediateCount)
        .take(_preParseMaxBackgroundEntries)
        .toList(growable: false);

    for (var i = 0; i < remaining.length; i += _preParseChunkSize) {
      if (!_shouldContinuePreParse(taskToken)) return;
      final end = i + _preParseChunkSize > remaining.length
          ? remaining.length
          : i + _preParseChunkSize;
      final chunk = remaining.sublist(i, end);
      try {
        await MarkdownIsolateParser.instance.batchPreParse(
          Map<String, String>.fromEntries(chunk),
        );
      } catch (e) {
        debugPrint('⚠️ [ConversationScreen] Markdown 分批预解析失败: $e');
        return;
      }

      if (!_shouldContinuePreParse(taskToken)) return;
      // 让出主线程时间片，降低后台预热对交互流畅度的影响
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  bool _shouldContinuePreParse(int taskToken) {
    return mounted && taskToken == _preParseTaskToken;
  }

  /// 打印 Topic 调试信息
  void _printTopicDebugInfo() {
    print('\n');
    print(
      '╔══════════════════════════════════════════════════════════════════╗',
    );
    print('║                    📋 TOPIC 详情调试信息                          ║');
    print(
      '╠══════════════════════════════════════════════════════════════════╣',
    );
    print('║ Topic ID:    ${widget.topicId}');
    print('║ Topic 名称:  ${widget.topicName}');

    // 获取 Assistant 信息
    if (widget.extractor != null) {
      final topic = widget.extractor!.getTopic(widget.topicId);
      if (topic != null) {
        final assistantId = topic['assistantId'] as String?;
        final assistant = assistantId != null
            ? widget.extractor!.getAssistantById(assistantId)
            : null;
        final assistantName = assistant?['name'] as String? ?? '未知助手';
        print('║ Assistant:   $assistantName (ID: $assistantId)');
      }
    }

    // 统计信息
    if (_conversation != null) {
      final messages = _conversation!['messages'] as List<dynamic>? ?? [];
      final groups = _getConversationGroups();

      // 统计用户消息和助手消息
      int userMsgCount = 0;
      int assistantMsgCount = 0;
      final modelNames = <String>{};

      for (final msg in messages) {
        if (msg is! Map<String, dynamic>) continue;
        final role = msg['role'] as String?;
        if (role == 'user') {
          userMsgCount++;
        } else if (role == 'assistant') {
          assistantMsgCount++;
          final model = msg['model'] as Map<String, dynamic>?;
          final modelName = model?['name'] as String?;
          if (modelName != null) modelNames.add(modelName);
        }
      }

      print(
        '╠══════════════════════════════════════════════════════════════════╣',
      );
      print('║ 📊 统计信息:');
      print('║   - 对话轮数:     ${groups.length} 轮');
      print('║   - 总消息数:     ${messages.length} 条');
      print('║   - 用户消息:     $userMsgCount 条');
      print('║   - 助手回复:     $assistantMsgCount 条');
      print('║   - 使用的模型:   ${modelNames.join(', ')}');

      // 打印每轮的详细信息
      print(
        '╠══════════════════════════════════════════════════════════════════╣',
      );
      print('║ 📝 各轮详情:');
      for (var i = 0; i < groups.length && i < 5; i++) {
        final group = groups[i];
        final userMsg = group['user_message'] as Map<String, dynamic>;
        final replies = group['assistant_replies'] as List<dynamic>;

        // 提取用户问题的前50个字符
        final blocks = userMsg['blocks'] as List<dynamic>? ?? [];
        String userText = '';
        for (final block in blocks) {
          if (block is Map<String, dynamic> && block['type'] == 'main_text') {
            userText += block['content'] as String? ?? '';
          }
        }
        final preview = userText.length > 50
            ? '${userText.substring(0, 50)}...'
            : userText;

        print('║   [第${i + 1}轮] ${replies.length}个回复 | Q: $preview');
      }
      if (groups.length > 5) {
        print('║   ... 还有 ${groups.length - 5} 轮');
      }
    }

    print(
      '╚══════════════════════════════════════════════════════════════════╝',
    );
    print('\n');
  }

  /// 获取对话分组（按 askId 和 useful 字段分组）
  ///
  /// 【性能优化】使用缓存避免重复计算
  List<Map<String, dynamic>> _getConversationGroups() {
    // 检查缓存
    if (_cachedGroups != null) {
      return _cachedGroups!;
    }

    if (_conversation == null) {
      return [];
    }

    final messages = _conversation!['messages'] as List<dynamic>;

    final groups = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentGroup;

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg is! Map<String, dynamic>) continue;

      final role = msg['role'] as String?;

      if (role == 'user') {
        // 新的用户消息 -> 新分组
        if (currentGroup != null) {
          groups.add(currentGroup);
        }
        currentGroup = {
          'user_message': msg,
          'assistant_replies': <Map<String, dynamic>>[],
        };
      } else if (role == 'assistant' && currentGroup != null) {
        // 助手回复 -> 添加到当前分组
        (currentGroup['assistant_replies'] as List).add(msg);
      }
    }

    if (currentGroup != null) {
      groups.add(currentGroup);
    }

    // 缓存结果
    _cachedGroups = groups;

    return groups;
  }

  /// 构建普通 AppBar
  AppBar _buildNormalAppBar() {
    final hasDrawer = widget.onOpenDrawer != null;
    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: !hasDrawer,
      leading: hasDrawer
          ? IconButton(
              icon: const Icon(Icons.menu),
              tooltip: '打开列表',
              onPressed: widget.onOpenDrawer,
            )
          : null,
      title: GestureDetector(
        onTap: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
        },
        child: Text(widget.topicName),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.map_rounded),
          tooltip: '迷你地图',
          onPressed: _conversation == null ? null : _showRoundPicker,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildNormalAppBar(),
      body: Column(
        children: [
          // 主体内容
          Expanded(
            child: _conversation == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      _buildConversation(),
                      // 能量条进度指示器
                      _buildEnergyBarIndicator(),
                      // Sticky 模型 Tab（滚动时显示在顶部）
                      _buildStickyModelTabs(),
                      // 浮动导航已融合到边缘抽屉
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: TtsMiniPlayer(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      // FAB 已移除，操作已融合到边缘抽屉
    );
  }

  String _extractRoundPreview(Map<String, dynamic> group) {
    final userMsg = group['user_message'] as Map<String, dynamic>?;
    final blocks = userMsg?['blocks'] as List<dynamic>? ?? [];
    final buffer = StringBuffer();
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        buffer.write(block['content'] as String? ?? '');
      }
    }
    final preview = buffer.toString().replaceAll('\n', ' ').trim();
    if (preview.isEmpty) return '无问题内容';
    const maxPreviewLength = 100;
    if (preview.length <= maxPreviewLength) return preview;
    return '${preview.substring(0, maxPreviewLength).trim()}...';
  }

  List<Map<String, dynamic>> _buildRoundMapCards(
    int groupIndex,
    Map<String, dynamic> group,
  ) {
    final cards = <Map<String, dynamic>>[];
    final assistantReplies = group['assistant_replies'] as List<dynamic>? ?? [];
    final aiAnalysisCount = _aiAnalyses[groupIndex]?.length ?? 0;

    for (var i = 0; i < aiAnalysisCount; i++) {
      cards.add({
        'cardIndex': i,
        'label': aiAnalysisCount > 1 ? '洞察 #${i + 1}' : '洞察',
        'color': const Color(0xFF10B981),
        'isMainline': false,
      });
    }

    final totalByModel = <String, int>{};
    for (final item in assistantReplies) {
      if (item is! Map<String, dynamic>) continue;
      final model = item['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Assistant';
      totalByModel[modelName] = (totalByModel[modelName] ?? 0) + 1;
    }

    final seenByModel = <String, int>{};
    for (var i = 0; i < assistantReplies.length; i++) {
      final reply = assistantReplies[i];
      if (reply is! Map<String, dynamic>) continue;
      final model = reply['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Assistant';
      final seen = (seenByModel[modelName] ?? 0) + 1;
      seenByModel[modelName] = seen;
      final showOrder = (totalByModel[modelName] ?? 0) > 1;

      cards.add({
        'cardIndex': aiAnalysisCount + i,
        'label': showOrder ? '$modelName #$seen' : modelName,
        'color': _getModelColor(modelName),
        'isMainline': reply['useful'] as bool? ?? false,
      });
    }

    return cards;
  }

  Future<void> _jumpToRoundTarget(int groupIndex, {int? cardIndex}) async {
    await _scrollToGroup(groupIndex);
    if (!mounted || cardIndex == null || cardIndex < 0) return;

    final pageNotifier = _getCardPageNotifier(groupIndex);
    pageNotifier.value = cardIndex;

    final pageController = _pageControllers[groupIndex];
    if (pageController != null && pageController.hasClients) {
      pageController.jumpToPage(cardIndex);
    }

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (mounted) {
      _scrollToTabTop(groupIndex);
    }
  }

  /// 显示轮次迷你地图（二级导航：轮次 + 模型回复）
  void _showRoundPicker() {
    // 避免底部弹层打开时残留焦点导致系统键盘自动弹出
    FocusManager.instance.primaryFocus?.unfocus();

    final groups = _getConversationGroups();
    if (groups.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentGroupIndex = _currentVisibleGroupNotifier.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '迷你地图',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentGroupIndex + 1} / ${groups.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final queryPreview = _extractRoundPreview(group);
                    final mapCards = _buildRoundMapCards(index, group);
                    final isCurrentRound = index == currentGroupIndex;
                    final currentCardIndex =
                        _cardPageNotifiers[index]?.value ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isCurrentRound
                            ? const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: isDark ? 0.14 : 0.08)
                            : (isDark
                                  ? const Color(0xFF252525)
                                  : const Color(0xFFF7F7FA)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrentRound
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.45)
                              : (isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                unawaited(_jumpToRoundTarget(index));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Q',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.grey[900],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        queryPreview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (mapCards.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: mapCards.map((card) {
                                  final cardIndex = card['cardIndex'] as int;
                                  final label = card['label'] as String;
                                  final chipColor = card['color'] as Color;
                                  final isMainline =
                                      card['isMainline'] as bool? ?? false;
                                  final isSelected =
                                      isCurrentRound &&
                                      currentCardIndex == cardIndex;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      unawaited(
                                        _jumpToRoundTarget(
                                          index,
                                          cardIndex: cardIndex,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? chipColor.withValues(
                                                alpha: isDark ? 0.30 : 0.18,
                                              )
                                            : chipColor.withValues(
                                                alpha: isDark ? 0.16 : 0.10,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? chipColor
                                              : chipColor.withValues(
                                                  alpha: 0.5,
                                                ),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 7,
                                            color: chipColor,
                                          ),
                                          const SizedBox(width: 6),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 160,
                                            ),
                                            child: Text(
                                              label,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isDark
                                                    ? Colors.grey[100]
                                                    : Colors.grey[900],
                                              ),
                                            ),
                                          ),
                                          if (isMainline) ...[
                                            const SizedBox(width: 5),
                                            const Icon(
                                              Icons.star,
                                              size: 11,
                                              color: Color(0xFFFFB800),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(sheetContext).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  /// 能量条进度指示器（轮次格子，渐进填充）
  /// 【性能优化】使用 ValueListenableBuilder，只重建能量条本身
  Widget _buildEnergyBarIndicator() {
    final groups = _getConversationGroups();
    final totalGroups = groups.length;
    if (totalGroups <= 1) return const SizedBox.shrink();

    return Positioned(
      right: 0,
      top: 0,
      bottom: 80,
      child: SafeArea(
        child: _EnergyBarWidget(
          totalGroups: totalGroups,
          visibleGroupNotifier: _currentVisibleGroupNotifier,
          progressNotifier: _currentGroupProgressNotifier,
          onTapGroup: _scrollToGroup,
        ),
      ),
    );
  }

  Widget _buildConversation() {
    final groups = _getConversationGroups();

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 16,
          bottom: 80,
        ),
        // cacheExtent: 提前渲染视口外的内容，确保滚动流畅
        cacheExtent: 800,
        itemCount: groups.length,
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          // 使用 AutoScrollTag 包装，支持 scrollToIndex
          return AutoScrollTag(
            key: ValueKey(index),
            controller: _scrollController,
            index: index,
            // 【性能优化】移除 KeepAliveWrapper，减少内存占用
            // cacheExtent 已增加到 800，滚动体验不受影响
            child: RepaintBoundary(
              child: _buildConversationGroup(groups[index], index),
            ),
          );
        },
      ),
    );
  }

  /// 构建 Sticky 模型 Tab（只在内联 Tab 滚出屏幕时显示）
  /// 【性能优化】使用 ValueListenableBuilder 避免整页重建
  Widget _buildStickyModelTabs() {
    return ValueListenableBuilder<bool>(
      valueListenable: _currentGroupTabVisibleNotifier,
      builder: (context, tabVisible, _) {
        // 如果当前轮次的内联 tab 还在屏幕内，不显示 sticky
        if (tabVisible) return const SizedBox.shrink();

        return ValueListenableBuilder<int>(
          valueListenable: _currentVisibleGroupNotifier,
          builder: (context, currentVisibleGroup, _) {
            final groups = _getConversationGroups();
            if (groups.isEmpty) return const SizedBox.shrink();

            final currentGroup = groups[currentVisibleGroup];
            final assistantReplies =
                currentGroup['assistant_replies'] as List<dynamic>;

            // 如果只有一个回复，不显示 Tab
            final aiAnalysisCount =
                _aiAnalyses[currentVisibleGroup]?.length ?? 0;
            final totalCards = aiAnalysisCount + assistantReplies.length;
            if (totalCards <= 1) return const SizedBox.shrink();

            final isDark = Theme.of(context).brightness == Brightness.dark;

            // 构建卡片信息
            final cardInfoList = <Map<String, dynamic>>[];
            for (var i = 0; i < aiAnalysisCount; i++) {
              cardInfoList.add({
                'type': 'analysis',
                'name': 'AI 分析 ${i + 1}',
                'index': i,
              });
            }
            for (var i = 0; i < assistantReplies.length; i++) {
              final reply = assistantReplies[i] as Map<String, dynamic>;
              final model = reply['model'] as Map<String, dynamic>?;
              final modelName = model?['name'] as String? ?? 'Assistant';
              final isMainline = reply['useful'] as bool? ?? false;
              cardInfoList.add({
                'type': 'assistant',
                'name': modelName,
                'index': aiAnalysisCount + i,
                'data': reply,
                'isMainline': isMainline,
              });
            }

            // 【性能优化】使用 ValueListenableBuilder 监听页码变化
            return ValueListenableBuilder<int>(
              valueListenable: _getCardPageNotifier(currentVisibleGroup),
              builder: (context, currentPage, _) {
                return Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.grey[900] : Colors.white)
                          ?.withValues(alpha: 0.98),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          // 轮次标识
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              'Q${currentVisibleGroup + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // 模型 Tab 列表 + 双击回到顶部
                          Expanded(
                            child: GestureDetector(
                              onDoubleTap: () {
                                // 【快速定位】双击 Tab 区域（包括空白）滚动到本轮次顶部
                                _scrollToGroupTop(currentVisibleGroup);
                              },
                              behavior: HitTestBehavior.translucent,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: cardInfoList.asMap().entries.map((
                                    entry,
                                  ) {
                                    final cardIndex = entry.key;
                                    final info = entry.value;
                                    final isSelected = cardIndex == currentPage;
                                    final isMainline =
                                        info['isMainline'] as bool? ?? false;

                                    return _AnimatedModelTab(
                                      modelName: info['name'] as String,
                                      isSelected: isSelected,
                                      isAnalysis: info['type'] == 'analysis',
                                      isDark: isDark,
                                      modelColor: info['type'] == 'analysis'
                                          ? const Color(0xFF10B981)
                                          : _getModelColor(
                                              info['name'] as String,
                                            ),
                                      isMainline: isMainline,
                                      onTap: () {
                                        // 【性能优化】直接更新 ValueNotifier，不触发整页 setState
                                        _getCardPageNotifier(
                                          currentVisibleGroup,
                                        ).value = cardIndex;
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildConversationGroup(Map<String, dynamic> group, int groupIndex) {
    return _buildCleanLayout(group, groupIndex);
  }

  /// 简洁整合布局 - 问答分区设计
  /// 特点：左侧色条区分问答 + 问题区域深色背景 + 回答区域浅色
  Widget _buildCleanLayout(Map<String, dynamic> group, int groupIndex) {
    final userMsg = group['user_message'] as Map<String, dynamic>;
    final assistantReplies = group['assistant_replies'] as List<dynamic>;

    final aiAnalysisCount = _aiAnalyses[groupIndex]?.length ?? 0;
    final totalCards = aiAnalysisCount + assistantReplies.length;
    final isSingleCard = totalCards == 1 && aiAnalysisCount == 0;

    // 提取用户消息文本
    final blocks = userMsg['blocks'] as List<dynamic>? ?? [];
    String userText = '';
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        userText += block['content'] as String? ?? '';
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const questionColor = Color(0xFF6366F1); // 紫色 - 问题

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== 问题区域 ==========
            // 【性能优化】使用 Stack 替代 IntrinsicHeight，避免双重布局
            Stack(
              children: [
                // 内容区域（决定高度）
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 4), // 为左侧色条留出空间
                  decoration: BoxDecoration(
                    color: isDark
                        ? questionColor.withValues(alpha: 0.08)
                        : questionColor.withValues(alpha: 0.03),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Q标记
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: questionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Q${groupIndex + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: questionColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      // 用户问题内容
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: _buildUserContent(userText),
                      ),
                    ],
                  ),
                ),
                // 左侧紫色色条（使用 Positioned.fill 自动匹配高度）
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: questionColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ========== 回答区域 ==========
            if (assistantReplies.isNotEmpty)
              _buildCleanReplyContent(
                groupIndex,
                assistantReplies,
                isSingleCard,
              ),
          ],
        ),
      ),
    );
  }

  /// 简洁布局：用户内容区域（双击展开收起）
  Widget _buildUserContent(String userText) {
    // 【统一】与 HighlightableCard 保持一致的折叠阈值
    const collapseThreshold = 1000;
    const collapsedPreviewLength = 500;
    final isLong = userText.length > collapseThreshold;
    final displayText = isLong
        ? '${userText.substring(0, collapsedPreviewLength)}...'
        : userText;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _UserContentWidget(
      userText: userText,
      displayText: displayText,
      isLong: isLong,
      isDark: isDark,
    );
  }

  /// 简洁布局：操作按钮（更紧凑）
  Widget _buildCleanActionButtons(int groupIndex) {
    return const SizedBox.shrink();
  }

  /// 简洁布局：回复内容区域（流式布局）
  /// 【性能优化】使用 ValueListenableBuilder 避免整页重建
  Widget _buildCleanReplyContent(
    int groupIndex,
    List<dynamic> assistantReplies,
    bool isSingleCard,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 单回复模式 - 直接展示，但仍保留轮次级别操作按钮
    if (isSingleCard) {
      final reply = assistantReplies.first as Map<String, dynamic>;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 操作按钮区域（与多回复模式保持一致）
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: Row(
              children: [const Spacer(), _buildCleanActionButtons(groupIndex)],
            ),
          ),
          // 回复内容
          _buildStreamReplyItem(
            reply: reply,
            groupIndex: groupIndex,
            isDark: isDark,
            showDivider: false,
          ),
        ],
      );
    }

    final aiAnalysisCount = _aiAnalyses[groupIndex]?.length ?? 0;

    // 构建所有卡片信息列表
    final cardInfoList = <Map<String, dynamic>>[];

    for (var i = 0; i < aiAnalysisCount; i++) {
      cardInfoList.add({
        'type': 'analysis',
        'name': 'AI 分析 ${i + 1}',
        'index': i,
      });
    }

    for (var i = 0; i < assistantReplies.length; i++) {
      final reply = assistantReplies[i] as Map<String, dynamic>;
      final model = reply['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Assistant';
      final isMainline = reply['useful'] as bool? ?? false;
      final msgId = reply['id'];
      if (kDebugMode && groupIndex < 2) {
        // Log first few groups
        print('DEBUG: Group $groupIndex Reply $i ($modelName): ID="$msgId"');
      }
      cardInfoList.add({
        'type': 'assistant',
        'name': modelName,
        'index': aiAnalysisCount + i,
        'data': reply,
        'isMainline': isMainline,
      });
    }

    // 获取页码 ValueNotifier
    final pageNotifier = _getCardPageNotifier(groupIndex);

    // 获取或创建 PageController
    if (!_pageControllers.containsKey(groupIndex)) {
      _pageControllers[groupIndex] = PageController(
        initialPage: pageNotifier.value,
      );
    }
    final pageController = _pageControllers[groupIndex]!;

    // 【性能优化】使用 ValueListenableBuilder 包裹整个多回复区域
    return ValueListenableBuilder<int>(
      valueListenable: pageNotifier,
      builder: (context, currentPage, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部：模型选择器（简洁线条风格）
            _buildStreamModelSelector(
              cardInfoList: cardInfoList,
              currentPage: currentPage,
              groupIndex: groupIndex,
              isDark: isDark,
              pageController: pageController,
              pageNotifier: pageNotifier,
            ),

            // 内容区域
            _buildPageViewReplyArea(
              cardInfoList: cardInfoList,
              groupIndex: groupIndex,
              assistantReplies: assistantReplies,
              isDark: isDark,
              pageController: pageController,
              currentPage: currentPage,
              pageNotifier: pageNotifier,
            ),
          ],
        );
      },
    );
  }

  /// 流式布局：模型选择器（带动画效果）
  /// 【性能优化】接收 pageNotifier 直接更新，避免 setState
  Widget _buildStreamModelSelector({
    required List<Map<String, dynamic>> cardInfoList,
    required int currentPage,
    required int groupIndex,
    required bool isDark,
    required PageController pageController,
    required ValueNotifier<int> pageNotifier,
  }) {
    // 获取或创建内联 tab 的 GlobalKey（用于位置追踪）
    _inlineTabKeys[groupIndex] ??= GlobalKey();

    // 获取或创建 Tab ScrollController
    if (!_tabScrollControllers.containsKey(groupIndex)) {
      _tabScrollControllers[groupIndex] = ScrollController();
    }
    final tabScrollController = _tabScrollControllers[groupIndex]!;

    // 【性能优化】只在页码变化时才注册 postFrameCallback，避免重复
    if (_lastProcessedTabPage[groupIndex] != currentPage) {
      _lastProcessedTabPage[groupIndex] = currentPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollTabToVisible(groupIndex, currentPage, tabScrollController);
        }
      });
    }

    return Padding(
      key: _inlineTabKeys[groupIndex], // 追踪这个区域的位置
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Row(
        children: [
          // 模型选择器（横向滚动）+ 双击回到顶部
          Expanded(
            child: GestureDetector(
              onDoubleTap: () {
                // 【快速定位】双击 Tab 区域（包括空白）滚动到本轮次顶部
                _scrollToGroupTop(groupIndex);
              },
              behavior: HitTestBehavior.translucent,
              child: SingleChildScrollView(
                controller: tabScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: cardInfoList.asMap().entries.map((entry) {
                    final cardIndex = entry.key;
                    final info = entry.value;
                    final isSelected = cardIndex == currentPage;
                    final tabKey = 'tab_${groupIndex}_$cardIndex';
                    final isMainline = info['isMainline'] as bool? ?? false;

                    // 确保每个 Tab 有唯一的 GlobalKey
                    _tabKeys[tabKey] ??= GlobalKey();

                    return _AnimatedModelTab(
                      key: _tabKeys[tabKey],
                      modelName: info['name'] as String,
                      isSelected: isSelected,
                      isAnalysis: info['type'] == 'analysis',
                      isDark: isDark,
                      modelColor: info['type'] == 'analysis'
                          ? const Color(0xFF10B981)
                          : _getModelColor(info['name'] as String),
                      isMainline: isMainline,
                      onTap: () {
                        // 【性能优化】直接更新 ValueNotifier，不触发整页 setState
                        pageNotifier.value = cardIndex;
                        // 【UX优化】切换模型回复后滚动到 Tab 栏顶部，直接看到回复内容
                        _scrollToTabTop(groupIndex);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // 操作按钮
          _buildCleanActionButtons(groupIndex),
        ],
      ),
    );
  }

  /// 滚动 Tab 到可见区域
  void _scrollTabToVisible(
    int groupIndex,
    int tabIndex,
    ScrollController controller,
  ) {
    if (!controller.hasClients) return;

    final tabKey = 'tab_${groupIndex}_$tabIndex';
    final key = _tabKeys[tabKey];
    if (key?.currentContext == null) return;

    final RenderBox? tabBox =
        key!.currentContext!.findRenderObject() as RenderBox?;
    if (tabBox == null) return;

    final tabPosition = tabBox.localToGlobal(Offset.zero);
    final tabWidth = tabBox.size.width;

    // 获取 ScrollView 的 RenderBox
    final scrollContext = controller.position.context.storageContext;
    final RenderBox? scrollBox = scrollContext.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    final scrollPosition = scrollBox.localToGlobal(Offset.zero);
    final scrollWidth = scrollBox.size.width;

    // 计算 Tab 相对于 ScrollView 的位置
    final relativePosition =
        tabPosition.dx - scrollPosition.dx + controller.offset;

    // 判断是否需要滚动
    final viewportStart = controller.offset;
    final viewportEnd = controller.offset + scrollWidth;

    double targetOffset = controller.offset;

    if (relativePosition < viewportStart + 20) {
      // Tab 在左边界外，滚动到左边
      targetOffset = relativePosition - 20;
    } else if (relativePosition + tabWidth > viewportEnd - 20) {
      // Tab 在右边界外，滚动到右边
      targetOffset = relativePosition + tabWidth - scrollWidth + 20;
    }

    // 限制滚动范围
    targetOffset = targetOffset.clamp(
      controller.position.minScrollExtent,
      controller.position.maxScrollExtent,
    );

    if ((targetOffset - controller.offset).abs() > 1) {
      controller.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// 完全展开的回复内容区域（支持左右滑动切换）
  /// 【性能优化】接收 pageNotifier 直接更新，避免 setState
  Widget _buildPageViewReplyArea({
    required List<Map<String, dynamic>> cardInfoList,
    required int groupIndex,
    required List<dynamic> assistantReplies,
    required bool isDark,
    required PageController pageController,
    required int currentPage,
    required ValueNotifier<int> pageNotifier,
  }) {
    final totalPages = cardInfoList.length;

    if (totalPages <= 1) {
      // 只有一个卡片，直接显示
      return _buildExpandedContent(
        key: ValueKey('${groupIndex}_0'),
        cardInfoList: cardInfoList,
        index: 0,
        groupIndex: groupIndex,
        isDark: isDark,
      );
    }

    return Column(
      children: [
        // 内容区域 - 滑动切换（自然高度）
        _SwipeableSwitcher(
          currentIndex: currentPage,
          totalCount: totalPages,
          onIndexChanged: (newIndex) {
            // 【性能优化】直接更新 ValueNotifier，不触发整页 setState
            pageNotifier.value = newIndex;
            // 【修复】切换后等待布局完成，重新计算进度条
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onScrollChanged();
              // 【Tab联动】强制滚动 Tab 到可见区域
              final tabController = _tabScrollControllers[groupIndex];
              if (tabController != null) {
                _scrollTabToVisible(groupIndex, newIndex, tabController);
              }
            });
            // 【UX优化】切换模型回复后滚动到 Tab 栏顶部，直接看到回复内容
            _scrollToTabTop(groupIndex);
          },
          // 【快速定位】双击功能已移除，以避免与文本选择冲突
          // onDoubleTap: () {
          //   _scrollToGroupTop(groupIndex);
          // },
          itemBuilder: (index) => _buildExpandedContent(
            key: ValueKey('${groupIndex}_$index'),
            cardInfoList: cardInfoList,
            index: index,
            groupIndex: groupIndex,
            isDark: isDark,
          ),
        ),

        // 页面指示器
        _buildPageIndicator(
          totalPages: totalPages,
          currentPage: currentPage,
          cardInfoList: cardInfoList,
          isDark: isDark,
        ),
      ],
    );
  }

  /// 构建完全展开的内容（无高度限制）
  Widget _buildExpandedContent({
    required Key key,
    required List<Map<String, dynamic>> cardInfoList,
    required int index,
    required int groupIndex,
    required bool isDark,
  }) {
    final info = cardInfoList[index];
    final isAnalysis = info['type'] == 'analysis';

    if (isAnalysis) {
      final analysisIndex = info['index'] as int;
      final analyses = _aiAnalyses[groupIndex] ?? [];
      if (analysisIndex >= analyses.length) return const SizedBox.shrink();

      return KeyedSubtree(
        key: key,
        child: _buildStreamAnalysisItem(
          content: analyses[analysisIndex],
          groupIndex: groupIndex,
          analysisIndex: analysisIndex,
          isDark: isDark,
        ),
      );
    } else {
      final reply = info['data'] as Map<String, dynamic>;
      return KeyedSubtree(
        key: key,
        child: _buildStreamReplyItem(
          reply: reply,
          groupIndex: groupIndex,
          isDark: isDark,
          showDivider: false,
        ),
      );
    }
  }

  /// 页面指示器
  Widget _buildPageIndicator({
    required int totalPages,
    required int currentPage,
    required List<Map<String, dynamic>> cardInfoList,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final isActive = index == currentPage;
          final info = cardInfoList[index];
          final isAnalysis = info['type'] == 'analysis';
          final color = isAnalysis
              ? const Color(0xFF10B981)
              : _getModelColor(info['name'] as String);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? color : color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  /// 流式布局：单条回复
  Widget _buildStreamReplyItem({
    required Map<String, dynamic> reply,
    required int groupIndex,
    required bool isDark,
    bool showDivider = true,
  }) {
    final model = reply['model'] as Map<String, dynamic>?;
    final modelName = model?['name'] as String? ?? 'Assistant';
    final messageId = reply['id'] as String? ?? '';
    final modelColor = _getModelColor(modelName);

    // 提取内容（包含多种可显示的块类型）
    // 按照 block 在列表中的顺序拼接
    final blocks = reply['blocks'] as List<dynamic>? ?? [];
    String content = '';
    final contentTypes = [
      'main_text',
      'thinking',
      'translation',
      'code',
      'error',
      'text',
    ];
    for (final block in blocks) {
      if (block is Map<String, dynamic> &&
          contentTypes.contains(block['type'])) {
        content += block['content'] as String? ?? '';
      }
    }

    return Container(
      color: modelColor.withValues(alpha: isDark ? 0.04 : 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 【性能优化】使用 Selector 只监听 hasValidConfig，避免 TTS 状态变化时重建整个卡片
          Selector<TtsProvider, bool>(
            selector: (_, tts) => tts.hasValidConfig,
            builder: (context, hasValidConfig, _) {
              return HighlightableCard.assistant(
                key: ValueKey(messageId),
                data: reply,
                streamLayout: true,
                maxHeight: null, // 自然撑开
                topicId: widget.topicId, // 【修复】传递 topicId
                contextData: {
                  'topicName': widget.topicName, // 【修复】传递 topicName，解决"未知对话"问题
                },
                actionBar: MessageActionBar(
                  content: content,
                  messageId: messageId,
                  modelName: modelName,
                  onRegenerate: null, // TODO: 实现重新生成
                  showRegenerate: false, // 查看模式暂不支持重新生成
                  showSpeak: hasValidConfig,
                  onSpeak: () => _speakContent(content, modelName),
                ),
                roundIndex: groupIndex,
                // 使用外部传入的关键词高亮
                searchKeyword: widget.highlightKeyword,
                // 【精确定位】传递目标高亮 ID，用于闪烁提示
                targetHighlightId: _targetHighlightId,
              );
            },
          ),
          if (showDivider)
            Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
        ],
      ),
    );
  }

  /// 流式布局：AI 分析内容
  Widget _buildStreamAnalysisItem({
    required String content,
    required int groupIndex,
    required int analysisIndex,
    required bool isDark,
  }) {
    const analysisColor = Color(0xFF10B981);

    return Container(
      color: analysisColor.withValues(alpha: isDark ? 0.04 : 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighlightableCard.aiAnalysis(
            key: ValueKey('ai_${groupIndex}_$analysisIndex'),
            content: content,
          ),
          // 操作栏 - 【性能优化】使用 Selector 只监听 hasValidConfig
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Selector<TtsProvider, bool>(
              selector: (_, tts) => tts.hasValidConfig,
              builder: (context, hasValidConfig, _) {
                return MessageActionBar(
                  content: content,
                  messageId: 'ai_${groupIndex}_$analysisIndex',
                  modelName: 'AI 分析',
                  showRegenerate: false,
                  showSpeak: hasValidConfig,
                  onSpeak: () => _speakContent(content, 'AI 分析'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 朗读内容
  void _speakContent(String content, String title) {
    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    final item = TtsItem(
      id: 'tts_${content.hashCode}',
      text: content,
      title: title,
      author: title,
    );
    ttsProvider.setPlaylist([item]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开始朗读...'), duration: Duration(seconds: 1)),
    );
  }

  /// 获取模型颜色
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

/// 独立的用户内容 Widget（保持状态，用于双击展开）
class _UserContentWidget extends StatefulWidget {
  final String userText;
  final String displayText;
  final bool isLong;
  final bool isDark;

  const _UserContentWidget({
    required this.userText,
    required this.displayText,
    required this.isLong,
    required this.isDark,
  });

  @override
  State<_UserContentWidget> createState() => _UserContentWidgetState();
}

class _UserContentWidgetState extends State<_UserContentWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.isLong
          ? () => setState(() => _expanded = !_expanded)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _expanded ? widget.userText : widget.displayText,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: widget.isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          if (widget.isLong)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _expanded ? Icons.unfold_less : Icons.unfold_more,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expanded ? '双击收起' : '双击展开全文',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  if (!_expanded) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? Colors.grey[700]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.userText.length} 字',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 带动画效果的模型 Tab（缩放 + 底部指示条）
class _AnimatedModelTab extends StatelessWidget {
  final String modelName;
  final bool isSelected;
  final bool isAnalysis;
  final bool isDark;
  final Color modelColor;
  final bool isMainline;
  final VoidCallback? onTap;

  const _AnimatedModelTab({
    super.key,
    required this.modelName,
    required this.isSelected,
    required this.isAnalysis,
    required this.isDark,
    required this.modelColor,
    this.isMainline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文字（选中时稍微放大）+ 主线标记
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: isSelected ? 15 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? modelColor
                        : (isDark ? Colors.grey[500] : Colors.grey[600]),
                  ),
                  child: Text(modelName),
                ),
                // 主线标记：金色星号
                if (isMainline) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.star,
                    size: 12,
                    color: isSelected
                        ? const Color(0xFFFFB800)
                        : (isDark
                              ? const Color(0xFFB8860B)
                              : const Color(0xFFDAA520)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // 底部指示条
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 3,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: modelColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 滑动切换器（简洁版：直接切换内容）
/// 【性能优化】使用 ValueNotifier 避免拖动时整个组件重建
class _SwipeableSwitcher extends StatefulWidget {
  final int currentIndex;
  final int totalCount;
  final ValueChanged<int> onIndexChanged;
  final Widget Function(int index) itemBuilder;

  const _SwipeableSwitcher({
    required this.currentIndex,
    required this.totalCount,
    required this.onIndexChanged,
    required this.itemBuilder,
  });

  @override
  State<_SwipeableSwitcher> createState() => _SwipeableSwitcherState();
}

class _SwipeableSwitcherState extends State<_SwipeableSwitcher> {
  // 【性能优化】使用 ValueNotifier 替代 setState，拖动时只重绘必要部分
  final ValueNotifier<double> _dragOffsetNotifier = ValueNotifier(0);
  bool _isDragging = false;

  // 【性能优化】内容缓存，避免切换时重复构建 Widget
  final Map<int, Widget> _contentCache = {};

  // 获取或构建缓存内容
  Widget _getOrBuildContent(int index) {
    if (index < 0 || index >= widget.totalCount) {
      return const SizedBox.shrink();
    }
    if (!_contentCache.containsKey(index)) {
      _contentCache[index] = widget.itemBuilder(index);
    }
    return _contentCache[index]!;
  }

  @override
  void didUpdateWidget(_SwipeableSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 【修复】父组件重绘时（可能因为数据更新），必须清理缓存
    // 否则 item builder 闭包可能捕获旧数据，导致显示陈旧内容
    if (widget.itemBuilder != oldWidget.itemBuilder ||
        widget.currentIndex != oldWidget.currentIndex) {
      _contentCache.clear();
    } else {
      // 常规清理
      _contentCache.removeWhere(
        (key, _) => (key - widget.currentIndex).abs() > 1,
      );
    }
  }

  @override
  void dispose() {
    _contentCache.clear();
    _dragOffsetNotifier.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _dragOffsetNotifier.value = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final maxDrag = MediaQuery.of(context).size.width * 0.4;
    _dragOffsetNotifier.value = (_dragOffsetNotifier.value + details.delta.dx)
        .clamp(-maxDrag, maxDrag);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    final threshold = MediaQuery.of(context).size.width * 0.15;
    final dragOffset = _dragOffsetNotifier.value;

    int targetIndex = widget.currentIndex;

    if (velocity < -500 || (dragOffset < -threshold && velocity <= 0)) {
      if (widget.currentIndex < widget.totalCount - 1) {
        targetIndex = widget.currentIndex + 1;
      }
    } else if (velocity > 500 || (dragOffset > threshold && velocity >= 0)) {
      if (widget.currentIndex > 0) {
        targetIndex = widget.currentIndex - 1;
      }
    }

    _dragOffsetNotifier.value = 0;

    if (targetIndex != widget.currentIndex) {
      widget.onIndexChanged(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = widget.currentIndex < widget.totalCount - 1;
    final hasPrev = widget.currentIndex > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 【性能优化】使用缓存获取内容，避免重复构建
    final contentWidget = _getOrBuildContent(widget.currentIndex);

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // 【性能优化】内容区域使用 ValueListenableBuilder，只有 Transform 会重建
          ValueListenableBuilder<double>(
            valueListenable: _dragOffsetNotifier,
            builder: (context, dragOffset, child) {
              return Transform.translate(
                offset: Offset(dragOffset * 0.25, 0),
                child: child,
              );
            },
            child: contentWidget, // child 参数不会随 dragOffset 变化而重建
          ),

          // 右侧暗示（使用 ValueListenableBuilder 优化）
          if (hasNext)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _dragOffsetNotifier,
                builder: (context, dragOffset, _) {
                  return _buildEdgeHint(
                    isRight: true,
                    isDark: isDark,
                    dragProgress: dragOffset < 0
                        ? (-dragOffset / 80).clamp(0.0, 1.0)
                        : 0.0,
                  );
                },
              ),
            ),

          // 左侧暗示（使用 ValueListenableBuilder 优化）
          if (hasPrev)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _dragOffsetNotifier,
                builder: (context, dragOffset, _) {
                  return _buildEdgeHint(
                    isRight: false,
                    isDark: isDark,
                    dragProgress: dragOffset > 0
                        ? (dragOffset / 80).clamp(0.0, 1.0)
                        : 0.0,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEdgeHint({
    required bool isRight,
    required bool isDark,
    required double dragProgress,
  }) {
    final baseOpacity = 0.4 + dragProgress * 0.5;

    return IgnorePointer(
      child: Container(
        width: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isRight ? Alignment.centerLeft : Alignment.centerRight,
            end: isRight ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              Colors.transparent,
              (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.06 * baseOpacity,
              ),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            isRight ? Icons.chevron_right : Icons.chevron_left,
            size: 24,
            color: (isDark ? Colors.grey[400] : Colors.grey[400])?.withValues(
              alpha: baseOpacity,
            ),
          ),
        ),
      ),
    );
  }
}

/// 能量条组件（独立 Widget，通过 ValueListenableBuilder 更新）
/// 【性能优化】滚动时只重建这个组件，不触发整个页面重建
class _EnergyBarWidget extends StatelessWidget {
  final int totalGroups;
  final ValueNotifier<int> visibleGroupNotifier;
  final ValueNotifier<double> progressNotifier;
  final void Function(int) onTapGroup;

  const _EnergyBarWidget({
    required this.totalGroups,
    required this.visibleGroupNotifier,
    required this.progressNotifier,
    required this.onTapGroup,
  });

  static const _cellColors = [
    Color(0xFF60A5FA), // 蓝
    Color(0xFF34D399), // 绿
    Color(0xFFFBBF24), // 黄
    Color(0xFFF87171), // 红
    Color(0xFFA78BFA), // 紫
    Color(0xFF2DD4BF), // 青
    Color(0xFFFB923C), // 橙
    Color(0xFFE879F9), // 粉
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final cellHeight = availableHeight / totalGroups;

        // 监听两个 ValueNotifier
        return ValueListenableBuilder<int>(
          valueListenable: visibleGroupNotifier,
          builder: (context, visibleGroup, _) {
            return ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, _) {
                return SizedBox(
                  width: 6,
                  height: availableHeight,
                  child: Column(
                    children: List.generate(totalGroups, (index) {
                      final color = _cellColors[index % _cellColors.length];
                      final emptyColor = color.withValues(
                        alpha: isDark ? 0.2 : 0.25,
                      );

                      // 计算每个格子的填充比例
                      double fillRatio;
                      if (index < visibleGroup) {
                        fillRatio = 1.0;
                      } else if (index == visibleGroup) {
                        fillRatio = progress;
                      } else {
                        fillRatio = 0.0;
                      }

                      return GestureDetector(
                        onTap: () => onTapGroup(index),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 6,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: index < totalGroups - 1
                                  ? BorderSide(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      width: 1,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // 空背景
                              Positioned.fill(
                                child: ColoredBox(color: emptyColor),
                              ),
                              // 填充部分（从顶部向下填充）
                              if (fillRatio > 0)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: ColoredBox(
                                    color: color,
                                    child: SizedBox(
                                      height: (cellHeight - 1) * fillRatio,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
