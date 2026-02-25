class ImportJobEntity {
  late String jobId;

  late String artifactId;

  late String sourceType;

  late String status;

  late int startedAt;

  int? finishedAt;

  String? statsJson;

  String? error;

  ImportJobEntity();

  factory ImportJobEntity.fromData({
    required String jobId,
    required String artifactId,
    required String sourceType,
    required String status,
    required int startedAt,
    int? finishedAt,
    String? statsJson,
    String? error,
  }) {
    return ImportJobEntity()
      ..jobId = jobId
      ..artifactId = artifactId
      ..sourceType = sourceType
      ..status = status
      ..startedAt = startedAt
      ..finishedAt = finishedAt
      ..statsJson = statsJson
      ..error = error;
  }
}
