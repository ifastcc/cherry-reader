import '../models/knowledge_item.dart';
import '../models/isar/knowledge_entry.dart';
import 'knowledge_entry_service.dart';

/// 知识库服务（门面模式）
///
/// 提供统一的查询接口，内部委托给 KnowledgeEntryService
/// 主要职责：将 KnowledgeEntry 转换为 KnowledgeItem 供 UI 使用
class KnowledgeService {
  static final KnowledgeService _instance = KnowledgeService._internal();
  factory KnowledgeService() => _instance;
  KnowledgeService._internal();

  final KnowledgeEntryService _entryService = KnowledgeEntryService();

  // ==================== 查询操作 ====================

  /// 获取所有知识项（按时间倒序）
  Future<List<KnowledgeItem>> getAllItems({
    KnowledgeType? type,
    int limit = 0,
  }) async {
    final entries = await _entryService.getAllEntries(
      type: type,
      limit: limit,
    );
    return entries.map(KnowledgeItem.fromEntry).toList();
  }

  /// 搜索知识项
  Future<List<KnowledgeItem>> searchItems(String query) async {
    final entries = await _entryService.search(query);
    return entries.map(KnowledgeItem.fromEntry).toList();
  }

  /// 按标签查询
  Future<List<KnowledgeItem>> getItemsByTag(String tag) async {
    final entries = await _entryService.getByTag(tag);
    return entries.map(KnowledgeItem.fromEntry).toList();
  }

  /// 按话题查询
  Future<List<KnowledgeItem>> getItemsByTopic(String topicId) async {
    final entries = await _entryService.getByTopic(topicId);
    return entries.map(KnowledgeItem.fromEntry).toList();
  }

  /// 按消息查询
  Future<List<KnowledgeItem>> getItemsByMessage(String messageId) async {
    final entries = await _entryService.getByMessage(messageId);
    return entries.map(KnowledgeItem.fromEntry).toList();
  }

  // ==================== 标签管理 ====================

  /// 获取所有标签统计
  Future<Map<String, int>> getTagStatistics() async {
    return _entryService.getTagStatistics();
  }

  /// 获取所有标签（去重排序）
  Future<List<String>> getAllTags() async {
    return _entryService.getAllTags();
  }

  // ==================== 每日回顾 ====================

  /// 随机获取知识项（用于每日回顾）
  Future<List<KnowledgeItem>> getRandomItems({int count = 10}) async {
    final entries = await _entryService.getRandomEntries(count: count);
    return entries.map(KnowledgeItem.fromEntry).toList();
  }

  /// 获取需要回顾的知识项（基于遗忘曲线）
  Future<List<KnowledgeItem>> getItemsForReview({int count = 10}) async {
    final entries = await _entryService.getEntriesForReview(count: count);
    return entries.map(KnowledgeItem.fromEntry).toList();
  }

  /// 记录一次回顾
  Future<void> recordReview(String entryId) async {
    await _entryService.recordReview(entryId);
  }

  /// 获取最近的知识项
  Future<List<KnowledgeItem>> getRecentItems({int count = 10}) async {
    return getAllItems(limit: count);
  }

  // ==================== 分组查询 ====================

  /// 按 Topic 分组获取知识项
  Future<Map<String?, List<KnowledgeItem>>> getItemsGroupedByTopic() async {
    final grouped = await _entryService.getEntriesGroupedByTopic();
    return grouped.map((key, entries) => MapEntry(
      key == '__no_source__' ? null : key,
      entries.map(KnowledgeItem.fromEntry).toList(),
    ));
  }

  /// 获取置顶知识项
  Future<List<KnowledgeItem>> getPinnedItems() async {
    final entries = await _entryService.getPinnedEntries();
    return entries.map(KnowledgeItem.fromEntry).toList();
  }

  /// 切换置顶状态
  Future<void> togglePin(String entryId) async {
    await _entryService.togglePin(entryId);
  }

  /// 更新重要性评分
  Future<void> updateImportance(String entryId, int importance) async {
    await _entryService.updateImportance(entryId, importance);
  }

  // ==================== 删除操作 ====================

  /// 删除知识项
  Future<void> deleteItem(KnowledgeItem item) async {
    await _entryService.deleteEntry(item.id);
  }

  // ==================== 统计信息 ====================

  /// 获取各类型数量统计
  Future<Map<KnowledgeType, int>> getCountByType() async {
    return _entryService.getCountByType();
  }

  /// 获取知识项总数
  Future<int> getTotalCount() async {
    return _entryService.getCount();
  }

  // ==================== 创建操作 ====================

  /// 创建高亮
  Future<KnowledgeEntry> createHighlight({
    required String messageId,
    required String quotedText,
    required int start,
    required int end,
    required int color,
    String styleType = 'background',
    String? topicId,
    String? topicName,
  }) async {
    return _entryService.createHighlight(
      messageId: messageId,
      quotedText: quotedText,
      start: start,
      end: end,
      color: color,
      styleType: styleType,
      topicId: topicId,
      topicName: topicName,
    );
  }

  /// 创建标注
  Future<KnowledgeEntry> createAnnotation({
    required String messageId,
    required String quotedText,
    required int start,
    required int end,
    required int color,
    required String comment,
    String styleType = 'background',
    String? topicId,
    String? topicName,
    List<String>? tags,
  }) async {
    return _entryService.createAnnotation(
      messageId: messageId,
      quotedText: quotedText,
      start: start,
      end: end,
      color: color,
      comment: comment,
      styleType: styleType,
      topicId: topicId,
      topicName: topicName,
      tags: tags,
    );
  }

  /// 创建笔记
  Future<KnowledgeEntry> createNote({
    required String content,
    String contentType = 'delta',
    String? plainText,
    List<String>? tags,
    String? messageId,
    String? topicId,
    String? topicName,
  }) async {
    return _entryService.createNote(
      content: content,
      contentType: contentType,
      plainText: plainText,
      tags: tags,
      messageId: messageId,
      topicId: topicId,
      topicName: topicName,
    );
  }

  // ==================== 更新操作 ====================

  /// 更新笔记内容
  Future<void> updateNoteContent({
    required String entryId,
    required String content,
    required String plainText,
    List<String>? tags,
  }) async {
    await _entryService.updateNoteContent(
      entryId: entryId,
      content: content,
      plainText: plainText,
      tags: tags,
    );
  }

  /// 更新标注评论
  Future<void> updateComment({
    required String entryId,
    required String comment,
    List<String>? tags,
  }) async {
    await _entryService.updateComment(
      entryId: entryId,
      comment: comment,
      tags: tags,
    );
  }

  /// 更新高亮样式
  Future<void> updateStyle({
    required String entryId,
    required int color,
    String? styleType,
  }) async {
    await _entryService.updateStyle(
      entryId: entryId,
      color: color,
      styleType: styleType,
    );
  }

  /// 高亮升级为标注
  Future<void> upgradeToAnnotation({
    required String entryId,
    required String comment,
    List<String>? tags,
  }) async {
    await _entryService.upgradeToAnnotation(
      entryId: entryId,
      comment: comment,
      tags: tags,
    );
  }
}
