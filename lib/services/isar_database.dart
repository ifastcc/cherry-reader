import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar/highlight_entity.dart';
import '../models/isar/ai_analysis_entity.dart';
import '../models/isar/discussion_entity.dart';
import '../models/isar/discussion_message_entity.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../models/isar/prompt_template_entity.dart';
import '../models/isar/version_entity.dart';
import '../models/isar/insight_entity.dart';
import '../models/isar/perspective_entity.dart';
import '../models/isar/note_entity.dart';
import 'perspective_storage.dart';
// 新架构：消息级存储
import '../models/isar/assistant_entity.dart';
import '../models/isar/topic_entity.dart';
import '../models/isar/message_entity.dart';
import '../models/isar/message_block_entity.dart';
import '../models/isar/file_entity.dart';
import 'version_service.dart';

/// Isar 数据库管理器（单例模式）
///
/// 统一管理所有 Isar 数据库操作：
/// - 主数据库：用户数据（标注、分析、讨论）、版本元数据
/// - 版本数据库：导入的 Cherry Studio 数据（通过 VersionService 管理）
///
/// 架构说明：
/// - 用户数据始终存在主数据库中
/// - 导入数据（Topics, Messages, Blocks）优先从版本数据库读取
/// - 如果没有版本数据库，fallback 到主数据库（兼容旧数据）
class IsarDatabase {
  static final IsarDatabase _instance = IsarDatabase._internal();
  factory IsarDatabase() => _instance;
  IsarDatabase._internal();

  Isar? _isar;
  bool _initialized = false;

  /// 获取主数据库 Isar 实例（用户数据）
  Future<Isar> get instance async {
    if (!_initialized) {
      await init();
    }
    return _isar!;
  }

  /// 同步获取主数据库实例（仅在确认已初始化后使用）
  Isar get instanceSync {
    if (!_initialized || _isar == null) {
      throw StateError('IsarDatabase not initialized. Call init() first.');
    }
    return _isar!;
  }

  /// 获取导入数据的 Isar 实例
  ///
  /// 优先返回 VersionService 的活跃版本数据库
  /// 如果没有版本数据库，fallback 到主数据库（兼容旧数据）
  Future<Isar> get importInstance async {
    // 优先使用版本数据库
    final versionIsar = VersionService.instance.activeImportIsar;
    if (versionIsar != null && versionIsar.isOpen) {
      return versionIsar;
    }

    // fallback 到主数据库
    return instance;
  }

  /// 同步获取导入数据实例
  Isar get importInstanceSync {
    final versionIsar = VersionService.instance.activeImportIsar;
    if (versionIsar != null && versionIsar.isOpen) {
      return versionIsar;
    }
    return instanceSync;
  }

  /// 是否有版本化的导入数据
  bool get hasVersionedImport => VersionService.instance.hasActiveVersion;

  /// 初始化数据库
  Future<void> init() async {
    if (_initialized && _isar != null) {
      return; // 已初始化，直接返回
    }

    try {
      final dir = await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        [
          // 基础功能
          HighlightEntitySchema,
          AIAnalysisEntitySchema,
          DiscussionEntitySchema,
          DiscussionMessageEntitySchema,
          UnifiedConversationEntitySchema,
          UnifiedMessageEntitySchema,
          UserPreferenceEntitySchema,
          TaskTemplateEntitySchema,
          // 洞察功能
          InsightEntitySchema,
          PerspectiveEntitySchema,
          // 笔记功能
          NoteEntitySchema,
          // 版本管理
          VersionEntitySchema,
          // 消息级存储
          AssistantEntitySchema,
          TopicEntitySchema,
          MessageEntitySchema,
          MessageBlockEntitySchema,
          FileEntitySchema,
        ],
        directory: dir.path,
        name: 'cherry_viewer',
        inspector: kDebugMode, // 仅在调试模式启用 Isar Inspector
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
    final topicCount = await isar.topicEntitys.count();
    final messageCount = await isar.messageEntitys.count();
    final analysisCount = await isar.aIAnalysisEntitys.count();

    final dbSize = await isar.getSize(includeIndexes: true);

    return {
      'highlights': highlightCount,
      'topics': topicCount,
      'messages': messageCount,
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

  /// 清空导入的数据（保留用户数据如标注、分析等）
  Future<void> clearImportedData() async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.assistantEntitys.clear();
      await isar.topicEntitys.clear();
      await isar.messageEntitys.clear();
      await isar.messageBlockEntitys.clear();
      await isar.fileEntitys.clear();
    });
    print('🗑️  已清空导入的数据');
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

  // ============ 统一对话相关操作 ============

  /// 保存统一对话
  Future<void> saveUnifiedConversation(UnifiedConversationEntity conv) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.unifiedConversationEntitys.put(conv);
    });
  }

  /// 获取统一对话列表
  Future<List<UnifiedConversationEntity>> getUnifiedConversations({
    ConversationContextType? contextType,
    bool includeArchived = false,
  }) async {
    final isar = await instance;

    // 根据条件构建查询
    if (contextType != null && !includeArchived) {
      return isar.unifiedConversationEntitys
          .filter()
          .isArchivedEqualTo(false)
          .contextTypeEqualTo(contextType)
          .sortByCreatedAtDesc()
          .findAll();
    } else if (contextType != null) {
      return isar.unifiedConversationEntitys
          .filter()
          .contextTypeEqualTo(contextType)
          .sortByCreatedAtDesc()
          .findAll();
    } else if (!includeArchived) {
      return isar.unifiedConversationEntitys
          .filter()
          .isArchivedEqualTo(false)
          .sortByCreatedAtDesc()
          .findAll();
    } else {
      return isar.unifiedConversationEntitys
          .where()
          .sortByCreatedAtDesc()
          .findAll();
    }
  }

  /// 根据上下文 ID 获取对话列表
  Future<List<UnifiedConversationEntity>> getUnifiedConversationsByContextId(
    String contextId,
  ) async {
    final isar = await instance;
    return isar.unifiedConversationEntitys
        .filter()
        .contextIdEqualTo(contextId)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 根据话题 ID 前缀获取所有相关对话
  ///
  /// contextId 格式：topicId:groupIndex 或 messageId
  /// 通过前缀匹配获取同一话题下所有轮次的讨论
  Future<List<UnifiedConversationEntity>> getUnifiedConversationsByTopicPrefix(
    String topicId,
  ) async {
    final isar = await instance;
    return isar.unifiedConversationEntitys
        .filter()
        .contextIdStartsWith('$topicId:')
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 获取单个统一对话
  Future<UnifiedConversationEntity?> getUnifiedConversation(
    String conversationId,
  ) async {
    final isar = await instance;
    return isar.unifiedConversationEntitys
        .filter()
        .conversationIdEqualTo(conversationId)
        .findFirst();
  }

  /// 删除统一对话（包括所有消息）
  Future<void> deleteUnifiedConversation(String conversationId) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      // 删除对话
      await isar.unifiedConversationEntitys
          .filter()
          .conversationIdEqualTo(conversationId)
          .deleteAll();
      // 删除所有相关消息
      await isar.unifiedMessageEntitys
          .filter()
          .conversationIdEqualTo(conversationId)
          .deleteAll();
    });
  }

  /// 保存统一消息
  Future<void> saveUnifiedMessage(UnifiedMessageEntity message) async {
    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.unifiedMessageEntitys.put(message);
    });
  }

  /// 批量保存统一消息
  Future<void> saveUnifiedMessages(List<UnifiedMessageEntity> messages) async {
    if (messages.isEmpty) return;

    final isar = await instance;
    await isar.writeTxn(() async {
      await isar.unifiedMessageEntitys.putAll(messages);
    });
  }

  /// 获取统一消息
  Future<UnifiedMessageEntity?> getUnifiedMessage(String messageId) async {
    final isar = await instance;
    return isar.unifiedMessageEntitys
        .filter()
        .messageIdEqualTo(messageId)
        .findFirst();
  }

  /// 删除统一消息
  Future<bool> deleteUnifiedMessage(String messageId) async {
    final isar = await instance;
    return isar.writeTxn(() async {
      return isar.unifiedMessageEntitys
          .filter()
          .messageIdEqualTo(messageId)
          .deleteFirst();
    });
  }

  /// 获取对话的所有消息
  Future<List<UnifiedMessageEntity>> getUnifiedMessages(
    String conversationId,
  ) async {
    final isar = await instance;
    return isar.unifiedMessageEntitys
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAt()
        .findAll();
  }

  /// 监听统一消息变化
  Stream<List<UnifiedMessageEntity>> watchUnifiedMessages(
    String conversationId,
  ) {
    return instanceSync.unifiedMessageEntitys
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  /// 获取所有独立对话（topic 类型）
  Future<List<UnifiedConversationEntity>> getTopicConversations() async {
    return getUnifiedConversations(contextType: ConversationContextType.topic);
  }

  // ============ 洞察相关操作 ============

  /// 初始化内置视角（确保每个内置视角都存在）
  Future<void> initBuiltinPerspectives() async {
    final isar = await instance;
    final builtins = BuiltinPerspectives.getAll();

    // 获取已存在的内置视角 ID
    final existingIds = <String>{};
    final existingPerspectives = await isar.perspectiveEntitys
        .filter()
        .isBuiltinEqualTo(true)
        .findAll();
    for (final p in existingPerspectives) {
      existingIds.add(p.perspectiveId);
    }

    // 找出缺失的内置视角
    final missing = builtins
        .where((p) => !existingIds.contains(p.perspectiveId))
        .toList();

    if (missing.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.perspectiveEntitys.putAll(missing);
      });
      print('✅ 已补充 ${missing.length} 个缺失的内置视角');
    }

    // 如果完全没有视角数据，说明是全新安装
    if (existingPerspectives.isEmpty && missing.length == builtins.length) {
      print('✅ 已初始化 ${builtins.length} 个内置视角（全新安装）');
    }
  }
}
