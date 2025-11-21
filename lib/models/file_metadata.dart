import 'package:json_annotation/json_annotation.dart';

part 'file_metadata.g.dart';

/// 文件元数据
@JsonSerializable()
class FileMetadata {
  final String id;

  @JsonKey(name: 'origin_name')
  final String originName;

  final String name;
  final String path;

  @JsonKey(name: 'created_at')
  final String createdAt;

  final int size;
  final String ext;
  final String type;

  @JsonKey(defaultValue: 0)
  final int count;

  FileMetadata({
    required this.id,
    required this.originName,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.size,
    required this.ext,
    required this.type,
    this.count = 0,
  });

  factory FileMetadata.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$FileMetadataToJson(this);
}
