import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../widgets/unified_markdown_renderer.dart';
import '../models/highlight_data.dart';
import '../services/highlight_service.dart';
import '../widgets/highlight_list_sheet.dart';
import '../widgets/highlight_style_menu.dart';

/// 全屏阅读页面 - 支持高亮标注
class FullscreenReaderScreen extends StatefulWidget {
  final String content;
  final String modelName;
  final String messageId;

  const FullscreenReaderScreen({
    super.key,
    required this.content,
    required this.modelName,
    required this.messageId,
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9DE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9DE),
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
}
