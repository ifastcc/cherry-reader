import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../services/cherry_extractor.dart';
import '../services/analysis_cache_manager.dart';
import '../services/highlight_service.dart';
import '../services/unified_conversation_service.dart';
import '../services/topic_service.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../widgets/highlightable_card.dart';
import '../widgets/message_action_bar.dart';
import '../services/epub_export_service.dart';
import 'settings_screen.dart';
import 'ai_chat_screen.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../models/tts_item.dart';
import '../widgets/tts_mini_player.dart';

class ConversationScreen extends StatefulWidget {
  final CherryExtractor extractor;
  final String topicId;
  final String topicName;

  const ConversationScreen({
    Key? key,
    required this.extractor,
    required this.topicId,
    required this.topicName,
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

  // 卡片显示配置
  late int _columnsPerView;

  // 【性能优化】缓存对话分组结果
  List<Map<String, dynamic>>? _cachedGroups;

  final _epubExportService = EpubExportService();

  // 【轮次导航】使用 scrollable_positioned_list 精确定位
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  int _currentVisibleGroup = 0;

  // 【卡片翻页】每个轮次的当前卡片页码
  final Map<int, int> _cardPageIndexes = {};

  @override
  void initState() {
    super.initState();

    _cacheManager = AnalysisCacheManager();
    _topicService = TopicService();
    _initColumnsConfig();
    _loadData();

    // 【轮次导航】监听可见位置变化
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  /// 位置变化回调：自动更新当前可见轮次
  void _onPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // 找到第一个可见度最高的 item（itemLeadingEdge 最接近 0 的）
    final visible = positions
        .where((p) => p.itemLeadingEdge < 1 && p.itemTrailingEdge > 0)
        .toList();

    if (visible.isEmpty) return;

    // 选择最靠近顶部的 item
    visible.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final topItem = visible.first;

    if (topItem.index != _currentVisibleGroup) {
      setState(() {
        _currentVisibleGroup = topItem.index;
      });
    }
  }

  /// 跳转到指定轮次（简洁实现）
  void _scrollToGroup(int groupIndex) {
    final groups = _getConversationGroups();
    if (groupIndex < 0 || groupIndex >= groups.length) return;

    _itemScrollController.scrollTo(
      index: groupIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 初始化卡片显示配置
  Future<void> _initColumnsConfig() async {
    final columnsPerView = await getColumnsPerView();
    setState(() {
      _columnsPerView = columnsPerView;
    });
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
    });

    // ========== 调试信息：打印 Topic 详情 ==========
    _printTopicDebugInfo();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName),
        actions: [
          // 导出完整对话按钮
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出完整对话',
            onPressed: _conversation == null ? null : _exportFullConversation,
          ),
        ],
      ),
      body: _conversation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildConversation(),
                // 浮动轮次导航器（集成卡片页码）
                _buildFloatingNavigation(),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TtsMiniPlayer(),
                ),
              ],
            ),
    );
  }

  Widget _buildConversation() {
    final groups = _getConversationGroups();

    // 使用 ScrollablePositionedList 实现精确定位
    return ScrollablePositionedList.separated(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 80),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: _buildConversationGroup(groups[index], index),
        );
      },
    );
  }


  /// 构建浮动导航组件（垂直布局）- 只用于轮次导航
  Widget _buildFloatingNavigation() {
    final groups = _getConversationGroups();
    final totalGroups = groups.length;

    if (totalGroups <= 1) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 6,
      bottom: 85,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.grey[900] : Colors.white)?.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 向上箭头
            _buildNavArrow(
              icon: Icons.keyboard_arrow_up_rounded,
              enabled: _currentVisibleGroup > 0,
              onTap: () => _scrollToGroup(_currentVisibleGroup - 1),
            ),

            // 页码（点击弹出完整列表）
            GestureDetector(
              onTap: () => _showRoundPicker(totalGroups),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  '${_currentVisibleGroup + 1}/$totalGroups',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // 向下箭头
            _buildNavArrow(
              icon: Icons.keyboard_arrow_down_rounded,
              enabled: _currentVisibleGroup < totalGroups - 1,
              onTap: () => _scrollToGroup(_currentVisibleGroup + 1),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导航箭头（紧凑版）
  Widget _buildNavArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(3),
        child: Icon(
          icon,
          size: 22,
          color: enabled
              ? Theme.of(context).primaryColor
              : (isDark ? Colors.grey[600] : Colors.grey[300]),
        ),
      ),
    );
  }

  /// 显示轮次选择器
  void _showRoundPicker(int totalGroups) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.layers_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '跳转到轮次',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '共 $totalGroups 轮',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 轮次列表
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: totalGroups,
                itemBuilder: (context, index) {
                  final isActive = index == _currentVisibleGroup;
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToGroup(index);
                    },
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Q${index + 1}',
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    trailing: isActive
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左侧紫色色条
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: questionColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                      ),
                    ),
                  ),
                  // 问题内容区
                  Expanded(
                    child: Container(
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
                  ),
                ],
              ),
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
    final isLong = userText.length > 200;
    final displayText = isLong ? '${userText.substring(0, 200)}...' : userText;
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI 讨论
        _buildIconOnlyButton(
          icon: Icons.chat_bubble_outline,
          tooltip: 'AI 讨论',
          color: const Color(0xFF8B5CF6),
          onPressed: () => _openAnalysisChat(groupIndex),
        ),
        // TTS 朗读
        Consumer<TtsProvider>(
          builder: (context, tts, _) {
            if (!tts.hasValidConfig) return const SizedBox.shrink();
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

  /// 简洁布局：回复内容区域（流式布局）
  Widget _buildCleanReplyContent(int groupIndex, List<dynamic> assistantReplies, bool isSingleCard) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 单回复模式 - 直接展示，不需要 Tab
    if (isSingleCard) {
      final reply = assistantReplies.first as Map<String, dynamic>;
      return _buildStreamReplyItem(
        reply: reply,
        groupIndex: groupIndex,
        isDark: isDark,
        showDivider: false,
      );
    }

    final aiAnalysisCount = _aiAnalyses[groupIndex]?.length ?? 0;
    final currentPage = _cardPageIndexes[groupIndex] ?? 0;

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
      cardInfoList.add({
        'type': 'assistant',
        'name': modelName,
        'index': aiAnalysisCount + i,
        'data': reply,
      });
    }

    final startIdx = currentPage * _columnsPerView;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 顶部：模型选择器（简洁线条风格）
        _buildStreamModelSelector(
          cardInfoList: cardInfoList,
          currentPage: currentPage,
          groupIndex: groupIndex,
          isDark: isDark,
        ),

        // 分隔线
        Container(
          height: 1,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
        ),

        // 内容区域 - 流式布局，自然撑开
        _buildStreamReplyArea(
          cardInfoList: cardInfoList,
          startIdx: startIdx,
          groupIndex: groupIndex,
          assistantReplies: assistantReplies,
          isDark: isDark,
        ),
      ],
    );
  }

  /// 流式布局：模型选择器（简洁线条风格）
  Widget _buildStreamModelSelector({
    required List<Map<String, dynamic>> cardInfoList,
    required int currentPage,
    required int groupIndex,
    required bool isDark,
  }) {
    final startIdx = currentPage * _columnsPerView;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Row(
        children: [
          // 模型选择器（横向滚动）
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: cardInfoList.asMap().entries.map((entry) {
                  final cardIndex = entry.key;
                  final info = entry.value;
                  final isSelected = cardIndex >= startIdx && cardIndex < startIdx + _columnsPerView;
                  final targetPage = cardIndex ~/ _columnsPerView;

                  return _buildStreamModelTab(
                    modelName: info['name'] as String,
                    isSelected: isSelected,
                    isAnalysis: info['type'] == 'analysis',
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        _cardPageIndexes[groupIndex] = targetPage;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          // 操作按钮
          _buildCleanActionButtons(groupIndex),
        ],
      ),
    );
  }

  /// 流式布局：单个模型 Tab（更简洁）
  Widget _buildStreamModelTab({
    required String modelName,
    required bool isSelected,
    required bool isDark,
    bool isAnalysis = false,
    VoidCallback? onTap,
  }) {
    final baseColor = isAnalysis ? const Color(0xFF10B981) : _getModelColor(modelName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? baseColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          modelName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? baseColor
                : (isDark ? Colors.grey[500] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  /// 流式布局：回复内容区域
  Widget _buildStreamReplyArea({
    required List<Map<String, dynamic>> cardInfoList,
    required int startIdx,
    required int groupIndex,
    required List<dynamic> assistantReplies,
    required bool isDark,
  }) {
    // 获取当前选中的卡片信息
    if (startIdx >= cardInfoList.length) return const SizedBox.shrink();

    final currentInfo = cardInfoList[startIdx];
    final isAnalysis = currentInfo['type'] == 'analysis';

    if (isAnalysis) {
      // AI 分析内容
      final analysisIndex = currentInfo['index'] as int;
      final analyses = _aiAnalyses[groupIndex] ?? [];
      if (analysisIndex >= analyses.length) return const SizedBox.shrink();

      return _buildStreamAnalysisItem(
        content: analyses[analysisIndex],
        groupIndex: groupIndex,
        analysisIndex: analysisIndex,
        isDark: isDark,
      );
    } else {
      // 助手回复
      final reply = currentInfo['data'] as Map<String, dynamic>;
      return _buildStreamReplyItem(
        reply: reply,
        groupIndex: groupIndex,
        isDark: isDark,
        showDivider: false,
      );
    }
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

    // 提取内容
    final blocks = reply['blocks'] as List<dynamic>? ?? [];
    String content = '';
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        content += block['content'] as String? ?? '';
      }
    }

    return Container(
      color: modelColor.withValues(alpha: isDark ? 0.04 : 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighlightableCard.assistant(
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
              showSpeak: Provider.of<TtsProvider>(context, listen: false).hasValidConfig,
              onSpeak: () => _speakContent(content, modelName),
            ),
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
          // 操作栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: MessageActionBar(
              content: content,
              messageId: 'ai_${groupIndex}_$analysisIndex',
              modelName: 'AI 分析',
              showRegenerate: false,
              showSpeak: Provider.of<TtsProvider>(context, listen: false).hasValidConfig,
              onSpeak: () => _speakContent(content, 'AI 分析'),
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

    // 提取内容
    final blocks = reply['blocks'] as List<dynamic>? ?? [];
    String content = '';
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        content += block['content'] as String? ?? '';
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

    // 创建消息组分析对话（不发送 initialPrompt，让用户在编辑器中确认后发送）
    final conversationService = UnifiedConversationService.instance;
    final conversationId = await conversationService.createMessageGroupAnalysis(
      topicId: widget.topicId,
      groupIndex: groupIndex,
      contextSnapshot: contextSnapshot,
      initialPrompt: null, // ← 不自动发送
    );

    // 跳转到 AI 对话界面
    if (mounted) {
      final contextId = '${widget.topicId}:$groupIndex';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIChatScreen(
            initialConversationId: conversationId,
            initialContextId: contextId,
            initialContextSnapshot: contextSnapshot,
            initialContextData: contextData, // ← 传递原始数据
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

    return {
      'rounds': rounds,
      'currentRoundIndex': currentGroupIndex, // 当前轮次索引
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
    final assistantReplies = group['assistant_replies'] as List<dynamic>;
    
    if (assistantReplies.isEmpty) return;

    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    final items = <TtsItem>[];

    // Add AI Analyses if any
    final analyses = _aiAnalyses[groupIndex] ?? [];
    for (var i = 0; i < analyses.length; i++) {
      items.add(TtsItem(
        id: 'analysis_${groupIndex}_$i',
        text: analyses[i],
        title: 'AI 分析 ${i + 1}',
        author: 'Cherry Assistant',
      ));
    }

    // Add Assistant Replies
    for (var i = 0; i < assistantReplies.length; i++) {
      final reply = assistantReplies[i] as Map<String, dynamic>;
      final model = reply['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Assistant';
      
      final blocks = reply['blocks'] as List<dynamic>? ?? [];
      var content = '';
      for (final block in blocks) {
        if (block is Map<String, dynamic> && block['type'] == 'main_text') {
          content += block['content'] as String? ?? '';
        }
      }

      if (content.isNotEmpty) {
        items.add(TtsItem(
          id: reply['id'] ?? 'reply_${groupIndex}_$i',
          text: content,
          title: '回复 ${i + 1}',
          author: modelName,
        ));
      }
    }

    if (items.isNotEmpty) {
      ttsProvider.setPlaylist(items);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('开始朗读...')),
      );
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
                    _expanded ? '双击收起' : '双击展开',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
