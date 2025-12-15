import '../../services/webdav_service.dart' show DataLoadMode;

/// 状态栏阶段枚举
enum StatusBarPhase {
  // === 空闲状态 ===
  /// 正常空闲
  idle,

  /// 已是最新（刚同步完，短暂显示后回到 idle）
  upToDate,

  /// 有新版本可用
  hasUpdate,

  /// 未配置数据源
  noDataSource,

  // === 进行中状态 ===
  /// 检查更新中
  checking,

  /// 下载中（有进度）
  downloading,

  /// 解析中
  parsing,

  /// 导入中
  importing,

  /// 切换版本中
  switching,

  // === 错误状态 ===
  /// 发生错误（可点击查看详情）
  error,
}

/// 状态栏状态模型
class StatusBarState {
  /// 当前阶段
  final StatusBarPhase phase;

  /// 数据加载模式
  final DataLoadMode loadMode;

  /// 状态描述（可选，用于自定义消息）
  final String? message;

  /// 下载进度 0-1（仅 downloading 阶段使用）
  final double? progress;

  /// 已下载大小（字节）
  final int? downloadedBytes;

  /// 总大小（字节）
  final int? totalBytes;

  /// 错误详情（仅 error 阶段使用）
  final String? errorDetail;

  /// 上次检查时间
  final DateTime? lastCheckTime;

  /// 版本显示名
  final String? versionDisplay;

  /// 话题数量
  final int? topicCount;

  /// 是否有新版本待应用（用于小蓝点）
  final bool hasNewVersion;

  const StatusBarState({
    required this.phase,
    required this.loadMode,
    this.message,
    this.progress,
    this.downloadedBytes,
    this.totalBytes,
    this.errorDetail,
    this.lastCheckTime,
    this.versionDisplay,
    this.topicCount,
    this.hasNewVersion = false,
  });

  /// 创建空闲状态
  factory StatusBarState.idle({
    required DataLoadMode loadMode,
    DateTime? lastCheckTime,
    String? versionDisplay,
    int? topicCount,
    bool hasNewVersion = false,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.idle,
      loadMode: loadMode,
      lastCheckTime: lastCheckTime,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
      hasNewVersion: hasNewVersion,
    );
  }

  /// 创建"已是最新"状态
  factory StatusBarState.upToDate({
    required DataLoadMode loadMode,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.upToDate,
      loadMode: loadMode,
      lastCheckTime: DateTime.now(),
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 创建"有新版本"状态
  factory StatusBarState.hasUpdate({
    required DataLoadMode loadMode,
    DateTime? lastCheckTime,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.hasUpdate,
      loadMode: loadMode,
      lastCheckTime: lastCheckTime,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
      hasNewVersion: true,
    );
  }

  /// 创建"未配置数据源"状态
  factory StatusBarState.noDataSource({
    required DataLoadMode loadMode,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.noDataSource,
      loadMode: loadMode,
    );
  }

  /// 创建"检查更新中"状态
  factory StatusBarState.checking({
    required DataLoadMode loadMode,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.checking,
      loadMode: loadMode,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 创建"下载中"状态
  factory StatusBarState.downloading({
    required DataLoadMode loadMode,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.downloading,
      loadMode: loadMode,
      progress: progress,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 创建"解析中"状态
  factory StatusBarState.parsing({
    required DataLoadMode loadMode,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.parsing,
      loadMode: loadMode,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 创建"导入中"状态
  factory StatusBarState.importing({
    required DataLoadMode loadMode,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.importing,
      loadMode: loadMode,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 创建"切换版本中"状态
  factory StatusBarState.switching({
    required DataLoadMode loadMode,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.switching,
      loadMode: loadMode,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 创建"错误"状态
  factory StatusBarState.error({
    required DataLoadMode loadMode,
    required String errorDetail,
    String? message,
    String? versionDisplay,
    int? topicCount,
  }) {
    return StatusBarState(
      phase: StatusBarPhase.error,
      loadMode: loadMode,
      message: message,
      errorDetail: errorDetail,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
    );
  }

  /// 是否处于空闲状态
  bool get isIdle =>
      phase == StatusBarPhase.idle ||
      phase == StatusBarPhase.upToDate ||
      phase == StatusBarPhase.hasUpdate ||
      phase == StatusBarPhase.noDataSource;

  /// 是否处于进行中状态
  bool get isInProgress =>
      phase == StatusBarPhase.checking ||
      phase == StatusBarPhase.downloading ||
      phase == StatusBarPhase.parsing ||
      phase == StatusBarPhase.importing ||
      phase == StatusBarPhase.switching;

  /// 是否处于错误状态
  bool get isError => phase == StatusBarPhase.error;

  /// 是否显示进度条
  bool get showProgress => phase == StatusBarPhase.downloading && progress != null;

  /// 获取状态图标
  String get statusIcon {
    switch (phase) {
      case StatusBarPhase.idle:
        return '○';
      case StatusBarPhase.upToDate:
        return '✓';
      case StatusBarPhase.hasUpdate:
        return '●';
      case StatusBarPhase.noDataSource:
        return '○';
      case StatusBarPhase.checking:
        return '◐';
      case StatusBarPhase.downloading:
        return '↓';
      case StatusBarPhase.parsing:
      case StatusBarPhase.importing:
      case StatusBarPhase.switching:
        return '⟳';
      case StatusBarPhase.error:
        return '✗';
    }
  }

  /// 获取状态描述文字
  String get statusText {
    // 如果有自定义消息，优先使用
    if (message != null) return message!;

    switch (phase) {
      case StatusBarPhase.idle:
        return _buildIdleText();
      case StatusBarPhase.upToDate:
        return '已是最新';
      case StatusBarPhase.hasUpdate:
        return '有新版本可用';
      case StatusBarPhase.noDataSource:
        return '未配置数据源';
      case StatusBarPhase.checking:
        return '检查更新...';
      case StatusBarPhase.downloading:
        return _buildDownloadingText();
      case StatusBarPhase.parsing:
        return '解析中...';
      case StatusBarPhase.importing:
        return '导入中...';
      case StatusBarPhase.switching:
        return '切换版本...';
      case StatusBarPhase.error:
        return '同步失败 · 点击查看';
    }
  }

  String _buildIdleText() {
    final modeText = switch (loadMode) {
      DataLoadMode.webdav => 'WebDAV',
      DataLoadMode.localFolder => '本地文件夹',
      DataLoadMode.manual => '手动模式',
    };

    if (lastCheckTime != null) {
      final timeText = _formatRelativeTime(lastCheckTime!);
      return '$modeText · $timeText';
    }

    return modeText;
  }

  String _buildDownloadingText() {
    if (downloadedBytes != null && totalBytes != null && totalBytes! > 0) {
      final downloadedMB = (downloadedBytes! / 1024 / 1024).toStringAsFixed(1);
      final totalMB = (totalBytes! / 1024 / 1024).toStringAsFixed(1);
      return '下载中 $downloadedMB/$totalMB MB';
    }
    if (downloadedBytes != null) {
      final downloadedMB = (downloadedBytes! / 1024 / 1024).toStringAsFixed(1);
      return '下载中 ${downloadedMB}MB';
    }
    if (progress != null) {
      return '下载中 ${(progress! * 100).toStringAsFixed(0)}%';
    }
    return '下载中...';
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }

  /// 复制并修改
  StatusBarState copyWith({
    StatusBarPhase? phase,
    DataLoadMode? loadMode,
    String? message,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? errorDetail,
    DateTime? lastCheckTime,
    String? versionDisplay,
    int? topicCount,
    bool? hasNewVersion,
  }) {
    return StatusBarState(
      phase: phase ?? this.phase,
      loadMode: loadMode ?? this.loadMode,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorDetail: errorDetail ?? this.errorDetail,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      versionDisplay: versionDisplay ?? this.versionDisplay,
      topicCount: topicCount ?? this.topicCount,
      hasNewVersion: hasNewVersion ?? this.hasNewVersion,
    );
  }

  @override
  String toString() {
    return 'StatusBarState(phase: $phase, loadMode: $loadMode, progress: $progress, hasNewVersion: $hasNewVersion)';
  }
}
