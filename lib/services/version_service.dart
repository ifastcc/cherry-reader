import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/domain/data_version.dart';
import '../models/isar/version_entity.dart';
import '../models/isar/assistant_entity.dart';
import '../models/isar/topic_entity.dart';
import '../models/isar/message_entity.dart';
import '../models/isar/message_block_entity.dart';
import '../models/isar/file_entity.dart';
import '../models/isar/topic_embedding_entity.dart';
import 'isar_database.dart';

/// 版本管理服务
///
/// 职责：
/// 1. 管理多个版本的 Isar 数据库实例
/// 2. 版本创建、激活、删除
/// 3. 版本锁定功能
/// 4. 旧版本清理
///
/// 架构：
/// - 主数据库 (cherry_viewer.isar)：存储用户数据（标注、分析）和版本元数据
/// - 版本数据库 (versions/v-xxx/imported.isar)：存储导入的 Cherry Studio 数据
class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  static VersionService get instance => _instance;

  VersionService._internal();

  /// 主数据库（存储用户数据和版本元数据）
  final IsarDatabase _mainDb = IsarDatabase();

  /// 当前活跃版本的 Isar 实例
  Isar? _activeImportIsar;

  /// 当前活跃版本 ID
  String? _activeVersionId;

  /// 是否锁定版本（锁定后不自动切换到新版本）
  bool _isVersionLocked = false;

  /// 版本目录基础路径
  String? _versionsBasePath;

  /// 最大保留版本数
  static const int maxVersions = 3;

  /// SharedPreferences keys
  static const String _activeVersionKey = 'active_version_id';
  static const String _versionLockedKey = 'version_locked';

  /// 导入数据的 Schema 列表
  static final List<CollectionSchema> _importSchemas = [
    AssistantEntitySchema,
    TopicEntitySchema,
    MessageEntitySchema,
    MessageBlockEntitySchema,
    FileEntitySchema,
    TopicEmbeddingEntitySchema,
  ];

  // ============ 初始化 ============

  /// 初始化版本服务
  ///
  /// 必须在使用其他方法前调用
  Future<void> init() async {
    // 获取版本目录基础路径
    final dir = await getApplicationDocumentsDirectory();
    _versionsBasePath = '${dir.path}/versions';

    // 确保版本目录存在
    await Directory(_versionsBasePath!).create(recursive: true);

    // 加载锁定状态
    final prefs = await SharedPreferences.getInstance();
    _isVersionLocked = prefs.getBool(_versionLockedKey) ?? false;

    // 尝试加载上次活跃的版本
    await _loadActiveVersion();

    debugPrint('✅ VersionService 初始化完成');
    debugPrint('   活跃版本: $_activeVersionId');
    debugPrint('   锁定状态: $_isVersionLocked');
  }

  /// 加载上次活跃的版本
  Future<void> _loadActiveVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersionId = prefs.getString(_activeVersionKey);

    if (savedVersionId != null) {
      // 检查该版本是否存在且可用
      final version = await getVersion(savedVersionId);
      if (version != null &&
          (version.status == VersionStatus.ready ||
              version.status == VersionStatus.active)) {
        await _openVersionIsar(version);
        _activeVersionId = savedVersionId;
        return;
      }
    }

    // 尝试加载最新的可用版本
    final versions = await listVersions();
    final readyVersions = versions
        .where((v) =>
            v.status == VersionStatus.ready || v.status == VersionStatus.active)
        .toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));

    if (readyVersions.isNotEmpty) {
      await _openVersionIsar(readyVersions.first);
      _activeVersionId = readyVersions.first.versionId;
      await prefs.setString(_activeVersionKey, _activeVersionId!);
    }
  }

  // ============ 公开属性 ============

  /// 获取当前活跃版本的 Isar 实例
  Isar? get activeImportIsar => _activeImportIsar;

  /// 获取当前活跃版本 ID
  String? get activeVersionId => _activeVersionId;

  /// 是否有活跃版本
  bool get hasActiveVersion => _activeImportIsar != null;

  /// 版本是否锁定
  bool get isVersionLocked => _isVersionLocked;

  // ============ 版本管理 ============

  /// 获取所有版本列表
  Future<List<DataVersion>> listVersions() async {
    final isar = await _mainDb.instance;
    final entities = await isar.versionEntitys
        .where()
        .sortByImportedAtMsDesc()
        .findAll();

    return entities.map((e) => e.toDataVersion()).toList();
  }

  /// 获取指定版本
  Future<DataVersion?> getVersion(String versionId) async {
    final isar = await _mainDb.instance;
    final entity = await isar.versionEntitys
        .filter()
        .versionIdEqualTo(versionId)
        .findFirst();

    return entity?.toDataVersion();
  }

  /// 获取当前活跃版本信息
  Future<DataVersion?> getActiveVersion() async {
    if (_activeVersionId == null) return null;
    return getVersion(_activeVersionId!);
  }

  /// 创建新版本（用于后台导入）
  ///
  /// 返回新版本的信息和对应的 Isar 实例
  Future<(DataVersion, Isar)> createVersion({
    required String sourceFileName,
    required DateTime sourceModifiedAt,
  }) async {
    final versionId = _generateVersionId();
    final dirPath = '$_versionsBasePath/$versionId';

    // 创建版本目录
    await Directory(dirPath).create(recursive: true);

    // 创建新的 Isar 实例
    final isar = await Isar.open(
      _importSchemas,
      directory: dirPath,
      name: 'imported',
      inspector: kDebugMode,
    );

    // 创建版本信息
    final version = DataVersion(
      versionId: versionId,
      sourceFileName: sourceFileName,
      importedAt: DateTime.now(),
      sourceModifiedAt: sourceModifiedAt,
      isarPath: '$dirPath/imported.isar',
      status: VersionStatus.importing,
    );

    // 保存到主数据库
    await _saveVersionMetadata(version);

    debugPrint('✅ 创建新版本: $versionId');
    return (version, isar);
  }

  /// 标记版本为就绪
  Future<void> markVersionReady(
    String versionId, {
    required int topicCount,
    required int messageCount,
    int? fileSizeBytes,
  }) async {
    final version = await getVersion(versionId);
    if (version == null) {
      throw Exception('版本不存在: $versionId');
    }

    // 计算文件大小
    int actualSize = fileSizeBytes ?? 0;
    if (actualSize == 0) {
      final file = File(version.isarPath);
      if (await file.exists()) {
        actualSize = await file.length();
      }
    }

    final updatedVersion = version.copyWith(
      topicCount: topicCount,
      messageCount: messageCount,
      fileSizeBytes: actualSize,
      status: VersionStatus.ready,
    );

    await _saveVersionMetadata(updatedVersion);
    debugPrint('✅ 版本就绪: $versionId (${topicCount}话题, ${messageCount}消息)');
  }

  /// 标记版本为失败
  Future<void> markVersionFailed(String versionId) async {
    final version = await getVersion(versionId);
    if (version == null) return;

    final updatedVersion = version.copyWith(status: VersionStatus.failed);
    await _saveVersionMetadata(updatedVersion);
    debugPrint('❌ 版本导入失败: $versionId');
  }

  /// 激活指定版本
  ///
  /// 切换到指定版本的数据
  Future<bool> activateVersion(String versionId, {bool force = false}) async {
    // 检查是否锁定
    if (_isVersionLocked && !force) {
      debugPrint('⚠️ 版本已锁定，跳过自动切换');
      return false;
    }

    final version = await getVersion(versionId);
    if (version == null) {
      debugPrint('❌ 版本不存在: $versionId');
      return false;
    }

    if (version.status != VersionStatus.ready &&
        version.status != VersionStatus.active) {
      debugPrint('❌ 版本不可用: $versionId (状态: ${version.status})');
      return false;
    }

    // 更新旧版本状态
    if (_activeVersionId != null && _activeVersionId != versionId) {
      final oldVersion = await getVersion(_activeVersionId!);
      if (oldVersion != null && oldVersion.status == VersionStatus.active) {
        await _saveVersionMetadata(
            oldVersion.copyWith(status: VersionStatus.ready));
      }
    }

    // 关闭当前活跃的导入数据库
    if (_activeImportIsar != null && _activeImportIsar!.isOpen) {
      await _activeImportIsar!.close();
      _activeImportIsar = null;
    }

    // 打开新版本
    await _openVersionIsar(version);
    _activeVersionId = versionId;

    // 更新版本状态为活跃
    await _saveVersionMetadata(version.copyWith(status: VersionStatus.active));

    // 保存活跃版本 ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeVersionKey, versionId);

    debugPrint('✅ 已切换到版本: $versionId');

    // 清理旧版本
    await cleanupOldVersions();

    return true;
  }

  /// 锁定/解锁版本
  Future<void> setVersionLocked(bool locked) async {
    _isVersionLocked = locked;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_versionLockedKey, locked);
    debugPrint('🔒 版本锁定状态: $locked');
  }

  /// 锁定/解锁指定版本
  Future<void> setVersionEntityLocked(String versionId, bool locked) async {
    final version = await getVersion(versionId);
    if (version == null) return;

    await _saveVersionMetadata(version.copyWith(isLocked: locked));
    debugPrint('🔒 版本 $versionId 锁定状态: $locked');
  }

  /// 删除指定版本
  Future<void> deleteVersion(String versionId) async {
    if (versionId == _activeVersionId) {
      throw Exception('无法删除当前活跃版本');
    }

    final version = await getVersion(versionId);
    if (version == null) return;

    if (version.isLocked) {
      throw Exception('无法删除已锁定的版本');
    }

    // 删除版本目录
    final dirPath = version.isarPath.replaceAll('/imported.isar', '');
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // 删除元数据
    await _deleteVersionMetadata(versionId);
    debugPrint('🗑️ 已删除版本: $versionId');
  }

  /// 清理旧版本
  ///
  /// 保留最近 [maxVersions] 个版本
  Future<void> cleanupOldVersions() async {
    final versions = await listVersions();
    final readyVersions = versions
        .where((v) =>
            v.status == VersionStatus.ready || v.status == VersionStatus.active)
        .where((v) => !v.isLocked) // 不删除锁定的版本
        .toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));

    // 删除超出限制的旧版本
    if (readyVersions.length > maxVersions) {
      for (var i = maxVersions; i < readyVersions.length; i++) {
        final version = readyVersions[i];
        if (version.versionId != _activeVersionId) {
          try {
            await deleteVersion(version.versionId);
          } catch (e) {
            debugPrint('⚠️ 清理版本失败: ${version.versionId}, $e');
          }
        }
      }
    }

    // 清理失败的版本
    final failedVersions =
        versions.where((v) => v.status == VersionStatus.failed).toList();
    for (final version in failedVersions) {
      try {
        await deleteVersion(version.versionId);
      } catch (e) {
        debugPrint('⚠️ 清理失败版本: ${version.versionId}, $e');
      }
    }

    // 清理导入中但超过 1 小时的版本（可能是崩溃遗留）
    final importingVersions = versions
        .where((v) => v.status == VersionStatus.importing)
        .where((v) =>
            DateTime.now().difference(v.importedAt) > const Duration(hours: 1))
        .toList();
    for (final version in importingVersions) {
      try {
        await deleteVersion(version.versionId);
      } catch (e) {
        debugPrint('⚠️ 清理超时版本: ${version.versionId}, $e');
      }
    }
  }

  /// 紧急清理（存储空间不足时）
  ///
  /// 只保留当前活跃版本
  Future<void> emergencyCleanup() async {
    final versions = await listVersions();

    for (final version in versions) {
      if (version.versionId != _activeVersionId && !version.isLocked) {
        try {
          await deleteVersion(version.versionId);
        } catch (e) {
          debugPrint('⚠️ 紧急清理失败: ${version.versionId}, $e');
        }
      }
    }
  }

  // ============ 崩溃恢复 ============

  /// 从崩溃中恢复
  ///
  /// 在 App 启动时调用，清理未完成的导入
  Future<void> recoverFromCrash() async {
    final versions = await listVersions();

    // 删除状态为 importing 的版本
    final importingVersions =
        versions.where((v) => v.status == VersionStatus.importing);
    for (final version in importingVersions) {
      debugPrint('🔧 清理未完成的导入: ${version.versionId}');
      try {
        final dirPath = version.isarPath.replaceAll('/imported.isar', '');
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        await _deleteVersionMetadata(version.versionId);
      } catch (e) {
        debugPrint('⚠️ 清理失败: $e');
      }
    }

    // 确保有活跃版本
    if (_activeVersionId == null || _activeImportIsar == null) {
      await _loadActiveVersion();
    }
  }

  // ============ 私有方法 ============

  /// 生成版本 ID
  String _generateVersionId() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'v-$dateStr-$timeStr';
  }

  /// 打开版本的 Isar 实例
  Future<void> _openVersionIsar(DataVersion version) async {
    final dirPath = version.isarPath.replaceAll('/imported.isar', '');

    // 确保目录存在
    if (!await Directory(dirPath).exists()) {
      debugPrint('⚠️ 版本目录不存在: $dirPath');
      return;
    }

    _activeImportIsar = await Isar.open(
      _importSchemas,
      directory: dirPath,
      name: 'imported',
      inspector: kDebugMode,
    );
  }

  /// 保存版本元数据
  Future<void> _saveVersionMetadata(DataVersion version) async {
    final isar = await _mainDb.instance;
    final entity = VersionEntity.fromDataVersion(version);

    await isar.writeTxn(() async {
      await isar.versionEntitys.putByIndex('versionId', entity);
    });
  }

  /// 删除版本元数据
  Future<void> _deleteVersionMetadata(String versionId) async {
    final isar = await _mainDb.instance;
    await isar.writeTxn(() async {
      await isar.versionEntitys
          .filter()
          .versionIdEqualTo(versionId)
          .deleteAll();
    });
  }

  /// 关闭服务（应用退出时调用）
  Future<void> close() async {
    if (_activeImportIsar != null && _activeImportIsar!.isOpen) {
      await _activeImportIsar!.close();
      _activeImportIsar = null;
    }
    debugPrint('🔒 VersionService 已关闭');
  }
}
