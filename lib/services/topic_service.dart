import 'package:flutter/foundation.dart';

import '../models/domain/domain_models.dart';
import '../repositories/i_message_repository.dart';
import '../repositories/i_topic_repository.dart';
import '../repositories/i_assistant_repository.dart';
import 'repository_provider.dart';

/// 话题服务
///
/// 封装话题数据的读取逻辑
/// 从 TopicEntity/MessageEntity/MessageBlockEntity 读取
class TopicService {
  // Repository（延迟初始化）
  IAssistantRepository? _assistantRepo;
  ITopicRepository? _topicRepo;
  IMessageRepository? _messageRepo;

  TopicService();

  /// 获取 Repository
  Future<void> _ensureRepositories() async {
    if (_assistantRepo != null) return;

    final provider = RepositoryProvider.instance;
    _assistantRepo = provider.assistantRepository;
    _topicRepo = provider.topicRepository;
    _messageRepo = provider.messageRepository;
  }

  // ========== 话题列表相关 ==========

  /// 获取所有话题（按助手分组）
  Future<Map<String, List<Map<String, dynamic>>>> getTopicsGrouped() async {
    await _ensureRepositories();

    final assistants = await _assistantRepo!.getAllAssistants();
    final result = <String, List<Map<String, dynamic>>>{};

    for (final assistant in assistants) {
      final topics = await _topicRepo!.getTopicsByAssistant(assistant.assistantId);

      result[assistant.assistantId] = topics.map((topic) => {
        'id': topic.topicId,
        'name': topic.name,
        'assistantId': topic.assistantId,
        'messageCount': topic.messageCount,
        'roundCount': topic.roundCount,
        'createdAt': topic.createdAt,
        'updatedAt': topic.updatedAt,
      }).toList();
    }

    return result;
  }

  /// 获取所有助手信息
  Future<List<AssistantModel>> getAssistants() async {
    await _ensureRepositories();
    return _assistantRepo!.getAllAssistants();
  }

  // ========== 单个话题相关 ==========

  /// 获取话题元数据
  Future<TopicModel?> getTopic(String topicId) async {
    await _ensureRepositories();
    return _topicRepo!.getTopic(topicId);
  }

  /// 获取话题的完整数据
  Future<Map<String, dynamic>?> getTopicFullData(String topicId) async {
    final sw = Stopwatch()..start();

    await _ensureRepositories();
    debugPrint('⏱️ [TopicService] ensureRepositories: ${sw.elapsedMilliseconds}ms');

    sw.reset();
    final topic = await _topicRepo!.getTopic(topicId);
    debugPrint('⏱️ [TopicService] getTopic: ${sw.elapsedMilliseconds}ms');
    if (topic == null) return null;

    // 加载所有消息
    sw.reset();
    final messages = await _messageRepo!.loadAllMessages(topicId);
    debugPrint('⏱️ [TopicService] loadAllMessages (${messages.length}条): ${sw.elapsedMilliseconds}ms');

    // 【优化】通过 topicId 直接加载所有 Block（避免 anyOf 的 O(n²) 问题）
    sw.reset();
    final blockMap = await _messageRepo!.loadBlocksByTopic(topicId);
    final totalBlocks = blockMap.values.fold<int>(0, (sum, list) => sum + list.length);
    debugPrint('⏱️ [TopicService] loadBlocksByTopic ($totalBlocks个Block): ${sw.elapsedMilliseconds}ms');

    // 组装数据
    sw.reset();
    final messagesData = messages.map((msg) {
      final blocks = blockMap[msg.messageId] ?? [];

      final resolvedBlocks = blocks.map((b) => {
        'id': b.blockId,
        'messageId': b.messageId,
        'type': b.type,
        'content': b.content,
        'thinking_millsec': b.thinkingMillsec,
        'url': b.url,
        'file': b.file,
        'error': b.error,
        'targetLanguage': b.targetLanguage,
        // tool 块字段
        'toolId': b.toolId,
        'toolName': b.toolName,
        'arguments': b.arguments,
        // citation 块字段
        'response': b.response,
        'knowledge': b.knowledge,
        'createdAt': DateTime.fromMillisecondsSinceEpoch(b.createdAt).toIso8601String(),
      }).toList();

      return {
        'id': msg.messageId,
        'role': msg.role,
        'topicId': msg.topicId,
        'assistantId': topic.assistantId,
        'createdAt': DateTime.fromMillisecondsSinceEpoch(msg.createdAt).toIso8601String(),
        'status': msg.status,
        'askId': msg.askId,
        'useful': msg.useful,
        'model': msg.modelId != null ? {'id': msg.modelId, 'name': msg.modelName} : null,
        'usage': msg.usage,
        'metrics': msg.metrics,
        'mentions': msg.mentions,
        'blocks': resolvedBlocks,
      };
    }).toList();
    debugPrint('⏱️ [TopicService] 数据组装: ${sw.elapsedMilliseconds}ms');

    return {
      'id': topic.topicId,
      'name': topic.name,
      'assistantId': topic.assistantId,
      'messages': messagesData,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(topic.createdAt).toIso8601String(),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(topic.updatedAt).toIso8601String(),
    };
  }

  // ========== 分页加载相关 ==========

  /// 获取话题的轮次总数
  Future<int> getRoundCount(String topicId) async {
    await _ensureRepositories();
    return _messageRepo!.getRoundCount(topicId);
  }

  /// 按轮次分页加载消息
  Future<List<MessageModel>> loadRounds(
    String topicId, {
    int startRound = 0,
    int roundCount = 5,
  }) async {
    await _ensureRepositories();
    return _messageRepo!.loadRounds(
      topicId,
      startRound: startRound,
      roundCount: roundCount,
    );
  }

  /// 批量加载消息的 Block
  Future<Map<String, List<BlockModel>>> batchLoadBlocks(
    List<String> messageIds,
  ) async {
    await _ensureRepositories();
    return _messageRepo!.batchLoadBlocks(messageIds);
  }
}
