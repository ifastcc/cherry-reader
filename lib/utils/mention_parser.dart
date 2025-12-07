import '../services/multi_model_service.dart';

/// @mention 解析结果
class MentionParseResult {
  /// 原始文本
  final String originalText;

  /// 去除 @mention 后的纯文本
  final String cleanText;

  /// 解析出的模型列表
  final List<MentionedModel> mentionedModels;

  MentionParseResult({
    required this.originalText,
    required this.cleanText,
    required this.mentionedModels,
  });

  /// 是否有提及模型
  bool get hasMentions => mentionedModels.isNotEmpty;

  /// 获取模型配置列表（用于 MultiModelService）
  List<Map<String, String>> get modelConfigs {
    return mentionedModels
        .map((m) => {'providerId': m.providerId, 'modelId': m.modelId})
        .toList();
  }
}

/// 被提及的模型
class MentionedModel {
  final String providerId;
  final String providerName;
  final String modelId;
  final String modelName;
  final String displayName;

  MentionedModel({
    required this.providerId,
    required this.providerName,
    required this.modelId,
    required this.modelName,
    required this.displayName,
  });
}

/// @mention 解析器
///
/// 支持格式：
/// - @模型名 - 模糊匹配
/// - @"模型名" - 精确匹配（带引号）
/// - @provider/model - Provider/Model 格式
class MentionParser {
  final MultiModelService _multiModelService = MultiModelService.instance;

  /// 解析文本中的 @mention
  MentionParseResult parse(String text) {
    final mentionedModels = <MentionedModel>[];
    var cleanText = text;

    // 匹配模式：@"xxx" 或 @xxx（到空格或中文字符为止）
    final mentionRegex = RegExp(r'@"([^"]+)"|@([\w\-\.\/]+)');

    final matches = mentionRegex.allMatches(text);

    for (final match in matches) {
      // 提取模型名（带引号或不带引号）
      final modelQuery = match.group(1) ?? match.group(2) ?? '';

      if (modelQuery.isEmpty) continue;

      // 搜索匹配的模型
      final matchedModel = _findModel(modelQuery);

      if (matchedModel != null) {
        mentionedModels.add(matchedModel);
        // 从文本中移除 @mention
        cleanText = cleanText.replaceFirst(match.group(0)!, '');
      }
    }

    // 清理多余空格
    cleanText = cleanText.trim().replaceAll(RegExp(r'\s+'), ' ');

    return MentionParseResult(
      originalText: text,
      cleanText: cleanText,
      mentionedModels: mentionedModels,
    );
  }

  /// 查找匹配的模型
  MentionedModel? _findModel(String query) {
    final availableModels = _multiModelService.getAvailableModels();

    if (availableModels.isEmpty) return null;

    final lowerQuery = query.toLowerCase();

    // 1. 精确匹配 modelId
    for (final m in availableModels) {
      if ((m['modelId'] as String).toLowerCase() == lowerQuery) {
        return MentionedModel(
          providerId: m['providerId'] as String,
          providerName: m['providerName'] as String,
          modelId: m['modelId'] as String,
          modelName: m['modelName'] as String,
          displayName: m['displayName'] as String,
        );
      }
    }

    // 2. 精确匹配 modelName
    for (final m in availableModels) {
      if ((m['modelName'] as String).toLowerCase() == lowerQuery) {
        return MentionedModel(
          providerId: m['providerId'] as String,
          providerName: m['providerName'] as String,
          modelId: m['modelId'] as String,
          modelName: m['modelName'] as String,
          displayName: m['displayName'] as String,
        );
      }
    }

    // 3. 模糊匹配（包含查询字符串）
    for (final m in availableModels) {
      final modelId = (m['modelId'] as String).toLowerCase();
      final modelName = (m['modelName'] as String).toLowerCase();

      if (modelId.contains(lowerQuery) || modelName.contains(lowerQuery)) {
        return MentionedModel(
          providerId: m['providerId'] as String,
          providerName: m['providerName'] as String,
          modelId: m['modelId'] as String,
          modelName: m['modelName'] as String,
          displayName: m['displayName'] as String,
        );
      }
    }

    // 4. 处理 provider/model 格式
    if (query.contains('/')) {
      final parts = query.split('/');
      if (parts.length == 2) {
        final providerQuery = parts[0].toLowerCase();
        final modelQuery = parts[1].toLowerCase();

        for (final m in availableModels) {
          final providerId = (m['providerId'] as String).toLowerCase();
          final providerName = (m['providerName'] as String).toLowerCase();
          final modelId = (m['modelId'] as String).toLowerCase();
          final modelName = (m['modelName'] as String).toLowerCase();

          final providerMatch =
              providerId.contains(providerQuery) || providerName.contains(providerQuery);
          final modelMatch =
              modelId.contains(modelQuery) || modelName.contains(modelQuery);

          if (providerMatch && modelMatch) {
            return MentionedModel(
              providerId: m['providerId'] as String,
              providerName: m['providerName'] as String,
              modelId: m['modelId'] as String,
              modelName: m['modelName'] as String,
              displayName: m['displayName'] as String,
            );
          }
        }
      }
    }

    return null;
  }

  /// 获取 @ 后面的搜索建议
  ///
  /// [text] 当前输入文本
  /// [cursorPosition] 光标位置
  ///
  /// 返回 (搜索词, 建议列表) 或 null（如果不在 @ 上下文中）
  ({String query, List<Map<String, dynamic>> suggestions})? getSuggestions(
    String text,
    int cursorPosition,
  ) {
    // 查找光标前最近的 @
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) return null;

    // 检查 @ 和光标之间是否有空格（如果有，说明已经完成输入）
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ') && !textAfterAt.startsWith('"')) {
      return null;
    }

    // 提取搜索词
    String query;
    if (textAfterAt.startsWith('"')) {
      // 带引号的情况
      final endQuote = textAfterAt.indexOf('"', 1);
      if (endQuote == -1) {
        query = textAfterAt.substring(1); // 还没输入结束引号
      } else {
        return null; // 已经闭合引号
      }
    } else {
      query = textAfterAt;
    }

    // 搜索模型
    final suggestions = _multiModelService.searchModels(query);

    return (query: query, suggestions: suggestions);
  }

  /// 在文本中插入选中的模型
  ///
  /// [text] 当前文本
  /// [cursorPosition] 光标位置
  /// [model] 选中的模型
  ///
  /// 返回 (新文本, 新光标位置)
  ({String text, int cursorPosition}) insertModel(
    String text,
    int cursorPosition,
    Map<String, dynamic> model,
  ) {
    final textBeforeCursor = text.substring(0, cursorPosition);
    final textAfterCursor = text.substring(cursorPosition);

    // 查找最近的 @
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');
    if (lastAtIndex == -1) {
      return (text: text, cursorPosition: cursorPosition);
    }

    // 构建新的 @mention
    final modelName = model['modelName'] as String;
    final mention = modelName.contains(' ') ? '@"$modelName" ' : '@$modelName ';

    // 替换 @ 到光标之间的内容
    final newText = textBeforeCursor.substring(0, lastAtIndex) + mention + textAfterCursor;
    final newCursorPosition = lastAtIndex + mention.length;

    return (text: newText, cursorPosition: newCursorPosition);
  }
}
