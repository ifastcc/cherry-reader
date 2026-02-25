/// 视角实体
///
/// 用于 AI 洞察功能的分析视角，支持内置和自定义视角
class PerspectiveEntity {
  /// 视角唯一标识
  late String perspectiveId;

  /// 视角名称
  late String name;

  /// 图标（emoji）
  late String icon;

  /// 简短描述
  late String description;

  /// Prompt 模板（必须包含 {queries} 占位符）
  late String promptTemplate;

  /// 分类（self_awareness, problem_solving, action_oriented, growth_mindset）
  late String category;

  /// 是否为内置视角
  late bool isBuiltin;

  /// 是否启用
  late bool isEnabled;

  /// 排序顺序
  late int sortOrder;

  /// 创建时间（毫秒时间戳）
  late int createdAt;

  /// 更新时间（毫秒时间戳）
  late int updatedAt;

  /// 构造函数
  PerspectiveEntity();

  /// 创建工厂方法
  factory PerspectiveEntity.create({
    required String perspectiveId,
    required String name,
    required String icon,
    required String description,
    required String promptTemplate,
    required String category,
    required bool isBuiltin,
    required bool isEnabled,
    required int sortOrder,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return PerspectiveEntity()
      ..perspectiveId = perspectiveId
      ..name = name
      ..icon = icon
      ..description = description
      ..promptTemplate = promptTemplate
      ..category = category
      ..isBuiltin = isBuiltin
      ..isEnabled = isEnabled
      ..sortOrder = sortOrder
      ..createdAt = now
      ..updatedAt = now;
  }
}
