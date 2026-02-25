import '../../models/domain/insight_models.dart';
import '../../models/isar/insight_entity.dart';
import '../../models/isar/perspective_entity.dart';

abstract class IInsightStore {
  Future<List<PerspectiveEntity>> getAllPerspectives();
  Future<List<PerspectiveEntity>> getEnabledPerspectives();
  Future<PerspectiveEntity?> getPerspective(String perspectiveId);
  Future<void> upsertPerspective(PerspectiveEntity perspective);
  Future<void> togglePerspectiveEnabled(String perspectiveId, bool isEnabled);
  Future<bool> deleteCustomPerspective(String perspectiveId);
  Future<List<PerspectiveEntity>> getCustomPerspectives();

  Future<List<Map<String, String>>> getAssistantList();

  Future<({
    List<Map<String, String>> assistantList,
    Map<String, String> assistantIdToName,
    List<TopicGroup> topicGroups,
  })> preloadTopicGroups();

  Future<void> saveInsight(InsightEntity insight);
  Future<List<InsightEntity>> getAllInsights();
  Future<void> deleteInsight(String insightId);
  Stream<List<InsightEntity>> watchInsights();
}
