import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// TTS 缓存迁移管理器
///
/// 负责从旧版缓存结构迁移到新版：
///
/// 旧版结构：
/// ```
/// tts_cache/
/// └── msg_{messageId}/
///     ├── meta.json
///     └── seg_*.mp3
/// ```
///
/// 新版结构：
/// ```
/// tts_cache/
/// ├── audio/           # 全局音频缓存池
/// │   └── xx/xxx.mp3
/// ├── sessions/        # 会话状态
/// │   └── msg_*.json
/// └── cache_index.json # LRU 索引
/// ```
class TtsCacheMigration {
  static const String _versionKey = 'tts_cache_version';
  static const int currentVersion = 2;

  /// 检查并执行迁移
  ///
  /// 在应用启动时调用
  static Future<void> migrateIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt(_versionKey) ?? 1;

      if (version < currentVersion) {
        debugPrint('🔊 TTS 缓存迁移: v$version -> v$currentVersion');
        await _migrateV1ToV2();
        await prefs.setInt(_versionKey, currentVersion);
        debugPrint('🔊 TTS 缓存迁移完成');
      }
    } catch (e) {
      debugPrint('🔊 TTS 缓存迁移失败: $e');
      // 迁移失败不影响应用运行，用户下次朗读时会自动使用新缓存
    }
  }

  /// 从 v1 迁移到 v2
  ///
  /// 策略：保留旧缓存，让其自然过期
  ///
  /// 原因：
  /// 1. 旧缓存的 key 计算方式不同，无法直接转换
  /// 2. 用户重新朗读时会自动使用新缓存
  /// 3. 避免迁移过程中出错导致缓存全部丢失
  static Future<void> _migrateV1ToV2() async {
    final appDir = await getApplicationDocumentsDirectory();
    final basePath = path.join(appDir.path, 'tts_cache');

    // 创建新目录结构
    final audioDir = Directory(path.join(basePath, 'audio'));
    final sessionsDir = Directory(path.join(basePath, 'sessions'));

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
      debugPrint('🔊 创建 audio 目录');
    }

    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
      debugPrint('🔊 创建 sessions 目录');
    }

    // 旧缓存保留，不删除
    // 可以在后续版本中添加清理逻辑
  }

  /// 清理旧格式缓存（v1 的 msg_* 目录）
  ///
  /// 可选调用，用于释放存储空间
  static Future<int> cleanupLegacyCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final basePath = path.join(appDir.path, 'tts_cache');
      final baseDir = Directory(basePath);

      if (!await baseDir.exists()) return 0;

      int deletedCount = 0;
      int freedBytes = 0;

      await for (final entity in baseDir.list()) {
        if (entity is Directory) {
          final name = path.basename(entity.path);
          // 旧格式目录：msg_开头但不在 sessions 目录中
          if (name.startsWith('msg_')) {
            // 计算大小
            await for (final file in entity.list(recursive: true)) {
              if (file is File) {
                freedBytes += await file.length();
              }
            }
            // 删除目录
            await entity.delete(recursive: true);
            deletedCount++;
            debugPrint('🔊 清理旧缓存: $name');
          }
        }
      }

      debugPrint('🔊 清理完成: 删除 $deletedCount 个旧缓存目录, 释放 ${(freedBytes / 1024 / 1024).toStringAsFixed(1)} MB');
      return freedBytes;
    } catch (e) {
      debugPrint('🔊 清理旧缓存失败: $e');
      return 0;
    }
  }

  /// 获取当前缓存版本
  static Future<int> getCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_versionKey) ?? 1;
  }

  /// 强制重置缓存版本（用于调试）
  static Future<void> resetVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_versionKey);
    debugPrint('🔊 缓存版本已重置');
  }
}
