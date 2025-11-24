import 'package:flutter/material.dart';
import 'unified_markdown_renderer.dart';

/// 用户消息卡片 - 简单展示用户输入，支持双击展开/收起
class UserMessageCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const UserMessageCard({super.key, required this.data});

  @override
  State<UserMessageCard> createState() => _UserMessageCardState();
}

class _UserMessageCardState extends State<UserMessageCard> {
  bool _isExpanded = false; // 默认收起
  static const int _previewLength = 200;

  @override
  Widget build(BuildContext context) {
    final blocks = widget.data['blocks'] as List<dynamic>? ?? [];
    final mentions = widget.data['mentions'] as List<dynamic>? ?? [];

    // 提取用户消息文本
    String userText = '';
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        userText += block['content'] as String? ?? '';
      }
    }

    final isLongText = userText.length > _previewLength;
    final displayContent = (!isLongText || _isExpanded)
        ? userText
        : userText.substring(0, _previewLength) + '...';

    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Card(
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
                    final modelName =
                        (m as Map)['name'] as String? ?? 'Unknown';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getModelColor(
                          modelName,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getModelColor(
                            modelName,
                          ).withValues(alpha: 0.35),
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
              UnifiedMarkdownRenderer(
                data: displayContent,
                scrollable: false,
                selectable: true,
                textStyle: const TextStyle(
                  fontSize: 15,
                  height: 1.85,
                  color: Color(0xFF333333),
                  letterSpacing: 0.2,
                ),
              ),

              // 折叠状态提示
              if (isLongText) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isExpanded ? '双击收起' : '双击展开',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],

              // 底部时间戳
              const SizedBox(height: 8),
              Text(
                _formatTime(widget.data['created_at'] as String? ?? ''),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
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
