// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as String,
      role: json['role'] as String,
      topicId: json['topicId'] as String,
      assistantId: json['assistantId'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      blocks:
          (json['blocks'] as List<dynamic>).map((e) => e as String).toList(),
      model: json['model'] as Map<String, dynamic>?,
      modelId: json['modelId'] as String?,
      usage: json['usage'] as Map<String, dynamic>?,
      metrics: json['metrics'] as Map<String, dynamic>?,
      mentions: (json['mentions'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      useful: json['useful'] as bool?,
      traceId: json['traceId'] as String?,
      blockContents: (json['blockContents'] as List<dynamic>?)
              ?.map((e) => MessageBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'topicId': instance.topicId,
      'assistantId': instance.assistantId,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'blocks': instance.blocks,
      'model': instance.model,
      'modelId': instance.modelId,
      'usage': instance.usage,
      'metrics': instance.metrics,
      'mentions': instance.mentions,
      'useful': instance.useful,
      'traceId': instance.traceId,
      'blockContents': instance.blockContents.map((e) => e.toJson()).toList(),
    };
