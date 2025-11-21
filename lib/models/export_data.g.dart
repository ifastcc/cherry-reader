// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportData _$ExportDataFromJson(Map<String, dynamic> json) => ExportData(
      time: (json['time'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      localStorage: json['localStorage'] as Map<String, dynamic>,
      indexedDB: json['indexedDB'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ExportDataToJson(ExportData instance) =>
    <String, dynamic>{
      'time': instance.time,
      'version': instance.version,
      'localStorage': instance.localStorage,
      'indexedDB': instance.indexedDB,
    };
