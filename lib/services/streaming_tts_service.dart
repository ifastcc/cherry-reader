import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'tts_cache_manager.dart';
import '../utils/markdown_to_ssml_converter.dart';

/// 流式 TTS 服务
///
/// 支持边下载边播放，同时缓存到本地文件。
/// 使用 Azure TTS REST API 的流式响应。
class StreamingTtsService {
  final List<String> apiKeys;
  int currentKeyIndex;
  final String region;
  final Dio _dio = Dio();

  /// SSML 配置
  SsmlConfig ssmlConfig = const SsmlConfig();

  StreamingTtsService({
    String? apiKey,
    List<String>? apiKeys,
    required this.region,
    this.currentKeyIndex = 0,
  }) : apiKeys = apiKeys ?? (apiKey != null ? [apiKey] : []);

  String get _ttsUrl =>
      'https://$region.tts.speech.microsoft.com/cognitiveservices/v1';

  String? get _currentApiKey {
    if (apiKeys.isEmpty) return null;
    if (currentKeyIndex < 0 || currentKeyIndex >= apiKeys.length) {
      currentKeyIndex = 0;
    }
    return apiKeys[currentKeyIndex];
  }

  bool _switchToNextKey() {
    if (apiKeys.length <= 1) return false;
    currentKeyIndex = (currentKeyIndex + 1) % apiKeys.length;
    debugPrint('TTS: Switching to next API key (index: $currentKeyIndex)');
    return true;
  }

  void setSsmlConfig(SsmlConfig config) {
    ssmlConfig = config;
  }

  String get _voicesUrl =>
      'https://$region.tts.speech.microsoft.com/cognitiveservices/voices/list';

  /// 获取可用声音列表
  Future<List<Map<String, String>>> getVoices() async {
    final currentKey = _currentApiKey;
    if (currentKey == null || currentKey.isEmpty) {
      throw Exception('No API key configured');
    }

    try {
      final response = await _dio.get(
        _voicesUrl,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': currentKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map<Map<String, String>>((voice) {
          return {
            'name': voice['Name'],
            'displayName': voice['DisplayName'],
            'localName': voice['LocalName'],
            'shortName': voice['ShortName'],
            'gender': voice['Gender'],
            'locale': voice['Locale'],
          };
        }).toList();
      } else {
        throw Exception('Failed to load voices: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting voices: $e');
      if (_switchToNextKey()) {
        return getVoices();
      }
      rethrow;
    }
  }

  /// 语音试听（生成短音频用于预览，不使用缓存）
  Future<String> previewVoice({
    required String voiceName,
    String previewText = "只有一件事会使人疲劳，摇摆不定和优柔寡断。",
    double rate = 1.0,
  }) async {
    debugPrint('TTS Preview: Generating preview for $voiceName');

    final currentKey = _currentApiKey;
    if (currentKey == null || currentKey.isEmpty) {
      throw Exception('No API key configured');
    }

    final ratePct = ((rate - 1.0) * 100).toStringAsFixed(0) + '%';
    final rateStr = (rate >= 1.0 ? '+' : '') + ratePct;

    final ssml = '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
<voice name="$voiceName">
<prosody rate="$rateStr">
$previewText
</prosody>
</voice>
</speak>
''';

    try {
      final response = await _dio.post(
        _ttsUrl,
        data: ssml,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': currentKey,
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
            'User-Agent': 'CherryViewer',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        final tempDir = await Directory.systemTemp.createTemp('tts_preview_');
        final tempFile = File('${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tempFile.writeAsBytes(response.data);
        return tempFile.path;
      } else {
        throw Exception('TTS Preview Failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error previewing voice: $e');
      if (_switchToNextKey()) {
        return previewVoice(voiceName: voiceName, previewText: previewText, rate: rate);
      }
      rethrow;
    }
  }

  /// 创建流式音频源
  ///
  /// 返回一个可以边下载边播放的音频源。
  /// 如果缓存中已有，直接返回文件源。
  Future<AudioSource> createStreamingSource({
    required String text,
    required String voiceName,
    String style = 'general',
    String role = '',
    double rate = 1.0,
    double pitch = 1.0,
    String? messageId,
    bool isMarkdown = true,
  }) async {
    debugPrint('🔊 createStreamingSource 开始');
    final stopwatch = Stopwatch()..start();

    final currentKey = _currentApiKey;
    if (currentKey == null || currentKey.isEmpty) {
      throw Exception('No API key configured');
    }

    // 构建 SSML（无论是否缓存都需要，用于生成缓存 key 和调试）
    debugPrint('🔊 [SSML] 开始转换...');
    final ssmlStopwatch = Stopwatch()..start();
    final ratePct = ((rate - 1.0) * 100).toStringAsFixed(0) + '%';
    final rateStr = (rate >= 1.0 ? '+' : '') + ratePct;

    String ssml;
    String ssmlContent; // 用于调试的纯内容部分
    if (isMarkdown) {
      final converter = MarkdownToSsmlConverter(config: ssmlConfig);
      ssmlContent = converter.convert(text); // 只转换内容部分
      ssml = converter.convertToFullSsml(
        markdown: text,
        voiceName: voiceName,
        rate: rateStr,
        style: style != 'general' && style.isNotEmpty ? style : null,
        role: role.isNotEmpty ? role : null,
      );
    } else {
      ssmlContent = text;
      ssml = _buildSimpleSsml(
        text: text,
        voiceName: voiceName,
        rate: rateStr,
        style: style,
        role: role,
      );
    }
    debugPrint('🔊 [SSML] 转换完成: ${ssmlStopwatch.elapsedMilliseconds}ms');

    // DEBUG: 打印原始文本和转换后的内容
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('TTS DEBUG - isMarkdown: $isMarkdown');
    debugPrint('TTS DEBUG - 原始文本长度: ${text.length} 字符');
    debugPrint('TTS DEBUG - SSML 长度: ${ssml.length} 字符');
    debugPrint('───────────────────────────────────────────────────────────');
    debugPrint('TTS DEBUG - 原始文本 (完整):');
    // 分段打印，避免日志截断
    for (int i = 0; i < text.length; i += 500) {
      final end = (i + 500 < text.length) ? i + 500 : text.length;
      debugPrint('[原始 $i-$end] ${text.substring(i, end)}');
    }
    debugPrint('───────────────────────────────────────────────────────────');
    debugPrint('TTS DEBUG - 转换后SSML内容 (完整):');
    for (int i = 0; i < ssmlContent.length; i += 500) {
      final end = (i + 500 < ssmlContent.length) ? i + 500 : ssmlContent.length;
      debugPrint('[SSML $i-$end] ${ssmlContent.substring(i, end)}');
    }
    debugPrint('───────────────────────────────────────────────────────────');
    // 打印特殊字符分析
    debugPrint('TTS DEBUG - 特殊字符分析:');
    final specialChars = <String, int>{};
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);
      // 检测非常规字符（非 ASCII 可打印字符，除了常见中文等）
      if (code < 32 || (code > 126 && code < 0x4E00) || code > 0x9FFF) {
        final key = 'U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')} ($char)';
        specialChars[key] = (specialChars[key] ?? 0) + 1;
      }
    }
    if (specialChars.isNotEmpty) {
      specialChars.forEach((char, count) {
        debugPrint('  $char: $count 次');
      });
    } else {
      debugPrint('  (无特殊字符)');
    }
    debugPrint('═══════════════════════════════════════════════════════════');

    // 1. 检查缓存
    debugPrint('🔊 [缓存] 检查缓存...');
    final cacheManager = TtsCacheManager();
    final cacheText = isMarkdown ? 'md:$text' : text;
    final cachedFile = await cacheManager.getFile(
      text: cacheText,
      voiceName: voiceName,
      style: style,
      rate: rate,
      pitch: pitch,
      messageId: messageId,
    );
    debugPrint('🔊 [缓存] 检查完成: ${stopwatch.elapsedMilliseconds}ms');

    if (cachedFile != null) {
      debugPrint('🔊 Cache HIT - ${cachedFile.path}');
      debugPrint('🔊 createStreamingSource 完成 (缓存命中): ${stopwatch.elapsedMilliseconds}ms');
      return AudioSource.file(cachedFile.path);
    }

    // 2. 缓存未命中，需要下载
    debugPrint('🔊 Cache MISS - downloading audio...');

    // 3. 直接下载完整音频（更可靠）
    final httpStopwatch = Stopwatch()..start();
    debugPrint('⏱️ TTS HTTP: 开始请求 Azure TTS API...');
    debugPrint('⏱️ TTS HTTP: SSML 大小 = ${ssml.length} 字符');

    try {
      final response = await _dio.post<List<int>>(
        _ttsUrl,
        data: ssml,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': currentKey,
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
            'User-Agent': 'CherryViewer',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('TTS API Failed: ${response.statusCode}');
      }

      final audioData = Uint8List.fromList(response.data!);
      debugPrint('⏱️ TTS HTTP: 请求完成 - ${httpStopwatch.elapsedMilliseconds}ms');
      debugPrint('⏱️ TTS HTTP: 音频大小 = ${audioData.length} bytes (${(audioData.length / 1024).toStringAsFixed(1)} KB)');

      // 保存到缓存
      final file = await cacheManager.saveFile(
        data: audioData,
        text: cacheText,
        voiceName: voiceName,
        style: style,
        rate: rate,
        pitch: pitch,
        messageId: messageId,
      );
      debugPrint('🔊 已缓存到: ${file.path}');
      debugPrint('🔊 createStreamingSource 完成 (新下载): ${stopwatch.elapsedMilliseconds}ms');

      // 返回文件音频源
      return AudioSource.file(file.path);
    } catch (e) {
      debugPrint('🔊 TTS HTTP 请求失败: $e');
      if (_switchToNextKey()) {
        debugPrint('🔊 尝试切换到下一个 API Key...');
        // 递归重试
        return createStreamingSource(
          text: text,
          voiceName: voiceName,
          style: style,
          role: role,
          rate: rate,
          pitch: pitch,
          messageId: messageId,
          isMarkdown: isMarkdown,
        );
      }
      rethrow;
    }
  }

  /// 同步方式合成（用于兼容旧代码或预加载）
  Future<String> synthesize({
    required String text,
    required String voiceName,
    String style = 'general',
    String role = '',
    double rate = 1.0,
    double pitch = 1.0,
    String? messageId,
    bool isMarkdown = true,
  }) async {
    final currentKey = _currentApiKey;
    if (currentKey == null || currentKey.isEmpty) {
      throw Exception('No API key configured');
    }

    // 1. 检查缓存
    final cacheManager = TtsCacheManager();
    final cacheText = isMarkdown ? 'md:$text' : text;
    final cachedFile = await cacheManager.getFile(
      text: cacheText,
      voiceName: voiceName,
      style: style,
      rate: rate,
      pitch: pitch,
      messageId: messageId,
    );

    if (cachedFile != null) {
      debugPrint('TTS: Cache hit');
      return cachedFile.path;
    }

    // 2. 构建 SSML
    final ratePct = ((rate - 1.0) * 100).toStringAsFixed(0) + '%';
    final rateStr = (rate >= 1.0 ? '+' : '') + ratePct;

    String ssml;
    if (isMarkdown) {
      final converter = MarkdownToSsmlConverter(config: ssmlConfig);
      ssml = converter.convertToFullSsml(
        markdown: text,
        voiceName: voiceName,
        rate: rateStr,
        style: style != 'general' && style.isNotEmpty ? style : null,
        role: role.isNotEmpty ? role : null,
      );
    } else {
      ssml = _buildSimpleSsml(
        text: text,
        voiceName: voiceName,
        rate: rateStr,
        style: style,
        role: role,
      );
    }

    // 3. 请求 API
    try {
      final response = await _dio.post(
        _ttsUrl,
        data: ssml,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': currentKey,
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
            'User-Agent': 'CherryViewer',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        final file = await cacheManager.saveFile(
          data: response.data,
          text: cacheText,
          voiceName: voiceName,
          style: style,
          rate: rate,
          pitch: pitch,
          messageId: messageId,
        );
        return file.path;
      } else {
        throw Exception('TTS API Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (_switchToNextKey()) {
        return synthesize(
          text: text,
          voiceName: voiceName,
          style: style,
          role: role,
          rate: rate,
          pitch: pitch,
          messageId: messageId,
          isMarkdown: isMarkdown,
        );
      }
      rethrow;
    }
  }

  String _buildSimpleSsml({
    required String text,
    required String voiceName,
    required String rate,
    required String style,
    required String role,
  }) {
    final escapedText = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    if (style != 'general' && style.isNotEmpty) {
      return '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="zh-CN">
<voice name="$voiceName">
<mstts:express-as style="$style"${role.isNotEmpty ? ' role="$role"' : ''}>
<prosody rate="$rate">
$escapedText
</prosody>
</mstts:express-as>
</voice>
</speak>''';
    } else {
      return '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
<voice name="$voiceName">
<prosody rate="$rate">
$escapedText
</prosody>
</voice>
</speak>''';
    }
  }
}
