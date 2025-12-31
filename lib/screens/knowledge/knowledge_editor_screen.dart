import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../models/knowledge_item.dart';
import '../../models/isar/knowledge_entry.dart';
import '../../services/knowledge_service.dart';

/// 统一知识编辑器
///
/// 支持编辑笔记和标注
/// - 笔记：富文本编辑
/// - 标注：引用原文预览 + 评论编辑
class KnowledgeEditorScreen extends StatefulWidget {
  /// 编辑现有知识项
  final KnowledgeItem? item;

  /// 创建模式时的类型（默认笔记）
  final KnowledgeType? createType;

  /// 来源上下文（创建时使用）
  final Map<String, dynamic>? sourceContext;

  const KnowledgeEditorScreen({
    super.key,
    this.item,
    this.createType,
    this.sourceContext,
  });

  @override
  State<KnowledgeEditorScreen> createState() => _KnowledgeEditorScreenState();
}

class _KnowledgeEditorScreenState extends State<KnowledgeEditorScreen> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final KnowledgeService _knowledgeService = KnowledgeService();

  bool _isLoading = false;
  bool _hasChanges = false;
  String? _itemId;
  late KnowledgeType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.item?.type ?? widget.createType ?? KnowledgeType.note;
    _itemId = widget.item?.id;
    _initController();
  }

  void _initController() {
    if (widget.item != null) {
      // 编辑现有项
      if (_type == KnowledgeType.note) {
        // 笔记：尝试加载富文本
        final entry = widget.item!.originalEntry;
        if (entry != null && entry.content != null) {
          try {
            final doc = Document.fromJson(jsonDecode(entry.content!));
            _controller = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
          } catch (_) {
            _controller = QuillController(
              document: Document()..insert(0, widget.item!.content),
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
        } else {
          _controller = QuillController(
            document: Document()..insert(0, widget.item!.content),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } else {
        // 标注：加载评论内容
        _controller = QuillController(
          document: Document()..insert(0, widget.item!.content),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      // 新建
      _controller = QuillController.basic();
    }

    _controller.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getPlainText() {
    return _controller.document.toPlainText().trim();
  }

  String _getDeltaJson() {
    return jsonEncode(_controller.document.toDelta().toJson());
  }

  Future<void> _save() async {
    final plainText = _getPlainText();
    if (plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容不能为空')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_type == KnowledgeType.note) {
        await _saveNote(plainText);
      } else if (_type == KnowledgeType.annotation) {
        await _saveAnnotation(plainText);
      }

      setState(() {
        _hasChanges = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _saveNote(String plainText) async {
    final content = _getDeltaJson();
    final tags = KnowledgeEntry.extractTags(plainText);

    if (_itemId != null) {
      await _knowledgeService.updateNoteContent(
        entryId: _itemId!,
        content: content,
        plainText: plainText,
        tags: tags,
      );
    } else {
      final entry = await _knowledgeService.createNote(
        content: content,
        contentType: 'delta',
        plainText: plainText,
        tags: tags,
      );
      _itemId = entry.entryId;
    }
  }

  Future<void> _saveAnnotation(String plainText) async {
    final tags = KnowledgeEntry.extractTags(plainText);

    if (_itemId != null) {
      await _knowledgeService.updateComment(
        entryId: _itemId!,
        comment: plainText,
        tags: tags,
      );
    }
    // 新建标注应该通过 QuickCaptureSheet，不在这里处理
  }

  Future<void> _delete() async {
    if (_itemId == null) {
      Navigator.pop(context);
      return;
    }

    final typeName = _type == KnowledgeType.note ? '笔记' : '标注';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除$typeName'),
        content: Text('确定要删除这条$typeName吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && _itemId != null) {
      await _knowledgeService.deleteItem(widget.item!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('是否保存更改？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == 0) return true;
    if (result == 2) {
      await _save();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _itemId != null;
    final typeName = _type == KnowledgeType.note ? '笔记' : '标注';

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? '编辑$typeName' : '新建$typeName'),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
                tooltip: '删除',
              ),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: _isLoading ? null : _save,
              tooltip: '保存',
            ),
          ],
        ),
        body: Column(
          children: [
            // 标注模式：显示引用原文
            if (_type == KnowledgeType.annotation && widget.item != null)
              _buildQuotedTextPreview(context),

            // 来源上下文预览
            if (widget.item?.hasSource == true) _buildSourcePreview(context),

            // 编辑器
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuillEditor(
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  controller: _controller,
                  config: QuillEditorConfig(
                    placeholder: _type == KnowledgeType.note
                        ? '写点什么...'
                        : '添加你的想法...',
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            // 工具栏（仅笔记模式显示完整工具栏）
            if (_type == KnowledgeType.note) _buildToolbar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotedTextPreview(BuildContext context) {
    final theme = Theme.of(context);
    final quotedText = widget.item?.quotedText ?? '';
    if (quotedText.isEmpty) return const SizedBox.shrink();

    final color = widget.item?.highlightColor != null
        ? Color(widget.item!.highlightColor!)
        : const Color(0xFF81D4FA);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                '引用原文',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quotedText,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePreview(BuildContext context) {
    final theme = Theme.of(context);
    final topicName = widget.item?.sourceTopicName;

    if (topicName == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '来自《$topicName》',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: QuillSimpleToolbar(
          controller: _controller,
          config: const QuillSimpleToolbarConfig(
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: false,
            showStrikeThrough: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showClearFormat: false,
            showAlignmentButtons: false,
            showHeaderStyle: false,
            showListNumbers: true,
            showListBullets: true,
            showListCheck: false,
            showCodeBlock: false,
            showQuote: true,
            showIndent: false,
            showLink: true,
            showUndo: true,
            showRedo: true,
            showSearchButton: false,
            showSubscript: false,
            showSuperscript: false,
            showSmallButton: false,
            showInlineCode: false,
            showDirection: false,
            showFontFamily: false,
            showFontSize: false,
            showDividers: false,
            multiRowsDisplay: false,
          ),
        ),
      ),
    );
  }
}
