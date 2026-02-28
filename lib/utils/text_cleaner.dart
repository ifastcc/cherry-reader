/// 文本清理工具
///
/// 提供轻量级的文本清理函数，适用于搜索结果展示等场景。
/// 相比完整的 Markdown AST 解析，性能更好。
library text_cleaner;

/// 清理 Markdown 语法符号，提取纯文本
///
/// 适用于搜索结果 snippet 展示，移除影响阅读的格式符号。
/// 使用正则表达式处理，性能好，但不保证 100% 准确。
String cleanMarkdownForDisplay(String text) {
  if (text.isEmpty) return text;

  var result = text;

  // 1. 移除代码块（```...```）
  result = result.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');

  // 2. 移除行内代码（`...`）保留内容
  result = result.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (m) => m.group(1) ?? '',
  );

  // 3. 移除粗体/斜体（**text** / *text* / __text__ / _text_）
  // 注意：先处理两个符号的（**/__），再处理单个符号的（*/_）
  result = result.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'__([^_]+)__'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'\*([^*]+)\*'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'_([^_\s][^_]*[^_\s]|[^_\s])_'),
    (m) => m.group(1) ?? '',
  );

  // 4. 移除删除线（~~text~~）
  result = result.replaceAllMapped(
    RegExp(r'~~([^~]+)~~'),
    (m) => m.group(1) ?? '',
  );

  // 5. 移除标题符号（# ## ### 等）
  result = result.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

  // 6. 移除链接，保留文字 [text](url) -> text
  result = result.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]+\)'),
    (m) => m.group(1) ?? '',
  );

  // 7. 移除图片 ![alt](url) -> (去掉)
  result = result.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '');

  // 8. 移除引用符号 >
  result = result.replaceAll(RegExp(r'^>\s*', multiLine: true), '');

  // 9. 移除无序列表符号 - * +
  result = result.replaceAll(RegExp(r'^[\-\*\+]\s+', multiLine: true), '');

  // 10. 移除有序列表符号 1. 2. 等
  result = result.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

  // 11. 移除表格分隔符 | 和对齐符号
  // 移除纯粹的表格分隔行 |---|---|
  result = result.replaceAll(RegExp(r'^\|[\s\-:|]+\|$', multiLine: true), '');
  // 清理单元格分隔符
  result = result.replaceAll(RegExp(r'\s*\|\s*'), ' ');

  // 12. 移除水平线 --- *** ___
  result = result.replaceAll(RegExp(r'^[\-\*_]{3,}\s*$', multiLine: true), '');

  // 13. 移除 HTML 标签
  result = result.replaceAll(RegExp(r'<[^>]+>'), '');

  // 14. 移除 LaTeX 公式
  result = result.replaceAll(RegExp(r'\$\$[\s\S]*?\$\$'), '');
  result = result.replaceAll(RegExp(r'\$[^$]+\$'), '');

  // 15. 清理多余空白
  result = result.replaceAll(RegExp(r'\n{2,}'), '\n');
  result = result.replaceAll(RegExp(r' {2,}'), ' ');
  result = result.replaceAll(RegExp(r'^\s+', multiLine: true), '');

  return result.trim();
}

/// 为搜索结果生成干净的 snippet
///
/// [content] 原始内容
/// [keyword] 搜索关键词
/// [snippetLength] 关键词前后各保留的字符数
///
/// 返回 (cleanedSnippet, matchStart, matchEnd)
/// - cleanedSnippet: 清理后的文本片段
/// - matchStart: 关键词在 snippet 中的起始位置
/// - matchEnd: 关键词在 snippet 中的结束位置
({String snippet, int matchStart, int matchEnd}) generateSearchSnippet({
  required String content,
  required String keyword,
  int snippetLength = 50,
}) {
  if (content.isEmpty || keyword.isEmpty) {
    return (snippet: content, matchStart: 0, matchEnd: 0);
  }

  // 1. 先清理 Markdown
  final cleanedContent = cleanMarkdownForDisplay(content);

  // 2. 查找关键词位置（忽略大小写）
  final lowerContent = cleanedContent.toLowerCase();
  final lowerKeyword = keyword.toLowerCase();
  final matchIndex = lowerContent.indexOf(lowerKeyword);

  if (matchIndex < 0) {
    // 关键词在清理后的文本中找不到（可能被移除了）
    // 返回开头部分作为 snippet
    final maxLen = (snippetLength * 2).clamp(0, cleanedContent.length);
    return (
      snippet:
          cleanedContent.substring(0, maxLen) +
          (maxLen < cleanedContent.length ? '...' : ''),
      matchStart: 0,
      matchEnd: 0,
    );
  }

  // 3. 计算 snippet 范围
  final snippetStart = (matchIndex - snippetLength).clamp(
    0,
    cleanedContent.length,
  );
  final snippetEnd = (matchIndex + keyword.length + snippetLength).clamp(
    0,
    cleanedContent.length,
  );

  var snippet = cleanedContent.substring(snippetStart, snippetEnd);

  // 4. 添加省略号
  final hasPrefix = snippetStart > 0;
  final hasSuffix = snippetEnd < cleanedContent.length;
  if (hasPrefix) snippet = '...$snippet';
  if (hasSuffix) snippet = '$snippet...';

  // 5. 计算在 snippet 中的匹配位置
  final snippetMatchStart = matchIndex - snippetStart + (hasPrefix ? 3 : 0);
  final snippetMatchEnd = snippetMatchStart + keyword.length;

  return (
    snippet: snippet,
    matchStart: snippetMatchStart,
    matchEnd: snippetMatchEnd,
  );
}

String fixMarkdownStrongAfterCjkPunctuation(String text) {
  if (text.isEmpty) return text;
  if (!text.contains('**')) return text;
  const separator = '\u200B';

  final opener = RegExp(
    r'([0-9A-Za-z\u4E00-\u9FFF])\*\*(?=[:;,.!?，。！？：；、（）【】《》「」『』、“”‘’…—])',
  );
  final closer = RegExp(
    r'([:;,.!?，。！？：；、（）【】《》「」『』、“”‘’…—])\*\*(?=[0-9A-Za-z\u4E00-\u9FFF])',
  );

  String fixInlineCode(String line) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < line.length) {
      final tickAt = line.indexOf('`', i);
      if (tickAt == -1) {
        buffer.write(
          line
              .substring(i)
              .replaceAllMapped(opener, (m) => '${m.group(1)}$separator**')
              .replaceAllMapped(closer, (m) => '${m.group(1)}**$separator'),
        );
        break;
      }

      buffer.write(
        line
            .substring(i, tickAt)
            .replaceAllMapped(opener, (m) => '${m.group(1)}$separator**')
            .replaceAllMapped(closer, (m) => '${m.group(1)}**$separator'),
      );

      var run = 1;
      while (tickAt + run < line.length &&
          line.codeUnitAt(tickAt + run) == 0x60) {
        run++;
      }
      final fence = '`' * run;
      final closeAt = line.indexOf(fence, tickAt + run);
      if (closeAt == -1) {
        buffer.write(line.substring(tickAt));
        break;
      }

      buffer.write(line.substring(tickAt, closeAt + run));
      i = closeAt + run;
    }
    return buffer.toString();
  }

  final lines = text.split('\n');
  var inFence = false;
  for (var idx = 0; idx < lines.length; idx++) {
    final raw = lines[idx];
    final trimmed = raw.trimLeft();
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) {
      lines[idx] = fixInlineCode(raw);
    }
  }
  return lines.join('\n');
}
