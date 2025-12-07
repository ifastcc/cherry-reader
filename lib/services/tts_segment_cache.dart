import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/tts_play_session.dart';
import '../models/tts_segment.dart';

/// TTS 分段缓存管理器
///
/// 缓存结构：
/// tts_cache/
/// ├── msg_{messageId}/
/// │   ├── meta.json
/// │   ├── seg_0.mp3
/// │   ├── seg_1.mp3
/// │   └── ...
/// └── ...
class TtsSegmentCache {
  static final TtsSegmentCache _instance = TtsSegmentCache._internal();

  factory TtsSegmentCache() => _instance;

  TtsSegmentCache._internal();

  String? _cacheBasePath;

  /// 获取缓存基础目录
  Future<String> get cacheBasePath async {
    if (_cacheBasePath != null) return _cacheBasePath!;

    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'tts_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _cacheBasePath = cacheDir.path;
    return _cacheBasePath!;
  }

  /// 获取消息缓存目录
  Future<String> _getMessageCacheDir(String messageId) async {
    final basePath = await cacheBasePath;
    final safeId = messageId.replaceAll(RegExp(r'[^\w-]'), '_');
    return path.join(basePath, 'msg_$safeId');
  }

  /// 获取 meta.json 路径
  Future<String> _getMetaPath(String messageId) async {
    final dir = await _getMessageCacheDir(messageId);
    return path.join(dir, 'meta.json');
  }

  /// 获取段落音频文件路径
  Future<String> getSegmentFilePath(String messageId, int segmentIndex) async {
    final dir = await _getMessageCacheDir(messageId);
    return path.join(dir, 'seg_$segmentIndex.mp3');
  }

  /// 检查是否有有效的缓存会话
  ///
  /// 验证 contentHash 和 settings 是否匹配
  Future<TtsPlaySession?> getValidSession({
    required String messageId,
    required String contentHash,
    required TtsSessionSettings settings,
  }) async {
    try {
      final metaPath = await _getMetaPath(messageId);
      final metaFile = File(metaPath);

      if (!await metaFile.exists()) {
        debugPrint('🔊 缓存不存在: $messageId');
        return null;
      }

      final jsonStr = await metaFile.readAsString();
      final session = TtsPlaySession.fromJson(jsonDecode(jsonStr));

      // 验证 contentHash
      if (session.contentHash != contentHash) {
        debugPrint('🔊 内容已变化，清除旧缓存: $messageId');
        await clearMessageCache(messageId);
        return null;
      }

      // 验证 settings
      if (!session.settingsMatch(settings)) {
        debugPrint('🔊 设置已变化，清除旧缓存: $messageId');
        await clearMessageCache(messageId);
        return null;
      }

      // 验证段落文件完整性
      final msgDir = await _getMessageCacheDir(messageId);
      for (var i = 0; i < session.segments.length; i++) {
        final segFile = File(path.join(msgDir, 'seg_$i.mp3'));
        if (session.segments[i].status == SegmentStatus.ready) {
          if (await segFile.exists()) {
            session.segments[i] = session.segments[i].copyWith(
              cachePath: segFile.path,
            );
          } else {
            // 文件丢失，标记为 pending
            session.segments[i] = session.segments[i].copyWith(
              status: SegmentStatus.pending,
              cachePath: null,
            );
          }
        }
      }

      debugPrint('🔊 缓存有效: $messageId, ${session.readyCount}/${session.segments.length} 段就绪');
      return session;
    } catch (e) {
      debugPrint('🔊 读取缓存失败: $e');
      return null;
    }
  }

  /// 创建新的缓存会话
  Future<void> createSession(TtsPlaySession session) async {
    final msgDir = await _getMessageCacheDir(session.messageId);
    final dir = Directory(msgDir);

    // 清除旧目录（如果存在）
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // 创建新目录
    await dir.create(recursive: true);

    // 保存 meta.json
    await saveSessionMeta(session);

    debugPrint('🔊 创建缓存会话: ${session.messageId}, ${session.segments.length} 段');
  }

  /// 保存会话元数据
  Future<void> saveSessionMeta(TtsPlaySession session) async {
    final metaPath = await _getMetaPath(session.messageId);
    final metaFile = File(metaPath);
    await metaFile.writeAsString(jsonEncode(session.toJson()));
  }

  /// 保存段落音频
  Future<String> saveSegmentAudio({
    required String messageId,
    required int segmentIndex,
    required List<int> audioData,
  }) async {
    final filePath = await getSegmentFilePath(messageId, segmentIndex);
    final file = File(filePath);
    await file.writeAsBytes(audioData);
    debugPrint('🔊 保存段落音频: seg_$segmentIndex.mp3 (${audioData.length} bytes)');
    return filePath;
  }

  /// 获取段落音频文件
  Future<File?> getSegmentFile(String messageId, int segmentIndex) async {
    final filePath = await getSegmentFilePath(messageId, segmentIndex);
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// 清除消息缓存
  Future<void> clearMessageCache(String messageId) async {
    try {
      final msgDir = await _getMessageCacheDir(messageId);
      final dir = Directory(msgDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        debugPrint('🔊 已清除缓存: $messageId');
      }
    } catch (e) {
      debugPrint('🔊 清除缓存失败: $e');
    }
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      final basePath = await cacheBasePath;
      final dir = Directory(basePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
        debugPrint('🔊 已清除所有 TTS 缓存');
      }
    } catch (e) {
      debugPrint('🔊 清除所有缓存失败: $e');
    }
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      final basePath = await cacheBasePath;
      final dir = Directory(basePath);
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('🔊 获取缓存大小失败: $e');
      return 0;
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final basePath = await cacheBasePath;
      final dir = Directory(basePath);
      if (!await dir.exists()) {
        return {'totalSize': 0, 'messageCount': 0};
      }

      int totalSize = 0;
      int messageCount = 0;

      await for (final entity in dir.list()) {
        if (entity is Directory && path.basename(entity.path).startsWith('msg_')) {
          messageCount++;
          await for (final file in entity.list()) {
            if (file is File) {
              totalSize += await file.length();
            }
          }
        }
      }

      return {
        'totalSize': totalSize,
        'messageCount': messageCount,
        'formattedSize': _formatSize(totalSize),
      };
    } catch (e) {
      return {'totalSize': 0, 'messageCount': 0, 'error': e.toString()};
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
