import 'package:json_annotation/json_annotation.dart';
import 'message_block.dart';

part 'message.g.dart';

/// 消息结构
@JsonSerializable(explicitToJson: true)
class Message {
  final String id;
  final String role;
  final String topicId;
  final String assistantId;
  final String createdAt;
  final String status;

  final List<String> blocks; // Block ID 数组

  final Map<String, dynamic>? model;
  final String? modelId;
  final Map<String, dynamic>? usage;
  final Map<String, dynamic>? metrics;
  final List<Map<String, dynamic>>? mentions;
  final bool? useful;
  final String? traceId;

  // 扩展字段：实际的消息块内容（由提取器填充）
  @JsonKey(defaultValue: [])
  final List<MessageBlock> blockContents;

  Message({
    required this.id,
    required this.role,
    required this.topicId,
    required this.assistantId,
    required this.createdAt,
    required this.status,
    required this.blocks,
    this.model,
    this.modelId,
    this.usage,
    this.metrics,
    this.mentions,
    this.useful,
    this.traceId,
    this.blockContents = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  /// 创建带有消息块内容的副本
  Message copyWithBlocks(List<MessageBlock> newBlocks) {
    return Message(
      id: id,
      role: role,
      topicId: topicId,
      assistantId: assistantId,
      createdAt: createdAt,
      status: status,
      blocks: blocks,
      model: model,
      modelId: modelId,
      usage: usage,
      metrics: metrics,
      mentions: mentions,
      useful: useful,
      traceId: traceId,
      blockContents: newBlocks,
    );
  }
}
