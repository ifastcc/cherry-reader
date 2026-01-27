import 'package:flutter/foundation.dart';

/// 同步状态
enum SyncPhase {
  idle,       // 空闲
  checking,   // 检查更新
  downloading, // 下载中
  parsing,    // 解析中
  importing,  // 导入中
  error,      // 错误
}

/// 同步状态数据
class SyncStatus {
  final SyncPhase phase;
  final String? message;
  final double? progress;
  final String? error;

  const SyncStatus._({
    required this.phase,
    this.message,
    this.progress,
    this.error,
  });

  factory SyncStatus.idle() => const SyncStatus._(phase: SyncPhase.idle);

  factory SyncStatus.checking() => const SyncStatus._(
        phase: SyncPhase.checking,
        message: '检查更新...',
      );

  factory SyncStatus.downloading(double progress, String message) =>
      SyncStatus._(
        phase: SyncPhase.downloading,
        progress: progress,
        message: message,
      );

  factory SyncStatus.parsing() => const SyncStatus._(
        phase: SyncPhase.parsing,
        message: '解析中...',
      );

  factory SyncStatus.importing(String message, {double? progress}) =>
      SyncStatus._(
        phase: SyncPhase.importing,
        message: message,
        progress: progress,
      );

  factory SyncStatus.error(String error) => SyncStatus._(
        phase: SyncPhase.error,
        error: error,
      );

  bool get isIdle => phase == SyncPhase.idle;
  bool get isInProgress =>
      phase == SyncPhase.checking ||
      phase == SyncPhase.downloading ||
      phase == SyncPhase.parsing ||
      phase == SyncPhase.importing;
  bool get isError => phase == SyncPhase.error;
}

/// 同步状态通知器
///
/// 独立于 HomeScreen 的状态管理，
/// 使用 ValueNotifier 实现精确的局部更新。
class SyncStatusNotifier extends ValueNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.idle());

  /// 节流控制
  DateTime _lastUpdate = DateTime.now();
  static const _throttleMs = 100;

  /// 开始检查
  void startChecking() {
    value = SyncStatus.checking();
  }

  /// 更新下载进度（带节流）
  void updateDownloadProgress(double progress, String message) {
    final now = DateTime.now();
    if (now.difference(_lastUpdate).inMilliseconds >= _throttleMs) {
      _lastUpdate = now;
      value = SyncStatus.downloading(progress, message);
    }
  }

  /// 开始解析
  void startParsing() {
    value = SyncStatus.parsing();
  }

  /// 更新导入进度
  void updateImportProgress(String message, {double? progress}) {
    final now = DateTime.now();
    if (now.difference(_lastUpdate).inMilliseconds >= _throttleMs) {
      _lastUpdate = now;
      value = SyncStatus.importing(message, progress: progress);
    }
  }

  /// 完成
  void complete() {
    value = SyncStatus.idle();
  }

  /// 错误
  void setError(String error) {
    value = SyncStatus.error(error);
  }

  /// 清除错误
  void clearError() {
    if (value.isError) {
      value = SyncStatus.idle();
    }
  }
}
