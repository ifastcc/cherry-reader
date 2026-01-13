import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gpt_markdown_custom/gpt_markdown.dart';
import 'package:gpt_markdown_custom/markdown_component.dart';

/// Markdown Syntax Highlighter
///
/// Uses a "Safe Injection" strategy by traversing the text using the same
/// regex components as the renderer. It identifies "Safe Text Nodes" (pure text
/// outside of syntax markers) and injects <highlight> tags only there.
class MarkdownSyntaxHighlighter {
  final String text;
  final List<HighlightRange> highlights;

  MarkdownSyntaxHighlighter(this.text, this.highlights);

  String process() {
    if (highlights.isEmpty) return text;

    // Combine all components (Global + Inline) ensuring correct precedence
    final components = [
      ...MarkdownComponent.globalComponents,
      ...MarkdownComponent.inlineComponents,
    ];

    // Build the mega-regex logic similar to gpt_markdown parser
    // But since we need to know *which* component matched, we can't just join rules.
    // We will use a scanner approach: find the earliest match among all components.
    
    final buffer = StringBuffer();
    _processRecursive(text, 0, components, buffer);
    return buffer.toString();
  }

  /// Recursively process text, injecting highlights into safe zones.
  void _processRecursive(
    String currentText,
    int globalOffset,
    List<MarkdownComponent> components,
    StringBuffer buffer,
  ) {
    if (currentText.isEmpty) return;

    // Find the first match across all components
    Match? firstMatch;
    MarkdownComponent? matchedComponent;

    // Optimization: we could combine regexes, but capturing groups would be messy.
    // For now, iterate. The text chunks are usually small (paragraphs).
    for (final component in components) {
      final regExp = RegExp(
        component.exp.pattern,
        multiLine: component.exp.isMultiLine,
        dotAll: component.exp.isDotAll,
      );
      
      final match = regExp.firstMatch(currentText);
      if (match != null) {
        if (firstMatch == null || match.start < firstMatch.start) {
          firstMatch = match;
          matchedComponent = component;
        }
      }
    }

    if (firstMatch != null && matchedComponent != null) {
      // 1. Process text BEFORE the match (Safe Text)
      if (firstMatch.start > 0) {
        final prefix = currentText.substring(0, firstMatch.start);
        _processSafeText(prefix, globalOffset, buffer);
      }

      // 2. Process the match
      final matchStart = globalOffset + firstMatch.start;
      final matchEnd = globalOffset + firstMatch.end;

      if (matchedComponent.contentGroup != null) {
        // This component has a "safe" content zone (e.g. ** content **)
        // We need to preserve syntax markers but recurse into content.
        
        final content = firstMatch.group(matchedComponent.contentGroup!)!;
        
        // Find where title/content actually is in the full match string.
        // Note: RegExp match indices are relative to the input string.
        // But group indices are what we have.
        // We need to find the offset of group relative to match.start.
        
        // Strategy: 
        // We know the full match string: firstMatch.group(0)
        // We know the content string: content
        // We need to find `content` inside `fullMatch` CAREFULLY.
        // Warning: `content` might appear multiple times or be empty.
        
        // A more robust way using `match.start` and `match.end` for groups is dependent on platform implementation,
        // but Dart's Match doesn't expose group offsets easily in all versions.
        // However, we can use `match.start(groupIndex)` if available? 
        // Accessing group start indices is standard in Dart RegExp Match since forever.
        
        // Wait, Dart `Match` class DOES have `start(int group)` and `end(int group)`.
        // Let's use that!
        
        try {
          // Inner content range relative to currentText
          // Dart RegExp Match doesn't support group offsets, so we have to find it manually.
          final fullMatchText = firstMatch.group(0)!;
          final contentText = firstMatch.group(matchedComponent.contentGroup!)!;
          
          // Find content start index relative to the match start
          // We assume the first occurrence of content inside the match is the correct one.
          // This is generally true for the markdown syntaxes we care about (surrounding markers).
          final localContentStart = fullMatchText.indexOf(contentText);
          
          if (localContentStart != -1) {
            final innerStart = firstMatch.start + localContentStart;
            final innerEnd = innerStart + contentText.length;

            // Text BEFORE content (Opening Syntax) - Opaque
            buffer.write(currentText.substring(firstMatch.start, innerStart));
            
            // Text CONTENT - Recurse
            _processRecursive(
              currentText.substring(innerStart, innerEnd),
              globalOffset + innerStart,
              components, 
              buffer
            );
            
            // Text AFTER content (Closing Syntax) - Opaque
            buffer.write(currentText.substring(innerEnd, firstMatch.end));
          } else {
             // Fallback: entire match opaque
             buffer.write(firstMatch.group(0));
          }
        } catch (e) {
           // Fallback on error
           buffer.write(firstMatch.group(0));
        }

      } else {
        // Opaque component (e.g. Code Block, Image, Link?)
        // Just write it as is.
        buffer.write(firstMatch.group(0));
      }

      // 3. Process remaining text
      final remaining = currentText.substring(firstMatch.end);
      _processRecursive(remaining, matchEnd, components, buffer);

    } else {
      // No match found: entire text is safe
      _processSafeText(currentText, globalOffset, buffer);
    }
  }

  /// Inject highlight tags into safe text if it overlaps with defined highlights.
  void _processSafeText(String text, int offset, StringBuffer buffer) {
    if (text.isEmpty) return;
    
    final endOffset = offset + text.length;
    
    // Find relevant highlights for this range [offset, endOffset]
    final relevantHighlights = highlights.where((h) {
      return h.start < endOffset && h.end > offset;
    }).toList();

    if (relevantHighlights.isEmpty) {
      buffer.write(text);
      return;
    }

    // Sort by start
    relevantHighlights.sort((a, b) => a.start.compareTo(b.start));

    int localCursor = 0; // Relative to `text` start

    for (final h in relevantHighlights) {
      // Calculate intersection in local coordinates
      final hStartLocal = max(0, h.start - offset);
      final hEndLocal = min(text.length, h.end - offset);

      if (hStartLocal < localCursor) continue; // Skip overlapped parts (simplified)

      // Write text before highlight
      if (hStartLocal > localCursor) {
        buffer.write(text.substring(localCursor, hStartLocal));
      }

      // Write highlight
      final highlightedContent = text.substring(hStartLocal, hEndLocal);
      final colorHex = h.color.value.toRadixString(16).padLeft(8, '0');
      
      buffer.write('<highlight c="$colorHex" t="${h.styleType ?? 'background'}" i="${h.id ?? ''}">');
      buffer.write(highlightedContent);
      buffer.write('</highlight>');

      localCursor = hEndLocal;
    }

    // Write remaining text
    if (localCursor < text.length) {
      buffer.write(text.substring(localCursor));
    }
  }
}

/// Simple HighlightRange model re-definition to avoid circular deps if needed,
/// but we should rely on the exported one if possible. 
/// However, to keep this file cleaner, we assume it's imported.
class HighlightRange {
  final String? id;
  final int start;
  final int end;
  final Color color;
  final String? styleType;
  final String? text;
  final String? prefix;
  final String? suffix;
  final int? blockIndex;
  final String? blockContentHash; // 【新增】
  final int? blockInternalStart; // 【新增】
  final int? blockInternalEnd; // 【新增】
  final String? groupId; // 【新增】
  final bool isTarget; // 【精确定位】是否为目标高亮（用于闪烁效果）

  HighlightRange({
    this.id,
    required this.start,
    required this.end,
    required this.color,
    this.styleType,
    this.text,
    this.prefix,
    this.suffix,
    this.blockIndex,
    this.blockContentHash,
    this.blockInternalStart,
    this.blockInternalEnd,
    this.groupId,
    this.isTarget = false,
  });
}
