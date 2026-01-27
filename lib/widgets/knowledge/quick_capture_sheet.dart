import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';
import '../../services/knowledge_service.dart';
import '../highlight_style_menu.dart';

/// 快速记录弹窗
///
/// 底部弹窗形式，从对话页面调起
/// 用于快速创建高亮、标注或笔记
class QuickCaptureSheet extends StatefulWidget {
  /// 选中的文本（高亮/标注必需）
  final String? selectedText;

  /// 选中文本的起始位置
  final int? selectionStart;

  /// 选中文本的结束位置
  final int? selectionEnd;

  /// 来源消息 ID
  final String? messageId;

  /// 来源话题 ID
  final String? topicId;

  /// 来源话题名称
  final String? topicName;

  /// 初始类型（默认根据是否有选中文本决定）
  final KnowledgeType? initialType;

  /// 创建完成回调
  final VoidCallback? onCreated;

  const QuickCaptureSheet({
    super.key,
    this.selectedText,
    this.selectionStart,
    this.selectionEnd,
    this.messageId,
    this.topicId,
    this.topicName,
    this.initialType,
    this.onCreated,
  });

  /// 显示快速记录弹窗
  static Future<void> show({
    required BuildContext context,
    String? selectedText,
    int? selectionStart,
    int? selectionEnd,
    String? messageId,
    String? topicId,
    String? topicName,
    KnowledgeType? initialType,
    VoidCallback? onCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickCaptureSheet(
        selectedText: selectedText,
        selectionStart: selectionStart,
        selectionEnd: selectionEnd,
        messageId: messageId,
        topicId: topicId,
        topicName: topicName,
        initialType: initialType,
        onCreated: onCreated,
      ),
    );
  }

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  late KnowledgeType _selectedType;
  late int _selectedColor;
  late String _selectedStyleType;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSaving = false;

  final KnowledgeService _knowledgeService = KnowledgeService();

  @override
  void initState() {
    super.initState();
    // 根据是否有选中文本决定默认类型
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    } else if (widget.selectedText != null && widget.selectedText!.isNotEmpty) {
      _selectedType = KnowledgeType.highlight;
    } else {
      _selectedType = KnowledgeType.note;
    }
    // 默认黄色背景
    _selectedColor = kHighlightStyles.first.color.value;
    _selectedStyleType = kHighlightStyles.first.type;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动条
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                '快速记录',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 类型选择
            _buildTypeSelector(context),
            const SizedBox(height: 16),
            // 选中文本预览（高亮/标注模式）
            if (_selectedType != KnowledgeType.note &&
                widget.selectedText != null &&
                widget.selectedText!.isNotEmpty) ...[
              _buildSelectedTextPreview(context),
              const SizedBox(height: 16),
            ],
            // 颜色选择（高亮/标注模式）
            if (_selectedType != KnowledgeType.note) ...[
              _buildColorSelector(context),
              const SizedBox(height: 16),
            ],
            // 评论输入（标注/笔记模式）
            if (_selectedType != KnowledgeType.highlight) ...[
              _buildCommentInput(context),
              const SizedBox(height: 16),
            ],
            // 操作按钮
            _buildActionButtons(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 类型选择器
  Widget _buildTypeSelector(BuildContext context) {
    final hasSelectedText =
        widget.selectedText != null && widget.selectedText!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        children: [
          // 高亮（需要选中文本）
          if (hasSelectedText)
            ChoiceChip(
              label: const Text('笔记'),
              avatar: Icon(
                Icons.highlight,
                size: 18,
                color: _selectedType == KnowledgeType.highlight
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : const Color(0xFFFFF176),
              ),
              selected: _selectedType == KnowledgeType.highlight,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = KnowledgeType.highlight);
                }
              },
            ),
          // 标注（需要选中文本）
          if (hasSelectedText)
            ChoiceChip(
              label: const Text('标注'),
              avatar: Icon(
                Icons.mode_comment_outlined,
                size: 18,
                color: _selectedType == KnowledgeType.annotation
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : const Color(0xFF81D4FA),
              ),
              selected: _selectedType == KnowledgeType.annotation,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = KnowledgeType.annotation);
                  // 自动聚焦评论输入框
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _commentFocusNode.requestFocus();
                  });
                }
              },
            ),
          // 笔记（始终可用）
          ChoiceChip(
            label: const Text('笔记'),
            avatar: Icon(
              Icons.edit_note,
              size: 18,
              color: _selectedType == KnowledgeType.note
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : const Color(0xFFCE93D8),
            ),
            selected: _selectedType == KnowledgeType.note,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedType = KnowledgeType.note);
                // 自动聚焦评论输入框
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _commentFocusNode.requestFocus();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// 选中文本预览
  Widget _buildSelectedTextPreview(BuildContext context) {
    final theme = Theme.of(context);
    final previewColor = Color(_selectedColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: previewColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: previewColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 引用标签
              Row(
                children: [
                  Icon(Icons.format_quote_rounded, size: 14, color: previewColor),
                  const SizedBox(width: 4),
                  Text(
                    '选中内容',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: previewColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.selectedText!,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 颜色选择器
  Widget _buildColorSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '颜色',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: kHighlightStyles.map((style) {
              final isSelected = _selectedColor == style.color.value &&
                  _selectedStyleType == style.type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = style.color.value;
                    _selectedStyleType = style.type;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: style.type == 'background'
                        ? style.color
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : (style.type == 'underline'
                              ? style.color.withOpacity(0.6)
                              : Colors.transparent),
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: style.type == 'background'
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          size: 20,
                        )
                      : (style.type == 'underline'
                          ? Center(
                              child: Container(
                                width: 16,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: style.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            )
                          : null),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 评论输入框
  Widget _buildCommentInput(BuildContext context) {
    final theme = Theme.of(context);
    final hintText = _selectedType == KnowledgeType.note
        ? '写下你的想法...'
        : '添加评论（可选）...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _commentController,
        focusNode: _commentFocusNode,
        maxLines: 4,
        minLines: 2,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
          height: 1.5,
        ),
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(_getButtonLabel()),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonLabel() {
    switch (_selectedType) {
      case KnowledgeType.highlight:
        return '添加笔记';
      case KnowledgeType.annotation:
        return '添加标注';
      case KnowledgeType.note:
        return '保存笔记';
    }
  }

  Future<void> _handleSave() async {
    // 验证输入
    if (_selectedType == KnowledgeType.note &&
        _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入笔记内容')),
      );
      return;
    }

    if (_selectedType != KnowledgeType.note &&
        (widget.selectedText == null || widget.selectedText!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择文本')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      switch (_selectedType) {
        case KnowledgeType.highlight:
          await _knowledgeService.createHighlight(
            messageId: widget.messageId ?? '',
            quotedText: widget.selectedText!,
            start: widget.selectionStart ?? 0,
            end: widget.selectionEnd ?? widget.selectedText!.length,
            color: _selectedColor,
            styleType: _selectedStyleType,
            topicId: widget.topicId,
            topicName: widget.topicName,
          );
          break;

        case KnowledgeType.annotation:
          await _knowledgeService.createAnnotation(
            messageId: widget.messageId ?? '',
            quotedText: widget.selectedText!,
            start: widget.selectionStart ?? 0,
            end: widget.selectionEnd ?? widget.selectedText!.length,
            color: _selectedColor,
            comment: _commentController.text.trim(),
            styleType: _selectedStyleType,
            topicId: widget.topicId,
            topicName: widget.topicName,
          );
          break;

        case KnowledgeType.note:
          await _knowledgeService.createNote(
            content: _commentController.text.trim(),
            plainText: _commentController.text.trim(),
            messageId: widget.messageId,
            start: widget.selectionStart,
            end: widget.selectionEnd,
            topicId: widget.topicId,
            topicName: widget.topicName,
          );
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedType == KnowledgeType.highlight ? '笔记' : _selectedType == KnowledgeType.annotation ? '标注' : '笔记'}已保存'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
