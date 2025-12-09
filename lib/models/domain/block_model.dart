import 'dart:convert';

/// 消息块类型常量
class BlockType {
  static const String mainText = 'main_text';
  static const String thinking = 'thinking';
  static const String image = 'image';
  static const String file = 'file';
  static const String tool = 'tool';
  static const String citation = 'citation';
  static const String error = 'error';
  static const String translation = 'translation';
  static const String code = 'code';
  static const String video = 'video';
}

/// 消息块领域模型（与数据库无关）
///
/// 用于 Repository 层和 UI 层的数据传输
/// 存储实际的消息内容
class BlockModel {
  final String blockId;
  final String topicId;
  final String messageId;
  final int orderIndex;
  final String type;
  final int createdAt;

  // 通用内容字段
  final String? content;

  // thinking 块特有字段
  final double? thinkingMillsec;

  // image 块特有字段
  final String? url;

  // file 块特有字段（JSON 对象）
  final Map<String, dynamic>? file;

  // tool 块特有字段
  final String? toolId;
  final String? toolName;
  final Map<String, dynamic>? arguments;

  // error 块特有字段
  final Map<String, dynamic>? error;

  // translation 块特有字段
  final String? targetLanguage;

  // citation 块特有字段
  final Map<String, dynamic>? response;
  final Map<String, dynamic>? knowledge;

  const BlockModel({
    required this.blockId,
    required this.topicId,
    required this.messageId,
    required this.orderIndex,
    required this.type,
    required this.createdAt,
    this.content,
    this.thinkingMillsec,
    this.url,
    this.file,
    this.toolId,
    this.toolName,
    this.arguments,
    this.error,
    this.targetLanguage,
    this.response,
    this.knowledge,
  });

  /// 是否为主要文本块
  bool get isMainText => type == BlockType.mainText;

  /// 是否为思考块
  bool get isThinking => type == BlockType.thinking;

  /// 是否为图片块
  bool get isImage => type == BlockType.image;

  /// 是否为文件块
  bool get isFile => type == BlockType.file;

  /// 是否为工具调用块
  bool get isTool => type == BlockType.tool;

  /// 是否为错误块
  bool get isError => type == BlockType.error;

  /// 是否为翻译块
  bool get isTranslation => type == BlockType.translation;

  /// 是否为引用块
  bool get isCitation => type == BlockType.citation;

  /// 获取思考时间（秒）
  double? get thinkingSeconds =>
      thinkingMillsec != null ? thinkingMillsec! / 1000 : null;

  /// 从 JSON 字符串解析 file 对象
  static Map<String, dynamic>? parseFileJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 从 JSON 字符串解析 tool 对象
  static Map<String, dynamic>? parseToolJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 从 JSON 字符串解析 error 对象
  static Map<String, dynamic>? parseErrorJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 创建副本
  BlockModel copyWith({
    String? blockId,
    String? topicId,
    String? messageId,
    int? orderIndex,
    String? type,
    int? createdAt,
    String? content,
    double? thinkingMillsec,
    String? url,
    Map<String, dynamic>? file,
    String? toolId,
    String? toolName,
    Map<String, dynamic>? arguments,
    Map<String, dynamic>? error,
    String? targetLanguage,
    Map<String, dynamic>? response,
    Map<String, dynamic>? knowledge,
  }) {
    return BlockModel(
      blockId: blockId ?? this.blockId,
      topicId: topicId ?? this.topicId,
      messageId: messageId ?? this.messageId,
      orderIndex: orderIndex ?? this.orderIndex,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      thinkingMillsec: thinkingMillsec ?? this.thinkingMillsec,
      url: url ?? this.url,
      file: file ?? this.file,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      arguments: arguments ?? this.arguments,
      error: error ?? this.error,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      response: response ?? this.response,
      knowledge: knowledge ?? this.knowledge,
    );
  }

  @override
  String toString() =>
      'BlockModel(id: $blockId, type: $type, order: $orderIndex)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockModel &&
          runtimeType == other.runtimeType &&
          blockId == other.blockId;

  @override
  int get hashCode => blockId.hashCode;
}
