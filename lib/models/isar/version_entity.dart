import 'package:isar_community/isar.dart';
import '../domain/data_version.dart';

part 'version_entity.g.dart';

/// 版本持久化实体
///
/// 存储在主数据库 (cherry_viewer.isar) 中，记录所有导入版本的元数据
@collection
class VersionEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 版本唯一标识，格式: "v-YYYYMMDD-HHMMSS"
  @Index(unique: true)
  late String versionId;

  /// 来源文件名
  late String sourceFileName;

  /// 导入时间（毫秒时间戳）
  @Index()
  late int importedAtMs;

  /// 源文件修改时间（毫秒时间戳）
  late int sourceModifiedAtMs;

  /// 话题数量
  late int topicCount;

  /// 消息数量
  late int messageCount;

  /// 数据库文件大小（字节）
  late int fileSizeBytes;

  /// Isar 数据库目录路径
  late String isarPath;

  /// 是否锁定
  late bool isLocked;

  /// 版本状态 (0=importing, 1=ready, 2=active, 3=failed)
  @Index()
  late int statusIndex;

  /// 构造函数
  VersionEntity();

  /// 从 DataVersion 创建
  factory VersionEntity.fromDataVersion(DataVersion version) {
    return VersionEntity()
      ..versionId = version.versionId
      ..sourceFileName = version.sourceFileName
      ..importedAtMs = version.importedAt.millisecondsSinceEpoch
      ..sourceModifiedAtMs = version.sourceModifiedAt.millisecondsSinceEpoch
      ..topicCount = version.topicCount
      ..messageCount = version.messageCount
      ..fileSizeBytes = version.fileSizeBytes
      ..isarPath = version.isarPath
      ..isLocked = version.isLocked
      ..statusIndex = version.status.index;
  }

  /// 转换为 DataVersion
  DataVersion toDataVersion() {
    return DataVersion(
      versionId: versionId,
      sourceFileName: sourceFileName,
      importedAt: DateTime.fromMillisecondsSinceEpoch(importedAtMs),
      sourceModifiedAt: DateTime.fromMillisecondsSinceEpoch(sourceModifiedAtMs),
      topicCount: topicCount,
      messageCount: messageCount,
      fileSizeBytes: fileSizeBytes,
      isarPath: isarPath,
      isLocked: isLocked,
      status: VersionStatus.values[statusIndex],
    );
  }

  /// 获取状态枚举（非 Isar 属性）
  VersionStatus getStatus() => VersionStatus.values[statusIndex];

  /// 设置状态枚举
  void setStatus(VersionStatus value) => statusIndex = value.index;
}
