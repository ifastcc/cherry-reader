import '../../services/webdav_service.dart' show DataLoadMode;

/// 简化的状态栏阶段（只有 4 种用户可感知的状态）
enum StatusBarPhase {
  /// 正常/空闲（灰色）
  idle,

  /// 同步中（蓝色，可能有进度）
  syncing,

  /// 有新版本可用（橙色）
  hasUpdate,

  /// 错误（红色，可点击查看详情）
  error,
}

/// 简化的状态栏状态模型
class StatusBarState {
  /// 当前阶段
  final StatusBarPhase phase;

  /// 数据加载模式
  final DataLoadMode loadMode;

  /// 同步进度 0-1（仅 syncing 阶段使用）
  final double? progress;

  /// 同步阶段描述（如"检查中"、"下载中"、"解析中"）
  final String? syncMessage;

  /// 错误详情（仅 error 阶段使用，点击可查看）
  final String? errorDetail;

  /// 版本显示名
  final String? versionDisplay;

  /// 话题数量
  final int? topicCount;

  /// 是否有新版本待查看（用于小蓝点）
  final bool hasNewVersion;

  const StatusBarState({
    required this.phase,
    required this.loadMode,
    this.progress,
    this.syncMessage,
    this.errorDetail,
    this.versionDisplay,
    this.topicCount,
    this.hasNewVersion = false,
  });

  /// 创建空闲状态
  factory StatusBarState.idle({
    required DataLoadMode loadMode,
    String? versionDisplay,
    int? topicCount,
    bool hasNewVersion = false,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.idle,
      loadMode: loadMode,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
      hasNewVersion: hasNewVersion,
    );
  }

  /// 创建同步中状态
  factory StatusBarState.syncing({
    required DataLoadMode loadMode,
    double? progress,
    String? message,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.syncing,
      loadMode: loadMode,
      progress: progress,
      syncMessage: message,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 创建"有新版本"状态
  factory StatusBarState.hasUpdate({
    required DataLoadMode loadMode,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.hasUpdate,
      loadMode: loadMode,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 创建错误状态
  factory StatusBarState.error({
    required DataLoadMode loadMode,
    required String errorDetail,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.error,
      loadMode: loadMode,
      errorDetail: errorDetail,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 是否处于空闲状态
  bool get isIdle => phase == StatusBarPhase.idle;

  /// 是否处于同步中状态
  bool get isSyncing => phase == StatusBarPhase.syncing;

  /// 是否处于错误状态
  bool get isError => phase == StatusBarPhase.error;

  /// 是否显示进度条
  bool get showProgress => phase == StatusBarPhase.syncing && progress != null;

  /// 获取状态描述文字
  String get statusText {
    switch (phase) {
      case StatusBarPhase.idle:
        return _modeText;
      case StatusBarPhase.syncing:
        return syncMessage ?? '同步中...';
      case StatusBarPhase.hasUpdate:
        return '有新版本';
      case StatusBarPhase.error:
        return '同步失败';
    }
  }

  String get _modeText {
    return switch (loadMode) {
      DataLoadMode.webdav => 'WebDAV',
      DataLoadMode.localFolder => '本地同步',
      DataLoadMode.manual => '手动模式',
    };
  }

  @override
  String toString() {
    return 'StatusBarState(phase: $phase, loadMode: $loadMode, progress: $progress)';
  }
}
