import 'package:uuid/uuid.dart';

/// 高亮范围（v3.0）
///
/// 表示一个 Block 内的选中范围，简化字段命名
class HighlightRange {
  /// Block 索引
  final int blockIndex;

  /// Block 内起始偏移
  final int start;

  /// Block 内结束偏移
  final int end;

  /// 该范围的文本（用于验证）
  final String text;

  HighlightRange({
    required this.blockIndex,
    required this.start,
    required this.end,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
        'blockIndex': blockIndex,
        'start': start,
        'end': end,
        'text': text,
      };

  factory HighlightRange.fromJson(Map<String, dynamic> json) => HighlightRange(
        blockIndex: json['blockIndex'] as int,
        start: json['start'] as int,
        end: json['end'] as int,
        text: json['text'] as String,
      );

  @override
  String toString() =>
      'HighlightRange(block:$blockIndex, $start-$end, "$text")';
}

/// 高亮数据模型（v3.0）
///
/// 用于 WebView 通信的标准格式
/// - color: CSS 十六进制字符串 '#FFF176'
/// - style: 'background' | 'underline' | 'wavy' | 'box' | 'dashed'
/// - start/end: 相对 message 容器 textContent 的全局字符偏移
/// - ranges: 兼容用于原生卡片的 Block 内偏移（可为空）
class HighlightData {
  /// 唯一标识（UUID）
  final String id;

  /// 关联的消息 ID
  final String messageId;

  /// 相对 message 容器的全局字符偏移
  final int start;
  final int end;

  /// 完整高亮文本
  final String text;

  /// CSS 颜色（十六进制 '#FFF176'）
  final String color;

  /// 样式类型
  final String style;

  /// 定位信息：每个 Block 内的范围
  final List<HighlightRange> ranges;

  /// 恢复上下文（前 50 字符）
  final String prefix;

  /// 恢复上下文（后 50 字符）
  final String suffix;

  /// 创建时间
  final DateTime createdAt;

  HighlightData({
    String? id,
    required this.messageId,
    required this.start,
    required this.end,
    required this.text,
    required this.color,
    this.style = 'background',
    required this.ranges,
    this.prefix = '',
    this.suffix = '',
    DateTime? createdAt,
  })  : id = id ?? 'hl-${const Uuid().v4()}',
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'messageId': messageId,
        'start': start,
        'end': end,
        'text': text,
        'color': color,
        'style': style,
        'ranges': ranges.map((r) => r.toJson()).toList(),
        'prefix': prefix,
        'suffix': suffix,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HighlightData.fromJson(Map<String, dynamic> json) {
    final rangesList = json['ranges'] as List?;
    final ranges = rangesList
            ?.map((e) => HighlightRange.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return HighlightData(
      id: json['id'] as String?,
      messageId: json['messageId'] as String,
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
      text: json['text'] as String,
      color: json['color'] as String,
      style: json['style'] as String? ?? 'background',
      ranges: ranges,
      prefix: json['prefix'] as String? ?? '',
      suffix: json['suffix'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// 从旧版 int 颜色格式转换为 CSS 十六进制
  static String intColorToHex(int color) {
    return '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// 从 CSS 十六进制转换为 int 颜色格式（用于数据库存储）
  static int hexColorToInt(String hex) {
    final cleanHex = hex.replaceFirst('#', '');
    return 0xFF000000 | int.parse(cleanHex, radix: 16);
  }

  HighlightData copyWith({
    String? id,
    String? messageId,
    int? start,
    int? end,
    String? text,
    String? color,
    String? style,
    List<HighlightRange>? ranges,
    String? prefix,
    String? suffix,
    DateTime? createdAt,
  }) {
    return HighlightData(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
      color: color ?? this.color,
      style: style ?? this.style,
      ranges: ranges ?? this.ranges,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'HighlightData(id:$id, msg:$messageId, style:$style, color:$color, ranges:${ranges.length})';
}
