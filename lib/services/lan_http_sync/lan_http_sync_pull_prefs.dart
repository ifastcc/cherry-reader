import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../data_persistence_manager.dart';

class LanHttpSyncRemoteFileInfo {
  final String name;
  final int size;
  final DateTime modifiedAt;

  const LanHttpSyncRemoteFileInfo({
    required this.name,
    required this.size,
    required this.modifiedAt,
  });
}

class LanHttpSyncPullImportData {
  final String baseUrl;
  final String token;

  const LanHttpSyncPullImportData({
    required this.baseUrl,
    required this.token,
  });
}

class LanHttpSyncPullPrefs {
  static const String keyBaseUrl = 'lan_http_sync_pull_base_url';
  static const String keyToken = 'lan_http_sync_pull_token';

  final String baseUrl;
  final String token;

  const LanHttpSyncPullPrefs({
    required this.baseUrl,
    required this.token,
  });

  static Future<LanHttpSyncPullPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LanHttpSyncPullPrefs(
      baseUrl: prefs.getString(keyBaseUrl) ?? 'http://',
      token: prefs.getString(keyToken) ?? '',
    );
  }

  static Future<void> save({required String baseUrl, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, baseUrl.trim());
    await prefs.setString(keyToken, token.trim());
  }

  static String buildHealthUrl(String base) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('/lan-sync/health')) return trimmed;
    final normalized =
        trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    return '$normalized/lan-sync/health';
  }

  static String buildDownloadUrl(String base) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('/lan-sync/latest.zip')) return trimmed;
    final normalized =
        trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    return '$normalized/lan-sync/latest.zip';
  }

  static String buildImportString({required String baseUrl, required String token}) {
    final normalizedBaseUrl = normalizeBaseUrl(baseUrl);
    if (normalizedBaseUrl.isEmpty) return '';
    final uri = Uri(
      scheme: 'cherryviewer',
      host: 'lan-http-sync',
      queryParameters: {
        'baseUrl': normalizedBaseUrl,
        if (token.trim().isNotEmpty) 'token': token.trim(),
      },
    );
    return uri.toString();
  }

  static LanHttpSyncPullImportData? parseImportText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final baseUrl = decoded['baseUrl']?.toString() ?? decoded['url']?.toString() ?? '';
          final token = decoded['token']?.toString() ?? decoded['sk']?.toString() ?? '';
          final normalizedBaseUrl = normalizeBaseUrl(baseUrl);
          if (normalizedBaseUrl.isEmpty) return null;
          return LanHttpSyncPullImportData(baseUrl: normalizedBaseUrl, token: token.trim());
        }
      } catch (_) {}
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final baseUrl = _originFromUri(uri);
      if (baseUrl.isEmpty) return null;
      final token = uri.queryParameters['token']?.trim() ?? '';
      return LanHttpSyncPullImportData(baseUrl: baseUrl, token: token);
    }

    if (uri.scheme == 'cherryviewer') {
      final baseUrl =
          uri.queryParameters['baseUrl']?.trim() ?? uri.queryParameters['url']?.trim() ?? '';
      final token = uri.queryParameters['token']?.trim() ??
          uri.queryParameters['sk']?.trim() ??
          '';
      final normalizedBaseUrl = normalizeBaseUrl(baseUrl);
      if (normalizedBaseUrl.isEmpty) return null;
      return LanHttpSyncPullImportData(baseUrl: normalizedBaseUrl, token: token);
    }

    if (trimmed.contains('baseUrl=') || trimmed.contains('token=')) {
      try {
        final fake = Uri.tryParse('scheme://host/?$trimmed');
        if (fake == null) return null;
        final baseUrl =
            fake.queryParameters['baseUrl']?.trim() ?? fake.queryParameters['url']?.trim() ?? '';
        final token = fake.queryParameters['token']?.trim() ?? fake.queryParameters['sk']?.trim() ?? '';
        final normalizedBaseUrl = normalizeBaseUrl(baseUrl);
        if (normalizedBaseUrl.isEmpty) return null;
        return LanHttpSyncPullImportData(baseUrl: normalizedBaseUrl, token: token);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static String normalizeBaseUrl(String baseUrlOrFullUrl) {
    final trimmed = baseUrlOrFullUrl.trim();
    if (trimmed.isEmpty) return '';

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (uri.host.isEmpty) return trimmed;
      return _originFromUri(uri);
    }

    return trimmed;
  }

  static String _originFromUri(Uri uri) {
    if (uri.host.isEmpty) return '';
    final hasPort = uri.hasPort && uri.port > 0;
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: hasPort ? uri.port : 0,
    ).toString();
  }

  static Future<LanHttpSyncRemoteFileInfo?> fetchLatestInfo({
    required String baseUrl,
    required String token,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final url = buildHealthUrl(baseUrl);
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final req = await client.getUrl(uri).timeout(timeout);
      if (token.trim().isNotEmpty) {
        req.headers.set('x-cherry-sync-token', token.trim());
      }
      final resp = await req.close().timeout(timeout);
      if (resp.statusCode != 200) return null;
      final body = await utf8.decodeStream(resp);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final file = decoded['file'];
      if (file is! Map<String, dynamic>) return null;
      final name = file['name']?.toString() ?? '';
      final size = (file['size'] is num)
          ? (file['size'] as num).toInt()
          : int.tryParse(file['size']?.toString() ?? '') ?? 0;
      final modifiedRaw = file['modifiedAt']?.toString() ?? '';
      final modifiedAt = DateTime.tryParse(modifiedRaw)?.toUtc();
      if (name.isEmpty || modifiedAt == null) return null;
      return LanHttpSyncRemoteFileInfo(
        name: name,
        size: size,
        modifiedAt: modifiedAt,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<String?> downloadLatestToAppData({
    required String baseUrl,
    required String token,
    void Function(int received, int total)? onProgress,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final url = buildDownloadUrl(baseUrl);
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final targetPath = await DataPersistenceManager.getAppDataFilePath();
    final tmpPath = '$targetPath.tmp';

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final tmpFile = File(tmpPath);
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }

      final req = await client.getUrl(uri);
      if (token.trim().isNotEmpty) {
        req.headers.set('x-cherry-sync-token', token.trim());
      }
      final resp = await req.close().timeout(timeout);
      if (resp.statusCode != 200) return null;

      final total = resp.contentLength > 0 ? resp.contentLength : -1;
      var received = 0;
      final sink = tmpFile.openWrite(mode: FileMode.writeOnlyAppend);
      try {
        await for (final chunk in resp) {
          received += chunk.length;
          sink.add(chunk);
          onProgress?.call(received, total);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      final finalFile = File(targetPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tmpFile.rename(targetPath);

      await DataPersistenceManager.clearCache();
      return targetPath;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
