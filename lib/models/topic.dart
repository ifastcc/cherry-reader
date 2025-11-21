import 'package:json_annotation/json_annotation.dart';
import 'message.dart';

part 'topic.g.dart';

/// 话题结构
@JsonSerializable(explicitToJson: true)
class Topic {
  final String id;
  final List<Message> messages;

  // 元数据字段（来自 localStorage）
  final String? name;
  final String? createdAt;
  final String? updatedAt;

  Topic({
    required this.id,
    required this.messages,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);

  Map<String, dynamic> toJson() => _$TopicToJson(this);
}
