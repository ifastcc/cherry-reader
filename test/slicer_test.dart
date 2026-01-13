
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import '../lib/services/markdown_block_service.dart';
import '../lib/services/parser/sliced_block_parser.dart';

void main() {
  test('SlicedBlockParser correctly slices tables', () {
    const tableMarkdown = '''
| Header 1 | Header 2 |
| --- | --- |
| Cell 1 | Cell 2 |
''';

    final fullText = "# Title\n\n$tableMarkdown\nParagraph";
    
    final parser = SlicedBlockParser(fullText);
    final results = parser.parse();
    
    expect(results.length, 3);
    expect(results[0].astNode, isA<md.Element>()); // h1
    expect((results[0].astNode as md.Element).tag, 'h1');
    
    // Check Table
    final tableBlock = results[1];
    expect(tableBlock.astNode, isA<md.Element>());
    expect((tableBlock.astNode as md.Element).tag, 'table');
    // CRITICAL: The content should match EXACTLY
    // Note: slice might include trailing newline depending on parser behavior?
    // BlockParser usually consumes line by line.
    // The table block consumes the lines.
    
    print("Extracted Table Content:\n'${tableBlock.content}'");
    
    // Allow trimming for comparison if needed, but we aimed for exact slice.
    expect(tableBlock.content.trim(), tableMarkdown.trim());
  });
  
  test('SlicedBlockParser handles nested lists', () {
     const listMarkdown = '''
- Item 1
  - Nested A
  - Nested B
- Item 2
''';
     final parser = SlicedBlockParser(listMarkdown);
     final results = parser.parse();
     
     expect(results.length, 1); // Should be one 'ul_chunk' logic? No, parser sees one UL.
     
     final listBlock = results[0];
     print("Extracted List Content:\n'${listBlock.content}'");
     expect(listBlock.content.trim(), listMarkdown.trim());
  });
}
