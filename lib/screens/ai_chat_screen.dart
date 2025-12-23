import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../models/isar/prompt_template_entity.dart';
import '../models/structured_context.dart';
import '../services/unified_conversation_service.dart';
import '../services/ai_provider_service.dart';
import '../services/prompt_template_service.dart';
import '../services/multi_model_service.dart' as multi_model;
import '../services/streaming_session_manager.dart';
import '../services/topic_service.dart';
import '../utils/mention_parser.dart';
import '../widgets/unified_markdown_renderer.dart';
import '../widgets/context_selector.dart' show TopicSummary;
import '../widgets/context_selector_with_styles.dart' show ContextSelectorWithStyles;
import '../widgets/context_structure_view.dart';
import '../widgets/provider_chip.dart';
import '../widgets/ai_chat_drawer.dart';
import '../widgets/model_selector.dart';
import '../widgets/multi_model_response_view.dart';
import '../providers/tts_provider.dart';
import '../models/tts_item.dart';
import '../widgets/tts_mini_player.dart';
import 'package:provider/provider.dart';

/// AI 对话界面 (重构版)
///
/// 设计理念：
/// - Context Banner 常驻顶部，始终可见
/// - Provider 显示在 AppBar，触手可及
/// - 对话历史放入右侧抽屉，减少干扰
/// - 统一的对话界面，无模式切换
class AIChatScreen extends StatefulWidget {
  /// 初始对话 ID（可选）
  final String? initialConversationId;

  /// 上下文类型过滤（可选）
  final ConversationContextType? contextTypeFilter;

  /// 初始上下文信息（用于创建新对话）
  final String? initialContextId;
  final String? initialContextSnapshot;
  final String? initialTitle;

  /// 原始上下文数据（结构化数据，包含轮次、回复、useful字段等）
  final Map<String, dynamic>? initialContextData;

  const AIChatScreen({
    Key? key,
    this.initialConversationId,
    this.contextTypeFilter,
    this.initialContextId,
    this.initialContextSnapshot,
    this.initialTitle,
    this.initialContextData,
  }) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _service = UnifiedConversationService.instance;
  final _templateService = PromptTemplateService.instance;
  final _multiModelService = multi_model.MultiModelService.instance;
  final _sessionManager = StreamingSessionManager.instance;
  final _mentionParser = MentionParser();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Session 订阅（用于监听后台继续的流式响应）
  StreamSubscription<String>? _sessionContentSubscription;
  StreamSubscription<StreamingSessionStatus>? _sessionStatusSubscription;

  // 重试订阅（用于监听多模型重试的流式响应）
  StreamSubscription<String>? _retrySubscription;

  List<UnifiedConversationEntity> _conversations = [];
  String? _activeConversationId;
  List<UnifiedMessageEntity> _messages = [];

  // 模版相关
  List<TaskTemplateEntity> _templates = [];
  TaskTemplateEntity? _selectedTemplate;
  String? _defaultTemplateId;  // 默认模板 ID

  bool _isLoading = true;
  bool _isSending = false;
  String _streamingContent = '';

  // @mention 和多模型相关
  OverlayEntry? _modelSelectorOverlay;
  List<Map<String, dynamic>> _modelSuggestions = [];
  String _currentMentionQuery = '';

  // 多模型响应
  Map<String, multi_model.ModelResponse>? _multiModelResponses;
  bool _isMultiModelMode = false;

  // 保存最后一次多模型调用的消息列表（用于重试）
  List<Map<String, String>>? _lastMultiModelMessages;

  // 保存最后一条用户消息 ID（用于重试时设置 askId）
  String? _lastUserMessageId;

  // 当前对话的上下文
  String? _currentContextContent;
  String? _currentContextSummary;

  // 解析后的结构化上下文（用于 UI 展示）
  StructuredContext? _structuredContext;

  // 基于用户选择生成的 contextDataJson（来自 ContextSelector）
  String? _selectedContextDataJson;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupInputListener();
  }

  @override
  void dispose() {
    // 取消所有订阅（但不取消后台任务）
    _sessionContentSubscription?.cancel();
    _sessionStatusSubscription?.cancel();
    _retrySubscription?.cancel();
    _hideModelSelectorOverlay();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// 检查并重新连接到活跃的 session
  ///
  /// 当用户返回到之前离开的对话时，如果后台有正在运行的流式响应，
  /// 可以重新连接并继续显示
  void _checkAndReconnectSession(String conversationId) {
    // 先取消之前的订阅
    _sessionContentSubscription?.cancel();
    _sessionStatusSubscription?.cancel();

    final session = _sessionManager.getSession(conversationId);
    if (session == null) return;

    if (session.isActive) {
      // 有活跃的 session，重新连接
      setState(() {
        _isSending = true;
        _streamingContent = session.content;
      });

      // 监听后续内容
      _sessionContentSubscription = session.contentStream.listen(
        (content) {
          if (mounted) {
            setState(() {
              _streamingContent = content;
            });
            _scrollToBottom();
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isSending = false;
              _streamingContent = '';
            });
          }
        },
      );

      // 监听状态变化
      _sessionStatusSubscription = session.statusStream.listen(
        (status) {
          if (mounted && status != StreamingSessionStatus.streaming) {
            setState(() {
              _isSending = false;
              _streamingContent = '';
            });
            // 刷新消息列表
            _loadMessages();
          }
        },
      );
    } else if (session.status == StreamingSessionStatus.completed) {
      // Session 已完成，刷新消息列表即可
      _loadMessages();
    }
  }

  /// 设置输入监听器，检测 @mention
  void _setupInputListener() {
    _inputController.addListener(_onInputChanged);
  }

  /// 输入变化回调
  void _onInputChanged() {
    final text = _inputController.text;
    final selection = _inputController.selection;

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _hideModelSelectorOverlay();
      return;
    }

    final cursorPosition = selection.baseOffset;
    final suggestions = _mentionParser.getSuggestions(text, cursorPosition);

    if (suggestions != null && suggestions.suggestions.isNotEmpty) {
      setState(() {
        _modelSuggestions = suggestions.suggestions;
        _currentMentionQuery = suggestions.query;
      });
      _showModelSelectorOverlay();
    } else {
      _hideModelSelectorOverlay();
    }
  }

  /// 显示模型选择器 Overlay
  void _showModelSelectorOverlay() {
    _hideModelSelectorOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _modelSelectorOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 120, // 输入框上方
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: ModelSelectorPopup(
            initialQuery: _currentMentionQuery,
            onSelect: _handleModelSelect,
            onCancel: _hideModelSelectorOverlay,
            maxHeight: 280,
          ),
        ),
      ),
    );

    overlay.insert(_modelSelectorOverlay!);
  }

  /// 隐藏模型选择器 Overlay
  void _hideModelSelectorOverlay() {
    _modelSelectorOverlay?.remove();
    _modelSelectorOverlay = null;
  }

  /// 处理模型选择
  void _handleModelSelect(Map<String, dynamic> model) {
    final text = _inputController.text;
    final selection = _inputController.selection;

    if (!selection.isValid) {
      _hideModelSelectorOverlay();
      return;
    }

    final result = _mentionParser.insertModel(
      text,
      selection.baseOffset,
      model,
    );

    _inputController.text = result.text;
    _inputController.selection = TextSelection.collapsed(
      offset: result.cursorPosition,
    );

    _hideModelSelectorOverlay();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 并行加载
      await Future.wait([
        _loadConversations(),
        _loadTemplates(),
      ]);

      // 设置初始上下文
      if (widget.initialContextSnapshot != null) {
        // 【修复】如果设置了 selectOnlyReplyIndex，用占位内容初始化
        // 等待 context selector 回调更新为正确的选中内容
        final selectOnlyReplyIndex = widget.initialContextData?['selectOnlyReplyIndex'] as int?;
        if (selectOnlyReplyIndex != null) {
          // 尝试从 contextData 中提取指定回复的内容作为初始值
          _currentContextContent = _extractReplyContent(selectOnlyReplyIndex);
        } else {
          _currentContextContent = widget.initialContextSnapshot;
        }

        _currentContextSummary = _generateContextSummary(
          _currentContextContent ?? '',
        );
        // 解析为结构化上下文
        _structuredContext = StructuredContext.parse(
          widget.initialContextSnapshot!,
          widget.contextTypeFilter ?? ConversationContextType.topic,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 从 contextData 中提取指定索引的回复内容
  String? _extractReplyContent(int replyIndex) {
    final contextData = widget.initialContextData;
    if (contextData == null) return null;

    final rounds = contextData['rounds'] as List<dynamic>?;
    if (rounds == null || rounds.isEmpty) return null;

    // 获取当前轮次
    final currentRoundIndex = contextData['currentRoundIndex'] as int? ?? 0;
    if (currentRoundIndex >= rounds.length) return null;

    final round = rounds[currentRoundIndex] as Map<String, dynamic>?;
    if (round == null) return null;

    final replies = round['replies'] as List<dynamic>?;
    if (replies == null || replyIndex >= replies.length) return null;

    final reply = replies[replyIndex] as Map<String, dynamic>?;
    if (reply == null) return null;

    // 提取回复内容
    final blocks = reply['blocks'] as List<dynamic>?;
    if (blocks == null) return null;

    final buffer = StringBuffer();
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        buffer.write(block['content'] as String? ?? '');
      }
    }

    final content = buffer.toString();
    if (content.isEmpty) return null;

    // 格式化为 markdown
    final model = reply['model'] as Map<String, dynamic>?;
    final modelName = model?['name'] as String? ?? 'AI';
    return '## 模型回复\n\n### $modelName\n\n$content';
  }

  Future<void> _loadConversations() async {
    // 根据是否有 contextId 决定过滤方式
    if (widget.initialContextId != null) {
      _conversations = await _service.getConversationsByContext(
        widget.initialContextId!,
      );
    } else if (widget.initialConversationId != null) {
      final conv = await _service.getConversation(widget.initialConversationId!);
      if (conv != null && conv.contextId.isNotEmpty) {
        _conversations = await _service.getConversationsByContext(conv.contextId);
      } else {
        _conversations = await _service.getConversations(
          contextType: widget.contextTypeFilter,
        );
      }
    } else {
      _conversations = await _service.getConversations(
        contextType: widget.contextTypeFilter,
      );
    }

    // 设置初始对话
    if (widget.initialConversationId != null) {
      _activeConversationId = widget.initialConversationId;
    } else if (_conversations.isNotEmpty) {
      _activeConversationId = _conversations.first.conversationId;
    }

    // 不再在初始化时创建空对话，延迟到用户发送消息时创建

    if (_activeConversationId != null) {
      await _loadMessages();
    }
  }

  Future<void> _loadTemplates() async {
    _templates = await _templateService.getAllTemplates();

    // 获取默认模板 ID
    final preference = await _templateService.getActivePreference();
    _defaultTemplateId = preference?.defaultTemplateId;

    // 如果是新对话（没有消息），加载默认模板
    final hasUserMessage = _messages.any((m) => m.role == 'user');
    if (!hasUserMessage) {
      _selectedTemplate = await _templateService.getDefaultTemplate();
    } else {
      // 已有对话历史，不使用模板
      _selectedTemplate = null;
    }
  }

  Future<void> _loadMessages() async {
    if (_activeConversationId == null) return;

    final messages = await _service.getMessages(_activeConversationId!);

    // 从对话中加载上下文
    final conversation = await _service.getConversation(_activeConversationId!);
    StructuredContext? structuredContext;
    String? contextContent;
    String? contextSummary;

    if (conversation?.contextSnapshot != null) {
      contextContent = conversation!.contextSnapshot;
      contextSummary = _generateContextSummary(conversation.contextSnapshot!);
      structuredContext = StructuredContext.parse(
        conversation.contextSnapshot!,
        conversation.contextType,
      );
    }

    setState(() {
      _messages = messages;
      _currentContextContent = contextContent;
      _currentContextSummary = contextSummary;
      _structuredContext = structuredContext;
    });

    // 检查是否有后台继续运行的流式响应，如果有则重新连接
    _checkAndReconnectSession(_activeConversationId!);

    _scrollToBottom();
  }

  String _generateContextSummary(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).length;
    final chars = content.length;
    if (chars > 1024) {
      return '$lines 段内容 (${(chars / 1024).toStringAsFixed(1)}KB)';
    }
    return '$lines 段内容 ($chars 字符)';
  }

  /// 生成结构化的 context 数据 JSON
  ///
  /// 根据 contextType 生成不同的结构：
  /// - singleMessage: {"type": "single", "modelName": "GPT-4", "charCount": 1234}
  /// - messageGroup: {"type": "multi", "rounds": [...], "charCount": 5678}
  ///
  /// rounds 结构增强版（包含问题预览和每个回复的详细信息）：
  /// {"index": 0, "questionPreview": "...", "replies": [{"model": "GPT-4", "charCount": 1234}, ...]}
  ///
  /// 重要：对于 messageGroup 类型，优先使用 ContextSelector 生成的选择数据，
  /// 而不是原始的 initialContextData（解决用户选择后显示全部轮次的问题）
  String? _generateContextDataJson() {
    final contextData = widget.initialContextData;
    if (contextData == null) return null;

    final contextType = widget.contextTypeFilter ?? ConversationContextType.topic;
    final charCount = _currentContextContent?.length ?? 0;

    // 【修复】如果用户已清空选择（_currentContextContent 为空），返回 null
    // 避免回退到原始数据导致显示全部内容
    if (_currentContextContent == null || _currentContextContent!.isEmpty) {
      return null;
    }

    // 对于多轮对话，必须使用 ContextSelector 生成的选择数据
    // 如果 _selectedContextDataJson 为 null，说明用户没有选择任何内容，返回 null
    if (contextType == ConversationContextType.messageGroup) {
      return _selectedContextDataJson;  // 可能为 null，这是预期行为
    }

    if (contextType == ConversationContextType.singleMessage) {
      // 单回复模式
      String? modelName;
      int replyCharCount = 0;
      final rounds = contextData['rounds'] as List?;
      if (rounds != null && rounds.isNotEmpty) {
        final replies = rounds[0]['replies'] as List?;
        if (replies != null && replies.isNotEmpty) {
          modelName = replies[0]['model']?['name'] as String?;
          // 计算回复字数
          final blocks = replies[0]['blocks'] as List? ?? [];
          for (final block in blocks) {
            if (block is Map && block['type'] == 'main_text') {
              replyCharCount += (block['content'] as String?)?.length ?? 0;
            }
          }
        }
      }
      return '{"type":"single","modelName":"${_escapeJson(modelName ?? "AI")}","charCount":${replyCharCount > 0 ? replyCharCount : charCount}}';
    }

    return null;
  }

  /// 转义 JSON 字符串中的特殊字符
  String _escapeJson(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// 构建创建对话所需的配置
  ConversationConfig _buildConversationConfig() {
    // 确定对话标题：优先使用模板名，其次使用传入的标题，最后使用默认值
    String title;
    if (_selectedTemplate != null) {
      title = _selectedTemplate!.name;
    } else if (widget.initialTitle != null) {
      title = widget.initialTitle!;
    } else {
      title = '新对话';
    }

    final contextType =
        widget.contextTypeFilter ?? ConversationContextType.topic;

    return ConversationConfig(
      title: title,
      contextType: contextType,
      contextId: widget.initialContextId,
      contextSnapshot: widget.initialContextSnapshot,
    );
  }

  Future<void> _selectConversation(String conversationId) async {
    setState(() {
      _activeConversationId = conversationId;
      _messages = [];
    });
    await _loadMessages();
  }

  Future<void> _sendMessage() async {
    final userQuery = _inputController.text.trim();

    // 检查是否是第一次发送（从编辑器发送）
    final hasUserMessage = _messages.any((m) => m.role == 'user');
    final isFirstSend = !hasUserMessage && widget.initialContextData != null;

    // 第一次发送时，可以没有追加问题
    if (!isFirstSend && userQuery.isEmpty) return;
    if (_isSending) return;

    // 解析 @mention
    final parseResult = _mentionParser.parse(userQuery);
    final hasMultipleModels = parseResult.mentionedModels.length > 1;

    // 懒创建：不在这里创建对话，而是在发送方法中处理
    // 如果没有活跃对话，准备对话配置供发送方法使用
    final isNewConversation = _activeConversationId == null;
    final conversationConfig = isNewConversation ? _buildConversationConfig() : null;

    _inputController.clear();
    _hideModelSelectorOverlay();

    setState(() {
      _isSending = true;
      _streamingContent = '';
      _isMultiModelMode = hasMultipleModels;
      _multiModelResponses = null;
    });

    try {
      // 确定实际的用户追加问题（去除 @mention 后的纯文本）
      String? effectiveUserQuery;
      if (isFirstSend) {
        final presetUserQuery = widget.initialContextData?['userQuery'] as String?;
        effectiveUserQuery = parseResult.cleanText.isNotEmpty
            ? parseResult.cleanText
            : presetUserQuery;
      } else {
        effectiveUserQuery = parseResult.cleanText;
      }

      // 生成结构化的 contextDataJson
      String? contextDataJson;
      if (isFirstSend && widget.initialContextData != null) {
        contextDataJson = _generateContextDataJson();
      }

      if (hasMultipleModels) {
        // 多模型并行调用
        await _sendMultiModelMessage(
          parseResult: parseResult,
          effectiveUserQuery: effectiveUserQuery,
          contextDataJson: contextDataJson,
          conversationConfig: conversationConfig,
        );
      } else {
        // 单模型调用（可能使用 @mention 指定的单个模型，或默认模型）
        await _sendSingleModelMessage(
          parseResult: parseResult,
          effectiveUserQuery: effectiveUserQuery,
          contextDataJson: contextDataJson,
          conversationConfig: conversationConfig,
        );
      }

      // 重新加载消息和对话列表
      await _loadMessages();
      await _loadConversations();

      // 第一次发送后清除模板（模板只用于第一轮）
      if (mounted) {
        setState(() {
          _selectedTemplate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 检查 mounted 再 setState（后台任务会继续运行）
      if (mounted) {
        setState(() {
          _isSending = false;
          _streamingContent = '';
        });
      }
    }
  }

  /// 单模型调用（支持懒创建）
  Future<void> _sendSingleModelMessage({
    required MentionParseResult parseResult,
    String? effectiveUserQuery,
    String? contextDataJson,
    ConversationConfig? conversationConfig,
  }) async {
    // 如果指定了单个模型，临时切换 Provider
    String? originalProviderId;
    String? originalModelId;

    if (parseResult.mentionedModels.length == 1) {
      final mentioned = parseResult.mentionedModels.first;
      final providerService = AIProviderService.instance;

      // 保存当前选择
      originalProviderId = providerService.activeProvider?.id;
      originalModelId = providerService.activeModel?.id;

      // 临时切换到指定的模型
      await providerService.setActiveProvider(mentioned.providerId);
      await providerService.setActiveModel(mentioned.modelId);
    }

    try {
      // 使用支持懒创建的新方法
      final result = _service.sendStructuredMessageAndStreamWithLazyCreate(
        conversationId: _activeConversationId,
        conversationConfig: conversationConfig,
        templateId: _selectedTemplate?.templateId,
        contextContent: _currentContextContent,
        contextSummary: _currentContextSummary,
        userQuery: effectiveUserQuery,
        contextDataJson: contextDataJson,
        debugContextData: widget.initialContextData,
      );

      // 如果是新对话，更新 _activeConversationId
      if (_activeConversationId == null) {
        _activeConversationId = result.conversationId;
      }

      await for (final chunk in result.stream) {
        // 如果 widget 已 dispose，流会在后台继续运行
        if (!mounted) break;
        setState(() {
          _streamingContent += chunk;
        });
        _scrollToBottom();
      }
    } finally {
      // 恢复原来的模型选择
      if (originalProviderId != null) {
        final providerService = AIProviderService.instance;
        await providerService.setActiveProvider(originalProviderId);
        if (originalModelId != null) {
          await providerService.setActiveModel(originalModelId);
        }
      }
    }
  }

  /// 多模型并行调用（支持懒创建）
  Future<void> _sendMultiModelMessage({
    required MentionParseResult parseResult,
    String? effectiveUserQuery,
    String? contextDataJson,
    ConversationConfig? conversationConfig,
  }) async {
    // 1. 使用懒创建方法：创建对话（如果需要）并保存用户消息
    final result = await _service.createConversationAndAddUserMessage(
      conversationId: _activeConversationId,
      conversationConfig: conversationConfig,
      templateId: _selectedTemplate?.templateId,
      templateName: _selectedTemplate?.name,
      templateContent: _selectedTemplate?.content,
      contextSummary: _currentContextSummary,
      contextContent: _currentContextContent,
      userQuery: effectiveUserQuery,
      contextDataJson: contextDataJson,
    );

    // 如果是新对话，更新 _activeConversationId
    if (_activeConversationId == null) {
      _activeConversationId = result.conversationId;
    }

    // 保存用户消息 ID，用于重试时设置 askId
    _lastUserMessageId = result.userMessageId;

    // 2. 构建发送给 API 的消息列表
    final messages = <Map<String, String>>[];

    // 添加系统消息（如果有模板）
    if (_selectedTemplate != null) {
      messages.add({
        'role': 'system',
        'content': _selectedTemplate!.content,
      });
    }

    // 添加上下文（如果有）
    if (_currentContextContent != null && _currentContextContent!.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': '以下是需要分析的内容:\n\n$_currentContextContent',
      });
    }

    // 添加用户问题
    if (effectiveUserQuery != null && effectiveUserQuery.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': effectiveUserQuery,
      });
    }

    // 保存消息列表，用于重试
    _lastMultiModelMessages = messages;

    // 3. 调用多模型服务
    final responses = await _multiModelService.callMultipleModels(
      modelConfigs: parseResult.modelConfigs,
      messages: messages,
    );

    // 【修复】检查 mounted 再 setState
    if (!mounted) return;

    setState(() {
      _multiModelResponses = responses;
    });

    // 4. 等待所有模型完成
    await Future.wait(
      responses.values.map((r) => r.contentStream.last.catchError((_) => '')),
    );

    // 5. 保存所有 AI 回复到数据库
    // 第一个成功的回复设为主线，其他设为非主线
    bool isFirstSuccess = true;
    for (final entry in responses.entries) {
      final response = entry.value;
      if (response.fullContent.isNotEmpty && response.error == null) {
        await _service.addAssistantMessage(
          result.conversationId,
          response.fullContent,
          modelId: response.modelId,
          modelName: response.modelName,
          askId: result.userMessageId,  // 设置 askId 关联到用户问题
          isMainline: isFirstSuccess,  // 第一个成功的回复是主线
        );
        isFirstSuccess = false;
      }
    }

    // 6. 清空临时展示数据（已保存到数据库）
    // 【修复】检查 mounted 再 setState
    if (!mounted) return;

    setState(() {
      _multiModelResponses = null;
      _isMultiModelMode = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteConversation(String conversationId) async {
    await _service.deleteConversation(conversationId);
    if (_activeConversationId == conversationId) {
      _activeConversationId = null;
      _messages = [];
    }
    await _loadConversations();
    setState(() {});
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildTemplateSelector(),
    );
  }

  void _showTemplateContent(TaskTemplateEntity template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description, color: Colors.purple[400], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                template.name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              template.content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showContextEditor() {
    // 单回复讨论：直接弹窗预览，不需要编辑器
    if (widget.contextTypeFilter == ConversationContextType.singleMessage) {
      _showContextPreview();
      return;
    }

    // 多轮对话：进入完整的 Context 编辑器
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ContextEditorPage(
            contextData: widget.initialContextData,
            contextSnapshot: _currentContextContent ?? '',
            currentRoundIndex: widget.initialContextData?['currentRoundIndex'],
            contextType: widget.contextTypeFilter ?? ConversationContextType.topic,
            onContextChanged: (newSnapshot, structuredContext, contextDataJson) {
              setState(() {
                _currentContextContent = newSnapshot;
                _currentContextSummary = _generateContextSummary(newSnapshot);
                _structuredContext = structuredContext;
                _selectedContextDataJson = contextDataJson;  // 保存基于选择生成的 JSON
              });
            },
            onClear: () {
              setState(() {
                _structuredContext = null;
                _currentContextContent = null;
                _currentContextSummary = null;
                _selectedContextDataJson = null;  // 清除选择数据
              });
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  /// 单回复预览弹窗
  void _showContextPreview() {
    final content = _currentContextContent ?? widget.initialContextSnapshot ?? '';
    final modelName = widget.initialContextData?['rounds']?[0]?['replies']?[0]?['model']?['name'] ?? '原始回复';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 18, color: Colors.purple[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        modelName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${(content.length / 1000).toStringAsFixed(1)}k 字',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
              // 内容
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    content,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      endDrawer: AIChatDrawer(
        activeConversationId: _activeConversationId,
        contextId: widget.initialContextId,
        onSelectConversation: _selectConversation,
        onNewConversation: () {
          setState(() {
            _activeConversationId = null;
            _messages = [];
          });
        },
        onDeleteConversation: _deleteConversation,
        onOpenSettings: () {
          Navigator.pushNamed(context, '/settings');
        },
        onExport: () {
          // TODO: 实现导出功能
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出功能开发中...')),
          );
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildBody(),
                // TTS 播放控制条（浮动在底部）
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TtsMiniPlayer(),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.initialTitle ?? 'AI 分析',
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        // Provider Chip
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ProviderChip(
            onChanged: () => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),

        // 菜单按钮
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          tooltip: '菜单',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Selector<TtsProvider, bool>(
      selector: (_, tts) => tts.playerState != TtsState.stopped || tts.playlist.isNotEmpty,
      builder: (context, isPlayerVisible, child) {
        return Padding(
          // 为 TtsMiniPlayer 预留空间（只在播放时）
          padding: EdgeInsets.only(bottom: isPlayerVisible ? 80 : 0),
          child: Column(
            children: [
              // 消息区域
              Expanded(child: _buildMessageArea()),

              // 输入区域（包含 Context 按钮）
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  /// 消息展示区
  Widget _buildMessageArea() {
    // 过滤掉系统消息
    final displayMessages = _messages.where((m) => m.role != 'system').toList();

    // 【修复】将消息分组：用户消息独立，同一 askId 的 assistant 消息合并显示
    final groupedItems = _groupMessagesForDisplay(displayMessages);

    // 计算显示项数：分组后的消息 + 正在发送的消息（单模型或多模型）
    final hasStreamingContent = _isSending && !_isMultiModelMode;
    final hasMultiModelContent = _isSending && _isMultiModelMode && _multiModelResponses != null;
    final itemCount = groupedItems.length +
        (hasStreamingContent ? 1 : 0) +
        (hasMultiModelContent ? 1 : 0);

    if (itemCount == 0) {
      return _buildWelcomeView();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 多模型流式消息
        if (index == groupedItems.length && hasMultiModelContent) {
          return _buildMultiModelResponseArea();
        }

        // 单模型流式消息
        if (index == groupedItems.length && hasStreamingContent) {
          return _buildAssistantMessage(
            content: _streamingContent.isEmpty ? '思考中...' : _streamingContent,
            isStreaming: true,
          );
        }

        // 正常消息（分组后的）
        if (index < groupedItems.length) {
          final item = groupedItems[index];

          if (item is _UserMessageItem) {
            return _buildStructuredUserMessage(item.message);
          }

          if (item is _SingleAssistantItem) {
            return _buildAssistantMessage(
              content: item.message.content,
              modelName: item.message.modelName,
              messageId: item.message.messageId,
              askId: item.message.askId,
              isStreaming: false,
            );
          }

          if (item is _MultiAssistantItem) {
            return _buildSavedMultiModelResponses(item.messages);
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// 将消息分组：用户消息独立，同一 askId 的多个 assistant 消息合并
  List<_DisplayItem> _groupMessagesForDisplay(List<UnifiedMessageEntity> messages) {
    final items = <_DisplayItem>[];
    final assistantByAskId = <String, List<UnifiedMessageEntity>>{};
    final processedAskIds = <String>{};

    for (final msg in messages) {
      if (msg.role == 'user') {
        items.add(_UserMessageItem(msg));
      } else if (msg.role == 'assistant') {
        final askId = msg.askId;
        if (askId != null && askId.isNotEmpty) {
          // 有 askId，加入分组
          assistantByAskId.putIfAbsent(askId, () => []).add(msg);
        } else {
          // 没有 askId，独立显示
          items.add(_SingleAssistantItem(msg));
        }
      }
    }

    // 按原始顺序插入分组的 assistant 消息
    final result = <_DisplayItem>[];
    for (final msg in messages) {
      if (msg.role == 'user') {
        result.add(_UserMessageItem(msg));
      } else if (msg.role == 'assistant') {
        final askId = msg.askId;
        if (askId != null && askId.isNotEmpty) {
          // 只在第一次遇到该 askId 时处理
          if (!processedAskIds.contains(askId)) {
            processedAskIds.add(askId);
            final group = assistantByAskId[askId]!;
            if (group.length > 1) {
              // 多个回复，横向显示
              result.add(_MultiAssistantItem(group));
            } else {
              // 只有一个回复，普通显示
              result.add(_SingleAssistantItem(group.first));
            }
          }
          // 后续遇到同一 askId 的消息跳过（已经处理过了）
        } else {
          result.add(_SingleAssistantItem(msg));
        }
      }
    }

    return result;
  }

  /// 已保存的多模型回复横向展示（从数据库加载的）
  Widget _buildSavedMultiModelResponses(List<UnifiedMessageEntity> messages) {
    // 获取 askId（用于追加回复）
    final askId = messages.isNotEmpty ? messages.first.askId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 朗读全部按钮（仅多个回复时显示）
        if (messages.length > 1)
          Selector<TtsProvider, bool>(
            selector: (_, tts) => tts.hasValidConfig,
            builder: (context, hasValidConfig, _) {
              if (!hasValidConfig) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                child: TextButton.icon(
                  onPressed: () => _speakMultipleResponses(messages),
                  icon: const Icon(Icons.headphones, size: 18),
                  label: Text('朗读全部 ${messages.length} 个回复'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              );
            },
          ),
        // 卡片列表
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 已有的回复卡片
                  ...messages.map((msg) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _SavedModelResponseCard(
                        message: msg,
                        onRetry: () => _regenerateMessage(msg.messageId),
                        onCopy: () => _copyToClipboard(msg.content),
                        onQuote: () => _quoteToInput(msg.content),
                        onSetMainline: () => _setAsMainline(msg.messageId),
                        onDelete: () => _deleteAssistantMessage(msg.messageId),
                        onSpeak: () => _speakContent(msg.content, msg.modelName ?? 'AI'),
                      ),
                    );
                  }),
                  // 追加回复按钮
                  if (askId != null)
                    _buildAddReplyCard(askId),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建追加回复卡片（显示在多模型回复列表末尾）
  Widget _buildAddReplyCard(String askId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAddReplyDialog(askId),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '追加回复',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '使用其他模型',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示追加回复的模型选择对话框
  Future<void> _showAddReplyDialog(String askId) async {
    final multiModelService = multi_model.MultiModelService.instance;
    final allModels = multiModelService.getAvailableModels();

    if (allModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的模型，请先配置 AI Provider')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示条
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    '追加模型回复',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 模型列表
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allModels.length,
                itemBuilder: (context, index) {
                  final model = allModels[index];
                  final providerId = model['providerId'] as String;
                  final modelId = model['modelId'] as String;
                  final modelName = model['displayName'] as String? ?? modelId;
                  final providerName = model['providerName'] as String? ?? '';

                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getModelColorByName(modelName).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.smart_toy_outlined,
                        size: 20,
                        color: _getModelColorByName(modelName),
                      ),
                    ),
                    title: Text(
                      modelName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      providerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _addReplyWithModel(askId, providerId, modelId, modelName);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 使用指定模型追加回复
  Future<void> _addReplyWithModel(
    String askId,
    String providerId,
    String modelId,
    String modelName,
  ) async {
    if (_activeConversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有活跃的对话')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _streamingContent = '';
    });

    try {
      await for (final chunk in _service.addReplyToExistingQuestion(
        conversationId: _activeConversationId!,
        askId: askId,
        providerId: providerId,
        modelId: modelId,
      )) {
        if (!mounted) break;
        setState(() {
          _streamingContent += chunk;
        });
        _scrollToBottom();
      }

      // 完成后重新加载消息
      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已追加 $modelName 的回复'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('追加回复失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _streamingContent = '';
        });
      }
    }
  }

  /// 根据模型名称获取颜色
  Color _getModelColorByName(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (name.contains('gpt') || name.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (name.contains('gemini') || name.contains('google')) {
      return const Color(0xFF4285F4);
    } else if (name.contains('qwen') || name.contains('通义')) {
      return const Color(0xFF6366F1);
    } else if (name.contains('deepseek')) {
      return const Color(0xFF06B6D4);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }

  /// 多模型回复展示区域 - Cherry Studio 风格横向布局
  Widget _buildMultiModelResponseArea() {
    if (_multiModelResponses == null || _multiModelResponses!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: MultiModelResponseView(
          responses: _multiModelResponses!,
          onRetry: (modelKey) => _retrySingleModel(modelKey),
          onEdit: (modelKey, content) {
            // TODO: 实现编辑回复
          },
          onDelete: (modelKey) {
            // TODO: 实现删除单个回复
          },
          onModelSelect: (modelKey) {
            // 采纳某个模型的回复
            final response = _multiModelResponses![modelKey];
            if (response != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已采纳 ${response.modelName} 的回复'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// 欢迎视图
  Widget _buildWelcomeView() {
    final providerService = AIProviderService.instance;
    final hasProvider = providerService.activeProvider != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              hasProvider ? '开始分析' : '请先配置 AI Provider',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasProvider
                  ? (_structuredContext != null
                      ? '点击下方发送按钮开始分析'
                      : '在下方输入框中输入消息开始对话')
                  : '点击右上角模型按钮进行配置',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            if (hasProvider) ...[
              const SizedBox(height: 24),
              Text(
                '当前模型: ${providerService.activeModel?.displayName ?? "未选择"}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 结构化用户消息
  ///
  /// 展示结构：
  /// 1. 模板按钮 → 点击弹窗显示模板内容
  /// 2. 要讨论的内容 → 使用 ContextStructureView 原地展开
  /// 3. 追加问题 → 直接显示文字
  Widget _buildStructuredUserMessage(UnifiedMessageEntity message) {
    final hasTemplate = message.templateName != null;
    final hasQuery = message.userQuery != null && message.userQuery!.isNotEmpty;

    // 获取 context
    String? contextContent = message.contextContent;
    UnifiedConversationEntity? conversation;

    try {
      conversation = _conversations.firstWhere(
        (c) => c.conversationId == message.conversationId,
      );
    } catch (_) {
      conversation = _conversations.isNotEmpty ? _conversations.first : null;
    }

    if ((contextContent == null || contextContent.isEmpty) &&
        conversation?.contextSnapshot != null) {
      contextContent = conversation!.contextSnapshot;
    }

    final hasContext = contextContent != null && contextContent.isNotEmpty;

    // 如果没有结构化信息，回退到普通显示
    if (!hasTemplate && !hasContext && !hasQuery) {
      return _buildSimpleUserMessage(message.content);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 模版按钮（点击弹窗查看内容）
                  if (hasTemplate)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTemplateButton(message.templateName!),
                    ),

                  // 2. 要讨论的内容（原地展开树形结构）
                  if (hasContext)
                    ContextStructureView(
                      contextDataJson: message.contextDataJson,
                      contextSnapshot: contextContent,
                    ),

                  // 3. 追加问题（直接显示）
                  if (hasQuery)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: SelectableText(
                          message.userQuery!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.person, size: 18, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  /// 模板按钮（点击弹窗查看模板内容）
  Widget _buildTemplateButton(String templateName) {
    return InkWell(
      onTap: () => _showTemplateContentByName(templateName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 16, color: Colors.purple[700]),
            const SizedBox(width: 8),
            Text(
              '模板',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                templateName,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 14, color: Colors.purple[400]),
          ],
        ),
      ),
    );
  }

  /// 根据模板名称显示模板内容
  void _showTemplateContentByName(String templateName) {
    // 查找模板
    final template = _templates.where((t) => t.name == templateName).firstOrNull;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description, color: Colors.purple[400], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                templateName,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              template?.content ?? '（模板内容不可用）',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleUserMessage(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(content),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.person, size: 18, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  /// AI 回复消息 - Cherry Studio 风格卡片
  Widget _buildAssistantMessage({
    required String content,
    String? modelName,
    String? messageId,
    String? askId,
    bool isStreaming = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modelColor = _getModelColor(modelName ?? 'AI');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 头部：模型名称
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: modelColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: modelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getModelIcon(modelName ?? 'AI'),
                      size: 16,
                      color: modelColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      modelName ?? 'AI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ),
                  if (isStreaming)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(modelColor),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            fontSize: 10,
                            color: modelColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  else
                    Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
                ],
              ),
            ),

            // 内容区域
            Padding(
              padding: const EdgeInsets.all(12),
              child: UnifiedMarkdownRenderer(
                data: content,
                selectable: true,
                textStyle: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: isDark ? Colors.grey[200] : const Color(0xFF2C3E50),
                ),
              ),
            ),

            // 底部操作栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 复制
                  _buildActionIconButton(
                    icon: Icons.copy_outlined,
                    tooltip: '复制',
                    onTap: () => _copyToClipboard(content),
                  ),
                  // 重试（原地重新请求）
                  if (messageId != null)
                    _buildActionIconButton(
                      icon: Icons.refresh_outlined,
                      tooltip: '重试',
                      onTap: () => _regenerateMessage(messageId),
                    ),
                  // 引用到输入框
                  _buildActionIconButton(
                    icon: Icons.format_quote_outlined,
                    tooltip: '引用',
                    onTap: () => _quoteToInput(content),
                  ),
                  // 翻译
                  _buildActionIconButton(
                    icon: Icons.translate_outlined,
                    tooltip: '翻译',
                    onTap: () => _translateContent(content),
                  ),
                  // 编辑
                  _buildActionIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: '编辑',
                    onTap: () => _editMessage(messageId, content),
                  ),
                  // 删除
                  _buildActionIconButton(
                    icon: Icons.delete_outline,
                    tooltip: '删除',
                    onTap: () => _deleteMessage(messageId),
                  ),
                  // 追加回复（使用其他模型）
                  if (askId != null && !isStreaming)
                    _buildActionIconButton(
                      icon: Icons.add_circle_outline,
                      tooltip: '追加回复',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => _showAddReplyDialog(askId),
                    ),

                  const Spacer(),

                  // 字数统计
                  Text(
                    '${content.length}字',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),

                  // 更多
                  _buildActionIconButton(
                    icon: Icons.more_horiz,
                    tooltip: '更多',
                    onTap: () => _showMessageMoreActions(content),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 复制到剪贴板
  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// 朗读单条内容
  void _speakContent(String content, String modelName) {
    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    if (!ttsProvider.hasValidConfig) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置 TTS API')),
      );
      return;
    }

    final item = TtsItem(
      id: 'ai_chat_${content.hashCode}',
      text: content,
      title: modelName,
      author: modelName,
    );
    ttsProvider.setPlaylist([item]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始朗读 $modelName 的回复...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 朗读多个模型的回复（合并成一个文本）
  void _speakMultipleResponses(List<UnifiedMessageEntity> messages) {
    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    if (!ttsProvider.hasValidConfig) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置 TTS API')),
      );
      return;
    }

    if (messages.isEmpty) return;

    final buffer = StringBuffer();
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final modelName = msg.modelName ?? 'AI';
      final isMainline = msg.isMainline == true;

      // 多回复时加提示语
      if (messages.length > 1) {
        if (isMainline) {
          buffer.writeln('$modelName 的主要回复：');
        } else {
          buffer.writeln('$modelName 回复：');
        }
        buffer.writeln();
      }

      buffer.writeln(msg.content);
      buffer.writeln();

      // 回复之间加分隔
      if (i < messages.length - 1) {
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    final combinedContent = buffer.toString().trim();
    final title = messages.length > 1
        ? '${messages.length} 个模型回复'
        : (messages.first.modelName ?? 'AI');

    final item = TtsItem(
      id: 'ai_chat_multi_${combinedContent.hashCode}',
      text: combinedContent,
      title: title,
      author: 'AI 分析',
    );
    ttsProvider.setPlaylist([item]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始朗读 $title...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 重试指定的 assistant 消息（原地重新请求）
  ///
  /// 参考 Cherry Studio 的 regenerateAssistantResponseThunk
  Future<void> _regenerateMessage(String messageId) async {
    // 找到要重试的消息
    final messageIndex = _messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('找不到要重试的消息')),
      );
      return;
    }

    final message = _messages[messageIndex];
    if (message.role != 'assistant') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只能重试 AI 回复')),
      );
      return;
    }

    // 设置状态为正在重试
    setState(() {
      _isSending = true;
      _streamingContent = '';
    });

    try {
      // 调用 service 层的重试方法
      await for (final chunk in _service.regenerateAssistantMessage(messageId)) {
        // 如果 widget 已 dispose，流会在后台继续运行
        if (!mounted) break;
        setState(() {
          _streamingContent += chunk;
        });
        _scrollToBottom();
      }

      // 检查 mounted 再继续
      if (!mounted) return;

      // 完成后刷新消息列表
      await _loadMessages();

      setState(() {
        _isSending = false;
        _streamingContent = '';
      });
    } catch (e) {
      // 检查 mounted 再 setState
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _streamingContent = '';
      });

      // 刷新消息列表（显示错误状态）
      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重试失败: $e')),
        );
      }
    }
  }

  /// 重试上一条 assistant 消息
  Future<void> _retryLastMessage() async {
    // 找到最后一条 assistant 消息
    final assistantMessages = _messages.where((m) => m.role == 'assistant').toList();
    if (assistantMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可重试的消息')),
      );
      return;
    }

    final lastAssistantMessage = assistantMessages.last;
    await _regenerateMessage(lastAssistantMessage.messageId);
  }

  /// 将指定消息设为主线
  Future<void> _setAsMainline(String messageId) async {
    try {
      await _service.setAsMainline(messageId);

      // 刷新消息列表
      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已设为主线'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e')),
        );
      }
    }
  }

  /// 删除指定的 assistant 消息
  Future<void> _deleteAssistantMessage(String messageId) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条回复吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteAssistantMessage(messageId);

      // 刷新消息列表
      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 重试单个模型调用
  Future<void> _retrySingleModel(String modelKey) async {
    if (_lastMultiModelMessages == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可重试的消息')),
      );
      return;
    }

    try {
      // 调用多模型服务的重试方法
      final newResponse = await _multiModelService.retrySingleModel(
        modelKey: modelKey,
        messages: _lastMultiModelMessages!,
      );

      // 检查 mounted 再 setState
      if (!mounted) return;

      // 更新响应 Map
      setState(() {
        _multiModelResponses = {
          ..._multiModelResponses ?? {},
          modelKey: newResponse,
        };
      });

      // 取消之前的重试订阅
      _retrySubscription?.cancel();

      // 监听流完成
      _retrySubscription = newResponse.contentStream.listen(
        (_) {
          // 流式更新会通过 ModelResponseCard 的监听自动处理
        },
        onDone: () async {
          // 检查 mounted 再继续
          if (!mounted) return;

          // 完成后保存到数据库
          if (newResponse.fullContent.isNotEmpty && newResponse.error == null) {
            await _service.addAssistantMessage(
              _activeConversationId!,
              newResponse.fullContent,
              modelId: newResponse.modelId,
              modelName: newResponse.modelName,
              askId: _lastUserMessageId,  // 设置 askId 关联到用户问题
              isMainline: false,  // 重试的回复默认不是主线
            );
          }
          if (mounted) {
            setState(() {});
          }
        },
        onError: (e) {
          // 错误已在 response 中处理
          if (mounted) {
            setState(() {});
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重试失败: $e')),
        );
      }
    }
  }

  /// 引用内容到输入框
  void _quoteToInput(String content) {
    // 截取前 200 字符作为引用
    final quote = content.length > 200
        ? '${content.substring(0, 200)}...'
        : content;

    final quotedText = '> $quote\n\n';

    // 插入到输入框
    final currentText = _inputController.text;
    _inputController.text = quotedText + currentText;
    _inputController.selection = TextSelection.collapsed(
      offset: _inputController.text.length,
    );
    _inputFocusNode.requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已引用到输入框'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// 翻译内容
  Future<void> _translateContent(String content) async {
    // 显示翻译选项
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('翻译'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('翻译成中文'),
              onTap: () => Navigator.pop(context, 'zh'),
            ),
            ListTile(
              title: const Text('翻译成英文'),
              onTap: () => Navigator.pop(context, 'en'),
            ),
            ListTile(
              title: const Text('翻译成日文'),
              onTap: () => Navigator.pop(context, 'ja'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      // 将翻译请求发送到 AI
      final targetLang = result == 'zh' ? '中文' : (result == 'en' ? '英文' : '日文');
      _inputController.text = '请将以下内容翻译成$targetLang：\n\n$content';
      _sendMessage();
    }
  }

  /// 编辑消息
  Future<void> _editMessage(String? messageId, String content) async {
    final controller = TextEditingController(text: content);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑消息'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '编辑内容...',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && messageId != null && mounted) {
      // 更新消息内容
      await _service.updateMessageContent(messageId, result);
      await _loadMessages();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('消息已更新'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// 删除消息
  Future<void> _deleteMessage(String? messageId) async {
    if (messageId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _service.deleteMessage(messageId);
      await _loadMessages();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('消息已删除'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// 操作图标按钮
  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: color ?? Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 更多操作菜单
  void _showMessageMoreActions(String content, {String modelName = 'AI'}) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 朗读（仅在配置有效时显示）
            Selector<TtsProvider, bool>(
              selector: (_, tts) => tts.hasValidConfig,
              builder: (context, hasValidConfig, _) {
                if (!hasValidConfig) return const SizedBox.shrink();
                return ListTile(
                  leading: const Icon(Icons.volume_up_outlined),
                  title: const Text('朗读'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _speakContent(content, modelName);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 分享功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('收藏'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 收藏功能
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 获取模型颜色
  Color _getModelColor(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (name.contains('gpt') || name.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (name.contains('gemini') || name.contains('google')) {
      return const Color(0xFF4285F4);
    } else if (name.contains('qwen') || name.contains('通义')) {
      return const Color(0xFF6366F1);
    } else if (name.contains('deepseek')) {
      return const Color(0xFF06B6D4);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }

  /// 获取模型图标
  IconData _getModelIcon(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return Icons.auto_awesome;
    } else if (name.contains('gpt') || name.contains('openai')) {
      return Icons.smart_toy_outlined;
    } else if (name.contains('gemini') || name.contains('google')) {
      return Icons.diamond_outlined;
    } else if (name.contains('qwen') || name.contains('通义')) {
      return Icons.cloud_outlined;
    } else if (name.contains('deepseek')) {
      return Icons.explore_outlined;
    } else {
      return Icons.memory;
    }
  }

  /// 输入区域
  Widget _buildInputArea() {
    // 判断是否显示 Context 按钮
    // 条件：有 Context 数据 + 没有发送过消息
    final hasContext = widget.initialContextData != null && _currentContextContent != null;
    final hasUserMessage = _messages.any((m) => m.role == 'user');
    final showContextButton = hasContext && !hasUserMessage;

    // 模板只在第一轮显示（没有用户消息时）
    final showTemplateSelector = !hasUserMessage;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具 chips 行（只在第一轮显示）
          if (showContextButton || showTemplateSelector)
            Row(
              children: [
                // Context 按钮（首次发送前显示）
                if (showContextButton) ...[
                  _buildContextChip(),
                  const SizedBox(width: 8),
                ],

                // 模版选择（只在第一轮显示）
                if (showTemplateSelector)
                  InkWell(
                    onTap: _showTemplateSelector,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedTemplate != null
                            ? Colors.purple.withAlpha(26)
                            : Colors.grey.withAlpha(26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedTemplate != null
                              ? Colors.purple.withAlpha(77)
                              : Colors.grey.withAlpha(77),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description,
                            size: 14,
                            color: _selectedTemplate != null
                                ? Colors.purple
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedTemplate?.name ?? '模板',
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedTemplate != null
                                  ? Colors.purple
                                  : Colors.grey[600],
                            ),
                          ),
                          if (_selectedTemplate != null) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _showTemplateContent(_selectedTemplate!),
                              child: Icon(
                                Icons.visibility_outlined,
                                size: 14,
                                color: Colors.purple[400],
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => setState(() => _selectedTemplate = null),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.purple[400],
                              ),
                            ),
                          ] else
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
              ],
            ),

          // 仅当有工具栏时添加间距
          if (showContextButton || showTemplateSelector)
            const SizedBox(height: 8),

          // 输入框和发送按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: showContextButton
                        ? '追加问题（可选），输入 @ 选择模型'
                        : '输入消息，输入 @ 选择模型',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                    // 显示后缀图标提示
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.alternate_email,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Context 按钮
  Widget _buildContextChip() {
    final contextInfo = _getContextInfo();
    final isSingleMessage = widget.contextTypeFilter == ConversationContextType.singleMessage;

    return InkWell(
      onTap: _showContextEditor,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 14, color: Colors.orange[700]),
            const SizedBox(width: 4),
            Text(
              contextInfo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(width: 4),
            // 单回复：预览图标；多轮：编辑图标
            Icon(
              isSingleMessage ? Icons.visibility_outlined : Icons.edit_outlined,
              size: 14,
              color: Colors.orange[600],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取 Context 简要信息
  String _getContextInfo() {
    final content = _currentContextContent ?? '';
    final charCount = content.length;

    // 格式化字数
    String charStr;
    if (charCount >= 10000) {
      charStr = '${(charCount / 10000).toStringAsFixed(1)}万';
    } else if (charCount >= 1000) {
      charStr = '${(charCount / 1000).toStringAsFixed(1)}K';
    } else if (charCount > 0) {
      charStr = '$charCount字';
    } else {
      charStr = '';
    }

    // 单回复讨论：显示"原文"
    if (widget.contextTypeFilter == ConversationContextType.singleMessage) {
      return charStr.isNotEmpty ? '原文 · $charStr' : '原文';
    }

    // 多轮对话：简化显示
    if (charCount == 0) {
      return '未选择';
    }
    return '已选 · $charStr';
  }

  /// 模版选择器
  Widget _buildTemplateSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 固定头部
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择模板',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showTemplateEditor(null);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新建'),
              ),
            ],
          ),
        ),

        // 可滚动列表
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              // 无模版选项
              ListTile(
                leading: Icon(
                  Icons.clear,
                  color: _selectedTemplate == null ? Colors.blue : Colors.grey,
                ),
                title: const Text('不使用模板'),
                subtitle: _defaultTemplateId == null
                    ? const Text('默认', style: TextStyle(fontSize: 12, color: Colors.blue))
                    : null,
                selected: _selectedTemplate == null,
                trailing: _defaultTemplateId != null
                    ? TextButton(
                        onPressed: () => _setDefaultTemplate(null),
                        child: const Text('设为默认', style: TextStyle(fontSize: 12)),
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedTemplate = null);
                  Navigator.pop(context);
                },
              ),
              const Divider(),

              // 模版列表
              ...List.generate(_templates.length, (index) {
                final template = _templates[index];
                final isSelected =
                    _selectedTemplate?.templateId == template.templateId;
                final isDefault = _defaultTemplateId == template.templateId;

                return ListTile(
                  leading: Icon(
                    template.isBuiltIn ? Icons.lock : Icons.description,
                    color: isSelected ? Colors.purple : Colors.grey,
                  ),
                  title: Row(
                    children: [
                      Text(template.name),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '默认',
                            style: TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: template.description != null
                      ? Text(
                          template.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  selected: isSelected,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 设为默认按钮
                      if (!isDefault)
                        IconButton(
                          icon: const Icon(Icons.push_pin_outlined, size: 18),
                          tooltip: '设为默认',
                          onPressed: () => _setDefaultTemplate(template.templateId),
                        ),
                      // 编辑按钮（仅非内置模板）
                      if (!template.isBuiltIn)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            Navigator.pop(context);
                            _showTemplateEditor(template);
                          },
                        ),
                    ],
                  ),
                  onTap: () {
                    setState(() => _selectedTemplate = template);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// 设置默认模板
  Future<void> _setDefaultTemplate(String? templateId) async {
    await _templateService.setDefaultTemplate(templateId);
    setState(() {
      _defaultTemplateId = templateId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(templateId == null ? '已取消默认模板' : '已设为默认模板'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showTemplateEditor(TaskTemplateEntity? template) {
    final nameController = TextEditingController(text: template?.name ?? '');
    final contentController =
        TextEditingController(text: template?.content ?? '');
    final descController =
        TextEditingController(text: template?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template == null ? '新建模板' : '编辑模板'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '模板名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '模板内容',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (template != null && !template.isBuiltIn)
            TextButton(
              onPressed: () async {
                await _templateService.deleteTemplate(template.templateId);
                await _loadTemplates();
                if (_selectedTemplate?.templateId == template.templateId) {
                  _selectedTemplate = null;
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final content = contentController.text.trim();

              if (name.isEmpty || content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名称和内容不能为空')),
                );
                return;
              }

              if (template == null) {
                final newTemplate = await _templateService.createTemplate(
                  name: name,
                  content: content,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                );
                _selectedTemplate = newTemplate;
              } else {
                template.name = name;
                template.content = content;
                template.description = descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim();
                await _templateService.updateTemplate(template);
              }

              await _loadTemplates();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

/// 全屏 Context 编辑器页面
class _ContextEditorPage extends StatefulWidget {
  final Map<String, dynamic>? contextData;
  final String contextSnapshot;
  final int? currentRoundIndex;
  final ConversationContextType contextType;
  /// 回调：返回新的 snapshot、结构化上下文、以及基于选择生成的 contextDataJson
  final Function(String, StructuredContext?, String?) onContextChanged;
  final VoidCallback onClear;

  const _ContextEditorPage({
    required this.contextData,
    required this.contextSnapshot,
    this.currentRoundIndex,
    required this.contextType,
    required this.onContextChanged,
    required this.onClear,
  });

  @override
  State<_ContextEditorPage> createState() => _ContextEditorPageState();
}

class _ContextEditorPageState extends State<_ContextEditorPage> {
  late String _currentSnapshot;
  final _topicService = TopicService();

  @override
  void initState() {
    super.initState();
    _currentSnapshot = widget.contextSnapshot;
  }

  void _handleContextChanged(String newSnapshot, String? contextDataJson) {
    setState(() => _currentSnapshot = newSnapshot);

    StructuredContext? structured;
    if (newSnapshot.isNotEmpty) {
      structured = StructuredContext.parse(newSnapshot, widget.contextType);
    }
    widget.onContextChanged(newSnapshot, structured, contextDataJson);
  }

  /// 加载所有话题列表
  Future<List<TopicSummary>> _loadTopics(String? assistantId) async {
    try {
      final topicsGrouped = await _topicService.getTopicsGrouped();
      // 获取助手列表来匹配名字
      final assistants = await _topicService.getAssistants();
      final assistantMap = <String, String>{};
      for (final assistant in assistants) {
        assistantMap[assistant.assistantId] = assistant.name;
      }

      final result = <TopicSummary>[];

      for (final entry in topicsGrouped.entries) {
        final assistantIdKey = entry.key;
        final topics = entry.value;
        final assistantName = assistantMap[assistantIdKey] ?? '未知助手';

        for (final topic in topics) {
          result.add(TopicSummary(
            id: topic['id'] as String,
            name: topic['name'] as String? ?? '未命名话题',
            assistantId: topic['assistantId'] as String?,
            assistantName: assistantName,
            roundCount: topic['roundCount'] as int? ?? 0,
            updatedAt: topic['updatedAt'] != null
                ? DateTime.tryParse(topic['updatedAt'].toString())
                : null,
          ));
        }
      }

      // 按更新时间排序（最新的在前）
      result.sort((a, b) {
        if (a.updatedAt == null && b.updatedAt == null) return 0;
        if (a.updatedAt == null) return 1;
        if (b.updatedAt == null) return -1;
        return b.updatedAt!.compareTo(a.updatedAt!);
      });

      return result;
    } catch (e) {
      debugPrint('加载话题列表失败: $e');
      return [];
    }
  }

  /// 加载话题详情
  Future<Map<String, dynamic>?> _loadTopicDetail(String topicId) async {
    try {
      final topicData = await _topicService.getTopicFullData(topicId);
      if (topicData == null) return null;

      // 将消息转换为 rounds 格式
      final messages = topicData['messages'] as List<dynamic>? ?? [];
      final rounds = _convertMessagesToRounds(messages);

      return {'rounds': rounds};
    } catch (e) {
      debugPrint('加载话题详情失败: $e');
      return null;
    }
  }

  /// 将消息列表转换为 rounds 格式（与 CherryExtractor 类似的逻辑）
  List<Map<String, dynamic>> _convertMessagesToRounds(List<dynamic> messages) {
    final rounds = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentUserMsg;
    List<Map<String, dynamic>> currentReplies = [];

    for (final msg in messages) {
      if (msg is! Map<String, dynamic>) continue;

      final role = msg['role'] as String?;
      if (role == 'user') {
        // 保存上一轮
        if (currentUserMsg != null || currentReplies.isNotEmpty) {
          rounds.add({
            'index': rounds.length,
            'question': currentUserMsg ?? {},
            'replies': List<Map<String, dynamic>>.from(currentReplies),
          });
          currentReplies = [];
        }
        currentUserMsg = msg;
      } else if (role == 'assistant') {
        currentReplies.add(msg);
      }
    }

    // 保存最后一轮
    if (currentUserMsg != null || currentReplies.isNotEmpty) {
      rounds.add({
        'index': rounds.length,
        'question': currentUserMsg ?? {},
        'replies': List<Map<String, dynamic>>.from(currentReplies),
      });
    }

    return rounds;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    // 侧滑页面宽度：宽屏占 95%，窄屏全屏（最大化编辑空间）
    final pageWidth = isWideScreen ? screenWidth * 0.95 : screenWidth;

    // 从 contextData 提取话题信息
    final currentTopicId = widget.contextData?['topicId'] as String?;
    final currentTopicName = widget.contextData?['topicName'] as String?;
    final currentAssistantId = widget.contextData?['assistantId'] as String?;
    final currentAssistantName = widget.contextData?['assistantName'] as String?;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 16,
        child: Container(
          width: pageWidth,
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                // 顶部栏
                _buildAppBar(context),

                // Context 选择器 (带三种视觉风格切换)
                Expanded(
                  child: ContextSelectorWithStyles(
                    contextData: widget.contextData,
                    contextSnapshot: _currentSnapshot,
                    currentRoundIndex: widget.currentRoundIndex,
                    currentTopicId: currentTopicId,
                    currentTopicName: currentTopicName,
                    currentAssistantId: currentAssistantId,
                    currentAssistantName: currentAssistantName,
                    onContextChanged: _handleContextChanged,
                    onClear: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    onLoadTopics: _loadTopics,
                    onLoadTopicDetail: _loadTopicDetail,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
            tooltip: '返回',
          ),
          const SizedBox(width: 8),

          // 标题
          Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text(
            'Context 编辑器',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // 完成按钮
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('完成'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 消息分组辅助类 ============

/// 消息显示项基类
sealed class _DisplayItem {}

/// 用户消息项
class _UserMessageItem extends _DisplayItem {
  final UnifiedMessageEntity message;
  _UserMessageItem(this.message);
}

/// 单个 assistant 消息项
class _SingleAssistantItem extends _DisplayItem {
  final UnifiedMessageEntity message;
  _SingleAssistantItem(this.message);
}

/// 多个 assistant 消息项（同一 askId 的多个回复）
class _MultiAssistantItem extends _DisplayItem {
  final List<UnifiedMessageEntity> messages;
  _MultiAssistantItem(this.messages);
}

// ============ 保存后的多模型回复卡片 ============

/// 已保存的模型回复卡片（从数据库加载的多模型回复）
class _SavedModelResponseCard extends StatelessWidget {
  final UnifiedMessageEntity message;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;
  final VoidCallback? onQuote;
  final VoidCallback? onSetMainline;
  final VoidCallback? onDelete;
  final VoidCallback? onSpeak;

  const _SavedModelResponseCard({
    required this.message,
    this.onRetry,
    this.onCopy,
    this.onQuote,
    this.onSetMainline,
    this.onDelete,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modelColor = _getModelColor(message.modelName ?? 'AI');
    final cardWidth = MediaQuery.of(context).size.width * 0.75;
    final minWidth = 320.0;
    final maxWidth = 500.0;
    final width = cardWidth.clamp(minWidth, maxWidth);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isMainline == true
              ? Colors.amber.withValues(alpha: 0.6)
              : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
          width: message.isMainline == true ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部：模型名称
          _buildHeader(context, modelColor, isDark),

          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: UnifiedMarkdownRenderer(
                data: message.content,
                scrollable: false,
                selectable: true,
                textStyle: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: isDark ? Colors.grey[200] : const Color(0xFF2C3E50),
                ),
              ),
            ),
          ),

          // 底部操作栏
          _buildActionBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color modelColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: modelColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // 模型图标
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: modelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getModelIcon(message.modelName ?? 'AI'),
              size: 16,
              color: modelColor,
            ),
          ),
          const SizedBox(width: 8),
          // 模型名称
          Expanded(
            child: Text(
              message.modelName ?? 'AI',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 主线标记
          if (message.isMainline == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '主线',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // 复制
          _buildActionButton(
            icon: Icons.copy_outlined,
            tooltip: '复制',
            onTap: onCopy,
          ),
          // 重试
          if (onRetry != null)
            _buildActionButton(
              icon: Icons.refresh_outlined,
              tooltip: '重试',
              onTap: onRetry,
            ),
          // 引用
          if (onQuote != null)
            _buildActionButton(
              icon: Icons.format_quote_outlined,
              tooltip: '引用',
              onTap: onQuote,
            ),
          // 设为主线（非主线消息才显示）
          if (onSetMainline != null && message.isMainline != true)
            _buildActionButton(
              icon: Icons.star_outline,
              tooltip: '设为主线',
              onTap: onSetMainline,
            ),
          // 删除
          if (onDelete != null)
            _buildActionButton(
              icon: Icons.delete_outline,
              tooltip: '删除',
              onTap: onDelete,
              color: Colors.red[400],
            ),
          // 朗读
          if (onSpeak != null)
            _buildActionButton(
              icon: Icons.volume_up_outlined,
              tooltip: '朗读',
              onTap: onSpeak,
            ),

          const Spacer(),

          // 字数统计
          Text(
            '${message.content.length}字',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: color ?? Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Color _getModelColor(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (name.contains('gpt') || name.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (name.contains('gemini') || name.contains('google')) {
      return const Color(0xFF4285F4);
    } else if (name.contains('qwen') || name.contains('通义')) {
      return const Color(0xFF6366F1);
    } else if (name.contains('deepseek')) {
      return const Color(0xFF06B6D4);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }

  IconData _getModelIcon(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return Icons.auto_awesome;
    } else if (name.contains('gpt') || name.contains('openai')) {
      return Icons.smart_toy_outlined;
    } else if (name.contains('gemini') || name.contains('google')) {
      return Icons.diamond_outlined;
    } else if (name.contains('qwen') || name.contains('通义')) {
      return Icons.cloud_outlined;
    } else if (name.contains('deepseek')) {
      return Icons.explore_outlined;
    } else {
      return Icons.memory;
    }
  }
}
