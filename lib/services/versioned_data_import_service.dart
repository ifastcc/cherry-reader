import 'dart:convert';
import 'package:isar_community/isar.dart';
import '../models/isar/assistant_entity.dart';
import '../models/isar/topic_entity.dart';
import '../models/isar/message_entity.dart';
import '../models/isar/message_block_entity.dart';
import '../models/isar/file_entity.dart';
import '../models/isar/topic_embedding_entity.dart';
import 'cherry_extractor.dart';
import 'embedding_service.dart';

/// 版本化数据导入服务
///
/// 与 DataImportService 类似，但用于导入到指定的 Isar 实例（版本数据库）
/// 特性：
/// - 直接接受 Isar 实例，不依赖 IsarDatabase
/// - 无断点续传（版本数据库是新建的，导入失败则删除整个版本）
/// - 分批事务（每 50 个话题一个事务），避免长事务锁定
class VersionedDataImportService {
  final Isar _isar;
  final CherryExtractor _extractor;

  VersionedDataImportService(this._isar, this._extractor);

  /// 从 Cherry Studio 导出文件导入数据
  ///
  /// [onProgress] 进度回调 (progress: 0.0-1.0, message: 状态描述)
  /// [generateEmbeddings] 是否生成首轮问题的 embedding（需要配置 API Key）
  Future<ImportResult> importFromExtractor({
    void Function(double progress, String message)? onProgress,
    bool generateEmbeddings = true,
  }) async {
    final result = ImportResult();

    try {
      // 1. 获取所有话题（先统计，用于去重）
      final groupedTopics = _extractor.getTopicsByAssistant();
      final allTopics = <Map<String, dynamic>>[];
      final seenTopicIds = <String>{}; // 防止同一 topic 被多个 assistant 引用导致重复

      for (final entry in groupedTopics.entries) {
        final topics = entry.value['topics'] as List<dynamic>? ?? [];
        for (final topic in topics) {
          if (topic is! Map<String, dynamic>) continue;
          final topicId = topic['id'] as String?;
          if (topicId == null) continue;

          // 去重：同一个 topic 只导入一次
          if (seenTopicIds.contains(topicId)) {
            continue;
          }
          seenTopicIds.add(topicId);

          allTopics.add({
            'assistantId': entry.key,
            'topic': topic,
          });
        }
      }

      result.totalTopics = allTopics.length;

      // 2. 导入 Assistants
      onProgress?.call(0.05, '正在导入助手信息...');
      await _importAssistants();

      // 3. 导入 Files
      onProgress?.call(0.08, '正在导入文件信息...');
      result.importedFiles = await _importFiles();

      onProgress?.call(0.1, '开始导入 ${allTopics.length} 个话题...');

      // 4. 分批导入（每批 50 个话题）
      const batchSize = 50;

      for (var i = 0; i < allTopics.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, allTopics.length);
        final batch = allTopics.sublist(i, end);

        // 每批一个事务
        await _isar.writeTxn(() async {
          for (final item in batch) {
            final importedMessages = await _importTopic(
              item['assistantId'] as String,
              item['topic'] as Map<String, dynamic>,
            );
            result.importedMessages += importedMessages;
          }
        });

        result.importedTopics = end;

        final progress = 0.1 + 0.75 * end / allTopics.length;
        onProgress?.call(progress, '已导入 $end/${allTopics.length} 个话题...');
      }

      // 5. 更新 Assistant 的 topicCount
      onProgress?.call(0.86, '正在更新统计信息...');
      await _updateAssistantTopicCounts();

      // 6. 生成 Embedding（如果配置了 API Key）
      if (generateEmbeddings && EmbeddingService.instance.isConfigured) {
        onProgress?.call(0.88, '正在生成语义索引...');
        result.embeddingsGenerated = await _generateEmbeddings(
          onProgress: (embProgress, msg) {
            final progress = 0.88 + 0.1 * embProgress;
            onProgress?.call(progress, msg);
          },
        );
      }

      result.success = true;
      onProgress?.call(1.0, '导入完成');
    } catch (e) {
      result.success = false;
      result.error = e.toString();
      print('❌ 导入失败: $e');
    }

    return result;
  }

  /// 生成首轮问题的 Embedding
  ///
  /// 返回成功生成的数量
  Future<int> _generateEmbeddings({
    void Function(double progress, String message)? onProgress,
  }) async {
    // 获取所有话题
    final topics = await _isar.topicEntitys.where().findAll();
    if (topics.isEmpty) return 0;

    // 收集所有首轮用户问题
    final topicFirstQueries = <String, String>{}; // topicId -> firstQuery

    for (final topic in topics) {
      // 获取该话题的首轮用户消息
      final firstUserMsg = await _isar.messageEntitys
          .filter()
          .topicIdEqualTo(topic.topicId)
          .roleEqualTo('user')
          .sortByRoundIndex()
          .findFirst();

      if (firstUserMsg == null) continue;

      // 获取该消息的 main_text block
      final blocks = await _isar.messageBlockEntitys
          .filter()
          .messageIdEqualTo(firstUserMsg.messageId)
          .typeEqualTo('main_text')
          .findAll();

      final content = blocks.map((b) => b.content ?? '').join().trim();
      if (content.isNotEmpty) {
        topicFirstQueries[topic.topicId] = content;
      }
    }

    if (topicFirstQueries.isEmpty) return 0;

    // 批量生成 embedding
    final topicIds = topicFirstQueries.keys.toList();
    final queries = topicFirstQueries.values.toList();

    onProgress?.call(0.1, '正在调用 AI 生成语义索引 (${queries.length} 条)...');

    final embeddings = await EmbeddingService.instance.embedBatch(queries);

    // 保存到数据库
    int successCount = 0;
    final embeddingEntities = <TopicEmbeddingEntity>[];

    for (var i = 0; i < topicIds.length; i++) {
      final embedding = embeddings[i];
      if (embedding != null) {
        embeddingEntities.add(TopicEmbeddingEntity.fromData(
          topicId: topicIds[i],
          firstQueryText: queries[i],
          embedding: embedding,
          modelName: 'BAAI/bge-large-zh-v1.5',
        ));
        successCount++;
      }
    }

    if (embeddingEntities.isNotEmpty) {
      await _isar.writeTxn(() async {
        for (final entity in embeddingEntities) {
          await _isar.topicEmbeddingEntitys.putByIndex('topicId', entity);
        }
      });
    }

    onProgress?.call(1.0, '语义索引生成完成 ($successCount/${topicIds.length})');
    return successCount;
  }

  /// 导入 Assistants
  Future<void> _importAssistants() async {
    final assistants = _extractor.getAssistants();

    await _isar.writeTxn(() async {
      for (final asst in assistants) {
        if (asst is! Map<String, dynamic>) continue;

        final entity = AssistantEntity.fromData(
          assistantId: asst['id'] as String? ?? '',
          name: asst['name'] as String? ?? '未命名助手',
          description: asst['description'] as String?,
          avatar: asst['avatar'] as String?,
          prompt: asst['prompt'] as String?,
          topicCount: 0, // 后面更新
        );

        await _isar.assistantEntitys.putByIndex('assistantId', entity);
      }
    });
  }

  /// 导入 Files
  Future<int> _importFiles() async {
    final files = _extractor.files;

    if (files.isEmpty) {
      return 0;
    }

    int importedCount = 0;

    await _isar.writeTxn(() async {
      for (final file in files) {
        if (file is! Map<String, dynamic>) continue;

        final fileId = file['id'] as String?;
        if (fileId == null || fileId.isEmpty) continue;

        // 优先使用 origin_name，其次 name
        final fileName =
            file['origin_name'] as String? ?? file['name'] as String?;

        // 推断 MIME 类型
        final ext = file['ext'] as String?;
        final fileType = file['type'] as String?;
        final mimeType = _inferMimeType(ext, fileType);

        // 文件大小
        final size = file['size'];
        final fileSize =
            size is int ? size : (size is num ? size.toInt() : null);

        // 引用计数
        final count = file['count'];
        final referenceCount =
            count is int ? count : (count is num ? count.toInt() : 1);

        // 创建时间
        final createdAt = _parseTimestamp(file['created_at']);

        final entity = FileEntity.fromData(
          fileId: fileId,
          fileName: fileName,
          mimeType: mimeType,
          fileSize: fileSize,
          localPath: file['path'] as String?, // Cherry Studio 原始路径
          referenceCount: referenceCount,
          createdAt: createdAt,
        );

        await _isar.fileEntitys.putByIndex('fileId', entity);
        importedCount++;
      }
    });

    return importedCount;
  }

  /// 根据扩展名和文件类型推断 MIME 类型
  String? _inferMimeType(String? ext, String? fileType) {
    if (ext == null && fileType == null) return null;

    // 常见扩展名映射
    final extMimeMap = <String, String>{
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.svg': 'image/svg+xml',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.txt': 'text/plain',
      '.md': 'text/markdown',
      '.json': 'application/json',
      '.xml': 'application/xml',
      '.csv': 'text/csv',
      '.mp3': 'audio/mpeg',
      '.mp4': 'video/mp4',
      '.wav': 'audio/wav',
      '.zip': 'application/zip',
    };

    if (ext != null) {
      final normalizedExt =
          ext.startsWith('.') ? ext.toLowerCase() : '.$ext'.toLowerCase();
      if (extMimeMap.containsKey(normalizedExt)) {
        return extMimeMap[normalizedExt];
      }
    }

    // 根据 fileType 推断（Cherry Studio 的 FileTypes）
    if (fileType != null) {
      switch (fileType.toLowerCase()) {
        case 'image':
          return 'image/*';
        case 'document':
        case 'file':
          return 'application/octet-stream';
        case 'audio':
          return 'audio/*';
        case 'video':
          return 'video/*';
      }
    }

    return null;
  }

  /// 更新 Assistant 的 topicCount
  Future<void> _updateAssistantTopicCounts() async {
    final assistants = await _isar.assistantEntitys.where().findAll();

    await _isar.writeTxn(() async {
      for (final asst in assistants) {
        final count = await _isar.topicEntitys
            .filter()
            .assistantIdEqualTo(asst.assistantId)
            .count();
        asst.topicCount = count;
        await _isar.assistantEntitys.putByIndex('assistantId', asst);
      }
    });
  }

  /// 导入单个话题
  ///
  /// 返回导入的消息数量
  Future<int> _importTopic(
    String assistantId,
    Map<String, dynamic> topicData,
  ) async {
    final topicId = topicData['id'] as String;
    final messages = topicData['messages'] as List<dynamic>? ?? [];

    // 计算统计信息 + 构建轮次映射（按 askId 分组）
    int roundCount = 0;
    int currentRound = -1;
    String? currentAskId;
    final roundMap = <int, int>{}; // messageIndex -> roundIndex

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i] as Map<String, dynamic>;
      final askId = msg['askId'] as String?;
      final role = msg['role'] as String?;

      if (askId != null && askId != currentAskId) {
        currentRound++;
        roundCount++;
        currentAskId = askId;
      } else if (role == 'user' && askId == null) {
        // 没有 askId 的用户消息也开启新轮次
        currentRound++;
        roundCount++;
      }

      roundMap[i] = currentRound >= 0 ? currentRound : 0;
    }

    // 保存 Topic
    final topicEntity = TopicEntity.fromData(
      topicId: topicId,
      name: topicData['name'] as String? ?? '未命名话题',
      assistantId: assistantId,
      messageCount: messages.length,
      roundCount: roundCount,
      createdAt: _parseTimestamp(topicData['createdAt']),
      updatedAt: _parseTimestamp(topicData['updatedAt']),
    );

    // 使用 putByIndex 而不是 put，确保相同 topicId 时更新而非插入
    await _isar.topicEntitys.putByIndex('topicId', topicEntity);

    // 保存 Messages 和 Blocks
    for (var i = 0; i < messages.length; i++) {
      final msgData = messages[i] as Map<String, dynamic>;
      await _importMessage(
        topicId,
        msgData,
        orderIndex: i,
        roundIndex: roundMap[i]!,
      );
    }

    return messages.length;
  }

  /// 导入单条消息
  Future<void> _importMessage(
    String topicId,
    Map<String, dynamic> msgData, {
    required int orderIndex,
    required int roundIndex,
  }) async {
    final messageId = msgData['id'] as String;
    final blockIds =
        (msgData['blocks'] as List<dynamic>?)?.cast<String>() ?? [];

    // 保存 Message
    final messageEntity = MessageEntity.fromData(
      messageId: messageId,
      topicId: topicId,
      orderIndex: orderIndex,
      roundIndex: roundIndex,
      role: msgData['role'] as String? ?? 'user',
      askId: msgData['askId'] as String?,
      useful: msgData['useful'] as bool? ?? false,
      modelId: (msgData['model'] as Map<String, dynamic>?)?['id'] as String?,
      modelName:
          (msgData['model'] as Map<String, dynamic>?)?['name'] as String?,
      usageJson:
          msgData['usage'] != null ? jsonEncode(msgData['usage']) : null,
      metricsJson:
          msgData['metrics'] != null ? jsonEncode(msgData['metrics']) : null,
      mentionsJson:
          msgData['mentions'] != null ? jsonEncode(msgData['mentions']) : null,
      createdAt: _parseTimestamp(msgData['createdAt']),
      status: msgData['status'] as String? ?? 'completed',
    );

    await _isar.messageEntitys.putByIndex('messageId', messageEntity);

    // 保存 Blocks（从 CherryExtractor.blockMap 获取实际内容）
    for (var j = 0; j < blockIds.length; j++) {
      final blockId = blockIds[j];
      // ⚠️ 关键：通过 blockMap 获取 block 内容
      final blockData = _extractor.blockMap[blockId];

      if (blockData != null && blockData is Map<String, dynamic>) {
        final blockEntity = MessageBlockEntity.fromData(
          blockId: blockId,
          topicId: topicId, // 【优化】添加 topicId 支持快速查询
          messageId: messageId,
          orderIndex: j,
          type: blockData['type'] as String? ?? 'main_text',
          // content 可能是 String 或 Map（如 tool 类型的 block）
          content: blockData['content'] is String
              ? blockData['content'] as String
              : (blockData['content'] != null
                  ? jsonEncode(blockData['content'])
                  : null),
          thinkingMillsec:
              (blockData['thinking_millsec'] as num?)?.toDouble(),
          url: blockData['url'] as String?,
          fileJson: blockData['file'] != null
              ? jsonEncode(blockData['file'])
              : null,
          toolJson: blockData['toolId'] != null
              ? jsonEncode({
                  'toolId': blockData['toolId'],
                  'toolName': blockData['toolName'],
                  'arguments': blockData['arguments'],
                })
              : null,
          errorJson: blockData['error'] != null
              ? jsonEncode(blockData['error'])
              : null,
          targetLanguage: blockData['targetLanguage'] as String?,
          // citation 块字段
          responseJson: blockData['response'] != null
              ? jsonEncode(blockData['response'])
              : null,
          knowledgeJson: blockData['knowledge'] != null
              ? jsonEncode(blockData['knowledge'])
              : null,
          // 文件关联
          fileId: blockData['fileId'] as String?,
          createdAt: _parseTimestamp(blockData['createdAt']),
        );

        await _isar.messageBlockEntitys.putByIndex('blockId', blockEntity);
      } else {
        // Block 数据丢失时创建占位符
        final placeholder = MessageBlockEntity.fromData(
          blockId: blockId,
          topicId: topicId, // 【优化】添加 topicId 支持快速查询
          messageId: messageId,
          orderIndex: j,
          type: 'error',
          content: '[Block 数据丢失: $blockId]',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _isar.messageBlockEntitys.putByIndex('blockId', placeholder);
      }
    }
  }

  /// 解析时间戳
  int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}

/// 导入结果
class ImportResult {
  bool success = false;
  String? error;
  int totalTopics = 0;
  int importedTopics = 0;
  int importedMessages = 0;
  int importedFiles = 0;
  int embeddingsGenerated = 0;

  @override
  String toString() {
    if (success) {
      final embStr = embeddingsGenerated > 0 ? ', $embeddingsGenerated 条语义索引' : '';
      return '导入成功: $importedTopics 个话题, $importedMessages 条消息, $importedFiles 个文件$embStr';
    } else {
      return '导入失败: $error (已导入 $importedTopics/$totalTopics 个话题)';
    }
  }
}
