import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 选区范围数据类（v3.0）
///
/// 表示一个 Block 内的选中范围
/// v3.0 简化字段：使用 start/end 替代 internalStart/internalEnd
class SelectionRange {
  /// Block 索引
  final int blockIndex;

  /// Block 内起始偏移
  final int start;

  /// Block 内结束偏移
  final int end;

  /// 该范围的文本（用于验证）
  final String text;

  SelectionRange({
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

  factory SelectionRange.fromJson(Map<String, dynamic> json) => SelectionRange(
        blockIndex: json['blockIndex'] as int,
        // 兼容旧格式：优先读取 start，fallback 到 internalStart
        start: json['start'] as int? ?? json['internalStart'] as int? ?? 0,
        end: json['end'] as int? ?? json['internalEnd'] as int? ?? 0,
        text: json['text'] as String? ?? '',
      );

  @override
  String toString() => 'SelectionRange(block:$blockIndex, $start-$end)';
}


/// 统一知识条目实体
///
/// 将高亮、标注、笔记统一为一种数据结构
/// 类型由字段组合推导：
/// - quotedText 非空 + content 为空 → 高亮
/// - quotedText 非空 + content 非空 → 标注
/// - quotedText 为空 + content 非空 → 笔记
class KnowledgeEntry {
  /// 条目唯一标识（UUID）
  late String entryId;

  // ==================== 核心内容 ====================

  /// 主内容（笔记内容 / 标注评论）
  /// - 笔记：富文本 Delta JSON
  /// - 标注：评论文本
  /// - 高亮：null 或空
  String? content;

  /// 内容类型（delta / plain）
  /// 用于区分富文本和纯文本
  String contentType = 'plain';

  /// 纯文本内容（用于搜索和预览）
  String? plainText;

  /// 引用原文（高亮/标注的选中文本）
  /// - 笔记：null
  /// - 高亮/标注：选中的原文
  String? quotedText;

  // ==================== 样式 ====================

  /// 高亮颜色（ARGB 整数）
  int? color;

  /// 样式类型（background / underline / border）
  String? styleType;

  // ==================== 来源关联 ====================

  /// 关联的消息 ID（高亮/标注来源）
  String? messageId;

  /// 关联的话题 ID
  String? topicId;

  /// 话题名称（冗余存储，避免查询）
  String? topicName;

  /// 上下文前缀
  String? prefix;

  /// 上下文后缀
  String? suffix;

  /// 文本位置 - 起始
  int? start;

  /// 文本位置 - 结束
  int? end;

  // ==================== 元数据 ====================

  /// 标签列表（JSON 序列化）
  List<String> tags = [];

  /// 创建时间戳
  late int createdAt;

  /// The sequence index of the block in the document (0-indexed).
  /// Used for fast lookup.
  int? blockIndex;

  /// A hash of the block's plain text content.
  /// Used to verify that the block hasn't changed.
  String? blockContentHash;

  /// Start offset RELATIVE to the start of the block's text.
  int? blockInternalStart;

  /// End offset RELATIVE to the start of the block's text.
  /// End offset RELATIVE to the start of the block's text.
  int? blockInternalEnd;
  
  /// Group ID for linking multiple entries (e.g. cross-block selection)
  /// @deprecated 已废弃，使用 selections 替代
  String? groupId;
  
  /// 【新架构】多选区信息 (JSON 字符串)
  /// 
  /// 存储格式: [{blockIndex, internalStart, internalEnd, text, hash, globalStart, globalEnd}, ...]
  /// 一次选择可能跨越多个 Block，每个 Block 内的选区单独记录
  String? selections;

  /// 更新时间戳
  late int updatedAt;

  // ==================== 回顾与记忆 ====================

  /// 回顾次数
  int reviewCount = 0;

  /// 上次回顾时间戳
  int? lastReviewedAt;

  /// 重要性评分 (0-5, 0=未评分)
  int importance = 0;

  /// 是否置顶
  bool isPinned = false;

  // ==================== 计算属性 ====================

  /// 推导类型
  KnowledgeEntryType get type {
    final hasQuotedText = quotedText != null && quotedText!.isNotEmpty;
    final hasContent = (content != null && content!.isNotEmpty) ||
        (plainText != null && plainText!.isNotEmpty);

    if (hasQuotedText && !hasContent) {
      return KnowledgeEntryType.highlight;
    } else if (hasQuotedText && hasContent) {
      return KnowledgeEntryType.annotation;
    } else {
      return KnowledgeEntryType.note;
    }
  }

  /// 显示内容（用于预览）
  String get displayContent {
    if (plainText != null && plainText!.isNotEmpty) {
      return plainText!;
    }
    if (quotedText != null && quotedText!.isNotEmpty) {
      return quotedText!;
    }
    return content ?? '';
  }

  /// 是否有来源
  bool get hasSource => messageId != null && messageId!.isNotEmpty;

  /// 是否有评论（标注）
  bool get hasComment {
    return quotedText != null &&
        quotedText!.isNotEmpty &&
        plainText != null &&
        plainText!.isNotEmpty;
  }
  
  /// 【v3.0】解析 selections JSON
  List<SelectionRange> get selectionRanges {
    if (selections == null || selections!.isEmpty) {
      // Fallback: 使用旧字段构建单个选区
      if (blockIndex != null && blockInternalStart != null && blockInternalEnd != null) {
        return [
          SelectionRange(
            blockIndex: blockIndex!,
            start: blockInternalStart!,
            end: blockInternalEnd!,
            text: quotedText ?? '',
          )
        ];
      }
      // 无 Block 信息，返回空
      return [];
    }
    
    try {
      final List<dynamic> list = jsonDecode(selections!);
      return list.map((e) => SelectionRange.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 【v3.0】设置 selections
  set selectionRanges(List<SelectionRange> ranges) {
    if (ranges.isEmpty) {
      selections = null;
    } else {
      selections = jsonEncode(ranges.map((r) => r.toJson()).toList());
    }
  }

  // ==================== 工厂方法 ====================

  /// 创建高亮
  static KnowledgeEntry createHighlight({
    String? entryId,
    required String messageId,
    required String quotedText,
    required int start,
    required int end,
    required int color,
    String styleType = 'background',
    String? topicId,
    String? topicName,
    String? prefix,
    String? suffix,
    String? groupId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return KnowledgeEntry()
      ..entryId = entryId ?? const Uuid().v4()
      ..quotedText = quotedText
      ..start = start
      ..end = end
      ..color = color
      ..styleType = styleType
      ..messageId = messageId
      ..topicId = topicId
      ..topicName = topicName
      ..prefix = prefix
      ..suffix = suffix
      ..groupId = groupId
      ..createdAt = now
      ..updatedAt = now;
  }

  /// 创建标注（高亮 + 评论）
  static KnowledgeEntry createAnnotation({
    String? entryId,
    required String messageId,
    required String quotedText,
    required int start,
    required int end,
    required int color,
    required String comment,
    String styleType = 'background',
    String? topicId,
    String? topicName,
    String? prefix,
    String? suffix,

    List<String>? tags,
    String? groupId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return KnowledgeEntry()
      ..entryId = entryId ?? const Uuid().v4()
      ..quotedText = quotedText
      ..content = comment
      ..plainText = comment
      ..contentType = 'plain'
      ..start = start
      ..end = end
      ..color = color
      ..styleType = styleType
      ..messageId = messageId
      ..topicId = topicId
      ..topicName = topicName
      ..prefix = prefix
      ..suffix = suffix
      ..tags = tags ?? []
      ..createdAt = now
      ..updatedAt = now;
  }

  /// 创建笔记
  static KnowledgeEntry createNote({
    String? entryId,
    required String content,
    String contentType = 'delta',
    String? plainText,
    List<String>? tags,
    String? messageId,
    int? start,
    int? end,
    String? prefix,
    String? suffix,
    String? topicId,
    String? topicName,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return KnowledgeEntry()
      ..entryId = entryId ?? const Uuid().v4()
      ..content = content
      ..contentType = contentType
      ..plainText = plainText ?? _extractPlainText(content, contentType)
      ..tags = tags ?? []
      ..messageId = messageId
      ..start = start
      ..end = end
      ..prefix = prefix
      ..suffix = suffix
      ..topicId = topicId
      ..topicName = topicName
      ..createdAt = now
      ..updatedAt = now;
  }

  /// 从内容提取纯文本
  static String _extractPlainText(String content, String contentType) {
    if (contentType == 'plain') return content;
    // Delta JSON 需要解析，这里简化处理
    // 实际使用时应该用 QuillController 解析
    return content;
  }

  /// 从内容提取标签
  static List<String> extractTags(String text) {
    final regex = RegExp(r'#([\u4e00-\u9fa5\w]+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toSet().toList();
  }

  /// 高亮升级为标注
  void upgradeToAnnotation(String comment, {List<String>? tags}) {
    content = comment;
    plainText = comment;
    contentType = 'plain';
    this.tags = tags ?? extractTags(comment);
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}

/// 知识条目类型
enum KnowledgeEntryType {
  highlight,
  annotation,
  note,
}
