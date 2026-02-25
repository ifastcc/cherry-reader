class ProvenanceRecordEntity {
  late String sourceType;

  late String entityType;

  late String externalId;

  late String entityId;

  String? parentExternalId;

  String? fingerprint;

  late int firstSeenAt;

  late int lastSeenAt;

  ProvenanceRecordEntity();

  factory ProvenanceRecordEntity.fromData({
    required String sourceType,
    required String entityType,
    required String externalId,
    required String entityId,
    String? parentExternalId,
    String? fingerprint,
    int? firstSeenAt,
    int? lastSeenAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ProvenanceRecordEntity()
      ..sourceType = sourceType
      ..entityType = entityType
      ..externalId = externalId
      ..entityId = entityId
      ..parentExternalId = parentExternalId
      ..fingerprint = fingerprint
      ..firstSeenAt = firstSeenAt ?? now
      ..lastSeenAt = lastSeenAt ?? now;
  }
}
