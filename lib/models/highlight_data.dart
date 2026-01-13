import 'package:uuid/uuid.dart';
import 'isar/knowledge_entry.dart' show SelectionRange;

/// 高亮数据模型
/// 
/// 【新架构】一条 HighlightData 代表用户的一次选择操作
/// - selections: 存储多个 Block 内的选区信息
/// - text: 完整的引用文本（保留换行）
/// - start/end: 全局偏移（用于 fallback）
class HighlightData {
  final String id;
  final String text;
  final int start;
  final int end;
  final int color;
  final String? prefix;
  final String? suffix;
  final String styleType;
  final int? blockIndex;
  final String? blockContentHash;
  final int? blockInternalStart;
  final int? blockInternalEnd;
  @Deprecated('使用 selections 替代')
  final String? groupId;
  final DateTime createdAt;
  
  /// 【新架构】多选区信息
  final List<SelectionRange>? selections;

  HighlightData({
    String? id,
    required this.text,
    required this.start,
    required this.end,
    required this.color,
    this.prefix,
    this.suffix,
    this.styleType = 'background',
    this.blockIndex,
    this.blockContentHash,
    this.blockInternalStart,
    this.blockInternalEnd,
    this.groupId,
    this.selections,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  
  /// 【新架构】获取有效的选区列表
  /// 
  /// 优先使用 selections，fallback 到旧字段
  List<SelectionRange> get effectiveSelections {
    if (selections != null && selections!.isNotEmpty) {
      return selections!;
    }
    // Fallback: 从旧字段构建单个选区
    if (blockIndex != null && blockInternalStart != null && blockInternalEnd != null) {
      return [
        SelectionRange(
          blockIndex: blockIndex!,
          internalStart: blockInternalStart!,
          internalEnd: blockInternalEnd!,
          text: text,
          blockContentHash: blockContentHash,
          globalStart: start,
          globalEnd: end,
          prefix: prefix,
          suffix: suffix,
        )
      ];
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'start': start,
    'end': end,
    'color': color,
    'prefix': prefix,
    'suffix': suffix,
    'styleType': styleType,
    'blockIndex': blockIndex,
    'blockContentHash': blockContentHash,
    'blockInternalStart': blockInternalStart,
    'blockInternalEnd': blockInternalEnd,
    'groupId': groupId,
    'selections': selections?.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory HighlightData.fromJson(Map<String, dynamic> json) => HighlightData(
    id: json['id'] as String?,
    text: json['text'] as String,
    start: json['start'] as int,
    end: json['end'] as int,
    color: json['color'] as int,
    prefix: json['prefix'] as String?,
    suffix: json['suffix'] as String?,
    styleType: json['styleType'] as String? ?? 'background',
    blockIndex: json['blockIndex'] as int?,
    blockContentHash: json['blockContentHash'] as String?,
    blockInternalStart: json['blockInternalStart'] as int?,
    blockInternalEnd: json['blockInternalEnd'] as int?,
    groupId: json['groupId'] as String?,
    selections: json['selections'] != null
        ? (json['selections'] as List).map((e) => SelectionRange.fromJson(e as Map<String, dynamic>)).toList()
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );
}

/// HighlightData 扩展
extension HighlightDataCopyWith on HighlightData {
  /// 创建副本并覆盖指定字段
  HighlightData copyWith({
    String? id,
    String? text,
    String? prefix,
    String? suffix,
    int? start,
    int? end,
    int? color,
    String? styleType,
    int? blockIndex,
    String? blockContentHash,
    int? blockInternalStart,
    int? blockInternalEnd,
    String? groupId,
    List<SelectionRange>? selections,
    DateTime? createdAt,
  }) {
    return HighlightData(
      id: id ?? this.id,
      text: text ?? this.text,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
      styleType: styleType ?? this.styleType,
      blockIndex: blockIndex ?? this.blockIndex,
      blockContentHash: blockContentHash ?? this.blockContentHash,
      blockInternalStart: blockInternalStart ?? this.blockInternalStart,
      blockInternalEnd: blockInternalEnd ?? this.blockInternalEnd,
      groupId: groupId ?? this.groupId,
      selections: selections ?? this.selections,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
