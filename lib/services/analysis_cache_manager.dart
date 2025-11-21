import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// AI 分析缓存管理器
///
/// 对应 Python 的 AnalysisCacheManager 类
/// 基于 Topic ID 的持久化存储，跨数据源共享
class AnalysisCacheManager {
  late final Directory cacheDir;
  late final File cacheFile;
  Map<String, dynamic>? cacheData;

  AnalysisCacheManager._();

  /// 单例模式
  static final AnalysisCacheManager _instance = AnalysisCacheManager._();
  factory AnalysisCacheManager() => _instance;

  /// 初始化缓存目录
  Future<void> init({String cacheDirName = 'analyses_cache'}) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    cacheDir = Directory(path.join(appDocDir.path, cacheDirName));

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    cacheFile = File(path.join(cacheDir.path, 'analyses.json'));
    print('📁 缓存目录: ${cacheDir.path}');
  }

  /// 加载缓存（全局单一缓存文件）
  Future<Map<String, dynamic>> loadCache() async {
    if (!await cacheFile.exists()) {
      // 缓存不存在，返回空结构
      cacheData = _createEmptyCache();
      return cacheData!;
    }

    try {
      final jsonString = await cacheFile.readAsString();
      cacheData = json.decode(jsonString) as Map<String, dynamic>;

      final totalTopics = (cacheData!['analyses'] as Map?)?.length ?? 0;
      var totalAnalyses = 0;

      final analyses = cacheData!['analyses'] as Map<String, dynamic>? ?? {};
      for (final topicAnalyses in analyses.values) {
        if (topicAnalyses is Map) {
          for (final analysisList in topicAnalyses.values) {
            if (analysisList is List) {
              totalAnalyses += analysisList.length;
            }
          }
        }
      }

      if (totalAnalyses > 0) {
        print('✅ 已加载缓存: $totalTopics 个话题，$totalAnalyses 个分析');
      }

      return cacheData!;
    } catch (e) {
      print('⚠️  加载缓存失败: $e');
      cacheData = _createEmptyCache();
      return cacheData!;
    }
  }

  /// 创建空缓存结构
  Map<String, dynamic> _createEmptyCache() {
    return {
      'analyses': <String, dynamic>{},
      'metadata': {
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      }
    };
  }

  /// 获取指定话题的所有分析
  Map<int, List<String>> getTopicAnalyses(
    Map<String, dynamic> cacheData,
    String topicId,
  ) {
    final topicAnalyses =
        (cacheData['analyses'] as Map<String, dynamic>?)?[topicId] as Map? ?? {};

    final result = <int, List<String>>{};

    // 转换字符串 key 为 int（JSON 不支持 int key）
    for (final entry in topicAnalyses.entries) {
      try {
        final key = int.parse(entry.key.toString());
        final value = entry.value as List<dynamic>?;
        result[key] = value?.map((e) => e.toString()).toList() ?? [];
      } catch (e) {
        // 无法转换为 int 的 key 将被忽略
      }
    }

    return result;
  }

  /// 保存单个分析到缓存
  Future<Map<String, dynamic>> saveAnalysis(
    Map<String, dynamic> cacheData,
    String topicId,
    int comparisonGroupIndex,
    String analysisContent,
  ) async {
    // 确保结构存在
    cacheData['analyses'] ??= <String, dynamic>{};

    final analyses = cacheData['analyses'] as Map<String, dynamic>;
    analyses[topicId] ??= <String, dynamic>{};

    final topicAnalyses = analyses[topicId] as Map<String, dynamic>;

    // 转换 int key 为 str（JSON 要求）
    final groupKey = comparisonGroupIndex.toString();
    topicAnalyses[groupKey] ??= <String>[];

    final analysisList = topicAnalyses[groupKey] as List;
    analysisList.add(analysisContent);

    // 更新时间戳
    (cacheData['metadata'] as Map)['last_updated'] =
        DateTime.now().toIso8601String();

    // 持久化
    await _persistCache(cacheData);

    return cacheData;
  }

  /// 删除指定的分析
  Future<Map<String, dynamic>> deleteAnalysis(
    Map<String, dynamic> cacheData,
    String topicId,
    int comparisonGroupIndex,
    int analysisIndex,
  ) async {
    try {
      final groupKey = comparisonGroupIndex.toString();
      final analyses = (cacheData['analyses'] as Map<String, dynamic>)[topicId]
          as Map<String, dynamic>?;

      if (analyses == null) {
        print('⚠️  话题不存在: $topicId');
        return cacheData;
      }

      final analysisList = analyses[groupKey] as List<dynamic>?;

      if (analysisList != null &&
          analysisIndex >= 0 &&
          analysisIndex < analysisList.length) {
        analysisList.removeAt(analysisIndex);
        (cacheData['metadata'] as Map)['last_updated'] =
            DateTime.now().toIso8601String();
        await _persistCache(cacheData);
        print('✅ 已删除分析');
      } else {
        print('⚠️  分析索引无效: $analysisIndex');
      }
    } catch (e) {
      print('⚠️  删除失败: $e');
    }

    return cacheData;
  }

  /// 清空指定话题的所有分析
  Future<Map<String, dynamic>> clearTopicAnalyses(
    Map<String, dynamic> cacheData,
    String topicId,
  ) async {
    final analyses = cacheData['analyses'] as Map<String, dynamic>?;
    if (analyses != null && analyses.containsKey(topicId)) {
      analyses.remove(topicId);
      (cacheData['metadata'] as Map)['last_updated'] =
          DateTime.now().toIso8601String();
      await _persistCache(cacheData);
      print('✅ 已清空话题 $topicId 的所有分析');
    }

    return cacheData;
  }

  /// 持久化缓存到文件
  Future<void> _persistCache(Map<String, dynamic> cacheData) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(cacheData);
      await cacheFile.writeAsString(jsonString);
      // print('💾 缓存已保存');
    } catch (e) {
      print('⚠️  保存缓存失败: $e');
    }
  }

  /// 获取缓存信息统计
  Map<String, dynamic> getCacheInfo(Map<String, dynamic> cacheData) {
    final analyses = cacheData['analyses'] as Map<String, dynamic>? ?? {};
    final totalTopics = analyses.length;

    var totalAnalyses = 0;
    for (final topicAnalyses in analyses.values) {
      if (topicAnalyses is Map) {
        for (final analysisList in topicAnalyses.values) {
          if (analysisList is List) {
            totalAnalyses += analysisList.length;
          }
        }
      }
    }

    final fileSize = cacheFile.existsSync() ? cacheFile.lengthSync() : 0;

    return {
      'total_topics': totalTopics,
      'total_analyses': totalAnalyses,
      'created_at': (cacheData['metadata'] as Map?)? ['created_at'],
      'last_updated': (cacheData['metadata'] as Map?)?['last_updated'],
      'file_size': fileSize,
    };
  }

  /// 清空所有缓存
  Future<Map<String, dynamic>> clearAllCache() async {
    cacheData = _createEmptyCache();
    await _persistCache(cacheData!);
    print('✅ 已清空所有缓存');
    return cacheData!;
  }
}
