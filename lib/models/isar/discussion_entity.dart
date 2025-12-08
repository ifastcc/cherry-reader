import 'package:isar_community/isar.dart';

part 'discussion_entity.g.dart';

/// 讨论线程实体
///
/// 存储针对某个AI回复的讨论线程元数据
@collection
class DiscussionEntity {
  /// Isar 自动生成的 ID
  Id id = Isar.autoIncrement;

  /// 讨论ID（UUID）
  @Index()
  late String discussionId;

  /// 关联的AI回复消息ID
  @Index()
  late String messageId;

  /// 讨论标题（第一条用户消息的内容）
  late String title;

  /// 消息数量
  late int messageCount;

  /// 创建时间（毫秒时间戳）
  late int createdAt;

  /// 最后更新时间（毫秒时间戳）
  late int updatedAt;

  /// 构造函数
  DiscussionEntity();

  /// 从Map创建
  factory DiscussionEntity.fromMap(Map<String, dynamic> map) {
    return DiscussionEntity()
      ..discussionId = map['discussionId'] as String
      ..messageId = map['messageId'] as String
      ..title = map['title'] as String
      ..messageCount = map['messageCount'] as int? ?? 0
      ..createdAt = map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch
      ..updatedAt = map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'discussionId': discussionId,
      'messageId': messageId,
      'title': title,
      'messageCount': messageCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
