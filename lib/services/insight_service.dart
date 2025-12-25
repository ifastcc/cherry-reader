import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'isar_database.dart';
import 'ai_provider_service.dart';
import 'openai_service.dart';
import 'perspective_storage.dart';
import '../models/isar/perspective_entity.dart';
import '../models/isar/insight_entity.dart';
import '../models/isar/topic_entity.dart';
import '../models/isar/assistant_entity.dart';
import '../models/isar/message_entity.dart';
import '../models/isar/message_block_entity.dart';

/// 提问项（选中的单个提问）
class QueryItem {
  final String topicId;
  final String topicName;
  final String messageId;
  final String preview;
  final int charCount;
  final DateTime timestamp;

  QueryItem({
    required this.topicId,
    required this.topicName,
    required this.messageId,
    required this.preview,
    required this.charCount,
    required this.timestamp,
  });
}

/// 话题分组
class TopicGroup {
  final String topicId;
  final String topicName;
  final String assistantId;
  final String assistantName;
  final List<QueryItem> queries;
  final int totalCharCount;
  final int roundCount;
  final DateTime latestTime;

  TopicGroup({
    required this.topicId,
    required this.topicName,
    required this.assistantId,
    required this.assistantName,
    required this.queries,
    required this.totalCharCount,
    required this.roundCount,
    required this.latestTime,
  });
}

/// 月份分组
class MonthGroup {
  final String label;
  final List<TopicGroup> topicGroups;

  MonthGroup({
    required this.label,
    required this.topicGroups,
  });
}

/// AI 洞察服务
///
/// 提供视角管理、数据查询、洞察生成等功能
class InsightService {
  // 单例模式
  InsightService._();
  static final InsightService instance = InsightService._();

  final _db = IsarDatabase();
  bool _initialized = false;

  // 缓存
  List<Map<String, String>>? _assistantListCache;
  Map<String, String>? _assistantIdToNameCache;  // ID -> Name 映射
  List<TopicGroup>? _allTopicGroupsCache;  // 全量话题缓存（预加载）
  bool _isPreloading = false;

  /// 初始化服务
  Future<void> init() async {
    if (_initialized) return;

    // 确保内置视角存在
    await _db.initBuiltinPerspectives();
    _initialized = true;
  }

  // ============ 视角管理 ============

  /// 获取所有视角
  Future<List<PerspectiveEntity>> getAllPerspectives() async {
    final isar = await _db.instance;
    return isar.perspectiveEntitys.where().sortBySortOrder().findAll();
  }

  /// 获取启用的视角
  Future<List<PerspectiveEntity>> getEnabledPerspectives() async {
    final isar = await _db.instance;
    return isar.perspectiveEntitys
        .filter()
        .isEnabledEqualTo(true)
        .sortBySortOrder()
        .findAll();
  }

  /// 切换视角启用状态
  Future<void> togglePerspectiveEnabled(String perspectiveId, bool isEnabled) async {
    final isar = await _db.instance;
    final perspective = await isar.perspectiveEntitys
        .filter()
        .perspectiveIdEqualTo(perspectiveId)
        .findFirst();

    if (perspective == null) return;

    perspective.isEnabled = isEnabled;
    perspective.updatedAt = DateTime.now().millisecondsSinceEpoch;

    await isar.writeTxn(() async {
      await isar.perspectiveEntitys.put(perspective);
    });
  }

  /// 添加自定义视角
  Future<void> addCustomPerspective(PerspectiveEntity perspective) async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.perspectiveEntitys.put(perspective);
    });
  }

  /// 更新自定义视角
  Future<void> updateCustomPerspective(PerspectiveEntity perspective) async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.perspectiveEntitys.put(perspective);
    });
  }

  /// 删除自定义视角（不允许删除内置视角）
  Future<bool> deleteCustomPerspective(String perspectiveId) async {
    final isar = await _db.instance;
    final perspective = await isar.perspectiveEntitys
        .filter()
        .perspectiveIdEqualTo(perspectiveId)
        .findFirst();

    if (perspective == null || perspective.isBuiltin) {
      return false;
    }

    await isar.writeTxn(() async {
      await isar.perspectiveEntitys
          .filter()
          .perspectiveIdEqualTo(perspectiveId)
          .deleteFirst();
    });

    return true;
  }

  /// 强制重置内置视角
  Future<void> forceResetBuiltinPerspectives() async {
    final isar = await _db.instance;

    // 删除所有内置视角
    await isar.writeTxn(() async {
      await isar.perspectiveEntitys
          .filter()
          .isBuiltinEqualTo(true)
          .deleteAll();
    });

    // 重新插入
    final builtins = BuiltinPerspectives.getAll();
    await isar.writeTxn(() async {
      await isar.perspectiveEntitys.putAll(builtins);
    });

    debugPrint('✅ 已强制重置 ${builtins.length} 个内置视角');
  }

  // ============ 数据查询 ============

  /// 获取助手列表
  Future<List<Map<String, String>>> getAssistantList() async {
    if (_assistantListCache != null) {
      return _assistantListCache!;
    }

    final isar = await _db.importInstance;
    final assistants = await isar.assistantEntitys
        .where()
        .sortByName()
        .findAll();

    _assistantListCache = assistants.map((a) => {
      'id': a.assistantId,
      'name': a.name,
    }).toList();

    return _assistantListCache!;
  }

  /// 预加载全部话题数据（首次调用时执行）
  Future<void> _ensureDataLoaded() async {
    if (_allTopicGroupsCache != null || _isPreloading) return;

    _isPreloading = true;
    final sw = Stopwatch()..start();
    debugPrint('⏳ 开始预加载话题数据...');

    try {
      final isar = await _db.importInstance;

      // 1. 加载助手列表并建立 ID->Name 映射
      final assistants = await isar.assistantEntitys.where().findAll();
      _assistantIdToNameCache = {
        for (final a in assistants) a.assistantId: a.name,
      };
      _assistantListCache = assistants.map((a) => {
        'id': a.assistantId,
        'name': a.name,
      }).toList();

      // 2. 加载全部话题
      final topics = await isar.topicEntitys
          .where()
          .sortByUpdatedAtDesc()
          .findAll();

      // 3. 批量加载全部用户消息
      final messages = await isar.messageEntitys
          .filter()
          .roleEqualTo('user')
          .sortByCreatedAt()
          .findAll();

      // 4. 批量加载全部 main_text 消息块
      final blocks = await isar.messageBlockEntitys
          .filter()
          .typeEqualTo('main_text')
          .findAll();

      // 5. 构建消息块索引 messageId -> content
      final blockContentMap = <String, String>{};
      for (final block in blocks) {
        // 只保留第一个 main_text 块的内容
        blockContentMap.putIfAbsent(block.messageId, () => block.content ?? '');
      }

      // 6. 按话题分组消息
      final messagesByTopic = <String, List<MessageEntity>>{};
      for (final msg in messages) {
        messagesByTopic.putIfAbsent(msg.topicId, () => []).add(msg);
      }

      // 7. 构建 TopicGroup 列表
      final topicGroups = <TopicGroup>[];
      for (final topic in topics) {
        final topicMessages = messagesByTopic[topic.topicId] ?? [];
        if (topicMessages.isEmpty) continue;

        final queries = <QueryItem>[];
        int totalChars = 0;

        for (final msg in topicMessages) {
          final content = blockContentMap[msg.messageId] ?? '';
          final preview = content.length > 100
              ? '${content.substring(0, 100)}...'
              : content;

          totalChars += content.length;

          queries.add(QueryItem(
            topicId: topic.topicId,
            topicName: topic.name,
            messageId: msg.messageId,
            preview: preview,
            charCount: content.length,
            timestamp: DateTime.fromMillisecondsSinceEpoch(msg.createdAt),
          ));
        }

        if (queries.isNotEmpty) {
          final assistantName = _assistantIdToNameCache?[topic.assistantId] ?? '未知助手';
          topicGroups.add(TopicGroup(
            topicId: topic.topicId,
            topicName: topic.name,
            assistantId: topic.assistantId,
            assistantName: assistantName,
            queries: queries,
            totalCharCount: totalChars,
            roundCount: queries.length,
            latestTime: queries.last.timestamp,
          ));
        }
      }

      _allTopicGroupsCache = topicGroups;
      debugPrint('✅ 预加载完成: ${topicGroups.length} 个话题, ${sw.elapsedMilliseconds}ms');
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
          .where((tg) => assistantFilters.contains(tg.assistantName))
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
    final isar = await _db.instance;
    final perspective = await isar.perspectiveEntitys
        .filter()
        .perspectiveIdEqualTo(perspectiveId)
        .findFirst();

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

    await isar.writeTxn(() async {
      await isar.insightEntitys.put(insight);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  // ============ 洞察历史 ============

  /// 获取所有洞察
  Future<List<InsightEntity>> getAllInsights() async {
    final isar = await _db.instance;
    return isar.insightEntitys.where().sortByCreatedAtDesc().findAll();
  }

  /// 删除洞察
  Future<void> deleteInsight(String insightId) async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.insightEntitys
          .filter()
          .insightIdEqualTo(insightId)
          .deleteFirst();
    });
  }

  /// 监听洞察变化
  Stream<List<InsightEntity>> watchInsights() {
    return _db.instanceSync.insightEntitys
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
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
