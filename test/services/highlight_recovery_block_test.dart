import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown_custom/markdown_parse_result.dart'; // BlockInfo
import 'package:cherry_reader/services/highlight_recovery_service.dart';
import 'package:cherry_reader/models/highlight_data.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  late HighlightRecoveryService service;
  
  setUp(() {
    service = HighlightRecoveryService();
  });

  String _hash(String text) => md5.convert(utf8.encode(text)).toString();

  group('Block-Based Recovery', () {
    test('Fast Path: Perfect Match by Index & Hash', () {
       final blockText = 'Hello World';
       final block = BlockInfo(
         index: 0,
         globalStart: 100,
         globalEnd: 111,
         tag: 'p',
         text: blockText,
         contentHash: _hash(blockText),
       );
       final registry = [block];
       
       // Create a highlight anchored to this block
       final highlight = HighlightData(
         text: 'World',
         start: 106, // 100 + 6
         end: 111,
         color: 0,
         blockIndex: 0,
         blockContentHash: _hash(blockText),
         blockInternalStart: 6,
         blockInternalEnd: 11,
       );
       
       // Same plain text context
       final plainText = '...' * 33 + ' Hello World'; // 99 + 1 + 11 = 111? no
       // 33*3 = 99 chars. + space = 100. 'Hello World' starts at 100.
       // '...' * 33 contains 99 chars.
       // plainText index 0-98.
       // space at 99.
       // H at 100.
       final padding = 'a' * 100;
       final currentPlainText = padding + blockText;
       
       final recovered = service.recover(highlight, currentPlainText, registry: registry);
       
       expect(recovered.start, 106);
       expect(recovered.end, 111);
       // Should match exactly
    });

    test('Content Changed: Text found within same block', () {
       // Original: "Hello World"
       // New: "Hello Beautiful World"
       
       final oldBlockText = 'Hello World';
       final newBlockText = 'Hello Beautiful World';
       
       final block = BlockInfo(
         index: 0,
         globalStart: 100,
         globalEnd: 100 + newBlockText.length,
         tag: 'p',
         text: newBlockText,
         contentHash: _hash(newBlockText), // Hash changed!
       );
       final registry = [block];
       
       // Highlight for "World" in old text
       // "Hello " is 6 chars. "World" is 5.
       // Internal: 6-11.
       final highlight = HighlightData(
         text: 'World',
         start: 106, 
         end: 111,
         color: 0,
         blockIndex: 0,
         blockContentHash: _hash(oldBlockText), // Old hash
         blockInternalStart: 6,
         blockInternalEnd: 11,
       );
       
       final padding = 'a' * 100;
       final currentPlainText = padding + newBlockText;
       
       final recovered = service.recover(highlight, currentPlainText, registry: registry);
       
       // "Hello Beautiful World"
       // "Hello " = 6. "Beautiful " = 10. "World".
       // "World" starts at 16.
       // Global start: 100 + 16 = 116.
       
       expect(recovered.start, 116);
       expect(recovered.end, 121);
       expect(recovered.blockInternalStart, 16);
       expect(recovered.blockInternalEnd, 21);
    });
    
    test('Block Moved: Found by Hash', () {
       final blockText = 'Unique Paragraph content';
       final hash = _hash(blockText);
       
       // Block moved from index 0 to index 5
       final block = BlockInfo(
         index: 5, // Moved
         globalStart: 500, // Moved
         globalEnd: 500 + blockText.length,
         tag: 'p',
         text: blockText,
         contentHash: hash,
       );
       final registry = [block];
       
       final highlight = HighlightData(
         text: 'Paragraph',
         start: 7, // Originally at 0+7
         end: 16,
         color: 0,
         blockIndex: 0, // Old index
         blockContentHash: hash,
         blockInternalStart: 7,
         blockInternalEnd: 16,
       );
       
       // Context: ... block at 500 ...
       final padding = 'a' * 500;
       final currentPlainText = padding + blockText;
       
       final recovered = service.recover(highlight, currentPlainText, registry: registry);
       
       // Should find it at 500 + 7 = 507
       expect(recovered.start, 507);
       expect(recovered.blockIndex, 5); // Should update index
    });

    test('Lazy Migration: Populates Block Info from Legacy', () {
       final blockText = 'Target Block Content';
       final block = BlockInfo(
         index: 2,
         globalStart: 50,
         globalEnd: 50 + blockText.length,
         tag: 'p',
         text: blockText,
         contentHash: _hash(blockText),
       );
       final registry = [block];
       
       // Legacy highlight: Global offsets only, no block info
       final highlight = HighlightData(
         text: 'Block', // "Target Block Content" -> "Block" is at 7
         start: 57, // 50 + 7
         end: 62,
         color: 0,
         // No block info
       );
       
       final padding = 'a' * 50;
       final currentPlainText = padding + blockText;
       
       final recovered = service.recover(highlight, currentPlainText, registry: registry);
       
       // Should still be at 57 (exact match)
       expect(recovered.start, 57);
       
       // BUT should now have block info
       expect(recovered.blockIndex, 2);
       expect(recovered.blockContentHash, _hash(blockText));
       expect(recovered.blockInternalStart, 7);
       expect(recovered.blockInternalEnd, 12);
    });
  });
}
