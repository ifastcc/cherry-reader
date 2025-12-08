import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/isar/prompt_template_entity.dart';
import 'isar_database.dart';

/// 模版管理服务
///
/// 管理用户偏好（System Prompt）和任务模版
class PromptTemplateService {
  static PromptTemplateService? _instance;
  static PromptTemplateService get instance {
    _instance ??= PromptTemplateService._();
    return _instance!;
  }

  PromptTemplateService._();

  final _uuid = const Uuid();
  final _db = IsarDatabase();

  // 缓存
  UserPreferenceEntity? _activePreference;
  List<TaskTemplateEntity>? _templates;

  // ============ 用户偏好管理 ============

  /// 获取当前激活的偏好
  Future<UserPreferenceEntity?> getActivePreference() async {
    if (_activePreference != null) return _activePreference;

    final isar = await _db.instance;
    _activePreference = await isar.userPreferenceEntitys
        .filter()
        .isActiveEqualTo(true)
        .findFirst();

    // 如果没有偏好，创建默认偏好
    if (_activePreference == null) {
      _activePreference = await _createDefaultPreference();
    }

    return _activePreference;
  }

  /// 获取所有偏好
  Future<List<UserPreferenceEntity>> getAllPreferences() async {
    final isar = await _db.instance;
    return isar.userPreferenceEntitys.where().sortByUpdatedAtDesc().findAll();
  }

  /// 创建偏好
  Future<UserPreferenceEntity> createPreference({
    required String name,
    required String systemPrompt,
    bool setActive = false,
  }) async {
    final isar = await _db.instance;

    // 如果设为激活，先取消其他偏好的激活状态
    if (setActive) {
      await _deactivateAllPreferences();
    }

    final entity = UserPreferenceEntity.create(
      preferenceId: _uuid.v4(),
      name: name,
      systemPrompt: systemPrompt,
      isActive: setActive,
    );

    await isar.writeTxn(() async {
      await isar.userPreferenceEntitys.put(entity);
    });

    if (setActive) {
      _activePreference = entity;
    }

    return entity;
  }

  /// 更新偏好
  Future<void> updatePreference(UserPreferenceEntity entity) async {
    final isar = await _db.instance;
    entity.updatedAt = DateTime.now().millisecondsSinceEpoch;

    await isar.writeTxn(() async {
      await isar.userPreferenceEntitys.put(entity);
    });

    if (entity.isActive) {
      _activePreference = entity;
    }
  }

  /// 设置激活偏好
  Future<void> setActivePreference(String preferenceId) async {
    final isar = await _db.instance;

    await _deactivateAllPreferences();

    final entity = await isar.userPreferenceEntitys
        .filter()
        .preferenceIdEqualTo(preferenceId)
        .findFirst();

    if (entity != null) {
      entity.isActive = true;
      entity.updatedAt = DateTime.now().millisecondsSinceEpoch;

      await isar.writeTxn(() async {
        await isar.userPreferenceEntitys.put(entity);
      });

      _activePreference = entity;
    }
  }

  /// 删除偏好（不能删除唯一的偏好）
  Future<bool> deletePreference(String preferenceId) async {
    final isar = await _db.instance;

    final count = await isar.userPreferenceEntitys.count();
    if (count <= 1) {
      return false; // 至少保留一个偏好
    }

    final entity = await isar.userPreferenceEntitys
        .filter()
        .preferenceIdEqualTo(preferenceId)
        .findFirst();

    if (entity != null) {
      final wasActive = entity.isActive;

      await isar.writeTxn(() async {
        await isar.userPreferenceEntitys.delete(entity.id);
      });

      // 如果删除的是激活的偏好，激活第一个
      if (wasActive) {
        final first =
            await isar.userPreferenceEntitys.where().findFirst();
        if (first != null) {
          await setActivePreference(first.preferenceId);
        }
      }

      if (_activePreference?.preferenceId == preferenceId) {
        _activePreference = null;
      }
    }

    return true;
  }

  Future<UserPreferenceEntity> _createDefaultPreference() async {
    final isar = await _db.instance;
    final entity = UserPreferenceEntity.createDefault(_uuid.v4());

    await isar.writeTxn(() async {
      await isar.userPreferenceEntitys.put(entity);
    });

    return entity;
  }

  Future<void> _deactivateAllPreferences() async {
    final isar = await _db.instance;
    final all = await isar.userPreferenceEntitys
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    await isar.writeTxn(() async {
      for (final entity in all) {
        entity.isActive = false;
        await isar.userPreferenceEntitys.put(entity);
      }
    });
  }

  // ============ 任务模版管理 ============

  /// 获取所有模版
  Future<List<TaskTemplateEntity>> getAllTemplates() async {
    if (_templates != null) return _templates!;

    final isar = await _db.instance;

    // 每次加载时检查并补充缺失的内置模板
    await _createBuiltInTemplates();

    _templates = await isar.taskTemplateEntitys
        .where()
        .sortByUpdatedAtDesc()
        .findAll();

    return _templates!;
  }

  /// 根据 ID 获取模版
  Future<TaskTemplateEntity?> getTemplate(String templateId) async {
    final isar = await _db.instance;
    return isar.taskTemplateEntitys
        .filter()
        .templateIdEqualTo(templateId)
        .findFirst();
  }

  /// 创建模版
  Future<TaskTemplateEntity> createTemplate({
    required String name,
    required String content,
    String? description,
  }) async {
    final isar = await _db.instance;

    final entity = TaskTemplateEntity.create(
      templateId: _uuid.v4(),
      name: name,
      content: content,
      description: description,
      isBuiltIn: false,
    );

    await isar.writeTxn(() async {
      await isar.taskTemplateEntitys.put(entity);
    });

    _templates = null; // 清除缓存

    return entity;
  }

  /// 更新模版
  Future<void> updateTemplate(TaskTemplateEntity entity) async {
    final isar = await _db.instance;
    entity.updatedAt = DateTime.now().millisecondsSinceEpoch;

    await isar.writeTxn(() async {
      await isar.taskTemplateEntitys.put(entity);
    });

    _templates = null; // 清除缓存
  }

  /// 删除模版（不能删除内置模版）
  Future<bool> deleteTemplate(String templateId) async {
    final isar = await _db.instance;

    final entity = await isar.taskTemplateEntitys
        .filter()
        .templateIdEqualTo(templateId)
        .findFirst();

    if (entity == null || entity.isBuiltIn) {
      return false;
    }

    await isar.writeTxn(() async {
      await isar.taskTemplateEntitys.delete(entity.id);
    });

    _templates = null; // 清除缓存

    return true;
  }

  /// 增加模版使用次数
  Future<void> incrementUsage(String templateId) async {
    final isar = await _db.instance;

    final entity = await isar.taskTemplateEntitys
        .filter()
        .templateIdEqualTo(templateId)
        .findFirst();

    if (entity != null) {
      entity.usageCount++;
      entity.updatedAt = DateTime.now().millisecondsSinceEpoch;

      await isar.writeTxn(() async {
        await isar.taskTemplateEntitys.put(entity);
      });

      _templates = null; // 清除缓存
    }
  }

  Future<void> _createBuiltInTemplates() async {
    final isar = await _db.instance;

    // 定义所有内置模板及其名称
    final builtInTemplates = {
      '元分析': () => TaskTemplateEntity.createMetaAnalysis(_uuid.v4()),
      '视角': () => TaskTemplateEntity.createPerspective(_uuid.v4()),
      '内容总结': () => TaskTemplateEntity.createSummary(_uuid.v4()),
      '翻译': () => TaskTemplateEntity.createTranslation(_uuid.v4()),
    };

    // 获取现有模板名称
    final existing = await isar.taskTemplateEntitys.where().findAll();
    final existingNames = existing.map((t) => t.name).toSet();

    // 找出缺失的内置模板
    final missingTemplates = <TaskTemplateEntity>[];
    for (final entry in builtInTemplates.entries) {
      if (!existingNames.contains(entry.key)) {
        missingTemplates.add(entry.value());
      }
    }

    // 添加缺失的模板
    if (missingTemplates.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.taskTemplateEntitys.putAll(missingTemplates);
      });
    }
  }

  /// 清除缓存
  void clearCache() {
    _activePreference = null;
    _templates = null;
  }
}
