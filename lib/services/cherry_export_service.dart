import 'dart:convert';
import 'dart:io' as io;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'app_db.dart';
import '../models/domain/block_model.dart';
import '../models/domain/export_snapshot.dart';
import '../models/domain/message_model.dart';
import '../models/domain/topic_model.dart';
import 'export/drift_export_store.dart';
import 'export/i_export_store.dart';

/// Cherry Studio 数据导出服务
///
/// 将 Flutter 应用中的数据导出为 Cherry Studio 兼容格式
/// 支持：
/// 1. 从 Isar 数据库导出
/// 2. 从 CherryExtractor 修改后导出
/// 3. 增量修改后重新导出
class CherryExportService {
  final AppDb _db;
  final IExportStore _store;

  CherryExportService(
    AppDb db, {
    IExportStore? store,
  })  : _db = db,
        _store = store ?? DriftExportStore(db);

  /// 从 Isar 数据库导出为 Cherry Studio 格式
  ///
  /// 这是一个"重建"导出，从 Isar 数据库重建完整的 Cherry Studio 格式
  /// 注意：某些原始数据可能在导入时丢失，导出的数据可能不完全等同于原始数据
  Future<String> exportFromIsar() async {
    await _db.init();
    final snapshot = await _store.loadSnapshot();
    return json.encode(_buildExportData(snapshot));
  }

  /// 导出为 ZIP 文件
  Future<void> exportToZip(String outputPath) async {
    await _db.init();
    final snapshot = await _store.loadSnapshot();
    final jsonData = json.encode(_buildExportData(snapshot));

    final archive = Archive();
    final dataJsonBytes = utf8.encode(jsonData);
    archive.addFile(ArchiveFile(
      'data.json',
      dataJsonBytes.length,
      dataJsonBytes,
    ));

    archive.addFile(ArchiveFile('Data/', 0, <int>[]));
    archive.addFile(ArchiveFile('Data/Files/', 0, <int>[]));

    for (final f in snapshot.files) {
      final localPath = f.localPath;
      if (localPath == null || localPath.isEmpty) continue;
      final localFile = io.File(localPath);
      if (!await localFile.exists()) continue;
      final bytes = await localFile.readAsBytes();
      final entryName = 'Data/Files/${p.basename(localPath)}';
      archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('ZIP 编码失败');
    }

    await io.File(outputPath).writeAsBytes(zipData);
    print('✅ 导出完成: $outputPath');
  }

  /// 导出为 JSON 文件
  Future<void> exportToJson(String outputPath) async {
    final jsonData = await exportFromIsar();
    await io.File(outputPath).writeAsString(jsonData);
    print('✅ 导出完成: $outputPath');
  }

  Map<String, dynamic> _buildExportData(ExportSnapshot snapshot) {
    final assistantToTopicIds = <String, List<String>>{};
    for (final link in snapshot.topicAssistantLinks) {
      assistantToTopicIds.putIfAbsent(link.assistantId, () => []).add(link.topicId);
    }

    final topicById = {for (final t in snapshot.topics) t.topicId: t};

    final assistantsList = <Map<String, dynamic>>[];
    for (final asst in snapshot.assistants) {
      final topicIds = assistantToTopicIds[asst.assistantId] ?? const <String>[];
      final topicEntities = topicIds
          .map((id) => topicById[id])
          .whereType<TopicModel>()
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final topicRefs = topicEntities
          .map(
            (t) => {
              'id': t.topicId,
              'name': t.name,
              'createdAt': t.createdAt,
              'updatedAt': t.updatedAt,
            },
          )
          .toList();

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

    final blocksByMessageId = <String, List<BlockModel>>{};
    for (final b in snapshot.blocks) {
      blocksByMessageId.putIfAbsent(b.messageId, () => []).add(b);
    }
    for (final list in blocksByMessageId.values) {
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    final messagesByTopicId = <String, List<MessageModel>>{};
    for (final m in snapshot.messages) {
      messagesByTopicId.putIfAbsent(m.topicId, () => []).add(m);
    }
    for (final list in messagesByTopicId.values) {
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    final allBlocks = <Map<String, dynamic>>[];
    final topicsData = <Map<String, dynamic>>[];
    for (final topic in snapshot.topics) {
      final messageEntities = messagesByTopicId[topic.topicId] ?? const <MessageModel>[];
      final messagesData = <Map<String, dynamic>>[];

      for (final msg in messageEntities) {
        final blockEntities = blocksByMessageId[msg.messageId] ?? const <BlockModel>[];
        final blockIds = <String>[];
        for (final block in blockEntities) {
          blockIds.add(block.blockId);
          allBlocks.add(_buildBlockData(block));
        }
        messagesData.add(_buildMessageData(msg, blockIds));
      }

      topicsData.add({'id': topic.topicId, 'messages': messagesData});
    }

    final filesData = <Map<String, dynamic>>[];
    for (final f in snapshot.files) {
      final fileName = (f.fileName == null || f.fileName!.isEmpty) ? f.fileId : f.fileName!;
      final hasLocalCache = f.localPath != null && f.localPath!.isNotEmpty;
      final zipPath = hasLocalCache ? 'Data/Files/${p.basename(f.localPath!)}' : null;
      final isImage = (f.mimeType ?? '').startsWith('image/');
      filesData.add({
        'id': f.fileId,
        'name': fileName,
        'origin_name': fileName,
        if (zipPath != null) 'path': zipPath,
        if (f.fileSize != null) 'size': f.fileSize,
        'type': isImage ? 'image' : 'file',
        'created_at': _msToIso(f.createdAt),
        'count': f.referenceCount,
        if (f.sha256 != null) 'sha256': f.sha256,
      });
    }

    return {
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
        'files': filesData,
        'settings': <dynamic>[],
        'knowledge_notes': <dynamic>[],
        'translate_history': <dynamic>[],
        'quick_phrases': <dynamic>[],
        'translate_languages': <dynamic>[],
      },
    };
  }

  /// 构建 message 数据
  Map<String, dynamic> _buildMessageData(
      MessageModel entity, List<String> blockIds) {
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
    if (entity.usage != null) {
      data['usage'] = entity.usage;
    }
    if (entity.metrics != null) {
      data['metrics'] = entity.metrics;
    }
    if (entity.mentions != null) {
      data['mentions'] = entity.mentions;
    }

    return data;
  }

  /// 构建 block 数据
  Map<String, dynamic> _buildBlockData(BlockModel entity) {
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
    if (entity.file != null) {
      data['file'] = entity.file;
    }
    if (entity.toolId != null || entity.toolName != null || entity.arguments != null) {
      data['toolId'] = entity.toolId;
      data['toolName'] = entity.toolName;
      data['arguments'] = entity.arguments;
    }
    if (entity.error != null) {
      data['error'] = entity.error;
    }
    if (entity.targetLanguage != null) {
      data['targetLanguage'] = entity.targetLanguage;
    }
    if (entity.response != null) {
      data['response'] = entity.response;
    }
    if (entity.knowledge != null) {
      data['knowledge'] = entity.knowledge;
    }

    return data;
  }

  /// 毫秒时间戳转 ISO 字符串
  String _msToIso(int ms) {
    return DateTime.fromMillisecondsSinceEpoch(ms).toUtc().toIso8601String();
  }
}
