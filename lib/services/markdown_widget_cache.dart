import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Markdown Widget 缓存服务
/// 
/// 使用 LRU 策略缓存已构建的 Markdown Widget，
/// 避免重复构建相同内容，提升翻页和滚动性能。
class MarkdownWidgetCache {
  static final instance = MarkdownWidgetCache._();
  MarkdownWidgetCache._();
  
  /// LRU 缓存 (使用 LinkedHashMap 保持插入顺序)
  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();
  
  /// 最大缓存数量
  static const int _maxSize = 50;
  
  /// 缓存命中统计
  int _hitCount = 0;
  int _missCount = 0;
  
  /// 获取缓存的 Widget，如果不存在则使用 builder 创建
  /// 
  /// [key] 缓存键（通常是 messageId）
  /// [contentHash] 内容 hash（用于验证缓存有效性）
  /// [builder] 构建函数（缓存未命中时调用）
  Widget getOrBuild({
    required String key,
    required int contentHash,
    required Widget Function() builder,
  }) {
    final entry = _cache[key];
    
    if (entry != null && entry.contentHash == contentHash) {
      // 缓存命中：移到末尾（LRU）
      _cache.remove(key);
      _cache[key] = entry;
      _hitCount++;
      return entry.widget;
    }
    
    // 缓存未命中：构建新 Widget
    _missCount++;
    final widget = builder();
    _put(key, contentHash, widget);
    return widget;
  }
  
  /// 检查缓存是否存在
  bool contains(String key, int contentHash) {
    final entry = _cache[key];
    return entry != null && entry.contentHash == contentHash;
  }
  
  /// 预构建 Widget（在空闲时执行）
  /// 
  /// 用于页面加载后异步预热缓存
  Future<void> prebuildInIdle({
    required String key,
    required int contentHash,
    required Widget Function() builder,
  }) async {
    if (contains(key, contentHash)) return;
    
    // 在空闲时段构建
    await SchedulerBinding.instance.scheduleTask(() {
      if (!contains(key, contentHash)) {
        final widget = builder();
        _put(key, contentHash, widget);
      }
      return null;
    }, Priority.idle);
  }
  
  /// 批量预构建
  Future<void> batchPrebuild(
    List<({String key, int contentHash, Widget Function() builder})> items,
  ) async {
    for (final item in items) {
      if (!contains(item.key, item.contentHash)) {
        await prebuildInIdle(
          key: item.key,
          contentHash: item.contentHash,
          builder: item.builder,
        );
      }
    }
  }
  
  /// 移除指定缓存
  void remove(String key) {
    _cache.remove(key);
  }
  
  /// 清空所有缓存
  void clear() {
    _cache.clear();
    _hitCount = 0;
    _missCount = 0;
  }
  
  /// 获取缓存统计信息
  String get stats {
    final total = _hitCount + _missCount;
    final hitRate = total > 0 ? (_hitCount / total * 100).toStringAsFixed(1) : '0.0';
    return 'size: ${_cache.length}/$_maxSize, hit: $_hitCount, miss: $_missCount, rate: $hitRate%';
  }
  
  /// 内部：添加缓存项
  void _put(String key, int contentHash, Widget widget) {
    // LRU 淘汰
    while (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = _CacheEntry(contentHash: contentHash, widget: widget);
  }
}

/// 缓存条目
class _CacheEntry {
  final int contentHash;
  final Widget widget;
  
  const _CacheEntry({
    required this.contentHash,
    required this.widget,
  });
}
