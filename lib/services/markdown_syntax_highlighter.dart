import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

/// Markdown 语法高亮处理器
///
/// 核心思想 (第一性原理):
/// 1. 识别所有 Markdown 语法标记的位置（Protected Ranges）
/// 2. 将用户的高亮范围（Highlight Ranges）与语法标记范围进行"差集"运算
/// 3. 仅在非语法标记的纯文本区域插入 HTML <span> 标签
/// 4. 这样既实现了高亮，又绝对保证了 Markdown 语法的完整性
class MarkdownSyntaxHighlighter {
  final String text;
  final List<HighlightRange> highlights;

  MarkdownSyntaxHighlighter(this.text, this.highlights);

  /// 处理并返回带有高亮标签的文本
  String process() {
    if (highlights.isEmpty) return text;

    // 1. 识别受保护的语法范围
    final protectedRanges = _findProtectedRanges(text);

    // 2. 计算安全的高亮范围 (从原始高亮范围中减去受保护范围)
    final safeHighlights = _calculateSafeHighlights(highlights, protectedRanges);

    // 3. 按照位置从后往前插入标签，避免破坏索引
    return _applyHighlights(text, safeHighlights);
  }

  /// 识别 Markdown 语法标记范围
  List<TextRange> _findProtectedRanges(String text) {
    final ranges = <TextRange>[];

    // 正则表达式定义 Markdown 语法标记
    // 注意：我们只匹配"标记本身"，而不是标记包含的内容
    final patterns = [
      // 标题标记 (e.g. "## ")
      RegExp(r'^#{1,6}\s', multiLine: true),
      
      // 粗体/斜体标记 (e.g. "**", "__", "*", "_")
      // 仅匹配边界标记
      RegExp(r'(\*\*|__|\*|_)'),
      
      // 代码块标记 (e.g. "```", "`")
      RegExp(r'(`{1,3})'),
      
      // 链接和图片语法结构: [, ], (, ), ![
      // 我们不仅要保护括号本身，还要保护 URL 部分，因为如果在 URL 中插入 span 会破坏链接
      // 匹配: [text](url) 或 ![alt](url)
      // 策略: 保护 `[` `]` `(` `)` `![` 这些字符本身
      // 以及 `(...)` 里面的内容 (URL)
      RegExp(r'!\[|\[|\]'),
      RegExp(r'\([^\)]+\)'), // 保护链接的 URL 部分 (content inside parens)
      
      // HTML 标签 (e.g. <br>, <span>) - 避免在高亮标签内部再插入高亮
      RegExp(r'<[^>]+>'),
      
      // 引用标记
      RegExp(r'^>\s', multiLine: true),
      
      // 列表标记
      RegExp(r'^(\s*[-*+]|\s*\d+\.)\s+', multiLine: true),
      
      // 分割线
      RegExp(r'^[\*\-_]{3,}\s*$', multiLine: true),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        ranges.add(TextRange(start: match.start, end: match.end));
      }
    }

    // 合并重叠的范围并排序
    return _mergeRanges(ranges);
  }

  /// 合并重叠或相邻的范围
  List<TextRange> _mergeRanges(List<TextRange> ranges) {
    if (ranges.isEmpty) return [];

    // 按起始位置排序
    ranges.sort((a, b) => a.start.compareTo(b.start));

    final merged = <TextRange>[];
    var current = ranges[0];

    for (int i = 1; i < ranges.length; i++) {
      final next = ranges[i];
      if (next.start <= current.end) {
        // 重叠或相邻，合并
        current = TextRange(
          start: current.start, 
          end: next.end > current.end ? next.end : current.end
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }

  /// 计算安全的高亮范围
  /// 算法: Safe = Highlight - Protected
  List<HighlightRange> _calculateSafeHighlights(
    List<HighlightRange> rawHighlights, 
    List<TextRange> protectedRanges
  ) {
    final safeHighlights = <HighlightRange>[];

    for (final highlight in rawHighlights) {
      var currentStart = highlight.start;
      final currentEnd = highlight.end;
      final color = highlight.color;
      final styleType = highlight.styleType;

      // 遍历所有受保护范围，切分高亮范围
      for (final protected in protectedRanges) {
        // 如果受保护范围在当前高亮范围之前，跳过
        if (protected.end <= currentStart) continue;
        
        // 如果受保护范围在当前高亮范围之后，结束检查
        if (protected.start >= currentEnd) break;

        // 此时 protected 与 [currentStart, currentEnd] 有交集

        // 1. 添加交集之前的高亮部分 (如果是有效文本)
        if (currentStart < protected.start) {
          safeHighlights.add(HighlightRange(
            id: highlight.id,
            start: currentStart,
            end: protected.start,
            color: color,
            styleType: styleType,
          ));
        }

        // 2. 跳过受保护部分，更新 currentStart
        currentStart = protected.end > currentStart ? protected.end : currentStart;

        // 如果已经超出了高亮范围，提前结束
        if (currentStart >= currentEnd) break;
      }

      // 添加剩余的高亮部分
      if (currentStart < currentEnd) {
        safeHighlights.add(HighlightRange(
          id: highlight.id,
          start: currentStart,
          end: currentEnd,
          color: color,
          styleType: styleType,
        ));
      }
    }

    return safeHighlights;
  }

  /// 应用高亮：从后往前插入 HTML 标签
  String _applyHighlights(String text, List<HighlightRange> safeHighlights) {
    // 按起始位置排序
    safeHighlights.sort((a, b) => a.start.compareTo(b.start));

    final buffer = StringBuffer();
    int currentPos = 0;

    for (final range in safeHighlights) {
       if (range.start < currentPos) continue; // 防止回退（理论上不会发生）

       // 添加未高亮的文本
       if (range.start > currentPos) {
         buffer.write(text.substring(currentPos, range.start));
       }

       // 生成高亮 HTML
       // 将颜色转换为 8 位 ARGB Hex 字符串，保留透明度
       final colorHex = range.color.value.toRadixString(16).padLeft(8, '0');
       
       // c 属性存储颜色的 hex 值
       // t 属性存储样式类型 (background/underline)
       // i 属性存储 ID
       final type = range.styleType ?? 'background';
       final id = range.id ?? '';
       buffer.write('<highlight c="$colorHex" t="$type" i="$id">');
       buffer.write(text.substring(range.start, range.end));
       buffer.write('</highlight>');

       currentPos = range.end;
    }

    // 添加剩余文本
    if (currentPos < text.length) {
      buffer.write(text.substring(currentPos));
    }

    return buffer.toString();
  }
}

/// 高亮范围数据模型
class HighlightRange {
  final String? id; // 关联的高亮数据 ID
  final int start;
  final int end;
  final Color color;
  final String? styleType; // 'background' 或 'underline'

  HighlightRange({
    this.id,
    required this.start,
    required this.end,
    required this.color,
    this.styleType,
  });
}

/// 解析 <highlight> 标签的语法规则
/// 匹配格式: <highlight c="RRGGBB" t="type" i="id">text</highlight>
class HighlightSyntax extends md.InlineSyntax {
  // 更新正则以匹配 i="id" 属性，支持 6 位或 8 位颜色 hex
  HighlightSyntax() : super(r'<highlight c="([a-fA-F0-9]{6,8})" t="([^\"]+)" i="([^\"]*)">(.+?)</highlight>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // Safety checks for null matches, although regex should prevent this
    final content = match[4];
    final colorHex = match[1];
    final styleType = match[2];
    final id = match[3];

    if (content == null || colorHex == null || styleType == null) {
      return false;
    }

    // 创建一个 Element，tag 为 'highlight'
    final element = md.Element.text('highlight', content);
    
    // 将捕获的属性存入 attributes
    element.attributes['c'] = colorHex; // 颜色 hex
    element.attributes['t'] = styleType; // 样式类型
    if (id != null) {
      element.attributes['i'] = id; // ID
    }
    
    // 内容是第四个捕获组
    element.children!.clear();
    element.children!.add(md.Text(content));
    
    parser.addNode(element);
    return true;
  }
}
