import 'package:flutter/material.dart';

class TopicCard extends StatelessWidget {
  final String title;
  final String date;
  final String assistantName;
  final int roundCount;
  final String? userPreview;
  final String? aiPreview;
  final VoidCallback onTap;

  const TopicCard({
    super.key,
    required this.title,
    required this.date,
    required this.assistantName,
    required this.roundCount,
    this.userPreview,
    this.aiPreview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cleanUserPreview = userPreview;
    final cleanAiPreview = aiPreview;

    return Padding(
      // 外边距 - 让卡片之间有明显间隔
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Title + Round count
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          height: 1.35,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (roundCount > 0) ...[
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$roundCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.outline.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                // Row 2: User query - 单行副标题
                if (cleanUserPreview != null &&
                    cleanUserPreview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    cleanUserPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.65,
                      ),
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                ],

                // Row 3: AI response - 两行，无标记，略深一点
                if (cleanAiPreview != null && cleanAiPreview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    cleanAiPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ],

                // Row 4: Meta info
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      assistantName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
