import '../models/domain/topic_model.dart';

/// 话题仓库抽象接口
///
/// 定义话题数据的访问接口，与具体数据库实现无关
abstract class ITopicRepository {
  /// 根据 ID 获取话题
  Future<TopicModel?> getTopic(String topicId);

  /// 获取所有话题
  Future<List<TopicModel>> getAllTopics();

  /// 批量根据 ID 获取话题
  Future<List<TopicModel>> getTopicsByIds(List<String> topicIds);

  /// 根据助手 ID 获取话题列表
  Future<List<TopicModel>> getTopicsByAssistant(String assistantId);

  /// 获取话题数量
  Future<int> getTopicCount();

  /// 获取指定助手的话题数量
  Future<int> getTopicCountByAssistant(String assistantId);

  /// 保存话题
  Future<void> saveTopic(TopicModel topic);

  /// 批量保存话题
  Future<void> saveTopics(List<TopicModel> topics);

  /// 删除话题
  Future<void> deleteTopic(String topicId);

  /// 删除指定助手的所有话题
  Future<void> deleteTopicsByAssistant(String assistantId);

  /// 清空所有话题
  Future<void> clearAllTopics();

  /// 搜索话题（按名称）
  Future<List<TopicModel>> searchTopics(String keyword);
}
