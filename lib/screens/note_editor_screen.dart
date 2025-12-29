import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/isar/note_entity.dart';
import '../services/note_service.dart';

/// 笔记编辑器页面
///
/// 支持：
/// - 创建新笔记
/// - 编辑现有笔记
/// - 从高亮/消息创建笔记（带上下文预览）
/// - 富文本编辑（粗体、斜体、列表、链接等）
/// - 自动提取标签
class NoteEditorScreen extends StatefulWidget {
  /// 编辑现有笔记时传入
  final NoteEntity? existingNote;

  /// 从高亮创建时的初始内容
  final String? initialContent;

  /// 来源信息（用于显示上下文预览）
  final Map<String, dynamic>? sourceContext;

  /// 来源类型：'highlight', 'message', 或 null（手动创建）
  final String? sourceType;

  /// 关联的高亮 ID
  final String? highlightId;

  /// 关联的消息 ID
  final String? messageId;

  /// 关联的话题 ID
  final String? topicId;

  const NoteEditorScreen({
    super.key,
    this.existingNote,
    this.initialContent,
    this.sourceContext,
    this.sourceType,
    this.highlightId,
    this.messageId,
    this.topicId,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final NoteService _noteService = NoteService();

  bool _isLoading = false;
  bool _hasChanges = false;
  String? _noteId;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.existingNote != null) {
      // 编辑现有笔记
      _noteId = widget.existingNote!.noteId;
      try {
        final doc = Document.fromJson(jsonDecode(widget.existingNote!.content));
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // 如果不是 Delta JSON，尝试作为纯文本加载
        _controller = QuillController(
          document: Document()..insert(0, widget.existingNote!.plainText),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else if (widget.initialContent != null) {
      // 从高亮/消息创建，使用初始内容
      _controller = QuillController(
        document: Document()..insert(0, widget.initialContent!),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      // 新建空白笔记
      _controller = QuillController.basic();
    }

    // 监听内容变化
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

  /// 获取纯文本内容
  String _getPlainText() {
    return _controller.document.toPlainText().trim();
  }

  /// 获取 Delta JSON
  String _getDeltaJson() {
    return jsonEncode(_controller.document.toDelta().toJson());
  }

  /// 保存笔记
  Future<void> _saveNote() async {
    final plainText = _getPlainText();
    if (plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('笔记内容不能为空')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final content = _getDeltaJson();
      final tags = NoteEntity.extractTags(plainText);

      if (_noteId != null) {
        // 更新现有笔记
        await _noteService.updateNote(
          noteId: _noteId!,
          content: content,
          plainText: plainText,
          tags: tags,
        );
      } else if (widget.sourceType == 'highlight' && widget.highlightId != null) {
        // 从高亮创建
        final note = await _noteService.createNoteFromHighlight(
          highlightText: plainText,
          highlightId: widget.highlightId!,
          messageId: widget.messageId!,
          topicId: widget.topicId!,
          topicName: widget.sourceContext?['topicName'] ?? '',
          assistantName: widget.sourceContext?['assistantName'],
          messagePreview: widget.sourceContext?['messagePreview'],
        );
        _noteId = note.noteId;
      } else if (widget.sourceType == 'message' && widget.messageId != null) {
        // 从消息创建
        final note = await _noteService.createNoteFromMessage(
          initialContent: content,
          messageId: widget.messageId!,
          topicId: widget.topicId!,
          topicName: widget.sourceContext?['topicName'] ?? '',
          assistantName: widget.sourceContext?['assistantName'],
          messagePreview: widget.sourceContext?['messagePreview'],
        );
        _noteId = note.noteId;
      } else {
        // 手动创建
        final note = await _noteService.createNote(
          content: content,
          plainText: plainText,
          tags: tags,
        );
        _noteId = note.noteId;
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

  /// 删除笔记
  Future<void> _deleteNote() async {
    if (_noteId == null) {
      Navigator.pop(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: const Text('确定要删除这条笔记吗？'),
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

    if (confirmed == true) {
      await _noteService.deleteNote(_noteId!);
      if (mounted) {
        Navigator.pop(context, true); // 返回 true 表示已删除
      }
    }
  }

  /// 处理返回
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('是否保存更改？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0), // 不保存
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 1), // 取消
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2), // 保存
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == 0) return true;
    if (result == 2) {
      await _saveNote();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_noteId != null ? '编辑笔记' : '新建笔记'),
          actions: [
            if (_noteId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteNote,
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
              onPressed: _isLoading ? null : _saveNote,
              tooltip: '保存',
            ),
          ],
        ),
        body: Column(
          children: [
            // 上下文预览（如果有来源）
            if (widget.sourceContext != null) _buildSourcePreview(),

            // 编辑器
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuillEditor(
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  controller: _controller,
                  config: const QuillEditorConfig(
                    placeholder: '写点什么...',
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            // 工具栏
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  /// 构建来源预览
  Widget _buildSourcePreview() {
    final topicName = widget.sourceContext?['topicName'] as String?;
    final messagePreview = widget.sourceContext?['messagePreview'] as String?;

    if (topicName == null && messagePreview == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '来源：$topicName',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (messagePreview != null) ...[
            const SizedBox(height: 8),
            Text(
              messagePreview,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建简化版工具栏
  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
