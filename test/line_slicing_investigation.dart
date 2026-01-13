
import 'package:markdown/markdown.dart';

// A custom syntax to "spy" on the parser?
// Or just replicate the loop in Document.parseLines?

void main() {
  final lines = [
    "# Header",
    "",
    "Paragraph line 1",
    "Paragraph line 2",
    "", 
    "- List item 1",
    "- List item 2",
    "",
    "```dart",
    "void main() {}",
    "```",
    "",
    "> Quote line 1",
    "> Quote line 2"
  ];
  
  print("Total Lines: ${lines.length}");
  
  final document = Document(
    extensionSet: ExtensionSet.gitHubFlavored,
  );
  
  // Inspecting how Document parses lines
  // We can't easily hook into 'Document.parseLines' because it creates the parser internally.
  // But we can instantiate BlockParser manually if we want to mimic it.
  
  final parser = BlockParser(lines, document);
  
  print("\n--- Starting Manual Block Parser Loop ---");
  
  while (!parser.isDone) {
    // Before parsing a block, capture current line index
    final startLine = parser.pos; // 'pos' is the index of the current line
    
    // We need to know WHICH syntax matched and how many lines it consumed.
    // The `parse()` method of BlockParser iterates syntaxes.
    // If we call `parser.parse()`, it does the whole loop until end? 
    // No, `BlockParser.parse()` returns List<Node> and runs until isDone.
    
    // We want to step ONE block at a time.
    // We can look at BlockParser source (or assume behavior):
    // It iterates syntaxes.
    
    // Let's try to find a matching syntax manually to see if we can emulate the step.
    
    bool matched = false;
    for (final syntax in parser.syntaxes) {
      if (syntax.canParse(parser)) {
        print("Syntax matches at line $startLine: ${syntax.runtimeType}");
        final node = syntax.parse(parser);
        matched = true;
        
        final endLine = parser.pos; // 'pos' matches the start of the *next* block
        print(" -> Produced Node: ${node?.runtimeType}");
        print(" -> Consumed lines: $startLine to $endLine (Exclusive end)");
        
        // Emulate content slice
        final consumedLines =lines.sublist(startLine, endLine);
        print(" -> RAW CONTENT:\n${consumedLines.join('\n')}");
        print("------------------------------------------------");
        break;
      }
    }
    
    if (!matched) {
      // If no syntax matches, BlockParser usually advances or treats as paragraph?
      // Actually standard BlockParser treats everything else as Paragraph if not matched?
      // Or it just advances?
      // Let's see if we get stuck.
      print("No syntax matched at line $startLine. Advancing...");
      parser.advance();
    }
  }
}
