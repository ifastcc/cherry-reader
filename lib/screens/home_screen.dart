import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/cherry_extractor.dart';
import '../services/data_persistence_manager.dart';
import '../services/isar_database.dart';
import '../services/webdav_service.dart';
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

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  void initState() {
    super.initState();
    _initAndLoad();
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
      _syncMessage = '正在连接 WebDAV 服务器...';
    });

    try {
      final (updated, localPath, message) = await WebDavService.autoSync(
        config,
        cancelToken: _downloadCancelToken,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _syncStage = SyncStage.downloading;
              _syncProgress = received / total;
              _syncMessage = '正在下载... ${(received / 1024 / 1024).toStringAsFixed(1)}MB';
            });
          }
        },
      );

      if (!mounted) return;

      if (localPath == null) {
        // 同步失败
        setState(() {
          _isBackgroundSyncing = false;
          _syncProgress = null;
          _syncMessage = null;
          _syncStage = null;
        });
        
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ WebDAV 同步失败: $message'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      if (updated) {
        // 有更新，重新加载数据
        setState(() {
          _syncStage = SyncStage.parsing;
          _syncProgress = null;
          _syncMessage = '正在解析和构建索引...';
        });

        try {
          await _loadFile(localPath, saveCache: true);

          // 更新缓存时间
          _lastSyncTime = await WebDavService.getLastSyncTime();

          // 【修复】加载成功后清除之前的错误状态
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
        } catch (e) {
          // 【修复】如果下载的文件损坏，清除并提示重试
          if (e.toString().contains('ZIP 文件损坏') ||
              e.toString().contains('FormatException')) {
            debugPrint('❌ WebDAV下载的文件损坏: $e');
            await _handleCorruptedFile(localPath);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ 下载的文件不完整或损坏\n可能是网络中断导致，请点击刷新按钮重试'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );

              // 同时更新错误状态，方便用户看到
              setState(() {
                _error = 'WebDAV 下载的文件损坏\n请点击右上角刷新按钮重新下载';
              });
            }
          } else {
            rethrow;
          }
        }
      } else {
        // 无更新
        debugPrint('ℹ️ WebDAV: 已是最新版本');
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
          try {
            await _loadFile(lastFile, saveCache: true);
            return true;
          } catch (e) {
            // 【修复】如果文件损坏，清除缓存并删除损坏的文件
            if (e.toString().contains('ZIP 文件损坏') ||
                e.toString().contains('FormatException')) {
              debugPrint('❌ 检测到ZIP文件损坏，清除缓存: $e');
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
            } else {
              rethrow;
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

      // 3. 清除Isar数据库
      await IsarDatabase().clearTopicCaches();
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
      try {
        await _loadFile(appFilePath, saveCache: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 文件已导入到App目录'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // 【修复】区分ZIP损坏和其他错误
        if (e.toString().contains('ZIP 文件损坏') ||
            e.toString().contains('FormatException')) {
          debugPrint('❌ 用户选择的文件损坏: $e');
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
        } else {
          // 其他加载错误
          rethrow;
        }
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
  Future<void> _loadFile(String filePath, {bool saveCache = false}) async {
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

      // 【优化】提取话题索引（轻量级）
      final grouped = extractor.getTopicsByAssistant();
      final topicIndex = <String, List<Map<String, dynamic>>>{};

      for (final entry in grouped.entries) {
        final assistantId = entry.key;
        final assistantData = entry.value;
        final topics = assistantData['topics'] as List<dynamic>;

        topicIndex[assistantId] = topics.map((t) {
          final topic = t as Map<String, dynamic>;
          return {
            'id': topic['id'],
            'name': topic['name'],
            'assistantId': assistantId,
            'messageCount': (topic['messages'] as List?)?.length ?? 0,
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

      // 保存轻量级索引到缓存
      if (saveCache) {
        try {
          // 【修复】构建完整话题数据（包含解析后的 blocks）
          final allTopics = <Map<String, dynamic>>[];
          for (final entry in grouped.entries) {
            final assistantData = entry.value;
            final topics = assistantData['topics'] as List<dynamic>;
            for (final t in topics) {
              final topic = t as Map<String, dynamic>;

              // 【关键修复】解析每个消息的 blocks
              final messages = topic['messages'] as List<dynamic>? ?? [];
              final processedMessages = <Map<String, dynamic>>[];

              for (final msg in messages) {
                if (msg is! Map<String, dynamic>) continue;

                // 提取 block IDs 并查找完整 block 数据
                final blockIds =
                    (msg['blocks'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final resolvedBlocks = extractor.getMessageBlocks(blockIds);

                // 创建包含完整 blocks 的消息副本
                final processedMsg = Map<String, dynamic>.from(msg);
                processedMsg['blocks'] = resolvedBlocks;
                processedMessages.add(processedMsg);
              }

              // 创建包含解析后消息的话题副本
              final processedTopic = Map<String, dynamic>.from(topic);
              processedTopic['messages'] = processedMessages;
              processedTopic['assistantId'] = entry.key;

              allTopics.add(processedTopic);
            }
          }

          await DataPersistenceManager.saveTopicIndexCache(allTopics);
          await DataPersistenceManager.markCacheAsValid();
          await DataPersistenceManager.saveFileTimestamp(filePath);
          debugPrint('✅ 已保存话题缓存');
        } catch (e) {
          debugPrint('⚠️  保存缓存失败: $e');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red),
        );
      }
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
                  await IsarDatabase().clearAll();

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 模式标识
          Icon(
            _loadMode == DataLoadMode.webdav ? Icons.cloud : Icons.folder,
            size: 12,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _loadMode == DataLoadMode.webdav ? 'WebDAV' : '本地',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          
          // 分隔符
          if (_lastSyncTime != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('·', style: TextStyle(color: Colors.grey[400])),
            ),
            // 同步时间
            Text(
              '同步于 ${_formatSyncTime(_lastSyncTime)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
          
          const Spacer(),
          
          // 精确时间（可选）
          if (_lastSyncTime != null)
            Text(
              DateFormat('MM-dd HH:mm').format(_lastSyncTime!),
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
        ],
      ),
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
      // 【优化】区分"未配置 WebDAV"和"已配置但无数据"
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _loadMode == DataLoadMode.webdav
                  ? (_hasValidWebDavConfig ? Icons.cloud_queue : Icons.cloud_off)
                  : Icons.folder_open,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              _loadMode == DataLoadMode.webdav
                  ? (_hasValidWebDavConfig ? '暂无数据' : '请在设置中配置 WebDAV')
                  : '请选择 Cherry Studio 导出文件',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _loadMode == DataLoadMode.webdav
                  ? (_hasValidWebDavConfig
                      ? '点击刷新按钮从云端同步数据'
                      : '配置后可自动同步对话记录')
                  : '支持 .zip 或 .json 格式',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            if (_loadMode == DataLoadMode.webdav) ...[
              if (_hasValidWebDavConfig)
                // 已配置，显示刷新按钮
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('立即同步'),
                )
              else
                // 未配置，显示去设置按钮
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
                  label: const Text('去设置'),
                ),
            ],
          ],
        ),
      );
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
            // 【优化】ExpansionTile 的 children 仍使用 map，因为这只在展开时渲染
            children: topics.map((topic) {
              final topicName = topic['name'] as String? ?? '未命名话题';
              final topicId = topic['id'] as String;
              final messageCount = topic['messageCount'] as int? ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                title: Text(topicName),
                subtitle: Text('$messageCount 条消息'),
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
              }).toList(),
            ),
          );
        },
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
