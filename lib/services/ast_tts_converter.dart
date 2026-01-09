import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart' as md;
import '../models/tts_segment.dart';

/// SSML 生成配置
class TtsSsmlConfig {
  // ========== 全局节奏控制 ==========
  /// 全局节奏倍率 (1.0 = 正常, 1.5 = 慢 50%, 0.7 = 快 30%)
  /// 影响所有停顿时间
  final double rhythmScale;

  // ========== 停顿时间（毫秒，会乘以 rhythmScale）==========
  // 标题
  final int h1BreakBeforeMs;
  final int h1BreakAfterMs;
  final int h2BreakBeforeMs;
  final int h2BreakAfterMs;
  final int h3BreakBeforeMs;
  final int h3BreakAfterMs;

  // 段落和列表
  final int paragraphBreakMs;
  final int listItemBreakMs;

  // 分隔线
  final int hrBreakMs;

  // 换行
  final int lineBreakMs;

  // ========== 句内标点停顿（毫秒，会乘以 rhythmScale）==========
  /// 是否启用句内标点停顿（逗号、句号等处自动插入停顿）
  final bool enablePunctuationBreaks;

  // 中文标点停顿
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

  // 英文标点停顿（与中文对应）
  final int enCommaBreakMs;
  final int enSemicolonBreakMs;
  final int enColonBreakMs;
  final int enPeriodBreakMs;
  final int enQuestionBreakMs;
  final int enExclamationBreakMs;

  // ========== 语调控制 ==========
  final String h1Pitch;
  final String h2Pitch;
  final String h3Pitch;

  // 引用块
  final String blockquoteRate;
  final String blockquotePitch;

  // 代码
  final String inlineCodeRate;

  // 强调
  final String strongEmphasis;
  final String emEmphasis;

  // ========== 功能开关 ==========
  // 代码处理
  final bool announceCodeBlocks;
  final String codeBlockAnnouncement;
  final bool readShortInlineCode;
  final int maxInlineCodeLength;

  // 链接
  final bool announceLinks;
  final String linkAnnouncement;

  // 图片
  final bool readImageAlt;
  final String imagePrefix;

  // 有序列表
  final bool readListNumbers;
  final String listNumberFormat; // 'short' = "1、", 'long' = "第1点，"
  final bool announceListCount;  // 预告列表项数 "下面有N点"

  // 英文处理
  final bool wrapEnglishWithLang;
  final String englishLang;

  const TtsSsmlConfig({
    // 全局节奏
    this.rhythmScale = 1.0,
    
    // ===== 层级5：话题切换（明确分隔） =====
    this.h1BreakBeforeMs = 1000,
    this.h1BreakAfterMs = 1200,
    this.h2BreakBeforeMs = 800,
    this.h2BreakAfterMs = 900,
    this.h3BreakBeforeMs = 500,
    this.h3BreakAfterMs = 600,
    this.hrBreakMs = 1500,
    
    // ===== 层级4：段落节奏（思考间隙） =====
    this.paragraphBreakMs = 700,
    this.listItemBreakMs = 400,
    this.lineBreakMs = 200,
    
    // ===== 层级3：句子节奏（完整呼吸） =====
    this.enablePunctuationBreaks = true,
    this.periodBreakMs = 400,
    this.questionBreakMs = 450,
    this.exclamationBreakMs = 400,
    this.ellipsisBreakMs = 350,
    this.enPeriodBreakMs = 400,
    this.enQuestionBreakMs = 450,
    this.enExclamationBreakMs = 400,
    
    // ===== 层级2：子句节奏（短呼吸） =====
    this.commaBreakMs = 150,
    this.semicolonBreakMs = 250,
    this.colonBreakMs = 200,
    this.dashBreakMs = 220,
    this.enCommaBreakMs = 150,
    this.enSemicolonBreakMs = 250,
    this.enColonBreakMs = 200,
    
    // ===== 层级1：词组节奏（微微停顿） =====
    this.enumBreakMs = 80,
    this.quoteEndBreakMs = 80,
    
    // ===== 语调设计 =====
    this.h1Pitch = '+8%',
    this.h2Pitch = '+5%',
    this.h3Pitch = '+3%',
    this.blockquoteRate = '-12%',
    this.blockquotePitch = '-5%',
    this.inlineCodeRate = '-15%',
    this.strongEmphasis = 'strong',
    this.emEmphasis = 'moderate',
    
    // ===== 内容策略 =====
    this.announceCodeBlocks = true,
    this.codeBlockAnnouncement = '接下来是一段代码',
    this.readShortInlineCode = true,
    this.maxInlineCodeLength = 20,
    this.announceLinks = false,
    this.linkAnnouncement = '链接',
    this.readImageAlt = true,
    this.imagePrefix = '图片：',
    this.readListNumbers = true,
    this.listNumberFormat = 'short',
    this.announceListCount = true,
    this.wrapEnglishWithLang = false,
    this.englishLang = 'en-US',
  });

  // ========== 便捷方法：获取实际停顿时间（应用节奏倍率）==========
  String get h1BreakBefore => '${(h1BreakBeforeMs * rhythmScale).round()}ms';
  String get h1BreakAfter => '${(h1BreakAfterMs * rhythmScale).round()}ms';
  String get h2BreakBefore => '${(h2BreakBeforeMs * rhythmScale).round()}ms';
  String get h2BreakAfter => '${(h2BreakAfterMs * rhythmScale).round()}ms';
  String get h3BreakBefore => '${(h3BreakBeforeMs * rhythmScale).round()}ms';
  String get h3BreakAfter => '${(h3BreakAfterMs * rhythmScale).round()}ms';
  String get paragraphBreak => '${(paragraphBreakMs * rhythmScale).round()}ms';
  String get listItemBreak => '${(listItemBreakMs * rhythmScale).round()}ms';
  String get hrBreak => '${(hrBreakMs * rhythmScale).round()}ms';
  String get lineBreak => '${(lineBreakMs * rhythmScale).round()}ms';

  /// 复制并修改节奏
  TtsSsmlConfig withRhythmScale(double scale) {
    return TtsSsmlConfig(
      rhythmScale: scale,
      h1BreakBeforeMs: h1BreakBeforeMs,
      h1BreakAfterMs: h1BreakAfterMs,
      h2BreakBeforeMs: h2BreakBeforeMs,
      h2BreakAfterMs: h2BreakAfterMs,
      h3BreakBeforeMs: h3BreakBeforeMs,
      h3BreakAfterMs: h3BreakAfterMs,
      paragraphBreakMs: paragraphBreakMs,
      listItemBreakMs: listItemBreakMs,
      hrBreakMs: hrBreakMs,
      lineBreakMs: lineBreakMs,
      enablePunctuationBreaks: enablePunctuationBreaks,
      commaBreakMs: commaBreakMs,
      enumBreakMs: enumBreakMs,
      semicolonBreakMs: semicolonBreakMs,
      colonBreakMs: colonBreakMs,
      periodBreakMs: periodBreakMs,
      questionBreakMs: questionBreakMs,
      exclamationBreakMs: exclamationBreakMs,
      ellipsisBreakMs: ellipsisBreakMs,
      dashBreakMs: dashBreakMs,
      quoteEndBreakMs: quoteEndBreakMs,
      enCommaBreakMs: enCommaBreakMs,
      enSemicolonBreakMs: enSemicolonBreakMs,
      enColonBreakMs: enColonBreakMs,
      enPeriodBreakMs: enPeriodBreakMs,
      enQuestionBreakMs: enQuestionBreakMs,
      enExclamationBreakMs: enExclamationBreakMs,
      h1Pitch: h1Pitch,
      h2Pitch: h2Pitch,
      h3Pitch: h3Pitch,
      blockquoteRate: blockquoteRate,
      blockquotePitch: blockquotePitch,
      inlineCodeRate: inlineCodeRate,
      strongEmphasis: strongEmphasis,
      emEmphasis: emEmphasis,
      announceCodeBlocks: announceCodeBlocks,
      codeBlockAnnouncement: codeBlockAnnouncement,
      readShortInlineCode: readShortInlineCode,
      maxInlineCodeLength: maxInlineCodeLength,
      announceLinks: announceLinks,
      linkAnnouncement: linkAnnouncement,
      readImageAlt: readImageAlt,
      imagePrefix: imagePrefix,
      readListNumbers: readListNumbers,
      listNumberFormat: listNumberFormat,
      announceListCount: announceListCount,
      wrapEnglishWithLang: wrapEnglishWithLang,
      englishLang: englishLang,
    );
  }

  // ========== 预设配置 ==========

  static const TtsSsmlConfig defaultConfig = TtsSsmlConfig();

  /// 快速朗读（节奏更快，停顿更短，关闭句内停顿）
  static const TtsSsmlConfig fastConfig = TtsSsmlConfig(
    rhythmScale: 0.6,
    enablePunctuationBreaks: false,
  );

  /// 舒缓朗读（节奏更慢，停顿更长）
  static const TtsSsmlConfig relaxedConfig = TtsSsmlConfig(
    rhythmScale: 1.3,
    commaBreakMs: 220,
    periodBreakMs: 550,
    questionBreakMs: 600,
    exclamationBreakMs: 550,
  );

  /// 有声书风格（停顿更长，语调变化更大，更有节奏感）
  static const TtsSsmlConfig audiobookConfig = TtsSsmlConfig(
    rhythmScale: 1.2,
    h1BreakBeforeMs: 1000,
    h1BreakAfterMs: 1200,
    h2BreakBeforeMs: 800,
    h2BreakAfterMs: 1000,
    h3BreakBeforeMs: 600,
    h3BreakAfterMs: 700,
    paragraphBreakMs: 800,
    listItemBreakMs: 400,
    hrBreakMs: 1200,
    commaBreakMs: 250,
    enumBreakMs: 180,
    semicolonBreakMs: 350,
    colonBreakMs: 300,
    periodBreakMs: 600,
    questionBreakMs: 650,
    exclamationBreakMs: 600,
    ellipsisBreakMs: 450,
    dashBreakMs: 320,
    h1Pitch: '+8%',
    h2Pitch: '+5%',
    blockquoteRate: '-15%',
    blockquotePitch: '-5%',
    readListNumbers: true,
    listNumberFormat: 'long',
  );
}

/// TTS 段落（包含纯文本和 SSML）
class TtsSegmentWithSsml {
  final int index;
  final String plainText;  // 处理后的纯文本（用于 TTS 合成、缓存 key）
  final String rawText;    // 原始格式文本（保留换行，用于显示）
  final String ssmlContent; // SSML 内容（不含外层 speak/voice 标签）
  final int startOffset;
  final int endOffset;

  TtsSegmentWithSsml({
    required this.index,
    required this.plainText,
    required this.rawText,
    required this.ssmlContent,
    required this.startOffset,
    required this.endOffset,
  });

  /// 生成完整的 SSML（包含 speak/voice 标签）
  String toFullSsml({
    required String voiceName,
    String rate = '+0%',
    String? style,
    String? role,
  }) {
    if (style != null && style.isNotEmpty && style != 'general') {
      return '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="zh-CN">
<voice name="$voiceName">
<mstts:express-as style="$style"${role != null && role.isNotEmpty ? ' role="$role"' : ''}>
<prosody rate="$rate">
$ssmlContent
</prosody>
</mstts:express-as>
</voice>
</speak>''';
    } else {
      return '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
<voice name="$voiceName">
<prosody rate="$rate">
$ssmlContent
</prosody>
</voice>
</speak>''';
    }
  }

  /// 转换为 TtsSegment（兼容现有代码）
  TtsSegment toTtsSegment() {
    return TtsSegment(
      index: index,
      text: plainText,
      rawText: rawText,
      startOffset: startOffset,
      endOffset: endOffset,
    );
  }

  @override
  String toString() =>
      'TtsSegmentWithSsml(index: $index, plainText: "${plainText.length > 30 ? '${plainText.substring(0, 30)}...' : plainText}")';
}

/// 基于 AST 的 TTS 转换器（原生分段版）
///
/// 核心设计原则：
/// 1. **原生分段**：在 AST 块级节点边界自然分段，而非事后切割
/// 2. **语义完整**：每个段落包含完整的 AST 子树，SSML 标签天然闭合
/// 3. **不可分割单元**：段落(p)、列表项(li)、引用块(blockquote) 等是最小分段粒度
class AstBasedTtsConverter {
  final TtsSsmlConfig config;

  /// 目标段落长度（可朗读文本字符数）
  final int targetSegmentLength;

  /// 最小段落长度（低于此值会尝试与下一个节点合并）
  final int minSegmentLength;

  /// 最大段落长度（超过此值会在下一个节点边界强制分段）
  final int maxSegmentLength;

  AstBasedTtsConverter({
    this.config = const TtsSsmlConfig(),
    this.targetSegmentLength = 200,
    this.minSegmentLength = 50,
    this.maxSegmentLength = 400,
  });

  /// 转换 Markdown 为带 SSML 的段落列表
  List<TtsSegmentWithSsml> convert(String markdown) {
    if (markdown.trim().isEmpty) {
      return [];
    }

    // 预处理
    final preprocessed = _preprocess(markdown);
    if (preprocessed.isEmpty) {
      return [];
    }

    // 解析为 AST
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
    );
    final nodes = document.parse(preprocessed);

    // 遍历 AST，在节点边界自然分段
    final context = _ConversionContext(
      config: config,
      targetLength: targetSegmentLength,
      minLength: minSegmentLength,
      maxLength: maxSegmentLength,
    );

    _visitNodes(nodes, context);
    context.finalFlush(); // 保存最后一个段落

    debugPrint('🎯 AST 原生分段完成: ${context.segments.length} 个段落');
    for (var i = 0; i < context.segments.length; i++) {
      final seg = context.segments[i];
      debugPrint('  段落 $i: ${seg.plainText.length} 字符');
    }

    return context.segments;
  }

  /// 预处理：只做 AST 解析必需的修复
  String _preprocess(String text) {
    var result = text;

    // 修复 markdown 包对中文标点的解析问题
    const zwsp = '\u200B';
    const cnPuncts = '""''「」『』（）【】';

    result = result.replaceAllMapped(
      RegExp('\\*\\*([$cnPuncts])'),
      (m) => '**$zwsp${m.group(1)}',
    );
    result = result.replaceAllMapped(
      RegExp('([$cnPuncts])\\*\\*'),
      (m) => '${m.group(1)}$zwsp**',
    );
    result = result.replaceAllMapped(
      RegExp('(?<!\\*)\\*(?!\\*)([$cnPuncts])'),
      (m) => '*$zwsp${m.group(1)}',
    );
    result = result.replaceAllMapped(
      RegExp('([$cnPuncts])\\*(?!\\*)'),
      (m) => '${m.group(1)}$zwsp*',
    );

    return result;
  }

  /// 遍历节点列表
  void _visitNodes(List<md.Node> nodes, _ConversionContext context) {
    for (final node in nodes) {
      _visitNode(node, context);
    }
  }

  /// 遍历单个节点
  void _visitNode(md.Node node, _ConversionContext context) {
    if (node is md.Text) {
      _visitText(node, context);
    } else if (node is md.Element) {
      _visitElement(node, context);
    }
  }

  /// 处理文本节点
  void _visitText(md.Text node, _ConversionContext context) {
    var text = node.text;
    if (text.isEmpty) return;

    // 保存原始文本（用于显示）
    var rawText = text;

    // 移除预处理插入的零宽空格
    text = text.replaceAll('\u200B', '');
    rawText = rawText.replaceAll('\u200B', '');
    if (text.isEmpty) return;

    // 移除控制字符
    text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    rawText = rawText.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    if (text.isEmpty) return;

    // 处理换行符（仅对 TTS 文本）
    text = text.replaceAll(RegExp(r'[\r\n]+'), ' ');
    text = text.replaceAll(RegExp(r' {2,}'), ' ');
    // rawText 保留换行符，只做基本清理
    rawText = rawText.replaceAll(RegExp(r'\r\n'), '\n');
    rawText = rawText.replaceAll(RegExp(r'\r'), '\n');
    if (text.trim().isEmpty) return;

    // 跳过 LaTeX 内容
    if (_isLaTeXContent(text)) {
      debugPrint('🔊 跳过 LaTeX 内容');
      return;
    }

    // 跳过纯符号
    if (_isPureMarkup(text)) {
      return;
    }

    // 生成 SSML
    final processedSsml = _processText(text, context);
    context.appendContent(text, processedSsml, rawText: rawText);
  }

  /// 检测是否为 LaTeX 内容
  bool _isLaTeXContent(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith(r'$$') || trimmed.startsWith(r'\[')) {
      return true;
    }
    if (RegExp(r'^\$[^\$]+\$$').hasMatch(trimmed)) {
      return true;
    }
    if (trimmed.startsWith(r'\(') && trimmed.endsWith(r'\)')) {
      return true;
    }
    if (RegExp(r'^\\(?:frac|sqrt|sum|int|lim|begin|end|text|mathrm)\b').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  /// 检测是否为纯标记符号
  bool _isPureMarkup(String text) {
    final trimmed = text.trim();
    if (RegExp(r'^[*_~`#>|\-+=\[\](){}]+$').hasMatch(trimmed)) {
      return true;
    }
    return trimmed.isEmpty;
  }

  /// 处理文本内容（XML 转义 + 可选 SSML 停顿）
  String _processText(String text, _ConversionContext context) {
    if (config.enablePunctuationBreaks) {
      return _processTextWithPunctuation(text);
    }
    return _escapeXml(text);
  }

  /// 处理文本并在标点处插入停顿
  String _processTextWithPunctuation(String text) {
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(_escapeXmlChar(char));

      final breakMs = _getPunctuationBreakMs(char, text, i);
      if (breakMs > 0) {
        final scaledMs = (breakMs * config.rhythmScale).round();
        buffer.write('<break time="${scaledMs}ms"/>');
      }
    }

    return buffer.toString();
  }

  /// 获取标点符号对应的停顿时间
  int _getPunctuationBreakMs(String char, String fullText, int index) {
    switch (char) {
      case '，': return config.commaBreakMs;
      case '、': return config.enumBreakMs;
      case '；': return config.semicolonBreakMs;
      case '：': return config.colonBreakMs;
      case '。': return config.periodBreakMs;
      case '？': return config.questionBreakMs;
      case '！': return config.exclamationBreakMs;
      case '…':
        if (index + 1 < fullText.length && fullText[index + 1] == '…') {
          return 0;
        }
        return config.ellipsisBreakMs;
      case '—':
        if (index + 1 < fullText.length && fullText[index + 1] == '—') {
          return 0;
        }
        return config.dashBreakMs;
      case '"':
      case "'":
      case '」':
      case '』':
      case '）':
      case '】':
        return config.quoteEndBreakMs;
      case ',': return config.enCommaBreakMs;
      case ';': return config.enSemicolonBreakMs;
      case ':': return config.enColonBreakMs;
      case '.':
        if (index + 1 >= fullText.length) {
          return config.enPeriodBreakMs;
        }
        final nextChar = fullText[index + 1];
        if (nextChar == ' ' || nextChar == '\n' || nextChar == '\r') {
          return config.enPeriodBreakMs;
        }
        return 0;
      case '!': return config.enExclamationBreakMs;
      case '?': return config.enQuestionBreakMs;
      default: return 0;
    }
  }

  /// 单字符 XML 转义
  String _escapeXmlChar(String char) {
    switch (char) {
      case '&': return '&amp;';
      case '<': return '&lt;';
      case '>': return '&gt;';
      case '"': return '&quot;';
      case "'": return '&apos;';
      default: return char;
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

  /// 处理元素节点
  void _visitElement(md.Element element, _ConversionContext context) {
    switch (element.tag) {
      // ========== 标题（块级，强制分段点） ==========
      case 'h1':
        _handleBlockElement(
          element,
          context,
          beforeBreak: config.h1BreakBefore,
          afterBreak: config.h1BreakAfter,
          pitch: config.h1Pitch,
          markdownPrefix: '# ',
          forceSegmentBefore: true,
          forceSegmentAfter: true,
        );
        break;

      case 'h2':
        _handleBlockElement(
          element,
          context,
          beforeBreak: config.h2BreakBefore,
          afterBreak: config.h2BreakAfter,
          pitch: config.h2Pitch,
          markdownPrefix: '## ',
          forceSegmentBefore: true,
          forceSegmentAfter: true,
        );
        break;

      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _handleBlockElement(
          element,
          context,
          beforeBreak: config.h3BreakBefore,
          afterBreak: config.h3BreakAfter,
          pitch: config.h3Pitch,
          markdownPrefix: '### ', // 简化处理，h3-h6 统一用 ###
          forceSegmentBefore: true,
        );
        break;

      // ========== 段落（块级，自然分段点） ==========
      case 'p':
        _handleBlockElement(
          element,
          context,
          afterBreak: config.paragraphBreak,
          forceSegmentAfter: true,
        );
        break;

      // ========== 列表（容器，不直接处理内容） ==========
      case 'ul':
        if (config.announceListCount) {
          final itemCount = _countListItems(element);
          if (itemCount > 1) {
            final announcement = '下面有$itemCount项。';
            context.appendContent(announcement, '<break time="200ms"/>${_escapeXml(announcement)}<break time="150ms"/>', rawText: '');
          }
        }
        context.enterList(ordered: false);
        _visitChildren(element, context);
        context.exitList();
        break;

      case 'ol':
        if (config.announceListCount) {
          final itemCount = _countListItems(element);
          if (itemCount > 1) {
            final announcement = '下面有$itemCount个要点。';
            context.appendContent(announcement, '<break time="200ms"/>${_escapeXml(announcement)}<break time="150ms"/>', rawText: '');
          }
        }
        context.enterList(ordered: true);
        _visitChildren(element, context);
        context.exitList();
        break;

      // ========== 列表项（块级，自然分段点） ==========
      case 'li':
        // 编号前缀
        String? numberPrefix;
        if (config.readListNumbers && context.isInOrderedList) {
          final number = context.nextListNumber();
          numberPrefix = config.listNumberFormat == 'long' ? '第$number点，' : '$number、';
        }
        
        // Markdown 前缀（用于显示）
        String? markdownPrefix;
        if (context.isInOrderedList) {
          // 尝试获取当前编号（但这很难完全准确，因为只有上下文知道）
          // 简单起见，可以用 '1. ' 或者 '- '。Markdown 渲染器通常会自动处理列表编号。
          // 只要是 '1. ' 开头，渲染器会重算。
          markdownPrefix = '1. '; 
        } else {
          markdownPrefix = '- ';
        }
        
        _handleBlockElement(
          element,
          context,
          beforeBreak: config.listItemBreak,
          prefix: numberPrefix,
          markdownPrefix: markdownPrefix,
          forceSegmentAfter: true,
        );
        break;

      // ========== 引用块（块级，强制独立成段） ==========
      case 'blockquote':
        _handleBlockElement(
          element,
          context,
          afterBreak: config.paragraphBreak,
          rate: config.blockquoteRate,
          pitch: config.blockquotePitch,
          markdownPrefix: '> ',
          repeatMarkdownPrefix: true, // 确保每一行都有引用符号
          forceSegmentBefore: true,
          forceSegmentAfter: true,
        );
        break;

      // ========== 强调（行内） ==========
      case 'strong':
      case 'b':
        _handleInlineElement(
          element,
          context,
          openTag: '<emphasis level="${config.strongEmphasis}">',
          closeTag: '</emphasis>',
          markdownOpen: '**',
          markdownClose: '**',
        );
        break;

      case 'em':
      case 'i':
        _handleInlineElement(
          element,
          context,
          openTag: '<emphasis level="${config.emEmphasis}">',
          closeTag: '</emphasis>',
          markdownOpen: '*',
          markdownClose: '*',
        );
        break;

      // ========== 代码 ==========
      case 'code':
        final text = _getTextContent(element);
        final isCodeBlock = element.attributes.containsKey('class');
        
        if (isCodeBlock) {
          // 代码块通常由 pre 处理，但如果单独出现
          if (config.announceCodeBlocks) {
            context.flushSegment();
            context.appendContent(
              config.codeBlockAnnouncement,
              '<break time="200ms"/>${_escapeXml(config.codeBlockAnnouncement)}<break time="200ms"/>',
              rawText: '```\n$text\n```', // 修正：这里应该显示代码内容，不能设为空，之前是对的
            );
            context.flushSegment();
          }
        } else {
          if (config.readShortInlineCode && text.length <= config.maxInlineCodeLength) {
            context.appendContent(
              text,
              '<prosody rate="${config.inlineCodeRate}">${_escapeXml(text)}</prosody>',
              rawText: '`$text`',
            );
          } else {
             // 不读但要显示
             context.appendContent('', '', rawText: '`$text`');
          }
        }
        break;

      case 'pre':
        final codeContent = _getTextContent(element);
        if (config.announceCodeBlocks) {
          context.flushSegment();
          context.appendContent(
            config.codeBlockAnnouncement,
            '<break time="300ms"/>${_escapeXml(config.codeBlockAnnouncement)}<break time="300ms"/>',
            rawText: '```\n$codeContent\n```',
          );
          context.flushSegment();
        }
        break;

      // ========== 链接（行内） ==========
      // ========== 链接（行内） ==========
      case 'a':
        final href = element.attributes['href'] ?? '';
        _handleInlineElement(
          element,
          context,
          openTag: '',
          closeTag: '',
          markdownOpen: '[',
          markdownClose: ']($href)',
        );
        if (config.announceLinks) {
          final announcement = '，${config.linkAnnouncement}';
          context.appendContent(announcement, _escapeXml(announcement), rawText: ''); // 后缀不需要显示在 rawText 中
        }
        break;

      // ========== 图片 ==========
      // ========== 图片 ==========
      case 'img':
        if (config.readImageAlt) {
          final alt = element.attributes['alt'] ?? '';
          final src = element.attributes['src'] ?? '';
          if (alt.isNotEmpty) {
            final imageText = '${config.imagePrefix}$alt';
            context.appendContent(
              imageText,
              '<break time="200ms"/>${_escapeXml(imageText)}<break time="200ms"/>',
              rawText: '![$alt]($src)',
            );
          } else {
             // 即使不读也要显示
             context.appendContent('', '', rawText: '![]($src)');
          }
        }
        break;

      // ========== 分隔线（块级，强制分段） ==========
      // ========== 分隔线（块级，强制分段） ==========
      case 'hr':
        context.flushSegment();
        context.appendContent('', '<break time="${config.hrBreak}"/>', rawText: '\n---\n');
        context.flushSegment();
        break;

      // ========== 删除线（跳过） ==========
      case 'del':
      case 's':
      case 'strike':
        break;

      // ========== 换行 ==========
      case 'br':
        context.appendContent(' ', '<break time="150ms"/>');
        break;

      // ========== 表格（简化处理） ==========
      case 'table':
        context.flushSegment();
        context.appendContent(
          '这里有一个表格',
          '<break time="300ms"/>这里有一个表格<break time="300ms"/>',
        );
        context.flushSegment();
        break;

      case 'thead':
      case 'tbody':
      case 'tr':
      case 'th':
      case 'td':
        break;

      // ========== 其他 ==========
      default:
        _visitChildren(element, context);
    }
  }

  /// 处理块级元素
  /// 
  /// 这是实现"原生分段"的核心方法。每个块级元素作为独立单元处理，
  /// 在元素边界检查分段条件，保证 SSML 标签完整闭合。
  void _handleBlockElement(
    md.Element element,
    _ConversionContext context, {
    String? beforeBreak,
    String? afterBreak,
    String? pitch,
    String? rate,
    String? prefix,         // 用于朗读的前缀（如"第1点，"）
    String? markdownPrefix, // 用于显示的 Markdown 前缀（如"1. "或"> "）
    bool repeatMarkdownPrefix = false, // 是否每行都重复 Markdown 前缀（用于 blockquote）
    bool forceSegmentBefore = false,
    bool forceSegmentAfter = false,
    bool isNaturalSegmentPoint = false,
  }) {
    // 元素前强制分段
    if (forceSegmentBefore) {
      context.flushSegment();
    }

    // 递归处理子节点到临时上下文
    final tempContext = _ConversionContext(
      config: config,
      targetLength: targetSegmentLength,
      minLength: minSegmentLength,
      maxLength: maxSegmentLength,
    );
    _visitChildren(element, tempContext);
    
    // 合并子节点的所有内容（包括已 flush 的段落 + 当前缓冲区）
    final allPlainText = StringBuffer();
    final allSsml = StringBuffer();
    final allRawText = StringBuffer();
    
    // 1. 先合并已 flush 的段落
    for (final seg in tempContext.segments) {
      allPlainText.write(seg.plainText);
      allSsml.write(seg.ssmlContent);
      allRawText.write(seg.rawText);
      allRawText.write('\n\n'); // 段落之间添加换行
    }
    
    // 2. 再合并当前缓冲区中未 flush 的内容
    allPlainText.write(tempContext.currentPlainText);
    allSsml.write(tempContext.currentSsml);
    final currentRaw = tempContext.currentRawText;
    if (currentRaw.isNotEmpty) {
      allRawText.write(currentRaw);
    } // 只有非空才写入，避免末尾多余换行影响 split
    
    // 如果没有实际内容，跳过
    if (allPlainText.toString().trim().isEmpty) {
      return;
    }

    // 使用临时缓冲区构建完整的 SSML（保证标签闭合）
    final ssmlBuffer = StringBuffer();
    final plainBuffer = StringBuffer();
    final rawBuffer = StringBuffer();

    // 前置 break
    if (beforeBreak != null) {
      ssmlBuffer.write('<break time="$beforeBreak"/>');
    }

    // 开始标签
    if (pitch != null || rate != null) {
      ssmlBuffer.write('<prosody');
      if (pitch != null) ssmlBuffer.write(' pitch="$pitch"');
      if (rate != null) ssmlBuffer.write(' rate="$rate"');
      ssmlBuffer.write('>');
    }

    // 前缀处理
    if (prefix != null) {
      ssmlBuffer.write(_escapeXml(prefix));
      plainBuffer.write(prefix);
    }
    
    // Raw Text 处理
    if (markdownPrefix != null) {
      if (repeatMarkdownPrefix) {
        // 给每一行都加上前缀（特别是 blockquote）
        final rawContent = allRawText.toString();
        // 移除末尾可能的空白，防止多余的 > 行
        final trimmedContent = rawContent.trimRight(); 
        if (trimmedContent.isNotEmpty) {
          final lines = trimmedContent.split('\n');
          for (var i = 0; i < lines.length; i++) {
            // 如果是空行，也加上前缀（> ）保持 block 连续性
            rawBuffer.write('$markdownPrefix${lines[i]}');
            if (i < lines.length - 1) {
              rawBuffer.write('\n');
            }
          }
        }
      } else {
        rawBuffer.write(markdownPrefix);
        rawBuffer.write(allRawText);
      }
    } else {
      // 降级策略
      if (prefix != null) {
         rawBuffer.write(prefix);
      }
      rawBuffer.write(allRawText);
    }

    // 添加合并后的子节点内容 (SSML/Plain)
    ssmlBuffer.write(allSsml);
    plainBuffer.write(allPlainText);
    // rawBuffer 已在上面处理完毕

    // 结束标签
    if (pitch != null || rate != null) {
      ssmlBuffer.write('</prosody>');
    }

    // 后置 break
    if (afterBreak != null) {
      ssmlBuffer.write('<break time="$afterBreak"/>');
    }

    // 将完整元素内容添加到主上下文
    context.appendContent(plainBuffer.toString(), ssmlBuffer.toString(), rawText: rawBuffer.toString());

    // 检查分段
    if (forceSegmentAfter) {
      context.flushSegment();
    } else if (isNaturalSegmentPoint) {
      context.flushIfNeeded();
    }
  }

  /// 处理行内元素
  void _handleInlineElement(
    md.Element element,
    _ConversionContext context, {
    required String openTag,
    required String closeTag,
    String markdownOpen = '',  // 新增：Markdown 开始标记
    String markdownClose = '', // 新增：Markdown 结束标记
  }) {
    final ssmlBuffer = StringBuffer();
    final plainBuffer = StringBuffer();
    final rawBuffer = StringBuffer();

    ssmlBuffer.write(openTag);
    // rawBuffer 写入 Markdown 标记
    rawBuffer.write(markdownOpen);

    // 递归处理子节点
    final tempContext = _ConversionContext(
      config: config,
      targetLength: targetSegmentLength,
      minLength: minSegmentLength,
      maxLength: maxSegmentLength,
    );
    _visitChildren(element, tempContext);
    
    ssmlBuffer.write(tempContext.currentSsml);
    plainBuffer.write(tempContext.currentPlainText);
    rawBuffer.write(tempContext.currentRawText);
    
    ssmlBuffer.write(closeTag);
    // rawBuffer 写入 Markdown 结束标记
    rawBuffer.write(markdownClose);

    context.appendContent(plainBuffer.toString(), ssmlBuffer.toString(), rawText: rawBuffer.toString());
  }

  /// 遍历子节点
  void _visitChildren(md.Element element, _ConversionContext context) {
    if (element.children != null) {
      _visitNodes(element.children!, context);
    }
  }

  /// 计算列表项数量
  int _countListItems(md.Element listElement) {
    if (listElement.children == null) return 0;
    return listElement.children!
        .whereType<md.Element>()
        .where((e) => e.tag == 'li')
        .length;
  }

  /// 获取元素内的纯文本
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
}

/// 转换上下文（原生分段版）
class _ConversionContext {
  final TtsSsmlConfig config;
  final int targetLength;
  final int minLength;
  final int maxLength;

  /// 当前段落的 SSML 缓冲
  final StringBuffer _ssmlBuffer = StringBuffer();

  /// 当前段落的纯文本缓冲（处理后，用于 TTS）
  final StringBuffer _plainTextBuffer = StringBuffer();

  /// 当前段落的原始文本缓冲（保留格式，用于显示）
  final StringBuffer _rawTextBuffer = StringBuffer();

  /// 当前段落的起始偏移
  int _currentStartOffset = 0;

  /// 全局偏移
  int _globalOffset = 0;

  /// 已完成的段落列表
  final List<TtsSegmentWithSsml> segments = [];

  /// 列表栈
  final List<_ListContext> _listStack = [];

  _ConversionContext({
    required this.config,
    required this.targetLength,
    required this.minLength,
    required this.maxLength,
  });

  /// 获取当前 SSML 内容
  String get currentSsml => _ssmlBuffer.toString();

  /// 获取当前纯文本内容
  String get currentPlainText => _plainTextBuffer.toString();

  /// 获取当前原始文本内容
  String get currentRawText => _rawTextBuffer.toString();

  /// 获取当前文本长度
  int get currentLength => _plainTextBuffer.length;

  /// 是否在有序列表中
  bool get isInOrderedList =>
      _listStack.isNotEmpty && _listStack.last.ordered;

  /// 进入列表
  void enterList({required bool ordered}) {
    _listStack.add(_ListContext(ordered: ordered));
  }

  /// 退出列表
  void exitList() {
    if (_listStack.isNotEmpty) {
      _listStack.removeLast();
    }
  }

  /// 获取下一个列表编号
  int nextListNumber() {
    if (_listStack.isEmpty) return 1;
    return ++_listStack.last.currentNumber;
  }

  /// 添加内容到当前段落
  /// [plainText] 处理后的纯文本（去掉换行等）
  /// [ssml] SSML 内容
  /// [rawText] 原始格式文本（可选，默认与 plainText 相同）
  void appendContent(String plainText, String ssml, {String? rawText}) {
    _plainTextBuffer.write(plainText);
    _ssmlBuffer.write(ssml);
    _rawTextBuffer.write(rawText ?? plainText);
  }

  /// 检查是否需要分段（在自然分段点调用）
  void flushIfNeeded() {
    if (currentLength >= targetLength) {
      flushSegment();
    }
  }

  /// 强制分段
  void flushSegment() {
    if (currentLength > 0) {
      _createSegment();
    }
  }

  /// 最终分段（处理结束时调用）
  void finalFlush() {
    if (currentLength > 0) {
      _createSegment();
    }
  }

  /// 创建段落
  void _createSegment() {
    final plainText = _plainTextBuffer.toString().trim();
    final rawText = _rawTextBuffer.toString().trim();
    final ssmlContent = _ssmlBuffer.toString().trim();

    if (plainText.isNotEmpty) {
      final segmentIndex = segments.length;
      final preview = plainText.length > 50
          ? '${plainText.substring(0, 50)}...'
          : plainText;
      debugPrint('🎯 创建段落 $segmentIndex: ${plainText.length} 字符 - "$preview"');

      segments.add(TtsSegmentWithSsml(
        index: segmentIndex,
        plainText: plainText,
        rawText: rawText,
        ssmlContent: ssmlContent,
        startOffset: _currentStartOffset,
        endOffset: _currentStartOffset + plainText.length,
      ));

      _globalOffset += plainText.length;
      _currentStartOffset = _globalOffset;
    }

    // 重置缓冲
    _ssmlBuffer.clear();
    _plainTextBuffer.clear();
    _rawTextBuffer.clear();
  }
}

/// 列表上下文
class _ListContext {
  final bool ordered;
  int currentNumber = 0;

  _ListContext({required this.ordered});
}
