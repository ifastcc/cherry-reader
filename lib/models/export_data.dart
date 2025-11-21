import 'package:json_annotation/json_annotation.dart';

part 'export_data.g.dart';

/// Cherry Studio 导出数据顶层结构
@JsonSerializable(explicitToJson: true)
class ExportData {
  final int time;
  final int version;
  final Map<String, dynamic> localStorage;
  final Map<String, dynamic> indexedDB;

  ExportData({
    required this.time,
    required this.version,
    required this.localStorage,
    required this.indexedDB,
  });

  factory ExportData.fromJson(Map<String, dynamic> json) =>
      _$ExportDataFromJson(json);

  Map<String, dynamic> toJson() => _$ExportDataToJson(this);
}
