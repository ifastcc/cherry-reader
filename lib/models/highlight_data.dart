import 'package:uuid/uuid.dart';

/// 高亮数据模型
class HighlightData {
  final String id;
  final String text;
  final int start;
  final int end;
  final int color;
  final String styleType;
  final DateTime createdAt;

  HighlightData({
    String? id,
    required this.text,
    required this.start,
    required this.end,
    required this.color,
    this.styleType = 'background',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'start': start,
        'end': end,
        'color': color,
        'styleType': styleType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HighlightData.fromJson(Map<String, dynamic> json) => HighlightData(
        id: json['id'] as String?,
        text: json['text'] as String,
        start: json['start'] as int,
        end: json['end'] as int,
        color: json['color'] as int,
        styleType: json['styleType'] as String? ?? 'background',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}
