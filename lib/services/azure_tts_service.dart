import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'tts_cache_manager.dart';

class AzureTtsService {
  // 支持多个 API Keys
  final List<String> apiKeys;
  int currentKeyIndex;
  final String region;
  final Dio _dio = Dio();

  AzureTtsService({
    String? apiKey,  // 向后兼容单个key
    List<String>? apiKeys,
    required this.region,
    this.currentKeyIndex = 0,
  }) : apiKeys = apiKeys ?? (apiKey != null ? [apiKey] : []);

  String get _tokenUrl =>
      'https://$region.api.cognitive.microsoft.com/sts/v1.0/issueToken';
  String get _ttsUrl =>
      'https://$region.tts.speech.microsoft.com/cognitiveservices/v1';
  String get _voicesUrl =>
      'https://$region.tts.speech.microsoft.com/cognitiveservices/voices/list';

  /// 获取当前使用的 API Key
  String? get _currentApiKey {
    if (apiKeys.isEmpty) return null;
    if (currentKeyIndex < 0 || currentKeyIndex >= apiKeys.length) {
      currentKeyIndex = 0;
    }
    return apiKeys[currentKeyIndex];
  }

  /// 切换到下一个 Key
  bool _switchToNextKey() {
    if (apiKeys.length <= 1) return false;
    currentKeyIndex = (currentKeyIndex + 1) % apiKeys.length;
    debugPrint('TTS: Switching to next API key (index: $currentKeyIndex)');
    return true;
  }

  /// 获取访问令牌 (Optional, usually can use key directly in headers for some endpoints, 
  /// but for TTS strictly speaking Ocp-Apim-Subscription-Key header is supported directly)
  /// We will use the Key directly in headers for simplicity unless Token is strictly required for long sessions.
  /// Azure TTS REST API supports `Ocp-Apim-Subscription-Key` header.

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
        // Filter for Chinese voices or return all? Let's return all but maybe prioritize later.
        // For now, mapping to a simple structure.
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
      
      // 尝试切换到下一个 Key
      if (_switchToNextKey()) {
        debugPrint('TTS: Retrying with next API key...');
        return getVoices(); // 递归重试
      }
      
      rethrow;
    }
  }

  /// 语音试听
  /// 生成短音频用于预览语音效果，不使用缓存
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

    // Rate conversion
    final ratePct = ((rate - 1.0) * 100).toStringAsFixed(0) + '%';
    final rateStr = (rate >= 1.0 ? '+' : '') + ratePct;
    
    final ssml = '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
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
        // 保存到临时文件（不使用缓存管理器）
        final tempDir = await Directory.systemTemp.createTemp('tts_preview_');
        final tempFile = File('${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tempFile.writeAsBytes(response.data);
        return tempFile.path;
      } else {
        throw Exception('TTS Preview Failed: ${response.statusCode} ${response.statusMessage}');
      }
    } catch (e) {
      debugPrint('Error previewing voice: $e');
      
      // 尝试切换到下一个 Key
      if (_switchToNextKey()) {
        debugPrint('TTS: Retrying preview with next API key...');
        return previewVoice(voiceName: voiceName, previewText: previewText, rate: rate);
      }
      
      rethrow;
    }
  }

  /// 合成语音
  /// Returns the path to the cached audio file.
  Future<String> synthesize({
    required String text,
    required String voiceName, // e.g., "zh-CN-XiaoxiaoNeural"
    String style = 'general', // e.g., "chat", "sad" (depends on voice)
    String role = '', // e.g., "YoungAdultFemale"
    double rate = 1.0, // 0.5 to 2.0
    double pitch = 1.0, // 0.5 to 2.0 (approx)
    String? messageId,
  }) async {
    final currentKey = _currentApiKey;
    if (currentKey == null || currentKey.isEmpty) {
      throw Exception('No API key configured');
    }

    // 1. Check Cache
    final cacheManager = TtsCacheManager();
    final cachedFile = await cacheManager.getFile(
      text: text,
      voiceName: voiceName,
      style: style,
      rate: rate,
      pitch: pitch,
      messageId: messageId,
    );

    if (cachedFile != null) {
      debugPrint('TTS Cache hit: ${cachedFile.path}');
      return cachedFile.path;
    }

    // 2. Call API
    debugPrint('TTS Cache miss, calling Azure API...');
    
    // SSML Construction
    // Rate: percentage or relative. 1.0 = +0%. 1.5 = +50%.
    // Azure expects string like "+50.00%" or "-10.00%".
    // Let's convert double rate to percentage string.
    // 1.0 -> "0%", 1.5 -> "+50%", 0.8 -> "-20%"
    final ratePct = ((rate - 1.0) * 100).toStringAsFixed(0) + '%';
    final rateStr = (rate >= 1.0 ? '+' : '') + ratePct;
    
    // Pitch is similar if we want to support it, but let's keep it simple or default.
    
    final ssml = '''
<speak version='1.0' xml:lang='en-US'>
<voice xml:lang='en-US' xml:gender='Female' name='$voiceName'>
<prosody rate='$rateStr'>
$text
</prosody>
</voice>
</speak>
''';
// Note: style and role are voice-specific and require <mstts:express-as> tag.
// For simplicity in V1, we might omit them or add if requested.
// The user mentioned "multiple voices", not necessarily styles, but styles are cool.
// Let's add style support if provided and not 'general'.

    String finalSsml = ssml;
    if (style != 'general' && style.isNotEmpty) {
       finalSsml = '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="en-US">
<voice name="$voiceName">
<mstts:express-as style="$style" ${role.isNotEmpty ? 'role="$role"' : ''}>
<prosody rate="$rateStr">
$text
</prosody>
</mstts:express-as>
</voice>
</speak>
''';
    } else {
       finalSsml = '''
<speak version='1.0' xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
<voice name="$voiceName">
<prosody rate="$rateStr">
$text
</prosody>
</voice>
</speak>
''';
    }

    try {
      final response = await _dio.post(
        _ttsUrl,
        data: finalSsml,
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
        // 3. Save to Cache
        final file = await cacheManager.saveFile(
          data: response.data,
          text: text,
          voiceName: voiceName,
          style: style,
          rate: rate,
          pitch: pitch,
          messageId: messageId,
        );
        return file.path;
      } else {
        throw Exception('TTS API Failed: ${response.statusCode} ${response.statusMessage}');
      }
    } catch (e) {
      debugPrint('Error synthesizing speech: $e');
      
      // 尝试切换到下一个 Key
      if (_switchToNextKey()) {
        debugPrint('TTS: Retrying synthesis with next API key...');
        return synthesize(
          text: text,
          voiceName: voiceName,
          style: style,
          role: role,
          rate: rate,
          pitch: pitch,
          messageId: messageId,
        );
      }
      
      rethrow;
    }
  }

  /// 验证配置是否有效
  Future<bool> validateConfig() async {
    try {
      await getVoices();
      return true;
    } catch (e) {
      return false;
    }
  }
}
