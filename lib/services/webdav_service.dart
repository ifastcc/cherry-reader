import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'data_persistence_manager.dart';

// 导出 Dio 类型供外部使用
export 'package:dio/dio.dart' show CancelToken, DioException, DioExceptionType;

/// 数据加载模式
enum DataLoadMode {
  manual,  // 手动加载
  webdav,  // WebDAV 自动加载
}

/// WebDAV 配置
class WebDavConfig {
  final String url;
  final String username;
  final String password;
  final String path;

  const WebDavConfig({
    required this.url,
    required this.username,
    required this.password,
    required this.path,
  });

  bool get isValid =>
      url.isNotEmpty &&
      username.isNotEmpty &&
      password.isNotEmpty &&
      path.isNotEmpty;

  /// 获取完整的文件路径
  String get fullPath {
    // Cherry Studio 备份文件名格式：cherry-studio.backup.时间戳.zip
    // 用户配置的是目录路径，需要查找最新的备份文件
    return path;
  }

  @override
  String toString() => 'WebDavConfig(url: $url, user: $username, path: $path)';
}

/// WebDAV 服务
class WebDavService {
  static const String _keyLoadMode = 'data_load_mode';
  static const String _keyWebdavUrl = 'webdav_url';
  static const String _keyWebdavUsername = 'webdav_username';
  static const String _keyWebdavPassword = 'webdav_password';
  static const String _keyWebdavPath = 'webdav_path';
  static const String _keyLastRemoteModified = 'webdav_last_remote_modified';
  
  // 同步锁，防止并发下载
  static bool _isSyncing = false;

  /// 获取当前加载模式
  static Future<DataLoadMode> getLoadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_keyLoadMode) ?? 'manual';
    return mode == 'webdav' ? DataLoadMode.webdav : DataLoadMode.manual;
  }

  /// 设置加载模式
  static Future<void> setLoadMode(DataLoadMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLoadMode,
      mode == DataLoadMode.webdav ? 'webdav' : 'manual',
    );
  }

  /// 加载 WebDAV 配置
  static Future<WebDavConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return WebDavConfig(
      url: prefs.getString(_keyWebdavUrl) ?? '',
      username: prefs.getString(_keyWebdavUsername) ?? '',
      password: prefs.getString(_keyWebdavPassword) ?? '',
      path: prefs.getString(_keyWebdavPath) ?? '/cherry-studio',
    );
  }

  /// 保存 WebDAV 配置
  static Future<void> saveConfig(WebDavConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebdavUrl, config.url);
    await prefs.setString(_keyWebdavUsername, config.username);
    await prefs.setString(_keyWebdavPassword, config.password);
    await prefs.setString(_keyWebdavPath, config.path);
  }

  /// 创建 WebDAV 客户端
  static webdav.Client _createClient(WebDavConfig config) {
    return webdav.newClient(
      config.url,
      user: config.username,
      password: config.password,
      debug: kDebugMode,
    );
  }

  /// 测试连接
  static Future<(bool success, String message)> testConnection(
    WebDavConfig config,
  ) async {
    if (!config.isValid) {
      return (false, '请填写完整的 WebDAV 配置');
    }

    try {
      final client = _createClient(config);

      // 尝试读取目录
      await client.readDir(config.path);
      return (true, '连接成功');
    } catch (e) {
      debugPrint('WebDAV 连接测试失败: $e');
      if (e.toString().contains('401')) {
        return (false, '认证失败：用户名或密码错误');
      } else if (e.toString().contains('404')) {
        return (false, '路径不存在：${config.path}');
      } else if (e.toString().contains('SocketException')) {
        return (false, '网络错误：无法连接到服务器');
      }
      return (false, '连接失败：$e');
    }
  }

  /// 查找最新的备份文件
  /// 
  /// Cherry Studio 备份文件格式：cherry-studio.时间戳.主机名.mac.zip
  /// 例如：cherry-studio.20251125094658.kbaicaideMacBook-Pro.local.mac.zip
  static Future<webdav.File?> findLatestBackup(WebDavConfig config) async {
    try {
      final client = _createClient(config);
      final files = await client.readDir(config.path);

      debugPrint('📂 WebDAV 目录文件列表:');
      for (final f in files) {
        debugPrint('   - ${f.name} (${f.mTime})');
      }

      // 过滤出备份文件（cherry-studio 开头的 zip 文件）
      final backupFiles = files.where((f) {
        final name = f.name ?? '';
        return name.startsWith('cherry-studio.') && name.endsWith('.zip');
      }).toList();

      if (backupFiles.isEmpty) {
        debugPrint('❌ 未找到备份文件（需要 cherry-studio.*.zip 格式）');
        return null;
      }

      // 按修改时间排序，取最新的
      backupFiles.sort((a, b) {
        final aTime = a.mTime ?? DateTime(1970);
        final bTime = b.mTime ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      final latest = backupFiles.first;
      debugPrint('✅ 找到最新备份: ${latest.name}, 修改时间: ${latest.mTime}');
      return latest;
    } catch (e) {
      debugPrint('❌ 查找备份文件失败: $e');
      return null;
    }
  }

  /// 检查是否需要更新
  /// 
  /// 返回 (需要更新, 远程文件, 消息)
  static Future<(bool needUpdate, webdav.File? remoteFile, String message)>
  checkForUpdate(WebDavConfig config) async {
    if (!config.isValid) {
      return (false, null, 'WebDAV 配置不完整');
    }

    try {
      final latestBackup = await findLatestBackup(config);
      if (latestBackup == null) {
        return (false, null, '未找到备份文件');
      }

      final prefs = await SharedPreferences.getInstance();
      final lastModified = prefs.getInt(_keyLastRemoteModified) ?? 0;
      final remoteModified = latestBackup.mTime?.millisecondsSinceEpoch ?? 0;

      if (remoteModified > lastModified) {
        return (true, latestBackup, '发现新版本');
      } else {
        return (false, latestBackup, '已是最新版本');
      }
    } catch (e) {
      debugPrint('❌ 检查更新失败: $e');
      return (false, null, '检查失败：$e');
    }
  }

  /// 下载备份文件
  /// 
  /// 使用 dio 直接下载（支持重定向）
  /// [cancelToken] 可选，用于取消下载
  static Future<String?> downloadBackup(
    WebDavConfig config,
    webdav.File remoteFile, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // 构建完整的下载 URL
      var baseUrl = config.url;
      if (!baseUrl.endsWith('/')) baseUrl += '/';
      // 移除 path 开头的斜杠
      var path = config.path;
      if (path.startsWith('/')) path = path.substring(1);
      if (!path.endsWith('/')) path += '/';
      
      final downloadUrl = '$baseUrl$path${remoteFile.name}';
      debugPrint('📥 开始下载: $downloadUrl');

      // 获取 App 数据目录
      final localPath = await DataPersistenceManager.getAppDataFilePath();
      final localFile = File(localPath);

      // 如果本地文件存在，先删除
      if (await localFile.exists()) {
        await localFile.delete();
      }

      // 使用 dio 下载（支持重定向）
      final dio = Dio();
      dio.options.followRedirects = true;
      dio.options.maxRedirects = 5;
      
      // 设置 Basic Auth
      final auth = base64Encode(utf8.encode('${config.username}:${config.password}'));
      dio.options.headers['Authorization'] = 'Basic $auth';
      
      // 禁用响应压缩，避免下载大文件时被截断
      dio.options.headers['Accept-Encoding'] = 'identity';

      await dio.download(
        downloadUrl,
        localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received, total);
          }
        },
      );

      // 验证下载
      if (!await localFile.exists()) {
        debugPrint('❌ 下载失败：本地文件不存在');
        return null;
      }

      final fileSize = await localFile.length();
      final expectedSize = remoteFile.size ?? 0;
      debugPrint('✅ 下载完成: $localPath');
      debugPrint('   本地文件大小: ${fileSize ~/ 1024} KB');
      debugPrint('   远程文件大小: ${expectedSize ~/ 1024} KB');
      
      // 检查文件大小是否匹配（允许 1% 误差）
      if (expectedSize > 0 && fileSize < expectedSize * 0.99) {
        debugPrint('⚠️ 警告：下载文件大小不匹配，可能下载不完整');
        debugPrint('   期望: ${expectedSize ~/ 1024} KB, 实际: ${fileSize ~/ 1024} KB');
      }

      // 保存远程文件的修改时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _keyLastRemoteModified,
        remoteFile.mTime?.millisecondsSinceEpoch ?? 0,
      );

      return localPath;
    } catch (e) {
      debugPrint('❌ 下载失败: $e');
      return null;
    }
  }

  /// 自动同步：检查更新并下载
  /// 
  /// 返回 (是否有更新, 本地文件路径, 消息)
  /// [cancelToken] 可选，用于取消下载
  static Future<(bool updated, String? localPath, String message)> autoSync(
    WebDavConfig config, {
    void Function(int received, int total)? onProgress,
    bool forceDownload = false,
    CancelToken? cancelToken,
  }) async {
    // 防止并发同步
    if (_isSyncing) {
      debugPrint('⚠️ WebDAV 同步已在进行中，跳过...');
      final localPath = await DataPersistenceManager.getLastFilePath();
      return (false, localPath, '同步进行中');
    }
    
    _isSyncing = true;
    debugPrint('🔄 开始 WebDAV 同步...');

    try {
      // 检查更新
      final (needUpdate, remoteFile, checkMessage) = await checkForUpdate(config);

      if (remoteFile == null) {
        _isSyncing = false;
        return (false, null, checkMessage);
      }

      if (!needUpdate && !forceDownload) {
        // 不需要更新，返回本地文件路径
        _isSyncing = false;
        final localPath = await DataPersistenceManager.getLastFilePath();
        return (false, localPath, checkMessage);
      }

      // 下载文件
      final localPath = await downloadBackup(
        config,
        remoteFile,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );

      if (localPath == null) {
        _isSyncing = false;
        return (false, null, '下载失败');
      }

      // 清除旧缓存，准备重新解析
      await DataPersistenceManager.clearCache();

      _isSyncing = false;
      return (true, localPath, '同步成功');
    } catch (e) {
      _isSyncing = false;
      debugPrint('❌ WebDAV 同步异常: $e');
      return (false, null, '同步异常: $e');
    }
  }

  /// 清除保存的远程时间戳（用于强制刷新）
  static Future<void> clearLastModified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastRemoteModified);
  }

  /// 获取上次同步的远程文件修改时间
  /// 
  /// 返回时间戳，如果没有则返回 null
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastRemoteModified);
    if (timestamp == null || timestamp == 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}
