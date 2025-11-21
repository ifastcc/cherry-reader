import 'package:flutter/material.dart';
import 'unified_markdown_renderer.dart';

/// 用户消息卡片 - 简单展示用户输入，不需要标注功能
class UserMessageCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const UserMessageCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = data['blocks'] as List<dynamic>? ?? [];
    final mentions = data['mentions'] as List<dynamic>? ?? [];

    // 提取用户消息文本
    String userText = '';
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        userText += block['content'] as String? ?? '';
      }
    }

    final isLongText = userText.length > 200;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部：@提及的模型标签
            if (mentions.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: mentions.map((m) {
                  final modelName = (m as Map)['name'] as String? ?? 'Unknown';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getModelColor(modelName).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getModelColor(modelName).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alternate_email,
                          size: 11,
                          color: _getModelColor(modelName),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          modelName,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getModelColor(modelName),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // 消息内容
            if (isLongText)
              _CollapsibleMarkdown(content: userText)
            else
              UnifiedMarkdownRenderer(
                data: userText,
                scrollable: false,
                selectable: true,
              ),

            // 底部时间戳
            const SizedBox(height: 8),
            Text(
              _formatTime(data['created_at'] as String? ?? ''),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getModelColor(String modelName) {
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

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoTime.substring(0, 16).replaceAll('T', ' ');
    }
  }
}

/// 可折叠的 Markdown 组件
class _CollapsibleMarkdown extends StatefulWidget {
  final String content;

  const _CollapsibleMarkdown({required this.content});

  @override
  State<_CollapsibleMarkdown> createState() => _CollapsibleMarkdownState();
}

class _CollapsibleMarkdownState extends State<_CollapsibleMarkdown> {
  bool _isExpanded = false;
  static const int _previewLength = 200;

  @override
  Widget build(BuildContext context) {
    final shouldCollapse = widget.content.length > _previewLength;
    final displayContent = (!shouldCollapse || _isExpanded)
        ? widget.content
        : widget.content.substring(0, _previewLength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        UnifiedMarkdownRenderer(
          data: displayContent,
          textStyle: const TextStyle(
            fontSize: 15,
            height: 1.85,
            color: Color(0xFF333333),
            letterSpacing: 0.2,
          ),
        ),
        if (shouldCollapse) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isExpanded ? '收起' : '展开更多',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
