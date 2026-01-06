import 'package:flutter/material.dart';

enum StatusBadgeState {
  idle,
  syncing,
  hasUpdate,
  error,
}

class StatusBadge extends StatelessWidget {
  final StatusBadgeState state;
  final String? message;
  final VoidCallback? onTap;

  const StatusBadge({
    super.key,
    required this.state,
    this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Define styles based on state
    final (Color color, IconData icon) = switch (state) {
      StatusBadgeState.idle => (theme.colorScheme.outline.withOpacity(0.3), Icons.cloud_done_outlined),
      StatusBadgeState.syncing => (theme.colorScheme.primary, Icons.sync),
      StatusBadgeState.hasUpdate => (Colors.orange, Icons.file_download_outlined),
      StatusBadgeState.error => (theme.colorScheme.error, Icons.error_outline),
    };

    final bool showText = state != StatusBadgeState.idle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: showText ? 12 : 8, 
              vertical: 6
            ),
            decoration: BoxDecoration(
              color: showText ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showText ? color.withOpacity(0.2) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state == StatusBadgeState.syncing)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Icon(icon, size: 16, color: color),

                if (showText && message != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
