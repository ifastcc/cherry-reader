import '../models/domain/assistant_model.dart';

/// 助手仓库抽象接口
///
/// 定义助手数据的访问接口，与具体数据库实现无关
abstract class IAssistantRepository {
  /// 获取所有助手
  Future<List<AssistantModel>> getAllAssistants();

  /// 根据 ID 获取助手
  Future<AssistantModel?> getAssistant(String assistantId);

  /// 获取助手数量
  Future<int> getAssistantCount();

  /// 保存助手
  Future<void> saveAssistant(AssistantModel assistant);

  /// 批量保存助手
  Future<void> saveAssistants(List<AssistantModel> assistants);

  /// 删除助手
  Future<void> deleteAssistant(String assistantId);

  /// 清空所有助手
  Future<void> clearAllAssistants();

  /// 更新助手的话题数量
  Future<void> updateTopicCount(String assistantId, int topicCount);
}
