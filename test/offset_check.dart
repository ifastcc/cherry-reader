
import 'package:markdown/markdown.dart';

void main() {
  final text = "# Header\n\nParagraph text.\n- List item";
  
  // Use a customized extension set or just default
  final document = Document(
     extensionSet: ExtensionSet.gitHubFlavored,
     withDefaultBlockSyntaxes: true,
  );
  
  // The parser operates on lines
  final lines = text.split('\n');
  final nodes = document.parseLines(lines);
  
  print("Parsed ${nodes.length} top-level nodes");
  
  for (var node in nodes) {
    if (node is Element) {
       print("Node: <${node.tag}>");
       // Check what kind of source info we have?
       // Element doesn't have start/end char offsets.
       // It might have line index?
       // Inspect runtime type
    }
  }
}
