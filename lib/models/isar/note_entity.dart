import 'dart:convert';
import 'package:isar_community/isar.dart';

part 'note_entity.g.dart';

/// 笔记实体
///
/// 支持类 flomo 的快速笔记功能
/// - 使用 Quill Delta JSON 或纯 Markdown 存储
/// - 支持标签索引
/// - 支持关联回源（跳回对话上下文）
@collection
class NoteEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 笔记 ID（UUID，用于外部引用）
  @Index(unique: true)
  late String noteId;

  /// 笔记内容（Quill Delta JSON 或 Markdown 文本）
  late String content;

  /// 内容格式类型（'delta' 或 'markdown'）
  late String contentType;

  /// 纯文本内容（用于搜索，从 content 提取）
  late String plainText;

  /// 标签列表（用于分类和搜索）
  List<String> tags = [];

  /// 创建时间（毫秒时间戳）
  @Index()
  late int createdAt;

  /// 更新时间（毫秒时间戳）
  late int updatedAt;

  /// 是否已归档
  late bool isArchived;

  /// 是否已删除（软删除）
  late bool isDeleted;

  /// 来源类型（'manual', 'from_highlight', 'from_message'）
  late String sourceType;

  /// 关联的话题 ID（如果来源于对话）
  @Index()
  String? topicId;

  /// 关联的消息 ID（如果来源于消息）
  @Index()
  String? messageId;

  /// 关联的高亮 ID（如果来源于高亮）
  @Index()
  String? highlightId;

  /// 上下文快照（用于跳回对话时快速预览）
  /// JSON 格式: { "topicName": "xxx", "messagePreview": "...", "assistantName": "..." }
  String? contextSnapshotJson;

  /// 构造函数
  NoteEntity();

  /// 从手动创建
  factory NoteEntity.create({
    required String noteId,
    required String content,
    required String contentType,
    required String plainText,
    List<String> tags = const [],
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return NoteEntity()
      ..noteId = noteId
      ..content = content
      ..contentType = contentType
      ..plainText = plainText
      ..tags = tags
      ..createdAt = now
      ..updatedAt = now
      ..isArchived = false
      ..isDeleted = false
      ..sourceType = 'manual';
  }

  /// 从高亮创建
  factory NoteEntity.fromHighlight({
    required String noteId,
    required String content,
    required String contentType,
    required String plainText,
    required String highlightId,
    required String messageId,
    required String topicId,
    required Map<String, dynamic> contextSnapshot,
    List<String> tags = const [],
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return NoteEntity()
      ..noteId = noteId
      ..content = content
      ..contentType = contentType
      ..plainText = plainText
      ..tags = tags
      ..createdAt = now
      ..updatedAt = now
      ..isArchived = false
      ..isDeleted = false
      ..sourceType = 'from_highlight'
      ..highlightId = highlightId
      ..messageId = messageId
      ..topicId = topicId
      ..contextSnapshotJson = jsonEncode(contextSnapshot);
  }

  /// 从消息创建
  factory NoteEntity.fromMessage({
    required String noteId,
    required String content,
    required String contentType,
    required String plainText,
    required String messageId,
    required String topicId,
    required Map<String, dynamic> contextSnapshot,
    List<String> tags = const [],
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return NoteEntity()
      ..noteId = noteId
      ..content = content
      ..contentType = contentType
      ..plainText = plainText
      ..tags = tags
      ..createdAt = now
      ..updatedAt = now
      ..isArchived = false
      ..isDeleted = false
      ..sourceType = 'from_message'
      ..messageId = messageId
      ..topicId = topicId
      ..contextSnapshotJson = jsonEncode(contextSnapshot);
  }

  /// 获取上下文快照
  Map<String, dynamic>? getContextSnapshot() {
    if (contextSnapshotJson == null || contextSnapshotJson!.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(contextSnapshotJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 是否有来源关联
  bool get hasSource =>
      sourceType != 'manual' && (topicId != null || messageId != null);

  /// 获取来源描述
  String? getSourceDescription() {
    final snapshot = getContextSnapshot();
    if (snapshot == null) return null;
    return snapshot['topicName'] as String?;
  }

  /// 从 plainText 提取标签
  static List<String> extractTags(String text) {
    // 支持中文和英文标签
    final regex = RegExp(r'#([\u4e00-\u9fa5\w]+)');
    return regex
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }

  /// 复制并更新
  NoteEntity copyWith({
    String? content,
    String? contentType,
    String? plainText,
    List<String>? tags,
    bool? isArchived,
    bool? isDeleted,
  }) {
    return NoteEntity()
      ..id = id
      ..noteId = noteId
      ..content = content ?? this.content
      ..contentType = contentType ?? this.contentType
      ..plainText = plainText ?? this.plainText
      ..tags = tags ?? this.tags
      ..createdAt = createdAt
      ..updatedAt = DateTime.now().millisecondsSinceEpoch
      ..isArchived = isArchived ?? this.isArchived
      ..isDeleted = isDeleted ?? this.isDeleted
      ..sourceType = sourceType
      ..topicId = topicId
      ..messageId = messageId
      ..highlightId = highlightId
      ..contextSnapshotJson = contextSnapshotJson;
  }
}
