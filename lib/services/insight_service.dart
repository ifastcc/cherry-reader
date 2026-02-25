import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_db.dart';
import 'ai_provider_service.dart';
import 'openai_service.dart';
import 'perspective_storage.dart';
import 'insight/drift_insight_store.dart';
import 'insight/i_insight_store.dart';
import '../models/domain/insight_models.dart';
import '../models/isar/perspective_entity.dart';
import '../models/isar/insight_entity.dart';

/// AI 洞察服务
///
/// 提供视角管理、数据查询、洞察生成等功能
class InsightService {
  // 单例模式
  InsightService._();
  static final InsightService instance = InsightService._();

  final AppDb _db = AppDb();
  late final IInsightStore _store = DriftInsightStore(_db);
  bool _initialized = false;

  // 缓存
  List<Map<String, String>>? _assistantListCache;
  Map<String, String>? _assistantIdToNameCache;  // ID -> Name 映射
  List<TopicGroup>? _allTopicGroupsCache;  // 全量话题缓存（预加载）
  bool _isPreloading = false;

  /// 初始化服务
  Future<void> init() async {
    if (_initialized) return;
    await _db.init();
    _initialized = true;
  }

  // ============ 视角管理 ============

  /// 获取所有视角
  Future<List<PerspectiveEntity>> getAllPerspectives() async {
    return _store.getAllPerspectives();
  }

  /// 获取启用的视角
  Future<List<PerspectiveEntity>> getEnabledPerspectives() async {
    return _store.getEnabledPerspectives();
  }

  /// 切换视角启用状态
  Future<void> togglePerspectiveEnabled(String perspectiveId, bool isEnabled) async {
    await _store.togglePerspectiveEnabled(perspectiveId, isEnabled);
  }

  /// 添加自定义视角
  Future<void> addCustomPerspective(PerspectiveEntity perspective) async {
    await _store.upsertPerspective(perspective);
  }

  /// 更新自定义视角
  Future<void> updateCustomPerspective(PerspectiveEntity perspective) async {
    await _store.upsertPerspective(perspective);
  }

  /// 删除自定义视角（不允许删除内置视角）
  Future<bool> deleteCustomPerspective(String perspectiveId) async {
    return _store.deleteCustomPerspective(perspectiveId);
  }

  /// 强制重置内置视角
  Future<void> forceResetBuiltinPerspectives() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('builtin_perspectives_version', 0);
    await _db.initBuiltinPerspectives();
  }

  // ============ 自定义分组管理 ============

  /// 获取所有自定义分组名称（非内置分组）
  Future<List<String>> getCustomCategories() async {
    final customPerspectives = await _store.getCustomPerspectives();

    final categories = customPerspectives
        .map((p) => p.category)
        .where((c) => !BuiltinPerspectives.categoryOrder.contains(c))
        .toSet()
        .toList();
    
    categories.sort();
    return categories;
  }

  /// 按分组获取启用的视角
  /// 
  /// 返回：内置视角全部显示 + 启用的自定义视角
  Future<Map<String, List<PerspectiveEntity>>> getEnabledPerspectivesGrouped() async {
    final allPerspectives = await getAllPerspectives();

    final grouped = <String, List<PerspectiveEntity>>{};

    for (final p in allPerspectives) {
      // 内置视角始终显示，自定义视角需要启用
      if (p.isBuiltin || p.isEnabled) {
        grouped.putIfAbsent(p.category, () => []).add(p);
      }
    }

    return grouped;
  }

  /// 获取所有视角按分组组织（用于设置页面）
  Future<Map<String, List<PerspectiveEntity>>> getAllPerspectivesGrouped() async {
    final perspectives = await getAllPerspectives();
    final grouped = <String, List<PerspectiveEntity>>{};

    for (final p in perspectives) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return grouped;
  }

  // ============ 数据查询 ============

  /// 获取助手列表
  Future<List<Map<String, String>>> getAssistantList() async {
    if (_assistantListCache != null) {
      return _assistantListCache!;
    }
    final list = await _store.getAssistantList();
    _assistantListCache = list;
    _assistantIdToNameCache = {
      for (final a in list) (a['id'] ?? ''): (a['name'] ?? ''),
    }..removeWhere((k, v) => k.isEmpty || v.isEmpty);

    return _assistantListCache!;
  }

  /// 获取助手统计信息（话题数、消息数、最后更新时间）
  Future<List<AssistantStats>> getAssistantStats() async {
    await _ensureDataLoaded();
    
    final assistantList = await getAssistantList();
    final statsMap = <String, AssistantStats>{};
    
    // 初始化所有助手的统计
    for (final a in assistantList) {
      final name = a['name'] ?? '';
      final id = a['id'] ?? '';
      if (name.isNotEmpty) {
        statsMap[name] = AssistantStats(
          id: id,
          name: name,
          topicCount: 0,
          messageCount: 0,
          latestTime: null,
        );
      }
    }
    
    // 从缓存中统计
    if (_allTopicGroupsCache != null) {
      for (final tg in _allTopicGroupsCache!) {
        for (int i = 0; i < tg.assistantNames.length; i++) {
          final name = tg.assistantNames[i];
          final current = statsMap[name];
          if (current != null) {
            DateTime? newLatest = current.latestTime;
            if (newLatest == null || tg.latestTime.isAfter(newLatest)) {
              newLatest = tg.latestTime;
            }
            statsMap[name] = AssistantStats(
              id: current.id,
              name: current.name,
              topicCount: current.topicCount + 1,
              messageCount: current.messageCount + tg.roundCount,
              latestTime: newLatest,
            );
          }
        }
      }
    }
    
    // 按话题数降序排序
    final result = statsMap.values.toList()
      ..sort((a, b) => b.topicCount.compareTo(a.topicCount));
    
    return result;
  }

  /// 预加载全部话题数据（首次调用时执行）
  Future<void> _ensureDataLoaded() async {
    if (_allTopicGroupsCache != null || _isPreloading) return;

    _isPreloading = true;
    final sw = Stopwatch()..start();
    debugPrint('⏳ 开始预加载话题数据...');

    try {
      final result = await _store.preloadTopicGroups();
      _assistantListCache = result.assistantList;
      _assistantIdToNameCache = result.assistantIdToName;
      _allTopicGroupsCache = result.topicGroups;
      debugPrint('✅ 预加载完成: ${result.topicGroups.length} 个话题, ${sw.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ 预加载失败: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// 按月份分组获取提问（内存筛选，快速响应）
  ///
  /// [assistantFilters] 是助手**名称**集合（不是ID）
  Future<List<MonthGroup>> getQueriesGroupedByMonth({
    Set<String>? assistantFilters,
  }) async {
    // 确保数据已加载
    await _ensureDataLoaded();

    if (_allTopicGroupsCache == null) {
      return [];
    }

    // 内存筛选（快速）
    List<TopicGroup> filteredGroups;
    if (assistantFilters != null && assistantFilters.isNotEmpty) {
      filteredGroups = _allTopicGroupsCache!
          .where((tg) => tg.assistantNames.any((n) => assistantFilters.contains(n)))
          .toList();
    } else {
      filteredGroups = _allTopicGroupsCache!;
    }

    // 按月份分组
    return _groupByMonth(filteredGroups);
  }

  /// 将话题列表按月份分组
  List<MonthGroup> _groupByMonth(List<TopicGroup> topicGroups) {
    final monthMap = <String, List<TopicGroup>>{};
    final monthLabels = <String, String>{};

    for (final tg in topicGroups) {
      final sortKey = _formatMonthSortKey(tg.latestTime);
      final label = _formatMonthLabel(tg.latestTime);
      monthMap.putIfAbsent(sortKey, () => []).add(tg);
      monthLabels[sortKey] = label;
    }

    final sortedKeys = monthMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((sortKey) {
      final groups = monthMap[sortKey]!;
      // 按最新消息时间倒序排列
      groups.sort((a, b) => b.latestTime.compareTo(a.latestTime));
      return MonthGroup(
        label: monthLabels[sortKey]!,
        topicGroups: groups,
      );
    }).toList();
  }

  String _formatMonthLabel(DateTime date) {
    return '${date.year}年${date.month}月';
  }

  /// 生成可排序的月份 key（零填充月份）
  String _formatMonthSortKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';  // "2025-01", "2025-12"
  }

  // ============ 洞察生成 ============

  /// 流式生成洞察
  Stream<String> generateInsightStream({
    required String perspectiveId,
    required List<QueryItem> selectedQueries,
    required String assistantFilter,
    required String timeRangeLabel,
  }) async* {
    // 1. 获取视角
    final perspective = await _store.getPerspective(perspectiveId);
    if (perspective == null) {
      yield '❌ 未找到视角';
      return;
    }

    // 2. 构建提问列表文本
    final queriesText = StringBuffer();
    for (int i = 0; i < selectedQueries.length; i++) {
      final q = selectedQueries[i];
      queriesText.writeln('${i + 1}. [${_formatDate(q.timestamp)}] ${q.preview}');
    }

    // 3. 替换 Prompt 模板
    final prompt = perspective.promptTemplate.replaceAll(
      '{queries}',
      queriesText.toString(),
    );

    // 4. 获取 AI 配置并调用
    final config = AIProviderService.instance.getActiveConfig();
    if (config == null) {
      yield '❌ 未配置 AI Provider，请先在设置中配置';
      return;
    }

    final service = OpenAIService(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
    );

    final contentBuffer = StringBuffer();

    try {
      await for (final chunk in service.streamChatCompletion(
        model: config.modelId,
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      )) {
        contentBuffer.write(chunk);
        yield chunk;
      }
    } catch (e) {
      yield '\n\n❌ 生成失败: $e';
      return;
    }

    // 5. 保存洞察记录
    final insight = InsightEntity.create(
      perspectiveId: perspectiveId,
      perspectiveName: perspective.name,
      perspectiveIcon: perspective.icon,
      content: contentBuffer.toString(),
      queryCount: selectedQueries.length,
      charCount: selectedQueries.fold(0, (sum, q) => sum + q.charCount),
      assistantFilter: assistantFilter,
      timeRangeLabel: timeRangeLabel,
    );
    await _store.saveInsight(insight);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  // ============ 洞察历史 ============

  /// 获取所有洞察
  Future<List<InsightEntity>> getAllInsights() async {
    return _store.getAllInsights();
  }

  /// 删除洞察
  Future<void> deleteInsight(String insightId) async {
    await _store.deleteInsight(insightId);
  }

  /// 监听洞察变化
  Stream<List<InsightEntity>> watchInsights() {
    return _store.watchInsights();
  }

  // ============ 缓存管理 ============

  /// 失效缓存
  void invalidateCache() {
    _assistantListCache = null;
    _assistantIdToNameCache = null;
    _allTopicGroupsCache = null;
    debugPrint('🔄 InsightService 缓存已失效');
  }

  /// 预加载查询数据
  Future<void> preloadQueries() async {
    await _ensureDataLoaded();
  }

  /// 获取全部助手名称集合
  Set<String> getAllAssistantNames() {
    return _assistantListCache
        ?.map((a) => a['name'] ?? '')
        .where((n) => n.isNotEmpty)
        .toSet() ?? {};
  }
}
