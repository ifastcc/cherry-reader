import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../models/isar/prompt_template_entity.dart';
import '../utils/api_host_utils.dart';
import 'isar_database.dart';
import 'ai_provider_service.dart';
import 'openai_service.dart';
import 'prompt_template_service.dart';
import 'streaming_session_manager.dart';

/// 创建对话所需的配置
///
/// 用于懒创建对话时传递对话的元信息
class ConversationConfig {
  final String title;
  final ConversationContextType contextType;
  final String? contextId;
  final String? contextSnapshot;

  const ConversationConfig({
    required this.title,
    required this.contextType,
    this.contextId,
    this.contextSnapshot,
  });
}

/// 日志开关：控制是否打印 AI 请求的详细日志
const bool kEnableAIRequestLog = kDebugMode && true;

/// 截断长文本，保留开头和结尾
String _truncateText(
  String text, {
  int headLength = 150,
  int tailLength = 100,
  int threshold = 300,
}) {
  if (text.length <= threshold) return text;
  final head = text.substring(0, headLength);
  final tail = text.substring(text.length - tailLength);
  final omitted = text.length - headLength - tailLength;
  return '$head\n... [省略 $omitted 字符] ...\n$tail';
}

/// 格式化字符数
String _formatCharCount(int count) {
  if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}万';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '$count';
}

/// 提取消息块的文本内容
String _extractBlocksText(List<dynamic>? blocks) {
  if (blocks == null) return '';
  final buffer = StringBuffer();
  for (final block in blocks) {
    if (block is Map<String, dynamic> && block['type'] == 'main_text') {
      buffer.write(block['content'] as String? ?? '');
    }
  }
  return buffer.toString();
}

/// 打印对话结构与选择情况日志
///
/// 通过将原始结构与实际发送的 contextSnapshot 做字符串匹配，
/// 准确判断哪些内容被选中发送。
///
/// [contextData] 原始对话数据，包含 rounds 和 currentRoundIndex
/// [contextSnapshot] 实际发送的上下文内容（用于反向匹配）
void _logContextStructure({
  required Map<String, dynamic>? contextData,
  required String? contextSnapshot,
}) {
  if (!kEnableAIRequestLog || contextData == null) return;

  final rounds = contextData['rounds'] as List<dynamic>? ?? [];
  final currentRoundIndex = contextData['currentRoundIndex'] as int?;
  final snapshot = contextSnapshot ?? '';

  final buffer = StringBuffer();
  buffer.writeln('');
  buffer.writeln('╔══════════════════════════════════════════════════════════════════');
  buffer.writeln('║ 📋 对话结构与选择情况（通过内容匹配验证）');
  buffer.writeln('╠══════════════════════════════════════════════════════════════════');
  buffer.writeln('║ 话题共 ${rounds.length} 轮对话');
  if (currentRoundIndex != null) {
    buffer.writeln('║ 初始轮次索引: $currentRoundIndex');
  }
  buffer.writeln('║ 实际发送内容长度: ${_formatCharCount(snapshot.length)}字');
  buffer.writeln('╠══════════════════════════════════════════════════════════════════');

  int totalSelectedChars = 0;
  int totalSelectedReplies = 0;
  int totalSelectedQuestions = 0;

  for (var i = 0; i < rounds.length; i++) {
    final round = rounds[i] as Map<String, dynamic>;
    final question = round['question'] as Map<String, dynamic>?;
    final replies = round['replies'] as List<dynamic>? ?? [];

    // 提取问题文本
    final questionBlocks = question?['blocks'] as List<dynamic>?;
    final questionText = _extractBlocksText(questionBlocks);
    final questionLen = questionText.length;

    // 通过字符串匹配判断问题是否被选中
    final isQuestionSelected = questionText.isNotEmpty &&
        _isContentInSnapshot(questionText, snapshot);

    buffer.writeln('║');

    // 轮次标题
    String questionMark = isQuestionSelected ? ' ✓ 已匹配' : '';
    buffer.writeln('║ [轮次 $i]');

    // 问题
    final questionPreview = questionText.length > 50
        ? '${questionText.substring(0, 50).replaceAll('\n', ' ')}...'
        : questionText.replaceAll('\n', ' ');
    buffer.writeln('║   Q: "$questionPreview" (${_formatCharCount(questionLen)}字)$questionMark');

    if (isQuestionSelected) {
      totalSelectedChars += questionLen;
      totalSelectedQuestions++;
    }

    // 回复列表
    buffer.writeln('║   回复: ${replies.length} 条');

    for (var j = 0; j < replies.length; j++) {
      final reply = replies[j] as Map<String, dynamic>;
      final model = reply['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Unknown';
      final useful = reply['useful'] as bool? ?? false;

      final replyBlocks = reply['blocks'] as List<dynamic>?;
      final replyText = _extractBlocksText(replyBlocks);
      final replyLen = replyText.length;

      // 通过字符串匹配判断回复是否被选中
      final isReplySelected = replyText.isNotEmpty &&
          _isContentInSnapshot(replyText, snapshot);

      // 构建标记
      final usefulMark = useful ? ' ← 主线' : '';
      final selectedMark = isReplySelected ? ' ✓' : '';

      buffer.writeln(
          '║     [$j] $modelName (${_formatCharCount(replyLen)}字) useful=$useful$usefulMark$selectedMark');

      if (isReplySelected) {
        totalSelectedChars += replyLen;
        totalSelectedReplies++;
      }
    }
  }

  buffer.writeln('║');
  buffer.writeln('╠══════════════════════════════════════════════════════════════════');
  buffer.writeln(
      '║ 匹配结果: $totalSelectedQuestions 问 + $totalSelectedReplies 回复 ≈ ${_formatCharCount(totalSelectedChars)}字');

  // 验证：匹配的字符数应该与 snapshot 长度接近
  final snapshotLen = snapshot.length;
  if (snapshotLen > 0) {
    // snapshot 包含格式化标记（## 用户问题、### 模型名 等），所以会比纯内容长
    final ratio = totalSelectedChars / snapshotLen;
    if (ratio < 0.5) {
      buffer.writeln('║ ⚠️ 警告: 匹配内容(${_formatCharCount(totalSelectedChars)}) 明显少于发送内容(${_formatCharCount(snapshotLen)})');
      buffer.writeln('║    可能有内容未被识别，请检查实际发送的消息');
    } else if (ratio > 1.5) {
      buffer.writeln('║ ⚠️ 警告: 匹配内容(${_formatCharCount(totalSelectedChars)}) 明显多于发送内容(${_formatCharCount(snapshotLen)})');
      buffer.writeln('║    可能是匹配算法误判，请检查实际发送的消息');
    } else {
      buffer.writeln('║ ✅ 匹配验证通过');
    }
  }
  buffer.writeln('╚══════════════════════════════════════════════════════════════════');

  _printLog(buffer.toString(), 'CONTEXT_STRUCTURE');
}

/// 检查内容是否在 snapshot 中
///
/// 使用内容的前 N 个字符和后 M 个字符做匹配，避免因格式差异导致的误判
bool _isContentInSnapshot(String content, String snapshot) {
  if (content.isEmpty || snapshot.isEmpty) return false;

  // 清理空白字符，统一比较
  final cleanContent = content.replaceAll(RegExp(r'\s+'), ' ').trim();
  final cleanSnapshot = snapshot.replaceAll(RegExp(r'\s+'), ' ').trim();

  if (cleanContent.isEmpty) return false;

  // 策略1：完整匹配（清理后）
  if (cleanSnapshot.contains(cleanContent)) return true;

  // 策略2：取前100字符匹配（处理可能的截断）
  if (cleanContent.length > 100) {
    final head = cleanContent.substring(0, 100);
    if (cleanSnapshot.contains(head)) return true;
  }

  // 策略3：取前50字符 + 后50字符匹配
  if (cleanContent.length > 100) {
    final head = cleanContent.substring(0, 50);
    final tail = cleanContent.substring(cleanContent.length - 50);
    if (cleanSnapshot.contains(head) && cleanSnapshot.contains(tail)) return true;
  }

  // 策略4：对于短内容，直接匹配
  if (cleanContent.length <= 100) {
    return cleanSnapshot.contains(cleanContent);
  }

  return false;
}

/// 打印 AI 请求日志（最终发送给模型的消息）
void _logAIRequest({
  required String conversationId,
  required ConversationContextType contextType,
  required List<Map<String, String>> messages,
  required String modelId,
}) {
  if (!kEnableAIRequestLog) return;

  final buffer = StringBuffer();
  buffer.writeln('');
  buffer.writeln('╔══════════════════════════════════════════════════════════════════');
  buffer.writeln('║ 🚀 实际发送给 AI 的消息');
  buffer.writeln('╠══════════════════════════════════════════════════════════════════');
  buffer.writeln('║ 对话ID: ${conversationId.length > 8 ? conversationId.substring(0, 8) : conversationId}...');
  buffer.writeln('║ 上下文类型: ${contextType.name}');
  buffer.writeln('║ 目标模型: $modelId');
  buffer.writeln('║ 消息数量: ${messages.length}');

  // 统计总字符数
  int totalChars = 0;
  for (final msg in messages) {
    totalChars += (msg['content'] ?? '').length;
  }
  buffer.writeln('║ 总字符数: ${_formatCharCount(totalChars)}');
  buffer.writeln('╠══════════════════════════════════════════════════════════════════');

  for (var i = 0; i < messages.length; i++) {
    final msg = messages[i];
    final role = msg['role'] ?? 'unknown';
    final content = msg['content'] ?? '';
    final charCount = content.length;

    // 角色标识
    String roleIcon;
    String roleLabel;
    switch (role) {
      case 'system':
        roleIcon = '⚙️';
        roleLabel = 'System Prompt';
        break;
      case 'user':
        roleIcon = '👤';
        roleLabel = 'User';
        break;
      case 'assistant':
        roleIcon = '🤖';
        roleLabel = 'Assistant';
        break;
      default:
        roleIcon = '❓';
        roleLabel = role;
    }

    buffer.writeln('║');
    buffer.writeln('║ [$i] $roleIcon $roleLabel (${_formatCharCount(charCount)}字)');
    buffer.writeln('║ ─────────────────────────────────────────────');

    // 截断并缩进显示内容
    final truncated = _truncateText(content);
    final lines = truncated.split('\n');
    for (final line in lines) {
      // 每行最多显示 75 字符
      final displayLine = line.length > 75 ? '${line.substring(0, 75)}...' : line;
      buffer.writeln('║   $displayLine');
    }
  }

  buffer.writeln('║');
  buffer.writeln('╚══════════════════════════════════════════════════════════════════');

  _printLog(buffer.toString(), 'AI_REQUEST');
}

/// 统一的日志输出
void _printLog(String message, String tag) {
  developer.log(message, name: tag);
  // ignore: avoid_print
  print(message);
}

/// 统一对话服务
///
/// 管理所有类型的 AI 对话：
/// 1. 独立对话（topic）：新建的 AI 对话
/// 2. 消息组分析（messageGroup）：对某一轮对话的分析
/// 3. 单消息讨论（singleMessage）：针对某个 AI 回复的讨论
class UnifiedConversationService {
  static UnifiedConversationService? _instance;
  static UnifiedConversationService get instance {
    _instance ??= UnifiedConversationService._();
    return _instance!;
  }

  UnifiedConversationService._();

  final _uuid = const Uuid();
  final _db = IsarDatabase();

  // ============ 对话管理 ============

  /// 创建新对话
  Future<String> createConversation({
    required String title,
    required ConversationContextType contextType,
    String? contextId,
    String? contextSnapshot,
    String? initialUserMessage,
  }) async {
    final conversationId = _uuid.v4();
    final providerService = AIProviderService.instance;

    final entity = UnifiedConversationEntity.create(
      conversationId: conversationId,
      title: title,
      contextType: contextType,
      contextId: contextId ?? '',
      contextSnapshot: contextSnapshot,
      providerId: providerService.activeProvider?.id,
      modelId: providerService.activeModelId,
    );

    await _db.saveUnifiedConversation(entity);

    // 如果有上下文快照，作为系统消息保存
    if (contextSnapshot != null && contextSnapshot.isNotEmpty) {
      final systemMessage = UnifiedMessageEntity.createSystemMessage(
        messageId: _uuid.v4(),
        conversationId: conversationId,
        content: contextSnapshot,
      );
      await _db.saveUnifiedMessage(systemMessage);
      await _updateMessageCount(conversationId);
    }

    // 如果有初始用户消息，保存
    if (initialUserMessage != null && initialUserMessage.isNotEmpty) {
      await addUserMessage(conversationId, initialUserMessage);
    }

    return conversationId;
  }

  /// 获取对话列表（按类型）
  Future<List<UnifiedConversationEntity>> getConversations({
    ConversationContextType? contextType,
    bool includeArchived = false,
  }) async {
    final conversations = await _db.getUnifiedConversations(
      contextType: contextType,
      includeArchived: includeArchived,
    );
    // 修复旧数据：如果 roundCount 为 0 但有消息，重新计算
    for (final conv in conversations) {
      if (conv.roundCount == 0 && conv.messageCount > 0) {
        await _updateMessageCount(conv.conversationId);
      }
    }
    // 如果有修复，重新获取
    return _db.getUnifiedConversations(
      contextType: contextType,
      includeArchived: includeArchived,
    );
  }

  /// 获取特定上下文的对话列表
  Future<List<UnifiedConversationEntity>> getConversationsByContext(
    String contextId,
  ) async {
    final conversations = await _db.getUnifiedConversationsByContextId(contextId);
    // 修复旧数据：如果 roundCount 为 0 但有消息，重新计算
    for (final conv in conversations) {
      if (conv.roundCount == 0 && conv.messageCount > 0) {
        await _updateMessageCount(conv.conversationId);
      }
    }
    // 重新获取更新后的数据
    return _db.getUnifiedConversationsByContextId(contextId);
  }

  /// 批量获取讨论数量
  Future<Map<String, int>> getDiscussionCounts(List<String> contextIds) async {
    if (contextIds.isEmpty) return {};

    final counts = <String, int>{};
    
    // 1. 批量查询所有相关对话
    final conversations = await _db.getUnifiedConversationsByContextIds(contextIds);

    // 2. 在内存中分组统计
    for (final conv in conversations) {
      final contextId = conv.contextId;
      if (contextId.isNotEmpty) {
        counts[contextId] = (counts[contextId] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// 获取同一话题下所有轮次的对话列表
  ///
  /// 用于"查看全部讨论"功能，根据话题 ID 前缀匹配
  Future<List<UnifiedConversationEntity>> getConversationsByTopicPrefix(
    String topicId,
  ) async {
    final conversations = await _db.getUnifiedConversationsByTopicPrefix(topicId);
    // 修复旧数据
    for (final conv in conversations) {
      if (conv.roundCount == 0 && conv.messageCount > 0) {
        await _updateMessageCount(conv.conversationId);
      }
    }
    return _db.getUnifiedConversationsByTopicPrefix(topicId);
  }

  /// 获取单个对话
  Future<UnifiedConversationEntity?> getConversation(
    String conversationId,
  ) async {
    return _db.getUnifiedConversation(conversationId);
  }

  /// 删除对话（包括所有消息）
  Future<void> deleteConversation(String conversationId) async {
    await _db.deleteUnifiedConversation(conversationId);
  }

  /// 删除所有对话
  Future<int> deleteAllConversations() async {
    final conversations = await _db.getUnifiedConversations(includeArchived: true);
    for (final conv in conversations) {
      await _db.deleteUnifiedConversation(conv.conversationId);
    }
    return conversations.length;
  }

  /// 删除空对话（没有用户消息的对话）
  ///
  /// 只删除 roundCount == 0 的对话（没有用户交互的对话），保留有内容的对话
  /// 注意：即使对话有系统消息（contextSnapshot），但没有用户消息也视为空对话
  /// 返回删除的对话数量
  Future<int> deleteEmptyConversations() async {
    final conversations = await _db.getUnifiedConversations(includeArchived: true);
    int deletedCount = 0;

    for (final conv in conversations) {
      // 只删除没有用户消息的空对话（roundCount 统计的是用户消息数量）
      if (conv.roundCount == 0) {
        await _db.deleteUnifiedConversation(conv.conversationId);
        deletedCount++;
      }
    }

    return deletedCount;
  }

  /// 获取空对话数量（用于 UI 显示）
  Future<int> getEmptyConversationCount() async {
    final conversations = await _db.getUnifiedConversations(includeArchived: true);
    return conversations.where((c) => c.roundCount == 0).length;
  }

  /// 归档对话
  Future<void> archiveConversation(String conversationId) async {
    final entity = await _db.getUnifiedConversation(conversationId);
    if (entity != null) {
      entity.isArchived = true;
      entity.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _db.saveUnifiedConversation(entity);
    }
  }

  /// 更新对话标题
  Future<void> updateTitle(String conversationId, String newTitle) async {
    final entity = await _db.getUnifiedConversation(conversationId);
    if (entity != null) {
      entity.title = newTitle;
      entity.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _db.saveUnifiedConversation(entity);
    }
  }

  // ============ 消息管理 ============

  /// 获取对话的所有消息
  Future<List<UnifiedMessageEntity>> getMessages(
    String conversationId,
  ) async {
    return _db.getUnifiedMessages(conversationId);
  }

  /// 监听对话消息变化
  Stream<List<UnifiedMessageEntity>> watchMessages(
    String conversationId,
  ) {
    return _db.watchUnifiedMessages(conversationId);
  }

  /// 添加用户消息
  Future<String> addUserMessage(
    String conversationId,
    String content,
  ) async {
    final messageId = _uuid.v4();
    final message = UnifiedMessageEntity.createUserMessage(
      messageId: messageId,
      conversationId: conversationId,
      content: content,
    );

    await _db.saveUnifiedMessage(message);
    await _updateMessageCount(conversationId);

    return messageId;
  }

  /// 添加结构化用户消息（支持模板、上下文等字段）
  Future<String> addStructuredUserMessage(
    String conversationId, {
    String? templateId,
    String? templateName,
    String? templateContent,
    String? contextSummary,
    String? contextContent,
    String? userQuery,
    String? contextDataJson,
  }) async {
    final message = UnifiedMessageEntity.createStructuredUserMessage(
      messageId: _uuid.v4(),
      conversationId: conversationId,
      templateId: templateId,
      templateName: templateName,
      templateContent: templateContent,
      contextSummary: contextSummary,
      contextContent: contextContent,
      userQuery: userQuery,
      contextDataJson: contextDataJson,
    );

    await _db.saveUnifiedMessage(message);
    await _updateMessageCount(conversationId);

    return message.messageId;
  }

  /// 创建对话并添加结构化用户消息（懒创建版本）
  ///
  /// 用于多模型调用等场景，将创建对话和添加用户消息合并为原子操作
  ///
  /// [conversationId] 可以为 null，此时会自动生成新 ID
  /// [conversationConfig] 创建对话所需的配置（仅当需要创建新对话时使用）
  ///
  /// 返回 (conversationId, userMessageId)
  Future<({String conversationId, String userMessageId})>
      createConversationAndAddUserMessage({
    String? conversationId,
    ConversationConfig? conversationConfig,
    String? templateId,
    String? templateName,
    String? templateContent,
    String? contextSummary,
    String? contextContent,
    String? userQuery,
    String? contextDataJson,
  }) async {
    // 生成或使用传入的 conversationId
    final effectiveConversationId = conversationId ?? _uuid.v4();
    final isNewConversation = conversationId == null;

    // 如果是新对话，先创建对话记录
    if (isNewConversation && conversationConfig != null) {
      final providerService = AIProviderService.instance;
      final entity = UnifiedConversationEntity.create(
        conversationId: effectiveConversationId,
        title: conversationConfig.title,
        contextType: conversationConfig.contextType,
        contextId: conversationConfig.contextId ?? '',
        contextSnapshot: conversationConfig.contextSnapshot,
        providerId: providerService.activeProvider?.id,
        modelId: providerService.activeModelId,
      );
      await _db.saveUnifiedConversation(entity);
    }

    // 创建结构化用户消息
    final userMessageId = _uuid.v4();
    final message = UnifiedMessageEntity.createStructuredUserMessage(
      messageId: userMessageId,
      conversationId: effectiveConversationId,
      templateId: templateId,
      templateName: templateName,
      templateContent: templateContent,
      contextSummary: contextSummary,
      contextContent: contextContent,
      userQuery: userQuery,
      contextDataJson: contextDataJson,
    );

    await _db.saveUnifiedMessage(message);
    await _updateMessageCount(effectiveConversationId);

    return (
      conversationId: effectiveConversationId,
      userMessageId: userMessageId,
    );
  }

  /// 添加助手消息
  ///
  /// [askId] 关联的用户问题 ID，指向触发这个回复的用户消息
  /// [isMainline] 是否为主线回复，默认为 true
  Future<String> addAssistantMessage(
    String conversationId,
    String content, {
    String? modelId,
    String? modelName,
    String? askId,
    bool isMainline = true,
  }) async {
    final messageId = _uuid.v4();
    final message = UnifiedMessageEntity.createAssistantMessage(
      messageId: messageId,
      conversationId: conversationId,
      content: content,
      modelId: modelId,
      modelName: modelName,
      askId: askId,
      isMainline: isMainline,
      status: 'completed',
    );

    await _db.saveUnifiedMessage(message);
    await _updateMessageCount(conversationId);

    return messageId;
  }

  /// 追加模型回复到已有问题
  ///
  /// 对已有的用户问题（askId）追加一个新模型的回复。
  /// 新回复使用相同的 askId，但 isMainline=false（不改变主线）。
  ///
  /// [conversationId] 对话 ID
  /// [askId] 用户问题的消息 ID
  /// [providerId] 要使用的 Provider ID
  /// [modelId] 要使用的模型 ID
  ///
  /// 返回 Stream<String>，流式输出 AI 回复内容
  Stream<String> addReplyToExistingQuestion({
    required String conversationId,
    required String askId,
    required String providerId,
    required String modelId,
  }) async* {
    // 1. 获取 Provider 配置
    final providerService = AIProviderService.instance;
    final provider = providerService.providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw Exception('找不到 Provider: $providerId'),
    );

    final model = provider.models.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw Exception('找不到模型: $modelId'),
    );

    // 2. 构建发送给 API 的消息列表（只取到 askId 对应的用户消息为止）
    final allMessages = await getMessages(conversationId);
    final apiMessages = <Map<String, String>>[];

    // 按 askId 分组找出主线消息
    final assistantsByAskId = <String, List<UnifiedMessageEntity>>{};
    for (final m in allMessages) {
      if (m.role == 'assistant' && m.askId != null) {
        assistantsByAskId.putIfAbsent(m.askId!, () => []).add(m);
      }
    }

    // 每个 askId 组选择主线消息
    final mainlineAssistantIds = <String>{};
    for (final group in assistantsByAskId.values) {
      final mainline = group.firstWhere(
        (m) => m.isMainline == true,
        orElse: () => group.first,
      );
      mainlineAssistantIds.add(mainline.messageId);
    }

    // 构建消息列表（只到 askId 对应的用户消息为止）
    for (final m in allMessages) {
      // 到达目标用户消息时停止（包含这条用户消息）
      if (m.messageId == askId) {
        apiMessages.add({'role': m.role, 'content': m.content});
        break;
      }

      // 用户消息直接添加
      if (m.role == 'user') {
        apiMessages.add({'role': m.role, 'content': m.content});
      }
      // assistant 消息只取主线的
      else if (m.role == 'assistant') {
        if (m.askId == null || mainlineAssistantIds.contains(m.messageId)) {
          apiMessages.add({'role': m.role, 'content': m.content});
        }
      }
    }

    if (apiMessages.isEmpty) {
      throw Exception('找不到用户消息: $askId');
    }

    // 3. 创建助手消息占位
    final assistantMessageId = _uuid.v4();
    final assistantMessage = UnifiedMessageEntity.createAssistantMessage(
      messageId: assistantMessageId,
      conversationId: conversationId,
      modelId: modelId,
      modelName: model.name,
      askId: askId,
      isMainline: false,  // 追加的回复不是主线
      status: 'streaming',
    );
    await _db.saveUnifiedMessage(assistantMessage);

    // 4. 调用 API 并流式更新
    // 注意：需要规范化 apiHost，确保包含 /v1 等版本路径
    final service = OpenAIService(
      apiKey: provider.apiKey,
      baseUrl: formatOpenAIApiHost(provider.apiHost),
    );

    var fullContent = '';
    try {
      await for (final chunk in service.streamChatCompletion(
        model: modelId,
        messages: apiMessages,
      )) {
        fullContent += chunk;
        yield chunk;

        // 每次收到内容都更新数据库
        await updateMessageContent(
          assistantMessageId,
          fullContent,
          status: 'streaming',
        );
      }

      // 完成
      await updateMessageContent(
        assistantMessageId,
        fullContent,
        status: 'completed',
      );
      await _updateMessageCount(conversationId);
    } catch (e) {
      // 错误处理
      final message = await _db.getUnifiedMessage(assistantMessageId);
      if (message != null) {
        message.status = 'error';
        message.errorMessage = e.toString();
        message.content = fullContent.isEmpty ? '请求失败: $e' : fullContent;
        await _db.saveUnifiedMessage(message);
      }
      rethrow;
    }
  }

  /// 更新消息内容（用于流式更新）
  Future<void> updateMessageContent(
    String messageId,
    String content, {
    String? status,
  }) async {
    final message = await _db.getUnifiedMessage(messageId);
    if (message != null) {
      message.content = content;
      if (status != null) {
        message.status = status;
      }
      await _db.saveUnifiedMessage(message);
    }
  }

  /// 删除单条消息
  Future<bool> deleteMessage(String messageId) async {
    final message = await _db.getUnifiedMessage(messageId);
    if (message != null) {
      final conversationId = message.conversationId;
      final deleted = await _db.deleteUnifiedMessage(messageId);
      if (deleted) {
        await _updateMessageCount(conversationId);
      }
      return deleted;
    }
    return false;
  }

  /// 更新消息计数
  Future<void> _updateMessageCount(String conversationId) async {
    final messages = await _db.getUnifiedMessages(conversationId);
    final entity = await _db.getUnifiedConversation(conversationId);
    if (entity != null) {
      entity.messageCount = messages.length;
      // 计算轮数：统计用户消息数量
      entity.roundCount = messages.where((m) => m.role == 'user').length;
      entity.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _db.saveUnifiedConversation(entity);
    }
  }

  // ============ AI 交互 ============

  /// 发送结构化消息并获取 AI 回复（流式）- 支持懒创建
  ///
  /// 这是推荐的发送方式，支持模版、上下文和追问问题的分离
  ///
  /// [conversationId] 可以为 null，此时会在发送消息时自动创建对话
  /// [conversationConfig] 创建对话所需的配置（仅当 conversationId 为 null 时使用）
  /// [debugContextData] 原始对话数据，用于调试日志，展示对话结构和选择情况
  ///
  /// 返回一个 Record：(Stream<String> stream, Future<String> conversationId)
  /// - stream: AI 回复的流
  /// - conversationId: 创建或使用的对话 ID（在流开始前即可获取）
  ({Stream<String> stream, String conversationId}) sendStructuredMessageAndStreamWithLazyCreate({
    String? conversationId,
    ConversationConfig? conversationConfig,
    String? templateId,
    String? contextContent,
    String? contextSummary,
    String? userQuery,
    String? contextDataJson,
    Map<String, dynamic>? debugContextData,
  }) {
    // 如果没有传入 conversationId，生成一个新的
    final effectiveConversationId = conversationId ?? _uuid.v4();

    final stream = _sendStructuredMessageAndStreamInternal(
      conversationId: effectiveConversationId,
      isNewConversation: conversationId == null,
      conversationConfig: conversationConfig,
      templateId: templateId,
      contextContent: contextContent,
      contextSummary: contextSummary,
      userQuery: userQuery,
      contextDataJson: contextDataJson,
      debugContextData: debugContextData,
    );

    return (stream: stream, conversationId: effectiveConversationId);
  }

  /// 内部方法：发送结构化消息并获取 AI 回复
  Stream<String> _sendStructuredMessageAndStreamInternal({
    required String conversationId,
    required bool isNewConversation,
    ConversationConfig? conversationConfig,
    String? templateId,
    String? contextContent,
    String? contextSummary,
    String? userQuery,
    String? contextDataJson,
    Map<String, dynamic>? debugContextData,
  }) async* {
    // 1. 获取模版
    TaskTemplateEntity? template;
    if (templateId != null) {
      template = await PromptTemplateService.instance.getTemplate(templateId);
      if (template != null) {
        await PromptTemplateService.instance.incrementUsage(templateId);
      }
    }

    // 2. 如果是新对话，先创建对话记录
    if (isNewConversation && conversationConfig != null) {
      final providerService = AIProviderService.instance;
      final entity = UnifiedConversationEntity.create(
        conversationId: conversationId,
        title: conversationConfig.title,
        contextType: conversationConfig.contextType,
        contextId: conversationConfig.contextId ?? '',
        contextSnapshot: conversationConfig.contextSnapshot,
        providerId: providerService.activeProvider?.id,
        modelId: providerService.activeModelId,
      );
      await _db.saveUnifiedConversation(entity);
    }

    // 3. 创建结构化消息
    final userMessageId = _uuid.v4();
    final message = UnifiedMessageEntity.createStructuredUserMessage(
      messageId: userMessageId,
      conversationId: conversationId,
      templateId: templateId,
      templateName: template?.name,
      templateContent: template?.content,
      contextSummary: contextSummary,
      contextContent: contextContent,
      userQuery: userQuery,
      contextDataJson: contextDataJson,
    );

    await _db.saveUnifiedMessage(message);
    await _updateMessageCount(conversationId);

    // 4. 继续发送给 AI
    yield* _streamAIResponse(
      conversationId,
      message.content,
      userMessageId: userMessageId,
      debugContextData: debugContextData,
      debugContextSnapshot: contextContent,
    );
  }

  /// 发送结构化消息并获取 AI 回复（流式）
  ///
  /// 这是推荐的发送方式，支持模版、上下文和追加问题的分离
  ///
  /// [debugContextData] 原始对话数据，用于调试日志，展示对话结构和选择情况
  @Deprecated('Use sendStructuredMessageAndStreamWithLazyCreate instead')
  Stream<String> sendStructuredMessageAndStream(
    String conversationId, {
    String? templateId,
    String? contextContent,
    String? contextSummary,
    String? userQuery,
    String? contextDataJson,
    Map<String, dynamic>? debugContextData,
  }) async* {
    // 1. 获取模版
    TaskTemplateEntity? template;
    if (templateId != null) {
      template = await PromptTemplateService.instance.getTemplate(templateId);
      if (template != null) {
        await PromptTemplateService.instance.incrementUsage(templateId);
      }
    }

    // 2. 创建结构化消息
    final userMessageId = _uuid.v4();
    final message = UnifiedMessageEntity.createStructuredUserMessage(
      messageId: userMessageId,
      conversationId: conversationId,
      templateId: templateId,
      templateName: template?.name,
      templateContent: template?.content,
      contextSummary: contextSummary,
      contextContent: contextContent,
      userQuery: userQuery,
      contextDataJson: contextDataJson,
    );

    await _db.saveUnifiedMessage(message);
    await _updateMessageCount(conversationId);

    // 3. 继续发送给 AI
    yield* _streamAIResponse(
      conversationId,
      message.content,
      userMessageId: userMessageId,  // 传递用户消息 ID 用于设置 askId
      debugContextData: debugContextData,
      debugContextSnapshot: contextContent,
    );
  }

  /// 发送消息并获取 AI 回复（流式）
  ///
  /// 返回 AI 回复的 messageId
  Stream<String> sendMessageAndStream(
    String conversationId,
    String userContent,
  ) async* {
    // 1. 保存用户消息
    final userMessageId = await addUserMessage(conversationId, userContent);

    // 2. 发送给 AI
    yield* _streamAIResponse(
      conversationId,
      userContent,
      userMessageId: userMessageId,  // 传递用户消息 ID 用于设置 askId
    );
  }

  /// 内部方法：发送消息给 AI 并流式返回
  ///
  /// [userMessageId] 触发这个回复的用户消息 ID，用于设置 askId
  /// [debugContextData] 原始对话数据，用于调试日志
  /// [debugContextSnapshot] 实际发送的上下文内容，用于验证匹配
  Stream<String> _streamAIResponse(
    String conversationId,
    String userContent, {
    String? userMessageId,
    Map<String, dynamic>? debugContextData,
    String? debugContextSnapshot,
  }) async* {
    // 1. 获取配置
    final config = AIProviderService.instance.getActiveConfig();
    if (config == null) {
      throw Exception('请先配置 AI Provider');
    }

    // 2. 获取用户偏好（System Prompt）
    final preference =
        await PromptTemplateService.instance.getActivePreference();

    // 3. 获取对话及消息
    final conversation = await _db.getUnifiedConversation(conversationId);
    final messages = await getMessages(conversationId);
    final apiMessages = <Map<String, String>>[];

    // 添加 System Prompt（如果有）
    if (preference != null && preference.systemPrompt.isNotEmpty) {
      apiMessages.add({
        'role': 'system',
        'content': preference.systemPrompt,
      });
    }

    // 4. 根据上下文类型构建要发送给模型的消息
    if (conversation?.contextType == ConversationContextType.messageGroup) {
      // 对于「本轮对话的 AI 分析」：
      // 1. 原始对话的上下文快照（contextSnapshot）
      // 2. 完整的分析对话历史（之前的 user + assistant 消息）
      // 这样 AI 能看到完整的对话上下文，包括之前的追问和回答

      // 4.1 上下文快照（原始对话的内容，作为参考）
      final snapshot = conversation?.contextSnapshot;
      if (snapshot != null && snapshot.isNotEmpty) {
        apiMessages.add({
          'role': 'user',
          'content': snapshot,
        });
      }

      // 4.2 添加完整的对话历史（跳过 system 消息，因为 snapshot 已经包含了）
      // 按 askId 分组找出主线消息
      final mainlineAssistantIds = <String>{};
      final assistantsByAskId = <String, List<UnifiedMessageEntity>>{};

      for (final m in messages) {
        if (m.role == 'assistant' && m.askId != null) {
          assistantsByAskId.putIfAbsent(m.askId!, () => []).add(m);
        }
      }

      // 每个 askId 组选择主线消息（isMainline=true 的，或第一个）
      for (final entry in assistantsByAskId.entries) {
        final group = entry.value;
        final mainline = group.firstWhere(
          (m) => m.isMainline,
          orElse: () => group.first,
        );
        mainlineAssistantIds.add(mainline.messageId);
      }

      // 构建消息列表（跳过 system 类型，因为 snapshot 已经作为 user 消息添加了）
      for (final m in messages) {
        if (m.role == 'system') {
          // 跳过 system 消息，上面已经添加了 snapshot
          continue;
        } else if (m.role == 'user') {
          // 用户消息：处理结构化消息
          final template = m.templateSnapshot;
          final userQuery = m.userQuery;

          if ((template != null && template.isNotEmpty) ||
              (userQuery != null && userQuery.isNotEmpty)) {
            final buffer = StringBuffer();
            if (template != null && template.isNotEmpty) {
              buffer.write(template);
            }
            if (userQuery != null && userQuery.isNotEmpty) {
              if (buffer.isNotEmpty) buffer.write('\n\n');
              buffer.write(userQuery);
            }
            apiMessages.add({
              'role': 'user',
              'content': buffer.isEmpty ? m.content : buffer.toString(),
            });
          } else {
            apiMessages.add({
              'role': 'user',
              'content': m.content,
            });
          }
        } else if (m.role == 'assistant') {
          // assistant 消息：只添加主线消息
          if (m.askId == null || mainlineAssistantIds.contains(m.messageId)) {
            apiMessages.add({
              'role': 'assistant',
              'content': m.content,
            });
          }
        }
      }
    } else {
      // 默认行为：保留完整对话历史
      // 参考 Cherry Studio 的 filterUsefulMessages 逻辑：
      // 1. 用户消息直接添加
      // 2. assistant 消息按 askId 分组，只取 isMainline=true 的那个

      // 先按 askId 分组找出主线消息
      final mainlineAssistantIds = <String>{};
      final assistantsByAskId = <String, List<UnifiedMessageEntity>>{};

      for (final m in messages) {
        if (m.role == 'assistant' && m.askId != null) {
          assistantsByAskId.putIfAbsent(m.askId!, () => []).add(m);
        }
      }

      // 每个 askId 组选择主线消息（isMainline=true 的，或第一个）
      for (final entry in assistantsByAskId.entries) {
        final group = entry.value;
        final mainline = group.firstWhere(
          (m) => m.isMainline,
          orElse: () => group.first,
        );
        mainlineAssistantIds.add(mainline.messageId);
      }

      // 构建消息列表
      for (final m in messages) {
        if (m.role == 'system') {
          // 系统消息作为 user 消息发送（上下文）
          apiMessages.add({
            'role': 'user',
            'content': m.content,
          });
        } else if (m.role == 'user') {
          // 用户消息直接添加
          apiMessages.add({
            'role': 'user',
            'content': m.content,
          });
        } else if (m.role == 'assistant') {
          // assistant 消息：只添加主线消息
          if (m.askId == null || mainlineAssistantIds.contains(m.messageId)) {
            apiMessages.add({
              'role': 'assistant',
              'content': m.content,
            });
          }
          // 非主线消息跳过
        }
      }
    }

    // 📝 打印对话结构日志（如果有原始数据）
    if (debugContextData != null) {
      // 优先使用传入的 snapshot，否则尝试从 conversation 获取
      final snapshotForLog = debugContextSnapshot ?? conversation?.contextSnapshot;
      _logContextStructure(
        contextData: debugContextData,
        contextSnapshot: snapshotForLog,
      );
    }

    // 📝 打印请求日志
    _logAIRequest(
      conversationId: conversationId,
      contextType: conversation?.contextType ?? ConversationContextType.topic,
      messages: apiMessages,
      modelId: config.modelId,
    );

    // 5. 创建助手消息占位
    // 如果没有传入 userMessageId，尝试从最后一条用户消息获取
    String? effectiveAskId = userMessageId;
    if (effectiveAskId == null) {
      for (final m in messages.reversed) {
        if (m.role == 'user') {
          effectiveAskId = m.messageId;
          break;
        }
      }
    }

    final assistantMessageId = _uuid.v4();
    final assistantMessage = UnifiedMessageEntity.createAssistantMessage(
      messageId: assistantMessageId,
      conversationId: conversationId,
      modelId: config.modelId,
      modelName: config.modelId,
      askId: effectiveAskId,
      isMainline: true,  // 第一个回复默认是主线
      status: 'streaming',
    );
    await _db.saveUnifiedMessage(assistantMessage);

    // 6. 创建 StreamingSession（支持后台继续运行）
    final sessionManager = StreamingSessionManager.instance;
    final session = sessionManager.createSession(
      conversationId: conversationId,
      messageId: assistantMessageId,
    );

    // 7. 调用 API 并流式更新
    final service = OpenAIService(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
    );

    var fullContent = '';
    try {
      await for (final chunk in service.streamChatCompletion(
        model: config.modelId,
        messages: apiMessages,
      )) {
        fullContent += chunk;

        // 更新 session（支持后台继续和重新连接）
        session.appendContent(chunk);

        yield chunk;

        // 每次收到内容都更新数据库
        await updateMessageContent(
          assistantMessageId,
          fullContent,
          status: 'streaming',
        );
      }

      // 完成
      session.complete();
      await updateMessageContent(
        assistantMessageId,
        fullContent,
        status: 'completed',
      );
      await _updateMessageCount(conversationId);
    } catch (e) {
      // 错误处理
      session.setError(e.toString());
      final message = await _db.getUnifiedMessage(assistantMessageId);
      if (message != null) {
        message.status = 'error';
        message.errorMessage = e.toString();
        message.content = fullContent.isEmpty ? '请求失败: $e' : fullContent;
        await _db.saveUnifiedMessage(message);
      }
      rethrow;
    }
  }

  /// 格式化消息为 API 格式
  Future<List<Map<String, String>>> formatMessagesForApi(
    String conversationId,
  ) async {
    final messages = await getMessages(conversationId);
    return messages.map((m) => {'role': m.role, 'content': m.content}).toList();
  }

  // ============ 便捷方法 ============

  /// 创建独立对话
  Future<String> createTopicConversation({
    required String title,
    String? initialMessage,
  }) async {
    return createConversation(
      title: title,
      contextType: ConversationContextType.topic,
      initialUserMessage: initialMessage,
    );
  }

  /// 创建消息组分析对话
  Future<String> createMessageGroupAnalysis({
    required String topicId,
    required int groupIndex,
    required String contextSnapshot,
    String? initialPrompt,
  }) async {
    return createConversation(
      title: '分析 - 第 ${groupIndex + 1} 轮对话',
      contextType: ConversationContextType.messageGroup,
      contextId: '$topicId:$groupIndex',
      contextSnapshot: contextSnapshot,
      initialUserMessage: initialPrompt,
    );
  }

  /// 创建单消息讨论对话
  Future<String> createSingleMessageDiscussion({
    required String messageId,
    required String contextSnapshot,
    String title = '讨论',
    String? initialMessage,
  }) async {
    return createConversation(
      title: title,
      contextType: ConversationContextType.singleMessage,
      contextId: messageId,
      contextSnapshot: contextSnapshot,
      initialUserMessage: initialMessage,
    );
  }

  // ============ 重试/重新生成 ============

  /// 重新生成 assistant 消息（重试）
  ///
  /// 参考 Cherry Studio 的 regenerateAssistantResponseThunk
  /// 1. 通过 askId 找到对应的用户消息
  /// 2. 构建 context（到用户消息为止）
  /// 3. 重置 assistant 消息状态
  /// 4. 重新调用 API
  Stream<String> regenerateAssistantMessage(String messageId) async* {
    // 1. 获取要重试的消息
    final message = await _db.getUnifiedMessage(messageId);
    if (message == null) {
      throw Exception('消息不存在: $messageId');
    }
    if (message.role != 'assistant') {
      throw Exception('只能重试 assistant 消息');
    }

    final conversationId = message.conversationId;
    final askId = message.askId;

    if (askId == null) {
      throw Exception('消息没有关联的用户问题（askId 为空）');
    }

    // 2. 获取配置
    final config = AIProviderService.instance.getActiveConfig();
    if (config == null) {
      throw Exception('请先配置 AI Provider');
    }

    // 3. 获取对话消息，构建 context
    final allMessages = await getMessages(conversationId);

    // 找到用户消息的位置
    final userMessageIndex = allMessages.indexWhere((m) => m.messageId == askId);
    if (userMessageIndex == -1) {
      throw Exception('找不到关联的用户消息');
    }

    // 取到用户消息为止的所有消息（包含用户消息）
    final contextMessages = allMessages.sublist(0, userMessageIndex + 1);

    // 4. 构建 API 消息列表（按主线过滤）
    final apiMessages = <Map<String, String>>[];

    // 添加 System Prompt（如果有）
    final preference = await PromptTemplateService.instance.getActivePreference();
    if (preference != null && preference.systemPrompt.isNotEmpty) {
      apiMessages.add({
        'role': 'system',
        'content': preference.systemPrompt,
      });
    }

    // 按 askId 分组找出主线消息
    final mainlineAssistantIds = <String>{};
    final assistantsByAskId = <String, List<UnifiedMessageEntity>>{};

    for (final m in contextMessages) {
      if (m.role == 'assistant' && m.askId != null) {
        assistantsByAskId.putIfAbsent(m.askId!, () => []).add(m);
      }
    }

    for (final entry in assistantsByAskId.entries) {
      final group = entry.value;
      final mainline = group.firstWhere(
        (m) => m.isMainline,
        orElse: () => group.first,
      );
      mainlineAssistantIds.add(mainline.messageId);
    }

    // 构建消息列表
    for (final m in contextMessages) {
      if (m.role == 'system') {
        apiMessages.add({'role': 'user', 'content': m.content});
      } else if (m.role == 'user') {
        apiMessages.add({'role': 'user', 'content': m.content});
      } else if (m.role == 'assistant') {
        if (m.askId == null || mainlineAssistantIds.contains(m.messageId)) {
          apiMessages.add({'role': 'assistant', 'content': m.content});
        }
      }
    }

    // 5. 重置消息状态
    final resetMessage = UnifiedMessageEntity.resetForRetry(message);
    await _db.saveUnifiedMessage(resetMessage);

    // 6. 创建 StreamingSession（支持后台继续运行）
    final sessionManager = StreamingSessionManager.instance;
    final session = sessionManager.createSession(
      conversationId: conversationId,
      messageId: messageId,
    );

    // 7. 调用 API
    final service = OpenAIService(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
    );

    var fullContent = '';
    try {
      await for (final chunk in service.streamChatCompletion(
        model: message.modelId ?? config.modelId,
        messages: apiMessages,
      )) {
        fullContent += chunk;

        // 更新 session（支持后台继续和重新连接）
        session.appendContent(chunk);

        yield chunk;

        // 更新数据库
        await updateMessageContent(
          messageId,
          fullContent,
          status: 'streaming',
        );
      }

      // 完成
      session.complete();
      await updateMessageContent(
        messageId,
        fullContent,
        status: 'completed',
      );
    } catch (e) {
      // 错误处理
      session.setError(e.toString());
      final msg = await _db.getUnifiedMessage(messageId);
      if (msg != null) {
        msg.status = 'error';
        msg.errorMessage = e.toString();
        msg.content = fullContent.isEmpty ? '请求失败: $e' : fullContent;
        await _db.saveUnifiedMessage(msg);
      }
      rethrow;
    }
  }

  // ============ 主线管理 ============

  /// 将指定消息设为主线
  ///
  /// 同一 askId 组中只能有一个主线消息
  /// 设置新主线时会自动取消同组其他消息的主线状态
  Future<void> setAsMainline(String messageId) async {
    // 1. 获取要设为主线的消息
    final message = await _db.getUnifiedMessage(messageId);
    if (message == null) {
      throw Exception('消息不存在: $messageId');
    }
    if (message.role != 'assistant') {
      throw Exception('只有 assistant 消息可以设为主线');
    }
    if (message.askId == null) {
      throw Exception('消息没有关联的用户问题（askId 为空）');
    }

    // 2. 获取同组的所有消息
    final allMessages = await getMessages(message.conversationId);
    final sameGroupMessages = allMessages.where(
      (m) => m.role == 'assistant' && m.askId == message.askId,
    ).toList();

    // 3. 批量更新：取消其他消息的主线状态，设置新主线
    for (final m in sameGroupMessages) {
      final shouldBeMainline = m.messageId == messageId;
      if (m.isMainline != shouldBeMainline) {
        m.isMainline = shouldBeMainline;
        await _db.saveUnifiedMessage(m);
      }
    }
  }

  // ============ 消息删除 ============

  /// 删除指定的 assistant 消息
  ///
  /// 如果删除的是主线消息，会自动将同组第一个剩余消息设为主线
  Future<void> deleteAssistantMessage(String messageId) async {
    // 1. 获取要删除的消息
    final message = await _db.getUnifiedMessage(messageId);
    if (message == null) {
      throw Exception('消息不存在: $messageId');
    }
    if (message.role != 'assistant') {
      throw Exception('只能删除 assistant 消息');
    }

    final conversationId = message.conversationId;
    final askId = message.askId;
    final wasMainline = message.isMainline;

    // 2. 删除消息
    await _db.deleteUnifiedMessage(messageId);

    // 3. 如果删除的是主线消息，需要选出新的主线
    if (wasMainline && askId != null) {
      final allMessages = await getMessages(conversationId);
      final remainingGroup = allMessages.where(
        (m) => m.role == 'assistant' && m.askId == askId,
      ).toList();

      // 如果还有剩余消息，将第一个设为主线
      if (remainingGroup.isNotEmpty) {
        final newMainline = remainingGroup.first;
        newMainline.isMainline = true;
        await _db.saveUnifiedMessage(newMainline);
      }
    }

    // 4. 更新对话的消息计数
    final allMessages = await getMessages(conversationId);
    final conversation = await _db.getUnifiedConversation(conversationId);
    if (conversation != null) {
      conversation.messageCount = allMessages.length;
      await _db.saveUnifiedConversation(conversation);
    }
  }
}
