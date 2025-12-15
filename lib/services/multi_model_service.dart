import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';
import 'ai_provider_service.dart';

/// 多模型调用结果
class ModelResponse {
  final String modelId;
  final String modelName;
  final String providerId;
  final String providerName;
  final Stream<String> stream;
  final StreamController<String> _contentController;

  String _fullContent = '';
  bool _isComplete = false;
  String? _error;

  ModelResponse({
    required this.modelId,
    required this.modelName,
    required this.providerId,
    required this.providerName,
    required this.stream,
  }) : _contentController = StreamController<String>.broadcast();

  /// 完整内容
  String get fullContent => _fullContent;

  /// 是否已完成
  bool get isComplete => _isComplete;

  /// 错误信息
  String? get error => _error;

  /// 内容流（用于 UI 监听）
  Stream<String> get contentStream => _contentController.stream;

  /// 追加内容
  void appendContent(String chunk) {
    _fullContent += chunk;
    _contentController.add(_fullContent);
  }

  /// 标记完成
  void complete() {
    _isComplete = true;
    _contentController.close();
  }

  /// 标记错误
  void setError(String error) {
    _error = error;
    _isComplete = true;
    _contentController.addError(error);
    _contentController.close();
  }
}

/// 多模型调用服务
///
/// 支持：
/// 1. 并行调用多个模型
/// 2. 每个模型独立的流式返回
/// 3. 聚合结果管理
/// 4. 请求取消机制
class MultiModelService {
  static MultiModelService? _instance;
  static MultiModelService get instance {
    _instance ??= MultiModelService._();
    return _instance!;
  }

  MultiModelService._();

  final AIProviderService _providerService = AIProviderService.instance;

  // 当前活跃的 HTTP 客户端（用于取消请求）
  final List<http.Client> _activeClients = [];

  /// 取消所有正在进行的请求
  void cancelAllRequests() {
    for (final client in _activeClients) {
      client.close();
    }
    _activeClients.clear();
  }

  /// 并行调用多个模型
  ///
  /// [modelConfigs] 格式: [{'providerId': 'xxx', 'modelId': 'yyy'}, ...]
  /// [messages] 对话消息列表
  ///
  /// 返回 Map<modelKey, ModelResponse>，modelKey 格式为 'providerId:modelId'
  Future<Map<String, ModelResponse>> callMultipleModels({
    required List<Map<String, String>> modelConfigs,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    final responses = <String, ModelResponse>{};

    // 为每个模型创建调用
    final futures = <Future<void>>[];

    for (final config in modelConfigs) {
      final providerId = config['providerId'];
      final modelId = config['modelId'];

      if (providerId == null || modelId == null) continue;

      // 查找 provider
      final provider = _providerService.providers.firstWhere(
        (p) => p.id == providerId,
        orElse: () => throw Exception('Provider not found: $providerId'),
      );

      // 查找 model
      final model = provider.models.firstWhere(
        (m) => m.id == modelId,
        orElse: () => AIModel(id: modelId, name: modelId),
      );

      final modelKey = '$providerId:$modelId';

      // 创建流控制器
      final streamController = StreamController<String>.broadcast();

      final response = ModelResponse(
        modelId: modelId,
        modelName: model.displayName,
        providerId: providerId,
        providerName: provider.name,
        stream: streamController.stream,
      );

      responses[modelKey] = response;

      // 异步调用
      futures.add(_callSingleModel(
        provider: provider,
        modelId: modelId,
        messages: messages,
        temperature: temperature,
        response: response,
        streamController: streamController,
      ));
    }

    // 不等待所有完成，让调用方自己监听各个流
    // 但要确保所有调用都已启动
    for (final future in futures) {
      future.catchError((e) {
        // 错误已在 _callSingleModel 中处理
      });
    }

    return responses;
  }

  /// 调用单个模型
  Future<void> _callSingleModel({
    required AIProvider provider,
    required String modelId,
    required List<Map<String, String>> messages,
    required double temperature,
    required ModelResponse response,
    required StreamController<String> streamController,
  }) async {
    // 创建可取消的 HTTP 客户端
    final client = http.Client();
    _activeClients.add(client);

    try {
      final baseUrl = _normalizeBaseUrl(provider.apiHost);
      final url = Uri.parse('$baseUrl/chat/completions');

      final requestBody = {
        'model': modelId,
        'messages': messages,
        'temperature': temperature,
        'stream': true,
      };

      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${provider.apiKey}',
        ...?provider.extraHeaders,
      });
      request.body = json.encode(requestBody);

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('API 错误 (${streamedResponse.statusCode}): $errorBody');
      }

      // 解析 SSE 流
      await for (final chunk in _parseSSEStream(streamedResponse.stream)) {
        if (chunk.startsWith('data: ')) {
          final jsonData = chunk.substring(6).trim();

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
                response.appendContent(content);
                streamController.add(content);
              }
            }
          } catch (e) {
            // 忽略解析错误，继续处理
          }
        }
      }

      response.complete();
      await streamController.close();
    } catch (e) {
      response.setError(e.toString());
      streamController.addError(e);
      await streamController.close();
    } finally {
      // 清理客户端
      _activeClients.remove(client);
      client.close();
    }
  }

  /// 解析 SSE 流
  Stream<String> _parseSSEStream(Stream<List<int>> byteStream) async* {
    final utf8Stream = byteStream.transform(utf8.decoder);
    var buffer = '';

    await for (final chunk in utf8Stream) {
      buffer += chunk;

      while (buffer.contains('\n\n')) {
        final index = buffer.indexOf('\n\n');
        final message = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 2);

        if (message.isNotEmpty) {
          yield message;
        }
      }
    }

    if (buffer.trim().isNotEmpty) {
      yield buffer.trim();
    }
  }

  /// 规范化 base URL
  String _normalizeBaseUrl(String url) {
    var normalized = url.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (!normalized.endsWith('/v1')) {
      normalized = '$normalized/v1';
    }
    return normalized;
  }

  /// 获取所有可用的模型列表（带 provider 信息）
  List<Map<String, dynamic>> getAvailableModels() {
    final models = <Map<String, dynamic>>[];

    for (final provider in _providerService.validProviders) {
      for (final model in provider.models) {
        models.add({
          'providerId': provider.id,
          'providerName': provider.name,
          'modelId': model.id,
          'modelName': model.displayName,
          'displayName': '${model.displayName} (${provider.name})',
        });
      }
    }

    return models;
  }

  /// 根据模型名称模糊搜索
  List<Map<String, dynamic>> searchModels(String query) {
    if (query.isEmpty) return getAvailableModels();

    final lowerQuery = query.toLowerCase();
    return getAvailableModels().where((m) {
      final modelName = (m['modelName'] as String).toLowerCase();
      final providerName = (m['providerName'] as String).toLowerCase();
      return modelName.contains(lowerQuery) || providerName.contains(lowerQuery);
    }).toList();
  }

  /// 重试单个模型调用
  ///
  /// [modelKey] 格式为 'providerId:modelId'
  /// [messages] 对话消息列表
  /// [temperature] 温度参数
  ///
  /// 返回新的 ModelResponse，调用方需要更新 UI
  Future<ModelResponse> retrySingleModel({
    required String modelKey,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    // 解析 modelKey
    final parts = modelKey.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid modelKey format: $modelKey');
    }

    final providerId = parts[0];
    final modelId = parts[1];

    // 查找 provider
    final provider = _providerService.providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw Exception('Provider not found: $providerId'),
    );

    // 查找 model
    final model = provider.models.firstWhere(
      (m) => m.id == modelId,
      orElse: () => AIModel(id: modelId, name: modelId),
    );

    // 创建流控制器
    final streamController = StreamController<String>.broadcast();

    final response = ModelResponse(
      modelId: modelId,
      modelName: model.displayName,
      providerId: providerId,
      providerName: provider.name,
      stream: streamController.stream,
    );

    // 异步调用（不阻塞）
    _callSingleModel(
      provider: provider,
      modelId: modelId,
      messages: messages,
      temperature: temperature,
      response: response,
      streamController: streamController,
    ).catchError((e) {
      // 错误已在 _callSingleModel 中处理
    });

    return response;
  }
}
