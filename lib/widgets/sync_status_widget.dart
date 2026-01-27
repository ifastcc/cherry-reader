import 'package:flutter/material.dart';
import '../services/sync_status_notifier.dart';
import 'status_badge.dart';

/// 独立的同步状态组件
///
/// 使用 ValueListenableBuilder 监听 SyncStatusNotifier，
/// 只有同步状态变化时才重建，不会触发父组件重建。
class SyncStatusWidget extends StatelessWidget {
  final SyncStatusNotifier notifier;
  final VoidCallback? onTap;

  const SyncStatusWidget({
    super.key,
    required this.notifier,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: notifier,
      builder: (context, status, _) {
        final badgeState = _mapToBadgeState(status);
        final message = _getMessage(status);

        return StatusBadge(
          state: badgeState,
          message: message,
          onTap: onTap,
        );
      },
    );
  }

  StatusBadgeState _mapToBadgeState(SyncStatus status) {
    return switch (status.phase) {
      SyncPhase.idle => StatusBadgeState.idle,
      SyncPhase.checking ||
      SyncPhase.downloading ||
      SyncPhase.parsing ||
      SyncPhase.importing =>
        StatusBadgeState.syncing,
      SyncPhase.error => StatusBadgeState.error,
    };
  }

  String? _getMessage(SyncStatus status) {
    if (status.isIdle) return null;
    if (status.isError) return status.error;
    return status.message;
  }
}

/// 带进度条的同步状态组件（用于详细显示）
class SyncProgressWidget extends StatelessWidget {
  final SyncStatusNotifier notifier;
  final VoidCallback? onCancel;

  const SyncProgressWidget({
    super.key,
    required this.notifier,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: notifier,
      builder: (context, status, _) {
        if (status.isIdle) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: status.isError
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (status.isInProgress)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (status.isError)
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.message ?? (status.isError ? '同步失败' : '同步中...'),
                      style: TextStyle(
                        fontSize: 13,
                        color: status.isError ? Colors.red : Colors.grey[700],
                      ),
                    ),
                    if (status.progress != null) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: status.progress,
                        backgroundColor: Colors.grey[300],
                      ),
                    ],
                  ],
                ),
              ),
              if (onCancel != null && status.isInProgress)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        );
      },
    );
  }
}
