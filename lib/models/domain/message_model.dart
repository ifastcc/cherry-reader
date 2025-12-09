import 'dart:convert';

/// 消息领域模型（与数据库无关）
///
/// 用于 Repository 层和 UI 层的数据传输
/// 存储消息的元数据，不存储 block 内容
class MessageModel {
  final String messageId;
  final String topicId;
  final int orderIndex;
  final int roundIndex;
  final String role;
  final String? askId;
  final bool useful;
  final String? modelId;
  final String? modelName;
  final int createdAt;
  final String status;

  // 可选的 JSON 字段
  final Map<String, dynamic>? usage;
  final Map<String, dynamic>? metrics;
  final List<Map<String, dynamic>>? mentions;

  const MessageModel({
    required this.messageId,
    required this.topicId,
    required this.orderIndex,
    required this.roundIndex,
    required this.role,
    this.askId,
    required this.useful,
    this.modelId,
    this.modelName,
    required this.createdAt,
    required this.status,
    this.usage,
    this.metrics,
    this.mentions,
  });

  /// 是否为用户消息
  bool get isUser => role == 'user';

  /// 是否为助手消息
  bool get isAssistant => role == 'assistant';

  /// 获取模型显示名称
  String get displayModelName => modelName ?? modelId ?? '未知模型';

  /// 从 JSON 字符串解析 usage
  static Map<String, dynamic>? parseUsageJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 从 JSON 字符串解析 metrics
  static Map<String, dynamic>? parseMetricsJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 从 JSON 字符串解析 mentions
  static List<Map<String, dynamic>>? parseMentionsJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 创建副本
  MessageModel copyWith({
    String? messageId,
    String? topicId,
    int? orderIndex,
    int? roundIndex,
    String? role,
    String? askId,
    bool? useful,
    String? modelId,
    String? modelName,
    int? createdAt,
    String? status,
    Map<String, dynamic>? usage,
    Map<String, dynamic>? metrics,
    List<Map<String, dynamic>>? mentions,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      topicId: topicId ?? this.topicId,
      orderIndex: orderIndex ?? this.orderIndex,
      roundIndex: roundIndex ?? this.roundIndex,
      role: role ?? this.role,
      askId: askId ?? this.askId,
      useful: useful ?? this.useful,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      usage: usage ?? this.usage,
      metrics: metrics ?? this.metrics,
      mentions: mentions ?? this.mentions,
    );
  }

  @override
  String toString() =>
      'MessageModel(id: $messageId, role: $role, round: $roundIndex, order: $orderIndex)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;
}
