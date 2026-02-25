import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../webdav_service.dart' show DataLoadMode, WebDavService;
import 'sync_candidate.dart';
import 'sync_source_type.dart';

class SyncPreferences {
  static const String _keyInitialized = 'sync_v2_initialized';
  static const String _keyAutoSources = 'sync_v2_auto_sources';
  static const String _keyLastImportedFingerprint = 'sync_v2_last_imported_fingerprint';
  static const String _keyLastImportedModified = 'sync_v2_last_imported_modified_ms';
  static const String _keyLastImportedSource = 'sync_v2_last_imported_source';
  static const String _keyInboxPrefix = 'sync_v2_inbox_candidate_';

  static const Map<String, bool> _defaultAutoSources = {
    'webdav': false,
    'localFolder': false,
    'lanReceive': false,
    'httpPull': false,
    'serverSync': false,
    'manualImport': false,
  };

  static Future<void> migrateFromLegacyIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool(_keyInitialized) ?? false;
    if (already) return;

    final legacyMode = await WebDavService.getLoadMode();
    final autoSources = Map<String, bool>.from(_defaultAutoSources);

    switch (legacyMode) {
      case DataLoadMode.webdav:
        autoSources[SyncSourceType.webdav.id] = true;
        break;
      case DataLoadMode.localFolder:
        autoSources[SyncSourceType.localFolder.id] = true;
        break;
      case DataLoadMode.manual:
        break;
    }

    await prefs.setString(_keyAutoSources, jsonEncode(autoSources));
    await prefs.setBool(_keyInitialized, true);
  }

  static Future<Map<SyncSourceType, bool>> getAutoSources() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAutoSources);
    Map<String, dynamic> decoded = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        final obj = jsonDecode(raw);
        if (obj is Map<String, dynamic>) decoded = obj;
      } catch (_) {}
    }

    final merged = Map<String, bool>.from(_defaultAutoSources);
    for (final entry in decoded.entries) {
      merged[entry.key] = entry.value == true;
    }

    final out = <SyncSourceType, bool>{};
    for (final t in SyncSourceType.values) {
      out[t] = merged[t.id] ?? false;
    }
    return out;
  }

  static Future<void> setAutoSourceEnabled(SyncSourceType type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getAutoSources();
    current[type] = enabled;
    final jsonMap = <String, bool>{};
    for (final e in current.entries) {
      jsonMap[e.key.id] = e.value;
    }
    await prefs.setString(_keyAutoSources, jsonEncode(jsonMap));
  }

  static Future<String?> getLastImportedFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyLastImportedFingerprint);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<DateTime?> getLastImportedModifiedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyLastImportedModified);
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setLastImported({
    required String fingerprint,
    required DateTime modifiedAt,
    required SyncSourceType sourceType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastImportedFingerprint, fingerprint);
    await prefs.setInt(_keyLastImportedModified, modifiedAt.millisecondsSinceEpoch);
    await prefs.setString(_keyLastImportedSource, sourceType.id);
  }

  static Future<void> clearLastImported() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastImportedFingerprint);
    await prefs.remove(_keyLastImportedModified);
    await prefs.remove(_keyLastImportedSource);
  }

  static String _inboxKey(SyncSourceType type) => '$_keyInboxPrefix${type.id}';

  static Future<void> setInboxCandidate(SyncCandidate candidate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _inboxKey(candidate.sourceType),
      jsonEncode({
        'sourceType': candidate.sourceType.id,
        'name': candidate.name,
        'remoteId': candidate.remoteId,
        'size': candidate.size,
        'modifiedAt': candidate.modifiedAt.toUtc().toIso8601String(),
        'displayName': candidate.displayName,
      }),
    );
  }

  static Future<SyncCandidate?> getInboxCandidate(SyncSourceType type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_inboxKey(type));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final name = decoded['name']?.toString() ?? '';
      final remoteId = decoded['remoteId']?.toString() ?? '';
      final size = (decoded['size'] is num)
          ? (decoded['size'] as num).toInt()
          : int.tryParse(decoded['size']?.toString() ?? '') ?? 0;
      final modifiedRaw = decoded['modifiedAt']?.toString() ?? '';
      final modifiedAt =
          DateTime.tryParse(modifiedRaw)?.toUtc() ?? DateTime(1970);
      final displayName = decoded['displayName']?.toString();
      return SyncCandidate(
        sourceType: type,
        name: name,
        remoteId: remoteId,
        size: size,
        modifiedAt: modifiedAt,
        displayName: displayName?.isEmpty == true ? null : displayName,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearInboxCandidate(SyncSourceType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_inboxKey(type));
  }

  static Future<SyncSourceType?> getLastImportedSourceType() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastImportedSource);
    if (raw == null || raw.isEmpty) return null;
    return SyncSourceType.fromId(raw);
  }

  static Future<void> applyLegacyChoice(DataLoadMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInitialized, true);

    final autoSources = Map<String, bool>.from(_defaultAutoSources);

    switch (mode) {
      case DataLoadMode.webdav:
        autoSources[SyncSourceType.webdav.id] = true;
        break;
      case DataLoadMode.localFolder:
        autoSources[SyncSourceType.localFolder.id] = true;
        break;
      case DataLoadMode.manual:
        break;
    }

    await prefs.setString(_keyAutoSources, jsonEncode(autoSources));
  }
}
