import 'package:flutter/material.dart';
import '../models/isar/discussion_message_entity.dart';
import'../services/discussion_service.dart';
import '../services/openai_service.dart';
import '../screens/settings_screen.dart';
import '../utils/api_host_utils.dart';

/// 讨论对话页面
///
/// 显示讨论的所有消息，支持多轮对话和流式生成
class DiscussionChatScreen extends StatefulWidget {
  final String discussionId;
  final String aiReplyContent; // 原AI回复内容（用于显示上下文）

  const DiscussionChatScreen({
    Key? key,
    required this.discussionId,
    required this.aiReplyContent,
  }) : super(key: key);

  @override
  State<DiscussionChatScreen> createState() => _DiscussionChatScreenState();
}

class _DiscussionChatScreenState extends State<DiscussionChatScreen> {
  final DiscussionService _discussionService = DiscussionService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  List<DiscussionMessageEntity> _messages = [];
  bool _loading = true;
  bool _isGenerating = false;
  String _streamingContent = '';

  // OpenAI配置
  OpenAIService? _openaiService;
  String _model = 'gpt-4-turbo-preview';

  // 原AI回复是否展开
  bool _aiReplyExpanded = false;

  @override
  void initState() {
    super.initState();
    _initApiConfig();
    _loadMessages();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initApiConfig() async {
    final config = await getApiConfig();
    setState(() {
      final apiKey = config['apiKey'] ?? '';
      final rawBaseUrl = config['apiUrl'] ?? 'https://api.openai.com/v1';
      final baseUrl = formatOpenAIApiHost(rawBaseUrl);
      _model = config['model'] ?? 'gpt-4-turbo-preview';
      _openaiService = OpenAIService(apiKey: apiKey, baseUrl: baseUrl);
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final messages = await _discussionService.getMessages(widget.discussionId);
    setState(() {
      _messages = messages;
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _inputController.clear();

    // 添加用户消息到UI
    await _discussionService.addMessage(
      discussionId: widget.discussionId,
      role: 'user',
      content: text,
    );

    await _loadMessages();

    // 生成AI回复
    await _generateAIReply();
  }

  /// 生成AI回复（流式）
  Future<void> _generateAIReply() async {
    if (_openaiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置 API Key')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _streamingContent = '';
    });

    try {
      // 获取所有消息（包括系统消息）
      final apiMessages = await _discussionService.formatMessagesForApi(
        widget.discussionId,
      );

      // 流式生成
      final stream = _openaiService!.streamChatCompletion(
        model: _model,
        messages: apiMessages,
      );

      await for (final chunk in stream) {
        setState(() {
          _streamingContent += chunk;
        });
        _scrollToBottom();
      }

      // 保存AI回复
      await _discussionService.addMessage(
        discussionId: widget.discussionId,
        role: 'assistant',
        content: _streamingContent,
      );

      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
        _streamingContent = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('讨论详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              setState(() {
                _aiReplyExpanded = !_aiReplyExpanded;
              });
            },
            tooltip: '查看原回复',
          ),
        ],
      ),
      body: Column(
        children: [
          // 原AI回复摘要（可展开）
          if (_aiReplyExpanded) _buildAIReplyContext(),
          // 消息列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          // 输入框
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildAIReplyContext() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 6),
              const Text(
                '正在讨论的AI回复',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _aiReplyExpanded = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Text(
                widget.aiReplyContent.length > 500
                    ? '${widget.aiReplyContent.substring(0, 500)}...'
                    : widget.aiReplyContent,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    // 过滤掉系统消息（不在UI中显示）
    final visibleMessages = _messages.where((m) => m.role != 'system').toList();

    return GestureDetector(
      onTap: () {
        // 点击消息列表区域时收起键盘
        _inputFocusNode.unfocus();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: visibleMessages.length + (_isGenerating ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isGenerating && index == visibleMessages.length) {
            // 显示流式生成中的消息
            return _buildMessageBubble(
              role: 'assistant',
              content: _streamingContent,
              isStreaming: true,
            );
          }

          final message = visibleMessages[index];
          return _buildMessageBubble(
            role: message.role,
            content: message.content,
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble({
    required String role,
    required String content,
    bool isStreaming = false,
  }) {
    final isUser = role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  if (isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[400]!,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8B5CF6),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              autofocus: false,
              enabled: !_isGenerating,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '输入您的问题...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isGenerating ? null : _sendMessage,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: const Color(0xFF8B5CF6),
            disabledColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}
