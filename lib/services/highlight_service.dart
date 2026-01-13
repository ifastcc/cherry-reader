import 'package:flutter/material.dart';
import '../models/highlight_data.dart';
import '../models/isar/knowledge_entry.dart';
import 'knowledge_entry_service.dart';

/// 统一的标注管理服务
///
/// 重构说明：
/// - 使用 KnowledgeEntry 作为底层存储（统一知识条目）
/// - 保持原有 HighlightData 接口不变（向后兼容）
/// - 内存缓存 + 数据库持久化双层架构
class HighlightService {
  static final HighlightService _instance = HighlightService._internal();
  factory HighlightService() => _instance;
  HighlightService._internal();

  final KnowledgeEntryService _entryService = KnowledgeEntryService();

  /// 内存缓存（第一层缓存）
  final Map<String, List<HighlightData>> _cache = {};

  // ============ 核心功能 ============

  /// 批量预加载多个消息的标注（性能优化关键）
  ///
  /// 用法：在进入对话页面时，一次性加载所有消息的标注
  /// ```dart
  /// await highlightService.batchPreload(['msg1', 'msg2', 'msg3']);
  /// ```
  Future<void> batchPreload(List<String> messageIds) async {
    if (messageIds.isEmpty) return;

    // 为每个消息 ID 加载高亮
    for (final messageId in messageIds) {
      if (!_cache.containsKey(messageId)) {
        final entries = await _entryService.getByMessage(messageId);
        // 只取高亮类型（type == highlight）
        final highlights = entries
            .where((e) => e.type == KnowledgeEntryType.highlight)
            .map(_entryToData)
            .toList();
        _cache[messageId] = highlights;
      }
    }
  }

  /// 加载指定消息的标注
  Future<List<HighlightData>> loadHighlights(String messageId) async {
    if (messageId.isEmpty) return [];

    // 检查内存缓存
    if (_cache.containsKey(messageId)) {
      return List.from(_cache[messageId]!);
    }

    // 从数据库加载
    final entries = await _entryService.getByMessage(messageId);
    // 只取高亮类型
    final highlights = entries
        .where((e) => e.type == KnowledgeEntryType.highlight)
        .map(_entryToData)
        .toList();

    // 更新缓存
    _cache[messageId] = highlights;

    return highlights;
  }

  /// 保存标注（替换消息的所有高亮）
  Future<void> saveHighlights(
    String messageId,
    List<HighlightData> highlights, {
    String? topicId,
    String? topicName,
  }) async {
    if (messageId.isEmpty) return;

    // 先获取该消息的所有高亮条目
    final existingEntries = await _entryService.getByMessage(messageId);
    final existingHighlights = existingEntries
        .where((e) => e.type == KnowledgeEntryType.highlight)
        .toList();

    // 删除所有现有高亮
    for (final entry in existingHighlights) {
      await _entryService.deleteEntry(entry.entryId);
    }

    // 创建新高亮
    for (final h in highlights) {
      await _entryService.createHighlight(
        messageId: messageId,
        quotedText: h.text,
        start: h.start,
        end: h.end,
        color: h.color,
        styleType: h.styleType,
        topicId: topicId,
        topicName: topicName,
        prefix: h.prefix,
        suffix: h.suffix,
        blockIndex: h.blockIndex,
        blockContentHash: h.blockContentHash,
        blockInternalStart: h.blockInternalStart,
        blockInternalEnd: h.blockInternalEnd,
        groupId: h.groupId,
      );
    }

    // 更新缓存
    _cache[messageId] = List.from(highlights);

    debugPrint('[HighlightService] 保存 ${highlights.length} 个标注: $messageId');
  }

  /// 【新架构】添加高亮 - 一次选择 = 一条记录
  Future<List<HighlightData>> addHighlight(
    String messageId,
    HighlightData highlight, {
    String? topicId,
    String? topicName,
  }) async {
    // 【Bug Fix】检查是否已存在相同范围的高亮（内容去重）
    final existingHighlights = await loadHighlights(messageId);
    final isDuplicate = existingHighlights.any((h) => 
      h.start == highlight.start && 
      h.end == highlight.end && 
      h.text == highlight.text
    );
    
    if (isDuplicate) {
      debugPrint('[HighlightService] 跳过重复高亮: ${highlight.text.substring(0, highlight.text.length.clamp(0, 20))}...');
      return existingHighlights;
    }
    
    // 【新架构】创建单条高亮记录，包含 selections
    final entry = await _entryService.createHighlight(
      messageId: messageId,
      quotedText: highlight.text,
      start: highlight.start,
      end: highlight.end,
      color: highlight.color,
      styleType: highlight.styleType,
      topicId: topicId,
      topicName: topicName,
      prefix: highlight.prefix,
      suffix: highlight.suffix,
      blockIndex: highlight.blockIndex,
      blockContentHash: highlight.blockContentHash,
      blockInternalStart: highlight.blockInternalStart,
      blockInternalEnd: highlight.blockInternalEnd,
      selections: highlight.selections,  // 【新架构】传递 selections
    );

    // 更新缓存
    _cache.remove(messageId);  // 清除缓存强制重新加载
    return loadHighlights(messageId);
  }

  /// @deprecated 已废弃 - 新架构不需要 groupId
  @Deprecated('新架构不再使用 groupId，直接使用 removeHighlight')
  Future<List<HighlightData>> removeHighlightGroup(
    String messageId,
    String groupId,
  ) async {
    // 向后兼容：仍然支持旧数据
    await _entryService.deleteByGroupId(groupId);
    _cache.remove(messageId);
    return loadHighlights(messageId);
  }

  /// 删除标注
  Future<List<HighlightData>> removeHighlight(
    String messageId,
    String highlightId,
  ) async {
    // 从数据库删除
    await _entryService.deleteEntry(highlightId);

    // 更新缓存
    final highlights = await loadHighlights(messageId);
    highlights.removeWhere((h) => h.id == highlightId);
    _cache[messageId] = highlights;

    return highlights;
  }

  /// 更新标注样式
  Future<List<HighlightData>> updateHighlightStyle(
    String messageId,
    String highlightId,
    int newColor,
    String newStyleType,
  ) async {
    // 更新数据库
    await _entryService.updateStyle(
      entryId: highlightId,
      color: newColor,
      styleType: newStyleType,
    );

    // 清除缓存，强制重新加载
    _cache.remove(messageId);
    return loadHighlights(messageId);
  }

  /// @deprecated 已废弃 - 新架构不需要 groupId
  @Deprecated('新架构不再使用 groupId，直接使用 updateHighlightStyle')
  Future<List<HighlightData>> updateHighlightGroupStyle(
    String messageId,
    String groupId,
    int newColor,
    String newStyleType,
  ) async {
    // 向后兼容
    await _entryService.updateStyleByGroupId(
      groupId: groupId,
      color: newColor,
      styleType: newStyleType,
    );
    _cache.remove(messageId);
    return loadHighlights(messageId);
  }

  /// 更新高亮 Block 信息 (Granular Update for Lazy Migration)
  Future<List<HighlightData>> updateHighlightBlockInfo(
    String messageId,
    String highlightId, {
    required int blockIndex,
    required String blockContentHash,
    required int blockInternalStart,
    required int blockInternalEnd,
  }) async {
    await _entryService.updateBlockInfo(
      entryId: highlightId,
      blockIndex: blockIndex,
      blockContentHash: blockContentHash,
      blockInternalStart: blockInternalStart,
      blockInternalEnd: blockInternalEnd,
    );

    // 清除缓存
    _cache.remove(messageId);
    return loadHighlights(messageId);
  }

  /// 清除指定消息的所有标注
  Future<void> clearHighlights(String messageId) async {
    if (messageId.isEmpty) return;

    await _entryService.deleteByMessage(messageId);
    _cache.remove(messageId);

    debugPrint('[HighlightService] 清除标注: $messageId');
  }

  /// 清除缓存（用于强制刷新）
  void clearCache([String? messageId]) {
    if (messageId != null) {
      _cache.remove(messageId);
    } else {
      _cache.clear();
    }
  }

  /// 强制从数据库重新加载（跳过缓存）
  Future<List<HighlightData>> reloadHighlights(String messageId) async {
    _cache.remove(messageId);
    return loadHighlights(messageId);
  }

  /// 监听标注变化（实时响应式更新）
  ///
  /// 返回 Stream，可用于 StreamBuilder
  Stream<List<HighlightData>> watchHighlights(String messageId) {
    return _entryService.watchByMessage(messageId).map(
      (entries) => entries
          .where((e) => e.type == KnowledgeEntryType.highlight)
          .map(_entryToData)
          .toList(),
    );
  }

  // ============ 私有辅助方法 ============

  /// 【新架构】KnowledgeEntry 转 HighlightData
  HighlightData _entryToData(KnowledgeEntry entry) {
    return HighlightData(
      id: entry.entryId,
      text: entry.quotedText ?? '',
      start: entry.start ?? 0,
      end: entry.end ?? 0,
      color: entry.color ?? 0xFFFFF176,
      styleType: entry.styleType ?? 'background',
      prefix: entry.prefix,
      suffix: entry.suffix,
      blockIndex: entry.blockIndex,
      blockContentHash: entry.blockContentHash,
      blockInternalStart: entry.blockInternalStart,
      blockInternalEnd: entry.blockInternalEnd,
      groupId: entry.groupId,
      selections: entry.selectionRanges.isNotEmpty ? entry.selectionRanges : null,  // 【新架构】解析 selections
      createdAt: DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
    );
  }
}
