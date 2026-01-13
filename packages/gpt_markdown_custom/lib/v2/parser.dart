import 'package:markdown/markdown.dart' as md;

/// Combined extension set for GPT Markdown
class GptExtensionSet {
  static md.ExtensionSet get all => md.ExtensionSet(
    [
      ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      LatexBlockSyntax(),
      RadioButtonSyntax(),
      CheckBoxSyntax(),
      // CheckBoxSyntax is already covered by GFM's UnorderedListSyntax + TaskList
      // but we add our own for consistent 'checkbox_list_item' tag generation 
      // if GFM's TaskList is not sufficient or if we want custom behavior.
    ],
    [
      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      LatexInlineSyntax(),
    ],
  );
}

/// Matches inline LaTeX: $...$
class LatexInlineSyntax extends md.InlineSyntax {
  // Match $...$ but not escaped \$
  // We use a capture group for the content.
  LatexInlineSyntax() : super(r'(?<!\\)\$((?:\\.|[^$])*)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match[1] ?? '';
    parser.addNode(md.Element.text('latex', content));
    return true;
  }
}

/// Matches block LaTeX: $$...$$
class LatexBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$(.*?)\$\$$', multiLine: true, dotAll: true);

  // Since standard BlockSyntax regexes usually match the start of the line, 
  // and we want to handle potentially multi-line blocks that start with $$ and end with $$,
  // we might need a more robust approach similar to FencedCodeBlock if $$ can span lines.
  
  // Actually, standard `BlockSyntax` expects `pattern` to match the *start* of the block.
  // We will simple use a pattern that detects the opening `$$`.
  // However, `package:markdown`'s BlockSyntax is line-based. 
  // We should mimic FencedCodeBlockSyntax or similar.
  
  // Let's try a simpler approach compatible with typical FencedCodeBlock usage 
  // but for $$ delimiters.
  @override
  bool canParse(md.BlockParser parser) {
    return parser.current.content.trimLeft().startsWith(r'$$');
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final lines = <String>[];
    // Consuming lines until we find the closing $$
    // First line
    lines.add(parser.current.content);
    parser.advance();
    
    while (!parser.isDone) {
      final content = parser.current.content;
      lines.add(content);
      if (content.trim().endsWith(r'$$')) {
        parser.advance();
        break;
      }
      parser.advance();
    }
    
    // Join lines and strip the $$ delimiters
    String content = lines.join('\n');
    content = content.trim();
    if (content.startsWith(r'$$')) content = content.substring(2);
    if (content.endsWith(r'$$')) content = content.substring(0, content.length - 2);
    
    return md.Element.text('latex_block', content.trim());
  }
}

/// Matches radio button items: (x) Item or ( ) Item
/// This is similar to ListSyntax but specifically for ( ) or (x) markers.
/// 
/// Note: package:markdown parses lists in a specific way. 
/// We might want to let the standard ListSyntax handle this if possible, 
/// but standard only handles * - + and 1.
/// 
/// We will register this as a BlockSyntax that produces a generic Element 
/// that our Visitor will render as a list item with a radio button.
class RadioButtonSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\s*\((x|\ )\)\s+(.*)$');

  @override
  bool canParse(md.BlockParser parser) {
    return pattern.hasMatch(parser.current.content);
  }

  @override
  md.Node parse(md.BlockParser parser) {
    // This is a simplified implementation. Proper list implementation needs to handle nesting.
    // For V2 MVP, we can treat them as individual blocks or try to group them.
    // Let's implement minimal parsing that treats them as 'radio_list_item'.
    
    final match = pattern.firstMatch(parser.current.content);
    final checked = match?[1] == 'x';
    final content = match?[2] ?? '';
    
    parser.advance();
    
    final element = md.Element('radio_list_item', [md.Text(content)]);
    element.attributes['checked'] = '$checked';
    return element;
  }
}

/// Matches checkbox items: [x] Item or [ ] Item
class CheckBoxSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\s*\[(x|\ )\]\s+(.*)$');

  @override
  bool canParse(md.BlockParser parser) {
    return pattern.hasMatch(parser.current.content);
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    final checked = match?[1] == 'x';
    final content = match?[2] ?? '';
    
    parser.advance();
    
    final element = md.Element('checkbox_list_item', [md.Text(content)]);
    element.attributes['checked'] = '$checked';
    return element;
  }
}
