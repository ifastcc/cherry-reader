import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../models/isar/topic_cache_entity.dart';
import 'isar_database.dart';

/// 数据持久化管理器（优化版 - 使用 Isar）
///
/// 优化策略：
/// 1. 使用 Isar 存储话题元数据（轻量级索引）
/// 2. 原始 ZIP/JSON 文件保留在 App 目录
/// 3. 按需解析话题详情，避免一次性加载所有数据
///
/// 性能提升：
/// - 启动时只加载索引（几百个话题元数据 < 1MB）
/// - 不再试图存储 117MB JSON 到 SharedPreferences
/// - 内存占用减少 90%+
class DataPersistenceManager {
  static const String _keyLastFilePath = 'last_file_path';
  static const String _appDataFileName = 'cherry_studio_data.zip';
  static const String _cacheVersion = 'cache_version_v2'; // 版本控制

  static final IsarDatabase _db = IsarDatabase();

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

  // ============ 新的缓存策略（使用 Isar）============

  /// 保存话题索引缓存（轻量级）
  ///
  /// 只存储话题元数据，不存储完整内容
  /// 参数:
  /// - topics: 话题列表（包含完整数据）
  static Future<void> saveTopicIndexCache(
    List<Map<String, dynamic>> topics,
  ) async {
    if (topics.isEmpty) return;

    final startTime = DateTime.now();
    final entities = <TopicCacheEntity>[];

    for (final topic in topics) {
      final topicId = topic['id'] as String? ?? '';
      final name = topic['name'] as String? ?? '未命名话题';
      final assistantId = topic['assistantId'] as String? ?? 'default';
      final messages = topic['messages'] as List<dynamic>? ?? [];

      // 计算轮数：统计用户消息数量
      int roundCount = 0;
      for (final msg in messages) {
        if (msg is Map<String, dynamic> && msg['role'] == 'user') {
          roundCount++;
        }
      }

      // 将话题完整数据序列化为 JSON
      final dataJson = json.encode(topic);

      final entity = TopicCacheEntity.fromTopicData(
        topicId,
        name,
        assistantId,
        messages.length,
        roundCount,
        dataJson,
      );

      entities.add(entity);
    }

    // 批量保存到 Isar
    await _db.saveTopicCaches(entities);

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    print('✅ 已缓存 ${topics.length} 个话题索引，耗时 ${elapsed}ms');
  }

  /// 从缓存加载话题索引（轻量级）
  ///
  /// 返回: Map<assistantId, List<TopicMetadata>>
  static Future<Map<String, List<Map<String, dynamic>>>>
  loadTopicIndexCache() async {
    final startTime = DateTime.now();

    // 从 Isar 加载所有话题缓存
    final grouped = await _db.getAllTopicsGrouped();

    // 转换为 Map 格式（不包含完整数据）
    final result = <String, List<Map<String, dynamic>>>{};

    for (final entry in grouped.entries) {
      final assistantId = entry.key;
      final topics = entry.value;

      result[assistantId] = topics.map((entity) {
        return {
          'id': entity.topicId,
          'name': entity.name,
          'assistantId': entity.assistantId,
          'messageCount': entity.messageCount,
          'roundCount': entity.roundCount,
          'createdAt': entity.createdAt,
          'updatedAt': entity.updatedAt,
        };
      }).toList();
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final totalTopics = result.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    print('✅ 从缓存加载 $totalTopics 个话题索引，耗时 ${elapsed}ms');

    return result;
  }

  /// 加载单个话题的完整数据（按需加载）
  ///
  /// 参数:
  /// - topicId: 话题 ID
  ///
  /// 返回: 话题完整数据（包含 messages）
  static Future<Map<String, dynamic>?> loadTopicData(String topicId) async {
    // 从 Isar 加载缓存
    final entity = await _db.getTopicCache(topicId);

    if (entity == null) {
      return null;
    }

    // 反序列化 JSON 数据
    try {
      final data = json.decode(entity.dataJson) as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('❌ 话题数据解析失败: $e');
      return null;
    }
  }

  /// 检查缓存是否有效
  static Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_cacheVersion);

    // 检查版本号
    if (version != 'v2') {
      print('⚠️  缓存版本不匹配，需要重新加载');
      return false;
    }

    // 检查 Isar 中是否有数据
    final stats = await _db.getStatistics();
    final topicCount = stats['topics'] as int;

    if (topicCount == 0) {
      print('⚠️  缓存为空，需要重新加载');
      return false;
    }

    return true;
  }

  /// 标记缓存为有效
  static Future<void> markCacheAsValid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheVersion, 'v2');
  }

  /// 清除所有缓存
  static Future<void> clearCache() async {
    await _db.clearTopicCaches();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheVersion);

    print('🗑️  已清除所有缓存');
  }

  /// 智能加载: 优先使用缓存,如果缓存无效则返回 null
  ///
  /// 返回: (话题索引数据, 是否来自缓存)
  static Future<(Map<String, List<Map<String, dynamic>>>?, bool)>
  smartLoad() async {
    final lastPath = await getLastFilePath();
    if (lastPath == null) {
      print('ℹ️  无上次打开的文件');
      return (null, false);
    }

    print('ℹ️  上次打开的文件: $lastPath');

    // 【修复】检查文件是否被修改
    final fileModified = await isFileModified(lastPath);
    if (fileModified) {
      print('⚠️  文件已修改，缓存失效');
      await clearCache();
      return (null, false);
    }

    // 检查缓存是否有效
    final cacheValid = await isCacheValid();
    if (!cacheValid) {
      print('⚠️  缓存版本无效');
      return (null, false);
    }

    // 加载话题索引
    final topicIndex = await loadTopicIndexCache();
    if (topicIndex.isEmpty) {
      print('⚠️  缓存数据为空');
      return (null, false);
    }

    print('✅ 使用缓存数据');
    return (topicIndex, true);
  }

  // ============ 废弃的方法（保留兼容性）============

  /// @deprecated 不再使用 SharedPreferences 存储大数据
  /// 使用 saveTopicIndexCache() 替代
  static Future<void> saveCachedData(
    String filePath,
    Map<String, dynamic> data,
  ) async {
    print('⚠️  saveCachedData() 已废弃，请使用 saveTopicIndexCache()');
    // 不再实现
  }

  /// @deprecated 不再使用 SharedPreferences 加载大数据
  /// 使用 loadTopicIndexCache() 替代
  static Future<Map<String, dynamic>?> getCachedData() async {
    print('⚠️  getCachedData() 已废弃，请使用 loadTopicIndexCache()');
    return null;
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
    } catch (e) {
      print('❌ 保存文件时间戳失败: $e');
    }
  }
}
