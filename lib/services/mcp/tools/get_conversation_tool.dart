import '../../repository_provider.dart';
import '../../../models/domain/block_model.dart';
import '../../../models/domain/message_model.dart';
import 'mcp_tool_base.dart';

/// 获取对话内容
///
/// 核心工具，支持三种模式获取对话内容
class GetConversationTool extends MCPTool {
  @override
  String get name => 'get_conversation';

  @override
  String get description => '''获取话题的对话内容，支持三种模式：

1. **queries_only**: 仅返回用户问题（快速浏览话题内容）
2. **mainline**: 返回主线对话，包括问题和主线回复（useful=true 的消息）
3. **full**: 返回完整对话，包括被弃用的多模型回复

适用场景：
- 快速了解话题讨论了什么：使用 queries_only
- 回顾完整的讨论过程：使用 mainline
- 查看所有多模型对比回复：使用 full''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'topic_id': {
            'type': 'string',
            'description': '话题 ID',
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
        'required': ['topic_id'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final topicId = arguments['topic_id'] as String?;
    if (topicId == null || topicId.isEmpty) {
      throw ArgumentError('topic_id is required');
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

    return {
      'topic_id': topicId,
      'mode': mode,
      'start_round': startRound,
      'round_count': rounds.length,
      'rounds': rounds,
    };
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
