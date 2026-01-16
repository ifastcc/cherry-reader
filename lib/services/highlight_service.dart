import 'package:flutter/material.dart';
import '../models/highlight_data.dart';
import '../models/isar/knowledge_entry.dart';
import 'knowledge_entry_service.dart';

/// 统一的标注管理服务（v3.0）
///
/// 重构说明：
/// - 使用 KnowledgeEntry 作为底层存储
/// - 使用 HighlightData v3.0 格式（color: String, style, ranges）
/// - 内存缓存 + 数据库持久化双层架构
class HighlightService {
  static final HighlightService _instance = HighlightService._internal();
  factory HighlightService() => _instance;
  HighlightService._internal();

  final KnowledgeEntryService _entryService = KnowledgeEntryService();

  /// 内存缓存（第一层缓存）
  final Map<String, List<HighlightData>> _cache = {};

  // ============ 核心功能 ============

  /// 批量预加载多个消息的标注
  Future<void> batchPreload(List<String> messageIds) async {
    if (messageIds.isEmpty) return;

    for (final messageId in messageIds) {
      if (!_cache.containsKey(messageId)) {
        final entries = await _entryService.getByMessage(messageId);
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

    if (_cache.containsKey(messageId)) {
      return List.from(_cache[messageId]!);
    }

    final entries = await _entryService.getByMessage(messageId);
    final highlights = entries
        .where((e) => e.type == KnowledgeEntryType.highlight)
        .map(_entryToData)
        .toList();

    _cache[messageId] = highlights;
    return highlights;
  }

  /// 【v3.0】添加高亮
  Future<List<HighlightData>> addHighlight(
    String messageId,
    HighlightData highlight, {
    String? topicId,
    String? topicName,
  }) async {
    // 检查重复（基于 ranges）
    final existingHighlights = await loadHighlights(messageId);
    final isDuplicate = existingHighlights.any((h) =>
        h.text == highlight.text &&
        h.ranges.length == highlight.ranges.length);

    if (isDuplicate) {
      debugPrint(
          '[HighlightService] 跳过重复高亮: ${highlight.text.substring(0, highlight.text.length.clamp(0, 20))}...');
      return existingHighlights;
    }

    // 转换颜色格式并创建
    final colorInt = HighlightData.hexColorToInt(highlight.color);

    await _entryService.createHighlight(
      messageId: messageId,
      quotedText: highlight.text,
      start: 0, // v3.0 不再使用全局偏移
      end: 0,
      color: colorInt,
      styleType: highlight.style,
      topicId: topicId,
      topicName: topicName,
      prefix: highlight.prefix,
      suffix: highlight.suffix,
      // 使用第一个 range 的信息（兼容旧数据库字段）
      blockIndex: highlight.ranges.isNotEmpty ? highlight.ranges.first.blockIndex : null,
      blockInternalStart: highlight.ranges.isNotEmpty ? highlight.ranges.first.start : null,
      blockInternalEnd: highlight.ranges.isNotEmpty ? highlight.ranges.first.end : null,
      // 存储完整 ranges
      selections: highlight.ranges.isNotEmpty
          ? highlight.ranges.map((r) => SelectionRange(
                blockIndex: r.blockIndex,
                start: r.start,
                end: r.end,
                text: r.text,
              )).toList()
          : null,
    );

    _cache.remove(messageId);
    return loadHighlights(messageId);
  }

  /// 删除标注
  Future<List<HighlightData>> removeHighlight(
    String messageId,
    String highlightId,
  ) async {
    await _entryService.deleteEntry(highlightId);

    final highlights = await loadHighlights(messageId);
    highlights.removeWhere((h) => h.id == highlightId);
    _cache[messageId] = highlights;

    return highlights;
  }

  /// 【v3.0】更新标注样式
  Future<List<HighlightData>> updateHighlightStyle(
    String messageId,
    String highlightId,
    String newColor,
    String newStyle,
  ) async {
    final colorInt = HighlightData.hexColorToInt(newColor);

    await _entryService.updateStyle(
      entryId: highlightId,
      color: colorInt,
      styleType: newStyle,
    );

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

  /// 清除缓存
  void clearCache([String? messageId]) {
    if (messageId != null) {
      _cache.remove(messageId);
    } else {
      _cache.clear();
    }
  }

  /// 强制从数据库重新加载
  Future<List<HighlightData>> reloadHighlights(String messageId) async {
    _cache.remove(messageId);
    return loadHighlights(messageId);
  }

  /// 监听标注变化
  Stream<List<HighlightData>> watchHighlights(String messageId) {
    return _entryService.watchByMessage(messageId).map(
          (entries) => entries
              .where((e) => e.type == KnowledgeEntryType.highlight)
              .map(_entryToData)
              .toList(),
        );
  }

  // ============ 私有辅助方法 ============

  /// 【v3.0】KnowledgeEntry 转 HighlightData
  HighlightData _entryToData(KnowledgeEntry entry) {
    // 颜色格式转换
    final colorStr = HighlightData.intColorToHex(entry.color ?? 0xFFFFF176);

    // 构建 ranges
    final ranges = entry.selectionRanges.map((r) => HighlightRange(
          blockIndex: r.blockIndex,
          start: r.start,
          end: r.end,
          text: r.text,
        )).toList();

    return HighlightData(
      id: entry.entryId,
      messageId: entry.messageId ?? '',
      text: entry.quotedText ?? '',
      color: colorStr,
      style: entry.styleType ?? 'background',
      ranges: ranges,
      prefix: entry.prefix ?? '',
      suffix: entry.suffix ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
    );
  }
}
