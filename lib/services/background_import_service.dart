import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import 'cherry_extractor.dart';
import 'insight_service.dart';
import 'version_service.dart';
import 'versioned_data_import_service.dart';
import '../models/domain/data_version.dart';

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
      // 0. 【去重检查】检查是否已存在相同的版本
      // 如果存在且状态正常，直接复用，不创建新版本
      final existingVersions = await VersionService.instance.listVersions();
      // 容差 2 秒，避免文件系统时间精度差异
      final existing = existingVersions.where((v) =>
          v.sourceFileName == sourceFileName &&
          v.sourceModifiedAt.difference(sourceModifiedAt).abs().inSeconds < 2 &&
          (v.status == VersionStatus.ready || v.status == VersionStatus.active));

      if (existing.isNotEmpty) {
        final targetVersion = existing.first;
        
        // 【健壮性检查】确保目标版本的数据库文件有效
        final dbFile = File(targetVersion.isarPath);
        bool isValid = await dbFile.exists();
        if (isValid) {
          final size = await dbFile.length();
          if (size < 1024) { // 小于 1KB 可能是空库或头部损坏
            isValid = false;
          }
        }
        
        if (isValid) {
          debugPrint('♻️ 发现已存在的版本，跳过导入直接复用: ${targetVersion.versionId}');
          
          _updateStatus(ImportStatus.importing('正在切换到已存在的版本...'));
          
          // 直接尝试激活
          final activated = await VersionService.instance.activateVersion(
            targetVersion.versionId,
            force: false, // 尊重锁定设置
          );
          
          if (activated) {
            _updateStatus(ImportStatus.completed(targetVersion.versionId));
          } else {
            // 如果激活失败（如因为锁定），也视为完成
            _updateStatus(ImportStatus.completed(targetVersion.versionId));
          }
          return;
        } else {
           debugPrint('⚠️ 发现已存在版本 ${targetVersion.versionId} 但数据库文件无效，将重新导入');
           // 这里可以选择是否清理旧版本，但为了安全，直接创建新版本（ID是基于时间的，不会冲突）
        }
      }

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

      // 【关键修复】激活前必须关闭当前的 Isar 实例，否则会因为文件锁导致 "Instance has already been opened"
      if (_importIsar != null && _importIsar!.isOpen) {
        await _importIsar!.close();
        _importIsar = null;
      }

      // 【关键修复】重命名数据库文件
      // CreateVersion 使用 name='importing_$versionId'，生成 'importing_$versionId.isar'
      // ActivateVersion 使用 name='imported'，期望 'imported.isar'
      // 所以必须重命名文件
      try {
        final versionDir = Directory(version.isarPath).parent;
        final importName = 'importing_${version.versionId}';
        final targetName = 'imported';
        
        final importFile = File('${versionDir.path}/$importName.isar');
        final importLockFile = File('${versionDir.path}/$importName.isar.lock');
        
        final targetFile = File('${versionDir.path}/$targetName.isar');
        final targetLockFile = File('${versionDir.path}/$targetName.isar.lock');
        
        if (await importFile.exists()) {
          // 如果目标文件已存在（可能有旧的残留），先删除
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
           await importFile.rename(targetFile.path);
        }
        
        // 锁文件处理：不要重命名，直接删除。
        // MDBX 的锁文件包含了进程/线程信息，直接重命名可能导致新打开的实例认为数据库被锁定
        // 让新的 Isar.open 自动创建新的锁文件
        if (await importLockFile.exists()) {
          await importLockFile.delete();
        }
        if (await targetLockFile.exists()) {
            await targetLockFile.delete();
        }
        
        debugPrint('✅ 数据库文件重命名完成');
      } catch (e) {
        debugPrint('❌ 数据库文件重命名失败: $e');
         // 如果重命名失败，可能无法正确加载数据，但我们继续尝试激活，或者抛出异常
      }

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
      // 增加安全延迟，确保 VersionService 的清理和 TopicIndexService 的重建完全结束
      // 避免 Isar 在高并发读写下出现 MdbxError
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        await InsightService.instance.preloadQueries();
      } catch (e) {
        debugPrint('⚠️ 预加载失败（不影响导入）: $e');
      }
    });
  }
}
