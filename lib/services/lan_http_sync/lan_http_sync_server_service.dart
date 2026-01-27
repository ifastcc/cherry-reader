import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../utils/platform_utils.dart';
import '../data_persistence_manager.dart';
import '../local_folder_sync_service.dart';
import 'lan_http_sync_config.dart';

sealed class LanHttpSyncServerStatus {
  const LanHttpSyncServerStatus();

  factory LanHttpSyncServerStatus.stopped() = LanHttpSyncStopped;
  factory LanHttpSyncServerStatus.running({
    required int port,
    required List<String> addresses,
  }) = LanHttpSyncRunning;
  factory LanHttpSyncServerStatus.error(String message) = LanHttpSyncError;

  bool get isRunning => this is LanHttpSyncRunning;
}

class LanHttpSyncStopped extends LanHttpSyncServerStatus {
  const LanHttpSyncStopped();
}

class LanHttpSyncRunning extends LanHttpSyncServerStatus {
  final int port;
  final List<String> addresses;
  const LanHttpSyncRunning({required this.port, required this.addresses});
}

class LanHttpSyncError extends LanHttpSyncServerStatus {
  final String message;
  const LanHttpSyncError(this.message);
}

class LanHttpSyncServerService {
  static final LanHttpSyncServerService _instance =
      LanHttpSyncServerService._internal();
  factory LanHttpSyncServerService() => _instance;
  static LanHttpSyncServerService get instance => _instance;

  LanHttpSyncServerService._internal();

  HttpServer? _server;
  bool _isRunning = false;
  int _port = LanHttpSyncConfig.defaultPort;
  List<String> _addresses = const [];
  LanHttpSyncConfig _config = LanHttpSyncConfig.defaults();
  bool _initialized = false;

  final _statusController =
      StreamController<LanHttpSyncServerStatus>.broadcast();
  Stream<LanHttpSyncServerStatus> get statusStream => _statusController.stream;

  LanHttpSyncServerStatus get currentStatus => _isRunning
      ? LanHttpSyncServerStatus.running(port: _port, addresses: _addresses)
      : LanHttpSyncServerStatus.stopped();

  LanHttpSyncConfig get config => _config;

  Future<void> init() async {
    if (_initialized) return;
    if (!PlatformUtils.isDesktop) return;

    _config = await LanHttpSyncConfig.load();
    _initialized = true;

    if (_config.enabled) {
      if (!_config.autoStart) {
        _config = _config.copyWith(autoStart: true);
        await _config.save();
      }
      await start(port: _config.port);
    }
  }

  Future<void> updateConfig(LanHttpSyncConfig newConfig) async {
    _config = newConfig;
    await _config.save();
  }

  Future<bool> start({int? port}) async {
    if (!_initialized) {
      await init();
    }
    if (!PlatformUtils.isDesktop) return false;
    if (_isRunning) return true;

    _port = port ?? _config.port;

    try {
      final router = _createRouter();
      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);

      _server = await shelf_io.serve(handler, '0.0.0.0', _port);
      _isRunning = true;
      _addresses = await _getLocalAddresses();
      _statusController.add(LanHttpSyncServerStatus.running(
        port: _port,
        addresses: _addresses,
      ));
      return true;
    } catch (e) {
      _statusController.add(LanHttpSyncServerStatus.error(e.toString()));
      return false;
    }
  }

  Future<void> stop() async {
    if (!_isRunning || _server == null) return;
    await _server!.close(force: true);
    _server = null;
    _isRunning = false;
    _addresses = const [];
    _statusController.add(LanHttpSyncServerStatus.stopped());
  }

  Future<bool> restart({int? port}) async {
    await stop();
    return start(port: port);
  }

  Router _createRouter() {
    final router = Router();
    router.get('/lan-sync/health', _handleHealth);
    router.get('/lan-sync/latest.zip', _handleLatestZip);
    return router;
  }

  Future<Response> _handleHealth(Request request) async {
    final auth = _authorize(request);
    if (auth != null) return auth;

    final selected = await _selectSourceFile();
    final fileInfo = selected == null ? null : await _describeFile(selected);
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'server': {'name': 'cherry-reader-lan-sync', 'version': '1.0'},
        'file': fileInfo,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleLatestZip(Request request) async {
    final auth = _authorize(request);
    if (auth != null) return auth;

    final selected = await _selectSourceFile();
    if (selected == null) {
      return Response.notFound(
        jsonEncode({'error': 'no_backup'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final file = File(selected);
    if (!await file.exists()) {
      return Response.notFound(
        jsonEncode({'error': 'not_found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final stat = await file.stat();
    final name = selected.split(Platform.pathSeparator).last;

    return Response.ok(
      file.openRead(),
      headers: {
        'Content-Type': 'application/zip',
        'Content-Length': stat.size.toString(),
        'Content-Disposition': 'attachment; filename="$name"',
        'Cache-Control': 'no-store',
        'X-Cherry-Sync-File-Name': name,
        'X-Cherry-Sync-File-Size': stat.size.toString(),
        'X-Cherry-Sync-File-Modified': stat.modified.toUtc().toIso8601String(),
      },
    );
  }

  Response? _authorize(Request request) {
    final token = _config.token.trim();
    if (token.isEmpty) return null;

    final header = request.headers['x-cherry-sync-token']?.trim();
    if (header != null && header == token) return null;

    final queryToken = request.url.queryParameters['token']?.trim();
    if (queryToken != null && queryToken == token) return null;

    return Response(
      401,
      body: jsonEncode({'error': 'unauthorized'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<String?> _selectSourceFile() async {
    try {
      final folderConfig = await LocalFolderSyncService.loadConfig();
      if (folderConfig.isValid) {
        final latest = await LocalFolderSyncService.findLatestBackup(folderConfig);
        if (latest != null) {
          final f = File(latest.path);
          if (await f.exists()) return latest.path;
        }
      }
    } catch (_) {}

    try {
      final appPath = await DataPersistenceManager.getAppDataFilePath();
      final f = File(appPath);
      if (await f.exists()) return appPath;
    } catch (_) {}

    return null;
  }

  Future<Map<String, dynamic>> _describeFile(String path) async {
    final file = File(path);
    final stat = await file.stat();
    return {
      'name': path.split(Platform.pathSeparator).last,
      'path': path,
      'size': stat.size,
      'modifiedAt': stat.modified.toUtc().toIso8601String(),
    };
  }

  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  Map<String, String> get _corsHeaders => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization, X-Cherry-Sync-Token',
      };

  Future<List<String>> _getLocalAddresses() async {
    final addresses = <String>['127.0.0.1'];
    try {
      for (final iface in await NetworkInterface.list()) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            addresses.add(addr.address);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 获取本机 IP 失败: $e');
    }
    return addresses;
  }
}
