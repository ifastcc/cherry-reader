import '../models/tts_segment.dart';

/// 文本分段服务
///
/// 将长文本智能分割成适合 TTS 朗读的段落
class TextSegmenter {
  /// 最小段落长度（字符数）
  final int minSegmentLength;

  /// 最大段落长度（字符数）
  final int maxSegmentLength;

  /// 目标段落长度（字符数）
  final int targetSegmentLength;

  TextSegmenter({
    this.minSegmentLength = 50,
    this.maxSegmentLength = 300,
    this.targetSegmentLength = 150,
  });

  /// 中文句子结束符
  static const _chineseSentenceEnders = ['。', '！', '？', '；', '…'];

  /// 英文句子结束符
  static const _englishSentenceEnders = ['. ', '! ', '? ', '; '];

  /// 中文分隔符（用于长句分割）
  static const _chineseDelimiters = ['，', '、', '：', '"', '"', '）', '】'];

  /// 英文分隔符
  static const _englishDelimiters = [', ', ': ', ') ', '] '];

  /// 分割文本为段落
  ///
  /// 返回 [TtsSegment] 列表
  List<TtsSegment> segment(String text) {
    if (text.isEmpty) return [];

    // 1. 预处理：清理文本
    final cleanedText = _preprocess(text);
    if (cleanedText.isEmpty) return [];

    // 2. 按句子分割
    final sentences = _splitIntoSentences(cleanedText);
    if (sentences.isEmpty) return [];

    // 3. 合并短句、分割长句
    final segments = _optimizeSegments(sentences, cleanedText);

    return segments;
  }

  /// 预处理文本
  String _preprocess(String text) {
    // 移除 Markdown 图片标记
    var result = text.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');

    // 移除 Markdown 链接，保留文字
    // 注意：Dart 的 replaceAll 不支持 $1 反向引用，必须用 replaceAllMapped
    result = result.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (m) => m.group(1) ?? '',
    );

    // 移除代码块（可能很长，不适合朗读）
    result = result.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // 移除行内代码
    result = result.replaceAll(RegExp(r'`[^`]+`'), '');

    // 移除 Markdown 标题标记，保留文字
    result = result.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

    // 移除粗体/斜体标记，保留文字
    result = result.replaceAllMapped(
      RegExp(r'\*{1,2}([^\*]+)\*{1,2}'),
      (m) => m.group(1) ?? '',
    );
    result = result.replaceAllMapped(
      RegExp(r'_{1,2}([^_]+)_{1,2}'),
      (m) => m.group(1) ?? '',
    );

    // 移除列表标记
    result = result.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    result = result.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // 移除多余空白
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');

    return result.trim();
  }

  /// 按句子分割
  List<_SentenceInfo> _splitIntoSentences(String text) {
    final sentences = <_SentenceInfo>[];
    var currentStart = 0;
    var i = 0;

    while (i < text.length) {
      // 检查是否是句子结束符
      bool isSentenceEnd = false;

      // 检查中文结束符
      if (_chineseSentenceEnders.contains(text[i])) {
        isSentenceEnd = true;
      }
      // 检查英文结束符（需要后面有空格）
      else if (i + 1 < text.length) {
        final twoChars = text.substring(i, i + 2);
        if (_englishSentenceEnders.contains(twoChars)) {
          isSentenceEnd = true;
        }
      }

      if (isSentenceEnd) {
        // 包含结束符
        final endIndex = i + 1;
        final sentenceText = text.substring(currentStart, endIndex).trim();

        if (sentenceText.isNotEmpty) {
          sentences.add(_SentenceInfo(
            text: sentenceText,
            startOffset: currentStart,
            endOffset: endIndex,
          ));
        }

        currentStart = endIndex;
        // 跳过结束符后的空白
        while (currentStart < text.length &&
               (text[currentStart] == ' ' || text[currentStart] == '\n')) {
          currentStart++;
        }
        i = currentStart;
      } else {
        i++;
      }
    }

    // 处理最后一个没有标点的句子
    if (currentStart < text.length) {
      final remaining = text.substring(currentStart).trim();
      if (remaining.isNotEmpty) {
        sentences.add(_SentenceInfo(
          text: remaining,
          startOffset: currentStart,
          endOffset: text.length,
        ));
      }
    }

    return sentences;
  }

  /// 优化段落：合并短句、分割长句
  List<TtsSegment> _optimizeSegments(List<_SentenceInfo> sentences, String originalText) {
    final segments = <TtsSegment>[];
    var currentText = StringBuffer();
    var currentStart = -1;
    var currentEnd = -1;
    var segmentIndex = 0;

    void flushSegment() {
      if (currentText.isEmpty) return;

      final text = currentText.toString().trim();
      if (text.isNotEmpty) {
        segments.add(TtsSegment(
          index: segmentIndex++,
          text: text,
          startOffset: currentStart,
          endOffset: currentEnd,
        ));
      }

      currentText.clear();
      currentStart = -1;
      currentEnd = -1;
    }

    for (final sentence in sentences) {
      final sentenceLength = sentence.text.length;

      // 如果句子太长，需要分割
      if (sentenceLength > maxSegmentLength) {
        // 先保存当前累积的内容
        flushSegment();

        // 分割长句
        final subSegments = _splitLongSentence(sentence, segmentIndex);
        for (final sub in subSegments) {
          segments.add(sub);
          segmentIndex++;
        }
        continue;
      }

      // 检查是否需要开始新段落
      if (currentStart == -1) {
        currentStart = sentence.startOffset;
      }

      // 检查添加这个句子后是否超过目标长度
      final newLength = currentText.length + sentenceLength;

      if (newLength > targetSegmentLength && currentText.isNotEmpty) {
        // 当前段落已经够长了，保存并开始新段落
        flushSegment();
        currentStart = sentence.startOffset;
      }

      // 添加句子到当前段落
      if (currentText.isNotEmpty) {
        currentText.write(' ');
      }
      currentText.write(sentence.text);
      currentEnd = sentence.endOffset;

      // 如果当前段落已经超过最大长度，强制保存
      if (currentText.length >= maxSegmentLength) {
        flushSegment();
      }
    }

    // 保存最后一个段落
    flushSegment();

    return segments;
  }

  /// 分割长句
  List<TtsSegment> _splitLongSentence(_SentenceInfo sentence, int startIndex) {
    final segments = <TtsSegment>[];
    final text = sentence.text;
    var currentStart = 0;
    var segmentIndex = startIndex;

    while (currentStart < text.length) {
      var endIndex = currentStart + targetSegmentLength;

      if (endIndex >= text.length) {
        // 剩余部分
        final remaining = text.substring(currentStart).trim();
        if (remaining.isNotEmpty) {
          segments.add(TtsSegment(
            index: segmentIndex++,
            text: remaining,
            startOffset: sentence.startOffset + currentStart,
            endOffset: sentence.endOffset,
          ));
        }
        break;
      }

      // 在目标长度附近找分隔符
      var splitIndex = -1;

      // 向前查找分隔符
      for (var i = endIndex; i > currentStart + minSegmentLength; i--) {
        if (_isDelimiter(text, i)) {
          splitIndex = i + 1;
          break;
        }
      }

      // 如果没找到，向后查找
      if (splitIndex == -1) {
        for (var i = endIndex; i < text.length && i < endIndex + 50; i++) {
          if (_isDelimiter(text, i)) {
            splitIndex = i + 1;
            break;
          }
        }
      }

      // 如果还是没找到，直接按目标长度切分
      if (splitIndex == -1) {
        splitIndex = endIndex;
      }

      final segmentText = text.substring(currentStart, splitIndex).trim();
      if (segmentText.isNotEmpty) {
        segments.add(TtsSegment(
          index: segmentIndex++,
          text: segmentText,
          startOffset: sentence.startOffset + currentStart,
          endOffset: sentence.startOffset + splitIndex,
        ));
      }

      currentStart = splitIndex;
      // 跳过分隔符后的空白
      while (currentStart < text.length && text[currentStart] == ' ') {
        currentStart++;
      }
    }

    return segments;
  }

  /// 检查是否是分隔符位置
  bool _isDelimiter(String text, int index) {
    if (index >= text.length) return false;

    final char = text[index];
    if (_chineseDelimiters.contains(char)) return true;

    if (index + 1 < text.length) {
      final twoChars = text.substring(index, index + 2);
      if (_englishDelimiters.contains(twoChars)) return true;
    }

    return false;
  }
}

/// 句子信息（内部使用）
class _SentenceInfo {
  final String text;
  final int startOffset;
  final int endOffset;

  _SentenceInfo({
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });
}
