// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileMetadata _$FileMetadataFromJson(Map<String, dynamic> json) => FileMetadata(
      id: json['id'] as String,
      originName: json['origin_name'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      createdAt: json['created_at'] as String,
      size: (json['size'] as num).toInt(),
      ext: json['ext'] as String,
      type: json['type'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FileMetadataToJson(FileMetadata instance) =>
    <String, dynamic>{
      'id': instance.id,
      'origin_name': instance.originName,
      'name': instance.name,
      'path': instance.path,
      'created_at': instance.createdAt,
      'size': instance.size,
      'ext': instance.ext,
      'type': instance.type,
      'count': instance.count,
    };
