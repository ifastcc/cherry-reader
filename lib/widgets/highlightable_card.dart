import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/highlight_data.dart';
import '../services/highlight_service.dart';
import '../screens/fullscreen_reader_screen.dart';
import 'unified_markdown_renderer.dart';
import 'highlight_style_menu.dart';

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

  /// 卡片最大高度（超出滚动）
  final double maxHeight;

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
  });

  /// 创建助手回复卡片
  factory HighlightableCard.assistant({
    Key? key,
    required Map<String, dynamic> data,
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
    );
  }

  /// 创建 AI 分析卡片
  factory HighlightableCard.aiAnalysis({
    Key? key,
    required String content,
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
enum CardType {
  assistant,
  aiAnalysis,
  user,
}

class _HighlightableCardState extends State<HighlightableCard> {
  final HighlightService _highlightService = HighlightService();

  List<HighlightData> _highlights = [];
  String _selectedText = '';
  int _selectionStart = 0;
  int _selectionEnd = 0;
  int _currentStyleIndex = 0;

  Color get _currentHighlightColor => kHighlightStyles[_currentStyleIndex].color;
  String get _currentHighlightType => kHighlightStyles[_currentStyleIndex].type;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    final highlights = await _highlightService.loadHighlights(widget.messageId);
    if (mounted) {
      setState(() {
        _highlights = highlights;
      });
    }
  }

  void _addHighlightFromSelection(String text, int start, int end) {
    final highlight = HighlightData(
      text: text,
      start: start,
      end: end,
      color: _currentHighlightColor.value,
      styleType: _currentHighlightType,
    );

    _highlightService.addHighlight(widget.messageId, highlight).then((highlights) {
      if (mounted) {
        setState(() {
          _highlights = highlights;
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
    _highlightService.removeHighlight(widget.messageId, highlight.id).then((highlights) {
      if (mounted) {
        setState(() {
          _highlights = highlights;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已删除高亮'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _updateHighlightStyle(HighlightData highlight, int newColor, String newType) {
    _highlightService.updateHighlightStyle(
      widget.messageId,
      highlight.id,
      newColor,
      newType,
    ).then((highlights) {
      if (mounted) {
        setState(() {
          _highlights = highlights;
        });
      }
    });
  }

  void _showHighlightMenu(HighlightData highlight) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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
    debugPrint('[HighlightableCard] Navigating to fullscreen with messageId: ${widget.messageId}');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenReaderScreen(
          content: widget.content,
          modelName: widget.modelName,
          messageId: widget.messageId,
        ),
      ),
    );
    // 从全屏返回后，强制刷新标注
    debugPrint('[HighlightableCard] Returned from fullscreen, reloading highlights...');
    final highlights = await _highlightService.reloadHighlights(widget.messageId);
    if (mounted) {
      setState(() {
        _highlights = highlights;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _openFullscreen,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.modelColor.withValues(alpha: 0.2), width: 1),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 头部
                  _buildHeader(),
                  const SizedBox(height: 12),
                  // 内容
                  _buildContent(),
                  // 标注标签
                  if (_highlights.isNotEmpty) _buildHighlightTags(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final icon = widget.cardType == CardType.aiAnalysis
        ? Icons.auto_awesome
        : Icons.smart_toy;

    return Row(
      children: [
        // 模型图标
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.modelColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.modelColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Icon(icon, size: 13, color: widget.modelColor),
        ),
        const SizedBox(width: 10),
        // 模型名称
        Expanded(
          child: Text(
            widget.modelName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: widget.modelColor,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 全屏阅读按钮
        IconButton(
          icon: Icon(Icons.fullscreen, size: 18, color: Colors.grey[500]),
          onPressed: _openFullscreen,
          tooltip: '全屏阅读',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        // 时间戳
        if (widget.showTimestamp && widget.timestamp != null) ...[
          const SizedBox(width: 8),
          Text(
            _formatTime(widget.timestamp!),
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
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
                  _addHighlightFromSelection(_selectedText, _selectionStart, _selectionEnd);
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
      child: UnifiedMarkdownRenderer(
        data: widget.content,
        scrollable: false,
        selectable: true,
        highlights: _highlights.map((h) => HighlightRange(
          id: h.id,
          start: h.start,
          end: h.end,
          color: Color(h.color),
          styleType: h.styleType,
        )).toList(),
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
      ),
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
                    h.text.length > 20 ? '${h.text.substring(0, 20)}...' : h.text,
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
