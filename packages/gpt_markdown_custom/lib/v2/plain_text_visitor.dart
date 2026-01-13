import '../markdown_parse_result.dart'; // For BlockInfo
import 'package:markdown/markdown.dart' as md;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:html_unescape/html_unescape.dart';

/// Visitor that extracts plain text from the AST.
/// This MUST mirrors the [GptMarkdownVisitor] logic to ensure 1:1 offset mapping.
class PlainTextVisitor implements md.NodeVisitor {
  final StringBuffer _buffer;
  final List<BlockInfo> blocks = [];
  int _currentBlockIndex = 0;
  
  // List Tracking
  final List<String> _listStack = [];
  final List<int> _listCounters = [];
  
  // To track offsets as we go (useful if we need to return specific node offsets, but here we just need the full text)
  int get length => _buffer.length;

  final List<int> _blockStartStack = [];
  final List<int> _blockIdStack = []; // Track IDs of open blocks
  final _unescape = HtmlUnescape();
  
  PlainTextVisitor(this._buffer);

  @override
  bool visitElementBefore(md.Element element) {
    // Track block start
    if (['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'div', 'li', 'blockquote'].contains(element.tag)) {
        _blockStartStack.add(_buffer.length);
        _blockIdStack.add(_currentBlockIndex++);
    }

    if (element.tag == 'ol') {
        _listStack.add('ol');
        int start = 1;
        if (element.attributes['start'] != null) {
            start = int.tryParse(element.attributes['start']!) ?? 1;
        }
        _listCounters.add(start);
    } 
    else if (element.tag == 'ul') {
        _listStack.add('ul');
        _listCounters.add(0); // Unused for UL but keeps stack in sync
    }
    
    if (element.tag == 'li') {
        if (_listStack.isNotEmpty) {
            final parent = _listStack.last;
            if (parent == 'ol') {
                final count = _listCounters.last;
                final marker = '$count.'; // Matches OrderedListView logic (No space)
                _buffer.write(marker);
                _listCounters.last++;
            } else {
                // Unordered: WidgetSpan(bullet) -> \uFFFC
                _buffer.write('\uFFFC');
            }
        }
    }

    if (element.tag == 'latex_block') {
      final start = _buffer.length;
      final blockId = _currentBlockIndex++;
      
      final text = element.textContent;
      _buffer.write(text);
      
      blocks.add(BlockInfo(
        index: blockId,
        globalStart: start,
        globalEnd: _buffer.length,
        tag: 'latex_block',
        text: text,
        contentHash: md5.convert(utf8.encode(text)).toString(),
      ));
      return false; 
    }
    
    if (element.tag == 'latex') {
      _buffer.write(element.textContent);
      return false; // Inline latex, no block ID
    }
    if (element.tag == 'img') {
        // Image logic: Visitor renders a WidgetSpan.
        // WidgetSpan length is 1 (placeholder) in Flutter.
        // We MUST sync with this.
        _buffer.write('\uFFFC');
        return false;
    }
    if (element.tag == 'br') {
      _buffer.write('\n');
      return false;
    }
    if (element.tag == 'hr') {
        final start = _buffer.length;
        final blockId = _currentBlockIndex++;

        _buffer.write('\uFFFC'); 
        
        final text = '\uFFFC';
        blocks.add(BlockInfo(
            index: blockId,
            globalStart: start,
            globalEnd: _buffer.length,
            tag: 'hr',
            text: text,
            contentHash: md5.convert(utf8.encode(text)).toString(),
        ));
        return false; 
    }
    
    // Table handling: Allow traversal to extract text from cells!
    // GptMarkdownVisitor recurses into tables, so we must too.
    // However, we should register the table block?
    // GptVisitor registers "Table Widget" as a Block?
    // L121 (GptVisitor): "element.tag == 'table' -> blockId = ...; _handleTable...".
    // _handleTable registers metaData blockIndex.
    // But does it register a text block?
    // GptVisitor L518: Only atomic blocks (p, h1, etc) call _registerBlock.
    // Is 'table' in isAtomic list?
    // GptVisitor L545: Atomic = p, h1..h6, pre. (NOT table).
    // So Table ITSELF is not a text block in Registry.
    // BUT the text inside cells might be wrapped in P?
    // Standard Markdown: Cells contain Inline content, not Blocks (usually).
    // So text inside cells are just text.
    // Does GptVisitor register blocks for Cell Text?
    // No. Cell text is just text added to the Table Widget.
    // So the entire Table is a "Container Block" with no registered text entry in `BlockRegistry`?
    // Then how do we highlight it?
    // If it's not in Registry, `SelectionService` won't find it?
    // `PlainTextVisitor` was creating a BlockInfo for Table (L128).
    // If we remove this, we lose the BlockInfo.
    
    // Correct Strategy:
    // Treat Table as a container.
    // But we need to index its text.
    // If we traverse, we get text.
    // Does that text belong to a Block?
    // If we don't start a Block for Table, the text belongs to "previous block" or "no block"?
    // In PlainTextVisitor, we should distinctify it.
    
    // Let's create a BlockInfo for the Table "Container" but allow recursion?
    // No, BlockInfo requires `text` field. Container's text is sum of children.
    // If we traverse, we write text.
    // We can wrap the traversal.
    
    if (element.tag == 'table') {
        final start = _buffer.length;
        final blockId = _currentBlockIndex++;
        
        // We do NOT return false. We let it visit children.
        // But we want to capture the text for the BlockInfo.
        // We can check buffer difference after visitElementAfter.
        
        _blockStartStack.add(start);
        _blockIdStack.add(blockId);
        
        return true; 
    }
    
    // GFM Task List Input (checkbox)
    if (element.tag == 'input') {
        return false; 
    }
    
    // Code blocks

    if (element.tag == 'pre') {
        final start = _buffer.length;
        
        final blockId = _currentBlockIndex++;

        if (element.children != null && 
            element.children!.isNotEmpty && 
            element.children!.first is md.Element && 
            (element.children!.first as md.Element).tag == 'code') {
              
            final codeElem = element.children!.first as md.Element;
            final text = codeElem.textContent + '\n';
            _buffer.write(text);
            
            final end = _buffer.length;
            // PRE is a block
            blocks.add(BlockInfo(
                index: blockId,
                globalStart: start,
                globalEnd: end,
                tag: 'pre',
                text: text,
                contentHash: md5.convert(utf8.encode(text)).toString(),
            ));
            
            return false;
        } else {
             // Fallback for pre without code?
             // Treat as container?
             // If we return true, children are visited.
             // But we consumed ID.
             // Let's assume visited children are text.
             // We can push this ID to stack?
              _blockStartStack.add(start);
              _blockIdStack.add(blockId);
        }
    }
    
    // List Logic (we do NOT write bullets/numbers to buffer, as Visitor puts them in WidgetSpan)
    // Only content is visited.

    return true; // Visit children
  }

  @override
  void visitText(md.Text text) {
    if (text.text.isEmpty) return;
    final content = _unescape.convert(text.text);
    _buffer.write(content);
  }

  @override
  void visitElementAfter(md.Element element) {
    // Block spacing (Identical logic to RenderVisitor)
    if (['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'div', 'li', 'table', 'blockquote'].contains(element.tag)) {
        if (_buffer.isNotEmpty && !_endsWithNewline()) {
             _buffer.write('\n');
        }

        if (['h1','h2','h3'].contains(element.tag)) {
            // RenderVisitor adds Divider + Newline
            // Divider is widget (length 0 or 1). Newline is text.
            _buffer.write('\n');
        }
        
        // Block End
        if (_blockStartStack.isNotEmpty) {
            final start = _blockStartStack.removeLast();
            final id = _blockIdStack.removeLast();
            final end = _buffer.length;
            final text = _buffer.toString().substring(start, end);
            blocks.add(BlockInfo(
                index: id,
                globalStart: start,
                globalEnd: end,
                tag: element.tag,
                text: text,
                contentHash: md5.convert(utf8.encode(text)).toString(),
            ));
        }
    }
    
    
    if (['radio_list_item', 'checkbox_list_item'].contains(element.tag)) {
         _buffer.write('\n');
         // These are blocks too? visitor says wraps span stack.
         // But logic handled in visitor is similar to li.
         // We didn't push them in visitElementBefore for _blockStartStack though.
         // Let's check logic.
    }
    


    if (element.tag == 'ol' || element.tag == 'ul') {
        if (_listStack.isNotEmpty) _listStack.removeLast();
        if (_listCounters.isNotEmpty) _listCounters.removeLast();
    }
  }

  
  bool _endsWithNewline() {
      if (_buffer.isEmpty) return false;
      final s = _buffer.toString();
      return s.endsWith('\n');
  }
}
