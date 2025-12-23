import 'package:markdown/markdown.dart' as md;

/// SSML 生成配置
class SsmlConfig {
  // 标题配置
  final String h1BreakBefore;
  final String h1BreakAfter;
  final String h1Pitch;
  final String h2BreakBefore;
  final String h2BreakAfter;
  final String h2Pitch;
  final String h3BreakBefore;
  final String h3BreakAfter;

  // 段落和列表
  final String paragraphBreak;
  final String listItemBreak;

  // 引用块
  final String blockquoteRate;
  final String blockquotePitch;

  // 代码处理
  final bool announceCodeBlocks;
  final String codeBlockAnnouncement;
  final bool readShortInlineCode;
  final int maxInlineCodeLength;
  final String inlineCodeRate;

  // 分隔线
  final String hrBreak;

  // 强调
  final String strongEmphasis;
  final String emEmphasis;

  // ========== 句内标点停顿配置 ==========
  /// 是否启用句内标点停顿（逗号、句号等处自动插入停顿）
  final bool enablePunctuationBreaks;

  /// 全局节奏倍率 (1.0 = 正常, 1.5 = 慢 50%, 0.7 = 快 30%)
  final double rhythmScale;

  // 中文标点停顿（毫秒）
  final int commaBreakMs;      // 逗号 ，
  final int enumBreakMs;       // 顿号 、
  final int semicolonBreakMs;  // 分号 ；
  final int colonBreakMs;      // 冒号 ：
  final int periodBreakMs;     // 句号 。
  final int questionBreakMs;   // 问号 ？
  final int exclamationBreakMs; // 感叹号 ！
  final int ellipsisBreakMs;   // 省略号 ……
  final int dashBreakMs;       // 破折号 ——
  final int quoteEndBreakMs;   // 引号结束 "』」

  // 英文标点停顿
  final int enCommaBreakMs;
  final int enSemicolonBreakMs;
  final int enColonBreakMs;
  final int enPeriodBreakMs;
  final int enQuestionBreakMs;
  final int enExclamationBreakMs;

  const SsmlConfig({
    // 标题
    this.h1BreakBefore = '600ms',
    this.h1BreakAfter = '400ms',
    this.h1Pitch = '+5%',
    this.h2BreakBefore = '450ms',
    this.h2BreakAfter = '350ms',
    this.h2Pitch = '+3%',
    this.h3BreakBefore = '350ms',
    this.h3BreakAfter = '250ms',
    // 段落和列表
    this.paragraphBreak = '400ms',
    this.listItemBreak = '200ms',
    // 引用
    this.blockquoteRate = '-10%',
    this.blockquotePitch = '-3%',
    // 代码
    this.announceCodeBlocks = false,
    this.codeBlockAnnouncement = '这里有一段代码',
    this.readShortInlineCode = true,
    this.maxInlineCodeLength = 30,
    this.inlineCodeRate = '-10%',
    // 分隔线
    this.hrBreak = '700ms',
    // 强调
    this.strongEmphasis = 'strong',
    this.emEmphasis = 'moderate',
    // 句内标点停顿（默认启用，模拟自然呼吸节奏）
    this.enablePunctuationBreaks = true,
    this.rhythmScale = 1.0,
    this.commaBreakMs = 180,       // 逗号：短停顿，喘息点
    this.enumBreakMs = 120,        // 顿号：更短，并列词项
    this.semicolonBreakMs = 280,   // 分号：中停顿，分句
    this.colonBreakMs = 220,       // 冒号：中停顿，引出内容
    this.periodBreakMs = 450,      // 句号：长停顿，句子结束
    this.questionBreakMs = 500,    // 问号：略长，疑问语调需要缓冲
    this.exclamationBreakMs = 450, // 感叹号：长停顿，情感表达
    this.ellipsisBreakMs = 350,    // 省略号：意犹未尽
    this.dashBreakMs = 250,        // 破折号：解释性停顿
    this.quoteEndBreakMs = 120,    // 引号结束：短停顿
    this.enCommaBreakMs = 180,
    this.enSemicolonBreakMs = 280,
    this.enColonBreakMs = 220,
    this.enPeriodBreakMs = 450,
    this.enQuestionBreakMs = 500,
    this.enExclamationBreakMs = 450,
  });

  /// 默认配置
  static const SsmlConfig defaultConfig = SsmlConfig();

  /// 更自然的朗读配置（停顿更短）
  static const SsmlConfig naturalConfig = SsmlConfig(
    h1BreakBefore: '500ms',
    h1BreakAfter: '350ms',
    h2BreakBefore: '400ms',
    h2BreakAfter: '300ms',
    h3BreakBefore: '300ms',
    h3BreakAfter: '200ms',
    paragraphBreak: '350ms',
    listItemBreak: '150ms',
    hrBreak: '500ms',
  );

  /// 有声书风格（停顿更长，更有节奏）
  static const SsmlConfig audiobookConfig = SsmlConfig(
    h1BreakBefore: '800ms',
    h1BreakAfter: '500ms',
    h1Pitch: '+8%',
    h2BreakBefore: '600ms',
    h2BreakAfter: '400ms',
    h2Pitch: '+5%',
    h3BreakBefore: '450ms',
    h3BreakAfter: '300ms',
    paragraphBreak: '500ms',
    listItemBreak: '250ms',
    blockquoteRate: '-15%',
    blockquotePitch: '-5%',
    hrBreak: '900ms',
    // 有声书风格：更明显的句内停顿
    rhythmScale: 1.2,
    commaBreakMs: 250,
    enumBreakMs: 180,
    semicolonBreakMs: 350,
    colonBreakMs: 300,
    periodBreakMs: 600,
    questionBreakMs: 650,
    exclamationBreakMs: 600,
    ellipsisBreakMs: 450,
    dashBreakMs: 320,
  );
}

/// Markdown AST 转 SSML 的转换器
///
/// 基于 markdown 包的语法树解析，将 Markdown 文本转换为 SSML 格式，
/// 使 TTS 朗读更加自然、有节奏。
class MarkdownToSsmlConverter {
  final SsmlConfig config;

  MarkdownToSsmlConverter({this.config = const SsmlConfig()});

  /// 将 Markdown 转换为 SSML 片段（不包含外层 speak/voice 标签）
  ///
  /// 返回可以直接嵌入到 <voice> 标签内的 SSML 内容
  String convert(String markdown) {
    if (markdown.trim().isEmpty) {
      return '';
    }

    // 预处理：移除不适合朗读的内容
    String preprocessed = _preprocess(markdown);

    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
    );
    final nodes = document.parse(preprocessed);
    final buffer = StringBuffer();
    _visitNodes(nodes, buffer, isRoot: true);

    // 清理多余的空白和换行
    String result = buffer.toString();
    result = result.replaceAll(RegExp(r'\n{2,}'), '\n');

    // 合并连续的 break 标签（保留后一个）
    // 注意：Dart 的 replaceAll 不支持 $1/$2 反向引用，必须用 replaceAllMapped
    result = result.replaceAllMapped(
      RegExp(r'(<break[^>]*/>)\s*(<break[^>]*/>)'),
      (match) => match.group(2)!,
    );

    return result.trim();
  }

  /// 预处理：移除不适合朗读的内容
  String _preprocess(String text) {
    String result = text;

    // 1. 移除 LaTeX 块级公式 $$...$$
    result = result.replaceAll(RegExp(r'\$\$[\s\S]*?\$\$'), ' ');

    // 2. 移除 LaTeX 行内公式 $...$（但不匹配单独的 $ 符号如价格 $100）
    // 匹配 $...$，其中内容不能以空格开头或结尾，且至少有一个非空格字符
    result = result.replaceAll(RegExp(r'\$([^\s$][^$]*?[^\s$]|[^\s$])\$'), ' ');

    // 3. 移除 HTML 标签（如 <br>, <div> 等）
    result = result.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // 4. 移除 HTML 实体
    result = result.replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ');
    result = result.replaceAll(RegExp(r'&#\d+;'), ' ');

    // 5. 清理多余空格
    result = result.replaceAll(RegExp(r' {2,}'), ' ');

    return result;
  }

  /// 将 Markdown 转换为完整的 SSML 文档
  ///
  /// 包含完整的 speak 和 voice 标签，可直接发送给 TTS API
  String convertToFullSsml({
    required String markdown,
    required String voiceName,
    String rate = '+0%',
    String? style,
    String? role,
  }) {
    final content = convert(markdown);

    if (style != null && style.isNotEmpty && style != 'general') {
      return '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="zh-CN">
<voice name="$voiceName">
<mstts:express-as style="$style"${role != null && role.isNotEmpty ? ' role="$role"' : ''}>
<prosody rate="$rate">
$content
</prosody>
</mstts:express-as>
</voice>
</speak>''';
    } else {
      return '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
<voice name="$voiceName">
<prosody rate="$rate">
$content
</prosody>
</voice>
</speak>''';
    }
  }

  void _visitNodes(List<md.Node> nodes, StringBuffer buffer, {bool isRoot = false}) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is md.Text) {
        // 处理文本节点，可选添加标点停顿
        if (config.enablePunctuationBreaks) {
          buffer.write(_processTextWithPunctuation(node.text));
        } else {
          buffer.write(_escapeXml(node.text));
        }
      } else if (node is md.Element) {
        _visitElement(node, buffer);
      }
    }
  }

  /// 处理文本并在标点处插入停顿
  ///
  /// 这是控制朗读节奏的核心方法：
  /// - 在逗号、顿号处插入短停顿（呼吸点）
  /// - 在分号、冒号处插入中停顿（分句点）
  /// - 在句号、问号、感叹号处插入长停顿（句末）
  String _processTextWithPunctuation(String text) {
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // 先写入字符（转义）
      buffer.write(_escapeXmlChar(char));

      // 根据标点决定是否插入停顿
      final breakMs = _getPunctuationBreakMs(char, text, i);
      if (breakMs > 0) {
        // 应用全局节奏倍率
        final scaledMs = (breakMs * config.rhythmScale).round();
        buffer.write('<break time="${scaledMs}ms"/>');
      }
    }

    return buffer.toString();
  }

  /// 获取标点符号对应的停顿时间（毫秒）
  int _getPunctuationBreakMs(String char, String fullText, int index) {
    switch (char) {
      // ========== 中文标点 ==========
      case '，':
        return config.commaBreakMs;
      case '、':
        return config.enumBreakMs;
      case '；':
        return config.semicolonBreakMs;
      case '：':
        return config.colonBreakMs;
      case '。':
        return config.periodBreakMs;
      case '？':
        return config.questionBreakMs;
      case '！':
        return config.exclamationBreakMs;
      case '…':
        // 省略号：只在最后一个 … 处停顿
        if (index + 1 < fullText.length && fullText[index + 1] == '…') {
          return 0;
        }
        return config.ellipsisBreakMs;
      case '—':
        // 破折号：只在最后一个 — 处停顿
        if (index + 1 < fullText.length && fullText[index + 1] == '—') {
          return 0;
        }
        return config.dashBreakMs;
      // 中文引号结束（短停顿）
      case '"':
      case "'":  // 中文右单引号
      case '」':
      case '』':
      case '）':
      case '】':
        return config.quoteEndBreakMs;

      // ========== 英文标点 ==========
      case ',':
        return config.enCommaBreakMs;
      case ';':
        return config.enSemicolonBreakMs;
      case ':':
        return config.enColonBreakMs;
      case '.':
        // 判断是否是句末句号（而非缩写）
        if (index + 1 >= fullText.length) {
          return config.enPeriodBreakMs;
        }
        final nextChar = fullText[index + 1];
        if (nextChar == ' ' || nextChar == '\n' || nextChar == '\r') {
          return config.enPeriodBreakMs;
        }
        return 0;
      case '!':
        return config.enExclamationBreakMs;
      case '?':
        return config.enQuestionBreakMs;

      default:
        return 0;
    }
  }

  /// 单字符 XML 转义
  String _escapeXmlChar(String char) {
    switch (char) {
      case '&':
        return '&amp;';
      case '<':
        return '&lt;';
      case '>':
        return '&gt;';
      case '"':
        return '&quot;';
      case "'":
        return '&apos;';
      default:
        return char;
    }
  }

  void _visitElement(md.Element element, StringBuffer buffer) {
    switch (element.tag) {
      // 标题
      case 'h1':
        buffer.write('<break time="${config.h1BreakBefore}"/>');
        buffer.write('<prosody pitch="${config.h1Pitch}">');
        _visitChildren(element, buffer);
        buffer.write('</prosody>');
        buffer.write('<break time="${config.h1BreakAfter}"/>');
        break;

      case 'h2':
        buffer.write('<break time="${config.h2BreakBefore}"/>');
        buffer.write('<prosody pitch="${config.h2Pitch}">');
        _visitChildren(element, buffer);
        buffer.write('</prosody>');
        buffer.write('<break time="${config.h2BreakAfter}"/>');
        break;

      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        buffer.write('<break time="${config.h3BreakBefore}"/>');
        _visitChildren(element, buffer);
        buffer.write('<break time="${config.h3BreakAfter}"/>');
        break;

      // 强调
      case 'strong':
      case 'b':
        buffer.write('<emphasis level="${config.strongEmphasis}">');
        _visitChildren(element, buffer);
        buffer.write('</emphasis>');
        break;

      case 'em':
      case 'i':
        buffer.write('<emphasis level="${config.emEmphasis}">');
        _visitChildren(element, buffer);
        buffer.write('</emphasis>');
        break;

      // 引用块
      case 'blockquote':
        buffer.write('<prosody rate="${config.blockquoteRate}" pitch="${config.blockquotePitch}">');
        _visitChildren(element, buffer);
        buffer.write('</prosody>');
        buffer.write('<break time="${config.paragraphBreak}"/>');
        break;

      // 列表
      case 'ul':
      case 'ol':
        _visitChildren(element, buffer);
        buffer.write('<break time="${config.listItemBreak}"/>');
        break;

      case 'li':
        buffer.write('<break time="${config.listItemBreak}"/>');
        _visitChildren(element, buffer);
        break;

      // 段落
      case 'p':
        _visitChildren(element, buffer);
        buffer.write('<break time="${config.paragraphBreak}"/>');
        break;

      // 行内代码
      case 'code':
        final text = _getTextContent(element);
        // 检查是否是代码块内的 code（有 class 属性通常表示代码块）
        final isCodeBlock = element.attributes.containsKey('class');

        if (isCodeBlock) {
          // 代码块处理
          if (config.announceCodeBlocks) {
            buffer.write('<break time="200ms"/>');
            buffer.write(config.codeBlockAnnouncement);
            buffer.write('<break time="200ms"/>');
          }
        } else {
          // 行内代码
          if (config.readShortInlineCode && text.length <= config.maxInlineCodeLength) {
            buffer.write('<prosody rate="${config.inlineCodeRate}">');
            buffer.write(_escapeXml(text));
            buffer.write('</prosody>');
          }
          // 超长的行内代码跳过
        }
        break;

      // 代码块
      case 'pre':
        if (config.announceCodeBlocks) {
          buffer.write('<break time="300ms"/>');
          buffer.write(config.codeBlockAnnouncement);
          buffer.write('<break time="300ms"/>');
        }
        // 跳过代码块内容
        break;

      // 链接 - 只读链接文字
      case 'a':
        _visitChildren(element, buffer);
        break;

      // 图片 - 跳过
      case 'img':
        // 可选：读出 alt 文字
        // final alt = element.attributes['alt'];
        // if (alt != null && alt.isNotEmpty) {
        //   buffer.write('图片：$alt');
        // }
        break;

      // 分隔线
      case 'hr':
        buffer.write('<break time="${config.hrBreak}"/>');
        break;

      // 删除线 - 跳过
      case 'del':
      case 's':
      case 'strike':
        // 被删除的内容不朗读
        break;

      // 换行
      case 'br':
        buffer.write('<break time="150ms"/>');
        break;

      // 表格 - 简化处理
      case 'table':
        buffer.write('<break time="300ms"/>');
        buffer.write('这里有一个表格');
        buffer.write('<break time="300ms"/>');
        // 跳过表格内容，表格不适合朗读
        break;

      case 'thead':
      case 'tbody':
      case 'tr':
      case 'th':
      case 'td':
        // 表格元素跳过
        break;

      // 其他元素 - 递归处理子元素
      default:
        _visitChildren(element, buffer);
    }
  }

  void _visitChildren(md.Element element, StringBuffer buffer) {
    if (element.children != null) {
      _visitNodes(element.children!, buffer);
    }
  }

  /// 获取元素内的纯文本内容
  String _getTextContent(md.Element element) {
    final buffer = StringBuffer();
    _collectText(element, buffer);
    return buffer.toString();
  }

  void _collectText(md.Node node, StringBuffer buffer) {
    if (node is md.Text) {
      buffer.write(node.text);
    } else if (node is md.Element && node.children != null) {
      for (final child in node.children!) {
        _collectText(child, buffer);
      }
    }
  }

  /// XML 转义
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// 便捷函数：将 Markdown 转换为 SSML 片段
String markdownToSsml(String markdown, {SsmlConfig? config}) {
  final converter = MarkdownToSsmlConverter(config: config ?? const SsmlConfig());
  return converter.convert(markdown);
}

/// 便捷函数：提取纯文本（不带任何 SSML 标签）
String markdownToPlainText(String markdown) {
  if (markdown.trim().isEmpty) {
    return '';
  }

  // 预处理：移除不适合朗读的内容
  String preprocessed = _preprocessForPlainText(markdown);

  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubWeb,
    encodeHtml: false,
  );
  final nodes = document.parse(preprocessed);
  final buffer = StringBuffer();
  _extractPlainText(nodes, buffer);

  // 清理多余空白
  String result = buffer.toString();
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  result = result.replaceAll(RegExp(r' {2,}'), ' ');

  return result.trim();
}

/// 预处理（用于纯文本提取）
String _preprocessForPlainText(String text) {
  String result = text;

  // 1. 移除 LaTeX 块级公式 $$...$$
  result = result.replaceAll(RegExp(r'\$\$[\s\S]*?\$\$'), ' ');

  // 2. 移除 LaTeX 行内公式 $...$
  result = result.replaceAll(RegExp(r'\$([^\s$][^$]*?[^\s$]|[^\s$])\$'), ' ');

  // 3. 移除 HTML 标签
  result = result.replaceAll(RegExp(r'<[^>]+>'), ' ');

  // 4. 移除 HTML 实体
  result = result.replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ');
  result = result.replaceAll(RegExp(r'&#\d+;'), ' ');

  // 5. 清理多余空格
  result = result.replaceAll(RegExp(r' {2,}'), ' ');

  return result;
}

void _extractPlainText(List<md.Node> nodes, StringBuffer buffer) {
  for (final node in nodes) {
    if (node is md.Text) {
      buffer.write(node.text);
    } else if (node is md.Element) {
      // 跳过的元素
      if (['pre', 'code', 'img', 'del', 's', 'strike', 'table', 'thead', 'tbody', 'tr', 'th', 'td']
          .contains(node.tag)) {
        // 对于有 class 的 code（代码块内），跳过
        if (node.tag == 'code' && node.attributes.containsKey('class')) {
          continue;
        }
        // 对于普通 code（行内代码），保留短的
        if (node.tag == 'code') {
          final text = _getPlainTextContent(node);
          if (text.length <= 30) {
            buffer.write(text);
          }
          continue;
        }
        continue;
      }

      // 块级元素后加换行
      if (node.children != null) {
        _extractPlainText(node.children!, buffer);
      }

      if (['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'blockquote', 'br'].contains(node.tag)) {
        buffer.write('\n');
      }
    }
  }
}

String _getPlainTextContent(md.Element element) {
  final buffer = StringBuffer();
  if (element.children != null) {
    for (final child in element.children!) {
      if (child is md.Text) {
        buffer.write(child.text);
      } else if (child is md.Element && child.children != null) {
        buffer.write(_getPlainTextContent(child));
      }
    }
  }
  return buffer.toString();
}
