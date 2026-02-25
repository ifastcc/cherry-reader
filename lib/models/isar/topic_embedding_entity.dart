/// 话题 Embedding 实体
///
/// 存储首轮用户问题的向量表示，用于语义搜索
class TopicEmbeddingEntity {
  /// 话题 ID（唯一索引）
  late String topicId;

  /// 首轮用户问题文本（方便调试和展示）
  late String firstQueryText;

  /// Embedding 向量（1024 维）
  late List<double> embedding;

  /// 使用的模型名称（方便未来升级模型时重新生成）
  late String modelName;

  /// 生成时间
  late int createdAt;

  /// 构造函数
  TopicEmbeddingEntity();

  /// 从数据创建
  factory TopicEmbeddingEntity.fromData({
    required String topicId,
    required String firstQueryText,
    required List<double> embedding,
    required String modelName,
  }) {
    return TopicEmbeddingEntity()
      ..topicId = topicId
      ..firstQueryText = firstQueryText
      ..embedding = embedding
      ..modelName = modelName
      ..createdAt = DateTime.now().millisecondsSinceEpoch;
  }
}
