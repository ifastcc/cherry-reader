import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'data_persistence_manager.dart';
import 'sync/sync_candidate.dart';
import 'sync/sync_preferences.dart';
import 'sync/sync_source_type.dart';

enum LanTransferReceiveStatus {
  idle,
  starting,
  advertising,
  waitingConnection,
  connected,
  receiving,
  verifying,
  completed,
  error,
}

class LanTransferReceiveState {
  final LanTransferReceiveStatus status;
  final String deviceName;
  final int? port;
  final String? connectedClientName;
  final String? message;
  final double? progress;
  final String? completedFilePath;
  final String? error;

  const LanTransferReceiveState({
    required this.status,
    required this.deviceName,
    this.port,
    this.connectedClientName,
    this.message,
    this.progress,
    this.completedFilePath,
    this.error,
  });

  LanTransferReceiveState copyWith({
    LanTransferReceiveStatus? status,
    String? deviceName,
    int? port,
    String? connectedClientName,
    String? message,
    double? progress,
    String? completedFilePath,
    String? error,
  }) {
    return LanTransferReceiveState(
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      port: port ?? this.port,
      connectedClientName: connectedClientName ?? this.connectedClientName,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      completedFilePath: completedFilePath ?? this.completedFilePath,
      error: error ?? this.error,
    );
  }
}

class LanTransferReceiveService {
  static const String serviceTypeFullName = '_cherrystudio._tcp';
  static const String protocolVersion = '1';
  static const int _maxJsonLineLength = 64 * 1024;
  static const int _magicC = 0x43;
  static const int _magicS = 0x53;
  static const int _binaryTypeFileChunk = 0x01;

  final ValueNotifier<LanTransferReceiveState> notifier;

  ServerSocket? _server;
  Socket? _client;
  BonsoirBroadcast? _broadcast;
  Uint8List _buffer = Uint8List(0);

  _ActiveTransfer? _transfer;

  LanTransferReceiveService({String? deviceName})
      : notifier = ValueNotifier(
          LanTransferReceiveState(
            status: LanTransferReceiveStatus.idle,
            deviceName: deviceName ?? _buildDefaultDeviceName(),
          ),
        );

  static String _buildDefaultDeviceName() {
    final os = Platform.isIOS
        ? 'iOS'
        : Platform.isAndroid
            ? 'Android'
            : Platform.operatingSystem;
    return 'Cherry Reader ($os)';
  }

  bool get isRunning =>
      notifier.value.status != LanTransferReceiveStatus.idle &&
      notifier.value.status != LanTransferReceiveStatus.completed &&
      notifier.value.status != LanTransferReceiveStatus.error;

  Future<void> start() async {
    if (_server != null) return;

    notifier.value = notifier.value.copyWith(
      status: LanTransferReceiveStatus.starting,
      message: '启动接收服务...',
      error: null,
      completedFilePath: null,
      progress: null,
      connectedClientName: null,
    );

    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0, shared: true);
      notifier.value = notifier.value.copyWith(
        port: _server!.port,
        status: LanTransferReceiveStatus.advertising,
        message: '发布局域网服务...',
      );

      await _startBroadcast(_server!.port);

      notifier.value = notifier.value.copyWith(
        status: LanTransferReceiveStatus.waitingConnection,
        message: '等待桌面端连接...',
      );

      _server!.listen(_handleClient, onError: _onServerError, onDone: () {});
    } catch (e) {
      await stop();
      notifier.value = notifier.value.copyWith(
        status: LanTransferReceiveStatus.error,
        error: '启动失败：$e',
      );
    }
  }

  Future<void> stop() async {
    await _shutdownNetwork(resetState: true);
  }

  Future<void> _shutdownNetwork({required bool resetState}) async {
    try {
      await _broadcast?.stop();
    } catch (_) {}
    _broadcast = null;

    try {
      _client?.destroy();
    } catch (_) {}
    _client = null;

    try {
      await _server?.close();
    } catch (_) {}
    _server = null;

    _buffer = Uint8List(0);
    await _transfer?.dispose();
    _transfer = null;

    if (resetState) {
      notifier.value = notifier.value.copyWith(
        status: LanTransferReceiveStatus.idle,
        message: null,
        progress: null,
        connectedClientName: null,
        port: null,
      );
    }
  }

  Future<void> dispose() async {
    await stop();
    notifier.dispose();
  }

  Future<void> _startBroadcast(int port) async {
    final service = BonsoirService(
      name: notifier.value.deviceName,
      type: serviceTypeFullName,
      port: port,
      attributes: {
        'version': protocolVersion,
        'platform': Platform.operatingSystem,
        'appVersion': 'unknown',
      },
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  void _onServerError(Object error) {
    notifier.value = notifier.value.copyWith(
      status: LanTransferReceiveStatus.error,
      error: '服务错误：$error',
    );
  }

  void _handleClient(Socket socket) {
    _client?.destroy();
    _client = socket;
    _buffer = Uint8List(0);
    _transfer?.dispose();
    _transfer = null;

    notifier.value = notifier.value.copyWith(
      status: LanTransferReceiveStatus.connected,
      message: '已连接，等待握手...',
      progress: null,
      connectedClientName: null,
    );

    socket.listen(
      (data) {
        _appendToBuffer(data);
        _drainMessages();
      },
      onError: (e) {
        notifier.value = notifier.value.copyWith(
          status: LanTransferReceiveStatus.error,
          error: '连接错误：$e',
        );
        _client?.destroy();
        _client = null;
        unawaited(_shutdownNetwork(resetState: false));
      },
      onDone: () {
        _client = null;
        if (notifier.value.status != LanTransferReceiveStatus.completed &&
            notifier.value.status != LanTransferReceiveStatus.error &&
            _server != null) {
          notifier.value = notifier.value.copyWith(
            status: LanTransferReceiveStatus.waitingConnection,
            message: '连接已断开，等待下一次连接...',
            connectedClientName: null,
          );
        }
      },
      cancelOnError: true,
    );
  }

  void _appendToBuffer(Uint8List data) {
    if (_buffer.isEmpty) {
      _buffer = data;
      return;
    }
    final merged = Uint8List(_buffer.length + data.length);
    merged.setRange(0, _buffer.length, _buffer);
    merged.setRange(_buffer.length, merged.length, data);
    _buffer = merged;
  }

  void _drainMessages() {
    while (_buffer.isNotEmpty) {
      if (_buffer.length >= 2 && _buffer[0] == _magicC && _buffer[1] == _magicS) {
        final consumed = _tryParseBinaryChunk();
        if (consumed == 0) return;
        _buffer = _buffer.sublist(consumed);
        continue;
      }

      if (_buffer[0] == 0x7B) {
        final consumed = _tryParseJsonLine();
        if (consumed == 0) return;
        _buffer = _buffer.sublist(consumed);
        continue;
      }

      _buffer = _buffer.sublist(1);
    }
  }

  int _tryParseJsonLine() {
    final newline = _buffer.indexOf(0x0A);
    if (newline < 0) {
      if (_buffer.length > _maxJsonLineLength) {
        _buffer = Uint8List(0);
        notifier.value = notifier.value.copyWith(
          status: LanTransferReceiveStatus.error,
          error: '接收的数据异常（JSON 行过长）',
        );
      }
      return 0;
    }

    final lineBytes = _buffer.sublist(0, newline);
    final raw = utf8.decode(lineBytes, allowMalformed: true);
    final consumed = newline + 1;

    Map<String, dynamic>? msg;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        msg = decoded;
      }
    } catch (_) {}

    if (msg == null) {
      _sendJson({
        'type': 'error',
        'error': 'Invalid JSON message format',
        'errorCode': 'PARSE_ERROR',
      });
      return consumed;
    }

    _handleJsonMessage(msg);
    return consumed;
  }

  int _tryParseBinaryChunk() {
    if (_buffer.length < 6) return 0;

    final totalLen = _readUint32BE(_buffer, 2);
    final frameLen = 6 + totalLen;
    if (_buffer.length < frameLen) return 0;

    final type = _buffer[6];
    if (type != _binaryTypeFileChunk) {
      return frameLen;
    }

    final transferIdLen = _readUint16BE(_buffer, 7);
    final transferIdStart = 9;
    final transferIdEnd = transferIdStart + transferIdLen;
    if (transferIdEnd + 4 > frameLen) return frameLen;

    final transferId = utf8.decode(_buffer.sublist(transferIdStart, transferIdEnd), allowMalformed: true);
    final chunkIndex = _readUint32BE(_buffer, transferIdEnd);
    final dataStart = transferIdEnd + 4;
    final dataLen = totalLen - (1 + 2 + transferIdLen + 4);
    final dataEnd = dataStart + dataLen;
    if (dataEnd > frameLen) return frameLen;

    final data = _buffer.sublist(dataStart, dataEnd);
    _handleBinaryChunk(transferId, chunkIndex, data);

    return frameLen;
  }

  void _handleJsonMessage(Map<String, dynamic> msg) {
    final type = msg['type'];
    if (type == 'handshake') {
      final version = msg['version']?.toString();
      final deviceName = msg['deviceName']?.toString();
      if (version != protocolVersion) {
        _sendJson({
          'type': 'handshake_ack',
          'accepted': false,
          'message': 'Protocol mismatch',
        });
        _client?.destroy();
        _client = null;
        notifier.value = notifier.value.copyWith(
          status: LanTransferReceiveStatus.error,
          error: '协议版本不匹配：$version',
        );
        unawaited(_shutdownNetwork(resetState: false));
        return;
      }

      notifier.value = notifier.value.copyWith(
        connectedClientName: deviceName ?? 'Cherry Studio',
        message: '握手成功，等待文件...',
      );

      _sendJson({'type': 'handshake_ack', 'accepted': true});
      return;
    }

    if (type == 'ping') {
      _sendJson({'type': 'pong', 'payload': msg['payload']});
      return;
    }

    if (type == 'file_start') {
      _handleFileStart(msg);
      return;
    }

    if (type == 'file_end') {
      _handleFileEnd(msg);
      return;
    }
  }

  Future<void> _handleFileStart(Map<String, dynamic> msg) async {
    final transferId = msg['transferId']?.toString();
    final fileName = msg['fileName']?.toString();
    final fileSize = (msg['fileSize'] is num) ? (msg['fileSize'] as num).toInt() : null;
    final checksum = msg['checksum']?.toString();
    final totalChunks = (msg['totalChunks'] is num) ? (msg['totalChunks'] as num).toInt() : null;
    final chunkSize = (msg['chunkSize'] is num) ? (msg['chunkSize'] as num).toInt() : null;

    if (transferId == null ||
        fileName == null ||
        fileSize == null ||
        checksum == null ||
        totalChunks == null ||
        chunkSize == null) {
      _sendJson({
        'type': 'file_start_ack',
        'transferId': transferId ?? '',
        'accepted': false,
        'message': 'Invalid file_start payload',
      });
      return;
    }

    if (!fileName.toLowerCase().endsWith('.zip')) {
      _sendJson({
        'type': 'file_start_ack',
        'transferId': transferId,
        'accepted': false,
        'message': 'Only .zip is supported',
      });
      return;
    }

    await _transfer?.dispose();
    _transfer = await _ActiveTransfer.create(
      transferId: transferId,
      fileName: fileName,
      fileSize: fileSize,
      checksumHex: checksum,
      totalChunks: totalChunks,
      chunkSize: chunkSize,
    );

    notifier.value = notifier.value.copyWith(
      status: LanTransferReceiveStatus.receiving,
      message: '接收中：$fileName',
      progress: 0,
      error: null,
      completedFilePath: null,
    );

    _sendJson({'type': 'file_start_ack', 'transferId': transferId, 'accepted': true});
  }

  Future<void> _handleBinaryChunk(String transferId, int chunkIndex, List<int> data) async {
    final transfer = _transfer;
    if (transfer == null || transfer.transferId != transferId) return;

    try {
      await transfer.addChunk(chunkIndex, data);
      final progress = transfer.receivedBytes / transfer.fileSize;
      notifier.value = notifier.value.copyWith(
        status: LanTransferReceiveStatus.receiving,
        progress: progress.clamp(0.0, 1.0),
        message: '接收中 ${(progress * 100).toStringAsFixed(1)}%',
      );
    } catch (e) {
      notifier.value = notifier.value.copyWith(
        status: LanTransferReceiveStatus.error,
        error: '接收失败：$e',
      );
      _client?.destroy();
      _client = null;
      unawaited(_shutdownNetwork(resetState: false));
    }
  }

  Future<void> _handleFileEnd(Map<String, dynamic> msg) async {
    final transferId = msg['transferId']?.toString();
    final transfer = _transfer;
    if (transfer == null || transferId == null || transfer.transferId != transferId) return;

    notifier.value = notifier.value.copyWith(
      status: LanTransferReceiveStatus.verifying,
      message: '校验文件...',
      progress: 1.0,
    );

    try {
      final savedPath = await transfer.finalizeToAppData();
      try {
        final stat = await File(savedPath).stat();
        await SyncPreferences.setInboxCandidate(
          SyncCandidate(
            sourceType: SyncSourceType.lanReceive,
            name: transfer.fileName,
            remoteId: savedPath,
            size: stat.size,
            modifiedAt: stat.modified.toUtc(),
          ),
        );
      } catch (_) {}
      notifier.value = notifier.value.copyWith(
        status: LanTransferReceiveStatus.completed,
        message: '接收完成',
        completedFilePath: savedPath,
      );
      _sendJson({'type': 'file_complete', 'transferId': transferId, 'success': true, 'filePath': savedPath});
    } catch (e) {
      notifier.value = notifier.value.copyWith(
        status: LanTransferReceiveStatus.error,
        error: '校验失败：$e',
      );
      _sendJson({'type': 'file_complete', 'transferId': transferId, 'success': false, 'error': '$e'});
    } finally {
      await _transfer?.dispose();
      _transfer = null;
      await _shutdownNetwork(resetState: false);
    }
  }

  void _sendJson(Map<String, dynamic> payload) {
    final socket = _client;
    if (socket == null) return;
    final encoded = utf8.encode('${jsonEncode(payload)}\n');
    socket.add(encoded);
    socket.flush();
  }

  static int _readUint16BE(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  static int _readUint32BE(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}

class _ActiveTransfer {
  final String transferId;
  final String fileName;
  final int fileSize;
  final String checksumHex;
  final int totalChunks;
  final int chunkSize;

  final File tempFile;
  final IOSink sink;
  int receivedBytes = 0;
  int expectedChunkIndex = 0;

  _ActiveTransfer._({
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    required this.checksumHex,
    required this.totalChunks,
    required this.chunkSize,
    required this.tempFile,
    required this.sink,
  });

  static Future<_ActiveTransfer> create({
    required String transferId,
    required String fileName,
    required int fileSize,
    required String checksumHex,
    required int totalChunks,
    required int chunkSize,
  }) async {
    final tmpDir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final tempPath = p.join(tmpDir.path, 'lan_transfer_$transferId.$safeName.part');
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    final sink = tempFile.openWrite(mode: FileMode.writeOnlyAppend);
    return _ActiveTransfer._(
      transferId: transferId,
      fileName: fileName,
      fileSize: fileSize,
      checksumHex: checksumHex,
      totalChunks: totalChunks,
      chunkSize: chunkSize,
      tempFile: tempFile,
      sink: sink,
    );
  }

  Future<void> addChunk(int chunkIndex, List<int> data) async {
    if (chunkIndex != expectedChunkIndex) {
      throw Exception('Chunk out of order: expected $expectedChunkIndex, got $chunkIndex');
    }
    sink.add(data);
    receivedBytes += data.length;
    expectedChunkIndex += 1;
    if (expectedChunkIndex > totalChunks) {
      throw Exception('Too many chunks');
    }
  }

  Future<String> finalizeToAppData() async {
    await sink.flush();
    await sink.close();

    final statSize = await tempFile.length();
    if (statSize != fileSize) {
      throw Exception('File size mismatch ($statSize != $fileSize)');
    }

    final digest = await _sha256Hex(tempFile);
    if (digest.toLowerCase() != checksumHex.toLowerCase()) {
      throw Exception('Checksum mismatch');
    }

    final appPath = await DataPersistenceManager.getAppDataFilePath();
    final dst = File(appPath);
    if (await dst.exists()) {
      await dst.delete();
    }
    await tempFile.copy(appPath);
    await tempFile.delete();
    await DataPersistenceManager.clearCache();
    return appPath;
  }

  Future<void> dispose() async {
    try {
      await sink.flush();
    } catch (_) {}
    try {
      await sink.close();
    } catch (_) {}
    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {}
  }

  static Future<String> _sha256Hex(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
