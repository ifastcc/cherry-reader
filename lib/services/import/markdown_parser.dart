import 'dart:io';

import 'package:path/path.dart' as p;

class ParsedTopic {
  final String sourcePath;
  final String topicSlug;
  final Map<String, dynamic> frontMatter;
  final List<ParsedMessage> messages;
  final List<ParsedAttachment> attachments;

  ParsedTopic({
    required this.sourcePath,
    required this.topicSlug,
    required this.frontMatter,
    required this.messages,
    required this.attachments,
  });
}

class ParsedMessage {
  final String role;
  final String rawContent;

  ParsedMessage({
    required this.role,
    required this.rawContent,
  });
}

class ParsedAttachment {
  final String kind;
  final String displayName;
  final String sourcePath;

  ParsedAttachment({
    required this.kind,
    required this.displayName,
    required this.sourcePath,
  });
}

class MarkdownParser {
  static final RegExp _frontMatterDelimiter = RegExp(r'^\s*---\s*$', multiLine: true);
  static final RegExp _headingRegExp =
      RegExp(r'^\s*##\s*(User|Assistant)\s*$', caseSensitive: false);
  static final RegExp _imageRegExp = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');

  Future<ParsedTopic> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Markdown 文件不存在: $filePath');
    }

    final text = await file.readAsString();
    final (frontMatter, body) = _splitFrontMatter(text);

    final topicSlug = p.basenameWithoutExtension(filePath);
    final (messages, attachments) = _parseMessagesAndAttachments(body, filePath);

    return ParsedTopic(
      sourcePath: filePath,
      topicSlug: topicSlug,
      frontMatter: frontMatter,
      messages: messages,
      attachments: attachments,
    );
  }

  (Map<String, dynamic> frontMatter, String body) _splitFrontMatter(String content) {
    if (!content.trimLeft().startsWith('---')) {
      return (<String, dynamic>{}, content);
    }

    final matches = _frontMatterDelimiter.allMatches(content).toList();
    if (matches.length < 2) {
      return (<String, dynamic>{}, content);
    }

    final start = matches[0].end;
    final end = matches[1].start;
    final frontMatterText = content.substring(start, end).trim();
    final body = content.substring(matches[1].end).trimLeft();
    final frontMatter = _parseSimpleYaml(frontMatterText);
    return (frontMatter, body);
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

  (List<ParsedMessage> messages, List<ParsedAttachment> attachments) _parseMessagesAndAttachments(
    String body,
    String sourceFilePath,
  ) {
    final lines = body.split(RegExp(r'\r?\n'));
    final messages = <ParsedMessage>[];
    final attachments = <ParsedAttachment>[];

    String? currentRole;
    final buffer = StringBuffer();

    void flush() {
      if (currentRole == null) return;
      final content = buffer.toString().trim();
      buffer.clear();
      if (content.isEmpty) return;

      final normalizedRole = currentRole!.toLowerCase() == 'assistant' ? 'assistant' : 'user';
      messages.add(ParsedMessage(role: normalizedRole, rawContent: content));

      for (final match in _imageRegExp.allMatches(content)) {
        final alt = (match.group(1) ?? '').trim();
        final path = (match.group(2) ?? '').trim();
        if (path.isEmpty) continue;
        final resolved = _resolvePath(sourceFilePath, path);
        attachments.add(
          ParsedAttachment(
            kind: 'image',
            displayName: alt.isNotEmpty ? alt : p.basename(resolved),
            sourcePath: resolved,
          ),
        );
      }
    }

    for (final line in lines) {
      final heading = _headingRegExp.firstMatch(line);
      if (heading != null) {
        flush();
        currentRole = heading.group(1);
        continue;
      }
      buffer.writeln(line);
    }
    flush();

    return (messages, attachments);
  }

  String _resolvePath(String markdownFilePath, String maybeRelative) {
    if (p.isAbsolute(maybeRelative)) return maybeRelative;
    final baseDir = p.dirname(markdownFilePath);
    return p.normalize(p.join(baseDir, maybeRelative));
  }
}

