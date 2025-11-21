import 'package:flutter/material.dart';
import 'unified_markdown_renderer.dart';

/// 流式生成的 AI 分析卡片
///
/// 实时更新显示，对应 Streamlit 的 content_placeholder.markdown()
class StreamingAnalysisCard extends StatelessWidget {
  final String content;
  final int analysisIndex;

  const StreamingAnalysisCard({
    Key? key,
    required this.content,
    required this.analysisIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const modelColor = Color(0xFF8B5CF6); // 紫色

    return Card(
      color: const Color(0xFF16162a),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: modelColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：模型图标 + 名称 + 加载动画（和助手回复一致的样式）
            Row(
              children: [
                // 模型图标
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: modelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: modelColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 13, color: modelColor),
                ),
                const SizedBox(width: 10),
                // 模型名称
                Expanded(
                  child: Text(
                    'AI 元分析 #$analysisIndex',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: modelColor,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 加载动画
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(modelColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 内容：Markdown 渲染 + 流式更新 - 使用 Expanded 支持滚动
            Expanded(
              child: content.isEmpty
                  ? const Center(
                      child: Text(
                        '等待响应...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      child: UnifiedMarkdownRenderer(
                        data: content,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          height: 1.8,
                          color: Color(0xFFE8E8E8),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
