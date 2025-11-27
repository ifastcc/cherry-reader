import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/isar/discussion_entity.dart';
import '../models/isar/discussion_message_entity.dart';
import 'isar_database.dart';

/// 讨论管理服务
///
/// 负责讨论线程和消息的CRUD操作
/// 参考 HighlightService 的结构，使用 Isar 数据库
class DiscussionService {
  static final DiscussionService _instance = DiscussionService._internal();
  factory DiscussionService() => _instance;
  DiscussionService._internal();

  final IsarDatabase _db = IsarDatabase();
  final _uuid = const Uuid();

  // ============ 讨论线程管理 ============

  /// 创建新讨论
  ///
  /// [messageId] - 关联的AI回复消息ID
  /// [title] - 讨论标题（通常是第一条用户消息）
  /// [initialUserMessage] - 初始用户消息（可选）
  /// [aiReplyContent] - 原AI回复内容（作为上下文）
  Future<String> createDiscussion({
    required String messageId,
    required String title,
    String? initialUserMessage,
    String? aiReplyContent,
  }) async {
    final discussionId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 创建讨论线程
    final discussion = DiscussionEntity()
      ..discussionId = discussionId
      ..messageId = messageId
      ..title = title
      ..messageCount = 0
      ..createdAt = now
      ..updatedAt = now;

    await _db.saveDiscussion(discussion);

    // 如果提供了AI回复内容，作为系统消息添加（上下文）
    if (aiReplyContent != null && aiReplyContent.isNotEmpty) {
      await addMessage(
        discussionId: discussionId,
        role: 'system',
        content: '用户正在讨论以下AI回复的内容：\n\n$aiReplyContent',
      );
    }

    // 如果提供了初始用户消息，添加
    if (initialUserMessage != null && initialUserMessage.isNotEmpty) {
      await addMessage(
        discussionId: discussionId,
        role: 'user',
        content: initialUserMessage,
      );
    }

    debugPrint('[DiscussionService] 创建讨论: $discussionId, 标题: $title');
    return discussionId;
  }

  /// 获取指定AI回复的所有讨论
  Future<List<DiscussionEntity>> getDiscussions(String messageId) async {
    return await _db.getDiscussions(messageId);
  }

  /// 获取单个讨论
  Future<DiscussionEntity?> getDiscussion(String discussionId) async {
    return await _db.getDiscussion(discussionId);
  }

  /// 删除讨论（包括所有消息）
  Future<void> deleteDiscussion(String discussionId) async {
    await _db.deleteDiscussion(discussionId);
    debugPrint('[DiscussionService] 删除讨论: $discussionId');
  }

  // ============ 消息管理 ============

  /// 添加消息
  ///
  /// [discussionId] - 讨论ID
  /// [role] - 消息角色（user, assistant, system）
  /// [content] - 消息内容
  Future<void> addMessage({
    required String discussionId,
    required String role,
    required String content,
  }) async {
    final messageId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final message = DiscussionMessageEntity()
      ..messageId = messageId
      ..discussionId = discussionId
      ..role = role
      ..content = content
      ..createdAt = now;

    await _db.saveDiscussionMessage(message);

    // 更新讨论的消息计数和更新时间
    final messages = await getMessages(discussionId);
    await _db.updateDiscussion(discussionId, messages.length);

    debugPrint(
      '[DiscussionService] 添加消息 ($role): ${content.substring(0, content.length > 50 ? 50 : content.length)}...',
    );
  }

  /// 获取讨论的所有消息
  Future<List<DiscussionMessageEntity>> getMessages(String discussionId) async {
    return await _db.getDiscussionMessages(discussionId);
  }

  /// 监听讨论消息变化（实时更新）
  Stream<List<DiscussionMessageEntity>> watchMessages(String discussionId) {
    return _db.watchDiscussionMessages(discussionId);
  }

  // ============ 辅助方法 ============

  /// 格式化讨论消息为OpenAI API格式
  ///
  /// 用于发送给OpenAI API进行对话
  Future<List<Map<String, String>>> formatMessagesForApi(
    String discussionId,
  ) async {
    final messages = await getMessages(discussionId);
    return messages
        .map((m) => {
              'role': m.role,
              'content': m.content,
            })
        .toList();
  }

  /// 获取讨论摘要（用于列表显示）
  ///
  /// 返回: {title, messageCount, lastUpdate}
  Future<Map<String, dynamic>?> getDiscussionSummary(
    String discussionId,
  ) async {
    final discussion = await getDiscussion(discussionId);
    if (discussion == null) return null;

    return {
      'title': discussion.title,
      'messageCount': discussion.messageCount,
      'lastUpdate': DateTime.fromMillisecondsSinceEpoch(discussion.updatedAt),
      'createdAt': DateTime.fromMillisecondsSinceEpoch(discussion.createdAt),
    };
  }

  /// 格式化时间为相对时间（如"刚刚"、"5分钟前"）
  String formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
