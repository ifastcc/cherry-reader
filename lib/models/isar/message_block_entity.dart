/// 消息块 Isar 实体
///
/// 存储消息的实际内容，包括文本、思考过程、图片等
/// 支持的类型：main_text, thinking, image, file, tool, citation, error, translation, code, video
class MessageBlockEntity {
  /// 消息块 ID（唯一索引）
  late String blockId;

  /// 所属话题 ID（用于快速批量查询）
  late String topicId;

  /// 所属消息 ID（复合索引：messageId + orderIndex）
  late String messageId;

  /// 在消息中的顺序
  late int orderIndex;

  /// 块类型：main_text, thinking, image, file, tool, citation, error, translation, code, video
  late String type;

  /// 主要文本内容（长文本）
  String? content;

  /// thinking 块：思考时间（毫秒）
  double? thinkingMillsec;

  /// image 块：图片 URL
  String? url;

  /// file 块：文件信息 (JSON)
  String? fileJson;

  /// tool 块：工具调用信息 (JSON)
  String? toolJson;

  /// error 块：错误信息 (JSON)
  String? errorJson;

  /// translation 块：目标语言
  String? targetLanguage;

  /// citation 块：响应信息 (JSON)
  String? responseJson;

  /// citation 块：知识库信息 (JSON)
  String? knowledgeJson;

  /// 关联的文件 ID（用于 image/file 块）
  String? fileId;

  /// 创建时间（毫秒时间戳）
  late int createdAt;

  /// 构造函数
  MessageBlockEntity();

  /// 从数据创建
  factory MessageBlockEntity.fromData({
    required String blockId,
    required String topicId,
    required String messageId,
    required int orderIndex,
    required String type,
    String? content,
    double? thinkingMillsec,
    String? url,
    String? fileJson,
    String? toolJson,
    String? errorJson,
    String? targetLanguage,
    String? responseJson,
    String? knowledgeJson,
    String? fileId,
    required int createdAt,
  }) {
    return MessageBlockEntity()
      ..blockId = blockId
      ..topicId = topicId
      ..messageId = messageId
      ..orderIndex = orderIndex
      ..type = type
      ..content = content
      ..thinkingMillsec = thinkingMillsec
      ..url = url
      ..fileJson = fileJson
      ..toolJson = toolJson
      ..errorJson = errorJson
      ..targetLanguage = targetLanguage
      ..responseJson = responseJson
      ..knowledgeJson = knowledgeJson
      ..fileId = fileId
      ..createdAt = createdAt;
  }

  /// 是否为主要文本块
  bool get isMainText => type == 'main_text';

  /// 是否为思考块
  bool get isThinking => type == 'thinking';

  /// 是否为图片块
  bool get isImage => type == 'image';

  /// 是否为文件块
  bool get isFile => type == 'file';

  /// 是否为工具调用块
  bool get isTool => type == 'tool';

  /// 是否为错误块
  bool get isError => type == 'error';
}
