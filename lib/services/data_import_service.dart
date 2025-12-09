import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/isar/assistant_entity.dart';
import '../models/isar/topic_entity.dart';
import '../models/isar/message_entity.dart';
import '../models/isar/message_block_entity.dart';
import '../models/isar/file_entity.dart';
import 'cherry_extractor.dart';
import 'isar_database.dart';

/// 数据导入服务
///
/// 负责将 Cherry Studio 导出数据导入到新的消息级存储架构
/// 特性：
/// - 分批事务（每 50 个话题一个事务），避免长事务锁定
/// - 支持断点续传（记录进度，失败后可继续）
/// - Block 数据从 CherryExtractor.blockMap 获取
class DataImportService {
  final IsarDatabase _db;
  final CherryExtractor _extractor;

  /// 断点续传：记录已导入的话题索引
  static const String _importProgressKey = 'import_progress';

  /// 导入状态标志
  static const String _importingFlagKey = 'is_importing';

  DataImportService(this._db, this._extractor);

  /// 检查是否有未完成的导入
  Future<bool> hasIncompleteImport() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_importingFlagKey) ?? false;
  }

  /// 获取导入进度
  Future<int> getImportProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_importProgressKey) ?? 0;
  }

  /// 从 Cherry Studio 导出文件导入数据
  ///
  /// [onProgress] 进度回调 (progress: 0.0-1.0, message: 状态描述)
  Future<ImportResult> importFromExtractor({
    void Function(double progress, String message)? onProgress,
    bool continueFromCheckpoint = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final result = ImportResult();

    try {
      // 标记正在导入
      await prefs.setBool(_importingFlagKey, true);

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

      // 2. 检查断点续传
      int startIndex = 0;
      if (continueFromCheckpoint) {
        startIndex = prefs.getInt(_importProgressKey) ?? 0;
        if (startIndex > 0) {
          onProgress?.call(0.05, '从断点继续导入（已完成 $startIndex 个话题）...');
        }
      }

      // 3. 首次导入：清除旧数据并导入 Assistants/Files
      if (startIndex == 0) {
        // 首次导入：清除所有旧数据
        onProgress?.call(0.05, '正在清理旧数据...');
        await _clearOldData();
        await prefs.setInt(_importProgressKey, 0);

        // 导入 Assistants（清理后重新导入）
        onProgress?.call(0.07, '正在导入助手信息...');
        await _importAssistants();

        // 导入 Files
        onProgress?.call(0.09, '正在导入文件信息...');
        result.importedFiles = await _importFiles();
      }

      onProgress?.call(0.1, '开始导入 ${allTopics.length} 个话题...');

      // 4. 分批导入（每批 50 个话题）
      const batchSize = 50;
      final isar = await _db.instance;

      for (var i = startIndex; i < allTopics.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, allTopics.length);
        final batch = allTopics.sublist(i, end);

        // 每批一个事务
        await isar.writeTxn(() async {
          for (final item in batch) {
            final importedMessages = await _importTopic(
              isar,
              item['assistantId'] as String,
              item['topic'] as Map<String, dynamic>,
            );
            result.importedMessages += importedMessages;
          }
        });

        result.importedTopics = end;

        // 保存进度（断点续传）
        await prefs.setInt(_importProgressKey, end);

        final progress = 0.1 + 0.85 * end / allTopics.length;
        onProgress?.call(progress, '已导入 $end/${allTopics.length} 个话题...');
      }

      // 5. 更新 Assistant 的 topicCount
      onProgress?.call(0.96, '正在更新统计信息...');
      await _updateAssistantTopicCounts();

      // 6. 清除进度记录
      await prefs.remove(_importProgressKey);
      await prefs.setBool(_importingFlagKey, false);

      result.success = true;
      onProgress?.call(1.0, '导入完成');
    } catch (e) {
      result.success = false;
      result.error = e.toString();
      print('❌ 导入失败: $e');

      // 保留进度，允许断点续传
      await prefs.setBool(_importingFlagKey, false);
    }

    return result;
  }

  /// 清除旧数据
  Future<void> _clearOldData() async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.assistantEntitys.clear();
      await isar.topicEntitys.clear();
      await isar.messageEntitys.clear();
      await isar.messageBlockEntitys.clear();
      await isar.fileEntitys.clear();
    });
  }

  /// 导入 Assistants
  ///
  /// 注意：调用前应先通过 _clearOldData() 清除旧数据
  Future<void> _importAssistants() async {
    final isar = await _db.instance;
    final assistants = _extractor.getAssistants();

    await isar.writeTxn(() async {
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

        await isar.assistantEntitys.putByIndex('assistantId', entity);
      }
    });
  }

  /// 导入 Files
  ///
  /// 将 Cherry Studio 的 files[] 数据导入到 FileEntity
  /// 字段映射：
  /// - id -> fileId
  /// - name/origin_name -> fileName
  /// - size -> fileSize
  /// - ext + type -> mimeType (推断)
  /// - path -> localPath (Cherry Studio 本地路径，仅供参考)
  /// - count -> referenceCount
  /// - created_at -> createdAt
  ///
  /// 注意：调用前应先通过 _clearOldData() 清除旧数据
  Future<int> _importFiles() async {
    final isar = await _db.instance;
    final files = _extractor.files;

    if (files.isEmpty) {
      return 0;
    }

    int importedCount = 0;

    await isar.writeTxn(() async {
      for (final file in files) {
        if (file is! Map<String, dynamic>) continue;

        final fileId = file['id'] as String?;
        if (fileId == null || fileId.isEmpty) continue;

        // 优先使用 origin_name，其次 name
        final fileName = file['origin_name'] as String? ??
                        file['name'] as String?;

        // 推断 MIME 类型
        final ext = file['ext'] as String?;
        final fileType = file['type'] as String?;
        final mimeType = _inferMimeType(ext, fileType);

        // 文件大小
        final size = file['size'];
        final fileSize = size is int ? size : (size is num ? size.toInt() : null);

        // 引用计数
        final count = file['count'];
        final referenceCount = count is int ? count : (count is num ? count.toInt() : 1);

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

        await isar.fileEntitys.putByIndex('fileId', entity);
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
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
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
      final normalizedExt = ext.startsWith('.') ? ext.toLowerCase() : '.$ext'.toLowerCase();
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
    final isar = await _db.instance;
    final assistants = await isar.assistantEntitys.where().findAll();

    await isar.writeTxn(() async {
      for (final asst in assistants) {
        final count = await isar.topicEntitys
            .filter()
            .assistantIdEqualTo(asst.assistantId)
            .count();
        asst.topicCount = count;
        await isar.assistantEntitys.putByIndex('assistantId', asst);
      }
    });
  }

  /// 导入单个话题
  ///
  /// 返回导入的消息数量
  Future<int> _importTopic(
    Isar isar,
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
    // 这样即使去重逻辑有遗漏，也不会因唯一索引冲突而崩溃
    await isar.topicEntitys.putByIndex('topicId', topicEntity);

    // 保存 Messages 和 Blocks
    for (var i = 0; i < messages.length; i++) {
      final msgData = messages[i] as Map<String, dynamic>;
      await _importMessage(
        isar,
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
    Isar isar,
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
      useful: msgData['useful'] as bool? ?? true,
      modelId: (msgData['model'] as Map<String, dynamic>?)?['id'] as String?,
      modelName:
          (msgData['model'] as Map<String, dynamic>?)?['name'] as String?,
      usageJson: msgData['usage'] != null ? jsonEncode(msgData['usage']) : null,
      metricsJson:
          msgData['metrics'] != null ? jsonEncode(msgData['metrics']) : null,
      mentionsJson:
          msgData['mentions'] != null ? jsonEncode(msgData['mentions']) : null,
      createdAt: _parseTimestamp(msgData['createdAt']),
      status: msgData['status'] as String? ?? 'completed',
    );

    await isar.messageEntitys.putByIndex('messageId', messageEntity);

    // 保存 Blocks（从 CherryExtractor.blockMap 获取实际内容）
    for (var j = 0; j < blockIds.length; j++) {
      final blockId = blockIds[j];
      // ⚠️ 关键：通过 blockMap 获取 block 内容
      final blockData = _extractor.blockMap[blockId];

      if (blockData != null && blockData is Map<String, dynamic>) {
        final blockEntity = MessageBlockEntity.fromData(
          blockId: blockId,
          topicId: topicId,  // 【优化】添加 topicId 支持快速查询
          messageId: messageId,
          orderIndex: j,
          type: blockData['type'] as String? ?? 'main_text',
          content: blockData['content'] as String?,
          thinkingMillsec:
              (blockData['thinking_millsec'] as num?)?.toDouble(),
          url: blockData['url'] as String?,
          fileJson:
              blockData['file'] != null ? jsonEncode(blockData['file']) : null,
          toolJson: blockData['toolId'] != null
              ? jsonEncode({
                  'toolId': blockData['toolId'],
                  'toolName': blockData['toolName'],
                  'arguments': blockData['arguments'],
                })
              : null,
          errorJson:
              blockData['error'] != null ? jsonEncode(blockData['error']) : null,
          targetLanguage: blockData['targetLanguage'] as String?,
          // citation 块字段
          responseJson:
              blockData['response'] != null ? jsonEncode(blockData['response']) : null,
          knowledgeJson:
              blockData['knowledge'] != null ? jsonEncode(blockData['knowledge']) : null,
          // 文件关联
          fileId: blockData['fileId'] as String?,
          createdAt: _parseTimestamp(blockData['createdAt']),
        );

        await isar.messageBlockEntitys.putByIndex('blockId', blockEntity);
      } else {
        // Block 数据丢失时创建占位符
        final placeholder = MessageBlockEntity.fromData(
          blockId: blockId,
          topicId: topicId,  // 【优化】添加 topicId 支持快速查询
          messageId: messageId,
          orderIndex: j,
          type: 'error',
          content: '[Block 数据丢失: $blockId]',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await isar.messageBlockEntitys.putByIndex('blockId', placeholder);
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

  /// 清除断点续传进度
  Future<void> clearImportProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_importProgressKey);
    await prefs.setBool(_importingFlagKey, false);
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

  @override
  String toString() {
    if (success) {
      return '导入成功: $importedTopics 个话题, $importedMessages 条消息, $importedFiles 个文件';
    } else {
      return '导入失败: $error (已导入 $importedTopics/$totalTopics 个话题)';
    }
  }
}
