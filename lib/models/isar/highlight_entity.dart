import 'package:isar/isar.dart';

part 'highlight_entity.g.dart';

/// Isar 标注实体
///
/// 对应原来的 HighlightData，但使用 Isar 存储
/// 优势：
/// - 支持高效索引查询
/// - 支持批量操作
/// - 支持实时监听变化
@collection
class HighlightEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 自定义的字符串 ID（用于兼容旧代码）
  @Index()
  late String highlightId;

  /// 关联的消息 ID（建立索引以支持快速查询）
  @Index()
  late String messageId;

  /// 高亮的文本内容
  late String text;

  /// 起始位置（在原文中的字符索引）
  late int start;

  /// 结束位置
  late int end;

  /// 颜色值（ARGB 格式的 int）
  late int color;

  /// 样式类型（highlight, underline, star 等）
  late String styleType;

  /// 创建时间（毫秒时间戳）
  late int createdAt;

  /// 构造函数
  HighlightEntity();

  /// 从 Map 创建（用于数据迁移）
  factory HighlightEntity.fromMap(Map<String, dynamic> map) {
    return HighlightEntity()
      ..highlightId = map['id'] as String
      ..messageId = map['messageId'] as String? ?? ''
      ..text = map['text'] as String
      ..start = map['start'] as int
      ..end = map['end'] as int
      ..color = map['color'] as int
      ..styleType = map['styleType'] as String? ?? 'highlight'
      ..createdAt =
          map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': highlightId,
      'messageId': messageId,
      'text': text,
      'start': start,
      'end': end,
      'color': color,
      'styleType': styleType,
      'createdAt': createdAt,
    };
  }
}
