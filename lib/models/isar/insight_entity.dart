import 'package:isar_community/isar.dart';

part 'insight_entity.g.dart';

/// 洞察实体
///
/// 存储 AI 生成的洞察分析结果
@collection
class InsightEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 洞察唯一标识
  @Index(unique: true)
  late String insightId;

  /// 使用的视角 ID
  late String perspectiveId;

  /// 视角名称（冗余存储，方便显示）
  late String perspectiveName;

  /// 视角图标（冗余存储，方便显示）
  late String perspectiveIcon;

  /// 洞察内容（Markdown 格式）
  late String content;

  /// 选中的提问数量
  late int queryCount;

  /// 总字数
  late int charCount;

  /// 助手筛选描述（如"全部"、"3个助手"）
  late String assistantFilter;

  /// 时间范围描述（如"本周"、"2025年12月"）
  late String timeRangeLabel;

  /// 创建时间（毫秒时间戳）
  @Index()
  late int createdAt;

  /// 构造函数
  InsightEntity();

  /// 创建工厂方法
  factory InsightEntity.create({
    required String perspectiveId,
    required String perspectiveName,
    required String perspectiveIcon,
    required String content,
    required int queryCount,
    required int charCount,
    required String assistantFilter,
    required String timeRangeLabel,
  }) {
    return InsightEntity()
      ..insightId = 'insight_${DateTime.now().millisecondsSinceEpoch}'
      ..perspectiveId = perspectiveId
      ..perspectiveName = perspectiveName
      ..perspectiveIcon = perspectiveIcon
      ..content = content
      ..queryCount = queryCount
      ..charCount = charCount
      ..assistantFilter = assistantFilter
      ..timeRangeLabel = timeRangeLabel
      ..createdAt = DateTime.now().millisecondsSinceEpoch;
  }
}
