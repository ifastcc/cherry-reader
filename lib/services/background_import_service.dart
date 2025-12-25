import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import 'cherry_extractor.dart';
import 'insight_service.dart';
import 'version_service.dart';
import 'versioned_data_import_service.dart';

/// 导入阶段
enum ImportPhase {
  /// 空闲
  idle,

  /// 下载中
  downloading,

  /// 解析中
  parsing,

  /// 导入中
  importing,

  /// 已完成
  completed,

  /// 失败
  failed,
}

/// 导入状态
class ImportStatus {
  final ImportPhase phase;
  final String? message;
  final double? progress;
  final String? versionId;
  final String? error;

  const ImportStatus._({
    required this.phase,
    this.message,
    this.progress,
    this.versionId,
    this.error,
  });

  factory ImportStatus.idle() => const ImportStatus._(phase: ImportPhase.idle);

  factory ImportStatus.downloading(String message, {double? progress}) =>
      ImportStatus._(
        phase: ImportPhase.downloading,
        message: message,
        progress: progress,
      );

  factory ImportStatus.parsing(String message) =>
      ImportStatus._(phase: ImportPhase.parsing, message: message);

  factory ImportStatus.importing(String message, {double? progress}) =>
      ImportStatus._(
        phase: ImportPhase.importing,
        message: message,
        progress: progress,
      );

  factory ImportStatus.completed(String versionId) => ImportStatus._(
        phase: ImportPhase.completed,
        versionId: versionId,
      );

  factory ImportStatus.failed(String error) =>
      ImportStatus._(phase: ImportPhase.failed, error: error);

  bool get isIdle => phase == ImportPhase.idle;
  bool get isInProgress =>
      phase == ImportPhase.downloading ||
      phase == ImportPhase.parsing ||
      phase == ImportPhase.importing;
  bool get isCompleted => phase == ImportPhase.completed;
  bool get isFailed => phase == ImportPhase.failed;
}

/// 后台导入服务
///
/// 职责：
/// 1. 后台静默下载和导入备份文件
/// 2. 使用 VersionService 创建新版本
/// 3. 通过 Stream 通知 UI 进度和状态
/// 4. 导入完成后自动激活新版本（如果未锁定）
class BackgroundImportService {
  static final BackgroundImportService _instance =
      BackgroundImportService._internal();
  factory BackgroundImportService() => _instance;
  static BackgroundImportService get instance => _instance;

  BackgroundImportService._internal();

  /// 导入状态流控制器
  final _statusController = StreamController<ImportStatus>.broadcast();

  /// 当前导入状态
  ImportStatus _currentStatus = ImportStatus.idle();

  /// 是否正在导入
  bool _isImporting = false;

  /// 正在导入的版本 ID
  String? _importingVersionId;

  /// 正在使用的 Isar 实例
  Isar? _importIsar;

  // ============ 公开接口 ============

  /// 导入状态流（供 UI 监听）
  Stream<ImportStatus> get statusStream => _statusController.stream;

  /// 当前状态
  ImportStatus get currentStatus => _currentStatus;

  /// 是否正在导入
  bool get isImporting => _isImporting;

  /// 后台导入
  ///
  /// 不阻塞，立即返回，通过 [statusStream] 通知进度
  ///
  /// [extractor] 已加载的 CherryExtractor
  /// [sourceFileName] 来源文件名
  /// [sourceModifiedAt] 源文件修改时间
  Future<void> importInBackground({
    required CherryExtractor extractor,
    required String sourceFileName,
    required DateTime sourceModifiedAt,
  }) async {
    if (_isImporting) {
      debugPrint('⚠️ 已有导入任务在进行中');
      return;
    }

    _isImporting = true;
    _updateStatus(ImportStatus.importing('准备导入...'));

    try {
      // 1. 创建新版本
      _updateStatus(ImportStatus.importing('创建新版本...'));
      final (version, isar) = await VersionService.instance.createVersion(
        sourceFileName: sourceFileName,
        sourceModifiedAt: sourceModifiedAt,
      );
      _importingVersionId = version.versionId;
      _importIsar = isar;

      debugPrint('📦 开始后台导入: ${version.versionId}');

      // 2. 导入数据到新版本
      final importService = VersionedDataImportService(isar, extractor);
      final result = await importService.importFromExtractor(
        onProgress: (progress, message) {
          _updateStatus(ImportStatus.importing(message, progress: progress));
        },
      );

      if (!result.success) {
        throw Exception(result.error ?? '导入失败');
      }

      // 3. 标记版本就绪
      await VersionService.instance.markVersionReady(
        version.versionId,
        topicCount: result.importedTopics,
        messageCount: result.importedMessages,
      );

      // 4. 激活新版本（如果未锁定）
      final activated =
          await VersionService.instance.activateVersion(version.versionId);

      if (activated) {
        debugPrint('✅ 后台导入完成并已激活: ${version.versionId}');
      } else {
        debugPrint('✅ 后台导入完成（版本已锁定，未激活）: ${version.versionId}');
      }

      // 5. 【性能优化】后台预加载 AI 洞察数据
      _triggerPreload();

      _updateStatus(ImportStatus.completed(version.versionId));
    } catch (e) {
      debugPrint('❌ 后台导入失败: $e');

      // 标记版本失败
      if (_importingVersionId != null) {
        await VersionService.instance.markVersionFailed(_importingVersionId!);
      }

      // 关闭 Isar
      if (_importIsar != null && _importIsar!.isOpen) {
        await _importIsar!.close();
      }

      _updateStatus(ImportStatus.failed(e.toString()));
    } finally {
      _isImporting = false;
      _importingVersionId = null;
      _importIsar = null;
    }
  }

  /// 取消正在进行的导入
  Future<void> cancelImport() async {
    if (!_isImporting) return;

    debugPrint('⚠️ 取消导入: $_importingVersionId');

    // 关闭 Isar
    if (_importIsar != null && _importIsar!.isOpen) {
      await _importIsar!.close();
    }

    // 标记版本失败
    if (_importingVersionId != null) {
      await VersionService.instance.markVersionFailed(_importingVersionId!);
    }

    _isImporting = false;
    _importingVersionId = null;
    _importIsar = null;

    _updateStatus(ImportStatus.idle());
  }

  /// 清除完成/失败状态，恢复为 idle
  void clearStatus() {
    if (_currentStatus.isCompleted || _currentStatus.isFailed) {
      _updateStatus(ImportStatus.idle());
    }
  }

  /// 关闭服务
  Future<void> close() async {
    await cancelImport();
    await _statusController.close();
  }

  // ============ 私有方法 ============

  void _updateStatus(ImportStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// 触发后台预加载（不阻塞导入流程）
  void _triggerPreload() {
    // 先失效缓存
    InsightService.instance.invalidateCache();

    // 异步预加载，不等待完成
    Future.microtask(() async {
      try {
        await InsightService.instance.preloadQueries();
      } catch (e) {
        debugPrint('⚠️ 预加载失败（不影响导入）: $e');
      }
    });
  }
}
