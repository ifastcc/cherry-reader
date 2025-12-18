import '../../repository_provider.dart';
import '../../../models/domain/block_model.dart';
import '../../../models/domain/message_model.dart';
import 'mcp_tool_base.dart';

/// 获取对话内容
///
/// 核心工具，支持三种模式获取对话内容
class GetConversationTool extends MCPTool {
  @override
  String get name => 'read_conversation_detail';

  @override
  String get description => '''读取某个话题的完整对话内容。

当需要查看具体某个话题的详细问答时使用。
支持通过 topic_id 或 topic_name（模糊匹配）查找话题。

模式：queries_only（仅问题）、mainline（主线对话）、full（全部含弃用回复）。''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'topic_id': {
            'type': 'string',
            'description': '话题 ID（与 topic_name 二选一）',
          },
          'topic_name': {
            'type': 'string',
            'description': '话题名称，支持模糊匹配（与 topic_id 二选一）',
          },
          'mode': {
            'type': 'string',
            'enum': ['queries_only', 'mainline', 'full'],
            'description': '获取模式，默认 mainline',
          },
          'start_round': {
            'type': 'integer',
            'description': '起始轮次（从 0 开始），默认 0',
          },
          'round_count': {
            'type': 'integer',
            'description': '获取轮次数，默认 10',
          },
          'include_thinking': {
            'type': 'boolean',
            'description': '是否包含 AI 思考过程，默认 false',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    var topicId = arguments['topic_id'] as String?;
    final topicName = arguments['topic_name'] as String?;

    // 需要提供 topic_id 或 topic_name
    if ((topicId == null || topicId.isEmpty) &&
        (topicName == null || topicName.isEmpty)) {
      throw ArgumentError('topic_id 或 topic_name 至少需要提供一个');
    }

    final topicRepo = RepositoryProvider.instance.topicRepository;
    String? matchedTopicName;

    // 通过话题名查找
    if (topicId == null || topicId.isEmpty) {
      final allTopics = await topicRepo.getAllTopics();
      final nameLower = topicName!.toLowerCase();

      // 1. 先找完全匹配的（名称等于关键词）
      var matches = allTopics.where((t) => t.name.toLowerCase() == nameLower).toList();

      // 2. 如果没有完全匹配，找包含匹配的
      if (matches.isEmpty) {
        matches = allTopics.where((t) => t.name.toLowerCase().contains(nameLower)).toList();
      }

      if (matches.isEmpty) {
        throw ArgumentError('未找到名称匹配 "$topicName" 的话题');
      }

      // 如果有多个匹配，按更新时间降序取最新的
      matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      topicId = matches.first.topicId;
      matchedTopicName = matches.first.name;
    }

    final mode = arguments['mode'] as String? ?? 'mainline';
    final startRound = arguments['start_round'] as int? ?? 0;
    final roundCount = arguments['round_count'] as int? ?? 10;
    final includeThinking = arguments['include_thinking'] as bool? ?? false;

    final messageRepo = RepositoryProvider.instance.messageRepository;

    // 加载消息
    final messages = await messageRepo.loadRounds(
      topicId,
      startRound: startRound,
      roundCount: roundCount,
    );

    // 加载所有 Block
    final blocksMap = await messageRepo.loadBlocksByTopic(topicId);

    // 根据模式过滤
    List filtered;
    switch (mode) {
      case 'queries_only':
        filtered = messages.where((m) => m.isUser).toList();
        break;
      case 'mainline':
        // 主线模式：用户消息 + 主线回复
        // 如果某轮没有 useful=true 的回复，回退到该轮第一个助手消息
        filtered = _filterMainline(messages.toList());
        break;
      case 'full':
      default:
        filtered = messages.toList();
    }

    // 构建结果
    final rounds = <Map<String, dynamic>>[];
    int? currentRound;
    Map<String, dynamic>? currentRoundData;

    for (final msg in filtered) {
      if (msg.roundIndex != currentRound) {
        if (currentRoundData != null) {
          rounds.add(currentRoundData);
        }
        currentRound = msg.roundIndex;
        currentRoundData = {
          'round': msg.roundIndex,
          'messages': [],
        };
      }

      final blocks = blocksMap[msg.messageId] ?? [];
      final content = _extractContent(blocks, includeThinking);

      (currentRoundData!['messages'] as List).add({
        'id': msg.messageId,
        'role': msg.role,
        'model': msg.displayModelName,
        'useful': msg.useful,
        'content': content,
        'created_at':
            DateTime.fromMillisecondsSinceEpoch(msg.createdAt).toIso8601String(),
      });
    }

    if (currentRoundData != null) {
      rounds.add(currentRoundData);
    }

    final result = <String, dynamic>{
      'topic_id': topicId,
      'mode': mode,
      'start_round': startRound,
      'round_count': rounds.length,
      'rounds': rounds,
    };

    // 如果是通过话题名匹配的，返回匹配的话题名
    if (matchedTopicName != null) {
      result['topic_name'] = matchedTopicName;
    }

    return result;
  }

  /// 过滤主线消息
  ///
  /// 规则：
  /// 1. 用户消息全部保留
  /// 2. 助手消息只保留 useful=true 的
  /// 3. 如果某轮没有 useful=true 的助手消息，回退到该轮第一个助手消息
  List<MessageModel> _filterMainline(List<MessageModel> messages) {
    // 按轮次分组
    final roundMap = <int, List<MessageModel>>{};
    for (final msg in messages) {
      roundMap.putIfAbsent(msg.roundIndex, () => []).add(msg);
    }

    final result = <MessageModel>[];

    // 按轮次顺序处理
    final sortedRounds = roundMap.keys.toList()..sort();
    for (final round in sortedRounds) {
      final roundMessages = roundMap[round]!;

      // 添加所有用户消息
      final userMessages = roundMessages.where((m) => m.isUser).toList();
      result.addAll(userMessages);

      // 处理助手消息
      final assistantMessages = roundMessages.where((m) => m.isAssistant).toList();
      if (assistantMessages.isEmpty) continue;

      // 找 useful=true 的
      final usefulMessages = assistantMessages.where((m) => m.useful).toList();
      if (usefulMessages.isNotEmpty) {
        // 有主线消息，只添加主线
        result.addAll(usefulMessages);
      } else {
        // 没有主线消息，回退到第一个助手消息
        result.add(assistantMessages.first);
      }
    }

    return result;
  }

  /// 提取消息内容
  String _extractContent(List<BlockModel> blocks, bool includeThinking) {
    final buffer = StringBuffer();

    for (final block in blocks) {
      if (block.isMainText && block.content != null) {
        buffer.writeln(block.content);
      } else if (includeThinking && block.isThinking && block.content != null) {
        buffer.writeln('<thinking>');
        buffer.writeln(block.content);
        buffer.writeln('</thinking>');
      }
    }

    return buffer.toString().trim();
  }
}
