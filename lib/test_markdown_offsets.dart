import 'package:markdown/markdown.dart';

void main() {
  final text = "# Header\n\nParagraph with **bold**.\n\n- List item";
  final document = Document(encodeHtml: false);
  final lines = text.split('\n');
  final nodes = document.parseLines(lines);

  for (final node in nodes) {
    if (node is Element) {
      print("Tag: ${node.tag}, Attributes: ${node.attributes}, GeneratedId: ${node.generatedId}");
      // Check if there are any offset related properties usually hidden or available
       // Note: Standard package:markdown does not expose start/end offsets in Node simply.
       // However, we can use a custom Parser?
    }
  }
}
