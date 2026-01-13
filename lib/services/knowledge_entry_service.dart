import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../models/isar/knowledge_entry.dart';
import 'isar_database.dart';

/// 统一知识条目服务
///
/// 管理所有类型的知识条目（高亮、标注、笔记）
/// 单例模式，全局共享
class KnowledgeEntryService {
  static final KnowledgeEntryService _instance =
      KnowledgeEntryService._internal();
  factory KnowledgeEntryService() => _instance;
  KnowledgeEntryService._internal();

  final IsarDatabase _db = IsarDatabase();

  // ==================== 创建操作 ====================

  /// 创建高亮

  /// 【新架构】创建高亮 - 支持 selections
  Future<KnowledgeEntry> createHighlight({
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
    int? blockIndex,
    String? blockContentHash,
    int? blockInternalStart,
    int? blockInternalEnd,
    @Deprecated('使用 selections 替代')
    String? groupId,
    List<SelectionRange>? selections,
  }) async {
    final entry = KnowledgeEntry.createHighlight(
      messageId: messageId,
      quotedText: quotedText,
      start: start,
      end: end,
      color: color,
      styleType: styleType,
      topicId: topicId,
      topicName: topicName,
      prefix: prefix,
      suffix: suffix,
      groupId: groupId,
    )
      ..blockIndex = blockIndex
      ..blockContentHash = blockContentHash
      ..blockInternalStart = blockInternalStart
      ..blockInternalEnd = blockInternalEnd;
    
    // 【新架构】设置 selections
    if (selections != null && selections.isNotEmpty) {
      entry.selectionRanges = selections;
    }

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 创建高亮: ${entry.entryId} (包含 ${selections?.length ?? 0} 个选区)');
    return entry;
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
    String? prefix,
    String? suffix,
    List<String>? tags,
  }) async {
    final entry = KnowledgeEntry.createAnnotation(
      messageId: messageId,
      quotedText: quotedText,
      start: start,
      end: end,
      color: color,
      comment: comment,
      styleType: styleType,
      topicId: topicId,
      topicName: topicName,
      prefix: prefix,
      suffix: suffix,
      tags: tags,
    );

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 创建标注: ${entry.entryId}');
    return entry;
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
    final entry = KnowledgeEntry.createNote(
      content: content,
      contentType: contentType,
      plainText: plainText,
      tags: tags,
      messageId: messageId,
      topicId: topicId,
      topicName: topicName,
    );

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 创建笔记: ${entry.entryId}');
    return entry;
  }

  // ==================== 查询操作 ====================

  /// 获取所有条目（按时间倒序）
  Future<List<KnowledgeEntry>> getAllEntries({
    KnowledgeEntryType? type,
    int limit = 0,
  }) async {
    final isar = await _db.instance;

    var entries = await isar.knowledgeEntrys
        .filter()
        .entryIdIsNotEmpty()
        .sortByCreatedAtDesc()
        .findAll();

    // 按类型筛选
    if (type != null) {
      entries = entries.where((e) => e.type == type).toList();
    }

    // 限制数量
    if (limit > 0 && entries.length > limit) {
      return entries.take(limit).toList();
    }

    return entries;
  }

  /// 获取单个条目
  Future<KnowledgeEntry?> getEntry(String entryId) async {
    final isar = await _db.instance;
    return isar.knowledgeEntrys
        .filter()
        .entryIdEqualTo(entryId)
        .findFirst();
  }

  /// 按消息 ID 获取（用于显示对话中的高亮/标注）
  Future<List<KnowledgeEntry>> getByMessage(String messageId) async {
    final isar = await _db.instance;
    return isar.knowledgeEntrys
        .filter()
        .messageIdEqualTo(messageId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 按话题 ID 获取
  Future<List<KnowledgeEntry>> getByTopic(String topicId) async {
    final isar = await _db.instance;
    return isar.knowledgeEntrys
        .filter()
        .topicIdEqualTo(topicId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 按标签获取
  Future<List<KnowledgeEntry>> getByTag(String tag) async {
    final isar = await _db.instance;
    final entries = await isar.knowledgeEntrys
        .filter()
        .entryIdIsNotEmpty()
        .sortByCreatedAtDesc()
        .findAll();

    return entries.where((e) => e.tags.contains(tag)).toList();
  }

  /// 搜索条目
  Future<List<KnowledgeEntry>> search(String query) async {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final isar = await _db.instance;

    final entries = await isar.knowledgeEntrys
        .filter()
        .entryIdIsNotEmpty()
        .sortByCreatedAtDesc()
        .findAll();

    return entries.where((e) {
      final content = e.displayContent.toLowerCase();
      final quoted = e.quotedText?.toLowerCase() ?? '';
      final tagMatch = e.tags.any((t) => t.toLowerCase().contains(lowerQuery));
      return content.contains(lowerQuery) ||
          quoted.contains(lowerQuery) ||
          tagMatch;
    }).toList();
  }

  /// 获取随机条目（用于每日回顾）
  Future<List<KnowledgeEntry>> getRandomEntries({int count = 10}) async {
    final entries = await getAllEntries();
    if (entries.isEmpty) return [];

    entries.shuffle();
    return entries.take(count).toList();
  }

  /// 按 Topic 分组获取条目
  Future<Map<String, List<KnowledgeEntry>>> getEntriesGroupedByTopic() async {
    final entries = await getAllEntries();
    final grouped = <String, List<KnowledgeEntry>>{};
    
    // 无来源的条目放在「独立笔记」分组
    const noSourceKey = '__no_source__';
    
    for (final entry in entries) {
      final key = entry.topicId ?? noSourceKey;
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    
    return grouped;
  }

  /// 获取需要回顾的条目（简化版遗忘曲线）
  /// 
  /// 算法：
  /// - 从未回顾过的条目优先级最高
  /// - 回顾次数少的优先
  /// - 距离上次回顾时间越长优先级越高
  Future<List<KnowledgeEntry>> getEntriesForReview({int count = 10}) async {
    final entries = await getAllEntries();
    if (entries.isEmpty) return [];
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 计算每个条目的「遗忘分数」，分数越高越需要回顾
    final scored = entries.map((e) {
      double score = 0;
      
      // 从未回顾过：高分
      if (e.reviewCount == 0) {
        score += 100;
      } else {
        // 距离上次回顾的天数
        final daysSinceReview = e.lastReviewedAt != null
            ? (now - e.lastReviewedAt!) / (1000 * 60 * 60 * 24)
            : 30;
        
        // 回顾次数越少，遗忘越快
        // 公式：天数 / (回顾次数 + 1) * 衰减因子
        score = daysSinceReview / (e.reviewCount + 1) * 10;
      }
      
      // 重要性加成
      score += e.importance * 5;
      
      return MapEntry(e, score);
    }).toList();
    
    // 按分数降序排序
    scored.sort((a, b) => b.value.compareTo(a.value));
    
    return scored.take(count).map((e) => e.key).toList();
  }

  /// 记录一次回顾
  Future<void> recordReview(String entryId) async {
    final entry = await getEntry(entryId);
    if (entry == null) return;
    
    entry.reviewCount += 1;
    entry.lastReviewedAt = DateTime.now().millisecondsSinceEpoch;
    
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });
    
    debugPrint('[KnowledgeEntryService] 记录回顾: $entryId (第${entry.reviewCount}次)');
  }

  /// 获取置顶条目
  Future<List<KnowledgeEntry>> getPinnedEntries() async {
    final isar = await _db.instance;
    return isar.knowledgeEntrys
        .filter()
        .isPinnedEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 切换置顶状态
  Future<void> togglePin(String entryId) async {
    final entry = await getEntry(entryId);
    if (entry == null) return;
    
    entry.isPinned = !entry.isPinned;
    entry.updatedAt = DateTime.now().millisecondsSinceEpoch;
    
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });
    
    debugPrint('[KnowledgeEntryService] 切换置顶: $entryId -> ${entry.isPinned}');
  }

  /// 更新重要性评分
  Future<void> updateImportance(String entryId, int importance) async {
    final entry = await getEntry(entryId);
    if (entry == null) return;
    
    entry.importance = importance.clamp(0, 5);
    entry.updatedAt = DateTime.now().millisecondsSinceEpoch;
    
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });
    
    debugPrint('[KnowledgeEntryService] 更新重要性: $entryId -> $importance');
  }

  // ==================== 更新操作 ====================

  /// 更新条目
  Future<void> updateEntry(KnowledgeEntry entry) async {
    entry.updatedAt = DateTime.now().millisecondsSinceEpoch;

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 更新条目: ${entry.entryId}');
  }

  /// 更新笔记内容
  Future<void> updateNoteContent({
    required String entryId,
    required String content,
    required String plainText,
    List<String>? tags,
  }) async {
    final entry = await getEntry(entryId);
    if (entry == null) return;

    entry.content = content;
    entry.plainText = plainText;
    entry.tags = tags ?? KnowledgeEntry.extractTags(plainText);
    entry.updatedAt = DateTime.now().millisecondsSinceEpoch;

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 更新笔记: $entryId');
  }

  /// 更新标注评论
  Future<void> updateComment({
    required String entryId,
    required String comment,
    List<String>? tags,
  }) async {
    final entry = await getEntry(entryId);
    if (entry == null) return;

    entry.content = comment;
    entry.plainText = comment;
    entry.tags = tags ?? KnowledgeEntry.extractTags(comment);
    entry.updatedAt = DateTime.now().millisecondsSinceEpoch;

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 更新评论: $entryId');
  }

  /// 更新高亮样式
  Future<void> updateStyle({
    required String entryId,
    required int color,
    String? styleType,
  }) async {
    final entry = await getEntry(entryId);
    if (entry == null) return;

    entry.color = color;
    if (styleType != null) entry.styleType = styleType;
    entry.updatedAt = DateTime.now().millisecondsSinceEpoch;

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 更新样式: $entryId');
  }

  /// 更新 Group 样式
  Future<void> updateStyleByGroupId({
    required String groupId,
    required int color,
    String? styleType,
  }) async {
    final isar = await _db.instance;
    final entries = await isar.knowledgeEntrys
        .filter()
        .groupIdEqualTo(groupId)
        .findAll();

    if (entries.isEmpty) return;

    for (final entry in entries) {
      entry.color = color;
      if (styleType != null) entry.styleType = styleType;
      entry.updatedAt = DateTime.now().millisecondsSinceEpoch;
    }

    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.putAll(entries);
    });

    debugPrint('[KnowledgeEntryService] 更新 Group 样式: $groupId');
  }

  /// 高亮升级为标注
  Future<void> upgradeToAnnotation({
    required String entryId,
    required String comment,
    List<String>? tags,
  }) async {
    final entry = await getEntry(entryId);
    if (entry == null) return;

    entry.upgradeToAnnotation(comment, tags: tags);

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 高亮升级为标注: $entryId');
  }

  /// 更新条目的 Block 信息（用于 Lazy Migration）
  Future<void> updateBlockInfo({
    required String entryId,
    required int blockIndex,
    required String blockContentHash,
    required int blockInternalStart,
    required int blockInternalEnd,
  }) async {
    final entry = await getEntry(entryId);
    if (entry == null) return;

    entry.blockIndex = blockIndex;
    entry.blockContentHash = blockContentHash;
    entry.blockInternalStart = blockInternalStart;
    entry.blockInternalEnd = blockInternalEnd;
    entry.updatedAt = DateTime.now().millisecondsSinceEpoch;

    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.put(entry);
    });

    debugPrint('[KnowledgeEntryService] 更新 Block 信息: $entryId');
  }

  // ==================== 删除操作 ====================

  /// 删除条目
  Future<void> deleteEntry(String entryId) async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.filter().entryIdEqualTo(entryId).deleteFirst();
    });

    debugPrint('[KnowledgeEntryService] 删除条目: $entryId');
  }

  /// 删除指定 group 的所有条目
  Future<void> deleteByGroupId(String groupId) async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys
          .filter()
          .groupIdEqualTo(groupId)
          .deleteAll();
    });

    debugPrint('[KnowledgeEntryService] 删除 Group 条目: $groupId');
  }

  /// 删除消息的所有条目
  Future<void> deleteByMessage(String messageId) async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.knowledgeEntrys
          .filter()
          .messageIdEqualTo(messageId)
          .deleteAll();
    });

    debugPrint('[KnowledgeEntryService] 删除消息条目: $messageId');
  }

  // ==================== 统计操作 ====================

  /// 获取总数
  Future<int> getCount() async {
    final isar = await _db.instance;
    return isar.knowledgeEntrys.count();
  }

  /// 按类型统计
  Future<Map<KnowledgeEntryType, int>> getCountByType() async {
    final entries = await getAllEntries();
    final counts = <KnowledgeEntryType, int>{
      KnowledgeEntryType.highlight: 0,
      KnowledgeEntryType.annotation: 0,
      KnowledgeEntryType.note: 0,
    };

    for (final entry in entries) {
      counts[entry.type] = (counts[entry.type] ?? 0) + 1;
    }

    return counts;
  }

  /// 获取所有标签
  Future<List<String>> getAllTags() async {
    final entries = await getAllEntries();
    final tags = <String>{};
    for (final entry in entries) {
      tags.addAll(entry.tags);
    }
    return tags.toList()..sort();
  }

  /// 获取标签统计
  Future<Map<String, int>> getTagStatistics() async {
    final entries = await getAllEntries();
    final stats = <String, int>{};
    for (final entry in entries) {
      for (final tag in entry.tags) {
        stats[tag] = (stats[tag] ?? 0) + 1;
      }
    }
    return stats;
  }

  // ==================== 监听操作 ====================

  /// 监听消息的条目变化
  Stream<List<KnowledgeEntry>> watchByMessage(String messageId) {
    return _db.instanceSync.knowledgeEntrys
        .filter()
        .messageIdEqualTo(messageId)
        .watch(fireImmediately: true);
  }

  /// 监听所有条目变化
  Stream<List<KnowledgeEntry>> watchAll() {
    return _db.instanceSync.knowledgeEntrys
        .filter()
        .entryIdIsNotEmpty()
        .watch(fireImmediately: true);
  }
}
