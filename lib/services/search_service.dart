import 'package:flutter/foundation.dart';
import '../models/domain/search_hits.dart';
import '../models/domain/search_result_model.dart';
import '../utils/text_cleaner.dart';
import 'app_db.dart';
import 'search/drift_search_store.dart';
import 'search/i_search_store.dart';

/// 搜索服务
///
/// 封装搜索业务逻辑，包括：
/// - 搜索话题名称和消息内容
/// - 结果分组（按时间/按助手）
class SearchService {
  static SearchService? _instance;
  static SearchService get instance => _instance ??= SearchService._();

  SearchService._();

  bool _initialized = false;
  late final ISearchStore _store = DriftSearchStore(AppDb());

  /// 初始化（必须在 RepositoryProvider.init() 之后调用）
  void init() {
    if (_initialized) return;
    _initialized = true;
    debugPrint('✅ SearchService 初始化完成');
  }

  /// 执行综合搜索
  ///
  /// [keyword] 搜索关键词
  /// [viewType] 视图类型（决定分组方式）
  Future<List<SearchResultGroup>> search(
    String keyword, {
    SearchViewType viewType = SearchViewType.time,
  }) async {
    if (keyword.trim().isEmpty) {
      return [];
    }

    final trimmedKeyword = keyword.trim();

    // 并行执行话题搜索和消息搜索
    final results = await Future.wait([
      _searchTopicNames(trimmedKeyword, limit: 20),
      _searchMessageContent(trimmedKeyword, limit: 80),
    ]);

    // 合并结果
    final allResults = [...results[0], ...results[1]];

    if (allResults.isEmpty) {
      return [];
    }

    // 根据视图类型分组
    return viewType == SearchViewType.time
        ? _groupByTime(allResults)
        : _groupByAssistant(allResults);
  }

  /// 仅搜索话题名称
  Future<List<SearchResultModel>> searchTopicsOnly(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    return _searchTopicNames(keyword.trim());
  }

  /// 仅搜索消息内容
  Future<List<SearchResultModel>> searchMessagesOnly(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    return _searchMessageContent(keyword.trim());
  }

  /// 搜索话题名称
  Future<List<SearchResultModel>> _searchTopicNames(
    String keyword, {
    int limit = 50,
  }) async {
    if (!_initialized) {
      throw StateError('SearchService not initialized. Call init() first.');
    }

    final hits = await _store.searchTopicNames(keyword, limit: limit);
    final lowerKeyword = keyword.toLowerCase();

    return hits.map((hit) {
      final lowerName = hit.topicName.toLowerCase();
      final matchIndex = lowerName.indexOf(lowerKeyword);
      return SearchResultModel(
        id: 'topic_${hit.topicId}',
        type: SearchResultType.topic,
        matchSnippet: hit.topicName,
        matchStart: matchIndex >= 0 ? matchIndex : 0,
        matchEnd: matchIndex >= 0 ? matchIndex + keyword.length : 0,
        topicId: hit.topicId,
        topicName: hit.topicName,
        contentPreview: hit.contentPreview,
        assistantIds: hit.assistantIds,
        assistantNames: hit.assistantNames,
        createdAt: hit.createdAt,
      );
    }).toList();
  }

  /// 搜索消息内容
  Future<List<SearchResultModel>> _searchMessageContent(
    String keyword, {
    int limit = 100,
    int snippetLength = 50,
  }) async {
    if (!_initialized) {
      throw StateError('SearchService not initialized. Call init() first.');
    }

    final hits = await _store.searchMessageContent(keyword, limit: limit);
    final results = <SearchResultModel>[];

    for (final hit in hits) {
      // 使用 text_cleaner 生成干净的 snippet
      final snippetResult = generateSearchSnippet(
        content: hit.content,
        keyword: keyword,
        snippetLength: snippetLength,
      );

      // 如果清理后找不到关键词且没有匹配位置，跳过
      if (snippetResult.matchStart == 0 && snippetResult.matchEnd == 0 && snippetResult.snippet.isEmpty) {
        continue;
      }

      results.add(SearchResultModel(
        id: 'block_${hit.blockId}',
        type: SearchResultType.message,
        matchSnippet: snippetResult.snippet,
        matchStart: snippetResult.matchStart,
        matchEnd: snippetResult.matchEnd,
        topicId: hit.topicId,
        topicName: hit.topicName,
        assistantIds: hit.assistantIds,
        assistantNames: hit.assistantNames,
        messageId: hit.messageId,
        role: hit.role,
        modelName: hit.modelName,
        roundIndex: hit.roundIndex,
        createdAt: hit.createdAt,
      ));
    }

    // 按时间倒序排序
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return results;
  }

  /// 按时间分组
  ///
  /// 分组规则：
  /// - 今天
  /// - 昨天
  /// - 本周
  /// - 上周
  /// - 本月
  /// - 上月
  /// - 更早（按月份分组）
  List<SearchResultGroup> _groupByTime(List<SearchResultModel> results) {
    if (results.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(
      now.month > 1 ? now.year : now.year - 1,
      now.month > 1 ? now.month - 1 : 12,
      1,
    );

    final groups = <String, List<SearchResultModel>>{};

    for (final result in results) {
      final date = result.dateTime;
      final dateOnly = DateTime(date.year, date.month, date.day);

      String groupKey;
      if (dateOnly == today) {
        groupKey = 'today';
      } else if (dateOnly == yesterday) {
        groupKey = 'yesterday';
      } else if (dateOnly.isAfter(thisWeekStart.subtract(const Duration(days: 1)))) {
        groupKey = 'this_week';
      } else if (dateOnly.isAfter(lastWeekStart.subtract(const Duration(days: 1)))) {
        groupKey = 'last_week';
      } else if (dateOnly.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) {
        groupKey = 'this_month';
      } else if (dateOnly.isAfter(lastMonthStart.subtract(const Duration(days: 1)))) {
        groupKey = 'last_month';
      } else {
        // 更早的按月份分组
        groupKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      }

      groups.putIfAbsent(groupKey, () => []).add(result);
    }

    // 按预定义顺序排序分组
    final orderedKeys = [
      'today',
      'yesterday',
      'this_week',
      'last_week',
      'this_month',
      'last_month'
    ];
    final sortedGroups = <SearchResultGroup>[];

    for (final key in orderedKeys) {
      if (groups.containsKey(key)) {
        sortedGroups.add(SearchResultGroup(
          groupKey: key,
          groupTitle: _getTimeGroupTitle(key),
          results: groups[key]!,
        ));
        groups.remove(key);
      }
    }

    // 剩余的按月份分组（按时间倒序）
    final monthKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final key in monthKeys) {
      sortedGroups.add(SearchResultGroup(
        groupKey: key,
        groupTitle: _formatMonthTitle(key),
        results: groups[key]!,
      ));
    }

    return sortedGroups;
  }

  /// 按助手分组
  List<SearchResultGroup> _groupByAssistant(List<SearchResultModel> results) {
    if (results.isEmpty) return [];

    final groups = <String, List<SearchResultModel>>{};
    final assistantNames = <String, String>{};

    for (final result in results) {
      for (int i = 0; i < result.assistantIds.length; i++) {
        final id = result.assistantIds[i];
        final name = result.assistantNames[i];
        groups.putIfAbsent(id, () => []).add(result);
        assistantNames[id] = name;
      }
    }

    // 组内按时间倒序排序
    for (final list in groups.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // 按助手名称排序
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) =>
          (assistantNames[a] ?? '').compareTo(assistantNames[b] ?? ''));

    return sortedKeys
        .map((key) => SearchResultGroup(
              groupKey: key,
              groupTitle: assistantNames[key] ?? '未知助手',
              results: groups[key]!,
            ))
        .toList();
  }

  /// 获取时间分组标题
  String _getTimeGroupTitle(String key) {
    switch (key) {
      case 'today':
        return '今天';
      case 'yesterday':
        return '昨天';
      case 'this_week':
        return '本周';
      case 'last_week':
        return '上周';
      case 'this_month':
        return '本月';
      case 'last_month':
        return '上月';
      default:
        return key;
    }
  }

  /// 格式化月份标题
  String _formatMonthTitle(String key) {
    // key 格式: "2024-01"
    final parts = key.split('-');
    if (parts.length == 2) {
      return '${parts[0]}年${int.parse(parts[1])}月';
    }
    return key;
  }
}
