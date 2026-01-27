import '../models/highlight_data.dart';
import 'package:gpt_markdown_custom/markdown_parse_result.dart'; // For BlockInfo
import 'package:gpt_markdown_custom/v2/highlight_locator.dart';

/// 高亮恢复服务
/// 
/// 实现多级恢复策略，确保高亮即使在文档发生变化时也能正确定位：
/// 
/// 1. **Fast Path**: 直接使用存储的 (start, end) 偏移，验证文本匹配
/// 2. **Robust Path**: 使用 prefix + text + suffix 上下文搜索定位
/// 3. **Fallback**: 模糊匹配 text
/// 
/// 【性能优化】
/// - 缓存恢复结果，避免重复搜索
/// - 同一 plainText 下的恢复结果会被缓存
class HighlightRecoveryService {
  
  /// 【性能优化】恢复结果缓存
  /// Key: "${highlightId}_${plainText.hashCode}"
  /// Value: 恢复后的 HighlightData
  final Map<String, HighlightData> _recoveryCache = {};
  
  /// 缓存的 plainText hash，用于判断是否需要清除缓存
  int? _lastPlainTextHash;
  
  /// 尝试恢复/修正高亮位置（带缓存）
  /// 
  /// [highlight] 原始高亮数据
  /// [plainText] 当前文档的规范化纯文本
  /// [registry] 当前文档的 Block Registry (可选, 用于 Block-Based Recovery)
  /// 
  /// 返回位置修正后的 HighlightData（可能与输入相同）
  HighlightData recover(HighlightData highlight, String plainText, {List<BlockInfo>? registry}) {
    // 边界检查
    if (plainText.isEmpty) {
      return highlight;
    }
    
    // 【性能优化】检查缓存
    final plainTextHash = plainText.hashCode;
    
    // 如果 plainText 变化，清空缓存
    if (_lastPlainTextHash != plainTextHash) {
      _recoveryCache.clear();
      _lastPlainTextHash = plainTextHash;
    }
    
    // 检查缓存命中
    final cacheKey = '${highlight.id}_$plainTextHash';
    if (_recoveryCache.containsKey(cacheKey)) {
      return _recoveryCache[cacheKey]!;
    }
    
    // 执行恢复逻辑
    final result = _doRecover(highlight, plainText, registry: registry);
    
    // 缓存结果
    _recoveryCache[cacheKey] = result;
    
    return result;
  }
  
  /// 批量恢复（性能优化版本）
  List<HighlightData> recoverBatch(List<HighlightData> highlights, String plainText) {
    if (plainText.isEmpty || highlights.isEmpty) {
      return highlights;
    }
    
    // 预热缓存
    final plainTextHash = plainText.hashCode;
    if (_lastPlainTextHash != plainTextHash) {
      _recoveryCache.clear();
      _lastPlainTextHash = plainTextHash;
    }
    
    return highlights.map((h) => recover(h, plainText)).toList();
  }
  
  /// 清除缓存
  void clearCache() {
    _recoveryCache.clear();
    _lastPlainTextHash = null;
  }
  
  /// 实际的恢复逻辑
  HighlightData _doRecover(HighlightData highlight, String plainText, {List<BlockInfo>? registry}) {
    
    // ============================================
    // Strategy 1: Block-Based Semantic Match (Highest Confidence)
    // ============================================
    if (registry != null && highlight.ranges.isNotEmpty) {
      final recovered = _recoverBySingleRange(
        highlight: highlight,
        plainText: plainText,
        registry: registry,
      );
      if (recovered != null) return recovered;
    }
    if (registry != null && highlight.ranges.isEmpty) {
      if (_validateOffset(highlight, plainText)) {
        final derived = _deriveSingleRangeFromGlobal(
          start: highlight.start,
          end: highlight.end,
          text: highlight.text,
          registry: registry,
        );
        if (derived != null) {
          return highlight.copyWith(ranges: [derived]);
        }
      }
    }

    // ============================================
    // Strategy 2: HighlightLocator Semantic Search (High Confidence)
    // ============================================
    // Logic: If block index failed (block edited or deleted), we search globally using context.
    final contextResult = _searchByContext(highlight, plainText);
    if (contextResult != null) {
       final derived = registry == null
           ? null
           : _deriveSingleRangeFromGlobal(
               start: contextResult.start,
               end: contextResult.end,
               text: highlight.text,
               registry: registry,
             );
       return highlight.copyWith(
         start: contextResult.start,
         end: contextResult.end,
         ranges: derived != null ? [derived] : highlight.ranges,
       );
    }
  
    // ============================================
    // Strategy 3: Global Offset Strict Fallback (Low Confidence)
    // ============================================
    // Logic: If semantic lookup failed, we check the original global offsets.
    // CRITICAL CHANGE: We only return this if the text MATCHES. 
    // If text does not match, we return the original data (which might be invalid) 
    // OR we could return a "broken" flag. For now, we return original but it won't be rendered 
    // if the renderer checks text.
    if (_validateOffset(highlight, plainText)) {
      return highlight;
    }

    // If strictly validating, we might want to return "invalid" here?
    // Current behavior: Return original. The Renderer/Card might filter it out if text mismatch?
    // Actually, HighlightableCard renders based on these offsets. 
    // If they point to wrong text, it looks bad.
    // IMPROVEMENT: If we are here, it means:
    // 1. Block match failed.
    // 2. Semantic/Locator search failed.
    // 3. Global offset text mismatch.
    // Conclusion: The highlight is effectively LOST or Broken.
    // It's better to show nothing than wrong thing? 
    // For now, let's keep legacy behavior (return original) but log a warning.
    // Or, we can use Fuzzy Search as a last ditch effort?
    
    final fuzzyResult = _fuzzySearch(highlight.text, plainText);
    if (fuzzyResult != null) {
       final derived = registry == null
           ? null
           : _deriveSingleRangeFromGlobal(
               start: fuzzyResult.start,
               end: fuzzyResult.end,
               text: highlight.text,
               registry: registry,
             );
       return highlight.copyWith(
         start: fuzzyResult.start,
         end: fuzzyResult.end,
         ranges: derived != null ? [derived] : highlight.ranges,
       );
    }
    
    // Truly lost.
    return highlight;
  }

  HighlightData? _recoverBySingleRange({
    required HighlightData highlight,
    required String plainText,
    required List<BlockInfo> registry,
  }) {
    final range = highlight.ranges.first;
    final byIndex = _matchRangeInBlock(
      highlight: highlight,
      range: range,
      plainText: plainText,
      registry: registry,
      onlyBlockIndex: range.blockIndex,
    );
    if (byIndex != null) return byIndex;

    final byScan = _matchRangeInBlock(
      highlight: highlight,
      range: range,
      plainText: plainText,
      registry: registry,
      onlyBlockIndex: null,
    );
    return byScan;
  }

  HighlightData? _matchRangeInBlock({
    required HighlightData highlight,
    required HighlightRange range,
    required String plainText,
    required List<BlockInfo> registry,
    required int? onlyBlockIndex,
  }) {
    for (final b in registry) {
      if (onlyBlockIndex != null && b.index != onlyBlockIndex) continue;
      final base = (b.globalStart as num).toInt();
      final newGlobalStart = base + range.start;
      final newGlobalEnd = base + range.end;
      if (newGlobalStart < 0 || newGlobalEnd > plainText.length) continue;
      if (newGlobalStart >= newGlobalEnd) continue;
      final actualText = plainText.substring(newGlobalStart, newGlobalEnd);
      final expectedText = range.text.isNotEmpty ? range.text : highlight.text;
      if (expectedText.isNotEmpty && actualText != expectedText) continue;

      final updatedRange = HighlightRange(
        blockIndex: b.index,
        start: range.start,
        end: range.end,
        text: expectedText,
      );
      return highlight.copyWith(
        start: newGlobalStart,
        end: newGlobalEnd,
        ranges: [updatedRange],
      );
    }
    return null;
  }

  HighlightRange? _deriveSingleRangeFromGlobal({
    required int start,
    required int end,
    required String text,
    required List<BlockInfo> registry,
  }) {
    for (final b in registry) {
      final base = (b.globalStart as num).toInt();
      final blockEnd = (b.globalEnd as num).toInt();
      if (start < base || end > blockEnd) continue;
      final localStart = start - base;
      final localEnd = end - base;
      if (localStart < 0 || localEnd < 0 || localStart >= localEnd) continue;
      return HighlightRange(
        blockIndex: b.index,
        start: localStart,
        end: localEnd,
        text: text,
      );
    }
    return null;
  }

  /// Fast Path: 验证原始偏移是否有效
  bool _validateOffset(HighlightData highlight, String plainText) {
    // 检查边界
    if (highlight.start < 0 || highlight.end > plainText.length) {
      return false;
    }
    if (highlight.start >= highlight.end) {
      return false;
    }
    
    // 验证文本匹配
    final actualText = plainText.substring(highlight.start, highlight.end);
    return actualText == highlight.text;
  }

  /// Robust Path: 使用上下文搜索 (Delegate to HighlightLocator)
  _MatchResult? _searchByContext(HighlightData highlight, String plainText) {
    if (highlight.text.isEmpty) return null;

    final range = HighlightLocator.locate(
      sourceText: plainText,
      targetText: highlight.text,
      prefix: highlight.prefix,
      suffix: highlight.suffix,
    );

    if (range.isValid) {
      return _MatchResult(range.start, range.end);
    }
    return null;
  }

  /// Fallback: 模糊搜索 (Delegate to HighlightLocator fallback logic or simple search)
  _MatchResult? _fuzzySearch(String text, String plainText) {
    // HighlightLocator already handles text-only fallback.
    // We can reuse it or keep simple logic here.
    // For consistency, let's use Locator with no context.
    final range = HighlightLocator.locate(
      sourceText: plainText,
      targetText: text,
    );

    if (range.isValid) {
      return _MatchResult(range.start, range.end);
    }
    
    // Legacy trimmed search (if Locator is too strict)
    // Locator (Phase 2) is strict about spaces for now. 
    // Let's keep the trim fallback as a "last resort".
    final trimmedText = text.trim();
    if (trimmedText != text && trimmedText.isNotEmpty) {
      final trimmedIndex = plainText.indexOf(trimmedText);
      if (trimmedIndex != -1) {
        return _MatchResult(trimmedIndex, trimmedIndex + trimmedText.length);
      }
    }
    
    return null;
  }
}

/// 匹配结果
class _MatchResult {
  final int start;
  final int end;
  
  _MatchResult(this.start, this.end);
}
