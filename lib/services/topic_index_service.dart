import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/i_topic_repository.dart';
import '../repositories/i_message_repository.dart';
import '../repositories/i_assistant_repository.dart';
import 'repository_provider.dart';

/// 话题索引服务（单例，常驻内存）
///
/// 设计原则：
/// - 第 1-2 层数据（结构 + 元数据 + 预览）常驻内存，~100KB
/// - 第 3 层数据（完整内容）按需从数据库加载
/// - 版本切换时自动重建索引
///
/// 内存估算（50 话题 × 10 轮 × 3 回复）：
/// - 结构索引：~5KB
/// - 轮次元数据 + 预览：~100KB
/// - 总计：<200KB，完全可以常驻
class TopicIndexService {
  TopicIndexService._();
  static final TopicIndexService instance = TopicIndexService._();

  // ========== 状态 ==========
  bool _isInitialized = false;
  bool _isLoading = false;
  DateTime? _lastBuildTime;

  // ========== 常驻数据（第 1-2 层）==========
  final Map<String, AssistantInfo> _assistants = {};
  final Map<String, TopicInfo> _topics = {};

  // ========== 按需缓存（第 3 层，LRU）==========
  final _contentCache = _LRUCache<String, String>(maxSize: 20);

  // ========== Repository ==========
  IAssistantRepository? _assistantRepo;
  ITopicRepository? _topicRepo;
  IMessageRepository? _messageRepo;

  // ========== 事件通知 ==========
  final _onIndexUpdated = StreamController<void>.broadcast();
  Stream<void> get onIndexUpdated => _onIndexUpdated.stream;

  // ========== 公开访问器（同步，无需等待）==========

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 获取所有助手（同步）
  List<AssistantInfo> get assistants => _assistants.values.toList();

  /// 获取助手信息（同步）
  AssistantInfo? getAssistant(String id) => _assistants[id];

  /// 获取所有话题（同步）
  List<TopicInfo> get topics => _topics.values.toList();

  /// 获取话题信息（同步）
  TopicInfo? getTopic(String id) => _topics[id];

  /// 获取指定助手的话题列表（同步）
  List<TopicInfo> getTopicsByAssistant(String assistantId) {
    return _topics.values.where((t) => t.assistantId == assistantId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// 按助手分组获取话题（同步）
  Map<String, List<TopicInfo>> get topicsGroupedByAssistant {
    final result = <String, List<TopicInfo>>{};
    for (final topic in _topics.values) {
      result.putIfAbsent(topic.assistantId, () => []).add(topic);
    }
    // 每组内按更新时间排序
    for (final list in result.values) {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return result;
  }

  // ========== 初始化和刷新 ==========

  /// 初始化（首次调用时构建索引）
  Future<void> init() async {
    if (_isInitialized || _isLoading) return;
    await rebuild();
  }

  /// 重建索引（版本切换时调用）
  Future<void> rebuild() async {
    if (_isLoading) return;

    _isLoading = true;
    final sw = Stopwatch()..start();

    try {
      await _ensureRepositories();

      // 1. 加载助手列表
      final assistants = await _assistantRepo!.getAllAssistants();
      _assistants.clear();
      for (final a in assistants) {
        _assistants[a.assistantId] = AssistantInfo(
          id: a.assistantId,
          name: a.name,
        );
      }
      debugPrint(
        '⏱️ [TopicIndex] 加载 ${assistants.length} 个助手: ${sw.elapsedMilliseconds}ms',
      );

      // 2. 加载所有话题元数据
      sw.reset();
      final allTopics = await _topicRepo!.getAllTopics();
      _topics.clear();

      for (final t in allTopics) {
        _topics[t.topicId] = TopicInfo(
          id: t.topicId,
          name: t.name,
          assistantId: t.assistantIds.isNotEmpty ? t.assistantIds.first : '',
          roundCount: t.roundCount,
          messageCount: t.messageCount,
          createdAt: DateTime.fromMillisecondsSinceEpoch(t.createdAt),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(t.updatedAt),
          rounds: [], // 轮次数据延迟加载
          isRoundsLoaded: false,
        );
      }
      debugPrint(
        '⏱️ [TopicIndex] 加载 ${allTopics.length} 个话题: ${sw.elapsedMilliseconds}ms',
      );

      _isInitialized = true;
      _lastBuildTime = DateTime.now();

      // 清空内容缓存
      _contentCache.clear();

      // 通知监听者
      _onIndexUpdated.add(null);
    } catch (e) {
      debugPrint('❌ [TopicIndex] 构建失败: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// 加载话题的轮次元数据（包含预览）
  ///
  /// 这是第 2 层数据，首次访问时加载，之后常驻
  Future<void> loadTopicRounds(String topicId) async {
    final topic = _topics[topicId];
    if (topic == null || topic.isRoundsLoaded) return;

    await _ensureRepositories();

    final sw = Stopwatch()..start();

    // 加载消息
    final messages = await _messageRepo!.loadAllMessages(
      topicId,
      parseExtendedFields: false,
    );

    // 加载 blocks（用于提取预览）
    final blockMap = await _messageRepo!.loadBlocksByTopic(topicId);

    // 组装轮次数据
    final rounds = <RoundInfo>[];
    String? currentQuestion;
    List<ReplyInfo> currentReplies = [];
    int roundIndex = 0;

    for (final msg in messages) {
      if (msg.role == 'user') {
        // 保存上一轮
        if (currentQuestion != null || currentReplies.isNotEmpty) {
          rounds.add(
            RoundInfo(
              index: roundIndex++,
              questionPreview: _truncate(currentQuestion ?? '', 80),
              questionLength: currentQuestion?.length ?? 0,
              replies: List.from(currentReplies),
            ),
          );
          currentReplies = [];
        }

        // 提取问题内容
        final blocks = blockMap[msg.messageId] ?? [];
        final content = _extractMainText(blocks);
        currentQuestion = content;
      } else if (msg.role == 'assistant') {
        // 提取回复内容
        final blocks = blockMap[msg.messageId] ?? [];
        final content = _extractMainText(blocks);

        currentReplies.add(
          ReplyInfo(
            id: msg.messageId,
            modelName: msg.modelName ?? 'AI',
            charCount: content.length,
            isMainline: msg.useful,
            contentPreview: _truncate(content, 150),
            // 完整内容不存储，按需加载
          ),
        );
      }
    }

    // 保存最后一轮
    if (currentQuestion != null || currentReplies.isNotEmpty) {
      rounds.add(
        RoundInfo(
          index: roundIndex,
          questionPreview: _truncate(currentQuestion ?? '', 80),
          questionLength: currentQuestion?.length ?? 0,
          replies: List.from(currentReplies),
        ),
      );
    }

    // 更新话题
    _topics[topicId] = topic.copyWith(rounds: rounds, isRoundsLoaded: true);

    debugPrint(
      '⏱️ [TopicIndex] 加载话题 $topicId 的 ${rounds.length} 轮: ${sw.elapsedMilliseconds}ms',
    );
  }

  /// 获取回复的完整内容（按需，从数据库或缓存）
  Future<String> getReplyFullContent(String messageId) async {
    // 先查缓存
    final cached = _contentCache.get(messageId);
    if (cached != null) return cached;

    // 从数据库加载
    await _ensureRepositories();
    final blocks = await _messageRepo!.loadBlocks(messageId);
    final content = _extractMainText(blocks);

    // 存入缓存
    _contentCache.put(messageId, content);

    return content;
  }

  /// 获取问题的完整内容（按需）
  Future<String> getQuestionFullContent(String topicId, int roundIndex) async {
    final cacheKey = '$topicId:q$roundIndex';

    // 先查缓存
    final cached = _contentCache.get(cacheKey);
    if (cached != null) return cached;

    // 从数据库加载
    await _ensureRepositories();
    final messages = await _messageRepo!.loadAllMessages(
      topicId,
      parseExtendedFields: false,
    );

    // 找到指定轮次的用户消息
    int currentRound = 0;
    for (final msg in messages) {
      if (msg.role == 'user') {
        if (currentRound == roundIndex) {
          final blocks = await _messageRepo!.loadBlocks(msg.messageId);
          final content = _extractMainText(blocks);
          _contentCache.put(cacheKey, content);
          return content;
        }
        currentRound++;
      }
    }

    return '';
  }

  // ========== 内部方法 ==========

  Future<void> _ensureRepositories() async {
    if (_assistantRepo != null) return;
    final provider = RepositoryProvider.instance;
    _assistantRepo = provider.assistantRepository;
    _topicRepo = provider.topicRepository;
    _messageRepo = provider.messageRepository;
  }

  String _extractMainText(List<dynamic> blocks) {
    final buffer = StringBuffer();
    for (final block in blocks) {
      if (block.type == 'main_text') {
        buffer.write(block.content ?? '');
      }
    }
    return buffer.toString();
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 释放资源
  void dispose() {
    _onIndexUpdated.close();
    _contentCache.clear();
  }
}

// ========== 数据模型 ==========

/// 助手信息（常驻）
class AssistantInfo {
  final String id;
  final String name;

  const AssistantInfo({required this.id, required this.name});
}

/// 话题信息（常驻）
class TopicInfo {
  final String id;
  final String name;
  final String assistantId;
  final int roundCount;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RoundInfo> rounds;
  final bool isRoundsLoaded;

  const TopicInfo({
    required this.id,
    required this.name,
    required this.assistantId,
    required this.roundCount,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
    required this.rounds,
    required this.isRoundsLoaded,
  });

  TopicInfo copyWith({List<RoundInfo>? rounds, bool? isRoundsLoaded}) {
    return TopicInfo(
      id: id,
      name: name,
      assistantId: assistantId,
      roundCount: roundCount,
      messageCount: messageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rounds: rounds ?? this.rounds,
      isRoundsLoaded: isRoundsLoaded ?? this.isRoundsLoaded,
    );
  }
}

/// 轮次信息（常驻）
class RoundInfo {
  final int index;
  final String questionPreview;
  final int questionLength;
  final List<ReplyInfo> replies;

  const RoundInfo({
    required this.index,
    required this.questionPreview,
    required this.questionLength,
    required this.replies,
  });
}

/// 回复信息（常驻，但完整内容按需加载）
class ReplyInfo {
  final String id;
  final String modelName;
  final int charCount;
  final bool isMainline;
  final String contentPreview;

  const ReplyInfo({
    required this.id,
    required this.modelName,
    required this.charCount,
    required this.isMainline,
    required this.contentPreview,
  });
}

// ========== LRU 缓存 ==========

class _LRUCache<K, V> {
  final int maxSize;
  final _cache = <K, V>{};
  final _accessOrder = <K>[];

  _LRUCache({required this.maxSize});

  V? get(K key) {
    final value = _cache[key];
    if (value != null) {
      // 移到最近使用
      _accessOrder.remove(key);
      _accessOrder.add(key);
    }
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    } else if (_cache.length >= maxSize) {
      // 移除最久未使用
      final oldest = _accessOrder.removeAt(0);
      _cache.remove(oldest);
    }
    _cache[key] = value;
    _accessOrder.add(key);
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }
}
