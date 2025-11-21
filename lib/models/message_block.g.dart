// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageBlock _$MessageBlockFromJson(Map<String, dynamic> json) => MessageBlock(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      type: json['type'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      content: json['content'] as String?,
      model: json['model'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      thinkingMillsec: (json['thinking_millsec'] as num?)?.toDouble(),
      file: json['file'] as Map<String, dynamic>?,
      url: json['url'] as String?,
      error: json['error'] as Map<String, dynamic>?,
      toolId: json['toolId'] as String?,
      toolName: json['toolName'] as String?,
      arguments: json['arguments'] as Map<String, dynamic>?,
      targetLanguage: json['targetLanguage'] as String?,
    );

Map<String, dynamic> _$MessageBlockToJson(MessageBlock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messageId': instance.messageId,
      'type': instance.type,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'content': instance.content,
      'model': instance.model,
      'metadata': instance.metadata,
      'thinking_millsec': instance.thinkingMillsec,
      'file': instance.file,
      'url': instance.url,
      'error': instance.error,
      'toolId': instance.toolId,
      'toolName': instance.toolName,
      'arguments': instance.arguments,
      'targetLanguage': instance.targetLanguage,
    };
