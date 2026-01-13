import 'package:flutter/material.dart';

/// Markdown 解析结果
///
/// 包含渲染所需的 Span 列表、纯文本和偏移映射。
/// 通过单次解析生成所有输出，确保坐标一致性。
class MarkdownParseResult {
  /// 渲染用的 InlineSpan 列表
  final List<InlineSpan> spans;

  /// 从 Markdown 提取的纯文本（去除格式标记）
  /// 用于高亮匹配、搜索等场景
  final String plainText;

  /// 块信息列表（用于 Block ID + Local Offset 映射）
  final List<BlockInfo> blocks;

  /// Span 与纯文本的映射关系列表
  final List<SpanMapping> mappings;

  /// WidgetSpan 的长度缓存
  final Map<InlineSpan, int> spanLengths;

  /// 块级 Widget 列表
  final List<Widget> blockWidgets;

  const MarkdownParseResult({
    required this.spans,
    required this.plainText,
    required this.mappings,
    this.spanLengths = const {},
    this.blocks = const [],
    this.blockWidgets = const [],
  });

  /// 空结果
  static const empty = MarkdownParseResult(
    spans: [],
    plainText: '',
    mappings: [],
    spanLengths: {},
    blocks: [],
    blockWidgets: [],
  );

  /// 根据全局偏移获取块信息和局部偏移
  (int blockIndex, int localOffset)? globalToBlockLocal(int globalOffset) {
    // 二分查找或遍历
    for (final block in blocks) {
      if (globalOffset >= block.globalStart && globalOffset < block.globalEnd) {
        return (block.index, globalOffset - block.globalStart);
      }
    }
    return null;
  }
}

/// 块信息
class BlockInfo {
  final int index;
  final int globalStart;
  final int globalEnd;
  final String tag; 

  const BlockInfo({
    required this.index,
    required this.globalStart,
    required this.globalEnd,
    required this.tag,
    required this.text,
    required this.contentHash,
  });

  /// 块内纯文本
  final String text;

  /// 块内容哈希 (MD5)
  final String contentHash;

  int get length => globalEnd - globalStart;
  
  // Aliases for compatibility with Visitor usage
  int get plainTextStart => globalStart;
  int get plainTextEnd => globalEnd;
  String get blockType => tag;
}

/// Span 与纯文本的映射关系
///
/// 记录每个 Span 对应的纯文本区间，用于高亮定位。
class SpanMapping {
  /// 在父级 spans 列表中的索引（如果是嵌套的则为 -1）
  final int spanIndex;

  /// 在 plainText 中的起始位置（inclusive）
  final int plainTextStart;

  /// 在 plainText 中的结束位置（exclusive）
  final int plainTextEnd;

  /// 对应的 Span 引用（便于快速访问）
  final InlineSpan span;

  const SpanMapping({
    required this.spanIndex,
    required this.plainTextStart,
    required this.plainTextEnd,
    required this.span,
  });

  /// 纯文本长度
  int get length => plainTextEnd - plainTextStart;

  /// 检查是否与给定范围重叠
  bool overlaps(int start, int end) {
    return !(end <= plainTextStart || start >= plainTextEnd);
  }

  /// 计算与给定范围的交集
  (int, int)? intersection(int start, int end) {
    if (!overlaps(start, end)) return null;
    final intersectStart = start > plainTextStart ? start : plainTextStart;
    final intersectEnd = end < plainTextEnd ? end : plainTextEnd;
    return (intersectStart, intersectEnd);
  }

  @override
  String toString() =>
      'SpanMapping(spanIndex: $spanIndex, range: [$plainTextStart, $plainTextEnd))';
}

/// 解析上下文，用于在解析过程中累积结果
class ParseContext {
  final List<InlineSpan> spans = [];
  final StringBuffer plainTextBuffer = StringBuffer();
  final List<SpanMapping> mappings = [];
  final Map<InlineSpan, int> spanLengths = {};
  final List<BlockInfo> blocks = [];

  int _currentOffset = 0;
  int _currentBlockIndex = 0;

  /// 当前纯文本偏移量
  int get currentOffset => _currentOffset;

  /// 添加一个 TextSpan 及其对应的纯文本
  void addTextSpan(TextSpan span, {String? plainText}) {
    final text = plainText ?? span.text ?? '';
    if (text.isEmpty && span.children == null) return;

    spans.add(span);

    if (text.isNotEmpty) {
      final startOffset = _currentOffset;
      plainTextBuffer.write(text);
      _currentOffset += text.length;

      mappings.add(SpanMapping(
        spanIndex: spans.length - 1,
        plainTextStart: startOffset,
        plainTextEnd: _currentOffset,
        span: span,
      ));
    }
  }

  /// 添加一个 WidgetSpan（图片、表格等非文本元素）
  /// [plainText] 该组件对应的纯文本内容，用于保持坐标一致性
  void addWidgetSpan(WidgetSpan span, {String? plainText}) {
    spans.add(span);

    final startOffset = _currentOffset;
    
    // 如果提供了纯文本，则写入纯文本；否则使用占位符
    // 注意：这里的纯文本应该尽可能包含完整内容，以便搜索和高亮定位
    final text = plainText ?? '\uFFFC';
    plainTextBuffer.write(text);
    
    // 记录实际长度，供 MdWidget._flattenSpans 使用
    spanLengths[span] = text.length;
    
    _currentOffset += text.length;

    mappings.add(SpanMapping(
      spanIndex: spans.length - 1,
      plainTextStart: startOffset,
      plainTextEnd: _currentOffset,
      span: span,
    ));
  }

  /// 直接添加纯文本（不关联到特定 Span）
  void addPlainText(String text) {
    if (text.isEmpty) return;
    plainTextBuffer.write(text);
    _currentOffset += text.length;
  }

  void addBlock(int startOffset, int endOffset, String tag, String text, String contentHash) {
     blocks.add(BlockInfo(
       index: _currentBlockIndex++,
       globalStart: startOffset,
       globalEnd: endOffset,
       tag: tag,
       text: text,
       contentHash: contentHash,
     ));
  }

  /// 合并另一个 ParseContext 的结果
  void merge(ParseContext other) {
    spanLengths.addAll(other.spanLengths);

    for (var i = 0; i < other.spans.length; i++) {
      final span = other.spans[i];
      // 更新映射的偏移量
      final mapping = other.mappings.firstWhere(
        (m) => m.spanIndex == i,
        orElse: () => SpanMapping(
          spanIndex: -1,
          plainTextStart: 0,
          plainTextEnd: 0,
          span: span,
        ),
      );

      spans.add(span);
      mappings.add(SpanMapping(
        spanIndex: spans.length - 1,
        plainTextStart: _currentOffset + mapping.plainTextStart,
        plainTextEnd: _currentOffset + mapping.plainTextEnd,
        span: span,
      ));
    }

    plainTextBuffer.write(other.plainTextBuffer.toString());
    
    // 合并 BlockInfo
    for (var block in other.blocks) {
         blocks.add(BlockInfo(
           index: _currentBlockIndex++, // Re-index blocks
           globalStart: _currentOffset + block.globalStart,
           globalEnd: _currentOffset + block.globalEnd,
           tag: block.tag,
           text: block.text,
           contentHash: block.contentHash,
         ));
    }

    _currentOffset += other._currentOffset;
  }

  /// 构建最终的解析结果
  MarkdownParseResult build() {
    return MarkdownParseResult(
      spans: List.unmodifiable(spans),
      plainText: plainTextBuffer.toString(),
      mappings: List.unmodifiable(mappings),
      spanLengths: Map.unmodifiable(spanLengths),
      blocks: List.unmodifiable(blocks),
    );
  }
}
