import 'package:flutter/material.dart';
import '../models/domain/search_result_model.dart';

/// 搜索结果卡片
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
    final isTopic = result.type == SearchResultType.topic;
    final colorScheme = Theme.of(context).colorScheme;

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
            // 顶部信息行
            _buildTopRow(context, isDark, isTopic, colorScheme),
            const SizedBox(height: 8),
            // 匹配内容（高亮关键词）
            _buildMatchContent(context, isDark, colorScheme),
            const SizedBox(height: 8),
            // 底部信息行
            _buildBottomRow(context, isDark),
          ],
        ),
      ),
    );
  }

  /// 顶部信息行：类型标签 + 话题名称 + 时间
  Widget _buildTopRow(
    BuildContext context,
    bool isDark,
    bool isTopic,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // 类型标签
        _buildTypeTag(isTopic),
        const SizedBox(width: 8),
        // 话题名称（如果是消息结果）
        if (!isTopic)
          Expanded(
            child: Text(
              result.topicName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (isTopic) const Spacer(),
        // 时间
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

  /// 类型标签
  Widget _buildTypeTag(bool isTopic) {
    Color bgColor;
    Color textColor;
    String label;

    if (isTopic) {
      bgColor = const Color(0xFF6366F1).withValues(alpha: 0.15);
      textColor = const Color(0xFF6366F1);
      label = '话题';
    } else if (result.isUserMessage) {
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
      textColor = const Color(0xFF10B981);
      label = '用户';
    } else {
      bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.15);
      textColor = const Color(0xFF3B82F6);
      label = 'AI';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// 匹配内容（高亮关键词）
  Widget _buildMatchContent(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final snippet = result.matchSnippet;
    final start = result.matchStart;
    final end = result.matchEnd;

    // 安全边界检查
    final safeStart = start.clamp(0, snippet.length);
    final safeEnd = end.clamp(0, snippet.length);

    // 构建高亮文本
    final spans = <TextSpan>[];
    final defaultStyle = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: isDark ? Colors.grey[300] : Colors.grey[800],
    );

    if (safeStart > 0) {
      spans.add(TextSpan(
        text: snippet.substring(0, safeStart),
        style: defaultStyle,
      ));
    }

    if (safeStart < safeEnd) {
      spans.add(TextSpan(
        text: snippet.substring(safeStart, safeEnd),
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ));
    }

    if (safeEnd < snippet.length) {
      spans.add(TextSpan(
        text: snippet.substring(safeEnd),
        style: defaultStyle,
      ));
    }

    // 如果没有构建任何 span，显示原始文本
    if (spans.isEmpty) {
      spans.add(TextSpan(text: snippet, style: defaultStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 底部信息行：助手名称 + 模型名称 + 轮次 + 箭头
  Widget _buildBottomRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        // 助手名称
        Icon(Icons.smart_toy_outlined, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            result.assistantName,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 消息特有信息
        if (result.type == SearchResultType.message) ...[
          // 模型名称
          if (result.modelName != null && result.modelName!.isNotEmpty) ...[
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
          // 轮次
          if (result.roundIndex != null) ...[
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
        const Spacer(),
        // 跳转箭头
        Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
      ],
    );
  }
}
