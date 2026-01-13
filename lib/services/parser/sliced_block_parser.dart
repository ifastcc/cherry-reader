import 'package:markdown/markdown.dart';

/// A wrapper around [BlockParser] that extracts the raw source lines for each parsed block.
///
/// This resolves the issue where re-serializing AST nodes to Markdown is lossy (e.g. Tables, custom syntax).
/// By tracking the parser's consumption of lines, we can slice the original source text exactly.
class SlicedBlockParser {
  final String text;
  final Document document;

  SlicedBlockParser(this.text, {Document? document})
      : document = document ?? Document(extensionSet: ExtensionSet.gitHubFlavored);

  List<SourceBlock> parse() {
    final lines = text.split('\n');
    // Note: Document.parseLines() usually handles line splitting, but we need access to the List<String>
    // so we can reconstruct the slice. 
    // However, BlockParser takes List<Line> (internal class? No, public).
    // Use Document to ensure consistent line splitting if possible, but simplest is just split.
    
    // Create the standard parser
    // FIX: BlockParser expects List<Line>.
    final lineObjects = lines.map((s) => Line(s)).toList();
    final parser = BlockParser(lineObjects, document);
    
    final results = <SourceBlock>[];
    int currentLineIndex = 0; // Track our known position in the lines list

    while (!parser.isDone) {
      // 1. Identify where the parser is currently at.
      // Since `pos` is private, we verify our tracking against `parser.current`.
      // Optimization: Start searching from currentLineIndex to avoid O(N^2)
      final startPos = _findCurrentLineIndex(lineObjects, parser.current, currentLineIndex);

      
      // Safety check: if we lost track, fallback (should not happen with linear parsing)
      if (startPos == -1) {
         // Fallback: search from 0
         final retry = lines.indexOf(parser.current.content);
         if (retry == -1) break; // Should never happen
         currentLineIndex = retry;
      } else {
         currentLineIndex = startPos;
      }

      final start = currentLineIndex;
      bool matched = false;

      // 2. iterate syntaxes to find a match
      // We must use the same syntaxes the parser would use.
      // `parser.syntaxes` is not public (in some versions), but `parser.blockSyntaxes` 
      // might be exposed if we are lucky? 
      // Checking source: `final List<BlockSyntax> blockSyntaxes = [];` is public!
      // (Verified in source code reading step 93)
      
      for (final syntax in parser.blockSyntaxes) {
        if (syntax.canParse(parser)) {
          final block = syntax.parse(parser);
          
          // 3. Determine End Position
          int end;
          if (parser.isDone) {
            end = lines.length;
          } else {
             // Find where we are now
             end = _findCurrentLineIndex(lineObjects, parser.current, currentLineIndex);
             if (end == -1) end = lines.length; // Safety
          }
          
          // 4. Extract Slice
          final slice = lines.sublist(start, end).join('\n');
          
          if (block != null) {
             results.add(SourceBlock(
               astNode: block,
               content: slice,
               startLine: start,
               endLine: end,
             ));
          }
          
          // Update tracker
          currentLineIndex = end;
          matched = true;
          break;
        }
      }

      if (!matched) {
        // Fallback: Just advance one line (treat as paragraph or empty)
        // Usually ParagraphSyntax catches everything, so this is rare.
        parser.advance();
        currentLineIndex++;
      }
    }
    
    return results;
  }

  int _findCurrentLineIndex(List<Line> sourceLines, dynamic currentLineObj, int startSearch) {
      // BlockParser wraps strings in Line objects.
      // We need to match the CONTENT of the line, but duplicate lines exist.
      // WE CANNOT RELY ON CONTENT MATCHING ALONE.
      
      // Since we created lineObjects ourselves, we can check identity!
      // But verify if BlockParser clones them?
      // Source code: `BlockParser(this.lines, ...)` - It stores reference.
      // So Identity check works!
      
      for (int i = startSearch; i < sourceLines.length; i++) {
         if (identical(sourceLines[i], currentLineObj)) {
            return i;
         }
      }
      return -1; 
  }
}


class SourceBlock {
  final Node astNode;
  final String content;
  final int startLine;
  final int endLine;

  SourceBlock({
    required this.astNode,
    required this.content,
    required this.startLine,
    required this.endLine,
  });
}
