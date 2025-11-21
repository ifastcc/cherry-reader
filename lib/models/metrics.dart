import 'package:json_annotation/json_annotation.dart';

part 'metrics.g.dart';

/// 性能指标
@JsonSerializable()
class Metrics {
  @JsonKey(name: 'time_thinking_millsec')
  final int? timeThinkingMillsec;

  @JsonKey(name: 'time_first_token_millsec')
  final int? timeFirstTokenMillsec;

  @JsonKey(name: 'time_total_millsec')
  final int? timeTotalMillsec;

  Metrics({
    this.timeThinkingMillsec,
    this.timeFirstTokenMillsec,
    this.timeTotalMillsec,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) =>
      _$MetricsFromJson(json);

  Map<String, dynamic> toJson() => _$MetricsToJson(this);
}
