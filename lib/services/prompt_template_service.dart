import 'package:uuid/uuid.dart';
import '../models/isar/prompt_template_entity.dart';
import 'app_db.dart';

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
  final _db = AppDb();

  // 缓存
  UserPreferenceEntity? _activePreference;
  List<TaskTemplateEntity>? _templates;

  // ============ 用户偏好管理 ============

  /// 获取当前激活的偏好
  Future<UserPreferenceEntity?> getActivePreference() async {
    if (_activePreference != null) return _activePreference;
    _activePreference = await _db.getActivePreference();

    // 如果没有偏好，创建默认偏好
    if (_activePreference == null) {
      _activePreference = await _createDefaultPreference();
    }

    return _activePreference;
  }

  /// 获取所有偏好
  Future<List<UserPreferenceEntity>> getAllPreferences() async {
    return _db.getAllPreferences();
  }

  /// 创建偏好
  Future<UserPreferenceEntity> createPreference({
    required String name,
    required String systemPrompt,
    bool setActive = false,
  }) async {
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

    await _db.upsertPreference(entity);

    if (setActive) {
      _activePreference = entity;
    }

    return entity;
  }

  /// 更新偏好
  Future<void> updatePreference(UserPreferenceEntity entity) async {
    entity.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.upsertPreference(entity);

    if (entity.isActive) {
      _activePreference = entity;
    }
  }

  /// 设置激活偏好
  Future<void> setActivePreference(String preferenceId) async {
    await _deactivateAllPreferences();
    final all = await _db.getAllPreferences();
    final entity = all.cast<UserPreferenceEntity?>().firstWhere(
          (e) => e?.preferenceId == preferenceId,
          orElse: () => null,
        );

    if (entity != null) {
      entity.isActive = true;
      entity.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _db.upsertPreference(entity);

      _activePreference = entity;
    }
  }

  /// 获取默认模板
  Future<TaskTemplateEntity?> getDefaultTemplate() async {
    final preference = await getActivePreference();
    if (preference?.defaultTemplateId == null) return null;

    return getTemplate(preference!.defaultTemplateId!);
  }

  /// 设置默认模板
  ///
  /// [templateId] 模板 ID，传 null 表示取消默认模板
  Future<void> setDefaultTemplate(String? templateId) async {
    final preference = await getActivePreference();
    if (preference == null) return;
    preference.defaultTemplateId = templateId;
    preference.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.upsertPreference(preference);

    _activePreference = preference;
  }

  /// 删除偏好（不能删除唯一的偏好）
  Future<bool> deletePreference(String preferenceId) async {
    final count = await _db.getPreferenceCount();
    if (count <= 1) {
      return false; // 至少保留一个偏好
    }
    final all = await _db.getAllPreferences();
    final entity = all.cast<UserPreferenceEntity?>().firstWhere(
          (e) => e?.preferenceId == preferenceId,
          orElse: () => null,
        );

    if (entity != null) {
      final wasActive = entity.isActive;
      await _db.deletePreference(preferenceId);

      // 如果删除的是激活的偏好，激活第一个
      if (wasActive) {
        final prefs = await _db.getAllPreferences();
        final first = prefs.isNotEmpty ? prefs.first : null;
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
    final entity = UserPreferenceEntity.createDefault(_uuid.v4());
    await _db.upsertPreference(entity);
    return entity;
  }

  Future<void> _deactivateAllPreferences() async {
    await _db.deactivateAllPreferences();
    _activePreference = null;
  }

  // ============ 任务模版管理 ============

  /// 获取所有模版
  Future<List<TaskTemplateEntity>> getAllTemplates() async {
    if (_templates != null) return _templates!;

    // 每次加载时检查并补充缺失的内置模板
    await _createBuiltInTemplates();
    _templates = await _db.getAllTemplates();

    return _templates!;
  }

  /// 根据 ID 获取模版
  Future<TaskTemplateEntity?> getTemplate(String templateId) async {
    return _db.getTemplate(templateId);
  }

  /// 创建模版
  Future<TaskTemplateEntity> createTemplate({
    required String name,
    required String content,
    String? description,
  }) async {
    final entity = TaskTemplateEntity.create(
      templateId: _uuid.v4(),
      name: name,
      content: content,
      description: description,
      isBuiltIn: false,
    );
    await _db.upsertTemplate(entity);

    _templates = null; // 清除缓存

    return entity;
  }

  /// 更新模版
  Future<void> updateTemplate(TaskTemplateEntity entity) async {
    entity.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.upsertTemplate(entity);

    _templates = null; // 清除缓存
  }

  /// 删除模版（不能删除内置模版）
  Future<bool> deleteTemplate(String templateId) async {
    final entity = await _db.getTemplate(templateId);

    if (entity == null || entity.isBuiltIn) {
      return false;
    }
    await _db.deleteTemplate(templateId);

    _templates = null; // 清除缓存

    return true;
  }

  /// 增加模版使用次数
  Future<void> incrementUsage(String templateId) async {
    await _db.incrementTemplateUsage(templateId);
    _templates = null;
  }

  Future<void> _createBuiltInTemplates() async {
    // 定义所有内置模板及其名称
    final builtInTemplates = {
      '视角': () => TaskTemplateEntity.createPerspective(_uuid.v4()),
      '元分析': () => TaskTemplateEntity.createMetaAnalysis(_uuid.v4()),
      '深度分析': () => TaskTemplateEntity.createDeepAnalysis(_uuid.v4()),
    };

    // 获取现有模板名称
    final existing = await _db.getAllTemplates();
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
      for (final t in missingTemplates) {
        await _db.upsertTemplate(t);
      }
    }
  }

  /// 清除缓存
  void clearCache() {
    _activePreference = null;
    _templates = null;
  }
}
