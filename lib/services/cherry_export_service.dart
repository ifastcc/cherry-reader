import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:isar_community/isar.dart';

import 'isar_database.dart';
import '../models/isar/assistant_entity.dart';
import '../models/isar/topic_entity.dart';
import '../models/isar/message_entity.dart';
import '../models/isar/message_block_entity.dart';

/// Cherry Studio 数据导出服务
///
/// 将 Flutter 应用中的数据导出为 Cherry Studio 兼容格式
/// 支持：
/// 1. 从 Isar 数据库导出
/// 2. 从 CherryExtractor 修改后导出
/// 3. 增量修改后重新导出
class CherryExportService {
  final IsarDatabase _db;

  CherryExportService(this._db);

  /// 从 Isar 数据库导出为 Cherry Studio 格式
  ///
  /// 这是一个"重建"导出，从 Isar 数据库重建完整的 Cherry Studio 格式
  /// 注意：某些原始数据可能在导入时丢失，导出的数据可能不完全等同于原始数据
  Future<String> exportFromIsar() async {
    final isar = await _db.instance;

    // 1. 获取所有 assistants
    final assistantEntities = await isar.assistantEntitys.where().findAll();

    // 2. 构建 assistants 数据（localStorage 格式）
    final assistantsList = <Map<String, dynamic>>[];

    for (final asst in assistantEntities) {
      // 获取该 assistant 的所有 topics
      final topicEntities = await isar.topicEntitys
          .filter()
          .assistantIdsElementEqualTo(asst.assistantId)
          .sortByCreatedAt()
          .findAll();

      final topicRefs = topicEntities.map((t) => {
        'id': t.topicId,
        'name': t.name,
        'createdAt': t.createdAt,
        'updatedAt': t.updatedAt,
      }).toList();

      assistantsList.add({
        'id': asst.assistantId,
        'name': asst.name,
        'description': asst.description,
        'prompt': asst.prompt,
        'avatar': asst.avatar,
        'topics': topicRefs,
        'createdAt': _msToIso(asst.createdAt),
        'updatedAt': _msToIso(asst.updatedAt),
      });
    }

    // 3. 构建 IndexedDB topics
    final topicsData = <Map<String, dynamic>>[];
    final allBlocks = <Map<String, dynamic>>[];

    final allTopics = await isar.topicEntitys.where().findAll();
    for (final topicEntity in allTopics) {
      // 获取该 topic 的所有消息
      final messageEntities = await isar.messageEntitys
          .filter()
          .topicIdEqualTo(topicEntity.topicId)
          .sortByOrderIndex()
          .findAll();

      final messagesData = <Map<String, dynamic>>[];

      for (final msgEntity in messageEntities) {
        // 获取该消息的所有 blocks
        final blockEntities = await isar.messageBlockEntitys
            .filter()
            .messageIdEqualTo(msgEntity.messageId)
            .sortByOrderIndex()
            .findAll();

        final blockIds = <String>[];

        for (final blockEntity in blockEntities) {
          blockIds.add(blockEntity.blockId);

          // 构建 block 数据
          final blockData = _buildBlockData(blockEntity);
          allBlocks.add(blockData);
        }

        // 构建 message 数据
        final messageData = _buildMessageData(msgEntity, blockIds);
        messagesData.add(messageData);
      }

      topicsData.add({
        'id': topicEntity.topicId,
        'messages': messagesData,
      });
    }

    // 4. 获取 files（如果有的话）
    // TODO: 如果有 FileEntity，也需要导出

    // 5. 构建完整的导出数据
    final exportData = {
      'time': DateTime.now().millisecondsSinceEpoch,
      'version': 5,
      'localStorage': {
        'persist:cherry-studio': json.encode({
          'assistants': json.encode({
            'assistants': assistantsList,
          }),
        }),
      },
      'indexedDB': {
        'topics': topicsData,
        'message_blocks': allBlocks,
        'files': <dynamic>[],
        'settings': <dynamic>[],
        'knowledge_notes': <dynamic>[],
        'translate_history': <dynamic>[],
        'quick_phrases': <dynamic>[],
        'translate_languages': <dynamic>[],
      },
    };

    return json.encode(exportData);
  }

  /// 导出为 ZIP 文件
  Future<void> exportToZip(String outputPath) async {
    final jsonData = await exportFromIsar();

    final archive = Archive();
    final dataJsonBytes = utf8.encode(jsonData);
    archive.addFile(ArchiveFile(
      'data.json',
      dataJsonBytes.length,
      dataJsonBytes,
    ));

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('ZIP 编码失败');
    }

    await File(outputPath).writeAsBytes(zipData);
    print('✅ 导出完成: $outputPath');
  }

  /// 导出为 JSON 文件
  Future<void> exportToJson(String outputPath) async {
    final jsonData = await exportFromIsar();
    await File(outputPath).writeAsString(jsonData);
    print('✅ 导出完成: $outputPath');
  }

  /// 构建 message 数据
  Map<String, dynamic> _buildMessageData(
      MessageEntity entity, List<String> blockIds) {
    final data = <String, dynamic>{
      'id': entity.messageId,
      'role': entity.role,
      'topicId': entity.topicId,
      'createdAt': _msToIso(entity.createdAt),
      'status': entity.status,
      'blocks': blockIds,
      'useful': entity.useful,
    };

    if (entity.askId != null) data['askId'] = entity.askId;
    if (entity.modelId != null) data['modelId'] = entity.modelId;
    if (entity.modelName != null) {
      data['model'] = {'id': entity.modelId, 'name': entity.modelName};
    }
    if (entity.usageJson != null) {
      data['usage'] = json.decode(entity.usageJson!);
    }
    if (entity.metricsJson != null) {
      data['metrics'] = json.decode(entity.metricsJson!);
    }
    if (entity.mentionsJson != null) {
      data['mentions'] = json.decode(entity.mentionsJson!);
    }

    return data;
  }

  /// 构建 block 数据
  Map<String, dynamic> _buildBlockData(MessageBlockEntity entity) {
    final data = <String, dynamic>{
      'id': entity.blockId,
      'messageId': entity.messageId,
      'type': entity.type,
      'createdAt': _msToIso(entity.createdAt),
      'status': 'success',
    };

    if (entity.content != null) data['content'] = entity.content;
    if (entity.thinkingMillsec != null) {
      data['thinking_millsec'] = entity.thinkingMillsec;
    }
    if (entity.url != null) data['url'] = entity.url;
    if (entity.fileJson != null) {
      data['file'] = json.decode(entity.fileJson!);
    }
    if (entity.toolJson != null) {
      final toolData = json.decode(entity.toolJson!);
      data['toolId'] = toolData['toolId'];
      data['toolName'] = toolData['toolName'];
      data['arguments'] = toolData['arguments'];
    }
    if (entity.errorJson != null) {
      data['error'] = json.decode(entity.errorJson!);
    }
    if (entity.targetLanguage != null) {
      data['targetLanguage'] = entity.targetLanguage;
    }
    if (entity.responseJson != null) {
      data['response'] = json.decode(entity.responseJson!);
    }
    if (entity.knowledgeJson != null) {
      data['knowledge'] = json.decode(entity.knowledgeJson!);
    }

    return data;
  }

  /// 毫秒时间戳转 ISO 字符串
  String _msToIso(int ms) {
    return DateTime.fromMillisecondsSinceEpoch(ms).toUtc().toIso8601String();
  }
}
