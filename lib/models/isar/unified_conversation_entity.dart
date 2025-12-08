import 'package:isar_community/isar.dart';

part 'unified_conversation_entity.g.dart';

/// 对话上下文类型
///
/// 用于区分不同场景的对话：
/// - topic: 完整的独立对话（新的 AI 对话）
/// - messageGroup: 某一轮对话的分析（原 AI 分析功能）
/// - singleMessage: 针对单个 AI 回复的讨论（原讨论功能）
enum ConversationContextType {
  topic,         // 独立对话
  messageGroup,  // 消息组分析
  singleMessage, // 单消息讨论
}

/// 统一对话实体
///
/// 将原有的 DiscussionEntity 和 AIAnalysisEntity 统一为一种数据结构
/// 通过 contextType 和 contextId 区分不同场景
@collection
class UnifiedConversationEntity {
  Id id = Isar.autoIncrement;

  /// 对话唯一 ID（UUID）
  @Index(unique: true)
  late String conversationId;

  /// 对话标题
  late String title;

  /// 上下文类型
  @Enumerated(EnumType.name)
  late ConversationContextType contextType;

  /// 上下文 ID
  /// - topic: 为空或自定义标识
  /// - messageGroup: topicId:groupIndex 格式
  /// - singleMessage: messageId
  @Index()
  late String contextId;

  /// 上下文快照（可选）
  /// 用于保存创建对话时的原始上下文内容
  String? contextSnapshot;

  /// 使用的 Provider ID（可选）
  String? providerId;

  /// 使用的 Model ID（可选）
  String? modelId;

  /// 消息数量
  late int messageCount;

  /// 对话轮数（用户消息数量）
  late int roundCount;

  /// 创建时间戳（毫秒）
  @Index()
  late int createdAt;

  /// 更新时间戳（毫秒）
  late int updatedAt;

  /// 是否已归档
  late bool isArchived;

  /// 是否置顶
  late bool isPinned;

  /// 创建实体
  static UnifiedConversationEntity create({
    required String conversationId,
    required String title,
    required ConversationContextType contextType,
    required String contextId,
    String? contextSnapshot,
    String? providerId,
    String? modelId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return UnifiedConversationEntity()
      ..conversationId = conversationId
      ..title = title
      ..contextType = contextType
      ..contextId = contextId
      ..contextSnapshot = contextSnapshot
      ..providerId = providerId
      ..modelId = modelId
      ..messageCount = 0
      ..roundCount = 0
      ..createdAt = now
      ..updatedAt = now
      ..isArchived = false
      ..isPinned = false;
  }
}

/// 统一对话消息实体
@collection
class UnifiedMessageEntity {
  Id id = Isar.autoIncrement;

  /// 消息唯一 ID（UUID）
  @Index(unique: true)
  late String messageId;

  /// 所属对话 ID
  @Index()
  late String conversationId;

  /// 角色：user / assistant / system
  late String role;

  /// 消息内容（Markdown 格式）
  /// 对于 user 消息，这是组装后的完整内容（发送给 API）
  late String content;

  /// 使用的 Model ID（assistant 消息）
  String? modelId;

  /// 使用的 Model 名称（assistant 消息）
  String? modelName;

  /// 关联的用户问题 ID（assistant 消息专用）
  /// 指向触发这个回复的用户消息的 messageId
  /// 同一用户问题的多个回复共享相同的 askId
  @Index()
  String? askId;

  /// 是否为主线回复（assistant 消息专用）
  /// 同一 askId 组中只能有一个 isMainline = true
  /// 用于构建下一轮对话的 context
  late bool isMainline;

  /// Token 使用情况（JSON）
  String? usageJson;

  /// 创建时间戳（毫秒）
  @Index()
  late int createdAt;

  /// 消息状态：pending / streaming / completed / error
  late String status;

  /// 错误信息（如果有）
  String? errorMessage;

  // ============ 结构化消息字段（用于 UI 展示）============

  /// 使用的模版 ID（user 消息）
  String? templateId;

  /// 模版名称快照（用于展示，即使模版被删除也能显示）
  String? templateName;

  /// 模版内容快照（用于展示）
  String? templateSnapshot;

  /// 上下文摘要（用于展示，如"3条模型回复"）
  String? contextSummary;

  /// 上下文内容（完整的上下文材料）
  String? contextContent;

  /// 用户追加问题（用户实际输入的那部分）
  String? userQuery;

  /// 结构化上下文数据（JSON格式）
  /// 保存用户的选择信息，如：
  /// - 单回复: {"type": "single", "modelName": "GPT-4", "charCount": 1234}
  /// - 多轮: {"type": "multi", "rounds": [{"index": 0, "replyCount": 2}, ...], "totalReplies": 5}
  String? contextDataJson;

  /// 创建用户消息
  static UnifiedMessageEntity createUserMessage({
    required String messageId,
    required String conversationId,
    required String content,
    // 结构化字段（可选）
    String? templateId,
    String? templateName,
    String? templateSnapshot,
    String? contextSummary,
    String? contextContent,
    String? userQuery,
    String? contextDataJson,
  }) {
    return UnifiedMessageEntity()
      ..messageId = messageId
      ..conversationId = conversationId
      ..role = 'user'
      ..content = content
      ..templateId = templateId
      ..templateName = templateName
      ..templateSnapshot = templateSnapshot
      ..contextSummary = contextSummary
      ..contextContent = contextContent
      ..userQuery = userQuery
      ..contextDataJson = contextDataJson
      ..isMainline = false  // 用户消息不参与主线选择
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..status = 'completed';
  }

  /// 创建结构化用户消息（从积木组装）
  ///
  /// 根据模版、上下文和用户问题自动组装完整内容
  static UnifiedMessageEntity createStructuredUserMessage({
    required String messageId,
    required String conversationId,
    String? templateId,
    String? templateName,
    String? templateContent,
    String? contextSummary,
    String? contextContent,
    String? userQuery,
    String? contextDataJson,
  }) {
    // 组装完整的消息内容
    final buffer = StringBuffer();

    if (templateContent != null && templateContent.isNotEmpty) {
      buffer.write(templateContent);
    }

    if (contextContent != null && contextContent.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(contextContent);
    }

    if (userQuery != null && userQuery.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(userQuery);
    }

    return UnifiedMessageEntity()
      ..messageId = messageId
      ..conversationId = conversationId
      ..role = 'user'
      ..content = buffer.toString()
      ..templateId = templateId
      ..templateName = templateName
      ..templateSnapshot = templateContent
      ..contextSummary = contextSummary
      ..contextContent = contextContent
      ..userQuery = userQuery
      ..contextDataJson = contextDataJson
      ..isMainline = false  // 用户消息不参与主线选择
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..status = 'completed';
  }

  /// 创建助手消息
  ///
  /// [askId] 关联的用户问题 ID，指向触发这个回复的用户消息
  /// [isMainline] 是否为主线回复，默认为 true（第一个回复自动成为主线）
  static UnifiedMessageEntity createAssistantMessage({
    required String messageId,
    required String conversationId,
    String content = '',
    String? modelId,
    String? modelName,
    String? askId,
    bool isMainline = true,
    String status = 'pending',
  }) {
    return UnifiedMessageEntity()
      ..messageId = messageId
      ..conversationId = conversationId
      ..role = 'assistant'
      ..content = content
      ..modelId = modelId
      ..modelName = modelName
      ..askId = askId
      ..isMainline = isMainline
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..status = status;
  }

  /// 创建系统消息（用于存储上下文）
  static UnifiedMessageEntity createSystemMessage({
    required String messageId,
    required String conversationId,
    required String content,
  }) {
    return UnifiedMessageEntity()
      ..messageId = messageId
      ..conversationId = conversationId
      ..role = 'system'
      ..content = content
      ..isMainline = false  // 系统消息不参与主线选择
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..status = 'completed';
  }

  /// 重置 assistant 消息（用于重试）
  ///
  /// 清空内容，重置状态，保持 id 和 askId 不变
  /// 参考 Cherry Studio 的 resetAssistantMessage 实现
  static UnifiedMessageEntity resetForRetry(UnifiedMessageEntity original) {
    if (original.role != 'assistant') {
      throw ArgumentError('只能重置 assistant 消息');
    }

    return UnifiedMessageEntity()
      // 保持身份标识不变
      ..messageId = original.messageId
      ..conversationId = original.conversationId
      ..role = 'assistant'
      ..askId = original.askId
      ..isMainline = original.isMainline
      // 保持模型信息
      ..modelId = original.modelId
      ..modelName = original.modelName
      // 重置内容和状态
      ..content = ''
      ..status = 'pending'
      ..errorMessage = null
      // 保持时间戳
      ..createdAt = original.createdAt;
  }
}
