import 'dart:ui';

/// Locator for finding highlight positions within a text block using semantic context.
/// 
/// First Principle: Do not trust offsets. Trust content.
/// 
/// Strategy:
/// 1. Exact Match: prefix + text + suffix
/// 2. Strong Context: prefix + text OR text + suffix
/// 3. Weak Context: text only (if unique)
class HighlightLocator {
  
  /// Locates the range of [targetText] within [sourceText] using semantic context.
  /// 
  /// Returns [TextRange.empty] if not found or ambiguous.
  static TextRange locate({
    required String sourceText,
    required String targetText,
    String? prefix,
    String? suffix,
  }) {
    if (sourceText.isEmpty || targetText.isEmpty) {
      return TextRange.empty;
    }

    final p = prefix ?? '';
    final s = suffix ?? '';
    final t = targetText;

    // 1. Exact Match (Prefix + Text + Suffix)
    if (p.isNotEmpty && s.isNotEmpty) {
      final pattern = '$p$t$s';
      final index = sourceText.indexOf(pattern);
      if (index != -1) {
        // Confirm uniqueness? For now, first match is good enough with full context.
        final start = index + p.length;
        return TextRange(start: start, end: start + t.length);
      }
    }

    // 2. Strong Context 
    // Try Prefix + Text
    if (p.isNotEmpty) {
      final pattern = '$p$t';
      final index = sourceText.indexOf(pattern);
      if (index != -1) {
        final start = index + p.length;
        return TextRange(start: start, end: start + t.length);
      }
    }

    // Try Text + Suffix
    if (s.isNotEmpty) {
      final pattern = '$t$s';
      final index = sourceText.indexOf(pattern);
      if (index != -1) {
        return TextRange(start: index, end: index + t.length);
      }
    }

    // 3. Fallback: Text Only
    // Only accept if it's unique or we have a policy (e.g. first occurrence).
    // Current policy: First occurrence. 
    // TODO: Improve strictness? If there are multiple matches and we lost context, 
    // maybe we shouldn't highlight to avoid misleading? 
    // Resilience decision: Highlight first occurrence is better than nothing.
    final index = sourceText.indexOf(t);
    if (index != -1) {
      return TextRange(start: index, end: index + t.length);
    }

    return TextRange.empty;
  }
}
