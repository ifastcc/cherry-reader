/// TTS 段落状态
enum SegmentStatus {
  pending,     // 等待下载
  downloading, // 下载中
  ready,       // 已就绪
  error,       // 下载失败
}

/// TTS 单个段落
class TtsSegment {
  final int index;
  final String text;      // 纯文本（用于显示、缓存 key）
  final String? ssml;     // SSML 内容（不含外层 speak/voice 标签）
  final int startOffset;  // 在原文中的起始位置
  final int endOffset;    // 在原文中的结束位置

  Duration? duration;     // 音频时长（播放后获取）
  String? cachePath;      // 缓存文件路径
  SegmentStatus status;   // 状态
  String? errorMessage;   // 错误信息

  TtsSegment({
    required this.index,
    required this.text,
    this.ssml,
    required this.startOffset,
    required this.endOffset,
    this.duration,
    this.cachePath,
    this.status = SegmentStatus.pending,
    this.errorMessage,
  });

  /// 是否有 SSML 内容
  bool get hasSsml => ssml != null && ssml!.isNotEmpty;

  /// 生成完整的 SSML（包含 speak/voice 标签）
  String toFullSsml({
    required String voiceName,
    String rate = '+0%',
    String? style,
    String? role,
  }) {
    final content = ssml ?? _escapeXml(text);

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

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// 从 JSON 创建
  factory TtsSegment.fromJson(Map<String, dynamic> json) {
    return TtsSegment(
      index: json['index'] as int,
      text: json['text'] as String,
      ssml: json['ssml'] as String?,
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
      duration: json['duration'] != null
          ? Duration(milliseconds: (json['duration'] as num).toInt())
          : null,
      cachePath: json['cachePath'] as String?,
      status: SegmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SegmentStatus.pending,
      ),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'text': text,
      'ssml': ssml,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'duration': duration?.inMilliseconds,
      'cachePath': cachePath,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  /// 复制并修改
  TtsSegment copyWith({
    String? ssml,
    Duration? duration,
    String? cachePath,
    SegmentStatus? status,
    String? errorMessage,
  }) {
    return TtsSegment(
      index: index,
      text: text,
      ssml: ssml ?? this.ssml,
      startOffset: startOffset,
      endOffset: endOffset,
      duration: duration ?? this.duration,
      cachePath: cachePath ?? this.cachePath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() => 'TtsSegment(index: $index, status: $status, text: "${text.length > 20 ? '${text.substring(0, 20)}...' : text}")';
}
