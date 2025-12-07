import 'package:flutter/material.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../models/structured_context.dart';
import 'unified_markdown_renderer.dart';

/// 上下文容器组件
///
/// 将结构化的上下文以可视化的"盒子"形式展示
/// 包含：System Prompt、User Query、Model Responses（网格布局）
class ContextContainer extends StatelessWidget {
  final StructuredContext context;
  final String? systemPrompt;
  final VoidCallback? onClear;

  /// 移除某个回复的回调（传入索引）
  final void Function(int index)? onRemoveResponse;

  const ContextContainer({
    Key? key,
    required this.context,
    this.systemPrompt,
    this.onClear,
    this.onRemoveResponse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题栏
          _buildHeader(context),

          // System Prompt（如果有）
          if (systemPrompt != null && systemPrompt!.isNotEmpty)
            _ContextSection(
              icon: Icons.settings,
              title: 'System Prompt',
              content: systemPrompt!,
              color: Colors.blue,
            ),

          // User Query（如果有）
          if (this.context.userQuery != null &&
              this.context.userQuery!.isNotEmpty)
            _ContextSection(
              icon: Icons.help_outline,
              title: '用户问题',
              content: this.context.userQuery!,
              color: Colors.green,
            ),

          // Model Responses（网格布局）
          if (this.context.responses.isNotEmpty)
            _buildResponsesSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            'Context',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              this.context.summaryDescription,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          if (onClear != null)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection(BuildContext context) {
    final responses = this.context.responses;
    final isSingleMessage = this.context.contextType == ConversationContextType.singleMessage;

    // 对于单条消息讨论，使用简洁的"原始回复"展示
    if (isSingleMessage && responses.length == 1) {
      return _ContextSection(
        icon: Icons.smart_toy,
        title: '原始回复',
        content: responses.first.content,
        color: Colors.purple,
      );
    }

    // 对于多模型回复（messageGroup），使用网格布局
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(Icons.smart_toy, size: 16, color: Colors.purple[600]),
              const SizedBox(width: 6),
              Text(
                '模型回复',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${responses.length} 个',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 网格布局
          _buildResponseGrid(context, responses),
        ],
      ),
    );
  }

  Widget _buildResponseGrid(
      BuildContext context, List<ModelResponse> responses) {
    // 根据回复数量决定布局
    if (responses.length == 1) {
      // 单个回复：全宽卡片（不显示删除按钮，因为至少要有一个）
      return _ResponseCard(
        response: responses.first,
        index: 0,
        canDelete: false,
        onDelete: null,
      );
    }

    // 多个回复：网格布局
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每行卡片数量（最多3个）
        const cardWidth = 200.0;
        final crossAxisCount =
            (constraints.maxWidth / cardWidth).floor().clamp(1, 3);

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(responses.length, (index) {
            final response = responses[index];
            final width = crossAxisCount == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - (crossAxisCount - 1) * 8) /
                    crossAxisCount;

            return SizedBox(
              width: width,
              child: _ResponseCard(
                response: response,
                index: index,
                canDelete: responses.length > 1, // 至少保留一个
                onDelete: onRemoveResponse != null
                    ? () => onRemoveResponse!(index)
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}

/// 可折叠的上下文区块
class _ContextSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _ContextSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  State<_ContextSection> createState() => _ContextSectionState();
}

class _ContextSectionState extends State<_ContextSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final preview = widget.content.length > 80
        ? '${widget.content.substring(0, 80)}...'
        : widget.content;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: widget.color.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏（可点击展开）
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: widget.color),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      preview,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),

          // 展开的内容
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SelectableText(
                widget.content,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 模型回复卡片
class _ResponseCard extends StatelessWidget {
  final ModelResponse response;
  final int index;
  final bool canDelete;
  final VoidCallback? onDelete;

  const _ResponseCard({
    required this.response,
    required this.index,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模型名称 + 字数 + 删除按钮
          Row(
            children: [
              Icon(Icons.smart_toy, size: 14, color: Colors.purple[400]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  response.modelName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  response.sizeDisplay,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              // 删除按钮
              if (canDelete && onDelete != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // 摘要预览（可点击查看全文）
          InkWell(
            onTap: () => _showFullContent(context),
            borderRadius: BorderRadius.circular(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.summary,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // 展开提示
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.open_in_full,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '点击查看全文',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullContent(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.purple[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response.modelName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      response.sizeDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // 内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: UnifiedMarkdownRenderer(
                    data: response.content,
                    selectable: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
