import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../cherry_extractor.dart';
import '../../models/domain/import_result.dart';
import 'app_database.dart';

class DriftDataImportService {
  final ImportDatabase _db;
  final CherryExtractor _extractor;

  static const String _importProgressKey = 'import_progress';
  static const String _importingFlagKey = 'is_importing';

  DriftDataImportService(this._db, this._extractor);

  Future<ImportResult> importFromExtractor({
    void Function(double progress, String message)? onProgress,
    bool continueFromCheckpoint = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final result = ImportResult();
    String? jobId;
    String? artifactId;

    try {
      await prefs.setBool(_importingFlagKey, true);

      final now = DateTime.now().millisecondsSinceEpoch;
      final sourceType = 'cherry_studio_backup';
      final sourcePath = _extractor.zipPath ?? _extractor.dataJsonPath;
      final fileName = sourcePath == null ? null : p.basename(sourcePath);
      final fileSize = await _tryGetFileSize(sourcePath);
      final sha256Hex = await _tryComputeSha256(sourcePath);
      artifactId = sha1
          .convert(
            utf8.encode(
              [sourceType, fileName ?? '', fileSize?.toString() ?? '', sha256Hex ?? ''].join('|'),
            ),
          )
          .toString();
      jobId = sha1.convert(utf8.encode('job:$artifactId:$now')).toString();

      await _db.transaction(() async {
        await _db.into(_db.importArtifacts).insertOnConflictUpdate(
              ImportArtifactsCompanion(
                artifactId: Value(artifactId!),
                sourceType: Value(sourceType),
                fileName: Value(fileName),
                sourcePath: Value(sourcePath),
                fileSize: Value(fileSize),
                sha256: Value(sha256Hex),
                createdAt: Value(now),
              ),
            );
        await _db.into(_db.importJobs).insertOnConflictUpdate(
              ImportJobsCompanion(
                jobId: Value(jobId!),
                artifactId: Value(artifactId!),
                sourceType: Value(sourceType),
                status: Value('running'),
                startedAt: Value(now),
              ),
            );
      });

      final groupedTopics = _extractor.getTopicsByAssistant();
      final topicIdToData = <String, Map<String, dynamic>>{};
      final topicIdToAssistantIds = <String, Set<String>>{};

      for (final entry in groupedTopics.entries) {
        final assistantId = entry.key;
        final topics = entry.value['topics'] as List<dynamic>? ?? [];
        for (final topic in topics) {
          if (topic is! Map<String, dynamic>) continue;
          final topicId = topic['id'] as String?;
          if (topicId == null || topicId.isEmpty) continue;
          topicIdToData[topicId] = topic;
          topicIdToAssistantIds.putIfAbsent(topicId, () => {}).add(assistantId);
        }
      }

      final allTopics = <Map<String, dynamic>>[];
      for (final topicId in topicIdToData.keys) {
        allTopics.add({
          'assistantIds': topicIdToAssistantIds[topicId]!.toList(),
          'topic': topicIdToData[topicId],
        });
      }

      result.totalTopics = allTopics.length;

      int startIndex = 0;
      if (continueFromCheckpoint) {
        startIndex = prefs.getInt(_importProgressKey) ?? 0;
        if (startIndex > 0) {
          onProgress?.call(0.05, '从断点继续导入（已完成 $startIndex 个话题）...');
        }
      }

      if (startIndex == 0) {
        await prefs.setInt(_importProgressKey, 0);
        onProgress?.call(0.07, '正在导入助手信息...');
        await _importAssistants(sourceType: sourceType, seenAt: now);
        onProgress?.call(0.09, '正在导入文件信息...');
        result.importedFiles = await _importFiles(sourceType: sourceType, seenAt: now);
      }

      onProgress?.call(0.1, '开始导入 ${allTopics.length} 个话题...');
      const batchSize = 50;

      for (var i = startIndex; i < allTopics.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, allTopics.length);
        final batch = allTopics.sublist(i, end);

        await _db.transaction(() async {
          for (final item in batch) {
            final assistantIds = (item['assistantIds'] as List).cast<String>();
            final topicData = item['topic'] as Map<String, dynamic>;
            final imported = await _importTopic(
              assistantIds: assistantIds,
              topicData: topicData,
              sourceType: sourceType,
              seenAt: now,
            );
            result.importedMessages += imported;
          }
        });

        result.importedTopics = end;
        await prefs.setInt(_importProgressKey, end);

        final progress = 0.1 + 0.85 * end / allTopics.length;
        onProgress?.call(progress, '已导入 $end/${allTopics.length} 个话题...');
      }

      onProgress?.call(0.96, '正在更新统计信息...');
      await _updateAssistantTopicCounts();

      await prefs.remove(_importProgressKey);
      await prefs.setBool(_importingFlagKey, false);

      result.success = true;
      onProgress?.call(1.0, '导入完成');

      await _db.transaction(() async {
        await (_db.update(_db.importJobs)..where((t) => t.jobId.equals(jobId!)))
            .write(
          ImportJobsCompanion(
            status: const Value('succeeded'),
            finishedAt: Value(DateTime.now().millisecondsSinceEpoch),
            statsJson: Value(
              jsonEncode({
                'topics': result.importedTopics,
                'messages': result.importedMessages,
                'files': result.importedFiles,
              }),
            ),
          ),
        );
      });
    } catch (e) {
      result.success = false;
      result.error = e.toString();

      try {
        if (jobId != null) {
          await _db.transaction(() async {
            await (_db.update(_db.importJobs)..where((t) => t.jobId.equals(jobId!)))
                .write(
              ImportJobsCompanion(
                status: const Value('failed'),
                finishedAt: Value(DateTime.now().millisecondsSinceEpoch),
                error: Value(result.error),
              ),
            );
          });
        }
      } catch (_) {}

      await prefs.setBool(_importingFlagKey, false);
    }

    return result;
  }

  Future<void> _importAssistants({
    required String sourceType,
    required int seenAt,
  }) async {
    final assistants = _extractor.getAssistants();
    if (assistants.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = <AssistantsCompanion>[];
    final prov = <ProvenanceRecordsCompanion>[];

    for (final asst in assistants) {
      if (asst is! Map<String, dynamic>) continue;
      final assistantId = asst['id'] as String? ?? '';
      if (assistantId.isEmpty) continue;

      rows.add(
        AssistantsCompanion(
          assistantId: Value(assistantId),
          name: Value(asst['name'] as String? ?? '未命名助手'),
          description: Value(asst['description'] as String?),
          avatar: Value(asst['avatar'] as String?),
          prompt: Value(asst['prompt'] as String?),
          topicCount: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      prov.add(
        ProvenanceRecordsCompanion(
          sourceType: Value(sourceType),
          entityType: const Value('assistant'),
          externalId: Value(assistantId),
          entityId: Value(assistantId),
          fingerprint: Value(sha1.convert(utf8.encode(jsonEncode(asst))).toString()),
          firstSeenAt: Value(seenAt),
          lastSeenAt: Value(seenAt),
        ),
      );
    }

    await _db.batch((b) {
      b.insertAll(_db.assistants, rows, mode: InsertMode.insertOrReplace);
      b.insertAll(_db.provenanceRecords, prov, mode: InsertMode.insertOrReplace);
    });
  }

  Future<int> _importFiles({
    required String sourceType,
    required int seenAt,
  }) async {
    final files = _extractor.files;
    if (files.isEmpty) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = <FilesCompanion>[];
    final prov = <ProvenanceRecordsCompanion>[];

    for (final file in files) {
      if (file is! Map<String, dynamic>) continue;
      final fileId = file['id'] as String?;
      if (fileId == null || fileId.isEmpty) continue;

      final fileName = file['origin_name'] as String? ?? file['name'] as String?;
      final size = file['size'];
      final fileSize = size is int ? size : (size is num ? size.toInt() : null);
      final sha256Hex = file['sha256'] as String?;
      final ext = file['ext'] as String?;
      final fileType = file['type'] as String?;
      final mimeType = _inferMimeType(ext, fileType);

      final createdAt = _parseTimestamp(file['created_at']);
      final updatedAt = createdAt;

      final count = file['count'];
      final referenceCount = count is int ? count : (count is num ? count.toInt() : 1);

      rows.add(
        FilesCompanion(
          fileId: Value(fileId),
          fileName: Value(fileName),
          localPath: const Value(null),
          fileSize: Value(fileSize),
          mimeType: Value(mimeType),
          sha256: Value(sha256Hex),
          referenceCount: Value(referenceCount),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
        ),
      );

      prov.add(
        ProvenanceRecordsCompanion(
          sourceType: Value(sourceType),
          entityType: const Value('file'),
          externalId: Value(fileId),
          entityId: Value(fileId),
          fingerprint: Value(
            sha1.convert(utf8.encode([fileId, sha256Hex ?? '', fileSize?.toString() ?? '', mimeType ?? ''].join('|'))).toString(),
          ),
          firstSeenAt: Value(seenAt),
          lastSeenAt: Value(seenAt),
        ),
      );
    }

    await _db.batch((b) {
      b.insertAll(_db.files, rows, mode: InsertMode.insertOrReplace);
      b.insertAll(_db.provenanceRecords, prov, mode: InsertMode.insertOrReplace);
    });

    return rows.length;
  }

  Future<int> _importTopic({
    required List<String> assistantIds,
    required Map<String, dynamic> topicData,
    required String sourceType,
    required int seenAt,
  }) async {
    final topicId = topicData['id'] as String? ?? '';
    if (topicId.isEmpty) return 0;

    final topicName = topicData['name'] as String? ?? '未命名话题';
    final createdAt = _parseTimestamp(topicData['createdAt'] ?? topicData['created_at']);
    final updatedAt = _parseTimestamp(topicData['updatedAt'] ?? topicData['updated_at']);

    final messages = topicData['messages'] as List<dynamic>? ?? [];

    final roundMap = <int, int>{};
    var roundIndex = -1;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m is! Map<String, dynamic>) continue;
      final role = m['role'] as String? ?? '';
      if (role == 'user') {
        roundIndex++;
      }
      roundMap[i] = roundIndex.clamp(0, 1 << 30);
    }

    final topicCompanion = TopicsCompanion(
      topicId: Value(topicId),
      name: Value(topicName),
      messageCount: Value(messages.length),
      roundCount: Value(roundIndex + 1),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );

    await _db.into(_db.topics).insertOnConflictUpdate(topicCompanion);

    await (_db.delete(_db.topicAssistants)..where((t) => t.topicId.equals(topicId)))
        .go();
    if (assistantIds.isNotEmpty) {
      await _db.batch((b) {
        b.insertAll(
          _db.topicAssistants,
          assistantIds
              .where((a) => a.isNotEmpty)
              .map(
                (a) => TopicAssistantsCompanion(
                  topicId: Value(topicId),
                  assistantId: Value(a),
                ),
              )
              .toList(),
          mode: InsertMode.insertOrIgnore,
        );
      });
    }

    await _upsertProvenance(
      sourceType: sourceType,
      entityType: 'topic',
      externalId: topicId,
      entityId: topicId,
      fingerprint: sha1.convert(utf8.encode([topicId, topicName, messages.length.toString(), updatedAt.toString()].join('|'))).toString(),
      seenAt: seenAt,
    );

    var importedMessages = 0;
    final messageRows = <MessagesCompanion>[];
    final blockRows = <MessageBlocksCompanion>[];
    final provRows = <ProvenanceRecordsCompanion>[];

    for (var i = 0; i < messages.length; i++) {
      final msgData = messages[i];
      if (msgData is! Map<String, dynamic>) continue;
      final messageId = msgData['id'] as String? ?? '';
      if (messageId.isEmpty) continue;

      final role = msgData['role'] as String? ?? '';
      final createdAtMsg = _parseTimestamp(msgData['createdAt'] ?? msgData['created_at']);
      final status = msgData['status'] as String? ?? 'success';
      final askId = msgData['askId'] as String?;
      final useful = (msgData['useful'] as bool?) ?? true;
      final model = msgData['model'] as Map<String, dynamic>?;
      final modelId = (model?['id'] ?? msgData['modelId']) as String?;
      final modelName = (model?['name'] ?? msgData['modelName']) as String?;

      messageRows.add(
        MessagesCompanion(
          messageId: Value(messageId),
          topicId: Value(topicId),
          orderIndex: Value(i),
          roundIndex: Value(roundMap[i] ?? 0),
          role: Value(role),
          askId: Value(askId),
          useful: Value(useful),
          modelId: Value(modelId),
          modelName: Value(modelName),
          usageJson: Value(msgData['usage'] != null ? jsonEncode(msgData['usage']) : null),
          metricsJson: Value(msgData['metrics'] != null ? jsonEncode(msgData['metrics']) : null),
          mentionsJson: Value(msgData['mentions'] != null ? jsonEncode(msgData['mentions']) : null),
          createdAt: Value(createdAtMsg),
          status: Value(status),
        ),
      );

      provRows.add(
        ProvenanceRecordsCompanion(
          sourceType: Value(sourceType),
          entityType: const Value('message'),
          externalId: Value(messageId),
          entityId: Value(messageId),
          parentExternalId: Value(topicId),
          fingerprint: Value(sha1.convert(utf8.encode(jsonEncode(msgData))).toString()),
          firstSeenAt: Value(seenAt),
          lastSeenAt: Value(seenAt),
        ),
      );

      importedMessages++;

      final blockIds = (msgData['blocks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      for (var j = 0; j < blockIds.length; j++) {
        final blockId = blockIds[j];
        final blockData = _extractor.blockMap[blockId];
        if (blockData is Map<String, dynamic>) {
          final type = blockData['type'] as String? ?? 'main_text';
          final content = blockData['content'] is String
              ? blockData['content'] as String
              : (blockData['content'] != null ? jsonEncode(blockData['content']) : null);

          blockRows.add(
            MessageBlocksCompanion(
              blockId: Value(blockId),
              topicId: Value(topicId),
              messageId: Value(messageId),
              orderIndex: Value(j),
              type: Value(type),
              content: Value(content),
              thinkingMillsec: Value((blockData['thinking_millsec'] as num?)?.toDouble()),
              url: Value(blockData['url'] as String?),
              fileJson: Value(blockData['file'] != null ? jsonEncode(blockData['file']) : null),
              toolJson: Value(
                blockData['toolId'] != null || blockData['toolName'] != null
                    ? jsonEncode({
                        'toolId': blockData['toolId'],
                        'toolName': blockData['toolName'],
                        'arguments': blockData['arguments'],
                      })
                    : null,
              ),
              errorJson: Value(blockData['error'] != null ? jsonEncode(blockData['error']) : null),
              targetLanguage: Value(blockData['targetLanguage'] as String?),
              responseJson: Value(blockData['response'] != null ? jsonEncode(blockData['response']) : null),
              knowledgeJson: Value(blockData['knowledge'] != null ? jsonEncode(blockData['knowledge']) : null),
              createdAt: Value(_parseTimestamp(blockData['createdAt'] ?? blockData['created_at'])),
            ),
          );

          provRows.add(
            ProvenanceRecordsCompanion(
              sourceType: Value(sourceType),
              entityType: const Value('block'),
              externalId: Value(blockId),
              entityId: Value(blockId),
              parentExternalId: Value(messageId),
              fingerprint: Value(sha1.convert(utf8.encode(jsonEncode(blockData))).toString()),
              firstSeenAt: Value(seenAt),
              lastSeenAt: Value(seenAt),
            ),
          );
        } else {
          blockRows.add(
            MessageBlocksCompanion(
              blockId: Value(blockId),
              topicId: Value(topicId),
              messageId: Value(messageId),
              orderIndex: Value(j),
              type: const Value('error'),
              content: Value('[Block 数据丢失: $blockId]'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

          provRows.add(
            ProvenanceRecordsCompanion(
              sourceType: Value(sourceType),
              entityType: const Value('block'),
              externalId: Value(blockId),
              entityId: Value(blockId),
              parentExternalId: Value(messageId),
              fingerprint: Value(sha1.convert(utf8.encode('missing:$blockId')).toString()),
              firstSeenAt: Value(seenAt),
              lastSeenAt: Value(seenAt),
            ),
          );
        }
      }
    }

    await _db.batch((b) {
      if (messageRows.isNotEmpty) {
        b.insertAll(_db.messages, messageRows, mode: InsertMode.insertOrReplace);
      }
      if (blockRows.isNotEmpty) {
        b.insertAll(_db.messageBlocks, blockRows, mode: InsertMode.insertOrReplace);
      }
      if (provRows.isNotEmpty) {
        b.insertAll(_db.provenanceRecords, provRows, mode: InsertMode.insertOrReplace);
      }
    });

    return importedMessages;
  }

  Future<void> _upsertProvenance({
    required String sourceType,
    required String entityType,
    required String externalId,
    required String entityId,
    String? parentExternalId,
    String? fingerprint,
    required int seenAt,
  }) async {
    final existing = await (_db.select(_db.provenanceRecords)
          ..where((t) =>
              t.sourceType.equals(sourceType) &
              t.entityType.equals(entityType) &
              t.externalId.equals(externalId))
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.provenanceRecords).insert(
            ProvenanceRecordsCompanion(
              sourceType: Value(sourceType),
              entityType: Value(entityType),
              externalId: Value(externalId),
              entityId: Value(entityId),
              parentExternalId: Value(parentExternalId),
              fingerprint: Value(fingerprint),
              firstSeenAt: Value(seenAt),
              lastSeenAt: Value(seenAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
      return;
    }

    await (_db.update(_db.provenanceRecords)
          ..where((t) =>
              t.sourceType.equals(sourceType) &
              t.entityType.equals(entityType) &
              t.externalId.equals(externalId)))
        .write(
      ProvenanceRecordsCompanion(
        entityId: Value(entityId),
        parentExternalId: Value(parentExternalId ?? existing.parentExternalId),
        fingerprint: Value(fingerprint ?? existing.fingerprint),
        lastSeenAt: Value(seenAt),
      ),
    );
  }

  Future<void> _updateAssistantTopicCounts() async {
    final assistants = await _db.select(_db.assistants).get();
    for (final a in assistants) {
      final countExp = _db.topicAssistants.topicId.count(distinct: true);
      final row = await (_db.selectOnly(_db.topicAssistants)
            ..addColumns([countExp])
            ..where(_db.topicAssistants.assistantId.equals(a.assistantId)))
          .getSingle();
      final count = row.read(countExp) ?? 0;
      await (_db.update(_db.assistants)
            ..where((t) => t.assistantId.equals(a.assistantId)))
          .write(
        AssistantsCompanion(topicCount: Value(count)),
      );
    }
  }

  Future<int?> _tryGetFileSize(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final f = io.File(path);
      if (!await f.exists()) return null;
      return await f.length();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryComputeSha256(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final f = io.File(path);
      if (!await f.exists()) return null;
      final digest = await sha256.bind(f.openRead()).first;
      return digest.toString();
    } catch (_) {
      return null;
    }
  }

  int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  String? _inferMimeType(String? ext, String? fileType) {
    final e = (ext ?? '').toLowerCase();
    if (fileType == 'image') {
      if (e == 'jpg' || e == 'jpeg') return 'image/jpeg';
      if (e == 'png') return 'image/png';
      if (e == 'gif') return 'image/gif';
      if (e == 'webp') return 'image/webp';
      return 'image/*';
    }
    if (e == 'pdf') return 'application/pdf';
    if (e == 'md' || e == 'markdown') return 'text/markdown';
    if (e == 'txt') return 'text/plain';
    return null;
  }
}
