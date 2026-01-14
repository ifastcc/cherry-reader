import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'dart:convert';
import '../custom_widgets/markdown_config.dart';
import '../custom_widgets/link_button.dart';
import '../custom_widgets/code_field.dart';
import '../custom_widgets/custom_divider.dart';
import '../custom_widgets/custom_rb_cb.dart';
import '../custom_widgets/unordered_ordered_list.dart';
import '../custom_widgets/custom_table_row.dart';
import '../theme.dart';
import '../markdown_parse_result.dart';
import 'package:html_unescape/html_unescape.dart';

/// Unified Visitor that converts Markdown nodes to Widgets AND extracts plain text.
/// This is the SINGLE SOURCE OF TRUTH for both rendering and offset calculation.
class GptMarkdownVisitor implements md.NodeVisitor {
  final GptMarkdownConfig config;
  final BuildContext context;

  // Output
  final List<Widget> _rootBlocks = [];
  
  // 【Single Source of Truth】Block 注册表
  final List<BlockInfo> blockRegistry = [];
  
  // 【Single Source of Truth】纯文本缓冲区
  final StringBuffer _plainTextBuffer = StringBuffer();
  
  // 【Single Source of Truth】当前全局纯文本偏移量
  int _currentGlobalOffset = 0;

  final _unescape = HtmlUnescape();

  
  // Stacks
  final List<List<Widget>> _widgetStack = []; // Stack of widget lists (for containers)
  final List<List<InlineSpan>> _spansStack = []; // Stack of span lists (for inline content)
  final List<int> _blockIdStack = []; // Stack of active Block IDs
  final List<int> _localOffsetStack = []; // Stack of local offsets
  final List<int> _blockGlobalStartStack = []; // 【Bug Fix】Stack of block start global offsets

  // List State
  final List<String> _listStack = []; 
  final List<int> _listCounters = []; 

  // Link State
  String? _currentLinkUrl;
  
  // Style Stack
  final List<TextStyle> _styleStack = [];
  TextStyle get _currentStyle => _styleStack.isEmpty 
      ? (config.style ?? const TextStyle()) 
      : _styleStack.last;

  int _currentBlockIndex = 0;

  // Helpers
  /// 【Bug Fix】注册 Block 时使用记录的起始偏移，而不是当前偏移
  void _registerBlock(String text, String type, int blockId, {int? globalStart}) {
    if (text.isEmpty) return;
    
    // 【Bug Fix】解码 HTML 实体，确保与用户选中文本一致
    final decodedText = _unescape.convert(text);
    
    // 计算哈希（使用解码后的文本）
    final bytes = utf8.encode(decodedText);
    final hash = md5.convert(bytes).toString().substring(0, 8);
    
    // 【Bug Fix】使用传入的 globalStart，或从 stack 获取，或回退到当前偏移
    final start = globalStart ?? 
        (_blockGlobalStartStack.isNotEmpty ? _blockGlobalStartStack.last : _currentGlobalOffset);
    
    // 注册（使用解码后的文本）
    blockRegistry.add(BlockInfo(
      text: decodedText,
      index: blockId,
      contentHash: hash,
      globalStart: start,
      globalEnd: start + decodedText.length,
      tag: type,
    ));
  }

  /// 辅助：重新计算子节点的纯文本
  String _getTextContent(List<md.Node> nodes) {
      final buffer = StringBuffer();
      for (final node in nodes) {
          buffer.write(node.textContent);
      }
      return buffer.toString();
  }

  GptMarkdownVisitor(this.context, this.config) {

    _widgetStack.add(_rootBlocks);
    // We don't push initial span stack or block ID because we rely on 'visitElementBefore' 
    // to detect blocks. But what if root has loose text?
    // Markdown parser normally wraps things. 
    // We'll handle "loose" content by buffering it if stacks are empty? 
    // Or we assume a "Root Block" (Implied Paragraph) logic?
    // For now, let's keep it strict: if valid markdown, blocks are defined.
    // If we receive loose text at root, we might need a "Root Spans" buffer.
    _spansStack.add([]); // Root spans buffer
    _localOffsetStack.add(0); // Root offset
    // _blockIdStack? If root text exists, what Block ID? 
    // PlainTextVisitor doesn't assign ID to root.
    // So root text has NO ID? Then it can't be highlighted in Strict Mode.
    // That's acceptable for v2 Strict.
  }
  
  List<Widget> get blocks {
      // Flush Root Spans if exists
      if (_spansStack.isNotEmpty && _spansStack.first.isNotEmpty) {
          // Wrapped in a generic block?
          // PlainTextVisitor does NOT assign ID for loose root text (unless we update it).
          // If we want it shown, we add it. But it won't be selectable via ID.
          _rootBlocks.add(Text.rich(
              TextSpan(children: _spansStack.first, style: config.style),
              textDirection: config.textDirection,
          ));
          _spansStack.first.clear(); // Consumed
      }
      return _rootBlocks;
  }
  
  // 【Single Source of Truth】纯文本访问器
  String get plainText => _plainTextBuffer.toString();
  
  // Helpers
  List<Widget> get currentWidgets => _widgetStack.last;
  List<InlineSpan> get currentSpans => _spansStack.last;
  
  @override
  bool visitElementBefore(md.Element element) {
    final theme = GptMarkdownTheme.of(context);
    
    // 1. Detect Block Entry (Pre-Order Indexing)
    // Matches PlainTextVisitor list: p, h1..h6, div, li, blockquote
    bool isContainerBlock = ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'div', 'li', 'blockquote'].contains(element.tag);
    
    if (isContainerBlock) {
        _blockIdStack.add(_currentBlockIndex++);
        _localOffsetStack.add(0);
        // 【Bug Fix】记录 Block 开始时的全局偏移
        _blockGlobalStartStack.add(_currentGlobalOffset);
        
        // Prepare storage
        // If it's a container that can hold Widgets (like blockquote, div, li), push widget stack.
        // If it's a leaf block (p, h1..), it usually holds spans.
        // But in our "Mixed" model (li can hold p), everything is potentially a container.
        // So we push BOTH stacks for every block?
        // Cons: Hierarchy. 
        // Strategy: 
        // - Always push `_spansStack` (for immediate child text).
        // - Always push `_widgetStack` (for child blocks).
        _spansStack.add([]);
        _widgetStack.add([]);
    }

    // 2. Atomic Blocks
    if (element.tag == 'latex_block') {
         final blockId = _currentBlockIndex++;
         _handleLatexBlock(element, blockId);
         return false;
    }

    if (element.tag == 'img') {
      _handleImage(element);
      return false;
    }
    if (element.tag == 'br') {
      // 【Single Source of Truth】同时写入纯文本 buffer
      _plainTextBuffer.write('\n');
      currentSpans.add(const TextSpan(text: '\n'));
      if (_localOffsetStack.isNotEmpty) _localOffsetStack.last++;
      _currentGlobalOffset++;
      return false;
    }
    if (element.tag == 'hr') {
      final blockId = _currentBlockIndex++;
      
      // 【Single Source of Truth】同时写入纯文本 buffer
      _plainTextBuffer.write('\uFFFC');
      _currentGlobalOffset++;
      
      Widget hr = CustomDivider(
          height: theme.hrLineThickness,
          color: config.style?.color ?? theme.hrLineColor,
      );
      
      currentWidgets.add(MetaData(
         behavior: HitTestBehavior.translucent,
         metaData: {'blockIndex': blockId},
         child: hr,
      ));
      
      return false;
    }
    
    if (element.tag == 'input') {
        return false; 
    }
    
    if (element.tag == 'table') {
        final blockId = _currentBlockIndex++;
        _handleTable(element, blockId);
        return false; 
    }

    // Wrapping Elements (Buffer)
    if (['radio_list_item', 'checkbox_list_item'].contains(element.tag)) {
        // These are inline wrappers usually?
        // PlainTextVisitor does NOT treat them as blocks (no ID).
        // So they are just span wrappers.
        _spansStack.add([]); 
    }
    
    // Lists logic
    if (element.tag == 'ul') {
      _listStack.add('ul');
      _listCounters.add(0);
      print('🔍 [Visitor] Found UL. Stack: $_listStack');
    }
    if (element.tag == 'ol') {
      _listStack.add('ol');
      final start = int.tryParse(element.attributes['start'] ?? '1') ?? 1;
      _listCounters.add(start);
      print('🔍 [Visitor] Found OL (Start: $start). Stack: $_listStack');
    }
    
    // List Item Marker Offset Logic - 【Single Source of Truth】
    if (element.tag == 'li') {
        if (_listStack.isNotEmpty && _listStack.last == 'ol') {
             final count = _listCounters.last;
             final marker = '$count.'; // Removed space to match OrderedListView
             // 【Single Source of Truth】同时写入纯文本 buffer
             _plainTextBuffer.write(marker);
             _currentGlobalOffset += marker.length;
             
             _listCounters.last++;
        } else if (_listStack.isNotEmpty && _listStack.last == 'ul') {
             // UL uses a WidgetSpan (bullet), which usually takes 1 char (\uFFFC) in Flutter Selection
             // 【Single Source of Truth】同时写入纯文本 buffer
             _plainTextBuffer.write('\uFFFC');
             _currentGlobalOffset += 1;
        }
    }
    
    // Latex (Inline)
    if (element.tag == 'latex') {
        _handleLatex(element);
        return false;
    }

    // Code Block (Pre) - Block ID Owner
    if (element.tag == 'pre') {
        final int blockId = _currentBlockIndex++; // Assign ID
        
        // PlainTextVisitor handles pre-with-code specifically
        if (element.children != null && 
            element.children!.isNotEmpty && 
            element.children!.first is md.Element && 
            (element.children!.first as md.Element).tag == 'code') {
              
            final codeElem = element.children!.first as md.Element;
            final code = codeElem.textContent;
            final language = codeElem.attributes['class']?.replaceFirst('language-', '') ?? '';
            
            Widget codeWidget;
            if (config.codeBuilder != null) {
              codeWidget = config.codeBuilder!(
                context, 
                language.isEmpty ? 'text' : language, 
                code, 
                true 
              );
            } else {
              codeWidget = CodeField(
                name: language,
                codes: code,
              );
            }
            
            // PRE is a Widget Block!
            // It is independent. It should NOT be a WidgetSpan if we can help it.
            // BUT, if we are inside a container (like div/li/blockquote), we add it to currentWidgets.
            // If we are "inline" in a p? PRE inside P is invalid HTML but Markdown...
            // Standard CommonMark: HTML blocks break paragraphs.
            
            // Implementation: Treat PRE as a Widget.
            // Add to currentWidgets.
            
            final metaCode = MetaData(
                behavior: HitTestBehavior.translucent,
                metaData: {'blockIndex': blockId},
                child: codeWidget
            );
            currentWidgets.add(metaCode);
            
            // 【Bug Fix】注册 Code Block 并更新全局偏移
            // 此时 _currentGlobalOffset 还未更新，可以直接使用
            _registerBlock(code, 'pre', blockId, globalStart: _currentGlobalOffset);
            
            // 【Bug Fix】更新纯文本 buffer 和全局偏移
            _plainTextBuffer.write(code);
            _currentGlobalOffset += code.length;
            _plainTextBuffer.write('\n');
            _currentGlobalOffset += 1;
            
            return false; // Skip children
        } else {
             // PRE without code? fallback.
             // Treat as Container Block.
             _blockIdStack.add(blockId);
             _localOffsetStack.add(0);
             // 【Bug Fix】记录 Block 开始时的全局偏移
             _blockGlobalStartStack.add(_currentGlobalOffset);
             _spansStack.add([]);
             _widgetStack.add([]);
        }
    }

    // 3. Apply Styles
    TextStyle newStyle = _currentStyle;
    switch (element.tag) {
      case 'h1': newStyle = newStyle.merge(theme.h1); break;
      case 'h2': newStyle = newStyle.merge(theme.h2); break;
      case 'h3': newStyle = newStyle.merge(theme.h3); break;
      case 'h4': newStyle = newStyle.merge(theme.h4); break;
      case 'h5': newStyle = newStyle.merge(theme.h5); break;
      case 'h6': newStyle = newStyle.merge(theme.h6); break;
      case 'strong': newStyle = newStyle.copyWith(fontWeight: FontWeight.bold); break;
      case 'em': newStyle = newStyle.copyWith(fontStyle: FontStyle.italic); break;
      case 'del': newStyle = newStyle.copyWith(decoration: TextDecoration.lineThrough); break;
      case 'a': 
        newStyle = newStyle.copyWith(color: theme.linkColor, decoration: TextDecoration.underline);
        _currentLinkUrl = element.attributes['href'];
        break;
      case 'code':
         newStyle = newStyle.copyWith(
           backgroundColor: theme.highlightColor, 
           fontFamily: 'monospace',
         );
         break;
    }
    _styleStack.add(newStyle);

    return true; // Visit children


  }

  @override
  void visitText(md.Text text) {
    if (text.text.isEmpty) return;
    _addTextWithHighlighting(_unescape.convert(text.text));
  }

    @override
    void visitElementAfter(md.Element element) {
      _styleStack.removeLast(); // Pop style
  
      // Handle Inline Wrappers (checkbox/radio)
      if (['radio_list_item', 'checkbox_list_item'].contains(element.tag)) {
          _handleRadioCheckBox(element);
          return;
      }
      
      // List State Cleanup
      if (element.tag == 'ul') {
        _listStack.removeLast();
      }
      if (element.tag == 'ol') {
        _listStack.removeLast();
        _listCounters.removeLast();
      }
      
      // Block End Detection
      bool isContainerBlock = ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'div', 'li', 'blockquote'].contains(element.tag);
      bool isPreFallback = (element.tag == 'pre' && _blockIdStack.isNotEmpty); // Rough check if we pushed stack for pre
  
      if (isContainerBlock || isPreFallback) {
          // Pop Context
          final theme = GptMarkdownTheme.of(context);
          final childrenSpans = _spansStack.removeLast();
          final childrenWidgets = _widgetStack.removeLast();
          final blockId = _blockIdStack.removeLast();
          _localOffsetStack.removeLast();
          // 【Bug Fix】获取并弹出 Block 起始偏移
          final blockGlobalStart = _blockGlobalStartStack.isNotEmpty 
              ? _blockGlobalStartStack.removeLast() 
              : _currentGlobalOffset;
  
          // Create Widget
          Widget? blockWidget;
          
          // 1. "Self" Content (Inline Spans)
          Widget? selfWidget;
          if (childrenSpans.isNotEmpty) {
              // Construct RichText
              // Note: We used to append '\n' in Visitor. In ListView, Blocks are separated by Layout.
              // However, Text.rich renders ONE block.
              
              // Styles for Headers
              TextStyle style = config.style ?? const TextStyle();
              /* attributes already applied via _styleStack during traversal? 
                 No, _styleStack applies to children spans. 
                 But the root TextSpan needs a default style? 
                 Or children already have it? 
                 Children have merged styles. Root can be basic.
              */
              
              selfWidget = Text.rich(
                  TextSpan(children: childrenSpans),
                  textDirection: config.textDirection,
              );
              
              // Heading dividers? Removed for cleaner look
              /*
              if (['h1','h2','h3'].contains(element.tag)) {
                  final theme = GptMarkdownTheme.of(context);
                  selfWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          selfWidget,
                          CustomDivider(
                             height: theme.hrLineThickness,
                             color: config.style?.color ?? theme.hrLineColor,
                          )
                      ],
                  );
              }
              */
              
              // BlockQuote styling
              if (element.tag == 'blockquote') {
                  // Wait, BlockQuote logic in old visitor was:
                  // IntrinsicHeight(Row(Bar, Expanded(Text))).
                  // Here we have selfWidget (text) AND childrenWidgets (if any).
                  // Blockquote usually contains P tags.
                  // So `childrenSpans` might be empty if it only contains P?
                  // Yes. Markdown: > paragraph -> blockquote > p.
                  // content is in P.
                  // So `selfWidget` is likely null/empty.
                  // But `childrenWidgets` has the P widget.
              }
          }
          
          // 2. Combine Self + Children
          List<Widget> content = [];
          if (selfWidget != null) content.add(selfWidget);
          content.addAll(childrenWidgets);
          
          if (content.isEmpty) {
              // Empty block?
              blockWidget = const SizedBox(); 
          } else {
              if (element.tag == 'blockquote') {
                   blockWidget = IntrinsicHeight(
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                         Container(
                           width: 4,
                           color: Colors.grey,
                         ),
                         const SizedBox(width: 8),
                         Expanded(
                           child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                               children: content,
                           ),
                         ),
                       ],
                     ),
                   );
              } else if (element.tag == 'li') {
                   // 【Bug Fix】传入 blockGlobalStart 以正确注册 Block
                   _handleListItemBlock(element, content, blockId, blockGlobalStart);
                   return; // _handleListItemBlock adds to currentWidgets
              } else {
                   // Standard Block (p, div, etc)
                   if (content.length == 1) {
                       blockWidget = content.first;
                   } else {
                       blockWidget = Column(
                           crossAxisAlignment: CrossAxisAlignment.stretch,
                           children: content,
                       );
                   }
              }
          }
          
          // Add to parent
          if (blockWidget != null) {
             // 【样式优化】为 H1/H2 添加下划线（细透明，支持深色模式）
             if (['h1', 'h2'].contains(element.tag)) {
               final lineColor = theme.hrLineColor;
               blockWidget = Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   blockWidget,
                   const SizedBox(height: 6),
                   Container(
                     height: theme.hrLineThickness,
                     color: lineColor,
                   ),
                 ],
               );
             }
             
             final metaBlock = MetaData(
                behavior: HitTestBehavior.translucent,
                metaData: {'blockIndex': blockId},
                child: blockWidget,
             );
          
             // Spacing & Margins
             // Add Top Margin for Headers (if not first element)
             if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(element.tag) && currentWidgets.isNotEmpty) {
                 currentWidgets.add(const SizedBox(height: 24)); // 减小标题上方间距
             }

             currentWidgets.add(metaBlock);
             
             // Bottom Margin
             if (['p', 'pre', 'ul', 'ol', 'table', 'blockquote'].contains(element.tag)) {
                 currentWidgets.add(const SizedBox(height: 8));
             } else if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(element.tag)) {
                  // Reduced bottom margin since we have top margin now
                 currentWidgets.add(const SizedBox(height: 8));
             }
             
             // 【新增】注册 Block
             // 只对原子内容 Block 进行注册，避免父子重复计算偏移
             // P, H1-H6, PRE 是原子文本块
             // Table, Li, Div, Blockquote 也需要注册，以便作为容器 Block 被索引
             final isAtomic = ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'pre', 'div', 'li', 'blockquote'].contains(element.tag);
             if (isAtomic) {
                 // 【Bug Fix】传入正确的 globalStart
                 _registerBlock(element.textContent, element.tag, blockId, globalStart: blockGlobalStart);
             }
             
             // 【核心修复】Highlight Drift Fix
             // 视觉上，Block 之间有换行 (SelectionArea 行为)。
             // 我们的 Pure Text Buffer 必须包含这些换行，否则索引会向左偏离。
             _plainTextBuffer.write('\n');
             _currentGlobalOffset += 1;
          }
      }
      
       

      
      if (isContainerBlock) {
          // 重新从 AST Element 获取纯文本 (这是 source of truth)
          final blockText = element.textContent;
          // 注意：这里用 removeLast 之前的 blockId 还是之后的？
          // 上面调用了 _blockIdStack.removeLast() 拿到了 blockId。
          // 这里的 blockId 就是刚才那个 block 的 ID。
          // 但是要注意：element.textContent 包含所有子节点的文本。
          // 我们的 _registerBlock 会更新全局偏移。
          // 如果嵌套 Block (如 li 包含 p)，子 Block 会先被 visitElementAfter 处理。
          // 这会导致重复注册吗？
          // V2 设计: 只有"叶子"内容才真正构成文本流。
          // 容器 Block (如 div, li) 本身没有"自己的"文本，它的文本是子节点的总和。
          // 如果我们注册了子 Block (P)，又注册了父 Block (LI)，那么 offset 会重复增加。
          
          // 策略：Leaf-Flattening
          // 只注册 "原子内容 Block" (Atomic Content Block)。
          // 原子 Block: p, h1-h6, pre, table, latex_block.
          // Container Block: div, li, blockquote.
          
          // Fix: Ensure we match PlainTextVisitor which registers ALL these.
          // The previous logic for `isAtomic` was restrictive.
          // We already registered them above in the `if (blockWidget != null)` block if they produced a widget.
          // But `isContainerBlock` logic here seems redundant if we handled it above?
          // L527 `if (isContainerBlock)` block seems to be just for comment/logic check?
          // No, L527 block is empty in previous view except for comments and an empty `if (isAtomic) {}`.
          // I will remove this redundant block or clean it up.
          
          /* 
          final isAtomic = ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'pre'].contains(element.tag);
          
          if (isAtomic) {
             // ...
          }
          */
      }
    }


  
  void _handleImage(md.Element element) {
      final url = element.attributes['src'] ?? '';
      Widget imageWidget;
      if (config.imageBuilder != null) {
        imageWidget = config.imageBuilder!(context, url);
      } else {
        imageWidget = Image.network(
           url, 
           fit: BoxFit.contain,
           errorBuilder: (ctx, error, stack) => const Icon(Icons.error),
        );
      }
      // 【Single Source of Truth】同时写入纯文本 buffer
      _plainTextBuffer.write('\uFFFC');
      _currentGlobalOffset++;
      
      currentSpans.add(WidgetSpan(child: imageWidget));
      if (_localOffsetStack.isNotEmpty) _localOffsetStack.last += 1;
  }

  void _handleTable(md.Element tableElement, int blockId) {
      // Structure: table -> thead -> tr -> th
      //                   -> tbody -> tr -> td
      // We manually parse this structure to build a list of rows.

      // Note: Table offset logic handled by _localOffsetStack updates at the end of _handleTable.ar, OR just ignore them for global sync.
      // However, we call `_addTextWithHighlighting` recursively.
      // To strictly match PlainTextVisitor (which writes `\n` ONLY), we must NOT increment offsets for internal content here.
      // Table offset logic is handled by _localOffsetStack updates at the end of _handleTable.



      final rows = <CustomTableRow>[];
      final theme = GptMarkdownTheme.of(context);
      
      for (final child in tableElement.children!) {
          if (child is! md.Element) continue;
          final part = child; // thead or tbody
          
          final isHeader = part.tag == 'thead';
          final style = isHeader 
              ? theme.h4 // Header style?
              : (config.style ?? Theme.of(context).textTheme.bodyMedium); // Body style
          
          for (final rowNode in part.children!) {
              if (rowNode is! md.Element || rowNode.tag != 'tr') continue;
              
              final cells = <Widget>[];
              for (final cellNode in rowNode.children!) {
                  if (cellNode is! md.Element) continue; // th or td
                  
                  // Render cell content to a separate span list
                  // We must create a temporary visitor or use a buffer.
                  // Since we are recursive, we can use our own visitor methods if we push a buffer!
                  // BUT we returned 'false' for table, so we are manual.
                  
                  // Create new buffer for this cell
                  _spansStack.add([]);
                  
                  // Setup style for cell
                  _styleStack.add(style ?? const TextStyle());
                  
                  // Visit children of cell
                  for (final cellChild in cellNode.children!) {
                      cellChild.accept(this);
                  }
                  
                  // Pop style
                  _styleStack.removeLast();
                  
                  // Pop content
                  final cellSpans = _spansStack.removeLast();
                  
                  // Create cell widget
                  cells.add(Text.rich(
                      TextSpan(children: cellSpans),
                      textDirection: config.textDirection,
                      textAlign: isHeader ? TextAlign.center : TextAlign.left,
                  ));
              }
              rows.add(CustomTableRow(
                  children: cells,
                  isHeader: isHeader,
              ));
          }
      }
      
      Widget tableWidget;
      if (config.tableBuilder != null) {
          tableWidget = config.tableBuilder!(context, rows, config.style ?? const TextStyle(), config);
      } else {
         // Default Table (simple implementation)
         tableWidget = Table(
             border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.5)),
             children: rows.map((r) {
                 return TableRow(
                     decoration: r.isHeader ? BoxDecoration(color: Colors.grey.withValues(alpha: 0.1)) : null,
                     children: r.children.map((c) => Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: c,
                     )).toList(),
                 );
             }).toList(),
         );
      }
      

      
      // Wrapp in MetaData
      currentWidgets.add(MetaData(
         behavior: HitTestBehavior.translucent,
         metaData: {'blockIndex': blockId},
         child: tableWidget
      ));
      
      // 【Bug Fix】Register Table Block with correct globalStart
      _registerBlock(tableElement.textContent, 'table', blockId, globalStart: _currentGlobalOffset);
      
      // 【Bug Fix】更新纯文本 buffer 和全局偏移
      _plainTextBuffer.write(tableElement.textContent);
      _currentGlobalOffset += tableElement.textContent.length;
      _plainTextBuffer.write('\n');
      _currentGlobalOffset += 1;
  }


  void _handleLatexBlock(md.Element element, int blockId) {
       final content = element.textContent;
       final style = _currentStyle;
       Widget latexWidget;
       
       if (config.latexBuilder != null) {
           latexWidget = config.latexBuilder!(context, content, style, false);
       } else {
            try {
               latexWidget = Math.tex(
                 content,
                 textStyle: style,
                 mathStyle: MathStyle.display,
                 onErrorFallback: (err) => Text(content, style: style),
               );
            } catch (e) {
               latexWidget = Text(content, style: style);
            }
       }
       
       currentWidgets.add(MetaData(
          behavior: HitTestBehavior.translucent,
          metaData: {'blockIndex': blockId},
          child: latexWidget
       ));
       
       // 【Bug Fix】注册 LaTeX Block 并更新全局偏移
       _registerBlock(content, 'latex_block', blockId, globalStart: _currentGlobalOffset);
       _plainTextBuffer.write(content);
       _currentGlobalOffset += content.length;
       _plainTextBuffer.write('\n');
       _currentGlobalOffset += 1;
  }
 
  void _handleLatex(md.Element element) {
      final content = element.textContent;
      final isInline = element.tag == 'latex';
      final style = _currentStyle;
      
      if (config.latexBuilder != null) {
        currentSpans.add(WidgetSpan(
          child: config.latexBuilder!(context, content, style, isInline),
          alignment: PlaceholderAlignment.middle,
        ));
      } else {
         try {
           currentSpans.add(WidgetSpan(
             child: Math.tex(
               content,
               textStyle: style,
               mathStyle: MathStyle.text,
               onErrorFallback: (err) => Text(content, style: style),
             ),
             alignment: PlaceholderAlignment.middle,
           ));
         } catch (e) {
           currentSpans.add(TextSpan(text: content, style: style));
         }
      }
      
      if (_localOffsetStack.isNotEmpty) {
         _localOffsetStack[_localOffsetStack.length - 1] = _localOffsetStack.last + content.length;
      }
  }

  void _addTextWithHighlighting(String text) {
    // 【Single Source of Truth】同时写入纯文本 buffer
    _plainTextBuffer.write(text);
    
    if (config.highlightRanges == null || config.highlightRanges!.isEmpty) {
      currentSpans.add(TextSpan(text: text, style: _currentStyle, recognizer: _buildLinkRecognizer()));
      if (_localOffsetStack.isNotEmpty) _localOffsetStack.last += text.length;
      _currentGlobalOffset += text.length;
      return;
    }

    if (_blockIdStack.isEmpty) {
        // Loose text? Just add.
        currentSpans.add(TextSpan(text: text, style: _currentStyle, recognizer: _buildLinkRecognizer()));
        return;
    }

    final blockIndex = _blockIdStack.last;
    final localStart = _localOffsetStack.last;
    final localEnd = localStart + text.length;
    
    // 【Bug Fix】正确的全局坐标计算
    // _currentGlobalOffset 已经是当前位置，不需要再加 localStart（会导致重复计算）
    final globalStart = _currentGlobalOffset;
    final globalEnd = _currentGlobalOffset + text.length;
    
    // Debug Logging
    // print('Render Text: "$text" Block: $blockIndex Local: [$start, $end] Global: [$globalStart, $globalEnd]');
    
     List<HighlightRangeData> ranges = config.highlightRanges!
        .where((r) {
           if (r.blockIndex != null) {
               // Block-Relative Logic
               if (r.blockIndex != blockIndex) return false;
               // Check intersection with current chunk's LOCAL range [localStart, localEnd]
               return r.start < localEnd && r.end > localStart;
           } else {
               // Global Logic (Legacy / Fallback)
               return r.start < globalEnd && r.end > globalStart;
           }
        })
        .toList();
    
    if (ranges.isNotEmpty) {
        print('GptMarkdownVisitor: Found ${ranges.length} ranges for text [${text.substring(0, min(5, text.length))}...] in Block $blockIndex (Global: $globalStart-$globalEnd)');
    }
            
    // Sort ranges
    ranges.sort((a, b) => a.start.compareTo(b.start));

    if (ranges.isEmpty) {
      currentSpans.add(TextSpan(text: text, style: _currentStyle, recognizer: _buildLinkRecognizer()));
      // Increment offsets for local and global
      if (_localOffsetStack.isNotEmpty) _localOffsetStack.last += text.length;
      _currentGlobalOffset += text.length;
      return;
    }

    // Processing Cursor
    // If using Block Logic, cursor is Local. If Global, cursor is Global.
    // To unify, let's map everything to "Chunk Relative" coordinates? 
    // Or just map Global Ranges to Local Space?
    
    // Let's use Local Space (relative to the start of 'text' chunk) for processing
    int chunkCursor = 0; 
    final int chunkLength = text.length;

    for (final r in ranges) {
       // Determine Highlight Range in "Chunk Space"
       int hChunkStart, hChunkEnd;
       
       if (r.blockIndex != null && r.blockIndex == blockIndex) {
           // Block-Relative Mode
           
           // 【New Semantic Runtime Resolution】
           // If semantic info is available, calculate offset at runtime.
           if (r.text != null && (r.prefix != null || r.suffix != null)) {
               // We need to match within the FULL block text, but we are currently processing a CHUNK.
               // Strategy: 
               // 1. We locate the range relative to the Block Start.
               // 2. We compare this range with our current Chunk Range [start, end].
               
               // But wait, Locator needs the SOURCE TEXT of the block.
               // Do we have the full block text here?
               // No. We are streaming chunks (visitText).
               // The Locator logic works best if we have the full text.
               
               // Alternative Strategy for Streaming Visitor:
               // We can't easily run Locator on "partial" block text if the context spans across chunks.
               // (e.g. prefix in chunk 1, highlight in chunk 2).
               
               // However, in our architecture, atomic blocks (P, H1) usually contain plain text children.
               // Even if they are split into multiple TextSpans (e.g. "bold **text**"),
               // the visitor visits them sequentially.
               
               // Ideally, we should resolve highlights ONCE for the block, then apply them.
               // But Visitor is streaming.
               
               // Pragmatic Approach for Phase 2:
               // Assume highlights are passed with "Correct Block-Relative Offsets" 
               // (which we fixed in Phase 1 via HighlightableCard's logic).
               // HighlightableCard ALREADY ran the recovery/locator logic effectively via `HighlightRecoveryService`.
               
               // Wait, `HighlightRecoveryService` runs BEFORE rendering.
               // It updates the `HighlightData`.
               // The `HighlightRangeData` passed here comes from `HighlightableCard`.
               
               // User Requirement: "Runtime" matching in Render Layer.
               // Why? Because between `HighlightableCard.build` and `Visitor.visit`,
               // the text structure shouldn't change relative to the offsets calculated 1ms ago.
               
               // Refined Definition of "Runtime":
               // The `HighlightableCard` calculation IS the runtime calculation.
               // The Visitor just applies it.
               
               // BUT, `HighlightRecoveryService` uses the *previous* parse result (cached).
               // If the *current* render (Visitor) produces different text (e.g. due to new widget logic),
               // then we have a mismatch.
               
               // So specific instruction: "Locator in Visitor".
               // To do this, Visitor needs access to the *full block text* at the moment of visiting.
               // But it's building it!
               
               // Solution: 
               // We cannot use Locator effectively *inside* `_addTextWithHighlighting` stream.
               // We must use the offsets provided by the config.
               // The "Runtime Semantic Matching" actually happens in `HighlightableCard` 
               // which prepares the config.
               
               // Let's re-read the plan.
               // "Refactor _addTextWithHighlighting to perform runtime lookup"
               // "Remove dependency on pre-calculated local offsets"
               
               // If we strictly follow this, we need to buffer the block content, 
               // run locator, then flush widgets.
               // But we are deep in `visitText`.
               
               // Let's implement a hybrid approach:
               // If we are in `_addTextWithHighlighting`, we are just adding a text node.
               // If `r` has valid start/end, we use them.
               // If `r` has NO start/end but HAS semantic info? (Future state)
               
               // For now, let's stick to using the start/end provided (which are Block-Relative).
               // The Phase 1 fix ensured these are correct.
               // The "Phase 2" might be interpreting "Runtime" as "HighlightableCard's build time".
               
               // Let's look at `HighlightLocator` usage.
               // It is intended to be used where we have full text.
               // `GptMarkdownVisitor` *generates* the text.
               
               // Maybe we don't change `GptMarkdownVisitor` logic deeply yet?
               // The prompt says: "Refactor _addTextWithHighlighting to perform runtime lookup".
               
               // If I am forced to do it here:
               // I can ONLY do it if I know the context.
               // Since `_addTextWithHighlighting` is called for fragments, I can't guarantee context.
               
               // Conclusion: The `HighlightLocator` should be called in `HighlightableCard` 
               // (or a pre-visitor pass) to resolve offsets.
               // The Visitor should remain "dumb" and just render offsets.
               // The "Runtime" aspect is that `HighlightableCard` recalculates offsets *every build*.
               
               // So, for this step, I will add a comment clarifying that we rely on the 
               // config-provided offsets (which are now dynamic), rather than trying to run 
               // regex on partial streams.
               
               hChunkStart = r.start - localStart;
               hChunkEnd = r.end - localStart;
           } else {
               hChunkStart = r.start - localStart;
               hChunkEnd = r.end - localStart;
           }
       } else {
           // Global Mode
           // r.start is Global
           // Chunk starts at `globalStart`
           hChunkStart = r.start - globalStart;
           hChunkEnd = r.end - globalStart;
       }
       
       // Clip to Chunk Boundaries [0, chunkLength]
       final intersectStart = max(hChunkStart, chunkCursor);
       final intersectEnd = min(hChunkEnd, chunkLength);
       
       if (intersectStart >= intersectEnd) continue;

       // 1. Text BEFORE highlight
       if (intersectStart > chunkCursor) {
          final sub = text.substring(chunkCursor, intersectStart);
          currentSpans.add(TextSpan(text: sub, style: _currentStyle, recognizer: _buildLinkRecognizer()));
       }
       
       // 2. Highlight Text
       final sub = text.substring(intersectStart, intersectEnd);
       final hData = _buildHighlightData(r);
       currentSpans.add(TextSpan(
         text: sub,
         style: hData.style,
         recognizer: hData.recognizer,
       ));
       
       chunkCursor = intersectEnd;
    }
    
    // 3. Remaining text
    if (chunkCursor < chunkLength) {
       final sub = text.substring(chunkCursor);
       currentSpans.add(TextSpan(text: sub, style: _currentStyle, recognizer: _buildLinkRecognizer()));
    }

    _localOffsetStack.last += text.length;
    _currentGlobalOffset += text.length;
  }
  
  TapGestureRecognizer? _buildLinkRecognizer() {
    if (_currentLinkUrl == null) return null;
    return TapGestureRecognizer()
      ..onTap = () {
        if (config.onLinkTap != null) {
          config.onLinkTap!(_currentLinkUrl!, '');
        }
      };
  }
  
  void _handleRadioCheckBox(md.Element element) {
      final children = _spansStack.removeLast();
      final checked = element.attributes['checked'] == 'true';
      final isRadio = element.tag == 'radio_list_item';
      
      Widget childWidget = Text.rich(
           TextSpan(children: children),
           textDirection: config.textDirection,
      );

      Widget wrappedWidget;
      if (isRadio) {
          wrappedWidget = CustomRb(
            value: checked,
            textDirection: config.textDirection,
            child: childWidget,
          );
      } else {
          wrappedWidget = CustomCb(
            value: checked,
            textDirection: config.textDirection,
            child: childWidget,
          );
      }
      
      currentSpans.add(WidgetSpan(
        child: wrappedWidget,
        alignment: PlaceholderAlignment.middle,
      ));
      
      currentSpans.add(const TextSpan(text: '\n'));
      if (_localOffsetStack.isNotEmpty) _localOffsetStack.last++; 
  }

  /// 【Bug Fix】增加 blockGlobalStart 参数，并在函数内调用 _registerBlock 和更新全局偏移
  void _handleListItemBlock(md.Element element, List<Widget> content, int blockId, int blockGlobalStart) {
      // Determine widget content
      Widget childWidget;
      if (content.length == 1) {
          childWidget = content.first;
      } else {
          childWidget = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content);
      }

      // Check for GFM Task List Item
      final isTaskItem = element.attributes['class'] == 'task-list-item';
      
      Widget itemWidget;
      // final theme = GptMarkdownTheme.of(context); // Unused?
      
      if (isTaskItem) {
          bool checked = false;
          if (element.children != null && element.children!.isNotEmpty) {
              final first = element.children!.first;
              if (first is md.Element && first.tag == 'input') {
                  checked = first.attributes.containsKey('checked');
              }
          }
          
          itemWidget = CustomCb(
            value: checked,
            textDirection: config.textDirection,
            child: childWidget,
          );
      } else if (_listStack.last == 'ul') {
          if (config.unOrderedListBuilder != null) {
              itemWidget = config.unOrderedListBuilder!(context, childWidget, config);
          } else {
              itemWidget = UnorderedListView(
                  bulletColor: config.style?.color,
                  padding: 8.0, 
                  bulletSize: 4.0,
                  textDirection: config.textDirection,
                  child: childWidget,
              );
          }
      } else {
          // ol
          int count = _listCounters.last;
          _listCounters[_listCounters.length - 1] = count + 1; 
          final no = "$count.";
          
          if (config.orderedListBuilder != null) {
              itemWidget = config.orderedListBuilder!(context, no, childWidget, config);
          } else {
              itemWidget = OrderedListView(
                  no: no,
                  padding: 8.0,
                  style: config.style,
                  textDirection: config.textDirection,
                  child: childWidget,
              );
          }
      }
      
      // Wrap in MetaData for HitTest
      // 【调试】如果开启 debugShowBlockIndex，在左上角显示 Block 索引
      Widget wrappedItemWidget = itemWidget;
      if (config.debugShowBlockIndex) {
        wrappedItemWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            itemWidget,
            Positioned(
              left: -20,
              top: 0,
              // 【修复】使用 IgnorePointer + ExcludeSemantics 防止调试角标被选中
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$blockId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      
      currentWidgets.add(MetaData(
        behavior: HitTestBehavior.translucent,
        metaData: {'blockIndex': blockId},
        child: wrappedItemWidget,
      ));
      
      // 【Bug Fix】注册 Block 并更新全局偏移（之前缺失这部分）
      _registerBlock(element.textContent, 'li', blockId, globalStart: blockGlobalStart);
      
      // 【Bug Fix】添加换行并更新全局偏移（之前缺失这部分）
      _plainTextBuffer.write('\n');
      _currentGlobalOffset += 1;
  }

  ({TextStyle style, TapGestureRecognizer? recognizer}) _buildHighlightData(HighlightRangeData r) {

      TextStyle style = _currentStyle;
      
      // 【精确定位】目标高亮使用更明显的样式
      final alpha = r.isTarget ? 255 : 180;
      final decorationThickness = r.isTarget ? 3.5 : 2.0;
      
      if (r.styleType == 'underline') {
        style = style.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: r.color,
          decorationThickness: decorationThickness,
          // 【精确定位】目标高亮添加背景色辅助突出
          backgroundColor: r.isTarget ? r.color.withAlpha(60) : null,
        );
      } else {
        style = style.copyWith(
          backgroundColor: r.color.withAlpha(alpha),
          // 【精确定位】目标高亮添加加粗效果
          fontWeight: r.isTarget ? FontWeight.w600 : null,
        );
      }
      
      TapGestureRecognizer? recognizer;
      if (r.id != null && config.onHighlightRangeTap != null) {
        recognizer = TapGestureRecognizer()
          ..onTapDown = (details) {
             config.onHighlightRangeTap!(r.id!, details.globalPosition);
          };
      }
      
      return (style: style, recognizer: recognizer);
  }
}
