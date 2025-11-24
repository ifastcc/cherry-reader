// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) => ModelInfo(
  id: json['id'] as String,
  provider: json['provider'] as String,
  name: json['name'] as String,
  group: json['group'] as String?,
);

Map<String, dynamic> _$ModelInfoToJson(ModelInfo instance) => <String, dynamic>{
  'id': instance.id,
  'provider': instance.provider,
  'name': instance.name,
  'group': instance.group,
};
