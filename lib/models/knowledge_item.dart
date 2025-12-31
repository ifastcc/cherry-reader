import 'package:flutter/material.dart';
import 'isar/knowledge_entry.dart';

// 为了兼容性，重新导出 KnowledgeEntryType 并起别名
typedef KnowledgeType = KnowledgeEntryType;

/// 统一的知识项模型
///
/// 作为 KnowledgeEntry 的视图模型，用于 UI 展示
class KnowledgeItem {
  /// 唯一标识符
  final String id;

  /// 知识类型
  final KnowledgeType type;

  /// 主要内容
  /// - 笔记：笔记内容（plainText）
  /// - 标注：用户评论
  /// - 高亮：高亮的文本
  final String content;

  /// 引用的原文（仅高亮和标注有值）
  final String? quotedText;

  /// 标签列表
  final List<String> tags;

  /// 创建时间
  final DateTime createdAt;

  /// 来源话题 ID
  final String? sourceTopicId;

  /// 来源话题名称
  final String? sourceTopicName;

  /// 来源消息 ID
  final String? sourceMessageId;

  /// 高亮颜色（ARGB int）
  final int? highlightColor;

  /// 高亮样式类型
  final String? highlightStyleType;

  /// 原始实体（用于编辑和删除操作）
  final KnowledgeEntry? originalEntry;

  const KnowledgeItem({
    required this.id,
    required this.type,
    required this.content,
    this.quotedText,
    this.tags = const [],
    required this.createdAt,
    this.sourceTopicId,
    this.sourceTopicName,
    this.sourceMessageId,
    this.highlightColor,
    this.highlightStyleType,
    this.originalEntry,
  });

  /// 从 KnowledgeEntry 创建
  factory KnowledgeItem.fromEntry(KnowledgeEntry entry) {
    return KnowledgeItem(
      id: entry.entryId,
      type: entry.type,
      content: entry.plainText ?? entry.content ?? '',
      quotedText: entry.quotedText,
      tags: entry.tags,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
      sourceTopicId: entry.topicId,
      sourceTopicName: entry.topicName,
      sourceMessageId: entry.messageId,
      highlightColor: entry.color,
      highlightStyleType: entry.styleType,
      originalEntry: entry,
    );
  }

  /// 类型对应的颜色
  Color get typeColor {
    switch (type) {
      case KnowledgeType.highlight:
        return const Color(0xFFFFF176); // 黄色
      case KnowledgeType.annotation:
        return const Color(0xFF81D4FA); // 蓝色
      case KnowledgeType.note:
        return const Color(0xFFCE93D8); // 紫色
    }
  }

  /// 类型对应的图标
  IconData get typeIcon {
    switch (type) {
      case KnowledgeType.highlight:
        return Icons.highlight;
      case KnowledgeType.annotation:
        return Icons.mode_comment_outlined;
      case KnowledgeType.note:
        return Icons.edit_note;
    }
  }

  /// 类型名称
  String get typeName {
    switch (type) {
      case KnowledgeType.highlight:
        return '高亮';
      case KnowledgeType.annotation:
        return '标注';
      case KnowledgeType.note:
        return '笔记';
    }
  }

  /// 是否有来源关联
  bool get hasSource => sourceTopicId != null || sourceMessageId != null;

  /// 获取显示用的颜色（优先使用高亮颜色）
  Color get displayColor {
    if (highlightColor != null) {
      return Color(highlightColor!);
    }
    return typeColor;
  }

  /// 获取主要显示内容
  /// - 高亮/标注：优先显示引用原文
  /// - 笔记：显示笔记内容
  String get displayContent {
    if (type == KnowledgeType.note) {
      return content;
    }
    // 高亮和标注优先显示引用原文
    return quotedText ?? content;
  }

  /// 是否有用户评论（仅标注有）
  bool get hasComment =>
      type == KnowledgeType.annotation && content.isNotEmpty;

  /// 格式化创建时间（相对时间）
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';

    return '${createdAt.month}-${createdAt.day}';
  }

  /// 用于排序的时间戳
  int get sortTimestamp => createdAt.millisecondsSinceEpoch;

  @override
  String toString() {
    return 'KnowledgeItem(id: $id, type: $type, content: ${content.length > 30 ? '${content.substring(0, 30)}...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeItem && other.id == id && other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

/// Color 扩展方法
extension KnowledgeColorExtension on Color {
  /// 加深颜色
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// 变亮颜色
  Color lighten(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
