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
  final String text;      // 处理后的纯文本（用于 TTS 合成、缓存 key）
  final String? rawText;  // 原始格式文本（保留换行，用于显示）
  final String? ssml;     // SSML 内容（不含外层 speak/voice 标签）
  final int startOffset;  // 在原文中的起始位置
  final int endOffset;    // 在原文中的结束位置

  Duration? duration;     // 音频时长（播放后获取）
  String? cachePath;      // 缓存文件路径
  SegmentStatus status;   // 状态
  String? errorMessage;   // 错误信息

  // 新增：全局缓存 Key（32 位 MD5）
  String? audioCacheKey;  // 音频缓存 Key（基于 ssml+voice+rate+style）

  // 新增：重试信息
  int retryCount;         // 已重试次数
  DateTime? lastErrorTime; // 最后一次错误时间

  TtsSegment({
    required this.index,
    required this.text,
    this.rawText,
    this.ssml,
    required this.startOffset,
    required this.endOffset,
    this.duration,
    this.cachePath,
    this.status = SegmentStatus.pending,
    this.errorMessage,
    this.audioCacheKey,
    this.retryCount = 0,
    this.lastErrorTime,
  });

  /// 获取显示用的文本（优先使用 rawText，回退到 text）
  String get displayText => rawText ?? text;

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
      rawText: json['rawText'] as String?,
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
      audioCacheKey: json['audioCacheKey'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      lastErrorTime: json['lastErrorTime'] != null
          ? DateTime.parse(json['lastErrorTime'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'text': text,
      'rawText': rawText,
      'ssml': ssml,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'duration': duration?.inMilliseconds,
      'cachePath': cachePath,
      'status': status.name,
      'errorMessage': errorMessage,
      'audioCacheKey': audioCacheKey,
      'retryCount': retryCount,
      'lastErrorTime': lastErrorTime?.toIso8601String(),
    };
  }

  /// 复制并修改
  TtsSegment copyWith({
    String? ssml,
    Duration? duration,
    String? cachePath,
    SegmentStatus? status,
    String? errorMessage,
    String? audioCacheKey,
    int? retryCount,
    DateTime? lastErrorTime,
  }) {
    return TtsSegment(
      index: index,
      text: text,
      rawText: rawText,
      ssml: ssml ?? this.ssml,
      startOffset: startOffset,
      endOffset: endOffset,
      duration: duration ?? this.duration,
      cachePath: cachePath ?? this.cachePath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      audioCacheKey: audioCacheKey ?? this.audioCacheKey,
      retryCount: retryCount ?? this.retryCount,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
    );
  }

  @override
  String toString() => 'TtsSegment(index: $index, status: $status, text: "${text.length > 20 ? '${text.substring(0, 20)}...' : text}")';
}
