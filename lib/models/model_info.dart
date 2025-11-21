import 'package:json_annotation/json_annotation.dart';

part 'model_info.g.dart';

/// 模型信息
@JsonSerializable()
class ModelInfo {
  final String id;
  final String provider;
  final String name;
  final String? group;

  ModelInfo({
    required this.id,
    required this.provider,
    required this.name,
    this.group,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ModelInfoToJson(this);
}
