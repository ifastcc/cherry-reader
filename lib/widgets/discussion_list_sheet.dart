import 'package:flutter/material.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../services/unified_conversation_service.dart';
import '../screens/ai_chat_screen.dart';

/// 讨论列表 BottomSheet
///
/// 显示某个AI回复的所有讨论线程
/// 已迁移至统一对话系统
class DiscussionListSheet extends StatefulWidget {
  final String messageId; // 关联的AI回复消息ID
  final String aiReplyContent; // AI回复内容（用于创建讨论时的上下文）

  const DiscussionListSheet({
    Key? key,
    required this.messageId,
    required this.aiReplyContent,
  }) : super(key: key);

  @override
  State<DiscussionListSheet> createState() => _DiscussionListSheetState();
}

class _DiscussionListSheetState extends State<DiscussionListSheet> {
  final UnifiedConversationService _conversationService = UnifiedConversationService.instance;
  List<UnifiedConversationEntity> _discussions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    setState(() => _loading = true);
    // 获取与当前消息关联的所有讨论（contextType = singleMessage, contextId = messageId）
    final allConversations = await _conversationService.getConversationsByContext(widget.messageId);
    // 只筛选 singleMessage 类型
    final discussions = allConversations
        .where((c) => c.contextType == ConversationContextType.singleMessage)
        .toList();
    setState(() {
      _discussions = discussions;
      _loading = false;
    });
  }

  /// 创建新讨论
  Future<void> _createNewDiscussion() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增讨论'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '请输入您的问题或想讨论的内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('开始讨论'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      // 【修复】不再预先创建对话，让 AIChatScreen 在用户发送消息时懒创建
      // 构建 contextData（包含上下文和用户问题）
      final contextData = {
        'rounds': [
          {
            'index': 0,
            'question': {'blocks': []}, // 单个回复没有问题
            'replies': [
              // TODO: 这里应该传递完整的回复数据，但现在只有文本
              // 暂时用简单结构
            ],
          },
        ],
        'currentRoundIndex': 0,
        // 格式化的上下文内容（AI 回复）
        'formattedContext': '**AI 回复内容：**\n\n${widget.aiReplyContent}',
        // 用户输入的问题作为追加问题
        'userQuery': result,
      };

      // 关闭当前sheet
      if (mounted) {
        Navigator.pop(context);
      }

      // 进入新的 AI 对话界面
      // 【修复】不传 initialConversationId，让 AIChatScreen 懒创建
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIChatScreen(
              // initialConversationId: null - 不预先创建，懒创建
              initialContextId: widget.messageId,
              initialContextSnapshot: widget.aiReplyContent,
              initialContextData: contextData, // ← 传递原始数据
              initialTitle: result.length > 50 ? '${result.substring(0, 50)}...' : result,
              contextTypeFilter: ConversationContextType.singleMessage,
            ),
          ),
        );
      }
    }
  }

  /// 进入讨论对话页面
  void _enterDiscussion(UnifiedConversationEntity conversation) {
    Navigator.pop(context); // 关闭当前sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          initialConversationId: conversation.conversationId,
          initialContextId: widget.messageId, // 传入 contextId 用于数据隔离
          initialContextSnapshot: widget.aiReplyContent,
          contextTypeFilter: ConversationContextType.singleMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部标题栏
          _buildHeader(),
          const Divider(height: 1),
          // 新增讨论按钮
          _buildNewDiscussionButton(),
          const Divider(height: 1),
          // 讨论列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _discussions.isEmpty
                    ? _buildEmptyState()
                    : _buildDiscussionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 8),
          const Text(
            '讨论列表',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildNewDiscussionButton() {
    return InkWell(
      onTap: _createNewDiscussion,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '新增讨论',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有讨论',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方"新增讨论"开始提问',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _discussions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final discussion = _discussions[index];
        return _buildDiscussionItem(discussion);
      },
    );
  }

  Widget _buildDiscussionItem(UnifiedConversationEntity conversation) {
    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(conversation.updatedAt);
    final relativeTime = _formatRelativeTime(lastUpdate);

    return InkWell(
      onTap: () => _enterDiscussion(conversation),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(
                  Icons.message,
                  size: 16,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    conversation.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 元信息
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${conversation.roundCount} 轮对话，${conversation.messageCount} 条消息',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  relativeTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化相对时间
  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
