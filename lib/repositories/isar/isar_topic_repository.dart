import 'package:isar_community/isar.dart';
import '../../models/domain/topic_model.dart';
import '../../models/isar/topic_entity.dart';
import '../../services/isar_database.dart';
import '../i_topic_repository.dart';

/// 话题仓库 Isar 实现
class IsarTopicRepository implements ITopicRepository {
  final IsarDatabase _db;

  IsarTopicRepository(this._db);

  // ========== 转换方法 ==========

  TopicModel _toModel(TopicEntity entity) {
    return TopicModel(
      topicId: entity.topicId,
      name: entity.name,
      assistantId: entity.assistantId,
      messageCount: entity.messageCount,
      roundCount: entity.roundCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TopicEntity _toEntity(TopicModel model) {
    return TopicEntity.fromData(
      topicId: model.topicId,
      name: model.name,
      assistantId: model.assistantId,
      messageCount: model.messageCount,
      roundCount: model.roundCount,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  // ========== 接口实现 ==========

  @override
  Future<TopicModel?> getTopic(String topicId) async {
    try {
      final isar = await _db.importInstance;
      final entity = await isar.topicEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .findFirst();
      return entity != null ? _toModel(entity) : null;
    } on IsarError catch (e) {
      print('❌ 获取话题失败: $e');
      return null;
    }
  }

  @override
  Future<List<TopicModel>> getAllTopics() async {
    try {
      final isar = await _db.importInstance;
      final entities = await isar.topicEntitys
          .where()
          .sortByUpdatedAtDesc()
          .findAll();
      return entities.map(_toModel).toList();
    } on IsarError catch (e) {
      print('❌ 获取所有话题失败: $e');
      return [];
    }
  }

  @override
  Future<List<TopicModel>> getTopicsByAssistant(String assistantId) async {
    try {
      final isar = await _db.importInstance;
      final entities = await isar.topicEntitys
          .filter()
          .assistantIdEqualTo(assistantId)
          .sortByUpdatedAtDesc()
          .findAll();
      return entities.map(_toModel).toList();
    } on IsarError catch (e) {
      print('❌ 获取助手话题失败: $e');
      return [];
    }
  }

  @override
  Future<int> getTopicCount() async {
    try {
      final isar = await _db.importInstance;
      return isar.topicEntitys.count();
    } on IsarError catch (e) {
      print('❌ 获取话题数量失败: $e');
      return 0;
    }
  }

  @override
  Future<int> getTopicCountByAssistant(String assistantId) async {
    try {
      final isar = await _db.importInstance;
      return isar.topicEntitys
          .filter()
          .assistantIdEqualTo(assistantId)
          .count();
    } on IsarError catch (e) {
      print('❌ 获取助手话题数量失败: $e');
      return 0;
    }
  }

  @override
  Future<void> saveTopic(TopicModel topic) async {
    try {
      final isar = await _db.instance;
      final entity = _toEntity(topic);
      await isar.writeTxn(() async {
        await isar.topicEntitys.put(entity);
      });
    } on IsarError catch (e) {
      print('❌ 保存话题失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveTopics(List<TopicModel> topics) async {
    if (topics.isEmpty) return;

    try {
      final isar = await _db.instance;
      final entities = topics.map(_toEntity).toList();
      await isar.writeTxn(() async {
        await isar.topicEntitys.putAll(entities);
      });
    } on IsarError catch (e) {
      print('❌ 批量保存话题失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTopic(String topicId) async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.topicEntitys
            .filter()
            .topicIdEqualTo(topicId)
            .deleteFirst();
      });
    } on IsarError catch (e) {
      print('❌ 删除话题失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTopicsByAssistant(String assistantId) async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.topicEntitys
            .filter()
            .assistantIdEqualTo(assistantId)
            .deleteAll();
      });
    } on IsarError catch (e) {
      print('❌ 删除助手话题失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAllTopics() async {
    try {
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.topicEntitys.clear();
      });
    } on IsarError catch (e) {
      print('❌ 清空话题失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<TopicModel>> searchTopics(String keyword) async {
    if (keyword.isEmpty) return [];

    try {
      final isar = await _db.importInstance;
      final entities = await isar.topicEntitys
          .filter()
          .nameContains(keyword, caseSensitive: false)
          .sortByUpdatedAtDesc()
          .findAll();
      return entities.map(_toModel).toList();
    } on IsarError catch (e) {
      print('❌ 搜索话题失败: $e');
      return [];
    }
  }
}
