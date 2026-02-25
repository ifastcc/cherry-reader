import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'app_db.dart';
import 'topic_service.dart';

/// 数据持久化管理器
///
/// 负责：
/// 1. 管理数据文件（复制到 App 目录）
/// 2. 文件时间戳管理（检测文件变化）
/// 3. 清除缓存
class DataPersistenceManager {
  static const String _keyLastFilePath = 'last_file_path';
  static const String _appDataFileName = 'cherry_studio_data.zip';
  static const String _cacheVersion = 'cache_version_v3'; // 版本控制

  static final AppDb _db = AppDb();

  /// 获取App的Documents目录
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<Directory> getAttachmentsDirectory() async {
    final dir = await getAppDocumentsDirectory();
    final attachments = Directory(p.join(dir.path, 'attachments'));
    if (!await attachments.exists()) {
      await attachments.create(recursive: true);
    }
    return attachments;
  }

  static Future<String> copyAttachmentToAppDirectory({
    required String sourcePath,
    required String targetFileName,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('附件文件不存在: $sourcePath');
    }

    final dir = await getAttachmentsDirectory();
    final destPath = p.join(dir.path, targetFileName);
    final destFile = File(destPath);
    if (!await destFile.exists()) {
      await sourceFile.copy(destPath);
    }
    return destPath;
  }

  /// 获取App内部的数据文件路径
  static Future<String> getAppDataFilePath() async {
    final dir = await getAppDocumentsDirectory();
    return '${dir.path}/$_appDataFileName';
  }

  /// 拷贝外部文件到App目录
  ///
  /// 参数:
  /// - sourcePath: 用户选择的文件路径
  ///
  /// 返回: App内部的文件路径
  static Future<String> copyFileToAppDirectory(String sourcePath) async {
    final sourceFile = File(sourcePath);
    final appFilePath = await getAppDataFilePath();
    final appFile = File(appFilePath);

    print('📋 开始拷贝文件...');
    print('   源文件: $sourcePath');
    print('   目标: $appFilePath');

    // 如果目标文件已存在,先删除
    if (await appFile.exists()) {
      await appFile.delete();
      print('   已删除旧文件');
    }

    // 拷贝文件
    await sourceFile.copy(appFilePath);

    final fileSize = await appFile.length();
    print('✅ 文件拷贝完成 (${fileSize ~/ 1024 / 1024} MB)');

    return appFilePath;
  }

  /// 保存上次打开的文件路径
  static Future<void> saveLastFilePath(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastFilePath, filePath);
  }

  /// 获取上次打开的文件路径
  static Future<String?> getLastFilePath() async {
    // 直接返回App内部的文件路径
    final appFilePath = await getAppDataFilePath();
    final file = File(appFilePath);

    if (await file.exists()) {
      return appFilePath;
    }

    return null;
  }

  // ============ 缓存管理 ============

  /// 检查缓存是否有效
  static Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_cacheVersion);

    // 检查版本号
    if (version != 'v3') {
      print('⚠️ 缓存版本不匹配，需要重新加载');
      return false;
    }

    // 检查 Isar 中是否有数据
    final stats = await _db.getStatistics();
    final topicCount = stats['topics'] as int;

    if (topicCount == 0) {
      print('⚠️ 缓存为空，需要重新加载');
      return false;
    }

    return true;
  }

  /// 标记缓存为有效
  static Future<void> markCacheAsValid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheVersion, 'v3');
  }

  /// 清除所有缓存
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheVersion);
    print('🗑️ 已清除缓存标记');
  }

  /// 智能加载: 检查是否有有效缓存
  ///
  /// 返回: (话题索引数据, 是否来自缓存)
  /// 注意: 新架构使用 TopicService.getTopicsGrouped() 获取数据
  static Future<(Map<String, List<Map<String, dynamic>>>?, bool)>
  smartLoad() async {
    final lastPath = await getLastFilePath();
    if (lastPath == null) {
      print('ℹ️ 无上次打开的文件');
      return (null, false);
    }

    print('ℹ️ 上次打开的文件: $lastPath');

    // 检查文件是否被修改
    final fileModified = await isFileModified(lastPath);
    if (fileModified) {
      print('⚠️ 文件已修改，缓存失效');
      await clearCache();
      return (null, false);
    }

    // 检查缓存是否有效
    final cacheValid = await isCacheValid();
    if (!cacheValid) {
      print('⚠️ 缓存版本无效');
      return (null, false);
    }

    // 使用 TopicService 加载数据（新架构）
    try {
      final topicService = TopicService();
      final topicIndex = await topicService.getTopicsGrouped();

      if (topicIndex.isEmpty) {
        print('⚠️ 缓存数据为空');
        return (null, false);
      }

      print('✅ 使用缓存数据');
      return (topicIndex, true);
    } catch (e) {
      print('❌ 加载缓存数据失败: $e');
      return (null, false);
    }
  }

  // ============ 文件时间戳管理 ============

  /// 检查文件是否被修改 (通过对比文件修改时间)
  ///
  /// 如果文件被修改,缓存应该失效
  static Future<bool> isFileModified(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final file = File(filePath);

      if (!await file.exists()) {
        return true; // 文件不存在,视为已修改
      }

      final lastModified = await file.lastModified();
      final cachedTimestamp = prefs.getInt('file_timestamp_$filePath') ?? 0;

      // 如果文件修改时间晚于缓存时间,说明文件被修改了
      return lastModified.millisecondsSinceEpoch > cachedTimestamp;
    } catch (e) {
      print('❌ 检查文件修改时间失败: $e');
      return true; // 出错时假设文件已修改
    }
  }

  /// 保存文件时间戳
  static Future<void> saveFileTimestamp(String filePath) async {
    try {
      final file = File(filePath);
      final lastModified = await file.lastModified();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'file_timestamp_$filePath',
        lastModified.millisecondsSinceEpoch,
      );

      // 同时标记缓存为有效
      await markCacheAsValid();
    } catch (e) {
      print('❌ 保存文件时间戳失败: $e');
    }
  }
}
