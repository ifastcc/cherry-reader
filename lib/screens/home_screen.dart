import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:webdav_client/webdav_client.dart' as wd;
import 'dart:io';
import 'dart:async'; // For Timer
import '../services/cherry_extractor.dart';
import '../services/data_persistence_manager.dart';
import '../services/repository_provider.dart';
import '../services/webdav_service.dart';
import '../services/local_folder_sync_service.dart';
import '../services/ai_provider_service.dart';
import '../services/version_service.dart';
import '../services/background_import_service.dart';
import '../services/sync_status_notifier.dart';
import '../services/sync/sync_coordinator.dart';
import '../services/sync/sync_candidate.dart';
import '../services/sync/sync_preferences.dart';
import '../services/sync/sync_source_type.dart';
import '../services/timeline_compute_service.dart';
import '../models/domain/data_version.dart';
import '../models/domain/status_bar_state.dart';
import '../models/computed_timeline.dart';
import 'conversation_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'insight_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/status_badge.dart';
import '../widgets/topic_card.dart';
import '../widgets/sync_status_widget.dart';

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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CherryExtractor? _extractor;
  bool _isLoading = false;  // 仅用于首次加载无缓存时
  bool _autoWebDavEnabled = false;
  bool _autoLocalFolderEnabled = false;
  bool _autoHttpPullEnabled = false;
  bool _autoLanReceiveEnabled = false;
  StreamSubscription<SyncCandidate>? _syncCandidateSubscription;

  // 视图模式（默认为时间线）
  HomeViewMode _viewMode = HomeViewMode.timeline;

  // 话题索引和助手信息（用于树形视图兼容）
  Map<String, List<Map<String, dynamic>>>? _topicIndex;
  Map<String, Map<String, dynamic>>? _assistantMap;

  // 【性能优化】预计算的时间线数据
  ComputedTimeline? _computedTimeline;
  int _timelineVersion = 0;
  bool _isComputingTimeline = false;
  Timer? _skeletonTimer;
  DateTime? _skeletonShownAt;
  static const _skeletonDelay = Duration(milliseconds: 200);
  static const _skeletonMinDuration = Duration(milliseconds: 300);

  // 【性能优化】同步状态通知器（独立于主 Widget 树）
  late final SyncStatusNotifier _syncNotifier;

  // 同步状态（保留用于兼容，逐步迁移到 _syncNotifier）
  bool _isSyncing = false;
  double? _syncProgress;
  String? _syncMessage;

  // 统一错误状态
  String? _statusError;

  // 数据源配置状态
  bool _hasValidWebDavConfig = false;
  bool _hasValidLocalFolderConfig = false;
  LocalBackupInfo? _pendingLocalBackup;

  // 版本管理
  StreamSubscription<ImportStatus>? _importStatusSubscription;
  DataVersion? _activeVersion;
  String? _currentVersionDisplay;
  bool _hasNewVersion = false;
  bool _hasUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncNotifier = SyncStatusNotifier();
    _loadViewMode();
    _initVersionListener();
    _initSyncCoordinator();
    _initAndLoad();
  }

  void _initSyncCoordinator() {
    unawaited(SyncCoordinator.instance.init());
    _syncCandidateSubscription?.cancel();
    _syncCandidateSubscription =
        SyncCoordinator.instance.candidateStream.listen(_onSyncCandidate);
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
    _syncCandidateSubscription?.cancel();
    unawaited(SyncCoordinator.instance.stopWatchingLocalFolder());
    _importStatusSubscription?.cancel();
    _skeletonTimer?.cancel();
    _syncNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用回到前台时刷新界面
    if (state == AppLifecycleState.resumed) {
      // 【增量更新】检查时间边界，必要时重新分组
      _refreshTimelineIfNeeded();
      setState(() {});
    }
  }

  /// 初始化并加载数据
  Future<void> _initAndLoad({bool forceReload = false}) async {
    if (_isLoading) {
      debugPrint('⚠️ _initAndLoad: 已在加载中，跳过');
      return;
    }

    final prevAutoWebDavEnabled = _autoWebDavEnabled;
    final prevAutoLocalFolderEnabled = _autoLocalFolderEnabled;
    final prevAutoHttpPullEnabled = _autoHttpPullEnabled;
    final prevAutoLanReceiveEnabled = _autoLanReceiveEnabled;

    await SyncPreferences.migrateFromLegacyIfNeeded();
    final sources = await SyncPreferences.getAutoSources();

    _autoWebDavEnabled = sources[SyncSourceType.webdav] ?? false;
    _autoLocalFolderEnabled = sources[SyncSourceType.localFolder] ?? false;
    _autoHttpPullEnabled = sources[SyncSourceType.httpPull] ?? false;
    _autoLanReceiveEnabled = sources[SyncSourceType.lanReceive] ?? false;

    final webdavConfig = await WebDavService.loadConfig();
    _hasValidWebDavConfig = webdavConfig.isValid;
    final localConfig = await LocalFolderSyncService.loadConfig();
    _hasValidLocalFolderConfig = localConfig.isValid;

    await SyncCoordinator.instance.startWatchingLocalFolderIfEnabled();

    final settingsChanged = prevAutoWebDavEnabled != _autoWebDavEnabled ||
        prevAutoLocalFolderEnabled != _autoLocalFolderEnabled ||
        prevAutoHttpPullEnabled != _autoHttpPullEnabled ||
        prevAutoLanReceiveEnabled != _autoLanReceiveEnabled;

    // 如果正在同步，只更新配置状态
    if (_isSyncing) {
      debugPrint('ℹ️ _initAndLoad: 同步中，只更新配置状态');
      if (mounted) setState(() {});
      return;
    }

    if (mounted) setState(() {});

    if (forceReload || settingsChanged || _topicIndex == null) {
      await _autoLoadDataFile();
    }
  }

  /// 自动加载数据文件
  Future<void> _autoLoadDataFile() async {
    await _loadFromLocal(showLoadingIfEmpty: true);
    if (_hasAnySyncSourceSelected) {
      _syncFromEnabledSources();
    }
  }

  List<String> get _selectedSourceLabels {
    final enabled = <String>[];
    if (_autoLocalFolderEnabled) enabled.add('文件夹');
    if (_autoWebDavEnabled) enabled.add('WebDAV');
    if (_autoHttpPullEnabled) enabled.add('HTTP');
    if (_autoLanReceiveEnabled) enabled.add('局域网接收');
    return enabled;
  }

  bool get _hasAnySyncSourceSelected => _selectedSourceLabels.isNotEmpty;

  String get _syncModeLabel {
    final enabled = _selectedSourceLabels;
    if (enabled.isEmpty) return '未选择来源';
    return enabled.join(' + ');
  }

  void _onSyncCandidate(SyncCandidate candidate) {
    if (candidate.sourceType != SyncSourceType.localFolder) return;
    unawaited(_syncLatestFromTypes({SyncSourceType.localFolder}));
  }

  Future<void> _syncLatestFromTypes(
    Set<SyncSourceType> enabledTypes, {
    bool force = false,
  }) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _statusError = null;
    _syncProgress = null;
    _syncMessage = null;
    _syncNotifier.startChecking();

    try {
      final discovery =
          await SyncCoordinator.instance.discoverLatestCandidatesForTypes(enabledTypes);
      if (!mounted) return;
      final candidate = SyncCoordinator.instance.chooseLatest(discovery.candidates);
      if (candidate == null) {
        if (discovery.warnings.isNotEmpty) {
          final msg = discovery.warnings.join('\n');
          _syncNotifier.setError(msg);
          setState(() {
            _statusError = msg;
          });
        }
        return;
      }

      final decision = force
          ? SyncDecision(selected: candidate, shouldSync: true)
          : await SyncCoordinator.instance.decideWhetherToSync(candidate);

      if (!decision.shouldSync) {
        if (mounted) setState(() => _hasUpdate = false);
        return;
      }

      await _performCandidateSync(candidate, force: force);
    } catch (e) {
      if (mounted) {
        _syncNotifier.setError('同步失败\n\n$e');
        setState(() {
          _statusError = '同步失败\n\n$e';
        });
      }
    } finally {
      _isSyncing = false;
      if (_statusError == null) {
        _syncNotifier.complete();
      }
    }
  }

  Future<void> _syncFromEnabledSources({bool force = false}) async {
    if (_isSyncing) return;
    if (!_hasAnySyncSourceSelected) return;

    _isSyncing = true;
    _statusError = null;
    _syncProgress = null;
    _syncMessage = null;
    _syncNotifier.startChecking();

    try {
      final discovery = await SyncCoordinator.instance.discoverLatestCandidates();
      if (!mounted) return;
      final candidate = SyncCoordinator.instance.chooseLatest(discovery.candidates);
      if (candidate == null) {
        if (discovery.warnings.isNotEmpty) {
          final msg = discovery.warnings.join('\n');
          _syncNotifier.setError(msg);
          setState(() {
            _statusError = msg;
          });
        } else {
          _syncNotifier.complete();
        }
        _isSyncing = false;
        return;
      }

      final decision = force
          ? SyncDecision(selected: candidate, shouldSync: true)
          : await SyncCoordinator.instance.decideWhetherToSync(candidate);

      if (!decision.shouldSync) {
        if (mounted) setState(() => _hasUpdate = false);
        return;
      }

      await _performCandidateSync(candidate, force: force);
    } catch (e) {
      if (mounted) {
        _syncNotifier.setError('同步失败\n\n$e');
        setState(() {
          _statusError = '同步失败\n\n$e';
        });
      }
    } finally {
      _isSyncing = false;
      if (_statusError == null) {
        _syncNotifier.complete();
      }
    }
  }

  Future<void> _performCandidateSync(
    SyncCandidate candidate, {
    required bool force,
  }) async {
    if (candidate.sourceType == SyncSourceType.localFolder) {
      final autoLoad = await LocalFolderSyncService.getAutoLoad();
      if (!autoLoad && !force) {
        if (mounted) {
          setState(() {
            _pendingLocalBackup = LocalBackupInfo(
              name: candidate.name,
              path: candidate.remoteId,
              size: candidate.size,
              modifiedTime: candidate.modifiedAt,
            );
            _hasUpdate = true;
          });
        }
        return;
      }
    }

    wd.File? remoteFileForDialog;
    if (candidate.sourceType == SyncSourceType.webdav) {
      final config = await WebDavService.loadConfig();
      final list = await WebDavService.listBackupFiles(config);
      for (final item in list) {
        if (item.name == candidate.name) {
          remoteFileForDialog = item.webdavFile;
          break;
        }
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      var shouldDownload = false;
      if (force) {
        shouldDownload = true;
      } else if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet)) {
        shouldDownload = true;
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        if (remoteFileForDialog != null) {
          _syncNotifier.updateDownloadProgress(0, '等待确认...');
          shouldDownload = await _showUpdateDialog(remoteFileForDialog);
        }
      } else {
        if (remoteFileForDialog != null) {
          shouldDownload = await _showUpdateDialog(remoteFileForDialog);
        }
      }

      if (!shouldDownload) {
        if (mounted) setState(() => _hasUpdate = true);
        return;
      }
    }

    if (candidate.sourceType == SyncSourceType.webdav) {
      _syncNotifier.updateDownloadProgress(0, '下载中...');
    } else {
      _syncNotifier.updateImportProgress('加载备份...');
    }

    final localPath = await SyncCoordinator.instance.fetchToAppDataPath(
      candidate,
      onWebDavProgress: (received, total) {
        if (total > 0) {
          final progress = received / total;
          final msg = '下载中 ${(received / 1024 / 1024).toStringAsFixed(1)}MB';
          _syncNotifier.updateDownloadProgress(progress, msg);
        }
      },
    );

    if (!mounted) return;
    if (localPath == null) throw Exception('获取失败');

    _syncNotifier.startParsing();

    await DataPersistenceManager.clearCache();
    final loadSuccess = await _loadFile(
      localPath,
      saveCache: true,
      silent: _topicIndex != null,
    );

    if (loadSuccess) {
      await SyncPreferences.setLastImported(
        fingerprint: candidate.fingerprint,
        modifiedAt: candidate.modifiedAt,
        sourceType: candidate.sourceType,
      );
    }

    if (mounted) {
      setState(() {
        _hasUpdate = false;
        _pendingLocalBackup = null;
      });
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

    _isSyncing = true;
    // 【性能优化】使用 notifier 更新状态
    _syncNotifier.updateImportProgress(
      retryCount > 0 ? '等待文件写入完成...' : '复制文件...',
    );

    try {
      // 1. 复制文件到 App 目录（含 ZIP 完整性检查）
      final localPath = await LocalFolderSyncService.loadBackup(backup);

      if (localPath == null) {
        // ZIP 文件可能还在写入中，尝试重试
        if (retryCount < maxRetries) {
          debugPrint('⏳ ZIP 文件未就绪，${retryDelay.inSeconds}秒后重试 (${retryCount + 1}/$maxRetries)');
          _isSyncing = false;
          _syncNotifier.complete();
          await Future.delayed(retryDelay);
          return _loadLocalBackup(backup, retryCount: retryCount + 1);
        }
        throw Exception('文件复制失败：ZIP 文件可能不完整');
      }

      if (!mounted) return;
      _syncNotifier.startParsing();

      // 2. 【后台】在 Isolate 中解压和解析 JSON（不阻塞 UI）
      final extractor = await CherryExtractor.loadInBackground(
        zipPath: localPath.endsWith('.zip') ? localPath : null,
        dataJsonPath: localPath.endsWith('.zip') ? null : localPath,
      );

      if (!mounted) return;
      _syncNotifier.updateImportProgress('处理数据...');

      // 3. 处理数据（主线程，但相对较快）
      await _processLoadedExtractor(extractor, backup.displayName);

      // 4. 保存缓存
      await DataPersistenceManager.clearCache();
      await _saveToCache(extractor, localPath);

      await SyncPreferences.setLastImported(
        fingerprint: SyncCandidate(
          sourceType: SyncSourceType.localFolder,
          name: backup.name,
          remoteId: backup.path,
          size: backup.size,
          modifiedAt: backup.modifiedTime,
          displayName: backup.displayName,
        ).fingerprint,
        modifiedAt: backup.modifiedTime,
        sourceType: SyncSourceType.localFolder,
      );

      if (mounted) {
        setState(() {
          _hasUpdate = false;
          _pendingLocalBackup = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _syncNotifier.setError('加载备份失败\n\n$e');
        _statusError = '加载备份失败\n\n$e';
      }
    } finally {
      _isSyncing = false;
      if (_statusError == null) {
        _syncNotifier.complete();
      }
    }
  }

  /// 处理已加载的 extractor（从后台加载结果更新 UI）
  Future<void> _processLoadedExtractor(CherryExtractor extractor, String versionDisplay) async {
    // 提取 Assistant 信息（轻量操作，保留在主线程）
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

    // 为树形视图保留 topicIndex（兼容）
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

    // 更新基础 UI 状态
    if (mounted) {
      setState(() {
        _extractor = extractor;
        _topicIndex = topicIndex;
        _assistantMap = assistantMap;
        _currentVersionDisplay = versionDisplay;
        _isLoading = false;
      });
    }

    // 【性能优化】触发 Isolate 计算时间线
    if (extractor.rawData != null) {
      _computeTimelineAsync(extractor.rawData!, assistantMap);
    }
  }

  /// 【性能优化】在 Isolate 中计算时间线
  Future<void> _computeTimelineAsync(
    Map<String, dynamic> rawData,
    Map<String, Map<String, dynamic>> assistantMap,
  ) async {
    _timelineVersion++;
    final currentVersion = _timelineVersion;
    _isComputingTimeline = true;

    // 延迟显示骨架屏，避免闪烁
    _skeletonTimer?.cancel();
    _skeletonTimer = Timer(_skeletonDelay, () {
      if (_isComputingTimeline && mounted) {
        _skeletonShownAt = DateTime.now();
        setState(() {}); // 触发显示骨架屏
      }
    });

    try {
      final result = await TimelineComputeService.computeTimeline(
        TimelineComputeParams(
          version: currentVersion,
          rawData: rawData,
          assistantMap: assistantMap,
          now: DateTime.now(),
        ),
      );

      // 版本检查，防止过期结果覆盖新数据
      if (result.version != _timelineVersion) {
        debugPrint('⚠️ 时间线计算结果已过期，丢弃');
        return;
      }

      _skeletonTimer?.cancel();

      // 如果骨架屏已显示，确保最少显示一段时间
      if (_skeletonShownAt != null) {
        final elapsed = DateTime.now().difference(_skeletonShownAt!);
        if (elapsed < _skeletonMinDuration) {
          await Future.delayed(_skeletonMinDuration - elapsed);
        }
      }

      if (mounted) {
        setState(() {
          _computedTimeline = result;
          _isComputingTimeline = false;
          _skeletonShownAt = null;
        });
      }

      debugPrint('✅ 时间线计算完成: ${result.totalCount} 个话题');
    } catch (e) {
      debugPrint('❌ 时间线计算失败: $e');
      _skeletonTimer?.cancel();
      if (mounted) {
        setState(() {
          _isComputingTimeline = false;
          _skeletonShownAt = null;
        });
      }
    }
  }

  /// 保存到缓存 (创建新版本)
  Future<void> _saveToCache(CherryExtractor extractor, String filePath) async {
    try {
      final file = File(filePath);
      final modifiedAt = await file.lastModified();
      final filename = filePath.split(Platform.pathSeparator).last;

      debugPrint('📦 启动后台导入以创建版本: $filename');
      // 不等待其完成，让它在后台运行，UI 通过 Stream 更新状态
      BackgroundImportService.instance.importInBackground(
        extractor: extractor,
        sourceFileName: filename,
        sourceModifiedAt: modifiedAt,
      ).ignore();
      
    } catch (e) {
      debugPrint('⚠️ 保存缓存请求失败: $e');
    }
  }

  // ============ 【增量更新】时间线缓存增量操作 ============

  /// 【增量更新】重新分组（当时间跨越边界时调用，如跨越午夜）
  void _regroupTimeline() {
    if (_computedTimeline == null) return;
    _computedTimeline!.regroup();
    if (mounted) setState(() {});
    debugPrint('✅ 时间线重新分组完成');
  }

  /// 【增量更新】刷新时间线分组（可在应用恢复前台时调用）
  void _refreshTimelineIfNeeded() {
    if (_computedTimeline == null) return;
    
    final now = DateTime.now();
    final computedAt = _computedTimeline!.computedAt;
    
    // 如果跨越了日期边界，重新分组
    final computedDate = DateTime(computedAt.year, computedAt.month, computedAt.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    
    if (nowDate != computedDate) {
      debugPrint('📅 时间线跨越日期边界，重新分组');
      _regroupTimeline();
    }
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
      if (_autoLocalFolderEnabled && _currentVersionDisplay == null) {
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

      if (success) {
        final stat = await File(filePath).stat();
        await SyncPreferences.setLastImported(
          fingerprint: SyncCandidate(
            sourceType: SyncSourceType.manualImport,
            name: filePath.split(Platform.pathSeparator).last,
            remoteId: filePath,
            size: stat.size,
            modifiedAt: stat.modified,
          ).fingerprint,
          modifiedAt: stat.modified,
          sourceType: SyncSourceType.manualImport,
        );
      }

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
        await _saveToCache(extractor, filePath);
        // 保存时间戳
        try {
           await DataPersistenceManager.saveFileTimestamp(filePath);
        } catch (_) {}
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

  /// 刷新数据（强制同步一次）
  Future<void> _refreshData() async {
    if (_hasAnySyncSourceSelected) {
      await _syncFromEnabledSources(force: true);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('未选择同步来源：请在设置里选择来源，或手动导入 ZIP'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSyncActionsSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('同步最新'),
                subtitle: Text(
                  _hasAnySyncSourceSelected ? _syncModeLabel : '未选择来源：去设置选择同步来源',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (_hasAnySyncSourceSelected) {
                    await _syncFromEnabledSources(force: true);
                    return;
                  }
                  await Navigator.push(
                    this.context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  if (mounted) {
                    _initAndLoad(forceReload: true);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('选择 ZIP/JSON 导入'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndLoadFile();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// 处理主按钮点击 (Floating Dock Center Action)
  void handleMainAction() {
    if (_topicIndex == null) {
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
      body: _buildBody(),
    );
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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        
        // 内容区域
        if (_topicIndex == null)
          SliverFillRemaining(
            child: _isSyncing 
              ? Center(
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
                )
              : _buildEmptyState(),
          )
        else
          _viewMode == HomeViewMode.tree 
              ? _buildTopicListSliver() 
              : _buildTimelineListSliver(),
          
        // 底部留白，防止被 Dock 遮挡
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  /// 构建 SliverAppBar (Immersive Header)
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      title: _buildStatusBadge(),
      centerTitle: false,
      pinned: false, // 不固定，随滚动滑出
      floating: true, // 向上滚动立即出现
      snap: true,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.sync),
          onPressed: _isLoading ? null : _showSyncActionsSheet,
          tooltip: '同步',
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
          icon: const Icon(Icons.settings_outlined),
          onPressed: _isLoading ? null : () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            if (mounted) {
              await _loadViewMode();
              _initAndLoad();
            }
          },
          tooltip: '设置',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
  
  /// 构建状态徽章 (Mini version for AppBar Action)
  Widget _buildStatusBadge() {
    // 【性能优化】同步进行中时使用独立的 SyncStatusWidget，不触发全局重建
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: _syncNotifier,
      builder: (context, syncStatus, _) {
        // 如果正在同步，显示同步状态
        if (syncStatus.isInProgress) {
          return SyncStatusWidget(
            notifier: _syncNotifier,
            onTap: () => _onStatusBarTap(_computeStatusBarState()),
          );
        }
        
        // 否则使用原有逻辑
        final state = _computeStatusBarState();
        final badgeState = switch (state.phase) {
          StatusBarPhase.idle => StatusBadgeState.idle,
          StatusBarPhase.syncing => StatusBadgeState.syncing,
          StatusBarPhase.hasUpdate => StatusBadgeState.hasUpdate,
          StatusBarPhase.error => StatusBadgeState.error,
        };
        
        return StatusBadge(
          state: badgeState,
          message: null,
          onTap: () => _onStatusBarTap(state),
        );
      },
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
        modeLabel: _syncModeLabel,
        errorDetail: _statusError!,
        versionDisplay: versionDisplay,
        topicCount: topicCount,
      );
    }

    // 2. 同步中状态
    if (_isSyncing) {
      return StatusBarState.syncing(
        modeLabel: _syncModeLabel,
        progress: _syncProgress,
        message: _syncMessage,
        versionDisplay: versionDisplay,
        topicCount: topicCount,
      );
    }

    // 3. 有更新可用
    if (_hasUpdate || _pendingLocalBackup != null) {
      return StatusBarState.hasUpdate(
        modeLabel: _syncModeLabel,
        versionDisplay: versionDisplay,
        topicCount: topicCount,
      );
    }

    // 4. 空闲状态
    return StatusBarState.idle(
      modeLabel: _syncModeLabel,
      versionDisplay: versionDisplay,
      topicCount: topicCount,
      todayTopicCount: todayTopicCount,
      hasNewVersion: _hasNewVersion,
    );
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
      if (_hasAnySyncSourceSelected) {
        _syncFromEnabledSources(force: true);
      } else {
        unawaited(_showSyncActionsSheet());
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

  Widget _buildTopicListSliver() {
    if (_topicIndex == null || _topicIndex!.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Text('没有找到话题')));
    }

    final assistantEntries = _topicIndex!.entries.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = assistantEntries[index];
          final assistantId = entry.key;
          final topics = entry.value;

          // 获取 Assistant 信息
          final assistantInfo =
              _assistantMap?[assistantId] ?? {'id': assistantId, 'name': '未命名助手'};

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 26),
              ),
            ),
            child: ExpansionTile(
              shape: const Border(), // Remove borders when expanded
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (assistantInfo['name'] as String?)?.substring(0, 1) ?? '?',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              title: Text(
                assistantInfo['name'] as String? ?? '未命名助手',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${topics.length} 个话题'),
              children: [
                // 显示所有话题（使用 Column 替代 ListView.builder 避免 shrinkWrap 问题）
                ...topics.map((topic) {
                  final topicName = topic['name'] as String? ?? '未命名话题';
                  final topicId = topic['id'] as String;
                  final messageCount = topic['messageCount'] as int? ?? 0;
                  final roundCount = topic['roundCount'] as int? ?? 0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    title: Text(topicName),
                    subtitle: Text('$roundCount 轮对话，$messageCount 条消息'),
                    trailing: const Icon(Icons.chevron_right, size: 16),
                    onTap: () => _openTopic(topicId, topicName),
                  );
                }),
              ],
            ),
          );
        },
        childCount: assistantEntries.length,
      ),
    );
  }

  /// 时间线视图（使用预计算数据，build 中零计算）
  Widget _buildTimelineListSliver() {
    // 【性能优化】如果正在计算或显示骨架屏
    if (_isComputingTimeline && _skeletonShownAt != null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildSkeletonCard(),
          childCount: 8,
        ),
      );
    }

    // 优先使用预计算的时间线
    if (_computedTimeline != null && _computedTimeline!.groups.isNotEmpty) {
      return _buildComputedTimelineSliver();
    }

    // 降级：使用旧逻辑（兼容）
    return _buildLegacyTimelineSliver();
  }

  /// 【性能优化】使用预计算数据构建时间线
  Widget _buildComputedTimelineSliver() {
    final flatItems = _computedTimeline!.flatItems;
    if (flatItems.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Text('没有找到话题')));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = flatItems[index];
          
          // 分组标题
          if (item is TimelineGroup) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                item.type.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }
          
          // 话题卡片（使用预计算的数据）
          if (item is TopicItem) {
            return TopicCard(
              title: item.name,
              date: item.timeDisplay,
              assistantName: item.assistantName,
              roundCount: item.roundCount,
              userPreview: item.userPreview,
              aiPreview: item.aiPreview,
              onTap: () => _openTopic(item.topicId, item.name),
            );
          }
          
          return const SizedBox.shrink();
        },
        childCount: flatItems.length,
      ),
    );
  }

  /// 骨架屏卡片
  Widget _buildSkeletonCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 降级：旧的时间线构建逻辑（兼容）
  Widget _buildLegacyTimelineSliver() {
    if (_topicIndex == null || _topicIndex!.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Text('没有找到话题')));
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
    final flatItems = <Widget>[];
    
    for (final group in groups) {
      final topics = groupedTopics[group];
      if (topics == null || topics.isEmpty) continue;
      
      // Header
      flatItems.add(
         Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              _getGroupTitle(group),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
      );
      
      // Items
      for (final topic in topics) {
        flatItems.add(_buildTopicCard(topic, group));
      }
      
      // Group spacing
      flatItems.add(const SizedBox(height: 16));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => flatItems[index],
        childCount: flatItems.length,
      ),
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
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(dt);
    final isThisYear = dt.year == now.year;
    
    return switch (group) {
      TimeGroup.today => timeStr,
      TimeGroup.yesterday => timeStr,
      TimeGroup.thisWeek => '${_getWeekdayName(dt.weekday)} $timeStr',
      TimeGroup.earlier => isThisYear 
          ? '${DateFormat('MM-dd').format(dt)} $timeStr'
          : '${DateFormat('yyyy-MM-dd').format(dt)} $timeStr',
    };
  }

  /// 获取星期名称
  String _getWeekdayName(int weekday) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday];
  }

  /// 构建话题卡片 (New Design)
  Widget _buildTopicCard(Map<String, dynamic> topic, TimeGroup group) {
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

    return TopicCard(
      title: topicName,
      date: timeDisplay,
      assistantName: assistantName,
      roundCount: roundCount,
      userPreview: userPreview,
      aiPreview: aiPreview,
      onTap: () => _openTopic(topicId, topicName),
    );
  }
  
  Future<void> _openTopic(String topicId, String topicName) async {
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
              color: (_autoWebDavEnabled)
                  ? (_hasValidWebDavConfig ? Colors.blue[50] : Colors.orange[50])
                  : (_autoLocalFolderEnabled)
                      ? (_hasValidLocalFolderConfig ? Colors.blue[50] : Colors.orange[50])
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              (_autoWebDavEnabled)
                  ? (_hasValidWebDavConfig ? Icons.cloud_queue : Icons.cloud_off)
                  : (_autoLocalFolderEnabled)
                      ? (_hasValidLocalFolderConfig ? Icons.folder_copy_outlined : Icons.folder_off_outlined)
                      : Icons.folder_open,
              size: 48,
              color: (_autoWebDavEnabled)
                  ? (_hasValidWebDavConfig ? Colors.blue[400] : Colors.orange[400])
                  : (_autoLocalFolderEnabled)
                      ? (_hasValidLocalFolderConfig ? Colors.blue[400] : Colors.orange[400])
                      : Colors.grey[500],
            ),
          ),

          const SizedBox(height: 24),

          // 标题
          Text(
            _hasAnySyncSourceSelected
                ? ((_autoWebDavEnabled && !_hasValidWebDavConfig) ||
                        (_autoLocalFolderEnabled && !_hasValidLocalFolderConfig))
                    ? '配置同步来源'
                    : '暂无数据'
                : '选择数据文件',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // 描述
          Text(
            _hasAnySyncSourceSelected
                ? ((_autoWebDavEnabled && !_hasValidWebDavConfig) ||
                        (_autoLocalFolderEnabled && !_hasValidLocalFolderConfig))
                    ? '先在设置页补全同步来源配置'
                    : '点击下方按钮同步并导入最新备份'
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
          if (_hasAnySyncSourceSelected) ...[
            if ((_autoWebDavEnabled && !_hasValidWebDavConfig) ||
                (_autoLocalFolderEnabled && !_hasValidLocalFolderConfig))
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
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
              )
            else
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _refreshData,
                icon: const Icon(Icons.cloud_sync),
                label: const Text('立即同步'),
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
                    '点击右上角“同步”导入文件',
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

          if (_autoWebDavEnabled && !_hasValidWebDavConfig) ...[
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
              title: '导入数据',
              description: '配置完成后，可在首页右上角“同步”手动导入；也可在设置里开启自动导入',
            ),
          ] else if (!_hasAnySyncSourceSelected) ...[
            _buildGuideStep(
              number: '1',
              title: '导出 Cherry Studio 数据',
              description: '在 Cherry Studio 中：设置 → 数据设置 → 导出菜单设置',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              number: '2',
              title: '导入到本应用',
              description: '首页右上角“同步” → 手动：选择文件导入',
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
                    '去设置选择并配置同步来源（WebDAV / 本地文件夹 / HTTP）',
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
