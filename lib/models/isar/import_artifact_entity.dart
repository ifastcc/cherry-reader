class ImportArtifactEntity {
  late String artifactId;

  late String sourceType;

  String? fileName;

  String? sourcePath;

  int? fileSize;

  String? sha256;

  late int createdAt;

  ImportArtifactEntity();

  factory ImportArtifactEntity.fromData({
    required String artifactId,
    required String sourceType,
    String? fileName,
    String? sourcePath,
    int? fileSize,
    String? sha256,
    int? createdAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ImportArtifactEntity()
      ..artifactId = artifactId
      ..sourceType = sourceType
      ..fileName = fileName
      ..sourcePath = sourcePath
      ..fileSize = fileSize
      ..sha256 = sha256
      ..createdAt = createdAt ?? now;
  }
}
