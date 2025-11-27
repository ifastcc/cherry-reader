import 'package:flutter/material.dart';
import '../models/isar/discussion_entity.dart';
import '../services/discussion_service.dart';
import '../screens/discussion_chat_screen.dart';

/// 讨论列表 BottomSheet
///
/// 显示某个AI回复的所有讨论线程
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
  final DiscussionService _discussionService = DiscussionService();
  List<DiscussionEntity> _discussions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    setState(() => _loading = true);
    final discussions = await _discussionService.getDiscussions(widget.messageId);
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
      // 创建讨论
      final discussionId = await _discussionService.createDiscussion(
        messageId: widget.messageId,
        title: result.length > 50 ? '${result.substring(0, 50)}...' : result,
        initialUserMessage: result,
        aiReplyContent: widget.aiReplyContent,
      );

      // 关闭当前sheet
      if (mounted) {
        Navigator.pop(context);
      }

      // 进入讨论对话页面
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscussionChatScreen(
              discussionId: discussionId,
              aiReplyContent: widget.aiReplyContent,
            ),
          ),
        );
      }
    }
  }

  /// 进入讨论对话页面
  void _enterDiscussion(DiscussionEntity discussion) {
    Navigator.pop(context); // 关闭当前sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionChatScreen(
          discussionId: discussion.discussionId,
          aiReplyContent: widget.aiReplyContent,
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

  Widget _buildDiscussionItem(DiscussionEntity discussion) {
    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(discussion.updatedAt);
    final relativeTime = _discussionService.formatRelativeTime(lastUpdate);

    return InkWell(
      onTap: () => _enterDiscussion(discussion),
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
                    discussion.title,
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
                  '${discussion.messageCount} 条消息',
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
}
