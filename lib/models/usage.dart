import 'package:json_annotation/json_annotation.dart';

part 'usage.g.dart';

/// Token 使用统计
@JsonSerializable()
class Usage {
  @JsonKey(name: 'prompt_tokens', defaultValue: 0)
  final int promptTokens;

  @JsonKey(name: 'completion_tokens', defaultValue: 0)
  final int completionTokens;

  @JsonKey(name: 'total_tokens', defaultValue: 0)
  final int totalTokens;

  Usage({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
  });

  factory Usage.fromJson(Map<String, dynamic> json) => _$UsageFromJson(json);

  Map<String, dynamic> toJson() => _$UsageToJson(this);
}
