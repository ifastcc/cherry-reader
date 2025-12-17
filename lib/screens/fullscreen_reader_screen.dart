import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../widgets/unified_markdown_renderer.dart';
import '../models/highlight_data.dart';
import '../services/highlight_service.dart';
import '../widgets/highlight_list_sheet.dart';
import '../widgets/highlight_style_menu.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../models/tts_item.dart';
import '../widgets/tts_mini_player.dart';
import '../screens/ai_chat_screen.dart';
import '../models/isar/unified_conversation_entity.dart';

/// 全屏阅读页面 - 支持高亮标注
class FullscreenReaderScreen extends StatefulWidget {
  final String content;
  final String modelName;
  final String messageId;
  final Color? backgroundColor; // 可选的背景颜色

  // 可选的上下文参数（用于讨论功能）
  final String? topicId;
  final int? roundIndex;
  final Map<String, dynamic>? contextData;

  const FullscreenReaderScreen({
    super.key,
    required this.content,
    required this.modelName,
    required this.messageId,
    this.backgroundColor,
    this.topicId,
    this.roundIndex,
    this.contextData,
  });

  @override
  State<FullscreenReaderScreen> createState() => _FullscreenReaderScreenState();
}

class _FullscreenReaderScreenState extends State<FullscreenReaderScreen> {
  final HighlightService _highlightService = HighlightService();

  List<HighlightData> _highlights = [];
  String _selectedText = '';
  int _selectionStart = 0;
  int _selectionEnd = 0;
  HighlightData? _activeHighlight;
  Offset? _toolbarPosition;
  bool _showColorPicker = false;
  int _currentStyleIndex = 0;

  // 悬浮工具栏展开状态
  bool _fabExpanded = false;

  Color get _currentHighlightColor =>
      kHighlightStyles[_currentStyleIndex].color;
  String get _currentHighlightType => kHighlightStyles[_currentStyleIndex].type;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[FullscreenReader] initState with messageId: ${widget.messageId}',
    );
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

  Future<void> _saveHighlights() async {
    await _highlightService.saveHighlights(widget.messageId, _highlights);
    debugPrint('[FullscreenReader] ✅ Saved ${_highlights.length} highlights');
  }

  void _addHighlight() {
    if (_selectedText.isEmpty) return;

    final highlight = HighlightData(
      text: _selectedText,
      start: _selectionStart,
      end: _selectionEnd,
      color: _currentHighlightColor.value,
      styleType: _currentHighlightType,
    );

    setState(() {
      _highlights.add(highlight);
      _selectedText = '';
      _activeHighlight = highlight;
      _showColorPicker = true;
    });

    _saveHighlights();
  }

  void _removeHighlight(HighlightData highlight) {
    setState(() {
      _highlights.remove(highlight);
    });
    _saveHighlights();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除高亮'), duration: Duration(seconds: 1)),
    );
  }

  void _clearAllHighlights() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有高亮'),
        content: const Text('确定要清除所有高亮标注吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _highlights.clear();
      });
      _saveHighlights();
    }
  }

  void _updateHighlightStyle(
    HighlightData oldHighlight,
    int newColor,
    String newType,
  ) {
    final newHighlight = HighlightData(
      id: oldHighlight.id,
      text: oldHighlight.text,
      start: oldHighlight.start,
      end: oldHighlight.end,
      color: newColor,
      styleType: newType,
      createdAt: oldHighlight.createdAt,
    );

    setState(() {
      final index = _highlights.indexWhere((h) => h.id == oldHighlight.id);
      if (index != -1) {
        _highlights[index] = newHighlight;
      }
    });
    _saveHighlights();
  }

  void _showHighlightMenu(String id, Offset position) {
    final highlight = _highlights.firstWhere(
      (h) => h.id == id,
      orElse: () => throw Exception('Highlight not found'),
    );

    HighlightStyleMenu.show(
      context: context,
      position: position,
      highlightId: id,
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

  void _showHighlightsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return HighlightListSheet(
              highlights: _highlights,
              onDelete: (highlight) {
                Navigator.pop(context);
                _removeHighlight(highlight);
              },
              onTap: (highlight) {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final screenCenter = Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2,
                    );
                    _showHighlightMenu(highlight.id, screenCenter);
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 计算背景色：使用传入的颜色（非常淡）或默认淡黄色
    final bgColor = widget.backgroundColor != null
        ? Color.lerp(Colors.white, widget.backgroundColor!, 0.08)! // 约 8% 的颜色混合
        : const Color(0xFFFAF9DE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.modelName,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          // 高亮颜色选择器
          PopupMenuButton<int>(
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _currentHighlightColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 2),
              ),
            ),
            tooltip: '选择高亮样式',
            onSelected: (index) {
              setState(() {
                _currentStyleIndex = index;
              });
            },
            itemBuilder: (context) =>
                List.generate(kHighlightStyles.length, (index) {
                  final style = kHighlightStyles[index];
                  final color = style.color;
                  final label = style.name;
                  final type = style.type;

                  return PopupMenuItem(
                    value: index,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: type == 'background'
                                ? color
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: _currentStyleIndex == index
                                ? Border.all(color: Colors.white, width: 2)
                                : Border.all(color: Colors.grey, width: 1),
                          ),
                          child: type == 'underline'
                              ? Center(
                                  child: Container(
                                    width: 16,
                                    height: 2,
                                    color: color,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(label),
                      ],
                    ),
                  );
                }),
          ),
          // 高亮列表
          IconButton(
            icon: Badge(
              label: Text('${_highlights.length}'),
              isLabelVisible: _highlights.isNotEmpty,
              child: const Icon(
                Icons.format_list_bulleted,
                color: Colors.black87,
              ),
            ),
            onPressed: _showHighlightsList,
            tooltip: '查看高亮列表',
          ),
          // 清除所有高亮
          if (_highlights.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.black87),
              onPressed: _clearAllHighlights,
              tooltip: '清除所有高亮',
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showColorPicker = false;
                _activeHighlight = null;
                _selectedText = '';
              });
            }
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: SelectionArea(
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
                  final buttonItems =
                      selectableRegionState.contextMenuButtonItems;

                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: selectableRegionState.contextMenuAnchors,
                    buttonItems: [
                      ContextMenuButtonItem(
                        onPressed: () {
                          if (_selectedText.isNotEmpty) {
                            _addHighlight();
                            _showColorPicker = true;
                            setState(() {});
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
                  scrollable: true,
                  largeFont: true,
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
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _showHighlightMenu(id, details.globalPosition);
                      }
                    });
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
              ),
            ),
            // 高亮颜色选择器
            if (_showColorPicker && _toolbarPosition != null)
              _buildStylePicker(),

            // 悬浮操作工具栏
            _buildFloatingToolbar(),

            // 独立的讨论浮动按钮
            _buildDiscussionFab(),

            // Mini Player
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TtsMiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStylePicker() {
    return Positioned(
      left: _toolbarPosition!.dx - 150 > 0 ? _toolbarPosition!.dx - 150 : 16,
      top: _toolbarPosition!.dy + 40,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(kHighlightStyles.length, (index) {
            final style = kHighlightStyles[index];
            final color = style.color;
            final type = style.type;
            final isSelected = _activeHighlight != null
                ? (_activeHighlight!.color == color.value &&
                      _activeHighlight!.styleType == type)
                : _currentStyleIndex == index;

            return GestureDetector(
              onTap: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  setState(() {
                    _currentStyleIndex = index;
                  });

                  if (_activeHighlight != null) {
                    _updateHighlightStyle(_activeHighlight!, color.value, type);
                    final newHighlight = _highlights.firstWhere(
                      (h) => h.id == _activeHighlight!.id,
                    );
                    setState(() {
                      _activeHighlight = newHighlight;
                    });
                  }
                });
              },
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: type == 'background' ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black87, width: 2)
                      : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: type == 'underline'
                    ? Center(
                        child: Container(width: 18, height: 2, color: color),
                      )
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }

  void _playContent() {
    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);

    // Split content by paragraphs to avoid too long text for one request
    // Or just send the whole thing if it's not too huge.
    // Azure has limits. Better to split.
    // Simple split by double newline.
    final paragraphs = widget.content.split(RegExp(r'\n\s*\n'));
    final items = <TtsItem>[];

    for (var i = 0; i < paragraphs.length; i++) {
      final text = paragraphs[i].trim();
      if (text.isNotEmpty) {
        items.add(TtsItem(
          id: '${widget.messageId}_p$i', // Use messageId for caching association
          text: text,
          title: widget.modelName,
          author: 'Paragraph ${i + 1}',
        ));
      }
    }

    if (items.isNotEmpty) {
      ttsProvider.setPlaylist(items);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('开始朗读全文...')),
      );
    }
  }

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// 进入讨论界面
  void _openDiscussion() {
    // 构建 contextData - 如果有传入的 contextData 使用它，否则构建单回复的结构
    final contextData = widget.contextData ?? {
      'rounds': [
        {
          'index': widget.roundIndex ?? 0,
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

    // 确定 contextId - 如果有 topicId 和 roundIndex，使用轮次级别的 ID
    final contextId = (widget.topicId != null && widget.roundIndex != null)
        ? '${widget.topicId}:${widget.roundIndex}'
        : widget.messageId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          initialContextId: contextId,
          initialContextSnapshot: widget.content,
          initialTitle: '讨论: ${widget.modelName}',
          initialContextData: contextData,
          // 如果有轮次信息，使用 messageGroup 类型（支持 context 编辑）
          contextTypeFilter: (widget.topicId != null && widget.roundIndex != null)
              ? ConversationContextType.messageGroup
              : ConversationContextType.singleMessage,
        ),
      ),
    );
  }

  /// 构建独立的讨论浮动按钮
  Widget _buildDiscussionFab() {
    return Positioned(
      left: 16,
      bottom: 80, // 与右边的工具栏对称
      child: GestureDetector(
        onTap: _openDiscussion,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6), // 紫色
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withAlpha(100),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  /// 构建悬浮操作工具栏
  Widget _buildFloatingToolbar() {
    return Consumer<TtsProvider>(
      builder: (context, tts, _) {
        final hasValidTts = tts.hasValidConfig;

        return Positioned(
          right: 16,
          bottom: 80, // 在 TtsMiniPlayer 上方
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 展开的操作按钮
              AnimatedOpacity(
                opacity: _fabExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedSlide(
                  offset: _fabExpanded ? Offset.zero : const Offset(0, 0.5),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: IgnorePointer(
                    ignoring: !_fabExpanded,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 朗读按钮（仅在配置有效时显示）
                        if (hasValidTts) ...[
                          _FloatingActionItem(
                            icon: Icons.volume_up_rounded,
                            label: '朗读',
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              setState(() => _fabExpanded = false);
                              _playContent();
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        // 复制按钮
                        _FloatingActionItem(
                          icon: Icons.copy_rounded,
                          label: '复制',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            setState(() => _fabExpanded = false);
                            _copyContent();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              // 主按钮
              GestureDetector(
                onTap: () {
                  setState(() => _fabExpanded = !_fabExpanded);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _fabExpanded
                        ? Colors.grey[800]
                        : const Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_fabExpanded
                            ? Colors.grey[800]!
                            : const Color(0xFF8B5CF6)).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedRotation(
                    turns: _fabExpanded ? 0.125 : 0, // 45度旋转
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 悬浮操作按钮项
class _FloatingActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FloatingActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 图标按钮
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
