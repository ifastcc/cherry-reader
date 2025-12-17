import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watcher/watcher.dart';
import 'data_persistence_manager.dart';

/// 本地文件夹配置
class LocalFolderConfig {
  final String folderPath;

  const LocalFolderConfig({required this.folderPath});

  /// 配置是否有效
  bool get isValid => folderPath.isNotEmpty;

  @override
  String toString() => 'LocalFolderConfig(path: $folderPath)';
}

/// 本地备份文件信息
class LocalBackupInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modifiedTime;

  const LocalBackupInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedTime,
  });

  /// 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 从文件名解析显示名称
  ///
  /// Cherry Studio 备份文件格式：cherry-studio.时间戳.主机名.平台.zip
  /// 例如：cherry-studio.20251130164825.kbaicaideMacBook-Pro.local.mac.zip
  String get displayName {
    final regex = RegExp(r'cherry-studio\.(\d{14})\.');
    final match = regex.firstMatch(name);
    if (match != null) {
      final timestamp = match.group(1)!;
      // 格式化为可读时间：20251130164825 -> 2025-11-30 16:48:25
      try {
        final year = timestamp.substring(0, 4);
        final month = timestamp.substring(4, 6);
        final day = timestamp.substring(6, 8);
        final hour = timestamp.substring(8, 10);
        final minute = timestamp.substring(10, 12);
        final second = timestamp.substring(12, 14);
        return '$year-$month-$day $hour:$minute:$second';
      } catch (_) {}
    }
    return name;
  }

  @override
  String toString() => 'LocalBackupInfo($name, $formattedSize, $modifiedTime)';
}

/// 本地文件夹同步服务
///
/// 监听本地 Cherry Studio 备份目录，自动检测文件变化并通知加载
class LocalFolderSyncService {
  static const String _keyFolderPath = 'local_folder_path';
  static const String _keyLastModified = 'local_folder_last_modified';
  static const String _keyAutoLoad = 'local_folder_auto_load';

  // 文件夹监听器
  DirectoryWatcher? _watcher;
  StreamSubscription<WatchEvent>? _watchSubscription;

  // 同步锁
  static bool _isSyncing = false;

  // 防抖定时器
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 800);

  // 文件变化回调
  Function(LocalBackupInfo)? onFileChanged;

  /// 加载本地文件夹配置
  static Future<LocalFolderConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalFolderConfig(
      folderPath: prefs.getString(_keyFolderPath) ?? '',
    );
  }

  /// 保存本地文件夹配置
  static Future<void> saveConfig(LocalFolderConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFolderPath, config.folderPath);
  }

  /// 获取自动加载配置（默认开启）
  static Future<bool> getAutoLoad() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoLoad) ?? true;
  }

  /// 保存自动加载配置
  static Future<void> setAutoLoad(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoLoad, value);
  }

  /// 验证文件夹路径是否有效
  ///
  /// 返回 (是否有效, 消息)
  static Future<(bool success, String message)> validateFolder(String path) async {
    if (path.isEmpty) {
      return (false, '请选择文件夹');
    }

    final dir = Directory(path);
    if (!await dir.exists()) {
      return (false, '文件夹不存在');
    }

    // 检查是否有 cherry-studio.*.zip 文件
    final backups = await listBackupFiles(LocalFolderConfig(folderPath: path));
    if (backups.isEmpty) {
      return (true, '文件夹有效，但未找到备份文件');
    }

    return (true, '找到 ${backups.length} 个备份文件');
  }

  /// 获取所有备份文件列表（按修改时间降序）
  static Future<List<LocalBackupInfo>> listBackupFiles(LocalFolderConfig config) async {
    if (!config.isValid) return [];

    final dir = Directory(config.folderPath);
    if (!await dir.exists()) return [];

    final backups = <LocalBackupInfo>[];

    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          // 只关注 cherry-studio.*.zip 文件
          if (name.startsWith('cherry-studio.') && name.endsWith('.zip')) {
            final stat = await entity.stat();
            backups.add(LocalBackupInfo(
              name: name,
              path: entity.path,
              size: stat.size,
              modifiedTime: stat.modified,
            ));
          }
        }
      }

      // 按修改时间降序排序（最新的在前面）
      backups.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    } catch (e) {
      debugPrint('❌ 列出备份文件失败: $e');
    }

    return backups;
  }

  /// 查找最新的备份文件
  static Future<LocalBackupInfo?> findLatestBackup(LocalFolderConfig config) async {
    final backups = await listBackupFiles(config);
    return backups.isNotEmpty ? backups.first : null;
  }

  /// 检查是否需要更新
  ///
  /// 返回 (需要更新, 最新文件, 消息)
  static Future<(bool needUpdate, LocalBackupInfo? latestFile, String message)>
  checkForUpdate(LocalFolderConfig config) async {
    if (!config.isValid) {
      return (false, null, '配置不完整');
    }

    final latest = await findLatestBackup(config);
    if (latest == null) {
      return (false, null, '未找到备份文件');
    }

    final prefs = await SharedPreferences.getInstance();
    final lastModified = prefs.getInt(_keyLastModified) ?? 0;
    final latestModified = latest.modifiedTime.millisecondsSinceEpoch;

    if (latestModified > lastModified) {
      return (true, latest, '发现新备份');
    }

    return (false, latest, '已是最新版本');
  }

  /// 加载备份文件到 App 目录
  ///
  /// 返回本地文件路径，失败返回 null
  static Future<String?> loadBackup(LocalBackupInfo backup) async {
    try {
      // 获取 App 数据目录
      final appPath = await DataPersistenceManager.getAppDataFilePath();
      final appFile = File(appPath);

      // 删除旧文件
      if (await appFile.exists()) {
        await appFile.delete();
      }

      // 复制新文件
      final sourceFile = File(backup.path);
      if (!await sourceFile.exists()) {
        debugPrint('❌ 源文件不存在: ${backup.path}');
        return null;
      }

      await sourceFile.copy(appPath);

      // 保存时间戳
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastModified, backup.modifiedTime.millisecondsSinceEpoch);

      debugPrint('✅ 已加载备份: ${backup.name}');
      return appPath;
    } catch (e) {
      debugPrint('❌ 加载备份失败: $e');
      return null;
    }
  }

  /// 开始监听文件夹
  Future<void> startWatching(LocalFolderConfig config) async {
    if (!config.isValid) {
      debugPrint('⚠️ 本地文件夹配置无效，跳过监听');
      return;
    }

    // 停止之前的监听
    await stopWatching();

    try {
      final dir = Directory(config.folderPath);
      if (!await dir.exists()) {
        debugPrint('❌ 监听目录不存在: ${config.folderPath}');
        return;
      }

      _watcher = DirectoryWatcher(config.folderPath);
      _watchSubscription = _watcher!.events.listen((event) {
        _handleWatchEvent(event, config);
      });

      debugPrint('👀 开始监听文件夹: ${config.folderPath}');
    } catch (e) {
      debugPrint('❌ 启动文件夹监听失败: $e');
    }
  }

  /// 处理文件监听事件
  void _handleWatchEvent(WatchEvent event, LocalFolderConfig config) {
    final path = event.path;
    final name = path.split(Platform.pathSeparator).last;

    // 只关注 cherry-studio.*.zip 文件
    if (!name.startsWith('cherry-studio.') || !name.endsWith('.zip')) {
      return;
    }

    debugPrint('📁 检测到文件变化: ${event.type} - $name');

    // 防抖处理：文件写入可能触发多次事件
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      // 延迟后再检查，确保文件写入完成
      final latest = await findLatestBackup(config);
      if (latest != null && onFileChanged != null) {
        debugPrint('📢 通知文件变化: ${latest.name}');
        onFileChanged!(latest);
      }
    });
  }

  /// 停止监听
  Future<void> stopWatching() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    await _watchSubscription?.cancel();
    _watchSubscription = null;
    _watcher = null;

    debugPrint('🛑 已停止文件夹监听');
  }

  /// 自动同步
  ///
  /// 返回 (是否有更新, 本地文件路径, 消息)
  static Future<(bool updated, String? localPath, String message)> autoSync(
    LocalFolderConfig config, {
    void Function(String stage)? onProgress,
  }) async {
    if (_isSyncing) {
      debugPrint('⚠️ 本地文件夹同步已在进行中，跳过...');
      return (false, null, '同步进行中');
    }

    _isSyncing = true;
    debugPrint('🔄 开始本地文件夹同步...');

    try {
      onProgress?.call('正在检查更新...');

      final (needUpdate, latestFile, checkMessage) = await checkForUpdate(config);

      if (latestFile == null) {
        _isSyncing = false;
        return (false, null, checkMessage);
      }

      if (!needUpdate) {
        _isSyncing = false;
        final appPath = await DataPersistenceManager.getLastFilePath();
        return (false, appPath, checkMessage);
      }

      onProgress?.call('正在加载备份...');

      final localPath = await loadBackup(latestFile);

      if (localPath == null) {
        _isSyncing = false;
        return (false, null, '加载失败');
      }

      // 清除旧缓存
      await DataPersistenceManager.clearCache();

      _isSyncing = false;
      debugPrint('✅ 本地文件夹同步完成');
      return (true, localPath, '同步成功');
    } catch (e) {
      _isSyncing = false;
      debugPrint('❌ 本地文件夹同步异常: $e');
      return (false, null, '同步异常: $e');
    }
  }

  /// 清除上次加载时间戳（用于强制刷新）
  static Future<void> clearLastModified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastModified);
  }

  /// 获取上次同步时间
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastModified);
    if (timestamp == null || timestamp == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 释放资源
  void dispose() {
    stopWatching();
  }
}
