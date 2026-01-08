import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/highlight_data.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../services/highlight_service.dart';
import '../services/unified_conversation_service.dart';
import '../screens/ai_chat_screen.dart';
import 'unified_markdown_renderer.dart';
import 'highlight_style_menu.dart';
import 'knowledge/quick_capture_sheet.dart';
import 'floating_selection_toolbar.dart';
import 'package:flutter/services.dart';

/// 统一的可高亮卡片组件
///
/// 整合了所有卡片类型的共同逻辑：
/// - 标注加载/保存（使用 HighlightService）
/// - Markdown 渲染（使用 UnifiedMarkdownRenderer）
/// - 文本选择和高亮标注
///
/// 使用方式：
/// ```dart
/// HighlightableCard(
///   messageId: 'xxx',
///   content: 'Markdown 内容',
///   header: HeaderWidget(), // 可选的头部
///   cardType: CardType.assistant,
/// )
/// ```
class HighlightableCard extends StatefulWidget {
  /// 消息 ID，用于标注存储的 key
  final String messageId;

  /// Markdown 内容
  final String content;

  /// 卡片类型（影响样式）
  final CardType cardType;

  /// 自定义头部组件
  final Widget? header;

  /// 模型名称
  final String modelName;

  /// 模型颜色
  final Color modelColor;

  /// 是否显示时间戳
  final bool showTimestamp;

  /// 时间戳
  final String? timestamp;

  /// 卡片最大高度（超出滚动），设为 null 则自然撑开
  final double? maxHeight;

  /// 是否使用流式布局（无边框、自然撑开）
  final bool streamLayout;

  /// 自定义底部操作栏
  final Widget? actionBar;

  /// 讨论回调
  final VoidCallback? onDiscuss;

  /// 重新生成回调
  final VoidCallback? onRegenerate;

  /// 朗读回调
  final VoidCallback? onSpeak;

  /// 【可选】是否启用长文本折叠功能（默认关闭）
  final bool enableCollapse;

  // 可选的上下文参数
  final String? topicId;
  final int? roundIndex;
  final Map<String, dynamic>? contextData;

  /// 【搜索高亮】要高亮的搜索关键词（忽略大小写）
  final String? searchKeyword;

  const HighlightableCard({
    super.key,
    required this.messageId,
    required this.content,
    required this.modelName,
    this.cardType = CardType.assistant,
    this.header,
    this.modelColor = Colors.blue,
    this.showTimestamp = false,
    this.timestamp,
    this.maxHeight = 600,
    this.streamLayout = false,
    this.actionBar,
    this.onDiscuss,
    this.onRegenerate,
    this.onSpeak,
    this.enableCollapse = false,
    this.topicId,
    this.roundIndex,
    this.contextData,
    this.searchKeyword,
  });

  /// 创建助手回复卡片
  factory HighlightableCard.assistant({
    Key? key,
    required Map<String, dynamic> data,
    bool streamLayout = false,
    double? maxHeight = 600,
    Widget? actionBar,
    VoidCallback? onDiscuss,
    VoidCallback? onRegenerate,
    VoidCallback? onSpeak,
    bool enableCollapse = false,
    // 可选的上下文参数
    String? topicId,
    int? roundIndex,
    Map<String, dynamic>? contextData,
    String? searchKeyword,
  }) {
    final blocks = data['blocks'] as List<dynamic>? ?? [];
    final model = data['model'] as Map<String, dynamic>?;
    final modelName = model?['name'] as String? ?? 'Unknown Model';
    final messageId = data['id'] as String? ?? '';
    final timestamp = data['created_at'] as String? ?? '';

    // 提取纯文本内容
    // 按照 block 在列表中的顺序拼接（TopicService 已按 orderIndex 排序）
    String plainContent = '';
    // 支持的文本块类型
    final textBlockTypes = ['main_text', 'thinking', 'translation', 'code', 'error', 'text'];

    for (final block in blocks) {
      if (block is Map<String, dynamic> && textBlockTypes.contains(block['type'])) {
        final content = block['content'] as String? ?? '';
        plainContent += content;
      }
    }

    return HighlightableCard(
      key: key,
      messageId: messageId,
      content: plainContent,
      modelName: modelName,
      modelColor: _getModelColor(modelName),
      cardType: CardType.assistant,
      showTimestamp: true,
      timestamp: timestamp,
      streamLayout: streamLayout,
      maxHeight: maxHeight,
      actionBar: actionBar,
      onDiscuss: onDiscuss,
      onRegenerate: onRegenerate,
      onSpeak: onSpeak,
      enableCollapse: enableCollapse,
      topicId: topicId,
      roundIndex: roundIndex,
      contextData: contextData,
      searchKeyword: searchKeyword,
    );
  }

  /// 创建 AI 分析卡片
  factory HighlightableCard.aiAnalysis({
    Key? key,
    required String content,
    bool enableCollapse = false,
  }) {
    final messageId = 'ai_analysis_${content.hashCode}';

    return HighlightableCard(
      key: key,
      messageId: messageId,
      content: content,
      modelName: 'AI 元分析',
      modelColor: const Color(0xFF8B5CF6),
      cardType: CardType.aiAnalysis,
      showTimestamp: false,
      enableCollapse: enableCollapse,
    );
  }

  /// 根据模型名称获取颜色
  static Color _getModelColor(String modelName) {
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
    } else if (name.contains('llama') || name.contains('meta')) {
      return const Color(0xFF0668E1);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }

  @override
  State<HighlightableCard> createState() => _HighlightableCardState();
}

/// 卡片类型
enum CardType { assistant, aiAnalysis, user }

class _HighlightableCardState extends State<HighlightableCard> {
  final HighlightService _highlightService = HighlightService();

  List<HighlightData> _highlights = [];
  String _selectedText = '';
  int _selectionStart = 0;
  int _selectionEnd = 0;
  int _currentStyleIndex = 0;

  // 讨论数量
  int _discussionCount = 0;
  // 【性能优化】标记是否已加载过讨论数量，避免重复加载
  bool _discussionCountLoaded = false;

  // 【性能优化】Markdown 渲染缓存（memo 模式）
  Widget? _cachedMarkdownWidget;
  String? _lastRenderedContent;
  int? _lastRenderedHighlightsHash;

  // 【新增】展开/收缩状态
  bool _expanded = false;

  // 折叠阈值（超过此字符数时默认折叠）
  static const int _collapseThreshold = 1000;
  // 折叠时显示的字符数
  static const int _collapsedPreviewLength = 500;

  Color get _currentHighlightColor =>
      kHighlightStyles[_currentStyleIndex].color;
  String get _currentHighlightType => kHighlightStyles[_currentStyleIndex].type;

  // 【新增】判断内容是否需要折叠（仅在启用折叠功能时生效）
  bool get _isLongContent => widget.enableCollapse && widget.content.length > _collapseThreshold;

  // 【新增】获取当前显示的内容
  String get _displayContent {
    if (!_isLongContent || _expanded) {
      return widget.content;
    }
    // 折叠模式：截取前 N 个字符
    return '${widget.content.substring(0, _collapsedPreviewLength)}...';
  }

  // 【新增】切换展开/收缩状态
  void _toggleExpand() {
    if (_isLongContent) {
      setState(() {
        _expanded = !_expanded;
        // 展开/收缩时清除 Markdown 缓存，因为内容变化了
        _cachedMarkdownWidget = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHighlights();
    // 【性能优化】延迟加载讨论数量，不阻塞首次渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_discussionCountLoaded) {
        _loadDiscussionCount();
      }
    });
  }

  Future<void> _loadDiscussionCount() async {
    if (_discussionCountLoaded) return; // 避免重复加载
    _discussionCountLoaded = true;

    final conversations = await UnifiedConversationService.instance
        .getConversationsByContext(widget.messageId);
    if (mounted) {
      setState(() {
        _discussionCount = conversations.length;
      });
    }
  }

  Future<void> _loadHighlights() async {
    final highlights = await _highlightService.loadHighlights(widget.messageId);
    if (mounted) {
      setState(() {
        _highlights = highlights;
        // 高亮变化时清除 Markdown 缓存
        _cachedMarkdownWidget = null;
      });
    }
  }

  /// 【性能优化】获取 memoized Markdown widget
  ///
  /// 只有在 content 或 highlights 变化时才重新创建
  Widget _getMemoizedMarkdownWidget() {
    // 【优化】使用 highlights 长度和搜索关键词作为快速检查
    final highlightsHash = _highlights.length + (widget.searchKeyword?.hashCode ?? 0);
    // 【新增】使用 _displayContent 而不是 widget.content，支持折叠显示
    final currentContent = _displayContent;

    // 检查是否需要重新渲染
    final needsRebuild =
        _cachedMarkdownWidget == null ||
        _lastRenderedContent != currentContent ||
        _lastRenderedHighlightsHash != highlightsHash;

    if (needsRebuild) {
      // 用户手动标注的高亮
      final userHighlights = _highlights
          .where((h) => h.end <= currentContent.length)
          .map(
            (h) => HighlightRange(
              id: h.id,
              start: h.start,
              end: h.end,
              color: Color(h.color),
              styleType: h.styleType,
            ),
          )
          .toList();

      // 【搜索高亮】生成搜索关键词的高亮范围
      final searchHighlights = _generateSearchHighlights(currentContent);

      // 合并高亮（搜索高亮 + 用户高亮）
      final allHighlights = [...searchHighlights, ...userHighlights];

      _cachedMarkdownWidget = UnifiedMarkdownRenderer(
        data: currentContent,
        scrollable: false,
        selectable: true,
        highlights: allHighlights,
        onHighlightTap: (id, details) {
          // 搜索高亮不响应点击
          if (id.startsWith('search_')) return;

          final highlight = _highlights.firstWhere(
            (h) => h.id == id,
            orElse: () => _highlights.first,
          );
          _showHighlightMenu(highlight);
        },
        textStyle: const TextStyle(
          fontSize: 15,
          height: 1.8,
          color: Color(0xFF2C3E50),
          letterSpacing: 0.3,
        ),
      );

      _lastRenderedContent = currentContent;
      _lastRenderedHighlightsHash = highlightsHash;
    }

    return _cachedMarkdownWidget!;
  }

  /// 【搜索高亮】根据搜索关键词生成高亮范围
  List<HighlightRange> _generateSearchHighlights(String content) {
    final keyword = widget.searchKeyword;
    if (keyword == null || keyword.isEmpty) return [];

    final highlights = <HighlightRange>[];
    final lowerContent = content.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    int startIndex = 0;
    int matchCount = 0;

    while (true) {
      final index = lowerContent.indexOf(lowerKeyword, startIndex);
      if (index == -1) break;

      highlights.add(HighlightRange(
        id: 'search_$matchCount',
        start: index,
        end: index + keyword.length,
        color: const Color(0xFFFFEB3B), // 黄色高亮
        styleType: 'background',
      ));

      startIndex = index + keyword.length;
      matchCount++;

      // 限制最多高亮 50 个匹配，避免性能问题
      if (matchCount >= 50) break;
    }

    return highlights;
  }

  void _addHighlightFromSelection(String text, int start, int end) {
    final highlight = HighlightData(
      text: text,
      start: start,
      end: end,
      color: _currentHighlightColor.value,
      styleType: _currentHighlightType,
    );

    _highlightService.addHighlight(
      widget.messageId,
      highlight,
      topicId: widget.topicId,
      topicName: widget.contextData?['topicName'] as String?,
    ).then((
      highlights,
    ) {
      if (mounted) {
        setState(() {
          _highlights = highlights;
          // 高亮变化时清除 Markdown 缓存
          _cachedMarkdownWidget = null;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 已添加高亮'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeHighlight(HighlightData highlight) {
    _highlightService.removeHighlight(widget.messageId, highlight.id).then((
      highlights,
    ) {
      if (mounted) {
        setState(() {
          _highlights = highlights;
          // 高亮变化时清除 Markdown 缓存
          _cachedMarkdownWidget = null;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除高亮'), duration: Duration(seconds: 1)),
    );
  }

  void _updateHighlightStyle(
    HighlightData highlight,
    int newColor,
    String newType,
  ) {
    _highlightService
        .updateHighlightStyle(widget.messageId, highlight.id, newColor, newType)
        .then((highlights) {
          if (mounted) {
            setState(() {
              _highlights = highlights;
              // 高亮变化时清除 Markdown 缓存
              _cachedMarkdownWidget = null;
            });
          }
        });
  }

  void _showHighlightMenu(HighlightData highlight) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final center = Offset(overlay.size.width / 2, overlay.size.height / 2);

    HighlightStyleMenu.show(
      context: context,
      position: center,
      highlightId: highlight.id,
      currentColor: highlight.color,
      currentStyleType: highlight.styleType,
      onStyleChanged: (highlightId, newColor, newType) {
        _updateHighlightStyle(highlight, newColor, newType);
      },
      onDelete: (highlightId) {
        _removeHighlight(highlight);
      },
    );
  }

  /// 显示快速记录弹窗（创建标注）
  void _showQuickCaptureSheet() {
    QuickCaptureSheet.show(
      context: context,
      selectedText: _selectedText,
      selectionStart: _selectionStart,
      selectionEnd: _selectionEnd,
      messageId: widget.messageId,
      topicId: widget.topicId,
      topicName: widget.contextData?['topicName'] as String?,
      onCreated: () {
        // 创建完成后重新加载高亮
        _loadHighlights();
      },
    );
  }


  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoTime.substring(0, 16).replaceAll('T', ' ');
    }
  }

  /// 进入讨论界面（直接进入 AIChatScreen）
  void _showDiscussionSheet() {
    // 构建单回复的 contextData
    final contextData = {
      'rounds': [
        {
          'index': 0,
          'question': null, // 单回复讨论没有问题
          'replies': [
            {
              'id': widget.messageId,
              'model': {'name': widget.modelName},
              'useful': true,
              'blocks': [
                {'type': 'main_text', 'content': widget.content}
              ],
            }
          ],
        }
      ],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          initialContextId: widget.messageId,
          initialContextSnapshot: widget.content,
          initialTitle: '讨论',
          initialContextData: contextData,
          contextTypeFilter: ConversationContextType.singleMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 流式布局模式
    if (widget.streamLayout) {
      return _buildStreamLayout();
    }

    // 传统卡片模式
    return _buildCardLayout();
  }

  /// 流式布局（无边框、自然撑开）
  Widget _buildStreamLayout() {
    return GestureDetector(
      // 双击展开/收缩
      // 双击展开/收缩 - 已移除，移动到 Header 以避免冲突
      // onDoubleTap: widget.enableCollapse ? _toggleExpand : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            GestureDetector(
              onDoubleTap: widget.enableCollapse ? _toggleExpand : null,
              child: _buildStreamHeader(),
            ),
            const SizedBox(height: 8),
            // 内容（自然撑开）
            _buildContent(),
            // 展开/收缩提示
            if (_isLongContent) _buildExpandHint(),
            // 标注标签 - 已移除，避免重复显示 (inline 高亮已足够)
            // if (_highlights.isNotEmpty) _buildHighlightTags(),
            // 操作栏
            if (widget.actionBar != null) ...[
              const SizedBox(height: 4),
              widget.actionBar!,
            ],
          ],
        ),
      ),
    );
  }

  /// 流式布局的头部（更简洁）
  Widget _buildStreamHeader() {
    return Row(
      children: [
        // 时间戳
        if (widget.showTimestamp && widget.timestamp != null)
          Text(
            _formatTime(widget.timestamp!),
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        const Spacer(),
      ],
    );
  }

  /// 传统卡片布局
  Widget _buildCardLayout() {
    return GestureDetector(
      // 双击展开/收缩
      // 双击展开/收缩 - 已移除，移动到 Header 以避免冲突
      // onDoubleTap: widget.enableCollapse ? _toggleExpand : null,
      child: widget.maxHeight != null
          ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxHeight!),
              child: _buildCardContent(),
            )
          : _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    return Container(
      // 背景透明，让父容器的淡色背景显示出来
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部 (固定)
          GestureDetector(
            behavior: HitTestBehavior.opaque, // 确保点击整个头部区域都能触发
            onDoubleTap: widget.enableCollapse ? _toggleExpand : null,
            child: _buildHeader(),
          ),
          const SizedBox(height: 6),
          // 内容 (可滚动)
          widget.maxHeight != null
              ? Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildContent(),
                        // 展开/收缩提示
                        if (_isLongContent) _buildExpandHint(),
                        // 标注标签 - 已移除
                        // if (_highlights.isNotEmpty) _buildHighlightTags(),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContent(),
                    // 展开/收缩提示
                    if (_isLongContent) _buildExpandHint(),
                    // if (_highlights.isNotEmpty) _buildHighlightTags(),
                  ],
                ),
          // 操作栏
          if (widget.actionBar != null) ...[
            const SizedBox(height: 4),
            widget.actionBar!,
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 时间戳（移到左边）
        if (widget.showTimestamp && widget.timestamp != null) ...[
          Text(
            _formatTime(widget.timestamp!),
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
          const Spacer(),
        ],
      ],
    );
  }

  // ... (existing state variables)
  
  // 【新增】浮动工具栏 Overlay
  OverlayEntry? _toolbarOverlay;
  Offset? _lastPointerPosition;

  @override
  void dispose() {
    _hideFloatingToolbar();
    super.dispose();
  }

  void _hideFloatingToolbar() {
    _toolbarOverlay?.remove();
    _toolbarOverlay = null;
  }

  void _showFloatingToolbar(Offset position) {
    _hideFloatingToolbar();

    _toolbarOverlay = OverlayEntry(
      builder: (context) => FloatingSelectionToolbar(
        position: position,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: _selectedText));
          _hideFloatingToolbar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
          );
        },
        onHighlight: () {
          _addHighlightFromSelection(_selectedText, _selectionStart, _selectionEnd);
          _hideFloatingToolbar();
        },
        highlightColor: _currentHighlightColor,
      ),
    );

    Overlay.of(context).insert(_toolbarOverlay!);
  }

  // ...

  Widget _buildContent() {
    return Listener(
      onPointerUp: (event) {
        _lastPointerPosition = event.position;
        // 如果松开鼠标时有选中文本，延迟显示工具栏（确保 selection 状态已更新）
        if (_selectedText.isNotEmpty) {
           // 稍微延迟以避免冲突
           Future.delayed(const Duration(milliseconds: 100), () {
             if (mounted && _selectedText.isNotEmpty) {
               _showFloatingToolbar(event.position);
             }
           });
        }
      },
      // 也可以监听 onPointerDown 隐藏工具栏
      onPointerDown: (_) => _hideFloatingToolbar(),
      child: SelectionArea(
        onSelectionChanged: (selection) {
          if (selection != null) {
            final newSelectedText = selection.plainText;
            if (newSelectedText != _selectedText) {
               // 状态更新逻辑保持不变
               if (newSelectedText.isEmpty) {
                  _hideFloatingToolbar();
               }
               
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedText = newSelectedText;
                      // ... index calculation
                      final start = widget.content.indexOf(_selectedText);
                      if (start != -1) {
                         _selectionStart = start;
                         _selectionEnd = start + _selectedText.length;
                      }
                    });
                  }
                });
            }
          }
        },
        // 保留原有的 contextMenuBuilder 作为备用（右键菜单）
        contextMenuBuilder: (context, selectableRegionState) {
          final buttonItems = selectableRegionState.contextMenuButtonItems;
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: selectableRegionState.contextMenuAnchors,
            buttonItems: [
              ContextMenuButtonItem(
                onPressed: () {
                  if (_selectedText.isNotEmpty) {
                    _addHighlightFromSelection(
                      _selectedText,
                      _selectionStart,
                      _selectionEnd,
                    );
                  }
                  ContextMenuController.removeAny();
                  _hideFloatingToolbar(); 
                },
                type: ContextMenuButtonType.custom,
                label: '高亮',
              ),
              ContextMenuButtonItem(
                onPressed: () {
                  if (_selectedText.isNotEmpty) {
                    ContextMenuController.removeAny();
                    _hideFloatingToolbar();
                    _showQuickCaptureSheet();
                  }
                },
                type: ContextMenuButtonType.custom,
                label: '标注',
              ),
              ...buttonItems,
            ],
          );
        },
        child: _getMemoizedMarkdownWidget(),
      ),
    );
  }

  /// 【新增】构建展开/收缩提示
  Widget _buildExpandHint() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _expanded ? Icons.unfold_less : Icons.unfold_more,
            size: 16,
            color: hintColor,
          ),
          const SizedBox(width: 4),
          Text(
            _expanded ? '双击收起' : '双击展开全文',
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
            ),
          ),
          if (!_expanded) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isDark ? Colors.grey[700] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.content.length} 字',
                style: TextStyle(
                  fontSize: 10,
                  color: hintColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
