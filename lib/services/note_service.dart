import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/isar/note_entity.dart';
import 'isar_database.dart';

/// 笔记服务
///
/// 管理笔记的 CRUD 操作，支持：
/// - 创建/更新/删除笔记
/// - 按标签、话题、消息查询
/// - 全文搜索
/// - 随机获取（用于每日回顾）
/// - 实时监听变化
class NoteService {
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();

  final IsarDatabase _db = IsarDatabase();
  final _uuid = const Uuid();

  // ============ 创建笔记 ============

  /// 创建手动笔记
  Future<NoteEntity> createNote({
    required String content,
    String contentType = 'delta',
    String? plainText,
    List<String>? tags,
  }) async {
    final noteId = 'note_${_uuid.v4()}';
    final extractedPlainText = plainText ?? content;
    final extractedTags = tags ?? NoteEntity.extractTags(extractedPlainText);

    final note = NoteEntity.create(
      noteId: noteId,
      content: content,
      contentType: contentType,
      plainText: extractedPlainText,
      tags: extractedTags,
    );

    await _saveNote(note);
    return note;
  }

  /// 从高亮创建笔记
  Future<NoteEntity> createNoteFromHighlight({
    required String highlightText,
    required String highlightId,
    required String messageId,
    required String topicId,
    required String topicName,
    String? assistantName,
    String? messagePreview,
    String contentType = 'delta',
  }) async {
    final noteId = 'note_${_uuid.v4()}';
    final contextSnapshot = {
      'topicName': topicName,
      'assistantName': assistantName,
      'messagePreview': messagePreview,
    };

    // 高亮文本作为初始内容
    final content = highlightText;
    final tags = NoteEntity.extractTags(highlightText);

    final note = NoteEntity.fromHighlight(
      noteId: noteId,
      content: content,
      contentType: contentType,
      plainText: highlightText,
      highlightId: highlightId,
      messageId: messageId,
      topicId: topicId,
      contextSnapshot: contextSnapshot,
      tags: tags,
    );

    await _saveNote(note);
    return note;
  }

  /// 从消息创建笔记
  Future<NoteEntity> createNoteFromMessage({
    required String initialContent,
    required String messageId,
    required String topicId,
    required String topicName,
    String? assistantName,
    String? messagePreview,
    String contentType = 'delta',
  }) async {
    final noteId = 'note_${_uuid.v4()}';
    final contextSnapshot = {
      'topicName': topicName,
      'assistantName': assistantName,
      'messagePreview': messagePreview,
    };

    final tags = NoteEntity.extractTags(initialContent);

    final note = NoteEntity.fromMessage(
      noteId: noteId,
      content: initialContent,
      contentType: contentType,
      plainText: initialContent,
      messageId: messageId,
      topicId: topicId,
      contextSnapshot: contextSnapshot,
      tags: tags,
    );

    await _saveNote(note);
    return note;
  }

  // ============ 更新笔记 ============

  /// 更新笔记内容
  Future<void> updateNote({
    required String noteId,
    required String content,
    String? plainText,
    List<String>? tags,
  }) async {
    final isar = await _db.instance;
    final note = await isar.noteEntitys
        .filter()
        .noteIdEqualTo(noteId)
        .findFirst();

    if (note == null) {
      throw Exception('笔记不存在: $noteId');
    }

    final extractedPlainText = plainText ?? content;
    final extractedTags = tags ?? NoteEntity.extractTags(extractedPlainText);

    final updated = note.copyWith(
      content: content,
      plainText: extractedPlainText,
      tags: extractedTags,
    );

    await _saveNote(updated);
  }

  /// 归档笔记
  Future<void> archiveNote(String noteId) async {
    final isar = await _db.instance;
    final note = await isar.noteEntitys
        .filter()
        .noteIdEqualTo(noteId)
        .findFirst();

    if (note != null) {
      final updated = note.copyWith(isArchived: true);
      await _saveNote(updated);
    }
  }

  /// 取消归档笔记
  Future<void> unarchiveNote(String noteId) async {
    final isar = await _db.instance;
    final note = await isar.noteEntitys
        .filter()
        .noteIdEqualTo(noteId)
        .findFirst();

    if (note != null) {
      final updated = note.copyWith(isArchived: false);
      await _saveNote(updated);
    }
  }

  // ============ 删除笔记 ============

  /// 软删除笔记
  Future<void> deleteNote(String noteId) async {
    final isar = await _db.instance;
    final note = await isar.noteEntitys
        .filter()
        .noteIdEqualTo(noteId)
        .findFirst();

    if (note != null) {
      final updated = note.copyWith(isDeleted: true);
      await _saveNote(updated);
    }
  }

  /// 彻底删除笔记
  Future<void> permanentlyDeleteNote(String noteId) async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.noteEntitys
          .filter()
          .noteIdEqualTo(noteId)
          .deleteFirst();
    });
  }

  /// 清空已删除的笔记
  Future<int> clearDeletedNotes() async {
    final isar = await _db.instance;
    return isar.writeTxn(() async {
      return isar.noteEntitys
          .filter()
          .isDeletedEqualTo(true)
          .deleteAll();
    });
  }

  // ============ 查询笔记 ============

  /// 获取单个笔记
  Future<NoteEntity?> getNote(String noteId) async {
    final isar = await _db.instance;
    return isar.noteEntitys
        .filter()
        .noteIdEqualTo(noteId)
        .findFirst();
  }

  /// 获取所有笔记（排除已删除）
  Future<List<NoteEntity>> getAllNotes({
    bool includeArchived = false,
  }) async {
    final isar = await _db.instance;

    if (includeArchived) {
      return isar.noteEntitys
          .filter()
          .isDeletedEqualTo(false)
          .sortByCreatedAtDesc()
          .findAll();
    } else {
      return isar.noteEntitys
          .filter()
          .isDeletedEqualTo(false)
          .isArchivedEqualTo(false)
          .sortByCreatedAtDesc()
          .findAll();
    }
  }

  /// 根据标签查询笔记
  Future<List<NoteEntity>> getNotesByTag(String tag) async {
    final isar = await _db.instance;
    return isar.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .isArchivedEqualTo(false)
        .tagsElementEqualTo(tag)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 根据话题查询笔记
  Future<List<NoteEntity>> getNotesByTopic(String topicId) async {
    final isar = await _db.instance;
    return isar.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .topicIdEqualTo(topicId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 根据消息查询笔记
  Future<List<NoteEntity>> getNotesByMessage(String messageId) async {
    final isar = await _db.instance;
    return isar.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .messageIdEqualTo(messageId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 根据高亮查询笔记
  Future<NoteEntity?> getNoteByHighlight(String highlightId) async {
    final isar = await _db.instance;
    return isar.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .highlightIdEqualTo(highlightId)
        .findFirst();
  }

  /// 全文搜索笔记
  Future<List<NoteEntity>> searchNotes(String query) async {
    if (query.isEmpty) return [];

    final isar = await _db.instance;
    final lowerQuery = query.toLowerCase();

    return isar.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .isArchivedEqualTo(false)
        .plainTextContains(lowerQuery, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 获取所有标签（去重）
  Future<List<String>> getAllTags() async {
    final notes = await getAllNotes();
    final tagSet = <String>{};
    for (final note in notes) {
      tagSet.addAll(note.tags);
    }
    return tagSet.toList()..sort();
  }

  /// 获取标签统计
  Future<Map<String, int>> getTagStatistics() async {
    final notes = await getAllNotes();
    final stats = <String, int>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        stats[tag] = (stats[tag] ?? 0) + 1;
      }
    }
    return stats;
  }

  // ============ 每日回顾 ============

  /// 随机获取笔记（用于每日回顾）
  Future<List<NoteEntity>> getRandomNotes({int count = 10}) async {
    final allNotes = await getAllNotes();
    if (allNotes.isEmpty) return [];

    // 随机打乱并取前 count 个
    allNotes.shuffle();
    return allNotes.take(count).toList();
  }

  /// 获取最近的笔记
  Future<List<NoteEntity>> getRecentNotes({int count = 10}) async {
    final isar = await _db.instance;
    return isar.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .isArchivedEqualTo(false)
        .sortByCreatedAtDesc()
        .limit(count)
        .findAll();
  }

  // ============ 监听变化 ============

  /// 监听所有笔记变化
  Stream<List<NoteEntity>> watchAllNotes() {
    return _db.instanceSync.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .isArchivedEqualTo(false)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// 监听特定标签的笔记变化
  Stream<List<NoteEntity>> watchNotesByTag(String tag) {
    return _db.instanceSync.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .isArchivedEqualTo(false)
        .tagsElementEqualTo(tag)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  // ============ 统计 ============

  /// 获取笔记数量
  Future<int> getNoteCount() async {
    final isar = await _db.instance;
    return isar.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .isArchivedEqualTo(false)
        .count();
  }

  /// 获取归档笔记数量
  Future<int> getArchivedNoteCount() async {
    final isar = await _db.instance;
    return isar.noteEntitys
        .filter()
        .isDeletedEqualTo(false)
        .isArchivedEqualTo(true)
        .count();
  }

  // ============ 私有方法 ============

  Future<void> _saveNote(NoteEntity note) async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.noteEntitys.put(note);
    });
  }
}
