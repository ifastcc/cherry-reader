
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_reader/services/markdown_syntax_highlighter.dart';

void main() {
  test('Highlight pure text', () {
    final text = 'Hello world';
    final highlights = [
      HighlightRange(start: 0, end: 5, color: Colors.yellow, id: '1'),
    ];
    final highlighter = MarkdownSyntaxHighlighter(text, highlights);
    final result = highlighter.process();
    // Expected: <highlight ...>Hello</highlight> world
    expect(result, contains('<highlight c="00ffeb3b"'));
    expect(result, contains('>Hello</highlight> world'));
  });

  test('Highlight inside Bold', () {
    final text = 'Hello **World**';
    // "World" starts at index 8 in the source string.
    // match: **World** (starts at 6)
    // content group 1: World
    final highlights = [
      HighlightRange(start: 8, end: 13, color: Colors.yellow, id: '1'),
    ];
    final highlighter = MarkdownSyntaxHighlighter(text, highlights);
    final result = highlighter.process();
    
    // Expected: Hello **<highlight ...>World</highlight>**
    // The syntax markers ** should be preserved outside the highlight.
    expect(result, contains('Hello **<highlight'));
    expect(result, contains('>World</highlight>**'));
  });

  test('Highlight overlapping Bold syntax (Should fail gracefully/clip)', () {
    final text = 'Hello **World**';
    // Highlight from 6 ("*") to 10 ("Wor")
    // Should NOT highlight the * characters because they are syntax.
    // Should highlight "Wor".
    final highlights = [
      HighlightRange(start: 6, end: 11, color: Colors.yellow, id: '1'), 
    ];
    // Range [6, 11] covers "**Wor"
    // Safe text in "**World**" is only "World" (8-13).
    // Intersection of [6,11] and [8,13] is [8,11] -> "Wor"
    
    final highlighter = MarkdownSyntaxHighlighter(text, highlights);
    final result = highlighter.process();
    
    // Expected: Hello **<highlight>Wor</highlight>ld**
    expect(result, contains('Hello **<highlight'));
    expect(result, contains('>Wor</highlight>ld**'));
  });

  test('Highlight inside Link (Should NOT highlight if opaque)', () {
    final text = 'Click [Here](url)';
    // "Here" is at 7
    final highlights = [
      HighlightRange(start: 7, end: 11, color: Colors.yellow, id: '1'),
    ];
    
    // Since we didn't add contentGroup for ATagMd yet, it should be opaque.
    // So NO highlight tags should be injected.
    final highlighter = MarkdownSyntaxHighlighter(text, highlights);
    final result = highlighter.process();
    
    expect(result, equals(text));
  });
}
