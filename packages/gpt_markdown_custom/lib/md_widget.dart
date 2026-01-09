import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'custom_widgets/markdown_config.dart';
import 'markdown_component.dart';

/// It creates a markdown widget closed to each other.
class MdWidget extends StatefulWidget {
  const MdWidget(
    this.context,
    this.exp,
    this.includeGlobalComponents, {
    super.key,
    required this.config,
  });

  /// The expression to be displayed.
  final String exp;
  final BuildContext context;

  /// Whether to include global components.
  final bool includeGlobalComponents;

  /// The configuration of the markdown widget.
  final GptMarkdownConfig config;

  @override
  State<MdWidget> createState() => _MdWidgetState();
}

class _MdWidgetState extends State<MdWidget> {
  List<InlineSpan> list = [];
  @override
  void initState() {
    super.initState();
    list = MarkdownComponent.generate(
      widget.context,
      widget.exp,
      widget.config,
      widget.includeGlobalComponents,
    );
  }

  @override
  void didUpdateWidget(covariant MdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exp != widget.exp ||
        !oldWidget.config.isSame(widget.config)) {
      list = MarkdownComponent.generate(
        context,
        widget.exp,
        widget.config,
        widget.includeGlobalComponents,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply highlight ranges if configured
    List<InlineSpan> processedList = list;
    final highlightRanges = widget.config.highlightRanges;
    if (highlightRanges != null && highlightRanges.isNotEmpty) {
      processedList = _applyHighlightRanges(list, highlightRanges);
    }

    return widget.config.getRich(
      TextSpan(children: processedList, style: widget.config.style?.copyWith()),
    );
  }

  /// Apply highlight ranges to the TextSpan list.
  ///
  /// This method traverses the spans, calculates global character offsets,
  /// and applies highlight styles to matching text ranges.
  List<InlineSpan> _applyHighlightRanges(
    List<InlineSpan> spans,
    List<HighlightRangeData> ranges,
  ) {
    if (ranges.isEmpty) return spans;

    // 1. Flatten spans to build the full plain text context
    // This allows us to search for text matches within the actually rendered content
    final flattenedSpans = <_SpanWithOffset>[];
    final buffer = StringBuffer();
    _flattenSpans(spans, flattenedSpans, 0, (offset) => offset);
    
    // Build full text from flattened spans to ensure 1:1 mapping
    for (var item in flattenedSpans) {
      if (item.span is TextSpan && (item.span as TextSpan).text != null) {
        buffer.write((item.span as TextSpan).text);
      } else if (item.span is WidgetSpan) {
        // WidgetSpan counts as 1 placeholder char
        buffer.write('\uFFFC'); 
      }
    }
    final fullText = buffer.toString();

    // 2. Calibrate ranges
    // Instead of blindly trusting the input indices, we search for the text 
    // in the rendered fullText to find the actually render-time indices.
    final calibratedRanges = <HighlightRangeData>[];

    for (var range in ranges) {
      if (range.text != null && range.text!.isNotEmpty) {
         // Strategy: Search for all occurrences of text in fullText
         // and pick the one closest to range.start (scaled if needed, but here 1:1)
         
         final matches = range.text!.allMatches(fullText);
         if (matches.isEmpty) {
            // Fallback: try trimmed
             final trimmed = range.text!.trim();
              if (trimmed.isNotEmpty) {
                 final matchesTrimmed = trimmed.allMatches(fullText);
                 if (matchesTrimmed.isNotEmpty) {
                    // Found trimmed match
                    calibratedRanges.add(_findClosestMatch(matchesTrimmed, range, fullText));
                    continue;
                 }
              }
             
             // If still no match, fallback to original indices (might be wrong but better than nothing)
             calibratedRanges.add(range);
         } else {
             // Found exact matches
             calibratedRanges.add(_findClosestMatch(matches, range, fullText));
         }
      } else {
         // Legacy mode: trust indices
         calibratedRanges.add(range);
      }
    }
    
    // Sort ranges by start position
    calibratedRanges.sort((a, b) => a.start.compareTo(b.start));

    // 3. Apply ranges
    final result = <InlineSpan>[];

    for (final item in flattenedSpans) {
      if (item.span is! TextSpan || (item.span as TextSpan).text == null) {
        result.add(item.span);
        continue;
      }

      final textSpan = item.span as TextSpan;
      final text = textSpan.text!;
      final spanStart = item.offset;
      final spanEnd = spanStart + text.length;

      // Find all ranges that overlap with this span
      final overlappingRanges = <HighlightRangeData>[];
      for (int i = 0; i < calibratedRanges.length; i++) {
        final range = calibratedRanges[i];
        if (range.end <= spanStart) continue;
        if (range.start >= spanEnd) continue; 
        overlappingRanges.add(range);
      }

      if (overlappingRanges.isEmpty) {
        result.add(textSpan);
        continue;
      }

      // Split the span according to highlight ranges
      final splitSpans = _splitSpanWithHighlights(
        textSpan,
        spanStart,
        overlappingRanges,
      );
      result.addAll(splitSpans);
    }

    return result;
  }

  /// Flatten nested spans and track their offsets.
  /// Returns the next available offset.
  /// Flatten nested spans and track their offsets.
  /// Returns the next available offset.
  int _flattenSpans(
    List<InlineSpan> spans,
    List<_SpanWithOffset> result,
    int startOffset,
    int Function(int) offsetMapper, {
    TextStyle? ancestorStyle,
  }) {
    int currentOffset = startOffset;

    for (final span in spans) {
      // Compute effective style by merging ancestor style with current span style
      TextStyle? effectiveStyle = span.style;
      if (ancestorStyle != null) {
        if (effectiveStyle != null) {
          effectiveStyle = ancestorStyle.merge(effectiveStyle);
        } else {
          effectiveStyle = ancestorStyle;
        }
      }

      if (span is TextSpan) {
        if (span.text != null && span.text!.isNotEmpty) {
          // KEY FIX: Create a shallow copy WITHOUT children to prevent double rendering
          // when we reconstruct the flat list.
          // AND use effectiveStyle to preserve inherited styles.
          final leafSpan = TextSpan(
            text: span.text,
            style: effectiveStyle,
            recognizer: span.recognizer,
            mouseCursor: span.mouseCursor,
            onEnter: span.onEnter,
            onExit: span.onExit,
            semanticsLabel: span.semanticsLabel,
            locale: span.locale,
            spellOut: span.spellOut,
          );
          
          result.add(_SpanWithOffset(leafSpan, offsetMapper(currentOffset)));
          currentOffset += span.text!.length;
        }
        if (span.children != null) {
          // Recursively Flatten children and update offset, passing down the style
          currentOffset = _flattenSpans(
            span.children!.cast<InlineSpan>(),
            result,
            currentOffset,
            offsetMapper,
            ancestorStyle: effectiveStyle,
          );
        }
      } else if (span is WidgetSpan) {
        result.add(_SpanWithOffset(span, offsetMapper(currentOffset)));
        // WidgetSpan counts as 1 character for selection purposes
        currentOffset += 1;
      }
    }
    return currentOffset;
  }

  /// Split a TextSpan according to highlight ranges.
  List<InlineSpan> _splitSpanWithHighlights(
    TextSpan originalSpan,
    int spanOffset,
    List<HighlightRangeData> ranges,
  ) {
    final text = originalSpan.text!;
    final spanEnd = spanOffset + text.length;
    final result = <InlineSpan>[];

    int currentPos = 0; // Position within the text string

    for (final range in ranges) {
      final rangeStart = max(range.start, spanOffset);
      final rangeEnd = min(range.end, spanEnd);

      if (rangeStart >= rangeEnd) continue;

      final localStart = rangeStart - spanOffset;
      final localEnd = rangeEnd - spanOffset;

      // Add text before the highlight
      if (localStart > currentPos) {
        result.add(TextSpan(
          text: text.substring(currentPos, localStart),
          style: originalSpan.style,
        ));
      }

      // Add highlighted text
      final highlightedText = text.substring(localStart, localEnd);
      final highlightStyle = _buildHighlightStyle(
        originalSpan.style,
        range.color,
        range.styleType ?? 'background',
      );

      // Create tappable span if callback is configured
      if (widget.config.onHighlightRangeTap != null && range.id != null) {
        result.add(TextSpan(
          text: highlightedText,
          style: highlightStyle,
          recognizer: TapGestureRecognizer()
            ..onTapDown = (details) {
              widget.config.onHighlightRangeTap!(
                range.id!,
                details.globalPosition,
              );
            },
        ));
      } else {
        result.add(TextSpan(
          text: highlightedText,
          style: highlightStyle,
        ));
      }

      currentPos = localEnd;
    }

    // Add remaining text after the last highlight
    if (currentPos < text.length) {
      result.add(TextSpan(
        text: text.substring(currentPos),
        style: originalSpan.style,
      ));
    }

    return result;
  }

  /// 在多个匹配中找到距离原位置最近的一个
  HighlightRangeData _findClosestMatch(
    Iterable<Match> matches,
    HighlightRangeData originalRange,
    String fullText,
  ) {
    if (matches.isEmpty) return originalRange;

    // 找到其实位置 (start) 最接近原 range.start 的匹配
    Match? bestMatch;
    int minDistance = 999999999;

    for (final match in matches) {
      final distance = (match.start - originalRange.start).abs();
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = match;
      }
    }

    if (bestMatch == null) return originalRange;

    return HighlightRangeData(
      id: originalRange.id,
      start: bestMatch.start,
      end: bestMatch.end,
      color: originalRange.color,
      styleType: originalRange.styleType,
      text: originalRange.text,
    );
  }

  /// Build highlight style based on type (background or underline).
  TextStyle _buildHighlightStyle(
    TextStyle? baseStyle,
    Color color,
    String styleType,
  ) {
    if (styleType == 'underline') {
      return (baseStyle ?? const TextStyle()).copyWith(
        decoration: TextDecoration.underline,
        decorationColor: color,
        decorationThickness: 2.0,
        decorationStyle: TextDecorationStyle.solid,
      );
    } else {
      // Default: background highlight
      return (baseStyle ?? const TextStyle()).copyWith(
        background: Paint()
          ..color = color.withAlpha(180)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }
}

/// Helper class to track span with its offset.
class _SpanWithOffset {
  final InlineSpan span;
  final int offset;

  _SpanWithOffset(this.span, this.offset);
}

/// A custom table column width.
class CustomTableColumnWidth extends TableColumnWidth {
  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    double width = 50;
    for (var each in cells) {
      each.layout(const BoxConstraints(), parentUsesSize: true);
      width = max(width, each.size.width);
    }
    return min(containerWidth, width);
  }

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return 50;
  }
}

