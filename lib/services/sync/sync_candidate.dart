import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'sync_source_type.dart';

class SyncCandidate {
  final SyncSourceType sourceType;
  final String name;
  final String remoteId;
  final int size;
  final DateTime modifiedAt;
  final String? displayName;

  const SyncCandidate({
    required this.sourceType,
    required this.name,
    required this.remoteId,
    required this.size,
    required this.modifiedAt,
    this.displayName,
  });

  String get fingerprint {
    final payload = [
      name,
      size.toString(),
      modifiedAt.toUtc().millisecondsSinceEpoch.toString(),
    ].join('|');
    return sha1.convert(utf8.encode(payload)).toString();
  }
}

