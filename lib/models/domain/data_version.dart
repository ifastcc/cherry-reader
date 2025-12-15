/// 版本状态枚举
enum VersionStatus {
  /// 正在导入
  importing,

  /// 可用（导入完成，但不是当前活跃版本）
  ready,

  /// 当前活跃版本
  active,

  /// 导入失败
  failed,
}

/// 数据版本信息
///
/// 表示一个导入的 Cherry Studio 备份版本
class DataVersion {
  /// 版本唯一标识，格式: "v-YYYYMMDD-HHMMSS"
  final String versionId;

  /// 来源文件名（如 "cherry-studio.20251214194355.zip"）
  final String sourceFileName;

  /// 导入时间
  final DateTime importedAt;

  /// 源文件修改时间（从文件名解析）
  final DateTime sourceModifiedAt;

  /// 话题数量
  final int topicCount;

  /// 消息数量
  final int messageCount;

  /// 数据库文件大小（字节）
  final int fileSizeBytes;

  /// Isar 数据库文件路径
  final String isarPath;

  /// 是否锁定（锁定后不自动切换到新版本）
  final bool isLocked;

  /// 版本状态
  final VersionStatus status;

  DataVersion({
    required this.versionId,
    required this.sourceFileName,
    required this.importedAt,
    required this.sourceModifiedAt,
    this.topicCount = 0,
    this.messageCount = 0,
    this.fileSizeBytes = 0,
    required this.isarPath,
    this.isLocked = false,
    this.status = VersionStatus.importing,
  });

  /// 显示名称（用户友好的格式）
  ///
  /// 例如: "12-14 19:43" (来自 sourceModifiedAt)
  String get displayName {
    final m = sourceModifiedAt.month.toString().padLeft(2, '0');
    final d = sourceModifiedAt.day.toString().padLeft(2, '0');
    final h = sourceModifiedAt.hour.toString().padLeft(2, '0');
    final min = sourceModifiedAt.minute.toString().padLeft(2, '0');
    return '$m-$d $h:$min';
  }

  /// 完整显示名称（包含年份）
  ///
  /// 例如: "2025-12-14 19:43:55"
  String get fullDisplayName {
    final y = sourceModifiedAt.year;
    final m = sourceModifiedAt.month.toString().padLeft(2, '0');
    final d = sourceModifiedAt.day.toString().padLeft(2, '0');
    final h = sourceModifiedAt.hour.toString().padLeft(2, '0');
    final min = sourceModifiedAt.minute.toString().padLeft(2, '0');
    final s = sourceModifiedAt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  /// 格式化的文件大小
  ///
  /// 例如: "12.5 MB"
  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 状态文本
  String get statusText {
    switch (status) {
      case VersionStatus.importing:
        return '导入中';
      case VersionStatus.ready:
        return '可用';
      case VersionStatus.active:
        return '当前使用';
      case VersionStatus.failed:
        return '导入失败';
    }
  }

  /// 复制并修改部分属性
  DataVersion copyWith({
    String? versionId,
    String? sourceFileName,
    DateTime? importedAt,
    DateTime? sourceModifiedAt,
    int? topicCount,
    int? messageCount,
    int? fileSizeBytes,
    String? isarPath,
    bool? isLocked,
    VersionStatus? status,
  }) {
    return DataVersion(
      versionId: versionId ?? this.versionId,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      importedAt: importedAt ?? this.importedAt,
      sourceModifiedAt: sourceModifiedAt ?? this.sourceModifiedAt,
      topicCount: topicCount ?? this.topicCount,
      messageCount: messageCount ?? this.messageCount,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      isarPath: isarPath ?? this.isarPath,
      isLocked: isLocked ?? this.isLocked,
      status: status ?? this.status,
    );
  }

  /// 从 JSON Map 创建
  factory DataVersion.fromJson(Map<String, dynamic> json) {
    return DataVersion(
      versionId: json['versionId'] as String,
      sourceFileName: json['sourceFileName'] as String,
      importedAt: DateTime.fromMillisecondsSinceEpoch(json['importedAt'] as int),
      sourceModifiedAt:
          DateTime.fromMillisecondsSinceEpoch(json['sourceModifiedAt'] as int),
      topicCount: json['topicCount'] as int? ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      isarPath: json['isarPath'] as String,
      isLocked: json['isLocked'] as bool? ?? false,
      status: VersionStatus.values[json['status'] as int? ?? 0],
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'versionId': versionId,
      'sourceFileName': sourceFileName,
      'importedAt': importedAt.millisecondsSinceEpoch,
      'sourceModifiedAt': sourceModifiedAt.millisecondsSinceEpoch,
      'topicCount': topicCount,
      'messageCount': messageCount,
      'fileSizeBytes': fileSizeBytes,
      'isarPath': isarPath,
      'isLocked': isLocked,
      'status': status.index,
    };
  }

  @override
  String toString() {
    return 'DataVersion(versionId: $versionId, status: $status, '
        'topics: $topicCount, messages: $messageCount)';
  }
}
