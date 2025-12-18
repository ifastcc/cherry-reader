import 'package:isar_community/isar.dart';
import '../../repository_provider.dart';
import '../../embedding_service.dart';
import '../../isar_database.dart';
import '../../../models/domain/block_model.dart';
import '../../../models/isar/topic_embedding_entity.dart';
import 'mcp_tool_base.dart';

/// 查找相关讨论
///
/// 基于主题词搜索相关的历史话题，支持跨助手搜索
/// 支持语义搜索和关键词搜索
class FindRelatedDiscussionsTool extends MCPTool {
  @override
  String get name => 'search_past_discussions';

  @override
  String get description => '''搜索我以前讨论过的相关话题。

当用户问：之前聊过XX吗、找一下关于XX的讨论、有没有讨论过XX — 用这个工具。

支持语义搜索（默认）和关键词搜索。''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': "想查找的主题，如'人生意义'、'职业规划'",
          },
          'search_mode': {
            'type': 'string',
            'enum': ['semantic', 'keyword'],
            'description': '搜索模式，默认 semantic',
          },
          'search_scope': {
            'type': 'string',
            'enum': ['query_only', 'response_only', 'full'],
            'description': '搜索范围，默认 query_only',
          },
          'min_score': {
            'type': 'number',
            'description': '最小相似度（0-1），仅语义搜索有效，默认 0.5',
          },
          'time_range_days': {
            'type': 'integer',
            'description': '搜索范围（天），0 表示全部，默认 0',
          },
          'min_rounds': {
            'type': 'integer',
            'description': '最小轮次，默认 1',
          },
          'limit': {
            'type': 'integer',
            'description': '返回数量，默认 10',
          },
        },
        'required': ['query'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final query = arguments['query'] as String?;
    if (query == null || query.isEmpty) {
      throw ArgumentError('query is required');
    }

    final searchMode = arguments['search_mode'] as String? ?? 'semantic';
    final searchScope = arguments['search_scope'] as String? ?? 'query_only';
    final minScore = (arguments['min_score'] as num?)?.toDouble() ?? 0.5;
    final timeRangeDays = arguments['time_range_days'] as int? ?? 0;
    final minRounds = arguments['min_rounds'] as int? ?? 1;
    final limit = arguments['limit'] as int? ?? 10;

    // 语义搜索只支持 query_only（因为 embedding 只对首轮问题生成）
    if (searchMode == 'semantic' && searchScope == 'query_only') {
      final semanticResult = await _semanticSearch(
        query: query,
        minScore: minScore,
        timeRangeDays: timeRangeDays,
        minRounds: minRounds,
        limit: limit,
      );

      if (semanticResult != null) {
        return semanticResult;
      }
      // 降级到关键词搜索
    }

    // 关键词搜索
    return _keywordSearch(
      query: query,
      searchScope: searchScope,
      timeRangeDays: timeRangeDays,
      minRounds: minRounds,
      limit: limit,
    );
  }

  /// 语义搜索
  Future<Map<String, dynamic>?> _semanticSearch({
    required String query,
    required double minScore,
    required int timeRangeDays,
    required int minRounds,
    required int limit,
  }) async {
    // 检查 embedding 服务是否可用
    if (!EmbeddingService.instance.isConfigured) {
      return null;
    }

    // 获取 query 的 embedding
    final queryEmbedding = await EmbeddingService.instance.embed(query);
    if (queryEmbedding == null) {
      return null;
    }

    // 获取所有话题的 embedding
    final isar = await IsarDatabase().importInstance;
    var embeddings = await isar.topicEmbeddingEntitys.where().findAll();

    if (embeddings.isEmpty) {
      return null; // 没有 embedding 数据，降级到关键词搜索
    }

    // 获取话题和助手信息
    final topicRepo = RepositoryProvider.instance.topicRepository;
    final messageRepo = RepositoryProvider.instance.messageRepository;

    // 获取所有话题
    var allTopics = await topicRepo.getAllTopics();

    // 按时间过滤
    if (timeRangeDays > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: timeRangeDays));
      allTopics = allTopics.where((t) {
        final updatedAt = DateTime.fromMillisecondsSinceEpoch(t.updatedAt);
        return updatedAt.isAfter(cutoff);
      }).toList();
    }

    // 按轮次过滤
    allTopics = allTopics.where((t) => t.roundCount >= minRounds).toList();

    // 构建 topicId -> Topic 映射
    final topicMap = {for (final t in allTopics) t.topicId: t};

    // 只保留有效话题的 embedding
    embeddings = embeddings.where((e) => topicMap.containsKey(e.topicId)).toList();

    if (embeddings.isEmpty) {
      return null;
    }

    // 计算相似度
    final candidates = embeddings.map((e) => e.embedding).toList();
    final scores = EmbeddingService.searchSimilar(
      queryEmbedding,
      candidates,
      limit: limit,
      minScore: minScore,
    );

    // 构建结果
    final relatedTopics = <Map<String, dynamic>>[];

    for (final (index, score) in scores) {
      final embedding = embeddings[index];
      final topic = topicMap[embedding.topicId];
      if (topic == null) continue;

      // 获取完整的 user_queries
      final userQueries = await _getAllUserQueries(topic.topicId, messageRepo);

      relatedTopics.add({
        'topic_id': topic.topicId,
        'topic_name': topic.name,
        'round_count': topic.roundCount,
        'score': double.parse(score.toStringAsFixed(3)),
        'user_queries': userQueries,
      });
    }

    return {
      'query': query,
      'search_mode': 'semantic',
      'related_topics': relatedTopics,
    };
  }

  /// 关键词搜索
  Future<Map<String, dynamic>> _keywordSearch({
    required String query,
    required String searchScope,
    required int timeRangeDays,
    required int minRounds,
    required int limit,
  }) async {
    final topicRepo = RepositoryProvider.instance.topicRepository;
    final messageRepo = RepositoryProvider.instance.messageRepository;

    // 获取所有话题
    var allTopics = await topicRepo.getAllTopics();

    // 按时间过滤
    if (timeRangeDays > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: timeRangeDays));
      allTopics = allTopics.where((t) {
        final updatedAt = DateTime.fromMillisecondsSinceEpoch(t.updatedAt);
        return updatedAt.isAfter(cutoff);
      }).toList();
    }

    // 按轮次过滤
    allTopics = allTopics.where((t) => t.roundCount >= minRounds).toList();

    // 搜索关键词（支持多个词）
    final keywords =
        query.toLowerCase().split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();

    // 搜索结果
    final results = <_SearchResult>[];

    for (final topic in allTopics) {
      final result = await _searchInTopic(
        topic,
        keywords,
        searchScope,
        messageRepo,
      );
      if (result != null) {
        results.add(result);
      }
    }

    // 按匹配度排序
    results.sort((a, b) => b.score.compareTo(a.score));

    // 限制数量
    final topResults = results.take(limit).toList();

    // 构建返回结果
    final relatedTopics = <Map<String, dynamic>>[];

    for (final r in topResults) {
      // 获取完整的 user_queries
      final userQueries = await _getAllUserQueries(r.topic.topicId, messageRepo);

      relatedTopics.add({
        'topic_id': r.topic.topicId,
        'topic_name': r.topic.name,
        'round_count': r.topic.roundCount,
        'score': null,
        'user_queries': userQueries,
      });
    }

    return {
      'query': query,
      'search_mode': 'keyword',
      'related_topics': relatedTopics,
    };
  }

  /// 在话题中搜索
  Future<_SearchResult?> _searchInTopic(
    topic,
    List<String> keywords,
    String searchScope,
    messageRepo,
  ) async {
    final messages = await messageRepo.loadAllMessages(topic.topicId);

    // 根据搜索范围过滤消息
    List filteredMessages;
    switch (searchScope) {
      case 'query_only':
        filteredMessages = messages.where((m) => m.isUser).toList();
        break;
      case 'response_only':
        filteredMessages = messages.where((m) => m.isAssistant).toList();
        break;
      case 'full':
      default:
        filteredMessages = messages;
        break;
    }

    if (filteredMessages.isEmpty) return null;

    // 获取所有消息的 blocks
    final messageIds = filteredMessages.map((m) => m.messageId).toList();
    final blocksMap = await messageRepo.batchLoadBlocks(messageIds);

    var matchCount = 0;

    for (final msg in filteredMessages) {
      final blocks = blocksMap[msg.messageId] ?? [];
      final content = _extractContent(blocks).toLowerCase();

      for (final keyword in keywords) {
        if (content.contains(keyword)) {
          matchCount++;
        }
      }
    }

    if (matchCount == 0) {
      // 也检查话题名称
      final nameLower = topic.name.toLowerCase();
      final nameMatches = keywords.where((k) => nameLower.contains(k)).length;
      if (nameMatches > 0) {
        matchCount = nameMatches;
      } else {
        return null;
      }
    }

    return _SearchResult(
      topic: topic,
      score: matchCount / keywords.length,
    );
  }

  /// 获取话题的所有用户问题
  Future<List<Map<String, dynamic>>> _getAllUserQueries(
    String topicId,
    messageRepo,
  ) async {
    final messages = await messageRepo.loadAllMessages(topicId);
    final userMessages = messages.where((m) => m.isUser).toList();

    // 按 roundIndex 排序
    userMessages.sort((a, b) => a.roundIndex.compareTo(b.roundIndex));

    // 获取 blocks
    final messageIds = userMessages.map((m) => m.messageId).toList();
    final blocksMap = await messageRepo.batchLoadBlocks(messageIds);

    final userQueries = <Map<String, dynamic>>[];
    for (final msg in userMessages) {
      final blocks = blocksMap[msg.messageId] ?? [];
      final content = _extractContent(blocks);
      if (content.isNotEmpty) {
        userQueries.add({
          'round': msg.roundIndex,
          'query': content,
        });
      }
    }

    return userQueries;
  }

  /// 提取消息内容
  String _extractContent(List<BlockModel> blocks) {
    final buffer = StringBuffer();
    for (final block in blocks) {
      if (block.isMainText && block.content != null) {
        buffer.write(block.content);
      }
    }
    return buffer.toString().trim();
  }
}

/// 搜索结果
class _SearchResult {
  final dynamic topic;
  final double score;

  _SearchResult({
    required this.topic,
    required this.score,
  });
}
