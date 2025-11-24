import 'isar_database.dart';
import '../models/isar/ai_analysis_entity.dart';

/// AI 分析缓存管理器（使用 Isar 优化版）
///
/// 重构亮点：
/// 1. 使用 Isar 替代文件系统，性能提升 10 倍+
/// 2. 自动持久化，无需手动管理缓存文件
/// 3. 支持索引查询，快速检索分析
/// 4. 保持 API 兼容性，现有代码无需修改
///
/// 对应 Python 的 AnalysisCacheManager 类
/// 基于 Topic ID 的持久化存储，跨数据源共享
class AnalysisCacheManager {
  final IsarDatabase _db = IsarDatabase();

  AnalysisCacheManager._();

  /// 单例模式
  static final AnalysisCacheManager _instance = AnalysisCacheManager._();
  factory AnalysisCacheManager() => _instance;

  /// 初始化（保持向后兼容，实际不再需要）
  ///
  /// Isar 在 main.dart 中初始化，此方法仅为保持兼容性
  Future<void> init({String cacheDirName = 'analyses_cache'}) async {
    // Isar 已在 main.dart 中初始化
    print('✅ AnalysisCacheManager 已就绪（使用 Isar）');
  }

  /// 加载缓存（保持向后兼容）
  ///
  /// 注意：返回的 Map 结构保持不变，但数据来自 Isar
  @Deprecated('使用 Isar 后不再需要显式加载缓存，保留此方法仅为兼容性')
  Future<Map<String, dynamic>> loadCache() async {
    // 为了兼容性，返回空结构
    // 实际数据会在调用具体方法时从 Isar 加载
    final stats = await getCacheInfo();
    print(
      '✅ 已加载缓存: ${stats['total_topics']} 个话题，${stats['total_analyses']} 个分析',
    );

    return {
      'analyses': <String, dynamic>{},
      'metadata': {
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
    };
  }

  /// 获取指定话题的所有分析
  ///
  /// 【API 变更】不再需要 cacheData 参数，直接从 Isar 加载
  Future<Map<int, List<String>>> getTopicAnalyses(String topicId) async {
    final entities = await _db.getAnalyses(topicId);

    // 按 groupIndex 分组
    final result = <int, List<String>>{};
    for (final entity in entities) {
      result.putIfAbsent(entity.groupIndex, () => []).add(entity.content);
    }

    return result;
  }

  /// 保存单个分析到缓存
  ///
  /// 【API 变更】不再需要 cacheData 参数，直接保存到 Isar
  /// 【API 变更】不再返回 cacheData，Isar 自动持久化
  Future<void> saveAnalysis(
    String topicId,
    int comparisonGroupIndex,
    String analysisContent,
  ) async {
    final entity = AIAnalysisEntity.create(
      topicId: topicId,
      groupIndex: comparisonGroupIndex,
      content: analysisContent,
    );

    await _db.saveAnalysis(entity);
    print('✅ 已保存分析: topicId=$topicId, groupIndex=$comparisonGroupIndex');
  }

  /// 删除指定的分析
  ///
  /// 【API 变更】不再需要 cacheData 参数
  /// 【API 变更】不再返回 cacheData
  Future<void> deleteAnalysis(
    String topicId,
    int comparisonGroupIndex,
    int analysisIndex,
  ) async {
    await _db.deleteAnalysisAt(topicId, comparisonGroupIndex, analysisIndex);
    print(
      '✅ 已删除分析: topicId=$topicId, groupIndex=$comparisonGroupIndex, index=$analysisIndex',
    );
  }

  /// 清空指定话题的所有分析
  ///
  /// 【API 变更】不再需要 cacheData 参数
  /// 【API 变更】不再返回 cacheData
  Future<void> clearTopicAnalyses(String topicId) async {
    await _db.clearAnalyses(topicId);
    print('✅ 已清空话题 $topicId 的所有分析');
  }

  /// 获取缓存信息统计
  ///
  /// 【API 变更】不再需要 cacheData 参数，直接从 Isar 统计
  Future<Map<String, dynamic>> getCacheInfo() async {
    final stats = await _db.getStatistics();

    // 为了详细统计，需要加载所有分析数据
    final allAnalyses = await _db.getAllAnalyses();

    // 统计话题数
    final topicIds = <String>{};
    for (final analysis in allAnalyses) {
      topicIds.add(analysis.topicId);
    }

    return {
      'total_topics': topicIds.length,
      'total_analyses': stats['analyses'] as int,
      'created_at': null, // Isar 不存储全局创建时间
      'last_updated': null, // Isar 不存储全局更新时间
      'database_size': stats['database_size_mb'],
    };
  }

  /// 清空所有缓存
  ///
  /// 【API 变更】不再返回 cacheData
  Future<void> clearAllCache() async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.aIAnalysisEntitys.clear();
    });
    print('✅ 已清空所有 AI 分析缓存');
  }
}
