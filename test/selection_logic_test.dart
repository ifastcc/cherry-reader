import 'package:flutter_test/flutter_test.dart';
import '../lib/services/highlight_selection_service.dart';
import '../lib/models/isar/message_block_entity.dart';

// Mock MessageBlockEntity since it's an Isar entity
class MockMessageBlockEntity extends MessageBlockEntity {
  @override
  String? content;
  
  MockMessageBlockEntity(this.content);
}

void main() {
  group('HighlightSelectionService', () {
    test('Selects single block completely', () {
      final blocks = [
        MockMessageBlockEntity("Hello World"),
      ];

      final results = HighlightSelectionService.calculateHighlights(
        blocks: blocks,
        startBlockIndex: 0,
        startOffset: 0,
        endBlockIndex: 0,
        endOffset: 5,
      );

      expect(results.length, 1);
      expect(results.first.text, "Hello");
      expect(results.first.start, 0); // Local start mapped to start
      expect(results.first.end, 5);   // Local end mapped to end
    });

    test('Selects across two blocks', () {
      final blocks = [
        MockMessageBlockEntity("Line 1"),
        MockMessageBlockEntity("Line 2"),
      ];

      // Select '1' from first block and 'Lin' from second
      // "Line 1" -> len 6. "1" is at index 5.
      // "Line 2" -> "Lin" is 0-3.
      
      final results = HighlightSelectionService.calculateHighlights(
        blocks: blocks,
        startBlockIndex: 0,
        startOffset: 5,
        endBlockIndex: 1,
        endOffset: 3,
      );

      expect(results.length, 2);
      
      // Block 0
      expect(results[0].text, "1");
      expect(results[0].start, 5);
      expect(results[0].end, 6);
      
      // Block 1
      expect(results[1].text, "Lin");
      expect(results[1].start, 0);
      expect(results[1].end, 3);
    });

    test('Handles reverse selection', () {
      final blocks = [
        MockMessageBlockEntity("First"),
        MockMessageBlockEntity("Second"),
      ];

      final results = HighlightSelectionService.calculateHighlights(
        blocks: blocks,
        startBlockIndex: 1, // Start at Second
        startOffset: 3,     // "Sec" -> index 3
        endBlockIndex: 0,   // End at First
        endOffset: 2,       // "Fi" -> index 2
      );

      // Should normalize to First[2:] ("rst") and Second[:3] ("Sec")
      // "First" (len 5). 2 to 5 -> "rst"
      // "Second". 0 to 3 -> "Sec"

      expect(results.length, 2);
      
      expect(results[0].text, "rst"); // Modified logic to ensure order
      expect(results[1].text, "Sec");
    });
  });
}
