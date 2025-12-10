import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../models/highlight_data.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../services/highlight_service.dart';
import '../services/unified_conversation_service.dart';
import '../screens/fullscreen_reader_screen.dart';
import '../screens/ai_chat_screen.dart';
import 'unified_markdown_renderer.dart';
import 'highlight_style_menu.dart';
import '../providers/tts_provider.dart';
import '../models/tts_item.dart';

/// 统一的可高亮卡片组件
///
/// 整合了所有卡片类型的共同逻辑：
/// - 标注加载/保存（使用 HighlightService）
/// - Markdown 渲染（使用 UnifiedMarkdownRenderer）
/// - 全屏阅读（导航到 FullscreenReaderScreen）
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

  /// 模型名称（用于全屏阅读显示）
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
  }) {
    final blocks = data['blocks'] as List<dynamic>? ?? [];
    final model = data['model'] as Map<String, dynamic>?;
    final modelName = model?['name'] as String? ?? 'Unknown Model';
    final messageId = data['id'] as String? ?? '';
    final timestamp = data['created_at'] as String? ?? '';

    // 提取纯文本内容
    String plainContent = '';
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        plainContent += block['content'] as String? ?? '';
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
    );
  }

  /// 创建 AI 分析卡片
  factory HighlightableCard.aiAnalysis({Key? key, required String content}) {
    final messageId = 'ai_analysis_${content.hashCode}';

    return HighlightableCard(
      key: key,
      messageId: messageId,
      content: content,
      modelName: 'AI 元分析',
      modelColor: const Color(0xFF8B5CF6),
      cardType: CardType.aiAnalysis,
      showTimestamp: false,
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

  Color get _currentHighlightColor =>
      kHighlightStyles[_currentStyleIndex].color;
  String get _currentHighlightType => kHighlightStyles[_currentStyleIndex].type;

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
    // 【优化】使用 highlights 长度作为快速检查
    final highlightsHash = _highlights.length;

    // 检查是否需要重新渲染
    final needsRebuild =
        _cachedMarkdownWidget == null ||
        _lastRenderedContent != widget.content ||
        _lastRenderedHighlightsHash != highlightsHash;

    if (needsRebuild) {
      _cachedMarkdownWidget = UnifiedMarkdownRenderer(
        data: widget.content,
        scrollable: false,
        selectable: true,
        highlights: _highlights
            .map(
              (h) => HighlightRange(
                id: h.id,
                start: h.start,
                end: h.end,
                color: Color(h.color),
                styleType: h.styleType,
              ),
            )
            .toList(),
        onHighlightTap: (id, details) {
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

      _lastRenderedContent = widget.content;
      _lastRenderedHighlightsHash = highlightsHash;
    }

    return _cachedMarkdownWidget!;
  }

  void _addHighlightFromSelection(String text, int start, int end) {
    final highlight = HighlightData(
      text: text,
      start: start,
      end: end,
      color: _currentHighlightColor.value,
      styleType: _currentHighlightType,
    );

    _highlightService.addHighlight(widget.messageId, highlight).then((
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

  Future<void> _openFullscreen() async {
    debugPrint(
      '[HighlightableCard] Navigating to fullscreen with messageId: ${widget.messageId}',
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenReaderScreen(
          content: widget.content,
          modelName: widget.modelName,
          messageId: widget.messageId,
          backgroundColor: widget.modelColor, // 传递模型颜色
        ),
      ),
    );
    // 从全屏返回后，强制刷新标注
    debugPrint(
      '[HighlightableCard] Returned from fullscreen, reloading highlights...',
    );
    final highlights = await _highlightService.reloadHighlights(
      widget.messageId,
    );
    if (mounted) {
      setState(() {
        _highlights = highlights;
        // 高亮变化时清除 Markdown 缓存
        _cachedMarkdownWidget = null;
      });
    }
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
      onDoubleTap: _openFullscreen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            _buildStreamHeader(),
            const SizedBox(height: 8),
            // 内容（自然撑开）
            _buildContent(),
            // 标注标签
            if (_highlights.isNotEmpty) _buildHighlightTags(),
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
        // 全屏阅读提示
        GestureDetector(
          onTap: _openFullscreen,
          child: Icon(
            Icons.fullscreen_rounded,
            size: 18,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  /// 传统卡片布局
  Widget _buildCardLayout() {
    return GestureDetector(
      onDoubleTap: _openFullscreen,
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
          _buildHeader(),
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
                        // 标注标签
                        if (_highlights.isNotEmpty) _buildHighlightTags(),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContent(),
                    if (_highlights.isNotEmpty) _buildHighlightTags(),
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
    // 讨论按钮颜色：有讨论时紫色，无讨论时灰色
    final discussionColor = _discussionCount > 0
        ? const Color(0xFF8B5CF6)  // 紫色
        : Colors.grey[400]!;

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

        // TTS 朗读按钮
        // 【性能优化】使用 Selector 只监听 hasValidConfig，避免 TTS 状态变化时重建
        Selector<TtsProvider, bool>(
          selector: (_, tts) => tts.hasValidConfig,
          builder: (context, hasValidConfig, _) {
            if (!hasValidConfig) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () {
                final tts = Provider.of<TtsProvider>(context, listen: false);
                final item = TtsItem(
                  id: widget.messageId,
                  text: widget.content,
                  title: widget.modelName,
                  author: widget.modelName,
                );
                tts.setPlaylist([item]);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('开始朗读...'), duration: Duration(seconds: 1)),
                );
              },
              child: Icon(Icons.volume_up_rounded, size: 16, color: Colors.grey[400]),
            );
          },
        ),
        // 间距
        const SizedBox(width: 10),
        // 讨论按钮（带数量角标）
        GestureDetector(
          onTap: _showDiscussionSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                _discussionCount > 0
                    ? Icons.chat_bubble  // 有讨论时实心
                    : Icons.chat_bubble_outline,  // 无讨论时空心
                size: 16,
                color: discussionColor,
              ),
              // 数量角标（仅当数量 > 0 时显示）
              if (_discussionCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_discussionCount',
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
      ],
    );
  }

  Widget _buildContent() {
    return SelectionArea(
      onSelectionChanged: (selection) {
        if (selection != null && selection.plainText.isNotEmpty) {
          if (_selectedText == selection.plainText) return;

          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedText = selection.plainText;
                final start = widget.content.indexOf(_selectedText);
                if (start != -1) {
                  _selectionStart = start;
                  _selectionEnd = start + _selectedText.length;
                }
              });
            }
          });
        }
      },
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
              },
              type: ContextMenuButtonType.custom,
              label: '📌 高亮',
            ),
            ...buttonItems,
          ],
        );
      },
      // 【性能优化】使用 memoized Markdown widget
      child: _getMemoizedMarkdownWidget(),
    );
  }

  Widget _buildHighlightTags() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _highlights.map((h) {
          final color = Color(h.color);
          return GestureDetector(
            onTap: () => _showHighlightMenu(h),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    h.text.length > 20
                        ? '${h.text.substring(0, 20)}...'
                        : h.text,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
