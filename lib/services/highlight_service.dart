import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/highlight_data.dart';

/// 统一的标注管理服务
///
/// 提供标注的加载、保存、增删改等功能
/// 所有需要标注功能的组件都应该使用这个服务
class HighlightService {
  static final HighlightService _instance = HighlightService._internal();
  factory HighlightService() => _instance;
  HighlightService._internal();

  /// 缓存已加载的标注数据，避免重复读取
  final Map<String, List<HighlightData>> _cache = {};

  /// 加载指定消息的标注
  Future<List<HighlightData>> loadHighlights(String messageId) async {
    if (messageId.isEmpty) return [];

    // 检查缓存
    if (_cache.containsKey(messageId)) {
      debugPrint('[HighlightService] Using cached highlights for: $messageId');
      return List.from(_cache[messageId]!);
    }

    final prefs = await SharedPreferences.getInstance();
    final key = 'highlights_$messageId';
    final data = prefs.getString(key);

    debugPrint('[HighlightService] Loading highlights for key: $key');

    if (data != null) {
      try {
        final List<dynamic> jsonList = json.decode(data);
        final highlights = jsonList.map((e) => HighlightData.fromJson(e)).toList();
        _cache[messageId] = highlights;
        debugPrint('[HighlightService] ✅ Loaded ${highlights.length} highlights');
        return highlights;
      } catch (e) {
        debugPrint('[HighlightService] ❌ Error loading highlights: $e');
        return [];
      }
    }

    debugPrint('[HighlightService] No highlights found');
    return [];
  }

  /// 保存标注
  Future<void> saveHighlights(String messageId, List<HighlightData> highlights) async {
    if (messageId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'highlights_$messageId';
    final data = json.encode(highlights.map((e) => e.toJson()).toList());
    await prefs.setString(key, data);

    // 更新缓存
    _cache[messageId] = List.from(highlights);

    debugPrint('[HighlightService] ✅ Saved ${highlights.length} highlights to key: $key');
  }

  /// 添加标注
  Future<List<HighlightData>> addHighlight(
    String messageId,
    HighlightData highlight,
  ) async {
    final highlights = await loadHighlights(messageId);
    highlights.add(highlight);
    await saveHighlights(messageId, highlights);
    return highlights;
  }

  /// 删除标注
  Future<List<HighlightData>> removeHighlight(
    String messageId,
    String highlightId,
  ) async {
    final highlights = await loadHighlights(messageId);
    highlights.removeWhere((h) => h.id == highlightId);
    await saveHighlights(messageId, highlights);
    return highlights;
  }

  /// 更新标注样式
  Future<List<HighlightData>> updateHighlightStyle(
    String messageId,
    String highlightId,
    int newColor,
    String newStyleType,
  ) async {
    final highlights = await loadHighlights(messageId);
    final index = highlights.indexWhere((h) => h.id == highlightId);

    if (index != -1) {
      final old = highlights[index];
      highlights[index] = HighlightData(
        id: old.id,
        text: old.text,
        start: old.start,
        end: old.end,
        color: newColor,
        styleType: newStyleType,
        createdAt: old.createdAt,
      );
      await saveHighlights(messageId, highlights);
    }

    return highlights;
  }

  /// 清除指定消息的所有标注
  Future<void> clearHighlights(String messageId) async {
    if (messageId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'highlights_$messageId';
    await prefs.remove(key);

    // 清除缓存
    _cache.remove(messageId);

    debugPrint('[HighlightService] Cleared highlights for: $messageId');
  }

  /// 清除缓存（用于强制刷新）
  void clearCache([String? messageId]) {
    if (messageId != null) {
      _cache.remove(messageId);
    } else {
      _cache.clear();
    }
  }

  /// 强制从存储重新加载（跳过缓存）
  Future<List<HighlightData>> reloadHighlights(String messageId) async {
    _cache.remove(messageId);
    return loadHighlights(messageId);
  }
}
