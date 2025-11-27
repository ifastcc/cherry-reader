import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar/highlight_entity.dart';
import '../models/isar/topic_cache_entity.dart';
import '../models/isar/ai_analysis_entity.dart';
import '../models/isar/discussion_entity.dart';
import '../models/isar/discussion_message_entity.dart';

/// Isar 数据库管理器（单例模式）
///
/// 统一管理所有 Isar 数据库操作：
/// - 标注数据（HighlightEntity）
/// - 话题缓存（TopicCacheEntity）
/// - AI 分析缓存（AIAnalysisEntity）
///
/// 优势：
/// - 单例模式保证全局唯一数据库实例
/// - 延迟初始化，按需开启
/// - 提供类型安全的查询接口
class IsarDatabase {
  static final IsarDatabase _instance = IsarDatabase._internal();
  factory IsarDatabase() => _instance;
  IsarDatabase._internal();

  Isar? _isar;
  bool _initialized = false;

  /// 获取 Isar 实例
  Future<Isar> get instance async {
    if (!_initialized) {
      await init();
    }
    return _isar!;
  }

  /// 同步获取实例（仅在确认已初始化后使用）
  Isar get instanceSync {
    if (!_initialized || _isar == null) {
      throw StateError('IsarDatabase not initialized. Call init() first.');
    }
    return _isar!;
  }

  /// 初始化数据库
  Future<void> init() async {
    if (_initialized && _isar != null) {
      return; // 已初始化，直接返回
    }

    try {
      final dir = await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        [
          HighlightEntitySchema,
          TopicCacheEntitySchema,
          AIAnalysisEntitySchema,
          DiscussionEntitySchema,
          DiscussionMessageEntitySchema,
        ],
        directory: dir.path,
        name: 'cherry_viewer', // 数据库名称
        inspector: true, // 启用 Isar Inspector（调试工具）
      );

      _initialized = true;
      print('✅ Isar 数据库初始化成功: ${dir.path}/cherry_viewer.isar');
    } catch (e) {
      print('❌ Isar 数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 关闭数据库（应用退出时调用）
  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _initialized = false;
      print('🔒 Isar 数据库已关闭');
    }
  }

  // ============ 标注相关操作 ============

  /// 批量加载指定消息的标注
  Future<Map<String, List<HighlightEntity>>> batchLoadHighlights(
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return {};

    final isar = await instance;
    final highlights = await isar.highlightEntitys
        .filter()
        .anyOf(messageIds, (q, messageId) => q.messageIdEqualTo(messageId))
        .findAll();

    // 按 messageId 分组
    final grouped = <String, List<HighlightEntity>>{};
    for (final h in highlights) {
      grouped.putIfAbsent(h.messageId, () => []).add(h);
    }

    return grouped;
  }

  /// 加载单个消息的标注
  Future<List<HighlightEntity>> loadHighlights(String messageId) async {
    if (messageId.isEmpty) return [];

    final isar = await instance;
    return isar.highlightEntitys
        .filter()
        .messageIdEqualTo(messageId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 保存标注
  Future<void> saveHighlight(HighlightEntity highlight) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.highlightEntitys.put(highlight);
    });
  }

  /// 批量保存标注
  Future<void> saveHighlights(List<HighlightEntity> highlights) async {
    if (highlights.isEmpty) return;

    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.highlightEntitys.putAll(highlights);
    });
  }

  /// 删除标注
  Future<void> deleteHighlight(String highlightId) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.highlightEntitys
          .filter()
          .highlightIdEqualTo(highlightId)
          .deleteFirst();
    });
  }

  /// 清除指定消息的所有标注
  Future<void> clearHighlights(String messageId) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.highlightEntitys
          .filter()
          .messageIdEqualTo(messageId)
          .deleteAll();
    });
  }

  /// 监听指定消息的标注变化（实时更新）
  Stream<List<HighlightEntity>> watchHighlights(String messageId) {
    return instanceSync.highlightEntitys
        .filter()
        .messageIdEqualTo(messageId)
        .watch(fireImmediately: true);
  }

  // ============ 话题缓存相关操作 ============

  /// 保存话题缓存
  Future<void> saveTopicCache(TopicCacheEntity topic) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.topicCacheEntitys.put(topic);
    });
  }

  /// 批量保存话题缓存
  Future<void> saveTopicCaches(List<TopicCacheEntity> topics) async {
    if (topics.isEmpty) return;

    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.topicCacheEntitys.putAll(topics);
    });
  }

  /// 获取话题缓存
  Future<TopicCacheEntity?> getTopicCache(String topicId) async {
    final isar = await instance;
    return isar.topicCacheEntitys.filter().topicIdEqualTo(topicId).findFirst();
  }

  /// 获取指定 Assistant 的所有话题
  Future<List<TopicCacheEntity>> getTopicsByAssistant(
    String assistantId,
  ) async {
    final isar = await instance;
    return isar.topicCacheEntitys
        .filter()
        .assistantIdEqualTo(assistantId)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 获取所有话题（按 Assistant 分组）
  Future<Map<String, List<TopicCacheEntity>>> getAllTopicsGrouped() async {
    final isar = await instance;
    final allTopics = await isar.topicCacheEntitys.where().findAll();

    final grouped = <String, List<TopicCacheEntity>>{};
    for (final topic in allTopics) {
      grouped.putIfAbsent(topic.assistantId, () => []).add(topic);
    }

    return grouped;
  }

  /// 清空话题缓存（重新加载数据时使用）
  Future<void> clearTopicCaches() async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.topicCacheEntitys.clear();
    });
  }

  // ============ AI 分析缓存相关操作 ============

  /// 保存 AI 分析
  Future<void> saveAnalysis(AIAnalysisEntity analysis) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.aIAnalysisEntitys.put(analysis);
    });
  }

  /// 获取指定话题的所有分析
  Future<List<AIAnalysisEntity>> getAnalyses(String topicId) async {
    final isar = await instance;
    return isar.aIAnalysisEntitys
        .filter()
        .topicIdEqualTo(topicId)
        .sortByGroupIndex()
        .findAll();
  }

  /// 获取指定话题、指定分组的分析
  Future<List<AIAnalysisEntity>> getAnalysisForGroup(
    String topicId,
    int groupIndex,
  ) async {
    final isar = await instance;
    return isar.aIAnalysisEntitys
        .filter()
        .topicIdEqualTo(topicId)
        .groupIndexEqualTo(groupIndex)
        .findAll();
  }

  /// 删除指定话题的所有分析
  Future<void> clearAnalyses(String topicId) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.aIAnalysisEntitys.filter().topicIdEqualTo(topicId).deleteAll();
    });
  }

  /// 删除指定的单个分析
  ///
  /// 参数:
  /// - topicId: 话题ID
  /// - groupIndex: 分组索引
  /// - analysisIndex: 该分组内的分析索引（从0开始）
  Future<void> deleteAnalysisAt(
    String topicId,
    int groupIndex,
    int analysisIndex,
  ) async {
    final isar = await instance;

    // 获取该分组的所有分析
    final analyses = await getAnalysisForGroup(topicId, groupIndex);

    // 检查索引是否有效
    if (analysisIndex < 0 || analysisIndex >= analyses.length) {
      print('⚠️  分析索引无效: $analysisIndex（总数: ${analyses.length}）');
      return;
    }

    // 删除指定索引的分析
    final targetAnalysis = analyses[analysisIndex];
    await isar.writeTxn(() async {
      await isar.aIAnalysisEntitys.delete(targetAnalysis.id);
    });

    print(
      '✅ 已删除分析: topicId=$topicId, groupIndex=$groupIndex, index=$analysisIndex',
    );
  }

  // ============ 数据统计和维护 ============

  /// 获取数据库统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    final isar = await instance;

    final highlightCount = await isar.highlightEntitys.count();
    final topicCount = await isar.topicCacheEntitys.count();
    final analysisCount = await isar.aIAnalysisEntitys.count();

    final dbSize = await isar.getSize(includeIndexes: true);

    return {
      'highlights': highlightCount,
      'topics': topicCount,
      'analyses': analysisCount,
      'database_size_mb': (dbSize / 1024 / 1024).toStringAsFixed(2),
    };
  }

  /// 获取所有 AI 分析（用于统计）
  Future<List<AIAnalysisEntity>> getAllAnalyses() async {
    final isar = await instance;
    return isar.aIAnalysisEntitys.where().findAll();
  }

  /// 清空所有数据（重置应用时使用）
  Future<void> clearAll() async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.clear();
    });
    print('🗑️  已清空所有数据库数据');
  }

  /// 压缩数据库（释放空间）
  Future<void> compact() async {
    // Isar 会自动管理压缩，通常不需要手动调用
    // 如果需要立即释放空间，可以先 close 再重新 open
    await close();
    await init();
    print('✅ 数据库压缩完成');
  }

  // ============ 讨论相关操作 ============

  /// 保存讨论线程
  Future<void> saveDiscussion(DiscussionEntity discussion) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.discussionEntitys.put(discussion);
    });
  }

  /// 获取指定AI回复的所有讨论
  Future<List<DiscussionEntity>> getDiscussions(String messageId) async {
    final isar = await instance;
    return isar.discussionEntitys
        .filter()
        .messageIdEqualTo(messageId)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 获取单个讨论
  Future<DiscussionEntity?> getDiscussion(String discussionId) async {
    final isar = await instance;
    return isar.discussionEntitys
        .filter()
        .discussionIdEqualTo(discussionId)
        .findFirst();
  }

  /// 更新讨论的消息计数和更新时间
  Future<void> updateDiscussion(
    String discussionId,
    int messageCount,
  ) async {
    final isar = await instance;
    final discussion = await getDiscussion(discussionId);
    if (discussion != null) {
      discussion.messageCount = messageCount;
      discussion.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await isar.writeTxn(() async {
        await isar.discussionEntitys.put(discussion);
      });
    }
  }

  /// 删除讨论（同时删除所有相关消息）
  Future<void> deleteDiscussion(String discussionId) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      // 删除讨论线程
      await isar.discussionEntitys
          .filter()
          .discussionIdEqualTo(discussionId)
          .deleteAll();
      // 删除所有相关消息
      await isar.discussionMessageEntitys
          .filter()
          .discussionIdEqualTo(discussionId)
          .deleteAll();
    });
  }

  /// 保存讨论消息
  Future<void> saveDiscussionMessage(DiscussionMessageEntity message) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.discussionMessageEntitys.put(message);
    });
  }

  /// 批量保存讨论消息
  Future<void> saveDiscussionMessages(
    List<DiscussionMessageEntity> messages,
  ) async {
    if (messages.isEmpty) return;

    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.discussionMessageEntitys.putAll(messages);
    });
  }

  /// 获取讨论的所有消息
  Future<List<DiscussionMessageEntity>> getDiscussionMessages(
    String discussionId,
  ) async {
    final isar = await instance;
    return isar.discussionMessageEntitys
        .filter()
        .discussionIdEqualTo(discussionId)
        .sortByCreatedAt()
        .findAll();
  }

  /// 监听讨论消息变化（实时更新）
  Stream<List<DiscussionMessageEntity>> watchDiscussionMessages(
    String discussionId,
  ) {
    return instanceSync.discussionMessageEntitys
        .filter()
        .discussionIdEqualTo(discussionId)
        .watch(fireImmediately: true);
  }
}
