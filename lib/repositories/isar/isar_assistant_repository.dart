import 'package:isar_community/isar.dart';
import '../../models/domain/assistant_model.dart';
import '../../models/isar/assistant_entity.dart';
import '../../services/isar_database.dart';
import '../i_assistant_repository.dart';

/// 助手仓库 Isar 实现
class IsarAssistantRepository implements IAssistantRepository {
  final IsarDatabase _db;

  IsarAssistantRepository(this._db);

  // ========== 转换方法 ==========

  AssistantModel _toModel(AssistantEntity entity) {
    return AssistantModel(
      assistantId: entity.assistantId,
      name: entity.name,
      description: entity.description,
      avatar: entity.avatar,
      prompt: entity.prompt,
      topicCount: entity.topicCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AssistantEntity _toEntity(AssistantModel model) {
    return AssistantEntity.fromData(
      assistantId: model.assistantId,
      name: model.name,
      description: model.description,
      avatar: model.avatar,
      prompt: model.prompt,
      topicCount: model.topicCount,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  // ========== 接口实现 ==========

  @override
  Future<List<AssistantModel>> getAllAssistants() async {
    try {
      final isar = await _db.instance;
      final entities = await isar.assistantEntitys
          .where()
          .sortByName()
          .findAll();
      return entities.map(_toModel).toList();
    } on IsarError catch (e) {
      print('❌ 获取所有助手失败: $e');
      return [];
    }
  }

  @override
  Future<AssistantModel?> getAssistant(String assistantId) async {
    try {
      final isar = await _db.instance;
      final entity = await isar.assistantEntitys
          .filter()
          .assistantIdEqualTo(assistantId)
          .findFirst();
      return entity != null ? _toModel(entity) : null;
    } on IsarError catch (e) {
      print('❌ 获取助手失败: $e');
      return null;
    }
  }

  @override
  Future<int> getAssistantCount() async {
    try {
      final isar = await _db.instance;
      return isar.assistantEntitys.count();
    } on IsarError catch (e) {
      print('❌ 获取助手数量失败: $e');
      return 0;
    }
  }

  @override
  Future<void> saveAssistant(AssistantModel assistant) async {
    try {
      final isar = await _db.instance;
      final entity = _toEntity(assistant);
      await isar.writeTxn(() async {
        await isar.assistantEntitys.put(entity);
      });
    } on IsarError catch (e) {
      print('❌ 保存助手失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveAssistants(List<AssistantModel> assistants) async {
    if (assistants.isEmpty) return;

    try {
      final isar = await _db.instance;
      final entities = assistants.map(_toEntity).toList();
      await isar.writeTxn(() async {
        await isar.assistantEntitys.putAll(entities);
      });
    } on IsarError catch (e) {
      print('❌ 批量保存助手失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAssistant(String assistantId) async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.assistantEntitys
            .filter()
            .assistantIdEqualTo(assistantId)
            .deleteFirst();
      });
    } on IsarError catch (e) {
      print('❌ 删除助手失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAllAssistants() async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.assistantEntitys.clear();
      });
    } on IsarError catch (e) {
      print('❌ 清空助手失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTopicCount(String assistantId, int topicCount) async {
    try {
      final isar = await _db.instance;
      final entity = await isar.assistantEntitys
          .filter()
          .assistantIdEqualTo(assistantId)
          .findFirst();

      if (entity != null) {
        entity.topicCount = topicCount;
        entity.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await isar.writeTxn(() async {
          await isar.assistantEntitys.put(entity);
        });
      }
    } on IsarError catch (e) {
      print('❌ 更新助手话题数量失败: $e');
      rethrow;
    }
  }
}
