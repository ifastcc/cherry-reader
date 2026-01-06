import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:webdav_client/webdav_client.dart' as wd;
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async'; // For Timer
import '../services/cherry_extractor.dart';
import '../services/data_persistence_manager.dart';
import '../services/repository_provider.dart';
import '../services/webdav_service.dart';
import '../services/local_folder_sync_service.dart';
import '../services/ai_provider_service.dart';
import '../services/unified_import_manager.dart';
import '../services/version_service.dart';
import '../services/background_import_service.dart';
import '../models/domain/data_version.dart';
import '../models/domain/status_bar_state.dart';
import '../utils/platform_utils.dart';
import 'conversation_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'insight_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/status_badge.dart';

/// 同步阶段
enum SyncStage {
  connecting,  // 连接服务器
  downloading, // 下载中
  parsing,     // 解析中
  completed,   // 完成
}

/// 首页视图模式
enum HomeViewMode {
  tree,      // 树形结构（按助手分组）
  timeline,  // 时间线（按更新时间倒序）
}

/// 时间分组枚举
enum TimeGroup { today, yesterday, thisWeek, earlier }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CherryExtractor? _extractor;
  bool _isLoading = false;  // 仅用于首次加载无缓存时
  DataLoadMode _loadMode = DataLoadMode.manual;

  // 视图模式（默认为时间线）
  HomeViewMode _viewMode = HomeViewMode.timeline;

  // 话题索引和助手信息
  Map<String, List<Map<String, dynamic>>>? _topicIndex;
  Map<String, Map<String, dynamic>>? _assistantMap;

  // 同步状态（统一）
  bool _isSyncing = false;
  double? _syncProgress;      // 同步进度 (0-1)
  String? _syncMessage;       // 同步阶段描述（检查中/下载中/解析中）
  CancelToken? _downloadCancelToken;

  // 统一错误状态（替代原来的 _error 和 _lastErrorDetail）
  String? _statusError;       // 错误详情，非空时状态栏显示红色

  // 数据源配置状态
  bool _hasValidWebDavConfig = false;
  bool _hasValidLocalFolderConfig = false;
  LocalFolderSyncService? _localFolderSyncService;
  LocalBackupInfo? _pendingLocalBackup;  // 本地文件夹模式下待加载的新版本

  // 版本管理
  StreamSubscription<ImportStatus>? _importStatusSubscription;
  DataVersion? _activeVersion;
  String? _currentVersionDisplay;
  bool _hasNewVersion = false;  // 是否有新版本待查看（小蓝点）
  bool _hasUpdate = false;      // 是否检测到更新可用

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadViewMode();
    _initVersionListener();
    _initAndLoad();
  }

  /// 加载视图模式偏好
  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('home_view_mode');
    if (savedMode != null && mounted) {
      setState(() {
        _viewMode = savedMode == 'timeline' ? HomeViewMode.timeline : HomeViewMode.tree;
      });
    }
  }

  /// 切换视图模式
  Future<void> _toggleViewMode() async {
    final newMode = _viewMode == HomeViewMode.tree ? HomeViewMode.timeline : HomeViewMode.tree;
    setState(() {
      _viewMode = newMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_view_mode', newMode == HomeViewMode.timeline ? 'timeline' : 'tree');
  }

  /// 初始化版本管理监听
  void _initVersionListener() {
    _loadActiveVersion();

    // 监听后台导入状态
    _importStatusSubscription = BackgroundImportService.instance.statusStream.listen((status) async {
      if (status.isCompleted && status.versionId != null) {
        // 自动激活新版本（无感更新的核心）
        final success = await VersionService.instance.activateVersion(
          status.versionId!,
          force: false, // 尊重版本锁定设置
        );

        if (success && mounted) {
          // 静默刷新数据（不显示加载动画）
          await _silentRefreshData();
          setState(() {
            _hasNewVersion = true; // 显示蓝点提示用户数据已更新
          });
        }

        await _loadActiveVersion();
      }
    });
  }

  /// 静默刷新数据（无加载动画）
  Future<void> _silentRefreshData() async {
    try {
      final (topicIndex, _) = await DataPersistenceManager.smartLoad();

      if (topicIndex != null && topicIndex.isNotEmpty && mounted) {
        final lastFile = await DataPersistenceManager.getLastFilePath();
        if (lastFile != null) {
          final extractor = _createLightweightExtractor(lastFile);
          await extractor.load();

          final assistants = extractor.getAssistants();
          final assistantMap = <String, Map<String, dynamic>>{};
          for (final a in assistants) {
            if (a is Map<String, dynamic>) {
              final id = a['id'] as String?;
              if (id != null) {
                assistantMap[id] = a;
              }
            }
          }

          // 平滑替换数据（不设置 _isLoading）
          setState(() {
            _extractor = extractor;
            _topicIndex = topicIndex;
            _assistantMap = assistantMap;
          });

          debugPrint('✅ 静默刷新数据完成');
        }
      }
    } catch (e) {
      debugPrint('⚠️ 静默刷新失败: $e');
    }
  }

  /// 加载当前活跃版本
  Future<void> _loadActiveVersion() async {
    final version = await VersionService.instance.getActiveVersion();
    if (mounted) {
      setState(() {
        _activeVersion = version;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _localFolderSyncService?.dispose();
    _importStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用回到前台时刷新界面
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  /// 初始化并加载数据
  Future<void> _initAndLoad({bool forceReload = false}) async {
    if (_isLoading) {
      debugPrint('⚠️ _initAndLoad: 已在加载中，跳过');
      return;
    }

    final newLoadMode = await WebDavService.getLoadMode();
    final modeChanged = newLoadMode != _loadMode;
    _loadMode = newLoadMode;

    // 检查数据源配置
    if (_loadMode == DataLoadMode.webdav) {
      final config = await WebDavService.loadConfig();
      _hasValidWebDavConfig = config.isValid;
      _hasValidLocalFolderConfig = false;
      _localFolderSyncService?.dispose();
      _localFolderSyncService = null;
    } else if (_loadMode == DataLoadMode.localFolder) {
      final config = await LocalFolderSyncService.loadConfig();
      _hasValidLocalFolderConfig = config.isValid;
      _hasValidWebDavConfig = false;
      if (config.isValid) {
        _localFolderSyncService?.dispose();
        _localFolderSyncService = LocalFolderSyncService();
        _localFolderSyncService!.onFileChanged = _onLocalFileChanged;
        await _localFolderSyncService!.startWatching(config);
      }
    } else {
      _hasValidWebDavConfig = false;
      _hasValidLocalFolderConfig = false;
      _localFolderSyncService?.dispose();
      _localFolderSyncService = null;
    }

    // 如果正在同步，只更新配置状态
    if (_isSyncing) {
      debugPrint('ℹ️ _initAndLoad: 同步中，只更新配置状态');
      if (mounted) setState(() {});
      return;
    }

    if (mounted) setState(() {});

    // 模式变化或强制重新加载时触发
    if (forceReload || modeChanged || _topicIndex == null) {
      await _autoLoadDataFile();
    }
  }

  /// 自动加载数据文件
  Future<void> _autoLoadDataFile() async {
    await _loadFromLocal(showLoadingIfEmpty: true);

    if (_loadMode == DataLoadMode.webdav) {
      _syncFromWebDav();
    } else if (_loadMode == DataLoadMode.localFolder) {
      _syncFromLocalFolder();
    }
  }

  /// 从 WebDAV 同步数据
  Future<void> _syncFromWebDav() async {
    if (_isSyncing) return;

    final config = await WebDavService.loadConfig();
    if (!config.isValid) {
      if (mounted) {
        setState(() {
          _hasValidWebDavConfig = false;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _hasValidWebDavConfig = true;
      });
    }

    _downloadCancelToken = CancelToken();

    setState(() {
      _isSyncing = true;
      _syncProgress = null;
      _syncMessage = '检查更新...';
      _statusError = null;  // 清除旧错误
    });

    try {
      // 1. 检查更新
      final (needUpdate, remoteFile, checkMessage) = await WebDavService.checkForUpdate(config);
      if (!mounted) return;

      if (!needUpdate) {
        setState(() {
          _isSyncing = false;
          _syncMessage = null;
          _hasUpdate = false;
        });
        debugPrint('ℹ️ WebDAV: $checkMessage');
        return;
      }

      setState(() => _hasUpdate = true);

      // 2. 根据网络状态决定是否自动下载
      final connectivityResult = await Connectivity().checkConnectivity();
      bool shouldDownload = false;

      if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet)) {
        shouldDownload = true;
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        setState(() => _syncMessage = '等待确认...');
        shouldDownload = await _showUpdateDialog(remoteFile!);
      } else {
        shouldDownload = await _showUpdateDialog(remoteFile!);
      }

      if (!shouldDownload) {
        if (mounted) {
          setState(() {
            _isSyncing = false;
            _syncMessage = null;
          });
        }
        return;
      }

      // 3. 开始下载
      setState(() => _syncMessage = '下载中...');

      final localPath = await WebDavService.downloadBackup(
        config,
        remoteFile!,
        cancelToken: _downloadCancelToken,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _syncProgress = received / total;
              _syncMessage = '下载中 ${(received / 1024 / 1024).toStringAsFixed(1)}MB';
            });
          }
        },
      );

      if (!mounted) return;
      if (localPath == null) throw Exception('下载失败');

      // 4. 解析文件
      setState(() {
        _syncProgress = null;
        _syncMessage = '解析中...';
      });

      await DataPersistenceManager.clearCache();
      // 如果已有数据，静默加载；否则显示加载动画
      final loadSuccess = await _loadFile(
        localPath,
        saveCache: true,
        silent: _topicIndex != null,
      );

      if (loadSuccess && mounted) {
        setState(() {
          _hasUpdate = false;
        });
      }

    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel && mounted) {
        setState(() {
          _statusError = 'WebDAV 同步失败\n\n${e.message ?? e.toString()}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusError = 'WebDAV 同步失败\n\n$e';
        });
      }
    } finally {
      _downloadCancelToken = null;
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncProgress = null;
          _syncMessage = null;
        });
      }
    }
  }

  /// 显示更新确认对话框（无倒计时）
  Future<bool> _showUpdateDialog(wd.File remoteFile) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('发现新版本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('当前处于移动网络，是否下载更新？'),
              const SizedBox(height: 16),
              Text('文件：${remoteFile.name}'),
              const SizedBox(height: 4),
              Text('大小：${(remoteFile.size ?? 0) ~/ 1024} KB'),
              const SizedBox(height: 4),
              Text('时间：${remoteFile.mTime}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('暂不更新'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('立即下载'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// 从本地文件夹同步数据
  Future<void> _syncFromLocalFolder() async {
    if (_isSyncing) return;

    final config = await LocalFolderSyncService.loadConfig();
    if (!config.isValid) {
      if (mounted) {
        setState(() {
          _hasValidLocalFolderConfig = false;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _hasValidLocalFolderConfig = true;
      });
    }

    setState(() {
      _isSyncing = true;
      _syncProgress = null;
      _syncMessage = '检查本地备份...';
      _statusError = null;
    });

    try {
      final (needUpdate, latestFile, checkMessage) =
          await LocalFolderSyncService.checkForUpdate(config);

      if (!mounted) return;

      if (latestFile != null) {
        _currentVersionDisplay = latestFile.displayName;
      }

      if (!needUpdate) {
        setState(() {
          _isSyncing = false;
          _syncMessage = null;
          _hasUpdate = false;
        });
        debugPrint('ℹ️ 本地文件夹: $checkMessage');
        return;
      }

      // 有更新，自动加载
      await _loadLocalBackup(latestFile!);

    } catch (e) {
      if (mounted) {
        setState(() {
          _statusError = '本地文件夹同步失败\n\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncProgress = null;
          _syncMessage = null;
        });
      }
    }
  }

  /// 本地文件变化回调
  void _onLocalFileChanged(LocalBackupInfo backup) async {
    debugPrint('📁 检测到新备份: ${backup.name}');
    if (_isSyncing) return;

    // 检查是否开启自动加载
    final autoLoad = await LocalFolderSyncService.getAutoLoad();

    if (autoLoad) {
      // 自动加载模式：直接加载新版本
      debugPrint('🔄 自动加载新版本...');
      await _loadLocalBackup(backup);
    } else {
      // 手动模式：只提示有新版本
      if (mounted) {
        setState(() {
          _pendingLocalBackup = backup;
          _hasUpdate = true;
        });
      }
    }
  }

  /// 加载待更新的本地备份
  Future<void> _loadPendingLocalBackup() async {
    if (_pendingLocalBackup == null) return;
    await _loadLocalBackup(_pendingLocalBackup!);
    setState(() {
      _pendingLocalBackup = null;
    });
  }

  /// 加载本地备份（后台静默加载，不阻塞 UI）
  Future<void> _loadLocalBackup(LocalBackupInfo backup, {int retryCount = 0}) async {
    if (_isSyncing) return;

    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    setState(() {
      _isSyncing = true;
      _syncMessage = retryCount > 0 ? '等待文件写入完成...' : '复制文件...';
      _syncProgress = null;
    });

    try {
      // 1. 复制文件到 App 目录（含 ZIP 完整性检查）
      final localPath = await LocalFolderSyncService.loadBackup(backup);

      if (localPath == null) {
        // ZIP 文件可能还在写入中，尝试重试
        if (retryCount < maxRetries) {
          debugPrint('⏳ ZIP 文件未就绪，${retryDelay.inSeconds}秒后重试 (${retryCount + 1}/$maxRetries)');
          setState(() {
            _isSyncing = false;
            _syncMessage = null;
          });
          await Future.delayed(retryDelay);
          return _loadLocalBackup(backup, retryCount: retryCount + 1);
        }
        throw Exception('文件复制失败：ZIP 文件可能不完整');
      }

      if (!mounted) return;
      setState(() => _syncMessage = '解压中...');

      // 2. 【后台】在 Isolate 中解压和解析 JSON（不阻塞 UI）
      final extractor = await CherryExtractor.loadInBackground(
        zipPath: localPath.endsWith('.zip') ? localPath : null,
        dataJsonPath: localPath.endsWith('.zip') ? null : localPath,
      );

      if (!mounted) return;
      setState(() => _syncMessage = '处理数据...');

      // 3. 处理数据（主线程，但相对较快）
      await _processLoadedExtractor(extractor, backup.displayName);

      // 4. 保存缓存
      await DataPersistenceManager.clearCache();
      await _saveToCache(extractor, localPath);

      if (mounted) {
        setState(() {
          _hasUpdate = false;
          _pendingLocalBackup = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusError = '加载备份失败\n\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncMessage = null;
          _syncProgress = null;
        });
      }
    }
  }

  /// 处理已加载的 extractor（从后台加载结果更新 UI）
  Future<void> _processLoadedExtractor(CherryExtractor extractor, String versionDisplay) async {
    // 提取话题索引
    final grouped = extractor.getTopicsByAssistant();
    final topicIndex = <String, List<Map<String, dynamic>>>{};

    for (final entry in grouped.entries) {
      final assistantId = entry.key;
      final assistantData = entry.value;
      final topics = assistantData['topics'] as List<dynamic>;

      topicIndex[assistantId] = topics.map((t) {
        final topic = t as Map<String, dynamic>;
        final messages = topic['messages'] as List? ?? [];
        int roundCount = 0;
        for (final msg in messages) {
          if (msg is Map<String, dynamic> && msg['role'] == 'user') {
            roundCount++;
          }
        }
        return {
          'id': topic['id'],
          'name': topic['name'],
          'assistantId': assistantId,
          'messageCount': messages.length,
          'roundCount': roundCount,
          'createdAt': topic['createdAt'],
          'updatedAt': topic['updatedAt'],
        };
      }).toList();
    }

    // 提取 Assistant 信息
    final assistants = extractor.getAssistants();
    final assistantMap = <String, Map<String, dynamic>>{};
    for (final a in assistants) {
      if (a is Map<String, dynamic>) {
        final id = a['id'] as String?;
        if (id != null) {
          assistantMap[id] = a;
        }
      }
    }

    // 【被动导入】自动从加载的数据中导入 AI Providers
    try {
      if (extractor.rawData != null) {
        final count = await AIProviderService.instance
            .importFromParsedData(extractor.rawData!);
        if (count > 0) {
          debugPrint('✅ 自动导入了 $count 个 AI Provider');
        }
      }
    } catch (e) {
      debugPrint('⚠️ AI Provider 自动导入失败: $e');
    }

    // 更新 UI
    if (mounted) {
      setState(() {
        _extractor = extractor;
        _topicIndex = topicIndex;
        _assistantMap = assistantMap;
        _currentVersionDisplay = versionDisplay;
        _isLoading = false;
      });
    }
  }

  /// 保存到缓存
  Future<void> _saveToCache(CherryExtractor extractor, String filePath) async {
    try {
      final importManager = DataImportManager(RepositoryProvider.instance.database);
      await importManager.importData(
        extractor,
        onProgress: (progress, message) {
          debugPrint('📦 导入进度: ${(progress * 100).toInt()}% - $message');
        },
      );
    } catch (e) {
      debugPrint('⚠️ 保存缓存失败: $e');
    }
  }

  /// 取消正在进行的下载
  void _cancelDownload() {
    _downloadCancelToken?.cancel('用户取消');
  }

  /// 从本地加载数据
  Future<bool> _loadFromLocal({bool showLoadingIfEmpty = false}) async {
    if (showLoadingIfEmpty) {
      setState(() {
        _isLoading = true;
        _statusError = null;
      });
    }

    try {
      final startTime = DateTime.now();

      // 尝试恢复版本显示（从上次同步时间）
      if (_loadMode == DataLoadMode.localFolder && _currentVersionDisplay == null) {
        final lastSyncTime = await LocalFolderSyncService.getLastSyncTime();
        if (lastSyncTime != null) {
          // 格式化为：2025-12-17 14:30:25
          final year = lastSyncTime.year.toString();
          final month = lastSyncTime.month.toString().padLeft(2, '0');
          final day = lastSyncTime.day.toString().padLeft(2, '0');
          final hour = lastSyncTime.hour.toString().padLeft(2, '0');
          final minute = lastSyncTime.minute.toString().padLeft(2, '0');
          final second = lastSyncTime.second.toString().padLeft(2, '0');
          _currentVersionDisplay = '$year-$month-$day $hour:$minute:$second';
        }
      }

      // 智能加载: 优先使用轻量级索引
      final (topicIndex, _) = await DataPersistenceManager.smartLoad();

      if (topicIndex != null && topicIndex.isNotEmpty) {
        debugPrint('✅ 从缓存加载话题索引');

        final lastFile = await DataPersistenceManager.getLastFilePath();
        if (lastFile != null) {
          final extractor = _createLightweightExtractor(lastFile);
          await extractor.load();

          final assistants = extractor.getAssistants();
          final assistantMap = <String, Map<String, dynamic>>{};
          for (final a in assistants) {
            if (a is Map<String, dynamic>) {
              final id = a['id'] as String?;
              if (id != null) {
                assistantMap[id] = a;
              }
            }
          }

          setState(() {
            _extractor = extractor;
            _topicIndex = topicIndex;
            _assistantMap = assistantMap;
            _isLoading = false;
          });

          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          debugPrint('💡 从缓存加载完成，耗时 ${elapsed}ms');
          return true;
        }
      }

      // 没有缓存,尝试重新解析文件
      final lastFile = await DataPersistenceManager.getLastFilePath();
      if (lastFile != null) {
        final file = File(lastFile);
        if (await file.exists()) {
          debugPrint('📂 重新解析文件: $lastFile');
          final success = await _loadFile(lastFile, saveCache: true);
          if (success) {
            return true;
          }
          // 加载失败，检查是否是文件损坏
          if (_statusError != null &&
              (_statusError!.contains('ZIP') || _statusError!.contains('FormatException'))) {
            debugPrint('❌ 检测到文件损坏: $_statusError');
            await _handleCorruptedFile(lastFile);
          }
        } else {
          debugPrint('⚠️ 上次打开的文件不存在: $lastFile');
        }
      }

      setState(() {
        _isLoading = false;
      });
      return false;
    } catch (e) {
      debugPrint('⚠️ 自动加载失败: $e');
      setState(() {
        _isLoading = false;
      });
      return false;
    }
  }

  /// 【新增】处理损坏的文件
  ///
  /// 当检测到ZIP文件损坏时:
  /// 1. 删除损坏的文件
  /// 2. 清除所有缓存
  /// 3. 清除文件时间戳
  Future<void> _handleCorruptedFile(String filePath) async {
    try {
      debugPrint('🗑️  开始清理损坏的文件: $filePath');

      // 1. 删除损坏的文件
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ 已删除损坏的ZIP文件');
      }

      // 2. 清除所有缓存
      await DataPersistenceManager.clearCache();
      debugPrint('✅ 已清除所有缓存');

      // 3. 清除Isar数据库中的导入数据
      await RepositoryProvider.instance.database.clearImportedData();
      debugPrint('✅ 已清除Isar缓存');
    } catch (e) {
      debugPrint('❌ 清理失败: $e');
    }
  }

  /// 创建轻量级 Extractor（只用于加载 Assistant 信息）
  CherryExtractor _createLightweightExtractor(String filePath) {
    final isZip = filePath.endsWith('.zip');
    return CherryExtractor(
      zipPath: isZip ? filePath : null,
      dataJsonPath: isZip ? null : filePath,
    );
  }

  /// 选择并加载文件
  Future<void> _pickAndLoadFile() async {
    // 获取上次打开的目录
    String? initialDirectory;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDir = prefs.getString('last_opened_directory');

      if (lastDir != null && await Directory(lastDir).exists()) {
        initialDirectory = lastDir;
      } else {
        // 如果没有上次目录,尝试使用用户主目录
        initialDirectory =
            Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      }
    } catch (e) {
      initialDirectory = null;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
      initialDirectory: initialDirectory,
      dialogTitle: '选择 Cherry Studio 导出文件',
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    setState(() {
      _isLoading = true;
      _statusError = null;
    });

    try {
      debugPrint('📂 用户选择的文件: $filePath');

      final appFilePath = await DataPersistenceManager.copyFileToAppDirectory(
        filePath,
      );

      try {
        var fileDir = File(filePath).parent.path;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_opened_directory', fileDir);
      } catch (e) {
        debugPrint('保存目录失败: $e');
      }

      final success = await _loadFile(appFilePath, saveCache: true);

      if (success && mounted) {
        setState(() {
          _hasUpdate = false;
          _statusError = null;
        });
      } else if (_statusError != null &&
          (_statusError!.contains('ZIP') || _statusError!.contains('FormatException'))) {
        debugPrint('❌ 用户选择的文件损坏');
        await _handleCorruptedFile(appFilePath);
      }
    } catch (e) {
      setState(() {
        _statusError = '文件导入失败: $e';
        _isLoading = false;
      });
      debugPrint('文件导入失败: $e');
    }
  }

  /// 加载指定文件
  /// [silent] 为 true 时静默加载，不显示加载动画
  Future<bool> _loadFile(String filePath, {bool saveCache = false, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _statusError = null;
        _extractor = null;
        _topicIndex = null;
        _assistantMap = null;
      });
    }

    try {
      final startTime = DateTime.now();

      final isZip = filePath.endsWith('.zip');
      final extractor = CherryExtractor(
        zipPath: isZip ? filePath : null,
        dataJsonPath: isZip ? null : filePath,
      );

      await extractor.load();

      // 【被动导入】自动从加载的数据中导入 AI Providers
      // 不需要重新解包 ZIP，直接从 extractor.rawData 中提取
      try {
        if (extractor.rawData != null) {
          final count = await AIProviderService.instance
              .importFromParsedData(extractor.rawData!);
          if (count > 0) {
            debugPrint('✅ 自动导入了 $count 个 AI Provider');
          }
        }
      } catch (e) {
        // 导入失败不影响主流程，只记录日志
        debugPrint('⚠️ AI Provider 自动导入失败: $e');
      }

      // 【优化】提取话题索引（轻量级）
      final grouped = extractor.getTopicsByAssistant();
      final topicIndex = <String, List<Map<String, dynamic>>>{};

      for (final entry in grouped.entries) {
        final assistantId = entry.key;
        final assistantData = entry.value;
        final topics = assistantData['topics'] as List<dynamic>;

        topicIndex[assistantId] = topics.map((t) {
          final topic = t as Map<String, dynamic>;
          final messages = topic['messages'] as List? ?? [];
          // 计算轮数：统计用户消息数量
          int roundCount = 0;
          for (final msg in messages) {
            if (msg is Map<String, dynamic> && msg['role'] == 'user') {
              roundCount++;
            }
          }
          return {
            'id': topic['id'],
            'name': topic['name'],
            'assistantId': assistantId,
            'messageCount': messages.length,
            'roundCount': roundCount,
            'createdAt': topic['createdAt'],
            'updatedAt': topic['updatedAt'],  // 直接使用 topic 的 updatedAt
          };
        }).toList();
      }

      // 提取 Assistant 信息
      final assistants = extractor.getAssistants();
      final assistantMap = <String, Map<String, dynamic>>{};
      for (final a in assistants) {
        if (a is Map<String, dynamic>) {
          final id = a['id'] as String?;
          if (id != null) {
            assistantMap[id] = a;
          }
        }
      }

      setState(() {
        _extractor = extractor;
        _topicIndex = topicIndex;
        _assistantMap = assistantMap;
        _isLoading = false;
      });

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('💡 文件加载完成，耗时 ${elapsed}ms');

      // 保存数据到 Isar 数据库
      if (saveCache) {
        try {
          final importManager = DataImportManager(RepositoryProvider.instance.database);
          final result = await importManager.importData(
            extractor,
            onProgress: (progress, message) {
              debugPrint('📦 导入进度: ${(progress * 100).toInt()}% - $message');
            },
          );

          if (result.success) {
            await DataPersistenceManager.saveFileTimestamp(filePath);
            debugPrint('✅ 已保存话题缓存 (${result.importedTopics} 话题, ${result.importedMessages} 消息)');
          } else {
            debugPrint('⚠️ 导入失败: ${result.error}');
          }
        } catch (e) {
          debugPrint('⚠️  保存缓存失败: $e');
        }
      }
      return true; // 加载成功
    } catch (e, stackTrace) {
      debugPrint('❌ 文件加载失败: $e');
      debugPrint('   堆栈: $stackTrace');

      setState(() {
        _statusError = '文件加载失败\n\n$e';
        _isLoading = false;
      });

      return false; // 加载失败
    }
  }

  /// 刷新数据（强制从 WebDAV 同步）
  Future<void> _refreshData() async {
    if (_loadMode == DataLoadMode.webdav) {
      // 清除时间戳，强制重新下载
      await WebDavService.clearLastModified();
    }
    await _autoLoadDataFile();
  }

  /// 显示备份选择对话框
  Future<void> _showBackupSelector() async {
    if (!_hasValidWebDavConfig) return;

    // 显示加载中对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在获取备份列表...'),
          ],
        ),
      ),
    );

    try {
      final config = await WebDavService.loadConfig();
      final backups = await WebDavService.listBackupFiles(config);

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载对话框

      if (backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未找到备份文件'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 显示备份选择对话框
      final selected = await showDialog<BackupFileInfo>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择备份版本'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                final isFirst = index == 0;
                return ListTile(
                  leading: Icon(
                    isFirst ? Icons.star : Icons.archive,
                    color: isFirst ? Colors.orange : Colors.grey,
                  ),
                  title: Text(backup.displayName),
                  subtitle: Text(backup.formattedSize),
                  trailing: isFirst
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '最新',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => Navigator.pop(context, backup),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      );

      if (selected != null) {
        await _downloadAndLoadBackup(selected);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 确保关闭加载对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取备份列表失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示本地文件夹备份选择对话框
  Future<void> _showLocalBackupSelector() async {
    if (!_hasValidLocalFolderConfig) return;

    // 显示加载中对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在获取备份列表...'),
          ],
        ),
      ),
    );

    try {
      final config = await LocalFolderSyncService.loadConfig();
      final backups = await LocalFolderSyncService.listBackupFiles(config);

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载对话框

      if (backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未找到备份文件'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 显示备份选择对话框
      final selected = await showDialog<LocalBackupInfo>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.folder_open, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('选择备份版本'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                final isFirst = index == 0;
                final isCurrent = backup.displayName == _currentVersionDisplay;
                return ListTile(
                  leading: Icon(
                    isFirst ? Icons.star : Icons.archive,
                    color: isFirst ? Colors.orange : Colors.grey,
                  ),
                  title: Text(
                    backup.displayName,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(backup.formattedSize),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '当前',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      if (isFirst && !isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '最新',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.pop(context, backup),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      );

      if (selected != null) {
        // 清除时间戳，强制加载选中的版本
        await LocalFolderSyncService.clearLastModified();
        await _loadLocalBackup(selected);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 确保关闭加载对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取备份列表失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 下载并加载指定的备份文件
  Future<void> _downloadAndLoadBackup(BackupFileInfo backup) async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0;
      _syncMessage = '下载: ${backup.displayName}';
      _statusError = null;
    });

    try {
      final config = await WebDavService.loadConfig();
      final localPath = await WebDavService.downloadBackup(
        config,
        backup.webdavFile,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() {
              _syncProgress = received / total;
            });
          }
        },
        cancelToken: _downloadCancelToken,
      );

      if (localPath == null) {
        throw Exception('下载失败');
      }

      setState(() {
        _syncProgress = null;
        _syncMessage = '解析中...';
      });

      await DataPersistenceManager.clearCache();
      // 如果已有数据，静默加载
      final loadSuccess = await _loadFile(
        localPath,
        saveCache: true,
        silent: _topicIndex != null,
      );

      if (loadSuccess && mounted) {
        setState(() {
          _hasUpdate = false;
          _statusError = null;
        });
      }
    } catch (e) {
      debugPrint('❌ 下载备份失败: $e');
      if (mounted) {
        setState(() {
          _statusError = '下载备份失败\n\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncProgress = null;
          _syncMessage = null;
        });
      }
    }
  }

  /// 处理主按钮点击 (Floating Dock Center Action)
  void handleMainAction() {
    if (_loadMode == DataLoadMode.manual && _topicIndex == null) {
      _pickAndLoadFile();
    } else if (_topicIndex != null) {
       Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InsightScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cherry Reader'),
        actions: [
          // 状态徽章
          _buildStatusBadge(),
          
          // 视图模式切换按钮
          IconButton(
            icon: Icon(
              _viewMode == HomeViewMode.tree ? Icons.view_timeline : Icons.account_tree,
            ),
            onPressed: (_isLoading || _topicIndex == null) ? null : _toggleViewMode,
            tooltip: _viewMode == HomeViewMode.tree ? '切换到时间线视图' : '切换到分组视图',
          ),
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: (_isLoading || _extractor == null) ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(extractor: _extractor!),
                ),
              );
            },
            tooltip: '搜索',
          ),
          // 设置按钮
           IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _isLoading ? null : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (mounted) {
                _initAndLoad();
              }
            },
            tooltip: '设置',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// 构建状态徽章
  Widget _buildStatusBadge() {
    final state = _computeStatusBarState();
    
    // Map StatusBarState to StatusBadgeState
    final badgeState = switch (state.phase) {
      StatusBarPhase.idle => StatusBadgeState.idle,
      StatusBarPhase.syncing => StatusBadgeState.syncing,
      StatusBarPhase.hasUpdate => StatusBadgeState.hasUpdate,
      StatusBarPhase.error => StatusBadgeState.error,
    };

    String? message;
    if (badgeState == StatusBadgeState.syncing) {
      message = state.syncMessage ?? '同步中...';
    } else if (badgeState == StatusBadgeState.hasUpdate) {
      message = '新版本';
    } else if (badgeState == StatusBadgeState.error) {
      message = '错误';
    }

    return StatusBadge(
      state: badgeState,
      message: message,
      onTap: () => _onStatusBarTap(state),
    );
  }

  /// 构建悬浮按钮
  Widget? _buildFloatingActionButton() {
    // 手动模式且无数据时，显示"加载数据"按钮
    if (_loadMode == DataLoadMode.manual && _topicIndex == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _pickAndLoadFile,
          icon: const Icon(Icons.folder_open),
          label: const Text('加载数据'),
        ),
      );
    }

    // 没有数据时不显示洞察按钮
    if (_topicIndex == null) {
      return null;
    }

    // 有数据时显示"洞察"悬浮按钮
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        onPressed: _isLoading ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InsightScreen(),
            ),
          );
        },
        tooltip: '洞察',
        child: const Icon(Icons.insights),
      ),
    );
  }

  /// 计算当前状态栏状态
  StatusBarState _computeStatusBarState() {
    final topicCount = _topicIndex?.values.fold<int>(0, (sum, list) => sum + list.length);
    final versionDisplay = _activeVersion?.displayName ?? _currentVersionDisplay;

    // 计算今日话题数
    int todayTopicCount = 0;
    if (_topicIndex != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final topics in _topicIndex!.values) {
        for (final topic in topics) {
          final dt = _parseUpdatedAt(topic['updatedAt']);
          if (dt != null) {
            final topicDate = DateTime(dt.year, dt.month, dt.day);
            if (topicDate == today) {
              todayTopicCount++;
            }
          }
        }
      }
    }

    // 1. 错误状态
    if (_statusError != null) {
      return StatusBarState.error(
        loadMode: _loadMode,
        errorDetail: _statusError!,
        versionDisplay: versionDisplay,
        topicCount: topicCount,
      );
    }

    // 2. 同步中状态
    if (_isSyncing) {
      return StatusBarState.syncing(
        loadMode: _loadMode,
        progress: _syncProgress,
        message: _syncMessage,
        versionDisplay: versionDisplay,
        topicCount: topicCount,
      );
    }

    // 3. 有更新可用
    if (_hasUpdate || _pendingLocalBackup != null) {
      return StatusBarState.hasUpdate(
        loadMode: _loadMode,
        versionDisplay: versionDisplay,
        topicCount: topicCount,
      );
    }

    // 4. 空闲状态
    return StatusBarState.idle(
      loadMode: _loadMode,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
      todayTopicCount: todayTopicCount,
      hasNewVersion: _hasNewVersion,
    );
  }



  /// 状态图标
  Widget _buildStatusIcon(StatusBarState state) {
    final (IconData icon, Color color) = switch (state.phase) {
      StatusBarPhase.idle => (Icons.cloud_done_outlined, Colors.grey[400]!),
      StatusBarPhase.syncing => (Icons.sync, Colors.blue[500]!),
      StatusBarPhase.hasUpdate => (Icons.file_download_outlined, Colors.orange[600]!),
      StatusBarPhase.error => (Icons.error_outline, Colors.red[500]!),
    };

    if (state.isSyncing) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Icon(icon, size: 14, color: color);
  }

  /// 获取状态文字
  String _getStatusText(StatusBarState state) {
    if (state.phase == StatusBarPhase.hasUpdate && _pendingLocalBackup != null) {
      return '点击更新';
    }
    return state.statusText;
  }

  /// 获取状态颜色
  Color _getStatusColor(StatusBarState state) {
    return switch (state.phase) {
      StatusBarPhase.idle => Colors.grey[500]!,
      StatusBarPhase.syncing => Colors.blue[600]!,
      StatusBarPhase.hasUpdate => Colors.orange[700]!,
      StatusBarPhase.error => Colors.red[600]!,
    };
  }

  /// 状态栏点击处理
  void _onStatusBarTap(StatusBarState state) {
    // 清除蓝点（用户已看到更新提示）
    if (_hasNewVersion) {
      setState(() => _hasNewVersion = false);
    }

    if (state.isError) {
      _showErrorDialog(state.errorDetail ?? '未知错误');
      return;
    }

    if (_pendingLocalBackup != null) {
      _loadPendingLocalBackup();
      return;
    }

    if (state.phase == StatusBarPhase.hasUpdate) {
      if (_loadMode == DataLoadMode.webdav) {
        _syncFromWebDav();
      }
      return;
    }
  }

  /// 显示错误详情弹窗
  void _showErrorDialog(String errorDetail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 24),
            const SizedBox(width: 8),
            const Text('同步失败'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            errorDetail,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _statusError = null);
            },
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _statusError = null);
              _refreshData();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 显示版本管理对话框
  Future<void> _showVersionManager() async {
    final versions = await VersionService.instance.listVersions();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '版本历史',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // 锁定开关
                    if (_activeVersion != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _activeVersion!.isLocked ? Icons.lock : Icons.lock_open,
                            size: 16,
                            color: _activeVersion!.isLocked ? Colors.orange : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _activeVersion!.isLocked ? '已锁定' : '自动更新',
                            style: TextStyle(
                              fontSize: 12,
                              color: _activeVersion!.isLocked ? Colors.orange : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 版本列表
              Expanded(
                child: versions.isEmpty
                    ? const Center(child: Text('暂无版本数据'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: versions.length,
                        itemBuilder: (context, index) {
                          final version = versions[index];
                          final isActive = version.status == VersionStatus.active;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? Colors.green[100]
                                  : Colors.grey[100],
                              child: Icon(
                                isActive ? Icons.check : Icons.archive,
                                color: isActive ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(version.displayName),
                                if (isActive)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '当前',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                                if (version.isLocked)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '锁定',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${version.topicCount} 话题 • ${version.formattedSize}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: isActive
                                ? null
                                : TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _activateVersion(version);
                                    },
                                    child: const Text('切换'),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 激活指定版本
  Future<void> _activateVersion(DataVersion version) async {
    try {
      final success = await VersionService.instance.activateVersion(
        version.versionId,
        force: true,
      );

      if (success && mounted) {
        await _loadActiveVersion();
        await _silentRefreshData(); // 静默刷新数据
        setState(() {
          _hasNewVersion = false; // 用户已手动切换，清除蓝点
          _statusError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusError = '切换版本失败\n\n$e';
        });
      }
    }
  }

  Widget _buildBody() {
    // 首次加载时显示加载动画
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载...'),
          ],
        ),
      );
    }

    // 无数据时
    if (_topicIndex == null) {
      // 同步中显示简洁占位
      if (_isSyncing) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync, size: 48, color: Colors.blue[300]),
              const SizedBox(height: 16),
              Text(
                _syncMessage ?? '同步中...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }
      // 空状态
      return _buildEmptyState();
    }

    return _viewMode == HomeViewMode.tree ? _buildTopicList() : _buildTimelineList();
  }

  /// 格式化缓存版本时间
  String _formatSyncTime(DateTime? time) {
    if (time == null) return '未知';
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }

  /// 【新增】格式化检查时间为友好的相对时间
  String _formatCheckTime(DateTime? checkTime) {
    if (checkTime == null) return '未检查';

    final now = DateTime.now();
    final diff = now.difference(checkTime);

    if (diff.inSeconds < 10) return '刚刚检查';
    if (diff.inMinutes < 1) return '${diff.inSeconds}秒前检查';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前检查';
    if (diff.inDays < 1) return '${diff.inHours}小时前检查';
    return DateFormat('MM-dd HH:mm').format(checkTime) + ' 检查';
  }

  /// 格式化版本时间（备份文件的修改时间）
  String _formatVersionTime(DateTime? time) {
    if (time == null) return '未知';
    return DateFormat('MM-dd HH:mm').format(time);
  }

  Widget _buildTopicList() {
    if (_topicIndex == null || _topicIndex!.isEmpty) {
      return const Center(child: Text('没有找到话题'));
    }

    final assistantEntries = _topicIndex!.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assistantEntries.length,
      itemBuilder: (context, index) {
        final entry = assistantEntries[index];
        final assistantId = entry.key;
        final topics = entry.value;

        // 获取 Assistant 信息
        final assistantInfo =
            _assistantMap?[assistantId] ?? {'id': assistantId, 'name': '未命名助手'};

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              child: Text(
                (assistantInfo['name'] as String?)?.substring(0, 1) ?? '?',
              ),
            ),
            title: Text(
              assistantInfo['name'] as String? ?? '未命名助手',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${topics.length} 个话题'),
            // 【性能优化】使用虚拟化列表替代 map().toList()
            // 避免一次性创建大量 Widget，特别是当助手有很多话题时
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  // 限制最大高度：最多显示 6 个话题的高度，超出可滚动
                  // 每个 ListTile 高度约 72px
                  maxHeight: topics.length > 6 ? 432 : topics.length * 72.0,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: topics.length > 6
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: topics.length,
                  itemBuilder: (context, topicIndex) {
                    final topic = topics[topicIndex];
                    final topicName = topic['name'] as String? ?? '未命名话题';
                    final topicId = topic['id'] as String;
                    final messageCount = topic['messageCount'] as int? ?? 0;
                    final roundCount = topic['roundCount'] as int? ?? 0;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      title: Text(topicName),
                      subtitle: Text('$roundCount 轮对话，$messageCount 条消息'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        if (_extractor == null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('数据加载器未就绪')));
                          return;
                        }

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConversationScreen(
                              extractor: _extractor!,
                              topicId: topicId,
                              topicName: topicName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

/// 时间线视图（按更新时间倒序，分组显示）
  Widget _buildTimelineList() {
    if (_topicIndex == null || _topicIndex!.isEmpty) {
      return const Center(child: Text('没有找到话题'));
    }

    // 将所有话题展平并按更新时间倒序排序
    final allTopics = <Map<String, dynamic>>[];
    for (final entry in _topicIndex!.entries) {
      final assistantId = entry.key;
      for (final topic in entry.value) {
        allTopics.add({
          ...topic,
          'assistantId': assistantId,
        });
      }
    }

    // 按 updatedAt 倒序排序
    allTopics.sort((a, b) {
      final aTime = _parseUpdatedAt(a['updatedAt']);
      final bTime = _parseUpdatedAt(b['updatedAt']);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    // 按时间分组
    final groupedTopics = <TimeGroup, List<Map<String, dynamic>>>{};
    for (final topic in allTopics) {
      final dt = _parseUpdatedAt(topic['updatedAt']);
      TimeGroup group = TimeGroup.earlier;
      if (dt != null) {
        group = _getTimeGroup(dt);
      }
      groupedTopics.putIfAbsent(group, () => []).add(topic);
    }

    // 构建分组列表
    final groups = [TimeGroup.today, TimeGroup.yesterday, TimeGroup.thisWeek, TimeGroup.earlier];
    final items = <Widget>[];
    bool isFirstGroup = true;

    for (final group in groups) {
      final topics = groupedTopics[group];
      if (topics == null || topics.isEmpty) continue;

      // 分组标题
      items.add(_buildGroupHeader(_getGroupTitle(group), isFirst: isFirstGroup));
      isFirstGroup = false;

      // 话题列表
      for (int i = 0; i < topics.length; i++) {
        final topic = topics[i];
        items.add(_buildTopicItem(topic, group, isLast: i == topics.length - 1));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: items,
    );
  }

  /// 获取时间分组
  TimeGroup _getTimeGroup(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return TimeGroup.today;
    if (date == yesterday) return TimeGroup.yesterday;
    if (date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
      return TimeGroup.thisWeek;
    }
    return TimeGroup.earlier;
  }

  /// 解析 updatedAt 字段（支持 int 时间戳和 String ISO 格式）
  DateTime? _parseUpdatedAt(dynamic value) {
    if (value == null) return null;
    try {
      DateTime dt;
      if (value is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        dt = DateTime.parse(value);
      } else {
        return null;
      }
      // Cherry Studio 存储 UTC 时间，需要转换为本地时间显示
      return dt.toLocal();
    } catch (_) {}
    return null;
  }

  /// 获取分组标题
  String _getGroupTitle(TimeGroup group) {
    return switch (group) {
      TimeGroup.today => '今天',
      TimeGroup.yesterday => '昨天',
      TimeGroup.thisWeek => '本周',
      TimeGroup.earlier => '更早',
    };
  }

  /// 格式化时间显示（根据分组）
  String _formatTimeForGroup(DateTime dt, TimeGroup group) {
    final timeStr = DateFormat('HH:mm').format(dt);
    return switch (group) {
      TimeGroup.today => timeStr,
      TimeGroup.yesterday => timeStr,
      TimeGroup.thisWeek => '${_getWeekdayName(dt.weekday)} $timeStr',
      TimeGroup.earlier => '${DateFormat('MM-dd').format(dt)} $timeStr',
    };
  }

  /// 获取星期名称
  String _getWeekdayName(int weekday) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday];
  }

  /// 构建分组标题
  Widget _buildGroupHeader(String title, {bool isFirst = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst)
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          color: Colors.grey[50],
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建话题项
  Widget _buildTopicItem(Map<String, dynamic> topic, TimeGroup group, {bool isLast = false}) {
    final topicId = topic['id'] as String;
    final topicName = topic['name'] as String? ?? '未命名话题';
    final assistantId = topic['assistantId'] as String;
    final roundCount = topic['roundCount'] as int? ?? 0;

    // 获取助手信息
    final assistantInfo = _assistantMap?[assistantId];
    final assistantName = assistantInfo?['name'] as String? ?? '未命名助手';

    // 格式化时间
    String timeDisplay = '';
    final dt = _parseUpdatedAt(topic['updatedAt']);
    if (dt != null) {
      timeDisplay = _formatTimeForGroup(dt, group);
    }

    // 获取预览：最后一个用户问题 + 第一个 AI 回答
    String? userPreview;
    String? aiPreview;
    if (_extractor != null) {
      try {
        final conversation = _extractor!.extractTopicConversation(topicId);
        if (conversation != null) {
          final messages = conversation['messages'] as List? ?? [];

          // 提取 main_text 内容的辅助函数
          String? extractMainText(Map<String, dynamic> msg) {
            final blocks = msg['blocks'] as List? ?? [];
            for (final block in blocks) {
              if (block is Map<String, dynamic> && block['type'] == 'main_text') {
                final content = block['content'] as String? ?? '';
                if (content.isNotEmpty) {
                  return content.replaceAll(RegExp(r'\s+'), ' ').trim();
                }
              }
            }
            return null;
          }

          // 从前往后找第一个 AI 回答
          for (int i = 0; i < messages.length; i++) {
            final msg = messages[i] as Map<String, dynamic>;
            if (msg['role'] == 'assistant') {
              final text = extractMainText(msg);
              if (text != null && text.isNotEmpty) {
                aiPreview = text.length > 80 ? '${text.substring(0, 80)}...' : text;
                break;
              }
            }
          }

          // 从后往前找最后一个用户问题
          for (int i = messages.length - 1; i >= 0; i--) {
            final msg = messages[i] as Map<String, dynamic>;
            if (msg['role'] == 'user') {
              final text = extractMainText(msg);
              if (text != null && text.isNotEmpty) {
                userPreview = text.length > 60 ? '${text.substring(0, 60)}...' : text;
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    return InkWell(
      onTap: () async {
        if (_extractor == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('数据加载器未就绪')),
          );
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              extractor: _extractor!,
              topicId: topicId,
              topicName: topicName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.grey[100]!,
                    width: 1,
                  ),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：标题 + 时间
            Row(
              children: [
                Expanded(
                  child: Text(
                    topicName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  timeDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            // 双行预览：用户问题 + AI 回答
            if (userPreview != null || aiPreview != null) ...[
              const SizedBox(height: 10),
              // 用户问题预览
              if (userPreview != null && userPreview.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.blue[400],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        userPreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              // AI 回答预览
              if (aiPreview != null && aiPreview.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Colors.purple[300],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        aiPreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            // 底部：助手名称（左） + 轮数（右）
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    assistantName,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (roundCount > 0)
                  Text(
                    '$roundCount轮对话',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 【优化】美观的空状态页面
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // 图标
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _loadMode == DataLoadMode.webdav
                  ? (_hasValidWebDavConfig ? Colors.blue[50] : Colors.orange[50])
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _loadMode == DataLoadMode.webdav
                  ? (_hasValidWebDavConfig ? Icons.cloud_queue : Icons.cloud_off)
                  : Icons.folder_open,
              size: 48,
              color: _loadMode == DataLoadMode.webdav
                  ? (_hasValidWebDavConfig ? Colors.blue[400] : Colors.orange[400])
                  : Colors.grey[500],
            ),
          ),

          const SizedBox(height: 24),

          // 标题
          Text(
            _loadMode == DataLoadMode.webdav
                ? (_hasValidWebDavConfig ? '暂无数据' : '配置 WebDAV 同步')
                : '选择数据文件',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // 描述
          Text(
            _loadMode == DataLoadMode.webdav
                ? (_hasValidWebDavConfig
                    ? '点击下方按钮从云端同步你的对话记录'
                    : '配置与 Cherry Studio 相同的 WebDAV 设置')
                : '导入 Cherry Studio 导出的 ZIP 或 JSON 文件',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // 操作按钮
          if (_loadMode == DataLoadMode.webdav) ...[
            if (_hasValidWebDavConfig)
              // 已配置，显示同步按钮
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _refreshData,
                icon: const Icon(Icons.cloud_sync),
                label: const Text('立即同步'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              )
            else
              // 未配置，显示配置按钮
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ).then((_) {
                    if (mounted) _initAndLoad();
                  });
                },
                icon: const Icon(Icons.settings),
                label: const Text('去配置'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
          ] else ...[
            // 手动模式，提示使用浮动按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '点击右下角按钮选择文件',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 48),

          // 快速开始指南
          _buildQuickStartGuide(),
        ],
      ),
    );
  }

  /// 快速开始指南
  Widget _buildQuickStartGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                '快速开始',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_loadMode == DataLoadMode.webdav && !_hasValidWebDavConfig) ...[
            _buildGuideStep(
              number: '1',
              title: '在 Cherry Studio 中配置 WebDAV',
              description: '设置 → 数据设置 → WebDAV → 填写配置并开启自动备份',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              number: '2',
              title: '在本应用中填写相同配置',
              description: '点击上方"去配置"按钮，填写与 Cherry Studio 相同的 WebDAV 信息',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              number: '3',
              title: '自动同步',
              description: '配置完成后，应用会自动从云端同步你的对话记录',
            ),
          ] else if (_loadMode == DataLoadMode.manual) ...[
            _buildGuideStep(
              number: '1',
              title: '导出 Cherry Studio 数据',
              description: '在 Cherry Studio 中：设置 → 数据设置 → 导出菜单设置',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              number: '2',
              title: '导入到本应用',
              description: '点击右下角按钮，选择导出的 ZIP 或 JSON 文件',
            ),
          ] else ...[
            _buildGuideStep(
              number: '1',
              title: '点击同步按钮',
              description: '点击上方"立即同步"从云端获取最新数据',
            ),
          ],

          const SizedBox(height: 16),

          // 切换模式提示
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                if (mounted) _initAndLoad();
              });
            },
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _loadMode == DataLoadMode.webdav
                        ? '想手动导入文件？去设置切换模式'
                        : '想自动同步？去设置配置 WebDAV',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 引导步骤项
  Widget _buildGuideStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
