import 'package:isar/isar.dart';

part 'ai_analysis_entity.g.dart';

/// AI 分析缓存实体
///
/// 存储 AI 对话分析结果，替代原来的 AnalysisCacheManager
@collection
class AIAnalysisEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 话题 ID
  @Index()
  late String topicId;

  /// 分组索引（对话分组的序号）
  late int groupIndex;

  /// 分析内容（Markdown 格式）
  late String content;

  /// 创建时间（毫秒时间戳）
  late int createdAt;

  /// 构造函数
  AIAnalysisEntity();

  /// 创建工厂方法
  factory AIAnalysisEntity.create({
    required String topicId,
    required int groupIndex,
    required String content,
  }) {
    return AIAnalysisEntity()
      ..topicId = topicId
      ..groupIndex = groupIndex
      ..content = content
      ..createdAt = DateTime.now().millisecondsSinceEpoch;
  }
}
