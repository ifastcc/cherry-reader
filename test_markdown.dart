
import 'package:markdown/markdown.dart';

void main() {
  final text = 'Hello **World** and [Link](url)';
  final document = Document();
  final nodes = document.parseLines(text.split('\n'));

  for (final node in nodes) {
    printNode(node);
  }
}

void printNode(Node node) {
  if (node is Element) {
    print('Element: <${node.tag}>');
    if (node.children != null) {
      for (final child in node.children!) {
        printNode(child);
      }
    }
  } else if (node is Text) {
    print('Text: "${node.text}"');
    // Check if we can get source positions? 
    // The Node class doesn't expose offsets by default in older versions.
  }
}
