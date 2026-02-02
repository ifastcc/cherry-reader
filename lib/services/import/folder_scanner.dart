import 'dart:io';

import 'package:path/path.dart' as p;

import 'markdown_parser.dart';

class ScannedAssistant {
  final String slug;
  final Map<String, dynamic> meta;
  final List<ParsedTopic> topics;

  ScannedAssistant({
    required this.slug,
    required this.meta,
    required this.topics,
  });
}

class ScanResult {
  final String rootPath;
  final List<ScannedAssistant> assistants;
  final List<ParsedTopic> unassignedTopics;

  ScanResult({
    required this.rootPath,
    required this.assistants,
    required this.unassignedTopics,
  });
}

class FolderScanner {
  final MarkdownParser _parser;

  FolderScanner({MarkdownParser? parser}) : _parser = parser ?? MarkdownParser();

  Future<ScanResult> scan(String rootPath) async {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) {
      throw Exception('导入目录不存在: $rootPath');
    }

    final assistantsDir = Directory(p.join(rootPath, 'assistants'));
    final chatsDir = Directory(p.join(rootPath, 'chats'));

    final assistants = <ScannedAssistant>[];
    if (await assistantsDir.exists()) {
      final children = await assistantsDir.list(followLinks: false).toList();
      for (final child in children) {
        if (child is! Directory) continue;
        final slug = p.basename(child.path);
        if (slug.startsWith('.')) continue;
        final meta = await _readOptionalMeta(child.path);
        final topics = await _scanTopicsInDir(child.path);
        assistants.add(ScannedAssistant(slug: slug, meta: meta, topics: topics));
      }
    }

    final unassignedTopics = <ParsedTopic>[];
    if (await chatsDir.exists()) {
      final topics = await _scanTopicsInDir(chatsDir.path);
      unassignedTopics.addAll(topics);
    }

    return ScanResult(
      rootPath: rootPath,
      assistants: assistants,
      unassignedTopics: unassignedTopics,
    );
  }

  Future<Map<String, dynamic>> _readOptionalMeta(String assistantDirPath) async {
    final metaFile = File(p.join(assistantDirPath, '_meta.yaml'));
    if (!await metaFile.exists()) return <String, dynamic>{};
    final text = await metaFile.readAsString();
    return _parseSimpleYaml(text);
  }

  Map<String, dynamic> _parseSimpleYaml(String yamlText) {
    final map = <String, dynamic>{};
    final lines = yamlText.split(RegExp(r'\r?\n'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim();
      var value = line.substring(idx + 1).trim();
      if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
        value = value.substring(1, value.length - 1);
      } else if (value.startsWith("'") && value.endsWith("'") && value.length >= 2) {
        value = value.substring(1, value.length - 1);
      }
      if (value.isEmpty) {
        map[key] = '';
        continue;
      }
      final numValue = num.tryParse(value);
      if (numValue != null) {
        map[key] = numValue;
        continue;
      }
      if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
        map[key] = value.toLowerCase() == 'true';
        continue;
      }
      map[key] = value;
    }
    return map;
  }

  Future<List<ParsedTopic>> _scanTopicsInDir(String dirPath) async {
    final dir = Directory(dirPath);
    final topics = <ParsedTopic>[];
    final children = await dir.list(recursive: false, followLinks: false).toList();
    for (final child in children) {
      if (child is! File) continue;
      if (!child.path.toLowerCase().endsWith('.md')) continue;
      if (p.basename(child.path).toLowerCase() == '_meta.yaml') continue;
      topics.add(await _parser.parseFile(child.path));
    }
    topics.sort((a, b) => a.topicSlug.compareTo(b.topicSlug));
    return topics;
  }
}

