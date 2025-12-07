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

  // ========== 语调控制 ==========
  final String h1Pitch;
  final String h2Pitch;

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

  // 英文处理
  final bool wrapEnglishWithLang;
  final String englishLang;

  const TtsSsmlConfig({
    // 全局节奏
    this.rhythmScale = 1.0,
    // 标题停顿（基准值，会乘以 rhythmScale）
    this.h1BreakBeforeMs = 800,   // 大标题前：长停顿
    this.h1BreakAfterMs = 1000,   // 大标题后：更长停顿（让听众准备好）
    this.h2BreakBeforeMs = 600,
    this.h2BreakAfterMs = 800,
    this.h3BreakBeforeMs = 400,
    this.h3BreakAfterMs = 500,
    // 段落和列表
    this.paragraphBreakMs = 600,  // 段落间：明显停顿
    this.listItemBreakMs = 300,
    // 分隔线
    this.hrBreakMs = 1000,
    // 换行
    this.lineBreakMs = 200,
    // 语调
    this.h1Pitch = '+5%',
    this.h2Pitch = '+3%',
    this.blockquoteRate = '-10%',
    this.blockquotePitch = '-3%',
    this.inlineCodeRate = '-10%',
    this.strongEmphasis = 'strong',
    this.emEmphasis = 'moderate',
    // 功能开关
    this.announceCodeBlocks = false,
    this.codeBlockAnnouncement = '这里有一段代码',
    this.readShortInlineCode = true,
    this.maxInlineCodeLength = 30,
    this.announceLinks = false,
    this.linkAnnouncement = '链接',
    this.readImageAlt = true,
    this.imagePrefix = '图片：',
    this.readListNumbers = true,
    this.listNumberFormat = 'short',
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
      h1Pitch: h1Pitch,
      h2Pitch: h2Pitch,
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
      wrapEnglishWithLang: wrapEnglishWithLang,
      englishLang: englishLang,
    );
  }

  // ========== 预设配置 ==========

  static const TtsSsmlConfig defaultConfig = TtsSsmlConfig();

  /// 快速朗读（节奏更快，停顿更短）
  static const TtsSsmlConfig fastConfig = TtsSsmlConfig(
    rhythmScale: 0.6,
  );

  /// 舒缓朗读（节奏更慢，停顿更长）
  static const TtsSsmlConfig relaxedConfig = TtsSsmlConfig(
    rhythmScale: 1.3,
  );

  /// 有声书风格（停顿更长，语调变化更大）
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
  final String plainText;  // 纯文本（用于显示、缓存 key）
  final String ssmlContent; // SSML 内容（不含外层 speak/voice 标签）
  final int startOffset;
  final int endOffset;

  TtsSegmentWithSsml({
    required this.index,
    required this.plainText,
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
      startOffset: startOffset,
      endOffset: endOffset,
    );
  }

  @override
  String toString() =>
      'TtsSegmentWithSsml(index: $index, plainText: "${plainText.length > 30 ? '${plainText.substring(0, 30)}...' : plainText}")';
}

/// 基于 AST 的 TTS 转换器
///
/// 遍历 Markdown AST 的同时：
/// 1. 生成 SSML 标签
/// 2. 累计可朗读文本长度
/// 3. 在块级节点边界智能分段
class AstBasedTtsConverter {
  final TtsSsmlConfig config;

  /// 目标段落长度（可朗读文本字符数）
  final int targetSegmentLength;

  /// 最小段落长度
  final int minSegmentLength;

  /// 最大段落长度
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

    // 遍历 AST，同时分段和生成 SSML
    final context = _ConversionContext(
      config: config,
      targetLength: targetSegmentLength,
      minLength: minSegmentLength,
      maxLength: maxSegmentLength,
    );

    _visitNodes(nodes, context);
    context.flush(); // 保存最后一个段落

    debugPrint('🎯 AST 分段完成: ${context.segments.length} 个段落');
    for (var i = 0; i < context.segments.length; i++) {
      final seg = context.segments[i];
      debugPrint('  段落 $i: ${seg.plainText.length} 字符');
    }

    return context.segments;
  }

  /// 预处理：移除不适合朗读的内容 + 修复 Markdown 解析问题
  String _preprocess(String text) {
    var result = text;

    // === 修复 markdown 包对中文标点的解析问题 ===
    // 问题：**"引号"** 无法正确解析，因为中文引号紧贴 ** 不满足 CommonMark 规则
    // 原因：CommonMark 的 left-flanking/right-flanking 规则对中文标点判断有问题
    // 解决：在 ** 和中文标点之间插入零宽空格 (U+200B)
    const zwsp = '\u200B'; // 零宽空格，不影响显示但帮助解析
    const cnPuncts = '""''「」『』（）【】'; // 中文引号和括号

    // ** 后面紧跟中文引号/括号 → 插入零宽空格
    result = result.replaceAllMapped(
      RegExp('\\*\\*([$cnPuncts])'),
      (m) => '**$zwsp${m.group(1)}',
    );

    // 中文引号/括号后面紧跟 ** → 插入零宽空格
    result = result.replaceAllMapped(
      RegExp('([$cnPuncts])\\*\\*'),
      (m) => '${m.group(1)}$zwsp**',
    );

    // 同样处理单个 * (斜体)
    result = result.replaceAllMapped(
      RegExp('(?<!\\*)\\*(?!\\*)([$cnPuncts])'),
      (m) => '*$zwsp${m.group(1)}',
    );
    result = result.replaceAllMapped(
      RegExp('([$cnPuncts])\\*(?!\\*)'),
      (m) => '${m.group(1)}$zwsp*',
    );

    // === 原有的预处理 ===

    // 移除 LaTeX 块级公式 $$...$$
    result = result.replaceAll(RegExp(r'\$\$[\s\S]*?\$\$'), ' ');

    // 移除 LaTeX 行内公式 $...$
    result = result.replaceAll(RegExp(r'\$([^\s$][^$]*?[^\s$]|[^\s$])\$'), ' ');

    // 移除 HTML 标签
    result = result.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // 移除 HTML 实体
    result = result.replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ');
    result = result.replaceAll(RegExp(r'&#\d+;'), ' ');

    // 清理多余空格
    result = result.replaceAll(RegExp(r' {2,}'), ' ');

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

    // 清理 markdown 包未正确解析的残留标记
    text = _cleanMarkdownResiduals(text);
    if (text.isEmpty) return;

    // 处理文本（可选：英文包裹）
    final processedSsml = _processText(text, context);
    context.ssmlBuffer.write(processedSsml);
    context.plainTextBuffer.write(text);
    context.currentTextLength += text.length;
  }

  /// 清理 markdown 解析残留的标记
  String _cleanMarkdownResiduals(String text) {
    var result = text;

    // 移除预处理时插入的零宽空格
    result = result.replaceAll('\u200B', '');

    // 移除残留的加粗/斜体标记 ** 和 *
    // 注意：要小心不要误删乘号等
    result = result.replaceAll(RegExp(r'\*{2,}'), ''); // ** 或更多
    result = result.replaceAll(RegExp(r'(?<![a-zA-Z0-9])\*(?![a-zA-Z0-9])'), ''); // 独立的 *

    // 移除残留的删除线标记 ~~
    result = result.replaceAll('~~', '');

    // 移除残留的行内代码标记 `
    result = result.replaceAll(RegExp(r'`+'), '');

    // 移除残留的下划线标记 __ (用于斜体/加粗)
    result = result.replaceAll(RegExp(r'_{2,}'), '');

    return result;
  }

  /// 处理文本内容（英文、数字等）
  String _processText(String text, _ConversionContext context) {
    if (!config.wrapEnglishWithLang) {
      // 不包裹英文，直接转义返回
      return _escapeXml(text);
    }

    // 将文本分成中文和英文片段，英文用 <lang> 包裹
    final buffer = StringBuffer();
    final regex = RegExp(r'[a-zA-Z][a-zA-Z0-9\s\-_\.]*[a-zA-Z0-9]|[a-zA-Z]');

    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      // 添加匹配前的中文部分
      if (match.start > lastEnd) {
        buffer.write(_escapeXml(text.substring(lastEnd, match.start)));
      }
      // 添加英文部分（用 lang 包裹）
      buffer.write('<lang xml:lang="${config.englishLang}">');
      buffer.write(_escapeXml(match.group(0)!));
      buffer.write('</lang>');
      lastEnd = match.end;
    }
    // 添加剩余部分
    if (lastEnd < text.length) {
      buffer.write(_escapeXml(text.substring(lastEnd)));
    }

    return buffer.toString();
  }

  /// 处理元素节点
  void _visitElement(md.Element element, _ConversionContext context) {
    switch (element.tag) {
      // ========== 标题 ==========
      case 'h1':
        _handleHeading(element, context, config.h1BreakBefore,
            config.h1BreakAfter, config.h1Pitch, forceSegmentBefore: true);
        break;

      case 'h2':
        _handleHeading(element, context, config.h2BreakBefore,
            config.h2BreakAfter, config.h2Pitch, forceSegmentBefore: true);
        break;

      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _handleHeading(
            element, context, config.h3BreakBefore, config.h3BreakAfter, null,
            forceSegmentBefore: true);
        break;

      // ========== 段落 ==========
      case 'p':
        _visitChildren(element, context);
        context.ssmlBuffer.write('<break time="${config.paragraphBreak}"/>');
        // 段落结束检查分段
        context.checkAndFlushIfNeeded();
        break;

      // ========== 列表 ==========
      case 'ul':
        context.enterList(ordered: false);
        _visitChildren(element, context);
        context.exitList();
        context.ssmlBuffer.write('<break time="${config.listItemBreak}"/>');
        break;

      case 'ol':
        context.enterList(ordered: true);
        _visitChildren(element, context);
        context.exitList();
        context.ssmlBuffer.write('<break time="${config.listItemBreak}"/>');
        break;

      case 'li':
        context.ssmlBuffer.write('<break time="${config.listItemBreak}"/>');

        // 有序列表编号
        if (config.readListNumbers && context.isInOrderedList) {
          final number = context.nextListNumber();
          String numberText;
          if (config.listNumberFormat == 'long') {
            numberText = '第$number点，';
          } else {
            numberText = '$number、';
          }
          context.ssmlBuffer.write(_escapeXml(numberText));
          context.plainTextBuffer.write(numberText);
          context.currentTextLength += numberText.length;
        }

        _visitChildren(element, context);
        // 列表项结束检查分段
        context.checkAndFlushIfNeeded();
        break;

      // ========== 引用块 ==========
      case 'blockquote':
        // 引用块前强制分段（独立成段）
        context.flushIfHasContent();

        context.ssmlBuffer.write(
            '<prosody rate="${config.blockquoteRate}" pitch="${config.blockquotePitch}">');
        _visitChildren(element, context);
        context.ssmlBuffer.write('</prosody>');
        context.ssmlBuffer.write('<break time="${config.paragraphBreak}"/>');

        // 引用块后强制分段
        context.flushIfHasContent();
        break;

      // ========== 强调 ==========
      case 'strong':
      case 'b':
        context.ssmlBuffer
            .write('<emphasis level="${config.strongEmphasis}">');
        _visitChildren(element, context);
        context.ssmlBuffer.write('</emphasis>');
        break;

      case 'em':
      case 'i':
        context.ssmlBuffer.write('<emphasis level="${config.emEmphasis}">');
        _visitChildren(element, context);
        context.ssmlBuffer.write('</emphasis>');
        break;

      // ========== 代码 ==========
      case 'code':
        final text = _getTextContent(element);
        final isCodeBlock = element.attributes.containsKey('class');

        if (isCodeBlock) {
          // 代码块：独立处理
          if (config.announceCodeBlocks) {
            context.flushIfHasContent();
            context.ssmlBuffer.write('<break time="200ms"/>');
            context.ssmlBuffer.write(_escapeXml(config.codeBlockAnnouncement));
            context.plainTextBuffer.write(config.codeBlockAnnouncement);
            context.currentTextLength += config.codeBlockAnnouncement.length;
            context.ssmlBuffer.write('<break time="200ms"/>');
            context.flushIfHasContent();
          }
        } else {
          // 行内代码
          if (config.readShortInlineCode &&
              text.length <= config.maxInlineCodeLength) {
            context.ssmlBuffer
                .write('<prosody rate="${config.inlineCodeRate}">');
            context.ssmlBuffer.write(_escapeXml(text));
            context.ssmlBuffer.write('</prosody>');
            context.plainTextBuffer.write(text);
            context.currentTextLength += text.length;
          }
        }
        break;

      case 'pre':
        // 代码块
        if (config.announceCodeBlocks) {
          context.flushIfHasContent();
          context.ssmlBuffer.write('<break time="300ms"/>');
          context.ssmlBuffer.write(_escapeXml(config.codeBlockAnnouncement));
          context.plainTextBuffer.write(config.codeBlockAnnouncement);
          context.currentTextLength += config.codeBlockAnnouncement.length;
          context.ssmlBuffer.write('<break time="300ms"/>');
          context.flushIfHasContent();
        }
        break;

      // ========== 链接 ==========
      case 'a':
        _visitChildren(element, context);
        // 可选：提示这是链接
        if (config.announceLinks) {
          final announcement = '，${config.linkAnnouncement}';
          context.ssmlBuffer.write(_escapeXml(announcement));
          context.plainTextBuffer.write(announcement);
          context.currentTextLength += announcement.length;
        }
        break;

      // ========== 图片 ==========
      case 'img':
        if (config.readImageAlt) {
          final alt = element.attributes['alt'];
          if (alt != null && alt.isNotEmpty) {
            final imageText = '${config.imagePrefix}$alt';
            context.ssmlBuffer.write('<break time="200ms"/>');
            context.ssmlBuffer.write(_escapeXml(imageText));
            context.plainTextBuffer.write(imageText);
            context.currentTextLength += imageText.length;
            context.ssmlBuffer.write('<break time="200ms"/>');
          }
        }
        break;

      // ========== 分隔线 ==========
      case 'hr':
        context.ssmlBuffer.write('<break time="${config.hrBreak}"/>');
        // 分隔线后强制分段
        context.flushIfHasContent();
        break;

      // ========== 删除线 ==========
      case 'del':
      case 's':
      case 'strike':
        // 被删除的内容不朗读
        break;

      // ========== 换行 ==========
      case 'br':
        context.ssmlBuffer.write('<break time="150ms"/>');
        break;

      // ========== 表格 ==========
      case 'table':
        context.flushIfHasContent();
        context.ssmlBuffer.write('<break time="300ms"/>');
        context.ssmlBuffer.write('这里有一个表格');
        context.plainTextBuffer.write('这里有一个表格');
        context.currentTextLength += 6;
        context.ssmlBuffer.write('<break time="300ms"/>');
        context.flushIfHasContent();
        break;

      case 'thead':
      case 'tbody':
      case 'tr':
      case 'th':
      case 'td':
        // 表格内容跳过
        break;

      // ========== 其他 ==========
      default:
        _visitChildren(element, context);
    }
  }

  /// 处理标题
  void _handleHeading(
    md.Element element,
    _ConversionContext context,
    String breakBefore,
    String breakAfter,
    String? pitch, {
    bool forceSegmentBefore = false,
  }) {
    // 标题前强制分段（新章节开始）
    if (forceSegmentBefore) {
      context.flushIfHasContent();
    }

    context.ssmlBuffer.write('<break time="$breakBefore"/>');
    if (pitch != null) {
      context.ssmlBuffer.write('<prosody pitch="$pitch">');
    }
    _visitChildren(element, context);
    if (pitch != null) {
      context.ssmlBuffer.write('</prosody>');
    }
    context.ssmlBuffer.write('<break time="$breakAfter"/>');

    // 标题后检查分段（短标题可以和后文合并）
    context.checkAndFlushIfNeeded();
  }

  /// 遍历子节点
  void _visitChildren(md.Element element, _ConversionContext context) {
    if (element.children != null) {
      _visitNodes(element.children!, context);
    }
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

/// 转换上下文（内部使用）
class _ConversionContext {
  final TtsSsmlConfig config;
  final int targetLength;
  final int minLength;
  final int maxLength;

  /// 当前段落的 SSML 缓冲
  final StringBuffer ssmlBuffer = StringBuffer();

  /// 当前段落的纯文本缓冲
  final StringBuffer plainTextBuffer = StringBuffer();

  /// 当前段落的文本长度
  int currentTextLength = 0;

  /// 当前段落的起始偏移
  int currentStartOffset = 0;

  /// 全局偏移（用于追踪位置）
  int globalOffset = 0;

  /// 已完成的段落列表
  final List<TtsSegmentWithSsml> segments = [];

  /// 列表栈（支持嵌套列表）
  final List<_ListContext> _listStack = [];

  _ConversionContext({
    required this.config,
    required this.targetLength,
    required this.minLength,
    required this.maxLength,
  });

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

  /// 检查是否需要分段
  void checkAndFlushIfNeeded() {
    if (currentTextLength >= targetLength) {
      flush();
    } else if (currentTextLength >= maxLength) {
      flush();
    }
  }

  /// 如果有内容就分段
  void flushIfHasContent() {
    if (currentTextLength >= minLength) {
      flush();
    }
  }

  /// 保存当前段落，开始新段落
  void flush() {
    final plainText = plainTextBuffer.toString().trim();
    final ssmlContent = ssmlBuffer.toString().trim();

    if (plainText.isNotEmpty) {
      // 清理 SSML
      final cleanedSsml = _cleanSsml(ssmlContent);

      segments.add(TtsSegmentWithSsml(
        index: segments.length,
        plainText: plainText,
        ssmlContent: cleanedSsml,
        startOffset: currentStartOffset,
        endOffset: currentStartOffset + currentTextLength,
      ));

      currentStartOffset += currentTextLength;
    }

    // 重置缓冲
    ssmlBuffer.clear();
    plainTextBuffer.clear();
    currentTextLength = 0;
  }

  /// 清理 SSML
  String _cleanSsml(String ssml) {
    var result = ssml;

    // 移除开头的 break 标签
    result = result.replaceFirst(RegExp(r'^(<break[^>]*/>[\s]*)+'), '');

    // 合并连续的 break 标签（保留时间较长的）
    result = result.replaceAllMapped(
      RegExp(r'<break time="(\d+)ms"/>\s*<break time="(\d+)ms"/>'),
      (match) {
        final time1 = int.parse(match.group(1)!);
        final time2 = int.parse(match.group(2)!);
        final maxTime = time1 > time2 ? time1 : time2;
        return '<break time="${maxTime}ms"/>';
      },
    );

    return result.trim();
  }
}

/// 列表上下文
class _ListContext {
  final bool ordered;
  int currentNumber = 0;

  _ListContext({required this.ordered});
}
