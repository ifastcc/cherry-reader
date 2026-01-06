import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:async';
import '../services/cherry_extractor.dart';
import '../services/analysis_cache_manager.dart';
import '../services/highlight_service.dart';
import '../services/unified_conversation_service.dart';
import '../services/topic_service.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../widgets/highlightable_card.dart';
import '../widgets/message_action_bar.dart';
import '../services/epub_export_service.dart';
import 'ai_chat_screen.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../models/tts_item.dart';
import '../widgets/tts_mini_player.dart';
import '../widgets/dual_fab.dart';
import '../widgets/keep_alive_wrapper.dart';

/// 页内搜索匹配结果
class InPageSearchMatch {
  /// 轮次索引 (0-based)
  final int roundIndex;
  /// 回复索引（null 表示用户问题）
  final int? replyIndex;
  /// 类型：'query' 或 'reply'
  final String type;
  /// 匹配的内容预览
  final String preview;

  const InPageSearchMatch({
    required this.roundIndex,
    this.replyIndex,
    required this.type,
    required this.preview,
  });

  @override
  String toString() => 'Match(round: $roundIndex, reply: $replyIndex, type: $type)';
}

class ConversationScreen extends StatefulWidget {
  final CherryExtractor extractor;
  final String topicId;
  final String topicName;

  /// 【搜索定位】初始滚动到的轮次索引（从 0 开始）
  final int? scrollToRoundIndex;

  /// 【搜索高亮】要高亮的搜索关键词
  final String? highlightKeyword;

  const ConversationScreen({
    Key? key,
    required this.extractor,
    required this.topicId,
    required this.topicName,
    this.scrollToRoundIndex,
    this.highlightKeyword,
  }) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final AnalysisCacheManager _cacheManager;
  late final TopicService _topicService;

  Map<String, dynamic>? _conversation;
  // _cacheData 已移除，Isar 自动管理持久化
  Map<int, List<String>> _aiAnalyses = {};

  // 【性能优化】缓存对话分组结果
  List<Map<String, dynamic>>? _cachedGroups;

  // 【新增】消息讨论数量缓存（key: messageId 或 contextId）
  Map<String, int> _discussionCounts = {};

  final _epubExportService = EpubExportService();

  // 【轮次导航】使用 scroll_to_index 实现精确跳转
  late AutoScrollController _scrollController;

  // 【性能优化】使用 ValueNotifier 避免整个页面重建
  final ValueNotifier<int> _currentVisibleGroupNotifier = ValueNotifier(0);
  final ValueNotifier<double> _currentGroupProgressNotifier = ValueNotifier(0.0);


  // 【滚动感知导航】- 使用 ValueNotifier 优化
  final ValueNotifier<bool> _isScrollingNotifier = ValueNotifier(false);
  int _hideCheckId = 0; // 用于取消过时的延迟隐藏

  // 【Sticky Tab 可见性】- 使用 ValueNotifier 优化
  final ValueNotifier<bool> _currentGroupTabVisibleNotifier = ValueNotifier(true);

  // 【双 FAB】样式和可见性
  final ValueNotifier<DualFabStyle> _fabStyleNotifier = ValueNotifier(DualFabStyle.pill);
  final ValueNotifier<bool> _fabVisibleNotifier = ValueNotifier(true);
  int _fabHideCheckId = 0; // 用于取消过时的延迟显示


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

  // ========== 【页内搜索】状态 ==========
  /// 是否处于搜索模式
  bool _isSearchMode = false;
  /// 搜索关键词
  String _searchKeyword = '';
  /// 搜索结果列表
  List<InPageSearchMatch> _searchResults = [];
  /// 当前选中的搜索结果索引
  int _currentSearchIndex = 0;
  /// 搜索输入框控制器
  final TextEditingController _searchController = TextEditingController();
  /// 搜索输入框焦点
  final FocusNode _searchFocusNode = FocusNode();

  /// 获取或创建指定轮次的页码 ValueNotifier
  ValueNotifier<int> _getCardPageNotifier(int groupIndex) {
    return _cardPageNotifiers.putIfAbsent(groupIndex, () => ValueNotifier(0));
  }

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

    final RenderBox? tabBox = tabKey!.currentContext!.findRenderObject() as RenderBox?;
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
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _currentVisibleGroupNotifier.dispose();
    _currentGroupProgressNotifier.dispose();
    _isScrollingNotifier.dispose();
    _currentGroupTabVisibleNotifier.dispose();
    _fabStyleNotifier.dispose();
    _fabVisibleNotifier.dispose();
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
    // 【页内搜索】释放资源
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果话题 ID 变化，需要重新加载数据
    if (oldWidget.topicId != widget.topicId) {
      debugPrint('🔄 [ConversationScreen] topicId 变化: ${oldWidget.topicId} → ${widget.topicId}');

      // 清空所有缓存
      _conversation = null;
      _cachedGroups = null;
      _aiAnalyses = {};
      _discussionCounts = {};

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
    // 【性能优化】节流：限制计算频率
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastScrollUpdate < 16) return; // 约 60fps
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
    final searchStart = (lastVisible - 2).clamp(0, groups.length - 1);

    // 查找结果
    int visibleGroup = _currentVisibleGroupNotifier.value; // 保持上次值作为默认
    double progress = 0.0;
    bool tabVisible = true;
    bool found = false;

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

        found = true;
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
        found = true;
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

    final RenderBox? tabBox = tabKey!.currentContext!.findRenderObject() as RenderBox?;
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
  /// 【性能优化】使用 ValueNotifier 避免 setState
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      // 滚动开始 - 取消之前的延迟隐藏
      _hideCheckId++;
      _fabHideCheckId++;
      if (!_isScrollingNotifier.value) {
        _isScrollingNotifier.value = true;
      }
      // 滚动时隐藏 FAB
      if (_fabVisibleNotifier.value) {
        _fabVisibleNotifier.value = false;
      }
    } else if (notification is ScrollEndNotification) {
      // 滚动结束 - 延迟 1.5 秒后隐藏导航
      _hideCheckId++;
      final currentCheckId = _hideCheckId;

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (currentCheckId == _hideCheckId && mounted && _isScrollingNotifier.value) {
          _isScrollingNotifier.value = false;
        }
      });

      // 滚动结束 - 延迟 0.8 秒后显示 FAB
      _fabHideCheckId++;
      final currentFabCheckId = _fabHideCheckId;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (currentFabCheckId == _fabHideCheckId && mounted && !_fabVisibleNotifier.value) {
          _fabVisibleNotifier.value = true;
        }
      });
    }
    return false; // 不阻止事件继续传递
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

  // ========== 【页内搜索】方法 ==========

  /// 进入搜索模式
  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
    // 延迟聚焦，等待 UI 更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  /// 退出搜索模式
  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchKeyword = '';
      _searchResults = [];
      _currentSearchIndex = 0;
    });
    _searchController.clear();
  }

  /// 执行页内搜索
  void _performInPageSearch(String keyword) {
    if (keyword.trim().isEmpty) {
      setState(() {
        _searchKeyword = '';
        _searchResults = [];
        _currentSearchIndex = 0;
      });
      return;
    }

    final groups = _getConversationGroups();
    final results = <InPageSearchMatch>[];
    final lowerKeyword = keyword.toLowerCase();

    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];

      // 搜索用户问题
      final userMsg = group['user_message'] as Map<String, dynamic>;
      final userBlocks = userMsg['blocks'] as List<dynamic>? ?? [];
      String userText = '';
      for (final block in userBlocks) {
        if (block is Map<String, dynamic> && block['type'] == 'main_text') {
          userText += block['content'] as String? ?? '';
        }
      }
      if (userText.toLowerCase().contains(lowerKeyword)) {
        // 生成预览（关键词前后各取一些文字）
        final matchIndex = userText.toLowerCase().indexOf(lowerKeyword);
        final previewStart = (matchIndex - 20).clamp(0, userText.length);
        final previewEnd = (matchIndex + keyword.length + 30).clamp(0, userText.length);
        var preview = userText.substring(previewStart, previewEnd);
        if (previewStart > 0) preview = '...$preview';
        if (previewEnd < userText.length) preview = '$preview...';

        results.add(InPageSearchMatch(
          roundIndex: groupIndex,
          replyIndex: null,
          type: 'query',
          preview: preview.replaceAll('\n', ' '),
        ));
      }

      // 搜索助手回复
      final assistantReplies = group['assistant_replies'] as List<dynamic>;
      for (var replyIndex = 0; replyIndex < assistantReplies.length; replyIndex++) {
        final reply = assistantReplies[replyIndex] as Map<String, dynamic>;
        final blocks = reply['blocks'] as List<dynamic>? ?? [];
        String replyText = '';
        for (final block in blocks) {
          if (block is Map<String, dynamic> && block['type'] == 'main_text') {
            replyText += block['content'] as String? ?? '';
          }
        }
        if (replyText.toLowerCase().contains(lowerKeyword)) {
          // 生成预览
          final matchIndex = replyText.toLowerCase().indexOf(lowerKeyword);
          final previewStart = (matchIndex - 20).clamp(0, replyText.length);
          final previewEnd = (matchIndex + keyword.length + 30).clamp(0, replyText.length);
          var preview = replyText.substring(previewStart, previewEnd);
          if (previewStart > 0) preview = '...$preview';
          if (previewEnd < replyText.length) preview = '$preview...';

          results.add(InPageSearchMatch(
            roundIndex: groupIndex,
            replyIndex: replyIndex,
            type: 'reply',
            preview: preview.replaceAll('\n', ' '),
          ));
        }
      }
    }

    setState(() {
      _searchKeyword = keyword;
      _searchResults = results;
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
    });

    // 如果有结果，跳转到第一个
    if (results.isNotEmpty) {
      _navigateToSearchResult(0);
    }
  }

  /// 跳转到指定的搜索结果
  Future<void> _navigateToSearchResult(int index) async {
    if (index < 0 || index >= _searchResults.length) return;

    final result = _searchResults[index];

    // 1. 滚动到对应轮次
    await _scrollToGroup(result.roundIndex);

    // 2. 如果是回复，切换到对应的回复卡片
    if (result.type == 'reply' && result.replyIndex != null) {
      // 计算实际的卡片索引（AI 分析在前，回复在后）
      final aiAnalysisCount = _aiAnalyses[result.roundIndex]?.length ?? 0;
      final cardIndex = aiAnalysisCount + result.replyIndex!;
      _getCardPageNotifier(result.roundIndex).value = cardIndex;

      // 同步 PageController
      final pageController = _pageControllers[result.roundIndex];
      if (pageController != null && pageController.hasClients) {
        pageController.animateToPage(
          cardIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }

    setState(() {
      _currentSearchIndex = index;
    });
  }

  /// 跳转到上一个搜索结果
  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;
    final newIndex = (_currentSearchIndex - 1 + _searchResults.length) % _searchResults.length;
    _navigateToSearchResult(newIndex);
  }

  /// 跳转到下一个搜索结果
  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;
    final newIndex = (_currentSearchIndex + 1) % _searchResults.length;
    _navigateToSearchResult(newIndex);
  }

  Future<void> _loadData() async {
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
    if (conv == null) {
      sw.reset();
      conv = widget.extractor.extractTopicConversation(widget.topicId);
      debugPrint('⏱️ [ConversationScreen] fallback到extractor: ${sw.elapsedMilliseconds}ms');
    }

    // 【性能优化】批量预加载所有消息的标注（依赖 conv，必须串行）
    if (conv != null) {
      final messages = conv['messages'] as List<dynamic>? ?? [];
      final messageIds = messages
          .where((m) => m is Map<String, dynamic>)
          .map((m) => m['id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      if (messageIds.isNotEmpty) {
        sw.reset();
        final highlightService = HighlightService();
        await highlightService.batchPreload(messageIds);
        debugPrint('⏱️ [ConversationScreen] 标注预加载 (${messageIds.length}条): ${sw.elapsedMilliseconds}ms');
      }

      // 【新增】批量预加载讨论数量
      sw.reset();
      await _preloadDiscussionCounts(conv);
      debugPrint('⏱️ [ConversationScreen] 讨论数量预加载: ${sw.elapsedMilliseconds}ms');
    }

    debugPrint('⏱️ [ConversationScreen] _loadData 总耗时: ${totalSw.elapsedMilliseconds}ms');

    final renderSw = Stopwatch()..start();
    setState(() {
      _conversation = conv;
      _aiAnalyses = analyses;
      _cachedGroups = null; // 清除缓存，触发重新计算
    });

    // 测量首帧渲染时间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('⏱️ [ConversationScreen] 首帧渲染完成: ${renderSw.elapsedMilliseconds}ms');

      // 【搜索定位】如果有指定的轮次，自动滚动到该位置
      if (widget.scrollToRoundIndex != null) {
        _scrollToGroupWithDelay(widget.scrollToRoundIndex!);
      }
    });

    // ========== 调试信息：打印 Topic 详情 ==========
    _printTopicDebugInfo();
  }

  /// 【新增】批量预加载讨论数量
  Future<void> _preloadDiscussionCounts(Map<String, dynamic> conv) async {
    final conversationService = UnifiedConversationService.instance;
    final messages = conv['messages'] as List<dynamic>? ?? [];
    final counts = <String, int>{};

    // 收集所有需要查询的 contextId
    final contextIds = <String>[];

    // 1. 收集所有消息的 messageId（单条消息讨论）
    for (final msg in messages) {
      if (msg is Map<String, dynamic>) {
        final messageId = msg['id'] as String?;
        if (messageId != null && messageId.isNotEmpty) {
          contextIds.add(messageId);
        }
      }
    }

    // 2. 收集轮次级别的 contextId（消息组讨论）
    // 先解析分组以获取轮次数量
    final groups = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentGroup;
    for (final msg in messages) {
      if (msg is! Map<String, dynamic>) continue;
      final role = msg['role'] as String?;
      if (role == 'user') {
        if (currentGroup != null) groups.add(currentGroup);
        currentGroup = {'user_message': msg, 'assistant_replies': <Map<String, dynamic>>[]};
      } else if (role == 'assistant' && currentGroup != null) {
        (currentGroup['assistant_replies'] as List).add(msg);
      }
    }
    if (currentGroup != null) groups.add(currentGroup);

    // 添加轮次级别的 contextId
    for (var i = 0; i < groups.length; i++) {
      contextIds.add('${widget.topicId}:$i');
    }

    // 3. 批量查询讨论数量
    for (final contextId in contextIds) {
      final conversations = await conversationService.getConversationsByContext(contextId);
      counts[contextId] = conversations.length;
    }

    _discussionCounts = counts;
  }

  /// 打印 Topic 调试信息
  void _printTopicDebugInfo() {
    print('\n');
    print('╔══════════════════════════════════════════════════════════════════╗');
    print('║                    📋 TOPIC 详情调试信息                          ║');
    print('╠══════════════════════════════════════════════════════════════════╣');
    print('║ Topic ID:    ${widget.topicId}');
    print('║ Topic 名称:  ${widget.topicName}');

    // 获取 Assistant 信息
    final topic = widget.extractor.getTopic(widget.topicId);
    if (topic != null) {
      final assistantId = topic['assistantId'] as String?;
      final assistant = assistantId != null
          ? widget.extractor.getAssistantById(assistantId)
          : null;
      final assistantName = assistant?['name'] as String? ?? '未知助手';
      print('║ Assistant:   $assistantName (ID: $assistantId)');
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

      print('╠══════════════════════════════════════════════════════════════════╣');
      print('║ 📊 统计信息:');
      print('║   - 对话轮数:     ${groups.length} 轮');
      print('║   - 总消息数:     ${messages.length} 条');
      print('║   - 用户消息:     $userMsgCount 条');
      print('║   - 助手回复:     $assistantMsgCount 条');
      print('║   - 使用的模型:   ${modelNames.join(', ')}');

      // 打印每轮的详细信息
      print('╠══════════════════════════════════════════════════════════════════╣');
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

    print('╚══════════════════════════════════════════════════════════════════╝');
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

  Future<void> _exportToEpub(int groupIndex) async {
    final groups = _getConversationGroups();
    if (groupIndex >= groups.length) return;

    final group = groups[groupIndex];
    final userMsg = group['user_message'] as Map<String, dynamic>;
    final assistantReplies = group['assistant_replies'] as List<dynamic>;
    final analyses = _aiAnalyses[groupIndex] ?? [];

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成电子书...')),
      );

      await _epubExportService.exportGroup(
        topicName: widget.topicName,
        userMessage: userMsg,
        assistantReplies: assistantReplies,
        aiAnalyses: analyses,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ EPUB 3.0 导出成功 (v2)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('电子书导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 导出完整对话（所有轮次）
  Future<void> _exportFullConversation() async {
    final groups = _getConversationGroups();

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有对话内容可以导出')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正在生成完整对话电子书 (${groups.length} 轮)...')),
      );

      await _epubExportService.exportFullConversation(
        topicName: widget.topicName,
        groups: groups,
        allAnalyses: _aiAnalyses,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 完整对话导出成功 (${groups.length} 轮)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('完整对话导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 构建格式化的上下文内容（用户问题 + 模型回复）
  ///
  /// 不包含模板内容，模板由用户在 AIChatScreen 中选择
  String _buildFormattedContext(
    Map<String, dynamic> userMsg,
    List<dynamic> assistantReplies,
  ) {
    // 提取用户问题
    final userBlocks = userMsg['blocks'] as List<dynamic>? ?? [];
    var userQuery = '';
    for (final block in userBlocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        userQuery += block['content'] as String? ?? '';
      }
    }

    // 提取各模型回复
    var modelResponses = '';
    for (var i = 0; i < assistantReplies.length; i++) {
      final reply = assistantReplies[i] as Map<String, dynamic>;
      final model = reply['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Unknown';

      final blocks = reply['blocks'] as List<dynamic>? ?? [];
      var content = '';
      for (final block in blocks) {
        if (block is Map<String, dynamic> && block['type'] == 'main_text') {
          content += block['content'] as String? ?? '';
        }
      }

      modelResponses += '\n\n### 模型 ${i + 1}: $modelName\n$content';
    }

    // 返回格式化的上下文（不含模板）
    return '''**用户问题：**

$userQuery

**模型回复对比（${assistantReplies.length} 个）：**

$modelResponses''';
  }

  /// 构建普通 AppBar
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: Text(widget.topicName),
      actions: [
        // 页内搜索按钮
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '页内搜索',
          onPressed: _conversation == null ? null : _enterSearchMode,
        ),
        // 朗读整个话题按钮 - 使用 Selector 只监听 hasValidConfig
        Selector<TtsProvider, bool>(
          selector: (_, tts) => tts.hasValidConfig,
          builder: (context, hasValidConfig, _) {
            if (!hasValidConfig) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.headphones),
              tooltip: '朗读整个话题',
              onPressed: _conversation == null ? null : _playTopicAudio,
            );
          },
        ),
        // 导出完整对话按钮
        IconButton(
          icon: const Icon(Icons.file_download),
          tooltip: '导出完整对话',
          onPressed: _conversation == null ? null : _exportFullConversation,
        ),
      ],
    );
  }

  /// 构建搜索模式 AppBar
  AppBar _buildSearchAppBar(bool isDark) {
    final hasResults = _searchResults.isNotEmpty;
    final resultText = hasResults
        ? '${_currentSearchIndex + 1}/${_searchResults.length}'
        : (_searchKeyword.isNotEmpty ? '0/0' : '');

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: '退出搜索',
        onPressed: _exitSearchMode,
      ),
      titleSpacing: 0,
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: '搜索对话内容...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _performInPageSearch('');
                  },
                )
              : null,
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        onChanged: _performInPageSearch,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) {
          // 回车跳转到下一个结果
          if (_searchResults.isNotEmpty) {
            _nextSearchResult();
          }
        },
      ),
      actions: [
        // 结果计数
        if (resultText.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                resultText,
                style: TextStyle(
                  fontSize: 14,
                  color: hasResults ? null : Colors.grey[500],
                ),
              ),
            ),
          ),
        // 上一个按钮
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          tooltip: '上一个',
          onPressed: hasResults ? _previousSearchResult : null,
        ),
        // 下一个按钮
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          tooltip: '下一个',
          onPressed: hasResults ? _nextSearchResult : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _isSearchMode
          ? _buildSearchAppBar(isDark)
          : _buildNormalAppBar(),
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
                      // 浮动轮次导航器（滚动时显示）
                      _buildFloatingNavigation(),
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
      // 双 FAB：朗读 + 讨论
      floatingActionButton: _conversation == null
          ? null
          : Selector<TtsProvider, bool>(
              selector: (_, tts) => tts.hasValidConfig,
              builder: (context, hasValidConfig, _) {
                // 如果没有 TTS 配置，显示原来的单按钮
                if (!hasValidConfig) {
                  return ValueListenableBuilder<int>(
                    valueListenable: _currentVisibleGroupNotifier,
                    builder: (context, currentGroup, _) {
                      final groups = _getConversationGroups();
                      if (groups.isEmpty) return const SizedBox.shrink();
                      final contextId = '${widget.topicId}:$currentGroup';
                      final discussionCount = _discussionCounts[contextId] ?? 0;
                      final hasDiscussion = discussionCount > 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: GestureDetector(
                          // 长按：选中当前整轮对话
                          onLongPress: () => _openAnalysisChat(currentGroup),
                          child: FloatingActionButton.extended(
                            // 单击：只选中当前回复
                            onPressed: () => _openAnalysisChatForReply(currentGroup),
                            backgroundColor: hasDiscussion
                                ? const Color(0xFF8B5CF6)
                                : Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: hasDiscussion
                                ? Colors.white
                                : Theme.of(context).colorScheme.onPrimaryContainer,
                            icon: Badge(
                              isLabelVisible: discussionCount > 0,
                              label: Text(
                                discussionCount > 99 ? '99+' : '$discussionCount',
                                style: const TextStyle(fontSize: 10),
                              ),
                              child: Icon(
                                hasDiscussion ? Icons.chat_bubble : Icons.chat_bubble_outline,
                              ),
                            ),
                            label: Text('讨论 #${currentGroup + 1}'),
                          ),
                        ),
                      );
                    },
                  );
                }

                // 有 TTS 配置，显示双 FAB
                return ValueListenableBuilder<DualFabStyle>(
                  valueListenable: _fabStyleNotifier,
                  builder: (context, fabStyle, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _fabVisibleNotifier,
                      builder: (context, fabVisible, _) {
                        return ValueListenableBuilder<int>(
                          valueListenable: _currentVisibleGroupNotifier,
                          builder: (context, currentGroup, _) {
                            final groups = _getConversationGroups();
                            if (groups.isEmpty) return const SizedBox.shrink();

                            final contextId = '${widget.topicId}:$currentGroup';
                            final discussionCount = _discussionCounts[contextId] ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 60),
                              child: DualFab(
                                style: fabStyle,
                                visible: fabVisible,
                                discussionCount: discussionCount,
                                isPlaying: false, // TODO: 连接 TTS 播放状态
                                onPlayPressed: () => _playGroupAudio(currentGroup),
                                // 单击：只选中当前回复
                                onDiscussPressed: () => _openAnalysisChatForReply(currentGroup),
                                // 长按：选中当前整轮对话（用户问题 + 回复）
                                onDiscussLongPressed: () => _openAnalysisChat(currentGroup),
                                onStyleChange: _showFabStylePicker,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
        padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 80),
        // cacheExtent: 提前渲染视口外的内容，确保滚动流畅
        cacheExtent: 500,
        itemCount: groups.length,
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          // 使用 AutoScrollTag 包装，支持 scrollToIndex
          return AutoScrollTag(
            key: ValueKey(index),
            controller: _scrollController,
            index: index,
            child: KeepAliveWrapper(
              child: RepaintBoundary(
                child: _buildConversationGroup(groups[index], index),
              ),
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
            final assistantReplies = currentGroup['assistant_replies'] as List<dynamic>;

            // 如果只有一个回复，不显示 Tab
            final aiAnalysisCount = _aiAnalyses[currentVisibleGroup]?.length ?? 0;
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
                      color: (isDark ? Colors.grey[900] : Colors.white)?.withValues(alpha: 0.98),
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
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                                  children: cardInfoList.asMap().entries.map((entry) {
                                    final cardIndex = entry.key;
                                    final info = entry.value;
                                    final isSelected = cardIndex == currentPage;
                                    final isMainline = info['isMainline'] as bool? ?? false;

                                    return _AnimatedModelTab(
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
                                        _getCardPageNotifier(currentVisibleGroup).value = cardIndex;
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


  /// 构建滚动感知的进度导航（紧凑胶囊式）
  /// 【性能优化】使用 ValueListenableBuilder 避免整页重建
  Widget _buildFloatingNavigation() {
    final groups = _getConversationGroups();
    final totalGroups = groups.length;

    if (totalGroups <= 1) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      right: 12, // 留出能量条的空间
      top: 0,
      bottom: 80,
      child: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: _isScrollingNotifier,
          builder: (context, isScrolling, child) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isScrolling ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: isScrolling ? Offset.zero : const Offset(0.3, 0),
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  ignoring: !isScrolling,
                  child: child,
                ),
              ),
            );
          },
          child: ValueListenableBuilder<int>(
            valueListenable: _currentVisibleGroupNotifier,
            builder: (context, currentVisibleGroup, _) {
              // 如果轮次太多，只显示关键节点
              final showAll = totalGroups <= 10;
              final displayIndices = showAll
                  ? List.generate(totalGroups, (i) => i)
                  : _getKeyIndices(totalGroups, currentVisibleGroup);

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.grey[900] : Colors.white)?.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: displayIndices.map((index) {
                    final isActive = index == currentVisibleGroup;
                    final isEllipsis = index < 0;

                    if (isEllipsis) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '⋮',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () => _scrollToGroup(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: EdgeInsets.symmetric(
                          horizontal: isActive ? 8 : 6,
                          vertical: isActive ? 4 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: isActive ? 12 : 10,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? Colors.white
                                : (isDark ? Colors.grey[500] : Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 获取关键索引（用于折叠显示）
  List<int> _getKeyIndices(int total, int current) {
    final indices = <int>[];

    // 始终显示第一个
    indices.add(0);

    // 当前位置附近
    if (current > 2) indices.add(-1); // 省略号
    if (current > 1) indices.add(current - 1);
    if (current > 0 && current < total - 1) indices.add(current);
    if (current < total - 2) indices.add(current + 1);
    if (current < total - 3) indices.add(-1); // 省略号

    // 始终显示最后一个
    if (total > 1 && !indices.contains(total - 1)) {
      indices.add(total - 1);
    }

    // 去重并排序
    return indices.toSet().toList()..sort((a, b) {
      if (a == -1) return 0;
      if (b == -1) return 0;
      return a.compareTo(b);
    });
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              _buildCleanReplyContent(groupIndex, assistantReplies, isSingleCard),
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
    final displayText = isLong ? '${userText.substring(0, collapsedPreviewLength)}...' : userText;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 获取轮次级别的讨论数量
    final contextId = '${widget.topicId}:$groupIndex';
    final discussionCount = _discussionCounts[contextId] ?? 0;
    final hasDiscussion = discussionCount > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI 讨论（带数量角标）
        _buildIconWithBadge(
          icon: hasDiscussion ? Icons.chat_bubble : Icons.chat_bubble_outline,
          tooltip: 'AI 讨论（长按选整轮）',
          color: hasDiscussion ? const Color(0xFF8B5CF6) : Colors.grey[400]!,
          badgeCount: discussionCount,
          // 单击：只选中当前回复
          onPressed: () => _openAnalysisChatForReply(groupIndex),
          // 长按：选中当前整轮对话
          onLongPress: () => _openAnalysisChat(groupIndex),
        ),
        // TTS 朗读 - 【性能优化】使用 Selector 只监听 hasValidConfig
        Selector<TtsProvider, bool>(
          selector: (_, tts) => tts.hasValidConfig,
          builder: (context, hasValidConfig, _) {
            if (!hasValidConfig) return const SizedBox.shrink();
            return _buildIconOnlyButton(
              icon: Icons.volume_up_rounded,
              tooltip: '朗读',
              color: const Color(0xFF8B5CF6),
              onPressed: () => _playGroupAudio(groupIndex),
            );
          },
        ),
        // 导出
        _buildIconOnlyButton(
          icon: Icons.menu_book_rounded,
          tooltip: '导出',
          color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
          onPressed: () => _exportToEpub(groupIndex),
        ),
      ],
    );
  }

  /// 简洁布局：图标按钮
  Widget _buildIconOnlyButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: color,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      splashRadius: 18,
    );
  }

  /// 简洁布局：带角标的图标按钮
  Widget _buildIconWithBadge({
    required IconData icon,
    required String tooltip,
    required Color color,
    required int badgeCount,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, size: 18, color: color)),
              if (badgeCount > 0)
                Positioned(
                  right: 0,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B5CF6),
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
        ),
      ),
    );
  }

  /// 简洁布局：回复内容区域（流式布局）
  /// 【性能优化】使用 ValueListenableBuilder 避免整页重建
  Widget _buildCleanReplyContent(int groupIndex, List<dynamic> assistantReplies, bool isSingleCard) {
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
              children: [
                const Spacer(),
                _buildCleanActionButtons(groupIndex),
              ],
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
      _pageControllers[groupIndex] = PageController(initialPage: pageNotifier.value);
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
  void _scrollTabToVisible(int groupIndex, int tabIndex, ScrollController controller) {
    if (!controller.hasClients) return;

    final tabKey = 'tab_${groupIndex}_$tabIndex';
    final key = _tabKeys[tabKey];
    if (key?.currentContext == null) return;

    final RenderBox? tabBox = key!.currentContext!.findRenderObject() as RenderBox?;
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
    final relativePosition = tabPosition.dx - scrollPosition.dx + controller.offset;

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
          onDoubleTap: () {
            // 【快速定位】双击内容区域滚动到本轮次顶部
            _scrollToGroupTop(groupIndex);
          },
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
    final contentTypes = ['main_text', 'thinking', 'translation', 'code', 'error', 'text'];
    for (final block in blocks) {
      if (block is Map<String, dynamic> && contentTypes.contains(block['type'])) {
        content += block['content'] as String? ?? '';
      }
    }

    // 获取单条消息的讨论数量
    final discussionCount = _discussionCounts[messageId] ?? 0;

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
                actionBar: MessageActionBar(
                  content: content,
                  messageId: messageId,
                  modelName: modelName,
                  onDiscuss: () => _openSingleMessageDiscussion(reply),
                  onRegenerate: null, // TODO: 实现重新生成
                  showRegenerate: false, // 查看模式暂不支持重新生成
                  showSpeak: hasValidConfig,
                  onSpeak: () => _speakContent(content, modelName),
                  discussionCount: discussionCount,
                ),
                // 传递上下文参数，使全屏阅读时能进行讨论
                topicId: widget.topicId,
                roundIndex: groupIndex,
                // 【搜索高亮】优先使用页内搜索关键词，否则使用外部传入的
                searchKeyword: _searchKeyword.isNotEmpty ? _searchKeyword : widget.highlightKeyword,
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

  /// 打开单条消息的讨论
  void _openSingleMessageDiscussion(Map<String, dynamic> reply) {
    final model = reply['model'] as Map<String, dynamic>?;
    final modelName = model?['name'] as String? ?? 'Assistant';
    final messageId = reply['id'] as String? ?? '';

    // 提取内容（包含多种可显示的块类型）
    // 优先顺序：main_text > thinking > translation > code > error
    final blocks = reply['blocks'] as List<dynamic>? ?? [];
    String content = '';
    final contentTypes = ['main_text', 'thinking', 'translation', 'code', 'error'];
    for (final type in contentTypes) {
      for (final block in blocks) {
        if (block is Map<String, dynamic> && block['type'] == type) {
          content += block['content'] as String? ?? '';
        }
      }
    }

    // 构建上下文数据
    final contextData = {
      'rounds': [
        {
          'index': 0,
          'question': null,
          'replies': [reply],
        }
      ],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          initialContextId: messageId,
          initialContextSnapshot: content,
          initialTitle: '讨论: $modelName',
          initialContextData: contextData,
          contextTypeFilter: ConversationContextType.singleMessage,
        ),
      ),
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


  /// 打开 AI 分析对话界面（多轮对话模式）
  ///
  /// 【修复】不再预先创建空对话，而是传递参数让 AIChatScreen 懒创建
  /// 只有当用户实际发送消息时才会创建对话，避免产生空对话
  Future<void> _openAnalysisChat(int groupIndex) async {
    final groups = _getConversationGroups();
    if (groupIndex >= groups.length) return;

    final group = groups[groupIndex];
    final userMsg = group['user_message'] as Map<String, dynamic>;
    final assistantReplies = group['assistant_replies'] as List<dynamic>;

    if (assistantReplies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该问题没有助手回复')),
      );
      return;
    }

    // 构建上下文快照（markdown 格式）
    final contextSnapshot = _buildContextSnapshot(userMsg, assistantReplies);

    // 构建原始上下文数据（结构化数据）
    final contextData = _buildContextData(groups, groupIndex);

    // 构建格式化的上下文内容（用户问题 + 模型回复，不含模板）
    final formattedContext = _buildFormattedContext(userMsg, assistantReplies);
    contextData['formattedContext'] = formattedContext;

    // 构建 contextId（用于对话分组和查询）
    final contextId = '${widget.topicId}:$groupIndex';

    // 跳转到 AI 对话界面
    // 【修复】不传 initialConversationId，让 AIChatScreen 在用户发送消息时懒创建
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIChatScreen(
            // initialConversationId: null - 不预先创建，懒创建
            initialContextId: contextId,
            initialContextSnapshot: contextSnapshot,
            initialContextData: contextData, // ← 传递原始数据
            initialTitle: '分析 - 第 ${groupIndex + 1} 轮对话',
            contextTypeFilter: ConversationContextType.messageGroup,
          ),
        ),
      );
    }
  }

  /// 打开 AI 分析对话界面（只选中当前显示的回复）
  ///
  /// 用于单击讨论按钮，只选中当前 tab 显示的那条回复
  Future<void> _openAnalysisChatForReply(int groupIndex) async {
    // 复用完整的 contextData，只是添加标记让编辑器只选当前显示的回复
    final groups = _getConversationGroups();
    if (groupIndex >= groups.length) return;

    final group = groups[groupIndex];
    final userMsg = group['user_message'] as Map<String, dynamic>;
    final assistantReplies = group['assistant_replies'] as List<dynamic>;

    if (assistantReplies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该问题没有助手回复')),
      );
      return;
    }

    // 获取当前显示的回复索引（用户正在看的 tab）
    final currentReplyIndex = _getCardPageNotifier(groupIndex).value;

    // 使用与长按相同的方式构建数据
    final contextSnapshot = _buildContextSnapshot(userMsg, assistantReplies);
    final contextData = _buildContextData(groups, groupIndex);
    final formattedContext = _buildFormattedContext(userMsg, assistantReplies);
    contextData['formattedContext'] = formattedContext;

    // 添加标记：不选问题，只选当前显示的回复
    contextData['selectQuestionByDefault'] = false;
    contextData['selectOnlyReplyIndex'] = currentReplyIndex;  // 只选这个索引的回复

    final contextId = '${widget.topicId}:$groupIndex:reply:$currentReplyIndex';

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIChatScreen(
            initialContextId: contextId,
            initialContextSnapshot: contextSnapshot,
            initialContextData: contextData,
            initialTitle: '讨论 - 第 ${groupIndex + 1} 轮回复',
            contextTypeFilter: ConversationContextType.messageGroup,
          ),
        ),
      );
    }
  }

  /// 构建原始上下文数据（结构化数据，包含所有轮次和完整字段）
  Map<String, dynamic> _buildContextData(
    List<Map<String, dynamic>> groups,
    int currentGroupIndex,
  ) {
    final rounds = <Map<String, dynamic>>[];

    // 提取所有轮次的原始数据
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final userMsg = group['user_message'] as Map<String, dynamic>;
      final assistantReplies = group['assistant_replies'] as List<dynamic>;

      rounds.add({
        'index': i,
        'question': userMsg, // 保留完整的用户消息数据
        'replies': assistantReplies, // 保留完整的助手回复数据（包含 useful 字段）
      });
    }

    // 获取助手信息
    String? assistantId;
    String? assistantName;
    if (_conversation != null) {
      assistantId = _conversation!['assistantId'] as String?;
      // 尝试从 assistant 字段获取名称
      final assistant = _conversation!['assistant'] as Map<String, dynamic>?;
      assistantName = assistant?['name'] as String?;
    }

    return {
      'rounds': rounds,
      'currentRoundIndex': currentGroupIndex, // 当前轮次索引
      'topicId': widget.topicId,
      'topicName': widget.topicName,
      'assistantId': assistantId,
      'assistantName': assistantName,
    };
  }

  /// 构建上下文快照（用于保存到对话中）
  String _buildContextSnapshot(
    Map<String, dynamic> userMsg,
    List<dynamic> assistantReplies,
  ) {
    // 提取用户问题
    final userBlocks = userMsg['blocks'] as List<dynamic>? ?? [];
    var userQuery = '';
    for (final block in userBlocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        userQuery += block['content'] as String? ?? '';
      }
    }

    // 构建快照
    var snapshot = '## 用户问题\n\n$userQuery\n\n## 模型回复\n\n';
    for (var i = 0; i < assistantReplies.length; i++) {
      final reply = assistantReplies[i] as Map<String, dynamic>;
      final model = reply['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Unknown';

      final blocks = reply['blocks'] as List<dynamic>? ?? [];
      var content = '';
      for (final block in blocks) {
        if (block is Map<String, dynamic> && block['type'] == 'main_text') {
          content += block['content'] as String? ?? '';
        }
      }

      snapshot += '### $modelName\n\n$content\n\n';
    }

    return snapshot;
  }

  /// 播放本轮对话音频
  void _playGroupAudio(int groupIndex) {
    final groups = _getConversationGroups();
    if (groupIndex >= groups.length) return;

    final group = groups[groupIndex];
    final content = _buildReadableTextForGroup(group, groupIndex);

    if (content.isEmpty) return;

    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    final item = TtsItem(
      id: 'group_${widget.topicId}_$groupIndex',
      text: content,
      title: '第 ${groupIndex + 1} 轮对话',
      author: widget.topicName,
    );

    ttsProvider.setPlaylist([item]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始朗读第 ${groupIndex + 1} 轮对话...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 播放整个话题的所有轮次
  void _playTopicAudio() {
    final groups = _getConversationGroups();
    if (groups.isEmpty) return;

    final content = _buildReadableTextForTopic(groups);
    if (content.isEmpty) return;

    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    final item = TtsItem(
      id: 'topic_${widget.topicId}',
      text: content,
      title: widget.topicName,
      author: 'Cherry Reader',
    );

    ttsProvider.setPlaylist([item]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始朗读话题：${widget.topicName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 构建单轮对话的可朗读文本
  String _buildReadableTextForGroup(Map<String, dynamic> group, int groupIndex, {bool includeRoundHint = false}) {
    final buffer = StringBuffer();

    // 轮次提示（用于整个话题朗读时）
    if (includeRoundHint) {
      buffer.writeln('第 ${groupIndex + 1} 轮对话');
      buffer.writeln();
    }

    // 用户问题
    final userText = group['user_text'] as String? ?? '';
    if (userText.isNotEmpty) {
      // 如果问题太长，截取前 200 字
      final displayQuestion = userText.length > 200
          ? '${userText.substring(0, 200)}...等等'
          : userText;
      buffer.writeln('用户问：$displayQuestion');
      buffer.writeln();
    }

    // AI 分析（如果有）
    final analyses = _aiAnalyses[groupIndex] ?? [];
    if (analyses.isNotEmpty) {
      buffer.writeln('AI 分析：');
      buffer.writeln();
      for (final analysis in analyses) {
        buffer.writeln(analysis);
        buffer.writeln();
      }
    }

    // 各模型回复
    final assistantReplies = group['assistant_replies'] as List<dynamic>? ?? [];
    for (var i = 0; i < assistantReplies.length; i++) {
      final reply = assistantReplies[i] as Map<String, dynamic>;
      final model = reply['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Assistant';
      final useful = reply['useful'] as bool? ?? false;

      final blocks = reply['blocks'] as List<dynamic>? ?? [];
      var content = '';
      for (final block in blocks) {
        if (block is Map<String, dynamic> && block['type'] == 'main_text') {
          content += block['content'] as String? ?? '';
        }
      }

      if (content.isNotEmpty) {
        // 多回复时加模型名称提示
        if (assistantReplies.length > 1) {
          if (useful) {
            buffer.writeln('$modelName 的主要回复：');
          } else {
            buffer.writeln('$modelName 回复：');
          }
          buffer.writeln();
        }

        buffer.writeln(content);
        buffer.writeln();

        // 回复之间添加分隔（会被 SSML 转换器处理为停顿）
        if (i < assistantReplies.length - 1) {
          buffer.writeln('---');
          buffer.writeln();
        }
      }
    }

    return buffer.toString().trim();
  }

  /// 构建整个话题的可朗读文本
  String _buildReadableTextForTopic(List<Map<String, dynamic>> groups) {
    final buffer = StringBuffer();

    // 话题标题
    buffer.writeln('话题：${widget.topicName}');
    buffer.writeln();
    buffer.writeln('共 ${groups.length} 轮对话');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 各轮次
    for (var i = 0; i < groups.length; i++) {
      buffer.writeln(_buildReadableTextForGroup(groups[i], i, includeRoundHint: true));

      // 轮次之间添加分隔
      if (i < groups.length - 1) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    buffer.writeln();
    buffer.writeln('话题结束');

    return buffer.toString().trim();
  }

  /// 显示 FAB 样式选择器底部弹窗
  void _showFabStylePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动指示器
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '选择悬浮按钮样式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
              ),
              // 样式列表
              SizedBox(
                height: 400,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: DualFabStyle.values.length,
                  itemBuilder: (context, index) {
                    final style = DualFabStyle.values[index];
                    final isSelected = style == _fabStyleNotifier.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          _fabStyleNotifier.value = style;
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                                : (isDark ? Colors.grey[850] : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF8B5CF6),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // 样式预览
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Transform.scale(
                                    scale: 0.6,
                                    child: IgnorePointer(
                                      child: DualFab(
                                        style: style,
                                        onPlayPressed: () {},
                                        onDiscussPressed: () {},
                                        discussionCount: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 样式信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      style.displayName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF8B5CF6)
                                            : (isDark ? Colors.white : Colors.grey[800]),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      style.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 选中标记
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF8B5CF6),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 底部安全区
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (!_expanded) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.userText.length} 字',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
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
                        : (isDark ? const Color(0xFFB8860B) : const Color(0xFFDAA520)),
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
  final VoidCallback? onDoubleTap;

  const _SwipeableSwitcher({
    required this.currentIndex,
    required this.totalCount,
    required this.onIndexChanged,
    required this.itemBuilder,
    this.onDoubleTap,
  });

  @override
  State<_SwipeableSwitcher> createState() => _SwipeableSwitcherState();
}

class _SwipeableSwitcherState extends State<_SwipeableSwitcher> {
  // 【性能优化】使用 ValueNotifier 替代 setState，拖动时只重绘必要部分
  final ValueNotifier<double> _dragOffsetNotifier = ValueNotifier(0);
  bool _isDragging = false;

  @override
  void dispose() {
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
    _dragOffsetNotifier.value = (_dragOffsetNotifier.value + details.delta.dx).clamp(-maxDrag, maxDrag);
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

    // 【性能优化】内容区域不依赖 dragOffset，避免重建
    final contentWidget = widget.itemBuilder(widget.currentIndex);

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onDoubleTap: widget.onDoubleTap,
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
                    dragProgress: dragOffset < 0 ? (-dragOffset / 80).clamp(0.0, 1.0) : 0.0,
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
                    dragProgress: dragOffset > 0 ? (dragOffset / 80).clamp(0.0, 1.0) : 0.0,
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
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06 * baseOpacity),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            isRight ? Icons.chevron_right : Icons.chevron_left,
            size: 24,
            color: (isDark ? Colors.grey[400] : Colors.grey[400])?.withValues(alpha: baseOpacity),
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
                      final emptyColor = color.withValues(alpha: isDark ? 0.2 : 0.25);

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
                                      color: isDark ? Colors.black : Colors.white,
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
