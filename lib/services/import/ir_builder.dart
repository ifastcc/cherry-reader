import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'folder_scanner.dart';
import 'markdown_parser.dart';

class IrBuildResult {
  final Map<String, dynamic> rawData;

  IrBuildResult({required this.rawData});
}

class IrBuilder {
  Future<IrBuildResult> buildFromMarkdownFile(String markdownFilePath) async {
    final parser = MarkdownParser();
    final topic = await parser.parseFile(markdownFilePath);
    final assistant = ScannedAssistant(slug: 'markdown', meta: <String, dynamic>{}, topics: [topic]);
    final scan = ScanResult(rootPath: p.dirname(markdownFilePath), assistants: [assistant], unassignedTopics: []);
    final rawData = await _buildRawData(scan);
    return IrBuildResult(rawData: rawData);
  }

  Future<IrBuildResult> buildFromFolderScan(ScanResult scan) async {
    final rawData = await _buildRawData(scan);
    return IrBuildResult(rawData: rawData);
  }

  Future<Map<String, dynamic>> _buildRawData(ScanResult scan) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final assistantsList = <Map<String, dynamic>>[];
    final topicsData = <Map<String, dynamic>>[];
    final blocksData = <Map<String, dynamic>>[];
    final filesData = <Map<String, dynamic>>[];

    final fileIdBySourcePath = <String, String>{};
    final fileRecordById = <String, Map<String, dynamic>>{};

    Future<Map<String, dynamic>?> buildFileRecord(String sourcePath) async {
      final normalized = p.normalize(sourcePath);
      final existing = fileIdBySourcePath[normalized];
      if (existing != null) {
        return fileRecordById[existing];
      }

      final file = File(normalized);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final contentHash = sha1.convert(bytes).toString();
      final ext = p.extension(normalized).toLowerCase();
      final fileId = _sha1Hex('file:$contentHash');
      fileIdBySourcePath[normalized] = fileId;

      final originName = p.basename(normalized);
      final record = <String, dynamic>{
        'id': fileId,
        'origin_name': originName,
        'name': originName,
        'path': 'Data/Files/$contentHash$ext',
        'sourcePath': normalized,
        'content_hash': contentHash,
        'ext': ext,
        'type': _inferFileType(ext),
        'size': bytes.length,
        'count': 1,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      filesData.add(record);
      fileRecordById[fileId] = record;
      return record;
    }

    void addAssistant({
      required String assistantId,
      required String name,
      required List<Map<String, dynamic>> topicRefs,
      Map<String, dynamic>? extra,
    }) {
      final asst = <String, dynamic>{
        'id': assistantId,
        'name': name,
        'topics': topicRefs,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      if (extra != null) {
        if (extra['description'] != null) asst['description'] = extra['description'];
        if (extra['systemPrompt'] != null) asst['prompt'] = extra['systemPrompt'];
        if (extra['prompt'] != null && asst['prompt'] == null) asst['prompt'] = extra['prompt'];
        if (extra['avatar'] != null) asst['avatar'] = extra['avatar'];
      }
      assistantsList.add(asst);
    }

    Future<void> buildTopicAndBlocks({
      required String topicId,
      required ParsedTopic topic,
      required DateTime baseTime,
      required String topicName,
    }) async {
      final messagesData = <Map<String, dynamic>>[];

      int msgIndex = 0;
      int askIndex = 0;
      String? currentAskId;

      for (final msg in topic.messages) {
        final createdAt = baseTime.add(Duration(seconds: msgIndex)).toUtc().toIso8601String();
        if (msg.role == 'user') {
          currentAskId = _sha1Hex('$topicId#ask:$askIndex');
          askIndex++;
        }

        final messageId = _sha1Hex('$topicId#msg:$msgIndex');
        final blockIds = <String>[];

        final blocks = await _buildBlocksForMessage(
          topicId: topicId,
          messageId: messageId,
          createdAtIso: createdAt,
          topicSourcePath: topic.sourcePath,
          rawContent: msg.rawContent,
          buildFileRecord: buildFileRecord,
          blockIdPrefix: '$messageId#blk:',
        );
        for (final blk in blocks) {
          blockIds.add(blk['id'] as String);
          blocksData.add(blk);
        }

        messagesData.add({
          'id': messageId,
          'role': msg.role,
          'topicId': topicId,
          'createdAt': createdAt,
          'status': 'success',
          'blocks': blockIds,
          'useful': true,
          if (currentAskId != null) 'askId': currentAskId,
        });

        msgIndex++;
      }

      topicsData.add({
        'id': topicId,
        'messages': messagesData,
        'name': topicName,
      });
    }

    for (final assistant in scan.assistants) {
      final assistantId = (assistant.meta['id'] as String?)?.trim().isNotEmpty == true
          ? assistant.meta['id'] as String
          : _sha1Hex('assistant:${assistant.slug}');
      final assistantName = (assistant.meta['name'] as String?)?.trim().isNotEmpty == true
          ? assistant.meta['name'] as String
          : assistant.slug;

      final topicRefs = <Map<String, dynamic>>[];

      for (final topic in assistant.topics) {
        final rel = _relativePathForHash(scan.rootPath, topic.sourcePath);
        final topicId = (topic.frontMatter['id'] as String?)?.trim().isNotEmpty == true
            ? topic.frontMatter['id'] as String
            : _sha1Hex('topic:$rel');
        final topicName = (topic.frontMatter['name'] as String?)?.trim().isNotEmpty == true
            ? topic.frontMatter['name'] as String
            : topic.topicSlug;

        final createdAtIso = (topic.frontMatter['created_at'] as String?) ??
            (topic.frontMatter['createdAt'] as String?);
        final updatedAtIso = (topic.frontMatter['updated_at'] as String?) ??
            (topic.frontMatter['updatedAt'] as String?);

        final createdAt = _parseIsoOrNow(createdAtIso);
        final updatedAt = _parseIsoOrNow(updatedAtIso, fallback: createdAt);

        topicRefs.add({
          'id': topicId,
          'name': topicName,
          'createdAt': createdAt.toUtc().toIso8601String(),
          'updatedAt': updatedAt.toUtc().toIso8601String(),
        });

        await buildTopicAndBlocks(
          topicId: topicId,
          topic: topic,
          baseTime: createdAt,
          topicName: topicName,
        );
      }

      addAssistant(
        assistantId: assistantId,
        name: assistantName,
        topicRefs: topicRefs,
        extra: assistant.meta,
      );
    }

    if (scan.unassignedTopics.isNotEmpty) {
      final assistantId = _sha1Hex('assistant:chats');
      final topicRefs = <Map<String, dynamic>>[];
      for (final topic in scan.unassignedTopics) {
        final rel = _relativePathForHash(scan.rootPath, topic.sourcePath);
        final topicId = (topic.frontMatter['id'] as String?)?.trim().isNotEmpty == true
            ? topic.frontMatter['id'] as String
            : _sha1Hex('topic:$rel');
        final topicName = (topic.frontMatter['name'] as String?)?.trim().isNotEmpty == true
            ? topic.frontMatter['name'] as String
            : topic.topicSlug;

        final createdAtIso = (topic.frontMatter['created_at'] as String?) ??
            (topic.frontMatter['createdAt'] as String?);
        final updatedAtIso = (topic.frontMatter['updated_at'] as String?) ??
            (topic.frontMatter['updatedAt'] as String?);

        final createdAt = _parseIsoOrNow(createdAtIso);
        final updatedAt = _parseIsoOrNow(updatedAtIso, fallback: createdAt);

        topicRefs.add({
          'id': topicId,
          'name': topicName,
          'createdAt': createdAt.toUtc().toIso8601String(),
          'updatedAt': updatedAt.toUtc().toIso8601String(),
        });

        await buildTopicAndBlocks(
          topicId: topicId,
          topic: topic,
          baseTime: createdAt,
          topicName: topicName,
        );
      }

      addAssistant(
        assistantId: assistantId,
        name: 'chats',
        topicRefs: topicRefs,
        extra: null,
      );
    }

    final persistObject = {
      'assistants': json.encode({'assistants': assistantsList}),
    };

    return {
      'time': nowMs,
      'version': 5,
      'localStorage': {
        'persist:cherry-studio': json.encode(persistObject),
      },
      'indexedDB': {
        'topics': topicsData,
        'message_blocks': blocksData,
        'files': filesData,
        'settings': <dynamic>[],
        'knowledge_notes': <dynamic>[],
        'translate_history': <dynamic>[],
        'quick_phrases': <dynamic>[],
        'translate_languages': <dynamic>[],
      },
    };
  }

  Future<List<Map<String, dynamic>>> _buildBlocksForMessage({
    required String topicId,
    required String messageId,
    required String createdAtIso,
    required String topicSourcePath,
    required String rawContent,
    required Future<Map<String, dynamic>?> Function(String sourcePath) buildFileRecord,
    required String blockIdPrefix,
  }) async {
    final blocks = <Map<String, dynamic>>[];
    final mainTextBlockId = _sha1Hex('${blockIdPrefix}0');
    blocks.add({
      'id': mainTextBlockId,
      'messageId': messageId,
      'type': 'main_text',
      'content': rawContent,
      'createdAt': createdAtIso,
      'status': 'success',
    });

    final matches = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)').allMatches(rawContent).toList();
    var blockIndex = 1;
    for (final m in matches) {
      final path = (m.group(2) ?? '').trim();
      if (path.isEmpty) continue;
      final resolvedPath = _resolvePath(topicSourcePath, path);
      final fileRecord = await buildFileRecord(resolvedPath);
      final blockId = _sha1Hex('$blockIdPrefix$blockIndex');
      final fileId = fileRecord?['id'] as String?;
      blocks.add({
        'id': blockId,
        'messageId': messageId,
        'type': 'image',
        'createdAt': createdAtIso,
        'status': 'success',
        if (fileRecord != null) 'file': fileRecord,
        if (fileRecord != null) 'url': fileRecord['path'],
        if (fileId != null) 'fileId': fileId,
      });
      blockIndex++;
    }

    return blocks;
  }

  String _resolvePath(String markdownFilePath, String maybeRelative) {
    if (p.isAbsolute(maybeRelative)) return p.normalize(maybeRelative);
    final baseDir = p.dirname(markdownFilePath);
    final primary = p.normalize(p.join(baseDir, maybeRelative));
    if (File(primary).existsSync()) return primary;

    final normalizedRel = p.normalize(maybeRelative).replaceAll('\\', '/');
    final filesIdx = normalizedRel.indexOf('files/');
    final root = _findImportRoot(baseDir);
    if (root != null) {
      if (filesIdx >= 0) {
        final sub = normalizedRel.substring(filesIdx);
        final candidate = p.normalize(p.join(root, sub));
        if (File(candidate).existsSync()) return candidate;
      }
      final candidate = p.normalize(p.join(root, normalizedRel));
      if (File(candidate).existsSync()) return candidate;
    }

    return primary;
  }

  String? _findImportRoot(String startDir) {
    var current = Directory(startDir);
    for (var i = 0; i < 10; i++) {
      final filesDir = Directory(p.join(current.path, 'files'));
      final assistantsDir = Directory(p.join(current.path, 'assistants'));
      if (filesDir.existsSync() && assistantsDir.existsSync()) {
        return current.path;
      }
      final parent = current.parent;
      if (parent.path == current.path) break;
      current = parent;
    }
    return null;
  }

  String _relativePathForHash(String rootPath, String filePath) {
    try {
      final rel = p.relative(filePath, from: rootPath);
      return rel.replaceAll('\\', '/');
    } catch (_) {
      return p.basename(filePath);
    }
  }

  DateTime _parseIsoOrNow(String? iso, {DateTime? fallback}) {
    if (iso == null || iso.trim().isEmpty) {
      return fallback ?? DateTime.now();
    }
    return DateTime.tryParse(iso)?.toUtc() ?? (fallback ?? DateTime.now());
  }

  String _sha1Hex(String input) => sha1.convert(utf8.encode(input)).toString();

  String _inferFileType(String ext) {
    final e = ext.startsWith('.') ? ext.substring(1) : ext;
    final lower = e.toLowerCase();
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'};
    if (imageExts.contains(lower)) return 'image';
    return 'file';
  }
}
