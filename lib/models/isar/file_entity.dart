import 'package:isar_community/isar.dart';

part 'file_entity.g.dart';

/// 文件 Isar 实体
///
/// 存储附件信息，用于去重和本地缓存管理
/// 导入时将 files[] 复制到应用可访问目录并记录 hash
@collection
class FileEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 文件 ID（对应 Cherry Studio 导出的文件 id，唯一索引）
  @Index(unique: true)
  late String fileId;

  /// 文件名
  String? fileName;

  /// MIME 类型
  String? mimeType;

  /// 文件大小（字节）
  int? fileSize;

  /// SHA256 哈希值（用于去重）
  @Index()
  String? sha256;

  /// 拷贝到应用沙箱后的本地路径
  String? localPath;

  /// 原始 URL 备份
  String? url;

  /// 引用计数（用于清理孤立文件）
  late int referenceCount;

  /// 创建时间（毫秒时间戳）
  @Index()
  late int createdAt;

  /// 构造函数
  FileEntity();

  /// 从数据创建
  factory FileEntity.fromData({
    required String fileId,
    String? fileName,
    String? mimeType,
    int? fileSize,
    String? sha256,
    String? localPath,
    String? url,
    int referenceCount = 1,
    int? createdAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return FileEntity()
      ..fileId = fileId
      ..fileName = fileName
      ..mimeType = mimeType
      ..fileSize = fileSize
      ..sha256 = sha256
      ..localPath = localPath
      ..url = url
      ..referenceCount = referenceCount
      ..createdAt = createdAt ?? now;
  }

  /// 是否为图片文件
  bool get isImage {
    if (mimeType == null) return false;
    return mimeType!.startsWith('image/');
  }

  /// 是否有本地缓存
  bool get hasLocalCache => localPath != null && localPath!.isNotEmpty;

  /// 增加引用计数
  void incrementReference() {
    referenceCount++;
  }

  /// 减少引用计数
  void decrementReference() {
    if (referenceCount > 0) {
      referenceCount--;
    }
  }

  /// 是否可以删除（引用计数为 0）
  bool get canDelete => referenceCount <= 0;
}
