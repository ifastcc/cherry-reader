import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

/// 数据持久化管理器
///
/// 功能:
/// 1. 将用户选择的文件拷贝到App目录
/// 2. 缓存解析后的数据,避免重复解析
/// 3. 自动加载上次的数据
class DataPersistenceManager {
  static const String _keyLastFilePath = 'last_file_path';
  static const String _keyCachedData = 'cached_data';
  static const String _keyCacheTimestamp = 'cache_timestamp';
  static const String _appDataFileName = 'cherry_studio_data.zip';

  /// 获取App的Documents目录
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
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

  /// 保存缓存数据
  ///
  /// 参数:
  /// - filePath: 文件路径
  /// - data: 解析后的数据 (Map<String, dynamic>)
  static Future<void> saveCachedData(String filePath, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // 保存文件路径
    await prefs.setString(_keyLastFilePath, filePath);

    // 保存数据
    final jsonString = json.encode(data);
    await prefs.setString(_keyCachedData, jsonString);

    // 保存时间戳
    await prefs.setInt(_keyCacheTimestamp, DateTime.now().millisecondsSinceEpoch);

    print('✅ 已缓存数据: $filePath (${jsonString.length} 字符)');
  }

  /// 获取缓存数据
  ///
  /// 返回缓存的数据,如果缓存不存在或已过期则返回 null
  static Future<Map<String, dynamic>?> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(_keyCachedData);
    if (jsonString == null) {
      print('ℹ️  无缓存数据');
      return null;
    }

    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final timestamp = prefs.getInt(_keyCacheTimestamp) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      print('ℹ️  找到缓存数据 (${jsonString.length} 字符, ${cacheAge ~/ 1000}秒前)');
      return data;
    } catch (e) {
      print('❌ 缓存数据解析失败: $e');
      return null;
    }
  }

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
      final cachedTimestamp = prefs.getInt(_keyCacheTimestamp) ?? 0;

      // 如果文件修改时间晚于缓存时间,说明文件被修改了
      return lastModified.millisecondsSinceEpoch > cachedTimestamp;
    } catch (e) {
      print('❌ 检查文件修改时间失败: $e');
      return true; // 出错时假设文件已修改
    }
  }

  /// 清除缓存数据
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCachedData);
    await prefs.remove(_keyCacheTimestamp);
    print('🗑️  已清除缓存');
  }

  /// 智能加载: 优先使用缓存,如果缓存无效则返回 null
  ///
  /// 返回: (数据, 是否来自缓存)
  static Future<(Map<String, dynamic>?, bool)> smartLoad() async {
    final lastPath = await getLastFilePath();
    if (lastPath == null) {
      print('ℹ️  无上次打开的文件');
      return (null, false);
    }

    print('ℹ️  上次打开的文件: $lastPath');

    // 检查文件是否被修改
    final isModified = await isFileModified(lastPath);
    if (isModified) {
      print('⚠️  文件已修改,缓存失效');
      return (null, false);
    }

    // 尝试加载缓存
    final cachedData = await getCachedData();
    if (cachedData != null) {
      print('✅ 使用缓存数据');
      return (cachedData, true);
    }

    return (null, false);
  }
}
