import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Embedding 服务
///
/// 接入硅基流动的向量服务，用于语义搜索
/// 模型：BAAI/bge-large-zh-v1.5（中文优化）
class EmbeddingService {
  static final EmbeddingService _instance = EmbeddingService._internal();
  static EmbeddingService get instance => _instance;
  EmbeddingService._internal();

  static const String _apiUrl = 'https://api.siliconflow.cn/v1/embeddings';
  static const String _model = 'BAAI/bge-large-zh-v1.5';
  static const int _dimensions = 1024;
  static const String _apiKeyPrefKey = 'siliconflow_api_key';

  String? _apiKey;

  /// 初始化服务
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPrefKey);
  }

  /// 设置 API Key
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey);
  }

  /// 获取 API Key
  String? get apiKey => _apiKey;

  /// 是否已配置
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// 生成单个文本的 embedding
  Future<List<double>?> embed(String text) async {
    if (!isConfigured) {
      debugPrint('⚠️ EmbeddingService: API Key 未配置');
      return null;
    }

    if (text.trim().isEmpty) {
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'input': text,
          'encoding_format': 'float',
          'dimensions': _dimensions,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = data['data'][0]['embedding'] as List;
        return embedding.map((e) => (e as num).toDouble()).toList();
      } else {
        debugPrint('❌ Embedding API 错误: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Embedding 请求失败: $e');
      return null;
    }
  }

  /// 批量生成 embedding
  ///
  /// 硅基流动支持批量请求，最多 64 个文本
  Future<List<List<double>?>> embedBatch(List<String> texts) async {
    if (!isConfigured) {
      debugPrint('⚠️ EmbeddingService: API Key 未配置');
      return List.filled(texts.length, null);
    }

    if (texts.isEmpty) {
      return [];
    }

    // 过滤空文本，记录原始索引
    final validTexts = <String>[];
    final validIndices = <int>[];
    for (var i = 0; i < texts.length; i++) {
      if (texts[i].trim().isNotEmpty) {
        validTexts.add(texts[i]);
        validIndices.add(i);
      }
    }

    if (validTexts.isEmpty) {
      return List.filled(texts.length, null);
    }

    // 分批处理（每批最多 64 个）
    final results = List<List<double>?>.filled(texts.length, null);
    const batchSize = 64;

    for (var batchStart = 0; batchStart < validTexts.length; batchStart += batchSize) {
      final batchEnd = (batchStart + batchSize).clamp(0, validTexts.length);
      final batch = validTexts.sublist(batchStart, batchEnd);
      final batchIndices = validIndices.sublist(batchStart, batchEnd);

      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'input': batch,
            'encoding_format': 'float',
            'dimensions': _dimensions,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final embeddings = data['data'] as List;

          for (final item in embeddings) {
            final index = item['index'] as int;
            final embedding = item['embedding'] as List;
            final originalIndex = batchIndices[index];
            results[originalIndex] = embedding.map((e) => (e as num).toDouble()).toList();
          }
        } else {
          debugPrint('❌ Embedding API 错误: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        debugPrint('❌ Embedding 批量请求失败: $e');
      }
    }

    return results;
  }

  /// 计算余弦相似度
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('向量维度不匹配: ${a.length} vs ${b.length}');
    }

    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) {
      return 0;
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// 在向量列表中搜索最相似的
  ///
  /// 返回 (索引, 相似度) 列表，按相似度降序
  static List<(int, double)> searchSimilar(
    List<double> query,
    List<List<double>> candidates, {
    int limit = 10,
    double minScore = 0.5,
  }) {
    final scores = <(int, double)>[];

    for (var i = 0; i < candidates.length; i++) {
      final score = cosineSimilarity(query, candidates[i]);
      if (score >= minScore) {
        scores.add((i, score));
      }
    }

    scores.sort((a, b) => b.$2.compareTo(a.$2));

    return scores.take(limit).toList();
  }
}
