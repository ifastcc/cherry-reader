import 'package:isar_community/isar.dart';

part 'discussion_message_entity.g.dart';

/// 讨论消息实体
///
/// 存储讨论线程中的单条消息
@collection
class DiscussionMessageEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 消息ID（UUID）
  @Index()
  late String messageId;

  /// 所属讨论ID
  @Index()
  late String discussionId;

  /// 消息角色（user, assistant, system）
  late String role;

  /// 消息内容
  late String content;

  /// 创建时间（毫秒时间戳）
  late int createdAt;

  /// 构造函数
  DiscussionMessageEntity();

  /// 从Map创建
  factory DiscussionMessageEntity.fromMap(Map<String, dynamic> map) {
    return DiscussionMessageEntity()
      ..messageId = map['messageId'] as String
      ..discussionId = map['discussionId'] as String
      ..role = map['role'] as String
      ..content = map['content'] as String
      ..createdAt = map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'discussionId': discussionId,
      'role': role,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
