import 'package:json_annotation/json_annotation.dart';

part 'message_block.g.dart';

/// 消息块基础结构
@JsonSerializable(explicitToJson: true)
class MessageBlock {
  final String id;
  final String messageId;
  final String type;
  final String createdAt;
  final String status;

  final String? content;
  final Map<String, dynamic>? model;
  final Map<String, dynamic>? metadata;

  // 特定类型字段
  @JsonKey(name: 'thinking_millsec')
  final double? thinkingMillsec; // thinking 块

  final Map<String, dynamic>? file; // file/image 块
  final String? url; // image 块
  final Map<String, dynamic>? error; // error 块

  final String? toolId; // tool 块
  final String? toolName; // tool 块
  final Map<String, dynamic>? arguments; // tool 块

  @JsonKey(name: 'targetLanguage')
  final String? targetLanguage; // translation 块

  MessageBlock({
    required this.id,
    required this.messageId,
    required this.type,
    required this.createdAt,
    required this.status,
    this.content,
    this.model,
    this.metadata,
    this.thinkingMillsec,
    this.file,
    this.url,
    this.error,
    this.toolId,
    this.toolName,
    this.arguments,
    this.targetLanguage,
  });

  factory MessageBlock.fromJson(Map<String, dynamic> json) =>
      _$MessageBlockFromJson(json);

  Map<String, dynamic> toJson() => _$MessageBlockToJson(this);
}
