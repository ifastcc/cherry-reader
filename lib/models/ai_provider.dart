import 'package:json_annotation/json_annotation.dart';

part 'ai_provider.g.dart';

/// AI Provider 类型枚举
/// 参考 Cherry Studio 的 ProviderType
enum AIProviderType {
  @JsonValue('openai')
  openai,
  @JsonValue('anthropic')
  anthropic,
  @JsonValue('gemini')
  gemini,
  @JsonValue('azure-openai')
  azureOpenai,
  @JsonValue('openai-response')
  openaiResponse,
  @JsonValue('vertexai')
  vertexai,
  @JsonValue('mistral')
  mistral,
  @JsonValue('aws-bedrock')
  awsBedrock,
  @JsonValue('new-api')
  newApi,
  @JsonValue('ai-gateway')
  aiGateway,
  @JsonValue('custom')
  custom,
}

/// AI 模型信息
@JsonSerializable()
class AIModel {
  final String id;
  final String name;
  final String? provider;
  final String? group;
  final String? description;
  final int? contextLength;
  final int? maxOutputTokens;

  AIModel({
    required this.id,
    required this.name,
    this.provider,
    this.group,
    this.description,
    this.contextLength,
    this.maxOutputTokens,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) => _$AIModelFromJson(json);
  Map<String, dynamic> toJson() => _$AIModelToJson(this);

  /// 显示名称，优先使用 name，否则使用 id
  String get displayName => name.isNotEmpty ? name : id;
}

/// AI Provider 配置
/// 参考 Cherry Studio 的 Provider 接口
/// Provider 来源
enum ProviderSource {
  @JsonValue('manual')
  manual, // 用户手动添加
  @JsonValue('cherry_studio')
  cherryStudio, // 从 Cherry Studio 导入
}

@JsonSerializable(explicitToJson: true)
class AIProvider {
  final String id;
  final String name;
  @JsonKey(unknownEnumValue: AIProviderType.custom)
  final AIProviderType type;
  final String apiKey;
  final String apiHost;
  final List<AIModel> models;
  final bool enabled;
  final bool isSystem;
  final String? apiVersion; // Azure OpenAI 需要
  final String? notes;
  final Map<String, String>? extraHeaders;

  /// Provider 来源（manual: 手动添加, cherry_studio: 从 Cherry Studio 导入）
  @JsonKey(defaultValue: ProviderSource.cherryStudio)
  final ProviderSource source;

  AIProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.apiKey,
    required this.apiHost,
    this.models = const [],
    this.enabled = true,
    this.isSystem = false,
    this.apiVersion,
    this.notes,
    this.extraHeaders,
    ProviderSource? source,
  }) : source = source ?? ProviderSource.cherryStudio;

  factory AIProvider.fromJson(Map<String, dynamic> json) =>
      _$AIProviderFromJson(json);

  Map<String, dynamic> toJson() => _$AIProviderToJson(this);

  /// 从 Cherry Studio 导出数据中解析 Provider
  factory AIProvider.fromCherryStudio(Map<String, dynamic> json) {
    // 解析 type
    final typeStr = json['type'] as String? ?? 'custom';
    AIProviderType type;
    try {
      type = AIProviderType.values.firstWhere(
        (e) => e.name == typeStr || _cherryTypeToEnum(typeStr) == e,
        orElse: () => AIProviderType.custom,
      );
    } catch (_) {
      type = AIProviderType.custom;
    }

    // 解析 models
    final modelsJson = json['models'] as List<dynamic>? ?? [];
    final models = modelsJson
        .map((m) => AIModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return AIProvider(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: type,
      apiKey: json['apiKey'] as String? ?? '',
      apiHost: json['apiHost'] as String? ?? '',
      models: models,
      enabled: json['enabled'] as bool? ?? true,
      isSystem: json['isSystem'] as bool? ?? false,
      apiVersion: json['apiVersion'] as String?,
      notes: json['notes'] as String?,
      extraHeaders: (json['extra_headers'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      source: ProviderSource.cherryStudio, // 标记为从 Cherry Studio 导入
    );
  }

  /// 是否配置有效（有 API Key 和 API Host）
  bool get isValid => apiKey.isNotEmpty && apiHost.isNotEmpty;

  /// 复制并修改
  AIProvider copyWith({
    String? id,
    String? name,
    AIProviderType? type,
    String? apiKey,
    String? apiHost,
    List<AIModel>? models,
    bool? enabled,
    bool? isSystem,
    String? apiVersion,
    String? notes,
    Map<String, String>? extraHeaders,
    ProviderSource? source,
  }) {
    return AIProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      apiKey: apiKey ?? this.apiKey,
      apiHost: apiHost ?? this.apiHost,
      models: models ?? this.models,
      enabled: enabled ?? this.enabled,
      isSystem: isSystem ?? this.isSystem,
      apiVersion: apiVersion ?? this.apiVersion,
      notes: notes ?? this.notes,
      extraHeaders: extraHeaders ?? this.extraHeaders,
      source: source ?? this.source,
    );
  }
}

/// Cherry Studio type 字符串到枚举的映射
AIProviderType _cherryTypeToEnum(String typeStr) {
  switch (typeStr) {
    case 'openai':
      return AIProviderType.openai;
    case 'anthropic':
      return AIProviderType.anthropic;
    case 'gemini':
      return AIProviderType.gemini;
    case 'azure-openai':
      return AIProviderType.azureOpenai;
    case 'openai-response':
      return AIProviderType.openaiResponse;
    case 'vertexai':
      return AIProviderType.vertexai;
    case 'mistral':
      return AIProviderType.mistral;
    case 'aws-bedrock':
      return AIProviderType.awsBedrock;
    case 'new-api':
      return AIProviderType.newApi;
    case 'ai-gateway':
      return AIProviderType.aiGateway;
    default:
      return AIProviderType.custom;
  }
}

/// Provider 类型的显示名称
extension AIProviderTypeExtension on AIProviderType {
  String get displayName {
    switch (this) {
      case AIProviderType.openai:
        return 'OpenAI';
      case AIProviderType.anthropic:
        return 'Anthropic';
      case AIProviderType.gemini:
        return 'Google Gemini';
      case AIProviderType.azureOpenai:
        return 'Azure OpenAI';
      case AIProviderType.openaiResponse:
        return 'OpenAI Responses';
      case AIProviderType.vertexai:
        return 'Vertex AI';
      case AIProviderType.mistral:
        return 'Mistral';
      case AIProviderType.awsBedrock:
        return 'AWS Bedrock';
      case AIProviderType.newApi:
        return 'New API';
      case AIProviderType.aiGateway:
        return 'AI Gateway';
      case AIProviderType.custom:
        return '自定义';
    }
  }
}
