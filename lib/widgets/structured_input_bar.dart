import 'package:flutter/material.dart';
import '../models/isar/prompt_template_entity.dart';

/// 结构化输入栏组件
///
/// 使用 Chips 展示已选择的模版和上下文，
/// 保持输入框纯净，只用于追加问题
class StructuredInputBar extends StatelessWidget {
  /// 输入框控制器
  final TextEditingController controller;

  /// 输入框焦点
  final FocusNode? focusNode;

  /// 已选择的模版
  final TaskTemplateEntity? selectedTemplate;

  /// 上下文摘要（如 "3条回复 (22KB)"）
  final String? contextSummary;

  /// 是否正在发送
  final bool isSending;

  /// 发送回调
  final VoidCallback? onSend;

  /// 选择模版回调
  final VoidCallback? onSelectTemplate;

  /// 清除模版回调
  final VoidCallback? onClearTemplate;

  /// 查看上下文回调
  final VoidCallback? onViewContext;

  /// 清除上下文回调
  final VoidCallback? onClearContext;

  /// 预览完整 prompt 回调
  final VoidCallback? onPreview;

  const StructuredInputBar({
    Key? key,
    required this.controller,
    this.focusNode,
    this.selectedTemplate,
    this.contextSummary,
    this.isSending = false,
    this.onSend,
    this.onSelectTemplate,
    this.onClearTemplate,
    this.onViewContext,
    this.onClearContext,
    this.onPreview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chips 区域
          _buildChipsRow(context),

          const SizedBox(height: 8),

          // 输入框和发送按钮
          _buildInputRow(context),
        ],
      ),
    );
  }

  Widget _buildChipsRow(BuildContext context) {
    return Row(
      children: [
        // 模版 Chip
        _TemplateChip(
          template: selectedTemplate,
          onTap: onSelectTemplate,
          onClear: onClearTemplate,
        ),

        const SizedBox(width: 8),

        // 上下文 Chip（如果有）
        if (contextSummary != null)
          _ContextChip(
            summary: contextSummary!,
            onTap: onViewContext,
            onClear: onClearContext,
          ),

        const Spacer(),

        // 预览按钮
        if (onPreview != null)
          IconButton(
            icon: Icon(Icons.preview, size: 20, color: Colors.grey[600]),
            onPressed: onPreview,
            tooltip: '预览完整 Prompt',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
      ],
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 5,
            minLines: 1,
            decoration: InputDecoration(
              hintText: '追加问题（可选）...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSubmitted: (_) => onSend?.call(),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isSending ? null : onSend,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ),
      ],
    );
  }
}

/// 模版 Chip
class _TemplateChip extends StatelessWidget {
  final TaskTemplateEntity? template;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _TemplateChip({
    this.template,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasTemplate = template != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasTemplate
              ? Colors.purple.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasTemplate
                ? Colors.purple.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description,
              size: 14,
              color: hasTemplate ? Colors.purple : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              template?.name ?? '选择模版',
              style: TextStyle(
                fontSize: 12,
                color: hasTemplate ? Colors.purple : Colors.grey[600],
                fontWeight: hasTemplate ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 2),
            if (hasTemplate && onClear != null)
              InkWell(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.purple[400],
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: hasTemplate ? Colors.purple : Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }
}

/// 上下文 Chip
class _ContextChip extends StatelessWidget {
  final String summary;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _ContextChip({
    required this.summary,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article,
              size: 14,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 4),
            Text(
              summary,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.orange[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
