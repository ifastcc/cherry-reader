import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:cherry_reader/services/import/source_adapter.dart';

void main() {
  test('SourceAdapter loads markdown as CherryExtractor-compatible rawData', () async {
    final dir = await Directory.systemTemp.createTemp('cherry_import_md_');
    addTearDown(() async {
      await dir.delete(recursive: true);
    });

    final md = File('${dir.path}/topic.md');
    await md.writeAsString(r'''
---
name: "测试话题"
created_at: 2024-01-15T10:00:00Z
---

## User
你好

## Assistant
世界
''');

    final adapter = SourceAdapter();
    final extractor = await adapter.loadExtractor(md.path);

    expect(extractor.rawData, isNotNull);
    final grouped = extractor.getTopicsByAssistant();
    expect(grouped.isNotEmpty, isTrue);

    final first = grouped.entries.first.value;
    final topics = first['topics'] as List<dynamic>;
    expect(topics.length, 1);

    final topic = topics.first as Map<String, dynamic>;
    expect(topic['name'], '测试话题');
    final messages = topic['messages'] as List<dynamic>;
    expect(messages.length, 2);
  });

  test('SourceAdapter loads folder structure with assistants and images', () async {
    final dir = await Directory.systemTemp.createTemp('cherry_import_folder_');
    addTearDown(() async {
      await dir.delete(recursive: true);
    });

    final assistantsDir = Directory('${dir.path}/assistants/coding-helper');
    await assistantsDir.create(recursive: true);
    await File('${assistantsDir.path}/_meta.yaml').writeAsString('name: "编程助手"\n');

    final filesDir = Directory('${dir.path}/files');
    await filesDir.create(recursive: true);
    final img = File('${filesDir.path}/diagram.png');
    await img.writeAsBytes(List<int>.filled(16, 7));

    final topicMd = File('${assistantsDir.path}/react.md');
    await topicMd.writeAsString('''
---
name: React
created_at: 2024-01-15T10:00:00Z
---

## User
看图
![diagram](../files/diagram.png)

## Assistant
收到
''');

    final adapter = SourceAdapter();
    final extractor = await adapter.loadExtractor(dir.path);

    final grouped = extractor.getTopicsByAssistant();
    expect(grouped.length, 1);

    final entry = grouped.entries.first;
    final assistant = entry.value['assistant'] as Map<String, dynamic>;
    expect(assistant['name'], '编程助手');

    final topics = entry.value['topics'] as List<dynamic>;
    final topic = topics.single as Map<String, dynamic>;
    final messages = topic['messages'] as List<dynamic>;
    final firstMsg = messages.first as Map<String, dynamic>;
    final blockIds = (firstMsg['blocks'] as List).cast<String>();
    expect(blockIds.isNotEmpty, isTrue);

    final hasImageBlock = blockIds.any((id) {
      final blk = extractor.blockMap[id];
      return blk is Map<String, dynamic> && blk['type'] == 'image';
    });
    expect(hasImageBlock, isTrue);

    expect(extractor.files.isNotEmpty, isTrue);
  });
}

