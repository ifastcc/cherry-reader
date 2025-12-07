/// 结构化上下文数据模型
///
/// 用于将 contextSnapshot 解析为结构化数据，便于 UI 展示
/// 支持两种入口：
/// - singleMessage: 单个 AI 回复的讨论
/// - messageGroup: 一轮对话的元分析（多个模型回复）

import '../models/isar/unified_conversation_entity.dart';

/// 模型回复数据
class ModelResponse {
  final String modelName;
  final String content;
  final String summary; // 前100字摘要
  final int charCount;

  ModelResponse({
    required this.modelName,
    required this.content,
    required this.summary,
    required this.charCount,
  });

  /// 从内容创建
  factory ModelResponse.fromContent(String modelName, String content) {
    final trimmed = content.trim();
    final summary = trimmed.length > 100
        ? '${trimmed.substring(0, 100)}...'
        : trimmed;

    return ModelResponse(
      modelName: modelName,
      content: trimmed,
      summary: summary,
      charCount: trimmed.length,
    );
  }

  /// 获取格式化的字数显示
  String get sizeDisplay {
    if (charCount >= 10000) {
      return '${(charCount / 10000).toStringAsFixed(1)}万字';
    } else if (charCount >= 1000) {
      return '${(charCount / 1000).toStringAsFixed(1)}千字';
    }
    return '$charCount 字';
  }
}

/// 结构化上下文
class StructuredContext {
  /// System Prompt（可选，通常从用户偏好获取）
  final String? systemPrompt;

  /// 用户问题（可选）
  final String? userQuery;

  /// 模型回复列表
  final List<ModelResponse> responses;

  /// 原始完整内容（用于实际发送）
  final String rawContent;

  /// 上下文类型
  final ConversationContextType contextType;

  StructuredContext({
    this.systemPrompt,
    this.userQuery,
    required this.responses,
    required this.rawContent,
    required this.contextType,
  });

  /// 从 contextSnapshot 解析
  factory StructuredContext.parse(
    String content,
    ConversationContextType type,
  ) {
    switch (type) {
      case ConversationContextType.singleMessage:
        return _parseSingleMessage(content);
      case ConversationContextType.messageGroup:
        return _parseMessageGroup(content);
      case ConversationContextType.topic:
        return _parseTopic(content);
    }
  }

  /// 解析单消息讨论
  static StructuredContext _parseSingleMessage(String content) {
    // singleMessage: 整个内容就是一个 AI 回复
    final response = ModelResponse.fromContent('AI 回复', content);

    return StructuredContext(
      userQuery: null,
      responses: [response],
      rawContent: content,
      contextType: ConversationContextType.singleMessage,
    );
  }

  /// 解析消息组分析（多模型回复）
  static StructuredContext _parseMessageGroup(String content) {
    // messageGroup 格式：
    // ## 用户问题
    // [问题内容]
    // ## 模型回复
    // ### Model1
    // [回复内容]
    // ### Model2
    // [回复内容]

    String? userQuery;
    final responses = <ModelResponse>[];

    // 提取用户问题
    final userQueryMatch = RegExp(
      r'##\s*用户问题\s*\n\n([\s\S]*?)(?=\n##\s*模型回复|\n###|\z)',
      multiLine: true,
    ).firstMatch(content);

    if (userQueryMatch != null) {
      userQuery = userQueryMatch.group(1)?.trim();
    }

    // 提取模型回复
    final modelMatches = RegExp(
      r'###\s*(.+?)\s*\n\n([\s\S]*?)(?=\n###|\z)',
      multiLine: true,
    ).allMatches(content);

    for (final match in modelMatches) {
      final modelName = match.group(1)?.trim() ?? 'Unknown';
      final modelContent = match.group(2)?.trim() ?? '';

      if (modelContent.isNotEmpty) {
        responses.add(ModelResponse.fromContent(modelName, modelContent));
      }
    }

    // 如果没有解析到任何回复，将整个内容作为一个回复
    if (responses.isEmpty) {
      responses.add(ModelResponse.fromContent('回复', content));
    }

    return StructuredContext(
      userQuery: userQuery,
      responses: responses,
      rawContent: content,
      contextType: ConversationContextType.messageGroup,
    );
  }

  /// 解析独立话题
  static StructuredContext _parseTopic(String content) {
    // topic: 可能是自由格式，暂时作为单个内容处理
    final response = ModelResponse.fromContent('内容', content);

    return StructuredContext(
      responses: [response],
      rawContent: content,
      contextType: ConversationContextType.topic,
    );
  }

  /// 是否有多个回复（用于决定显示网格还是单卡片）
  bool get hasMultipleResponses => responses.length > 1;

  /// 获取摘要描述（用于 Chip 显示）
  String get summaryDescription {
    if (responses.isEmpty) return '无内容';

    if (responses.length == 1) {
      return responses.first.sizeDisplay;
    }

    final totalSize = responses.fold<int>(0, (sum, r) => sum + r.charCount);
    String sizeStr;
    if (totalSize >= 10000) {
      sizeStr = '${(totalSize / 10000).toStringAsFixed(1)}万字';
    } else if (totalSize >= 1000) {
      sizeStr = '${(totalSize / 1000).toStringAsFixed(1)}千字';
    } else {
      sizeStr = '$totalSize 字';
    }

    return '${responses.length}条回复 ($sizeStr)';
  }

  /// 获取总字符数
  int get totalCharCount => responses.fold<int>(0, (sum, r) => sum + r.charCount);

  /// 移除指定索引的回复，返回新的 StructuredContext
  StructuredContext removeResponseAt(int index) {
    if (index < 0 || index >= responses.length) return this;

    final newResponses = List<ModelResponse>.from(responses)..removeAt(index);

    // 重新生成 rawContent
    final buffer = StringBuffer();
    if (userQuery != null && userQuery!.isNotEmpty) {
      buffer.writeln('## 用户问题\n');
      buffer.writeln(userQuery);
      buffer.writeln();
    }

    if (newResponses.isNotEmpty) {
      buffer.writeln('## 模型回复\n');
      for (final response in newResponses) {
        buffer.writeln('### ${response.modelName}\n');
        buffer.writeln(response.content);
        buffer.writeln();
      }
    }

    return StructuredContext(
      systemPrompt: systemPrompt,
      userQuery: userQuery,
      responses: newResponses,
      rawContent: buffer.toString().trim(),
      contextType: contextType,
    );
  }

  /// 创建一个带有更新 responses 的副本
  StructuredContext copyWith({
    String? systemPrompt,
    String? userQuery,
    List<ModelResponse>? responses,
    String? rawContent,
  }) {
    return StructuredContext(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      userQuery: userQuery ?? this.userQuery,
      responses: responses ?? this.responses,
      rawContent: rawContent ?? this.rawContent,
      contextType: contextType,
    );
  }
}
