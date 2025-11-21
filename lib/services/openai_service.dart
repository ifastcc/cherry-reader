import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenAI API 流式响应服务
///
/// 实现 SSE (Server-Sent Events) 流式解析
/// 对应 Python Streamlit 中的 OpenAI streaming API
class OpenAIService {
  final String apiKey;
  final String baseUrl;

  OpenAIService({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
  });

  /// 流式聊天补全
  ///
  /// 返回一个 Stream，实时产生文本片段
  Stream<String> streamChatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    final url = Uri.parse('$baseUrl/chat/completions');

    final requestBody = {
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'stream': true,
      if (maxTokens != null) 'max_tokens': maxTokens,
    };

    final request = http.Request('POST', url);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });
    request.body = json.encode(requestBody);

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw Exception(
        'OpenAI API 错误 (${streamedResponse.statusCode}): $errorBody',
      );
    }

    // 解析 SSE 流
    await for (final chunk in _parseSSEStream(streamedResponse.stream)) {
      // SSE 格式: data: {json}\n\n
      if (chunk.startsWith('data: ')) {
        final jsonData = chunk.substring(6).trim();

        // [DONE] 标记流结束
        if (jsonData == '[DONE]') {
          break;
        }

        try {
          final data = json.decode(jsonData) as Map<String, dynamic>;
          final choices = data['choices'] as List<dynamic>?;

          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;

            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        } catch (e) {
          print('⚠️  解析 SSE 数据失败: $e');
          print('   数据: $jsonData');
        }
      }
    }
  }

  /// 解析 SSE 流
  ///
  /// Server-Sent Events 格式:
  /// data: {...}\n\n
  /// data: {...}\n\n
  Stream<String> _parseSSEStream(Stream<List<int>> byteStream) async* {
    final utf8Stream = byteStream.transform(utf8.decoder);
    var buffer = '';

    await for (final chunk in utf8Stream) {
      buffer += chunk;

      // SSE 消息以 \n\n 分隔
      while (buffer.contains('\n\n')) {
        final index = buffer.indexOf('\n\n');
        final message = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 2);

        if (message.isNotEmpty) {
          yield message;
        }
      }
    }

    // 处理剩余数据
    if (buffer.trim().isNotEmpty) {
      yield buffer.trim();
    }
  }

  /// 非流式聊天补全（一次性返回）
  Future<String> chatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    final requestBody = {
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'stream': false,
      if (maxTokens != null) 'max_tokens': maxTokens,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API 错误 (${response.statusCode}): ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      throw Exception('API 返回为空');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    return message?['content'] as String? ?? '';
  }
}
