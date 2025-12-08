// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Metrics _$MetricsFromJson(Map<String, dynamic> json) => Metrics(
  timeThinkingMillsec: (json['time_thinking_millsec'] as num?)?.toInt(),
  timeFirstTokenMillsec: (json['time_first_token_millsec'] as num?)?.toInt(),
  timeTotalMillsec: (json['time_total_millsec'] as num?)?.toInt(),
);

Map<String, dynamic> _$MetricsToJson(Metrics instance) => <String, dynamic>{
  'time_thinking_millsec': instance.timeThinkingMillsec,
  'time_first_token_millsec': instance.timeFirstTokenMillsec,
  'time_total_millsec': instance.timeTotalMillsec,
};
