import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/audio_cache_key.dart';

/// TTS 全局音频缓存管理器
///
/// 职责：
/// 1. 基于内容哈希的音频文件存储/查找
/// 2. 缓存容量管理（LRU 清理）
/// 3. 不关心"会话"概念，只管理音频文件
///
/// 缓存结构：
/// ```
/// tts_cache/
/// ├── audio/               # 全局音频缓存池
/// │   ├── ab/              # 两级目录分片（前两位）
/// │   │   └── abcd...32位.mp3
/// │   └── ...
/// └── cache_index.json     # LRU 清理索引
/// ```
class TtsAudioCache {
  static final TtsAudioCache _instance = TtsAudioCache._internal();

  factory TtsAudioCache() => _instance;

  TtsAudioCache._internal();

  String? _basePath;

  /// 获取缓存基础目录
  Future<String> get basePath async {
    if (_basePath != null) return _basePath!;

    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'tts_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _basePath = cacheDir.path;
    return _basePath!;
  }

  /// 检查音频是否已缓存
  ///
  /// 返回缓存文件路径，如果不存在则返回 null
  Future<String?> getCachedPath(String cacheKey) async {
    final base = await basePath;
    final filePath = AudioCacheKey.getFilePath(base, cacheKey);
    final file = File(filePath);

    if (await file.exists()) {
      // 更新访问时间（用于 LRU）
      await _updateAccessTime(cacheKey);
      debugPrint('🔊 缓存命中: $cacheKey');
      return filePath;
    }
    return null;
  }

  /// 保存音频到缓存
  ///
  /// 返回保存后的文件路径
  Future<String> saveAudio(String cacheKey, List<int> audioData) async {
    final base = await basePath;
    final filePath = AudioCacheKey.getFilePath(base, cacheKey);
    final file = File(filePath);

    // 确保目录存在
    await file.parent.create(recursive: true);

    // 写入文件
    await file.writeAsBytes(audioData);

    // 更新访问时间
    await _updateAccessTime(cacheKey);

    debugPrint('🔊 缓存保存: $cacheKey (${audioData.length} bytes)');
    return filePath;
  }

  /// 获取缓存索引文件路径
  Future<String> get _indexPath async {
    final base = await basePath;
    return path.join(base, 'cache_index.json');
  }

  /// 更新访问时间（用于 LRU）
  Future<void> _updateAccessTime(String cacheKey) async {
    try {
      final indexFile = File(await _indexPath);
      Map<String, dynamic> index = {};

      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        index = jsonDecode(content) as Map<String, dynamic>;
      }

      index[cacheKey] = DateTime.now().millisecondsSinceEpoch;
      await indexFile.writeAsString(jsonEncode(index));
    } catch (e) {
      // 索引更新失败不影响主流程
      debugPrint('🔊 更新缓存索引失败: $e');
    }
  }

  /// 清理旧缓存（LRU 策略）
  ///
  /// [maxSizeMB] 最大缓存大小（MB）
  Future<void> cleanup({int maxSizeMB = 500}) async {
    try {
      final base = await basePath;
      final audioDir = Directory(path.join(base, 'audio'));
      if (!await audioDir.exists()) return;

      // 计算当前缓存大小
      int totalSize = 0;
      final files = <MapEntry<File, int>>[];

      await for (final entity in audioDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          final size = await entity.length();
          totalSize += size;
          files.add(MapEntry(entity, size));
        }
      }

      final maxSizeBytes = maxSizeMB * 1024 * 1024;
      if (totalSize <= maxSizeBytes) {
        debugPrint('🔊 缓存大小正常: ${(totalSize / 1024 / 1024).toStringAsFixed(1)} MB');
        return;
      }

      // 读取索引获取访问时间
      final indexFile = File(await _indexPath);
      Map<String, dynamic> index = {};
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        index = jsonDecode(content) as Map<String, dynamic>;
      }

      // 按访问时间排序（旧的在前）
      files.sort((a, b) {
        final keyA = path.basenameWithoutExtension(a.key.path);
        final keyB = path.basenameWithoutExtension(b.key.path);
        final timeA = index[keyA] as int? ?? 0;
        final timeB = index[keyB] as int? ?? 0;
        return timeA.compareTo(timeB);
      });

      // 删除旧文件直到缓存大小合适
      int deleted = 0;
      for (final entry in files) {
        if (totalSize <= maxSizeBytes * 0.8) break; // 清理到 80%

        try {
          final key = path.basenameWithoutExtension(entry.key.path);
          await entry.key.delete();
          index.remove(key);
          totalSize -= entry.value;
          deleted++;
        } catch (e) {
          debugPrint('🔊 删除缓存文件失败: $e');
        }
      }

      // 保存更新后的索引
      await indexFile.writeAsString(jsonEncode(index));

      debugPrint('🔊 缓存清理完成: 删除 $deleted 个文件, 当前 ${(totalSize / 1024 / 1024).toStringAsFixed(1)} MB');
    } catch (e) {
      debugPrint('🔊 缓存清理失败: $e');
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getStats() async {
    try {
      final base = await basePath;
      final audioDir = Directory(path.join(base, 'audio'));
      if (!await audioDir.exists()) {
        return {'totalSize': 0, 'fileCount': 0, 'formattedSize': '0 B'};
      }

      int totalSize = 0;
      int fileCount = 0;

      await for (final entity in audioDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          totalSize += await entity.length();
          fileCount++;
        }
      }

      return {
        'totalSize': totalSize,
        'fileCount': fileCount,
        'formattedSize': _formatSize(totalSize),
      };
    } catch (e) {
      return {'totalSize': 0, 'fileCount': 0, 'error': e.toString()};
    }
  }

  /// 清除所有缓存
  Future<void> clearAll() async {
    try {
      final base = await basePath;
      final audioDir = Directory(path.join(base, 'audio'));
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }

      final indexFile = File(await _indexPath);
      if (await indexFile.exists()) {
        await indexFile.delete();
      }

      debugPrint('🔊 已清除所有 TTS 缓存');
    } catch (e) {
      debugPrint('🔊 清除缓存失败: $e');
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
