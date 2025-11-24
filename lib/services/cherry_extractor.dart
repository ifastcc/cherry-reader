import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../models/export_data.dart';

/// Cherry Studio 数据提取器
///
/// 对应 Python 的 CherryStudioExtractor 类
/// 核心功能：
/// 1. 从 ZIP 或 JSON 加载数据
/// 2. 构建 block_id -> block 的索引
/// 3. 提取和组装完整对话
class CherryExtractor {
  String? zipPath;
  String? dataJsonPath;

  ExportData? exportData;
  Map<String, dynamic>? rawData;

  // 索引数据
  Map<String, dynamic> blockMap = {};
  List<dynamic> topics = [];
  List<dynamic> messageBlocks = [];
  List<dynamic> files = [];
  List<dynamic> assistants = [];
  Map<String, dynamic> assistantMap = {};

  CherryExtractor({this.zipPath, this.dataJsonPath}) {
    if (zipPath == null && dataJsonPath == null) {
      throw ArgumentError('必须指定 zipPath 或 dataJsonPath');
    }
  }

  /// 从缓存数据创建 (用于快速加载)
  CherryExtractor.fromCachedData(Map<String, dynamic> data) {
    rawData = data;
    _buildIndexes();
  }

  /// 加载数据（主入口）
  Future<CherryExtractor> load() async {
    if (zipPath != null) {
      await _loadFromZip();
    } else if (dataJsonPath != null) {
      await _loadFromJson();
    }

    _buildIndexes();
    return this;
  }

  /// 从 ZIP 包加载
  Future<void> _loadFromZip() async {
    print('📦 正在解压: $zipPath');

    final bytes = await File(zipPath!).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 查找 data.json
    for (final file in archive) {
      if (file.name == 'data.json' && file.isFile) {
        final content = file.content as List<int>;
        final jsonString = utf8.decode(content);
        rawData = json.decode(jsonString) as Map<String, dynamic>;
        break;
      }
    }

    if (rawData == null) {
      throw Exception('ZIP 中未找到 data.json');
    }

    print('✅ 解压完成');
  }

  /// 从 JSON 文件加载
  Future<void> _loadFromJson() async {
    print('📄 正在加载: $dataJsonPath');

    final file = File(dataJsonPath!);
    final jsonString = await file.readAsString();
    rawData = json.decode(jsonString) as Map<String, dynamic>;

    print('✅ 加载完成');
  }

  /// 构建索引
  void _buildIndexes() {
    print('🔨 正在构建索引...');

    if (rawData == null) {
      throw Exception('数据未加载');
    }

    final indexedDB = rawData!['indexedDB'] as Map<String, dynamic>? ?? {};

    // 提取各个表
    topics = indexedDB['topics'] as List<dynamic>? ?? [];
    messageBlocks = indexedDB['message_blocks'] as List<dynamic>? ?? [];
    files = indexedDB['files'] as List<dynamic>? ?? [];

    // 构建 block_id -> block 的映射
    for (final block in messageBlocks) {
      if (block is Map<String, dynamic>) {
        final id = block['id'] as String?;
        if (id != null) {
          blockMap[id] = block;
        }
      }
    }

    // 提取 assistants 信息
    _extractAssistants();

    print('  - 话题数: ${topics.length}');
    print('  - 消息块数: ${messageBlocks.length}');
    print('  - 文件数: ${files.length}');
    print('  - Assistant数: ${assistants.length}');
    print('✅ 索引构建完成');
  }

  /// 从 localStorage 中提取 assistants 信息
  void _extractAssistants() {
    try {
      final localStorage =
          rawData!['localStorage'] as Map<String, dynamic>? ?? {};
      final persistDataStr = localStorage['persist:cherry-studio'];

      Map<String, dynamic> persistData;
      if (persistDataStr is String) {
        persistData = json.decode(persistDataStr) as Map<String, dynamic>;
      } else {
        persistData = persistDataStr as Map<String, dynamic>? ?? {};
      }

      final assistantsStr = persistData['assistants'];
      Map<String, dynamic> assistantsData;

      if (assistantsStr is String) {
        assistantsData = json.decode(assistantsStr) as Map<String, dynamic>;
      } else {
        assistantsData = assistantsStr as Map<String, dynamic>? ?? {};
      }

      assistants = assistantsData['assistants'] as List<dynamic>? ?? [];

      // 构建 id -> assistant 映射
      for (final asst in assistants) {
        if (asst is Map<String, dynamic>) {
          final id = asst['id'] as String?;
          if (id != null) {
            assistantMap[id] = asst;
          }
        }
      }
    } catch (e) {
      print('⚠️  提取 assistants 信息失败: $e');
      assistants = [];
      assistantMap = {};
    }
  }

  /// 获取指定话题
  Map<String, dynamic>? getTopic(String topicId) {
    for (final topic in topics) {
      if (topic is Map<String, dynamic> && topic['id'] == topicId) {
        return topic;
      }
    }
    return null;
  }

  /// 获取所有话题
  List<dynamic> getAllTopics() {
    return topics;
  }

  /// 获取所有 assistants
  List<dynamic> getAssistants() {
    return assistants;
  }

  /// 根据 ID 获取 assistant 信息
  Map<String, dynamic>? getAssistantById(String assistantId) {
    return assistantMap[assistantId];
  }

  /// 按 assistant 分组话题，并附加话题名称
  ///
  /// 返回:
  /// {
  ///   'assistant_id': {
  ///     'assistant': {...},  // assistant 信息
  ///     'topics': [...]      // 该 assistant 的所有话题（带名称）
  ///   }
  /// }
  Map<String, Map<String, dynamic>> getTopicsByAssistant() {
    final grouped = <String, Map<String, dynamic>>{};

    // 构建 topic_id -> full_topic 的映射（从 indexedDB）
    final topicFullMap = <String, Map<String, dynamic>>{};
    for (final topic in topics) {
      if (topic is Map<String, dynamic>) {
        final id = topic['id'] as String?;
        if (id != null) {
          topicFullMap[id] = topic;
        }
      }
    }

    // 遍历所有 assistants，按照 localStorage 中的归属关系分组
    for (final assistant in assistants) {
      if (assistant is! Map<String, dynamic>) continue;

      final assistantId = assistant['id'] as String?;
      if (assistantId == null) continue;

      // 初始化分组
      grouped[assistantId] = {
        'assistant': assistant,
        'topics': <Map<String, dynamic>>[],
      };

      // 遍历该 assistant 的 topics 数组（来自 localStorage）
      final assistantTopics = assistant['topics'] as List<dynamic>? ?? [];
      for (final topicWithName in assistantTopics) {
        if (topicWithName is! Map<String, dynamic>) continue;

        final topicId = topicWithName['id'] as String?;
        if (topicId == null) continue;

        // 从 indexedDB 中获取完整的话题数据（包含 messages）
        final fullTopic = topicFullMap[topicId];
        if (fullTopic == null) {
          // 如果 indexedDB 中找不到，可能是已删除的话题
          continue;
        }

        // 合并两者：indexedDB 的数据 + localStorage 的元数据
        final mergedTopic = {
          ...fullTopic, // messages 等数据在这里
          'name': topicWithName['name'] ?? '未命名话题',
          'createdAt': topicWithName['createdAt'],
          'updatedAt': topicWithName['updatedAt'],
        };

        // 添加话题
        (grouped[assistantId]!['topics'] as List).add(mergedTopic);
      }
    }

    return grouped;
  }

  /// 根据 ID 列表获取消息块
  List<Map<String, dynamic>> getMessageBlocks(List<String> blockIds) {
    final blocks = <Map<String, dynamic>>[];

    for (final blockId in blockIds) {
      final block = blockMap[blockId];
      if (block != null && block is Map<String, dynamic>) {
        blocks.add(block);
      } else {
        print('⚠️  警告: 找不到消息块 $blockId');
      }
    }

    return blocks;
  }

  /// 提取指定话题的完整对话
  Map<String, dynamic>? extractTopicConversation(String topicId) {
    final topic = getTopic(topicId);
    if (topic == null) {
      print('❌ 错误: 找不到话题 $topicId');
      return null;
    }

    return _processTopic(topic);
  }

  /// 导出为 Map (用于缓存)
  Map<String, dynamic> exportToMap() {
    return rawData ?? {};
  }

  /// 提取所有对话
  List<Map<String, dynamic>> extractAllConversations() {
    print('🔍 开始提取所有对话...');
    final conversations = <Map<String, dynamic>>[];

    for (var i = 0; i < topics.length; i++) {
      if ((i + 1) % 100 == 0) {
        print('  处理进度: ${i + 1}/${topics.length}');
      }

      if (topics[i] is Map<String, dynamic>) {
        final conv = _processTopic(topics[i] as Map<String, dynamic>);
        if (conv != null) {
          conversations.add(conv);
        }
      }
    }

    print('✅ 提取完成，共 ${conversations.length} 个对话');
    return conversations;
  }

  /// 处理单个话题
  Map<String, dynamic>? _processTopic(Map<String, dynamic> topic) {
    final messages = topic['messages'] as List<dynamic>? ?? [];
    final processedMessages = <Map<String, dynamic>>[];

    var totalTokens = 0;
    var userCount = 0;
    var assistantCount = 0;
    String? firstTime;
    String? lastTime;

    for (final message in messages) {
      if (message is! Map<String, dynamic>) continue;

      // 统计
      final role = message['role'] as String? ?? '';
      if (role == 'user') {
        userCount++;
      } else if (role == 'assistant') {
        assistantCount++;
      }

      // Token 统计
      final usage = message['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        totalTokens += (usage['total_tokens'] as int?) ?? 0;
      }

      // 时间
      final createdAt = message['createdAt'] as String? ?? '';
      firstTime ??= createdAt;
      lastTime = createdAt;

      // 获取消息块内容
      final blockIds =
          (message['blocks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final blocks = getMessageBlocks(blockIds);

      // 构建完整消息
      final processedMessage = {
        'id': message['id'],
        'role': role,
        'created_at': createdAt,
        'status': message['status'],
        'model': message['model'],
        'usage': usage,
        'metrics': message['metrics'],
        'mentions': message['mentions'], // 添加 mentions 信息
        'blocks': _processBlocks(blocks),
      };

      processedMessages.add(processedMessage);
    }

    return {
      'topic_id': topic['id'],
      'topic_count': 1,
      'message_count': messages.length,
      'block_count': processedMessages.fold<int>(
        0,
        (sum, m) => sum + ((m['blocks'] as List?)?.length ?? 0),
      ),
      'messages': processedMessages,
      'total_tokens': totalTokens,
      'user_message_count': userCount,
      'assistant_message_count': assistantCount,
      'first_message_time': firstTime,
      'last_message_time': lastTime,
    };
  }

  /// 处理消息块
  List<Map<String, dynamic>> _processBlocks(List<Map<String, dynamic>> blocks) {
    final processedBlocks = <Map<String, dynamic>>[];

    for (final block in blocks) {
      final blockType = block['type'] as String? ?? 'unknown';

      final processedBlock = {
        'id': block['id'],
        'type': blockType,
        'status': block['status'],
        'created_at': block['createdAt'],
      };

      // 根据类型提取特定内容
      switch (blockType) {
        case 'main_text':
          processedBlock['content'] = block['content'] ?? '';
          processedBlock['citation_references'] =
              block['citationReferences'] ?? [];
          break;

        case 'thinking':
          processedBlock['content'] = block['content'] ?? '';
          processedBlock['thinking_ms'] = block['thinking_millsec'] ?? 0;
          break;

        case 'image':
          processedBlock['url'] = block['url'];
          processedBlock['file'] = block['file'];
          break;

        case 'file':
          processedBlock['file'] = block['file'];
          break;

        case 'error':
          processedBlock['error'] = block['error'];
          break;

        case 'tool':
          processedBlock['tool_id'] = block['toolId'];
          processedBlock['tool_name'] = block['toolName'];
          processedBlock['arguments'] = block['arguments'];
          processedBlock['content'] = block['content'];
          break;

        case 'citation':
          processedBlock['response'] = block['response'];
          processedBlock['knowledge'] = block['knowledge'];
          break;

        case 'translation':
          processedBlock['content'] = block['content'] ?? '';
          processedBlock['target_language'] = block['targetLanguage'];
          break;

        default:
          // 未知类型，保存原始内容
          processedBlock['raw'] = block;
      }

      processedBlocks.add(processedBlock);
    }

    return processedBlocks;
  }

  /// 获取总体统计信息
  Map<String, dynamic> getStatistics() {
    var totalMessages = 0;
    var totalUserMessages = 0;
    var totalAssistantMessages = 0;
    var totalTokens = 0;

    final blockTypeCounts = <String, int>{};
    final blockStatusCounts = <String, int>{};

    for (final topic in topics) {
      if (topic is! Map<String, dynamic>) continue;

      final messages = topic['messages'] as List<dynamic>? ?? [];
      totalMessages += messages.length;

      for (final message in messages) {
        if (message is! Map<String, dynamic>) continue;

        final role = message['role'] as String? ?? '';
        if (role == 'user') {
          totalUserMessages++;
        } else if (role == 'assistant') {
          totalAssistantMessages++;
        }

        final usage = message['usage'] as Map<String, dynamic>?;
        if (usage != null) {
          totalTokens += (usage['total_tokens'] as int?) ?? 0;
        }

        // Block IDs 已统计在 messageBlocks.length 中
      }
    }

    // 统计消息块类型
    for (final block in messageBlocks) {
      if (block is! Map<String, dynamic>) continue;

      final blockType = block['type'] as String? ?? 'unknown';
      final blockStatus = block['status'] as String? ?? 'unknown';

      blockTypeCounts[blockType] = (blockTypeCounts[blockType] ?? 0) + 1;
      blockStatusCounts[blockStatus] =
          (blockStatusCounts[blockStatus] ?? 0) + 1;
    }

    return {
      'export_time': rawData!['time'],
      'export_version': rawData!['version'],
      'topics_count': topics.length,
      'messages_count': totalMessages,
      'user_messages_count': totalUserMessages,
      'assistant_messages_count': totalAssistantMessages,
      'blocks_count': messageBlocks.length,
      'files_count': files.length,
      'total_tokens': totalTokens,
      'block_types': blockTypeCounts,
      'block_statuses': blockStatusCounts,
    };
  }
}
