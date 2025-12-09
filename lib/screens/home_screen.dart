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
import '../services/ai_provider_service.dart';
import '../services/unified_import_manager.dart';
import 'conversation_screen.dart';
import 'settings_screen.dart';
import 'package:intl/intl.dart';

/// 同步阶段
enum SyncStage {
  connecting,  // 连接服务器
  downloading, // 下载中
  parsing,     // 解析中
  completed,   // 完成
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CherryExtractor? _extractor;
  bool _isLoading = false;  // 仅用于首次加载无缓存时
  String? _error;
  String? _loadingMessage;  // 加载状态描述
  DataLoadMode _loadMode = DataLoadMode.manual;

  // 【优化】使用轻量级索引，而非完整数据
  Map<String, List<Map<String, dynamic>>>? _topicIndex;
  Map<String, Map<String, dynamic>>? _assistantMap;

  // 【新增】后台同步状态
  bool _isBackgroundSyncing = false;
  double? _syncProgress;  // 同步进度 (0-1)
  String? _syncMessage;   // 同步状态描述
  SyncStage? _syncStage;  // 同步阶段
  CancelToken? _downloadCancelToken;
  DateTime? _lastSyncTime;  // 缓存版本时间
  bool _hasValidWebDavConfig = false;  // 【新增】WebDAV 配置是否有效
  
  // 【新增】检查状态
  DateTime? _lastCheckTime;  // 上次检查更新的时间
  bool? _hasUpdate;  // 是否有更新（null=未检查，true=有更新，false=已是最新）

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 【新增】监听应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _lastCheckTime != null) {
      // 当应用从后台回到前台时，刷新状态栏时间显示
      setState(() {});
    }
  }

  /// 初始化并加载数据
  /// 
  /// 【重构】缓存优先：先加载本地缓存，再后台同步
  Future<void> _initAndLoad({bool forceReload = false}) async {
    // 防止重复加载
    if (_isLoading) {
      debugPrint('⚠️ _initAndLoad: 已在加载中，跳过');
      return;
    }
    
    final newLoadMode = await WebDavService.getLoadMode();
    final modeChanged = newLoadMode != _loadMode;
    _loadMode = newLoadMode;
    
    // 【新增】检查 WebDAV 配置是否有效
    if (_loadMode == DataLoadMode.webdav) {
      final config = await WebDavService.loadConfig();
      _hasValidWebDavConfig = config.isValid;
    } else {
      _hasValidWebDavConfig = false;
    }
    
    // 加载缓存版本时间
    _lastSyncTime = await WebDavService.getLastSyncTime();
    setState(() {});
    
    // 只有模式变化或强制重新加载时才触发
    if (forceReload || modeChanged || _topicIndex == null) {
      await _autoLoadDataFile();
    } else {
      debugPrint('ℹ️ _initAndLoad: 模式未变化且已有数据，跳过加载');
    }
  }

  /// 自动加载数据文件
  ///
  /// 【重构】缓存优先，后台同步
  /// - 先尝试加载本地缓存
  /// - WebDAV 模式下后台启动同步
  Future<void> _autoLoadDataFile() async {
    // 先尝试加载本地缓存
    await _loadFromLocal(showLoadingIfEmpty: true);
    
    // WebDAV 模式下，后台启动同步
    if (_loadMode == DataLoadMode.webdav) {
      // 不 await，让其在后台运行
      _backgroundSyncFromWebDav();
    }
  }

  /// 【新增】后台从 WebDAV 同步数据
  /// 
  /// 非阻塞式，不影响缓存数据的显示
  Future<void> _backgroundSyncFromWebDav() async {
    // 防止重复同步
    if (_isBackgroundSyncing) {
      debugPrint('⚠️ 已在后台同步中，跳过');
      return;
    }

    final config = await WebDavService.loadConfig();
    if (!config.isValid) {
      // 配置不完整，更新状态（不显示错误，让空状态提示处理）
      if (mounted) {
        setState(() {
          _hasValidWebDavConfig = false;
          _isLoading = false;
        });
      }
      return;
    }
    
    // 配置有效
    if (mounted) {
      setState(() {
        _hasValidWebDavConfig = true;
      });
    }

    // 创建取消 token
    _downloadCancelToken = CancelToken();

    setState(() {
      _isBackgroundSyncing = true;
      _syncStage = SyncStage.connecting;
      _syncProgress = null;
      _syncMessage = '正在检查更新...';
    });

    try {
      // 1. 检查更新
      final (needUpdate, remoteFile, checkMessage) = await WebDavService.checkForUpdate(config);

      if (!mounted) return;

      // 【新增】记录检查时间和结果
      setState(() {
        _lastCheckTime = DateTime.now();
        _hasUpdate = needUpdate;
      });

      if (!needUpdate) {
        // 无需更新
        setState(() {
          _isBackgroundSyncing = false;
          _syncMessage = null;
          _syncStage = null;
        });
        debugPrint('ℹ️ WebDAV: $checkMessage');
        return;
      }

      // 2. 发现更新，根据网络状态决定是否自动下载
      final connectivityResult = await Connectivity().checkConnectivity();
      bool shouldDownload = false;

      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        // WiFi 环境下自动下载
        debugPrint('✅ WiFi 环境，自动开始下载');
        shouldDownload = true;
        setState(() {
          _syncMessage = 'WiFi 环境，自动下载更新...';
        });
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        // 蜂窝网络下询问用户
        debugPrint('⚠️ 蜂窝网络，询问用户');
        setState(() {
          _syncMessage = '发现新版本 (蜂窝网络)，等待确认...';
        });
        shouldDownload = await _showUpdateDialog(remoteFile!);
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
         // 有线网络自动下载
         shouldDownload = true;
      } else {
        // 无网络或其他情况 (虽然能检查到更新说明有网，但以防万一)
        // 默认询问
        shouldDownload = await _showUpdateDialog(remoteFile!);
      }
      
      if (!shouldDownload) {
        if (mounted) {
          setState(() {
            _isBackgroundSyncing = false;
            _syncMessage = null;
            _syncStage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已取消更新')),
          );
        }
        return;
      }

      // 3. 开始下载
      setState(() {
        _syncStage = SyncStage.downloading;
        _syncMessage = '正在下载...';
      });

      final localPath = await WebDavService.downloadBackup(
        config,
        remoteFile!,
        cancelToken: _downloadCancelToken,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _syncProgress = received / total;
              _syncMessage = '正在下载... ${(received / 1024 / 1024).toStringAsFixed(1)}MB';
            });
          }
        },
      );
      
      if (!mounted) return;

      if (localPath == null) {
        // 下载失败
        throw Exception('下载失败');
      }

      // 4. 下载成功，更新数据
      setState(() {
        _syncStage = SyncStage.parsing;
        _syncProgress = null;
        _syncMessage = '正在解析和构建索引...';
        _hasUpdate = false; // 【修复】下载完成后重置更新状态
      });

      // 清除旧缓存
      await DataPersistenceManager.clearCache();

      // 加载新文件
      final loadSuccess = await _loadFile(localPath, saveCache: true);

      if (loadSuccess) {
        // 更新缓存时间
        _lastSyncTime = await WebDavService.getLastSyncTime();

        if (mounted) {
          setState(() {
            _error = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 已从 WebDAV 同步最新数据'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // 加载失败，_error 已在 _loadFile 中设置
        debugPrint('⚠️ WebDAV 下载的文件加载失败');
      }

    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('ℹ️ WebDAV 下载已取消');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已取消下载'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        debugPrint('❌ WebDAV 同步异常: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ WebDAV 同步失败: ${e.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ WebDAV 同步异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ WebDAV 同步失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _downloadCancelToken = null;
      if (mounted) {
        setState(() {
          _isBackgroundSyncing = false;
          _syncProgress = null;
          _syncMessage = null;
          _syncStage = null;
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





  /// 取消正在进行的下载
  void _cancelDownload() {
    _downloadCancelToken?.cancel('用户取消');
  }

  /// 从本地加载数据
  /// 
  /// [showLoadingIfEmpty] 如果没有缓存是否显示加载状态
  /// 返回是否成功加载了缓存数据
  Future<bool> _loadFromLocal({bool showLoadingIfEmpty = false}) async {
    if (showLoadingIfEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
        _loadingMessage = '正在加载本地数据...';
      });
    }

    try {
      final startTime = DateTime.now();

      // 智能加载: 优先使用轻量级索引
      final (topicIndex, _) = await DataPersistenceManager.smartLoad();

      if (topicIndex != null && topicIndex.isNotEmpty) {
        // 从缓存加载索引
        debugPrint('✅ 从缓存加载话题索引');

        // 加载 Assistant 信息
        final lastFile = await DataPersistenceManager.getLastFilePath();
        if (lastFile != null) {
          // 创建轻量级 extractor（只用于获取 assistant 信息）
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
          if (_error != null &&
              (_error!.contains('ZIP 文件损坏') ||
                  _error!.contains('FormatException'))) {
            debugPrint('❌ 检测到ZIP文件损坏: $_error');
            await _handleCorruptedFile(lastFile);

            if (mounted) {
              // 根据是否正在后台同步，显示不同提示
              final errorMessage = _isBackgroundSyncing
                  ? '缓存文件损坏\n正在从 WebDAV 下载最新文件，请稍候...'
                  : 'ZIP 文件损坏\n请点击右上角刷新按钮重新下载，或手动选择文件';

              setState(() {
                _error = errorMessage;
                _isLoading = false;
              });
            }
          }
        } else {
          debugPrint('⚠️  上次打开的文件不存在: $lastFile');
        }
      } else {
        debugPrint('ℹ️  没有上次打开的文件记录');
      }

      setState(() {
        _isLoading = false;
      });
      return false;
    } catch (e) {
      debugPrint('⚠️  自动加载失败: $e');
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

    // 拷贝文件到App目录
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('📂 用户选择的文件: $filePath');

      // 拷贝文件到App内部目录
      final appFilePath = await DataPersistenceManager.copyFileToAppDirectory(
        filePath,
      );

      // 保存上次打开的目录(用于下次打开文件选择器)
      try {
        var fileDir = File(filePath).parent.path;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_opened_directory', fileDir);
        debugPrint('✅ 已保存目录: $fileDir');
      } catch (e) {
        debugPrint('保存目录失败: $e');
      }

      // 加载拷贝后的文件
      final success = await _loadFile(appFilePath, saveCache: true);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 文件已导入到App目录'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 加载失败，检查是否是文件损坏
        if (_error != null &&
            (_error!.contains('ZIP 文件损坏') ||
                _error!.contains('FormatException'))) {
          debugPrint('❌ 用户选择的文件损坏: $_error');
          await _handleCorruptedFile(appFilePath);

          if (mounted) {
            setState(() {
              _error = '选择的 ZIP 文件损坏或格式无效\n请确认文件完整性后重新选择';
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ ZIP 文件损坏，请重新选择文件'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        // 其他错误 _error 已在 _loadFile 中设置
      }
    } catch (e) {
      // 拷贝过程或其他错误
      setState(() {
        _error = '文件导入失败: $e';
        _isLoading = false;
      });
      debugPrint('文件导入失败: $e');
    }
  }

  /// 加载指定文件
  ///
  /// 【优化】加载完成后保存轻量级索引到 Isar
  /// 加载文件，返回是否成功
  Future<bool> _loadFile(String filePath, {bool saveCache = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _extractor = null;
      _topicIndex = null;
      _assistantMap = null;
    });

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
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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

  /// 下载并加载指定的备份文件
  Future<void> _downloadAndLoadBackup(BackupFileInfo backup) async {
    setState(() {
      _isBackgroundSyncing = true;
      _syncStage = SyncStage.downloading;
      _syncProgress = 0;
      _syncMessage = '正在下载: ${backup.displayName}';
      _error = null;
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

      // 下载成功，解析文件
      setState(() {
        _syncStage = SyncStage.parsing;
        _syncProgress = null;
        _syncMessage = '正在解析和构建索引...';
      });

      // 清除旧缓存
      await DataPersistenceManager.clearCache();

      // 加载新文件
      final loadSuccess = await _loadFile(localPath, saveCache: true);

      if (loadSuccess) {
        _lastSyncTime = await WebDavService.getLastSyncTime();

        if (mounted) {
          setState(() {
            _error = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 已加载备份: ${backup.displayName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('⚠️ 备份文件加载失败');
      }
    } catch (e) {
      debugPrint('❌ 下载备份失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackgroundSyncing = false;
          _syncProgress = null;
          _syncMessage = null;
          _syncStage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cherry Reader'),
        actions: [
          // 后台同步时显示取消按钮
          if (_isBackgroundSyncing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelDownload,
              tooltip: '取消同步',
            ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isLoading || _isBackgroundSyncing) ? null : _refreshData,
            tooltip: _loadMode == DataLoadMode.webdav ? '从 WebDAV 刷新' : '重新加载',
          ),
          // 清除缓存按钮
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _isLoading ? null : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清除缓存'),
                  content: const Text('确定要清除所有缓存吗？\n\n清除后需要重新加载数据文件。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await DataPersistenceManager.clearCache();
                  await RepositoryProvider.instance.database.clearAll();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 缓存已清除，请重新加载文件'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  setState(() {
                    _extractor = null;
                    _topicIndex = null;
                    _assistantMap = null;
                    _lastSyncTime = null;
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('清除缓存失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            tooltip: '清除缓存',
          ),
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
        ],
        // 【新增】AppBar 下方同步进度条
        // 【优化】只有在有缓存数据时才显示顶部进度条（静默同步）
        // 无缓存首次下载时，使用中间的大进度展示，避免重复
        bottom: (_isBackgroundSyncing && _topicIndex != null)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _syncProgress,
                      backgroundColor: Colors.grey[300],
                      minHeight: 3,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _syncMessage ?? '同步中...',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          if (_syncProgress != null)
                            Text(
                              '${(_syncProgress! * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          // 【新增】底部状态栏
          if (_topicIndex != null) _buildStatusBar(),
        ],
      ),
      floatingActionButton: _loadMode == DataLoadMode.manual
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _pickAndLoadFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('加载数据'),
            )
          : null,
    );
  }

  /// 底部状态栏
  Widget _buildStatusBar() {
    return GestureDetector(
      onTap: () {
        // 【新增】点击状态栏时刷新时间显示
        if (_lastCheckTime != null) {
          setState(() {});
        }
      },
      child: SafeArea(
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // WebDAV 模式：显示数据同步状态 + 检查时效性
            if (_loadMode == DataLoadMode.webdav) ...[
              // 根据状态显示不同图标
              if (_hasUpdate == null) ...[
                // 未检查
                Icon(Icons.help_outline, size: 14, color: Colors.grey[400]),
              ] else if (_hasUpdate == true) ...[
                // 有更新
                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange[600]),
              ] else ...[
                // 已是最新
                Icon(Icons.check_circle_outline, size: 14, color: Colors.green[600]),
              ],
              const SizedBox(width: 6),
              
              // 状态文字
              Expanded(
                child: Text(
                  _hasUpdate == null
                      ? '未检查 • 点击刷新检查更新'
                      : _hasUpdate == true
                          ? '有新版本可用 • ${_formatCheckTime(_lastCheckTime)}'
                          : '数据已是最新 • ${_formatCheckTime(_lastCheckTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: _hasUpdate == null
                        ? Colors.grey[500]
                        : _hasUpdate == true
                            ? Colors.orange[700]
                            : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              // 本地模式
              const Icon(Icons.folder_open, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '本地模式 • 数据来自本地文件',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      ), // GestureDetector
    );
  }

  Widget _buildBody() {
    // 首次加载无缓存时显示加载动画
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_loadingMessage ?? '正在加载数据...'),
          ],
        ),
      );
    }

    // 【修复】如果正在后台同步，优先显示同步状态，不显示旧的错误
    // 因为新文件正在下载，旧错误会让用户困惑
    if (_error != null && !_isBackgroundSyncing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('加载失败', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 如果是 WebDAV 模式，显示选择其他备份按钮
              if (_loadMode == DataLoadMode.webdav && _hasValidWebDavConfig) ...[
                ElevatedButton.icon(
                  onPressed: _showBackupSelector,
                  icon: const Icon(Icons.history),
                  label: const Text('选择其他备份'),
                ),
                const SizedBox(height: 12),
              ],
              // 重试按钮
              OutlinedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_topicIndex == null) {
      // 【优化】如果正在后台同步，显示友好的阶段提示（方案A）
      if (_isBackgroundSyncing) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 根据阶段显示不同图标
              _buildSyncStageIcon(),
              const SizedBox(height: 24),
              // 阶段提示文字（友好）
              Text(
                _getSyncStageMessage(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              // 阶段描述
              Text(
                _getSyncStageDescription(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              // 下载阶段显示进度条
              if (_syncStage == SyncStage.downloading && _syncProgress != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: 250,
                  child: LinearProgressIndicator(
                    value: _syncProgress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_syncProgress! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ] else ...[
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ],
          ),
        );
      }

      // 无数据且未在同步，显示空状态提示
      // 【优化】更美观的空状态页面
      return _buildEmptyState();
    }

    return _buildTopicList();
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

                        Navigator.push(
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

  /// 【新增】根据同步阶段显示不同图标
  Widget _buildSyncStageIcon() {
    switch (_syncStage) {
      case SyncStage.connecting:
        return Icon(Icons.cloud_sync, size: 64, color: Colors.blue[400]);
      case SyncStage.downloading:
        return Icon(Icons.cloud_download, size: 64, color: Colors.blue[600]);
      case SyncStage.parsing:
        return Icon(Icons.auto_fix_high, size: 64, color: Colors.orange[400]);
      case SyncStage.completed:
        return Icon(Icons.check_circle, size: 64, color: Colors.green[400]);
      default:
        return Icon(Icons.sync, size: 64, color: Colors.grey[400]);
    }
  }

  /// 【新增】获取同步阶段的友好提示
  String _getSyncStageMessage() {
    switch (_syncStage) {
      case SyncStage.connecting:
        return '正在连接云端';
      case SyncStage.downloading:
        return '正在下载数据';
      case SyncStage.parsing:
        return '正在解析内容';
      case SyncStage.completed:
        return '同步完成';
      default:
        return '正在同步';
    }
  }

  /// 【新增】获取同步阶段的详细描述
  String _getSyncStageDescription() {
    switch (_syncStage) {
      case SyncStage.connecting:
        return '正在连接到 WebDAV 服务器\n验证配置并检查更新';
      case SyncStage.downloading:
        return '正在从云端下载您的对话记录\n请保持网络连接';
      case SyncStage.parsing:
        return '正在解析数据并构建索引\n马上就好...';
      case SyncStage.completed:
        return '数据已成功同步';
      default:
        return '请稍候...';
    }
  }
}
