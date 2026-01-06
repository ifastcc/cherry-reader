import 'package:flutter/material.dart';

class TopicCard extends StatelessWidget {
  final String title;
  final String date;
  final String assistantName;
  final int roundCount; // 0 means just started
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

    return Card(
      elevation: 0,
      color: theme.cardColor, // Use card color for a distinct "cell" background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.08), // Subtle border
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontSize: 16, 
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              // Content Previews
              if (userPreview != null) ...[
                _buildPreviewLine(
                  context,
                  emoji: '🗣️', // Speaking head emoji
                  text: userPreview!,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
              ],
              
              if (aiPreview != null) ...[
                _buildPreviewLine(
                  context,
                  emoji: '✨', // Sparkles emoji
                  text: aiPreview!,
                  color: colorScheme.secondary,
                ),
              ],

              // Meta Footer (only if previews exist, adds spacing)
              if (userPreview != null || aiPreview != null)
                const SizedBox(height: 12),
              
              // Minimal Footer
              Row(
                children: [
                  _buildTag(context, assistantName, isPrimary: false),
                  if (roundCount > 0) ...[
                    const SizedBox(width: 8),
                    _buildTag(context, '$roundCount Rnds', isPrimary: false),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewLine(BuildContext context, {required String emoji, required String text, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1, right: 8),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 14), 
          ),
        ),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              height: 1.5, // slightly looser line height for readability
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String text, {bool isPrimary = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary ? colorScheme.primaryContainer.withOpacity(0.3) : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isPrimary ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}
