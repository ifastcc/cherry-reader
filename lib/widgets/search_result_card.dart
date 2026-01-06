import 'package:flutter/material.dart';
import '../models/domain/search_result_model.dart';

/// 搜索结果卡片
///
/// 统一样式：
/// - 顶部：话题名（如果是话题匹配则高亮）+ 时间
/// - 中部：内容预览/匹配片段（如果是消息匹配则高亮）
/// - 底部：助手名 + 模型名（如果有）+ 轮次（如果有）
class SearchResultCard extends StatelessWidget {
  final SearchResultModel result;
  final String keyword;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.keyword,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isTopic = result.type == SearchResultType.topic;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：话题名 + 时间
            _buildTopicRow(context, isDark, colorScheme, isTopic),
            const SizedBox(height: 8),
            // 中部：内容预览/匹配片段
            _buildContentRow(context, isDark, colorScheme, isTopic),
            const SizedBox(height: 8),
            // 底部：助手名 + 模型名 + 轮次
            _buildBottomRow(context, isDark),
          ],
        ),
      ),
    );
  }

  /// 顶部：话题名（可能高亮）+ 时间
  Widget _buildTopicRow(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    bool isTopic,
  ) {
    return Row(
      children: [
        Expanded(
          child: isTopic
              ? _buildHighlightedText(
                  result.topicName,
                  result.matchStart,
                  result.matchEnd,
                  colorScheme,
                  isDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                )
              : Text(
                  result.topicName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        const SizedBox(width: 8),
        Text(
          result.relativeTime,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  /// 中部：内容预览/匹配片段
  Widget _buildContentRow(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    bool isTopic,
  ) {
    if (isTopic) {
      // 话题匹配：显示内容预览（不高亮）
      final preview = result.contentPreview;
      if (preview == null || preview.isEmpty) {
        return const SizedBox.shrink();
      }
      return Text(
        preview,
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    // 消息匹配：显示匹配的内容片段并高亮
    return _buildHighlightedText(
      result.matchSnippet,
      result.matchStart,
      result.matchEnd,
      colorScheme,
      isDark,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      maxLines: 3,
      height: 1.5,
    );
  }

  /// 构建高亮文本
  Widget _buildHighlightedText(
    String text,
    int start,
    int end,
    ColorScheme colorScheme,
    bool isDark, {
    required double fontSize,
    required FontWeight fontWeight,
    required int maxLines,
    double height = 1.3,
  }) {
    // 安全边界检查
    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(0, text.length);

    final defaultStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: isDark ? Colors.grey[300] : Colors.grey[800],
    );

    final highlightStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: height,
      color: colorScheme.primary,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
    );

    final spans = <TextSpan>[];

    if (safeStart > 0) {
      spans.add(TextSpan(
        text: text.substring(0, safeStart),
        style: defaultStyle,
      ));
    }

    if (safeStart < safeEnd) {
      spans.add(TextSpan(
        text: text.substring(safeStart, safeEnd),
        style: highlightStyle,
      ));
    }

    if (safeEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(safeEnd),
        style: defaultStyle,
      ));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: defaultStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 底部：助手名 + 模型名 + 轮次
  Widget _buildBottomRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        // 助手名称
        Icon(Icons.smart_toy_outlined, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            result.assistantNames.join(', '),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 模型名称（消息类型才有）
        if (result.type == SearchResultType.message &&
            result.modelName != null &&
            result.modelName!.isNotEmpty) ...[
          const SizedBox(width: 12),
          Icon(Icons.memory, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              result.modelName!,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        // 轮次（消息类型才有）
        if (result.type == SearchResultType.message &&
            result.roundIndex != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Q${result.roundIndex! + 1}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
