import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class LanTransferPeer {
  final String name;
  final String host;
  final int port;
  final Map<String, String> attributes;

  const LanTransferPeer({
    required this.name,
    required this.host,
    required this.port,
    required this.attributes,
  });
}

enum LanTransferSendStatus {
  idle,
  connecting,
  handshaking,
  preparing,
  transferring,
  completing,
  completed,
  error,
}

class LanTransferSendState {
  final LanTransferSendStatus status;
  final String? peerName;
  final String? message;
  final double? progress;
  final String? error;

  const LanTransferSendState({
    required this.status,
    this.peerName,
    this.message,
    this.progress,
    this.error,
  });

  LanTransferSendState copyWith({
    LanTransferSendStatus? status,
    String? peerName,
    String? message,
    double? progress,
    String? error,
  }) {
    return LanTransferSendState(
      status: status ?? this.status,
      peerName: peerName ?? this.peerName,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

class LanTransferSendService {
  static const String protocolVersion = '1';
  static const int chunkSizeBytes = 512 * 1024;
  static const int _magicC = 0x43;
  static const int _magicS = 0x53;
  static const int _binaryTypeFileChunk = 0x01;

  final ValueNotifier<LanTransferSendState> notifier = ValueNotifier(
    const LanTransferSendState(status: LanTransferSendStatus.idle),
  );

  Socket? _socket;
  final _lineBuffer = StringBuffer();
  final _pending = <String, Completer<Map<String, dynamic>>>{};

  Future<void> dispose() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('disposed'));
      }
    }
    _pending.clear();
    notifier.dispose();
  }

  Future<void> sendZipToPeer({
    required LanTransferPeer peer,
    required String zipPath,
    String? deviceName,
    Duration handshakeTimeout = const Duration(seconds: 10),
    Duration startAckTimeout = const Duration(seconds: 10),
    Duration completeTimeout = const Duration(seconds: 60),
  }) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      notifier.value = notifier.value.copyWith(
        status: LanTransferSendStatus.error,
        error: '文件不存在：$zipPath',
      );
      return;
    }

    notifier.value = notifier.value.copyWith(
      status: LanTransferSendStatus.connecting,
      peerName: peer.name,
      message: '连接中...',
      progress: null,
      error: null,
    );

    try {
      final socket = await Socket.connect(peer.host, peer.port, timeout: handshakeTimeout);
      _socket = socket;
      socket.setOption(SocketOption.tcpNoDelay, true);
      socket.listen(
        _onData,
        onError: (e) => _failAll('连接错误：$e'),
        onDone: () => _failAll('连接已断开'),
        cancelOnError: true,
      );

      notifier.value = notifier.value.copyWith(status: LanTransferSendStatus.handshaking, message: '握手中...');
      await _sendHandshake(deviceName: deviceName ?? 'Cherry Reader Desktop', timeout: handshakeTimeout);

      notifier.value = notifier.value.copyWith(status: LanTransferSendStatus.preparing, message: '计算校验和...');
      final checksum = await _sha256Hex(file);
      final fileSize = await file.length();
      final totalChunks = (fileSize / chunkSizeBytes).ceil();
      final transferId = _uuid();

      notifier.value = notifier.value.copyWith(status: LanTransferSendStatus.preparing, message: '等待接收确认...');
      await _sendFileStart(
        transferId: transferId,
        fileName: file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'backup.zip',
        fileSize: fileSize,
        checksum: checksum,
        totalChunks: totalChunks,
        timeout: startAckTimeout,
      );

      notifier.value = notifier.value.copyWith(status: LanTransferSendStatus.transferring, message: '传输中...', progress: 0);
      await _streamFileChunks(file, transferId, totalChunks);

      notifier.value = notifier.value.copyWith(status: LanTransferSendStatus.completing, message: '等待完成确认...', progress: 1.0);
      _sendJson({'type': 'file_end', 'transferId': transferId});
      await _waitFor('file_complete', timeout: completeTimeout);

      notifier.value = notifier.value.copyWith(status: LanTransferSendStatus.completed, message: '已发送完成', progress: 1.0);
    } catch (e) {
      notifier.value = notifier.value.copyWith(status: LanTransferSendStatus.error, error: '$e');
    } finally {
      try {
        await _socket?.close();
      } catch (_) {}
      _socket = null;
      _pending.clear();
    }
  }

  void _onData(Uint8List data) {
    final text = utf8.decode(data, allowMalformed: true);
    for (final rune in text.runes) {
      if (rune == 0x0A) {
        final line = _lineBuffer.toString();
        _lineBuffer.clear();
        if (line.isEmpty) continue;
        _handleLine(line);
      } else {
        _lineBuffer.writeCharCode(rune);
      }
    }
  }

  void _handleLine(String line) {
    Map<String, dynamic>? msg;
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) {
        msg = decoded;
      }
    } catch (_) {}
    if (msg == null) return;

    final type = msg['type']?.toString();
    if (type == null) return;

    if (type == 'handshake_ack') {
      _completePending('handshake_ack', msg);
      return;
    }
    if (type == 'file_start_ack') {
      _completePending('file_start_ack', msg);
      return;
    }
    if (type == 'file_complete') {
      _completePending('file_complete', msg);
      return;
    }
  }

  void _completePending(String key, Map<String, dynamic> msg) {
    final c = _pending.remove(key);
    if (c == null || c.isCompleted) return;
    c.complete(msg);
  }

  void _failAll(String error) {
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(Exception(error));
      }
    }
    _pending.clear();
  }

  Future<void> _sendHandshake({required String deviceName, required Duration timeout}) async {
    _sendJson({
      'type': 'handshake',
      'deviceName': deviceName,
      'version': protocolVersion,
      'platform': Platform.operatingSystem,
      'appVersion': 'unknown',
    });

    final ack = await _waitFor('handshake_ack', timeout: timeout);
    final accepted = ack['accepted'] == true;
    if (!accepted) {
      throw Exception(ack['message']?.toString() ?? '握手被拒绝');
    }
  }

  Future<void> _sendFileStart({
    required String transferId,
    required String fileName,
    required int fileSize,
    required String checksum,
    required int totalChunks,
    required Duration timeout,
  }) async {
    _sendJson({
      'type': 'file_start',
      'transferId': transferId,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': 'application/zip',
      'checksum': checksum,
      'totalChunks': totalChunks,
      'chunkSize': chunkSizeBytes,
    });

    final ack = await _waitFor('file_start_ack', timeout: timeout);
    final accepted = ack['accepted'] == true;
    if (!accepted) {
      throw Exception(ack['message']?.toString() ?? '接收端拒绝文件');
    }
  }

  Future<Map<String, dynamic>> _waitFor(String type, {required Duration timeout}) {
    final c = Completer<Map<String, dynamic>>();
    _pending[type] = c;
    return c.future.timeout(timeout, onTimeout: () {
      _pending.remove(type);
      throw TimeoutException('等待 $type 超时');
    });
  }

  void _sendJson(Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null) {
      throw StateError('Socket not connected');
    }
    socket.add(utf8.encode('${jsonEncode(payload)}\n'));
  }

  Future<void> _streamFileChunks(File file, String transferId, int totalChunks) async {
    final socket = _socket;
    if (socket == null) throw StateError('Socket not connected');

    final fileSize = await file.length();
    var sentBytes = 0;
    var chunkIndex = 0;

    final raf = await file.open(mode: FileMode.read);
    try {
      while (sentBytes < fileSize) {
        final remaining = fileSize - sentBytes;
        final size = remaining >= chunkSizeBytes ? chunkSizeBytes : remaining;
        final data = await raf.read(size);

        final frame = _buildFileChunkFrame(
          transferId: transferId,
          chunkIndex: chunkIndex,
          data: data,
        );
        socket.add(frame);

        sentBytes += data.length;
        chunkIndex += 1;

        final progress = sentBytes / fileSize;
        notifier.value = notifier.value.copyWith(
          status: LanTransferSendStatus.transferring,
          progress: progress.clamp(0.0, 1.0),
          message: '传输中 ${(progress * 100).toStringAsFixed(1)}%（$chunkIndex/$totalChunks）',
        );
      }
    } finally {
      await raf.close();
    }
  }

  Uint8List _buildFileChunkFrame({
    required String transferId,
    required int chunkIndex,
    required Uint8List data,
  }) {
    final transferIdBytes = utf8.encode(transferId);
    final transferIdLen = transferIdBytes.length;

    final totalLen = 1 + 2 + transferIdLen + 4 + data.length;
    final frame = BytesBuilder(copy: false);
    frame.add([_magicC, _magicS]);
    frame.add(_uint32be(totalLen));
    frame.add([_binaryTypeFileChunk]);
    frame.add(_uint16be(transferIdLen));
    frame.add(transferIdBytes);
    frame.add(_uint32be(chunkIndex));
    frame.add(data);
    return frame.takeBytes();
  }

  static List<int> _uint16be(int value) => [(value >> 8) & 0xFF, value & 0xFF];

  static List<int> _uint32be(int value) => [
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  static Future<String> _sha256Hex(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  static String _uuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    String hex(int v) => v.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b.sublist(0, 4).join()}-${b.sublist(4, 6).join()}-${b.sublist(6, 8).join()}-${b.sublist(8, 10).join()}-${b.sublist(10, 16).join()}';
  }
}
