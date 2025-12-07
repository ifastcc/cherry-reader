// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIModel _$AIModelFromJson(Map<String, dynamic> json) => AIModel(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String?,
      group: json['group'] as String?,
      description: json['description'] as String?,
      contextLength: (json['contextLength'] as num?)?.toInt(),
      maxOutputTokens: (json['maxOutputTokens'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AIModelToJson(AIModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'provider': instance.provider,
      'group': instance.group,
      'description': instance.description,
      'contextLength': instance.contextLength,
      'maxOutputTokens': instance.maxOutputTokens,
    };

AIProvider _$AIProviderFromJson(Map<String, dynamic> json) => AIProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$AIProviderTypeEnumMap, json['type'],
          unknownValue: AIProviderType.custom),
      apiKey: json['apiKey'] as String,
      apiHost: json['apiHost'] as String,
      models: (json['models'] as List<dynamic>?)
              ?.map((e) => AIModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      enabled: json['enabled'] as bool? ?? true,
      isSystem: json['isSystem'] as bool? ?? false,
      apiVersion: json['apiVersion'] as String?,
      notes: json['notes'] as String?,
      extraHeaders: (json['extraHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      source: $enumDecodeNullable(_$ProviderSourceEnumMap, json['source']) ??
          ProviderSource.cherryStudio,
    );

Map<String, dynamic> _$AIProviderToJson(AIProvider instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$AIProviderTypeEnumMap[instance.type]!,
      'apiKey': instance.apiKey,
      'apiHost': instance.apiHost,
      'models': instance.models.map((e) => e.toJson()).toList(),
      'enabled': instance.enabled,
      'isSystem': instance.isSystem,
      'apiVersion': instance.apiVersion,
      'notes': instance.notes,
      'extraHeaders': instance.extraHeaders,
      'source': _$ProviderSourceEnumMap[instance.source]!,
    };

const _$AIProviderTypeEnumMap = {
  AIProviderType.openai: 'openai',
  AIProviderType.anthropic: 'anthropic',
  AIProviderType.gemini: 'gemini',
  AIProviderType.azureOpenai: 'azure-openai',
  AIProviderType.openaiResponse: 'openai-response',
  AIProviderType.vertexai: 'vertexai',
  AIProviderType.mistral: 'mistral',
  AIProviderType.awsBedrock: 'aws-bedrock',
  AIProviderType.newApi: 'new-api',
  AIProviderType.aiGateway: 'ai-gateway',
  AIProviderType.custom: 'custom',
};

const _$ProviderSourceEnumMap = {
  ProviderSource.manual: 'manual',
  ProviderSource.cherryStudio: 'cherry_studio',
};
