import 'package:flutter/material.dart';
import 'context_selector.dart' show TopicSummary;
import '../services/topic_index_service.dart';

/// UI 风格枚举（仅保留语义图标风格）
enum ContextStyleVariant {
  semantic,    // 语义化图标（有边框卡片）
}

/// Context 选择器 - 混合风格（卡片质感 + 极简连接线 + 层级颜色）
///
/// 优化：使用 TopicIndexService 常驻索引，打开即显示
class ContextSelectorWithStyles extends StatefulWidget {
  final Map<String, dynamic>? contextData;
  final String contextSnapshot;
  final int? currentRoundIndex;
  final String? currentTopicId;
  final String? currentTopicName;
  final String? currentAssistantId;
  final String? currentAssistantName;
  final Function(String newSnapshot, String? contextDataJson)? onContextChanged;
  final VoidCallback? onClear;
  /// 备用：如果 TopicIndexService 未初始化时使用
  final Future<List<TopicSummary>> Function(String? assistantId)? onLoadTopics;
  final Future<Map<String, dynamic>?> Function(String topicId)? onLoadTopicDetail;

  /// 只读模式：隐藏勾选框、操作按钮和底部 footer
  final bool readOnly;

  const ContextSelectorWithStyles({
    super.key,
    this.contextData,
    required this.contextSnapshot,
    this.currentRoundIndex,
    this.currentTopicId,
    this.currentTopicName,
    this.currentAssistantId,
    this.currentAssistantName,
    this.onContextChanged,
    this.onClear,
    this.onLoadTopics,
    this.onLoadTopicDetail,
    this.readOnly = false,
  });

  @override
  State<ContextSelectorWithStyles> createState() => _ContextSelectorWithStylesState();
}

/// 设计原则：
/// - "选中"是最强视觉信号 → 左侧竖条 + 背景色 + 绿色勾
/// - "当前"是位置提示 → 小标签
/// - "展开"仅作结构指示 → 图标方向
/// - 层级用缩进区分，不用颜色

/// 状态颜色定义
const _selectedColor = Color(0xFF4CAF50);  // 选中状态：绿色
const _currentColor = Color(0xFF2196F3);   // 当前位置：蓝色
const _mainlineColor = Color(0xFFFFB300);  // 主线推荐：琥珀色

class _ContextSelectorWithStylesState extends State<ContextSelectorWithStyles> {

  // ===== 4 层数据结构 =====
  final List<_AssistantNode> _assistants = [];
  final Map<String, bool> _selections = {};

  // ===== 展开状态 =====
  final Set<String> _expandedAssistants = {};
  final Set<String> _expandedTopics = {};
  final Set<String> _expandedRounds = {};
  final Set<String> _expandedReplies = {};

  // ===== 加载状态 =====
  bool _isLoadingTopics = false;
  bool _hasLoadedTopics = false;
  final Set<String> _loadingTopicIds = {};
  final Set<String> _loadingReplyIds = {};  // 正在加载完整内容的回复

  // ===== 完整内容缓存（按需加载）=====
  final Map<String, String> _fullContentCache = {};

  // 索引服务引用
  final _indexService = TopicIndexService.instance;

  final ScrollController _scrollController = ScrollController();

  // 暂存当前话题的轮次数据
  List<_RoundNode> _currentTopicRounds = [];

  @override
  void initState() {
    super.initState();
    _parseContextData();
    _initFromIndexService();
  }

  /// 从索引服务初始化（同步，无闪烁）
  void _initFromIndexService() {
    // 如果索引服务已初始化，直接使用
    if (_indexService.isInitialized) {
      _buildFromIndexService();
      return;
    }

    // 索引服务未初始化，用当前话题数据先展示
    if (widget.currentTopicId != null && _currentTopicRounds.isNotEmpty) {
      _initCurrentTopicOnly();
      return;
    }

    // 都没有，回退到传统加载方式
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onLoadTopics != null) {
        _loadTopics();
      }
    });
  }

  /// 从索引服务构建视图（同步）
  void _buildFromIndexService() {
    _assistants.clear();

    final groupedTopics = _indexService.topicsGroupedByAssistant;
    final currentAssistantId = widget.currentAssistantId;
    final currentTopicId = widget.currentTopicId;

    // 跟踪是否找到了当前话题
    bool foundCurrentTopic = false;

    for (final entry in groupedTopics.entries) {
      final assistantId = entry.key;
      final topics = entry.value;
      final assistantInfo = _indexService.getAssistant(assistantId);
      final isCurrentAssistant = assistantId == currentAssistantId;

      final topicNodes = <_TopicNode>[];
      for (final topic in topics) {
        final isCurrentTopic = topic.id == currentTopicId;
        if (isCurrentTopic) foundCurrentTopic = true;

        // 如果是当前话题，使用传入的 contextData 构建轮次
        List<_RoundNode> rounds;
        bool isLoaded;
        if (isCurrentTopic && _currentTopicRounds.isNotEmpty) {
          rounds = _currentTopicRounds;
          isLoaded = true;
        } else if (topic.isRoundsLoaded) {
          // 从索引服务获取轮次（预览数据）
          rounds = topic.rounds.map((r) => _RoundNode(
            index: r.index,
            question: r.questionPreview,
            replies: r.replies.map((reply) => _ReplyNode(
              id: reply.id,
              modelName: reply.modelName,
              content: reply.contentPreview,  // 只有预览
              isMainline: reply.isMainline,
              charCount: reply.charCount,
            )).toList(),
          )).toList();
          isLoaded = true;
        } else {
          rounds = [];
          isLoaded = false;
        }

        topicNodes.add(_TopicNode(
          id: topic.id,
          name: topic.name,
          isCurrent: isCurrentTopic,
          rounds: rounds,
          roundCount: topic.roundCount,
          isLoaded: isLoaded,
        ));
      }

      // 当前话题排在最前
      topicNodes.sort((a, b) {
        if (a.isCurrent && !b.isCurrent) return -1;
        if (!a.isCurrent && b.isCurrent) return 1;
        return 0;
      });

      _assistants.add(_AssistantNode(
        id: assistantId,
        name: assistantInfo?.name ?? '未知助手',
        isCurrent: isCurrentAssistant,
        topics: topicNodes,
      ));
    }

    // 🔴 关键修复：如果当前话题不在索引中（新话题），手动添加
    if (!foundCurrentTopic && currentTopicId != null && _currentTopicRounds.isNotEmpty) {
      debugPrint('⚠️ [ContextSelector] 当前话题不在索引中，手动添加: $currentTopicId');

      final assistantId = currentAssistantId ?? 'unknown';
      final assistantName = widget.currentAssistantName ?? '当前助手';
      final topicName = widget.currentTopicName ?? '当前话题';

      // 查找或创建当前助手的节点
      final existingAssistant = _assistants.cast<_AssistantNode?>().firstWhere(
        (a) => a?.id == assistantId,
        orElse: () => null,
      );

      final currentTopicNode = _TopicNode(
        id: currentTopicId,
        name: topicName,
        isCurrent: true,
        rounds: _currentTopicRounds,
        roundCount: _currentTopicRounds.length,
        isLoaded: true,
      );

      if (existingAssistant != null) {
        // 添加到现有助手
        existingAssistant.topics.insert(0, currentTopicNode);
      } else {
        // 创建新助手节点
        _assistants.insert(0, _AssistantNode(
          id: assistantId,
          name: assistantName,
          isCurrent: true,
          topics: [currentTopicNode],
        ));
      }
    }

    // 当前助手排在最前
    _assistants.sort((a, b) {
      if (a.isCurrent && !b.isCurrent) return -1;
      if (!a.isCurrent && b.isCurrent) return 1;
      return a.name.compareTo(b.name);
    });

    _initDefaultExpansion();
    _initDefaultSelection();
    _hasLoadedTopics = true;

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyChange();
    });
  }

  /// 备用：仅用当前话题数据初始化
  void _initCurrentTopicOnly() {
    final assistantId = widget.currentAssistantId ?? 'unknown';
    final assistantName = widget.currentAssistantName ?? '当前助手';
    final topicId = widget.currentTopicId!;
    final topicName = widget.currentTopicName ?? '当前话题';

    _assistants.clear();
    _assistants.add(_AssistantNode(
      id: assistantId,
      name: assistantName,
      isCurrent: true,
      topics: [
        _TopicNode(
          id: topicId,
          name: topicName,
          isCurrent: true,
          rounds: _currentTopicRounds,
          roundCount: _currentTopicRounds.length,
          isLoaded: true,
        ),
      ],
    ));

    _initDefaultExpansion();
    _initDefaultSelection();

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyChange();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ContextSelectorWithStyles oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检测数据源是否变化
    // 注意：不检查 contextSnapshot，因为它是由本组件生成并返回给父组件的
    // 如果检查 contextSnapshot 变化，会导致用户选择后状态被立即重置（无限循环）
    final dataChanged = oldWidget.contextData != widget.contextData;
    final roundChanged = oldWidget.currentRoundIndex != widget.currentRoundIndex;
    final topicChanged = oldWidget.currentTopicId != widget.currentTopicId;

    if (dataChanged || topicChanged) {
      // 数据源变化：清空所有缓存，重新初始化
      _fullContentCache.clear();
      _selections.clear();
      _assistants.clear();
      _currentTopicRounds = [];

      debugPrint('🧹 [ContextSelector] 数据源变化，清空缓存 (topicId: ${widget.currentTopicId})');

      _parseContextData();
      _initFromIndexService();
      _initDefaultSelection();
      _initDefaultExpansion();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyChange();
      });
    } else if (roundChanged) {
      // 仅轮次变化：轻量级更新
      _parseContextData();
      _initDefaultSelection();
      _initDefaultExpansion();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyChange();
      });
    }
  }

  void _parseContextData() {
    _currentTopicRounds = [];

    if (widget.contextData != null && widget.contextData!['rounds'] != null) {
      _currentTopicRounds = _extractRoundsFromData(widget.contextData!);
    } else if (widget.contextSnapshot.isNotEmpty) {
      _currentTopicRounds = _extractRoundsFromMarkdown(widget.contextSnapshot);
    }
  }

  List<_RoundNode> _extractRoundsFromData(Map<String, dynamic> data) {
    final rounds = <_RoundNode>[];
    final roundsData = data['rounds'] as List<dynamic>? ?? [];

    for (var roundData in roundsData) {
      if (roundData is! Map<String, dynamic>) continue;

      final index = roundData['index'] as int? ?? rounds.length;
      final questionData = roundData['question'] as Map<String, dynamic>?;
      final repliesData = roundData['replies'] as List<dynamic>? ?? [];

      String question = '';
      if (questionData != null) {
        final blocks = questionData['blocks'] as List<dynamic>? ?? [];
        for (final block in blocks) {
          if (block is Map<String, dynamic> && block['type'] == 'main_text') {
            question += block['content'] as String? ?? '';
          }
        }
      }

      final replies = <_ReplyNode>[];
      for (var replyData in repliesData) {
        if (replyData is! Map<String, dynamic>) continue;

        final id = replyData['id'] as String? ?? 'reply_${index}_${replies.length}';
        final model = replyData['model'] as Map<String, dynamic>?;
        final modelName = model?['name'] as String? ?? 'Unknown';
        final useful = replyData['useful'] as bool? ?? false;

        final blocks = replyData['blocks'] as List<dynamic>? ?? [];
        String content = '';
        for (final block in blocks) {
          if (block is Map<String, dynamic> && block['type'] == 'main_text') {
            content += block['content'] as String? ?? '';
          }
        }

        replies.add(_ReplyNode(
          id: id,
          modelName: modelName,
          content: content,
          isMainline: useful,
          charCount: content.length,
        ));
      }

      rounds.add(_RoundNode(
        index: index,
        question: question,
        replies: replies,
      ));
    }

    return rounds;
  }

  List<_RoundNode> _extractRoundsFromMarkdown(String snapshot) {
    final rounds = <_RoundNode>[];
    final sections = snapshot.split('##').where((s) => s.trim().isNotEmpty).toList();

    String? currentQuestion;
    List<_ReplyNode> currentReplies = [];
    int roundIndex = 0;

    for (var section in sections) {
      final lines = section.trim().split('\n');
      final header = lines.first.trim();

      if (header.startsWith('用户问题')) {
        if (currentQuestion != null) {
          rounds.add(_RoundNode(
            index: roundIndex++,
            question: currentQuestion,
            replies: List.from(currentReplies),
          ));
          currentReplies.clear();
        }
        currentQuestion = lines.skip(1).join('\n').trim();
      } else if (header.startsWith('模型回复')) {
        final replyBlocks = section.split('###').where((s) => s.trim().isNotEmpty).skip(1);

        for (var block in replyBlocks) {
          final blockLines = block.trim().split('\n');
          if (blockLines.isEmpty) continue;

          final modelLine = blockLines.first.trim();
          final content = blockLines.skip(1).join('\n').trim();

          String modelName = modelLine.contains(':')
              ? modelLine.split(':').last.trim()
              : modelLine;

          currentReplies.add(_ReplyNode(
            id: 'reply_${roundIndex}_${currentReplies.length}',
            modelName: modelName,
            content: content,
            isMainline: false,
            charCount: content.length,
          ));
        }
      }
    }

    if (currentQuestion != null) {
      rounds.add(_RoundNode(
        index: roundIndex,
        question: currentQuestion,
        replies: currentReplies,
      ));
    }

    return rounds;
  }

  void _initDefaultSelection() {
    _selections.clear();

    final targetIndex = widget.currentRoundIndex;
    // 检查是否跳过选中问题（单击进入只选回复）
    final selectQuestion = widget.contextData?['selectQuestionByDefault'] ?? true;
    // 检查是否只选中指定索引的回复（单击进入只选当前 tab 显示的回复）
    final selectOnlyReplyIndex = widget.contextData?['selectOnlyReplyIndex'] as int?;

    for (final assistant in _assistants) {
      for (final topic in assistant.topics) {
        if (topic.isCurrent && topic.rounds.isNotEmpty) {
          final roundIdx = targetIndex ?? topic.rounds.length - 1;
          if (roundIdx < topic.rounds.length) {
            final round = topic.rounds[roundIdx];
            final roundKey = _getRoundKey(assistant.id, topic.id, round.index);

            // 根据 selectQuestion 标记决定是否选中问题
            if (selectQuestion && round.question.isNotEmpty) {
              _selections['$roundKey:q'] = true;
            }

            // 根据 selectOnlyReplyIndex 决定选中哪些回复
            if (selectOnlyReplyIndex != null) {
              // 只选中指定索引的回复
              if (selectOnlyReplyIndex < round.replies.length) {
                final reply = round.replies[selectOnlyReplyIndex];
                _selections['$roundKey:${reply.id}'] = true;
              }
            } else {
              // 选中所有回复
              for (var reply in round.replies) {
                _selections['$roundKey:${reply.id}'] = true;
              }
            }
          }
        }
      }
    }
  }

  void _initDefaultExpansion() {
    _expandedAssistants.clear();
    _expandedTopics.clear();
    _expandedRounds.clear();

    debugPrint('🔍 [_initDefaultExpansion] currentAssistantId: ${widget.currentAssistantId}, currentTopicId: ${widget.currentTopicId}');
    debugPrint('🔍 [_initDefaultExpansion] _assistants count: ${_assistants.length}');

    for (final assistant in _assistants) {
      debugPrint('  - Assistant: ${assistant.name} (${assistant.id}), isCurrent: ${assistant.isCurrent}');
      if (assistant.isCurrent) {
        _expandedAssistants.add(assistant.id);
        debugPrint('    ✅ 展开助手: ${assistant.name}');
        for (final topic in assistant.topics) {
          debugPrint('    - Topic: ${topic.name} (${topic.id}), isCurrent: ${topic.isCurrent}');
          if (topic.isCurrent) {
            _expandedTopics.add(_getTopicKey(assistant.id, topic.id));
            debugPrint('      ✅ 展开话题: ${topic.name}');
            final targetIndex = widget.currentRoundIndex ?? (topic.rounds.isNotEmpty ? topic.rounds.length - 1 : -1);
            if (targetIndex >= 0 && targetIndex < topic.rounds.length) {
              _expandedRounds.add(_getRoundKey(assistant.id, topic.id, targetIndex));
              debugPrint('        ✅ 展开轮次: $targetIndex');
            }
          }
        }
      }
    }

    debugPrint('🔍 [_initDefaultExpansion] 结果: expandedAssistants=${_expandedAssistants.length}, expandedTopics=${_expandedTopics.length}, expandedRounds=${_expandedRounds.length}');
  }

  String _getTopicKey(String assistantId, String topicId) => '$assistantId:$topicId';
  String _getRoundKey(String assistantId, String topicId, int roundIndex) => '$assistantId:$topicId:r$roundIndex';

  // ===== 选择操作 =====
  void _toggleRound(String assistantId, String topicId, _RoundNode round) {
    final roundKey = _getRoundKey(assistantId, topicId, round.index);
    final questionKey = '$roundKey:q';
    final isSelected = _selections[questionKey] == true;

    setState(() {
      if (isSelected) {
        _selections.remove(questionKey);
        for (var reply in round.replies) {
          _selections.remove('$roundKey:${reply.id}');
        }
      } else {
        if (round.question.isNotEmpty) {
          _selections[questionKey] = true;
        }
        for (var reply in round.replies) {
          _selections['$roundKey:${reply.id}'] = true;
        }
      }
    });
    _notifyChange();
  }

  void _toggleReply(String assistantId, String topicId, _RoundNode round, _ReplyNode reply) {
    final roundKey = _getRoundKey(assistantId, topicId, round.index);
    final replyKey = '$roundKey:${reply.id}';
    final isSelected = _selections[replyKey] == true;

    setState(() {
      if (isSelected) {
        _selections.remove(replyKey);
      } else {
        _selections[replyKey] = true;
        if (round.question.isNotEmpty) {
          _selections['$roundKey:q'] = true;
        }
      }
    });
    _notifyChange();
  }

  void _selectMainlineOnly() {
    _selections.clear();
    for (final assistant in _assistants) {
      for (final topic in assistant.topics) {
        for (final round in topic.rounds) {
          final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
          if (round.question.isNotEmpty) {
            _selections['$roundKey:q'] = true;
          }
          final mainlineReplies = round.replies.where((r) => r.isMainline).toList();
          if (mainlineReplies.isNotEmpty) {
            for (var reply in mainlineReplies) {
              _selections['$roundKey:${reply.id}'] = true;
            }
          } else if (round.replies.isNotEmpty) {
            _selections['$roundKey:${round.replies.first.id}'] = true;
          }
        }
      }
    }
    setState(() {});
    _notifyChange();
  }

  void _selectAll() {
    _selections.clear();
    for (final assistant in _assistants) {
      for (final topic in assistant.topics) {
        for (final round in topic.rounds) {
          final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
          if (round.question.isNotEmpty) {
            _selections['$roundKey:q'] = true;
          }
          for (var reply in round.replies) {
            _selections['$roundKey:${reply.id}'] = true;
          }
        }
      }
    }
    setState(() {});
    _notifyChange();
  }

  void _clearAll() {
    setState(() => _selections.clear());
    _notifyChange();
  }

  // ===== Context 组装 =====
  String _buildContextSnapshot() {
    final buffer = StringBuffer();

    for (final assistant in _assistants) {
      for (final topic in assistant.topics) {
        bool topicHasContent = false;
        final topicBuffer = StringBuffer();

        for (final round in topic.rounds) {
          final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
          final questionSelected = _selections['$roundKey:q'] == true;

          if (questionSelected && round.question.isNotEmpty) {
            topicBuffer.writeln('## 用户问题\n');
            topicBuffer.writeln(round.question);
            topicBuffer.writeln();
            topicHasContent = true;
          }

          final selectedReplies = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).toList();
          if (selectedReplies.isNotEmpty) {
            topicBuffer.writeln('## 模型回复\n');
            for (var reply in selectedReplies) {
              topicBuffer.writeln('### ${reply.modelName}\n');
              topicBuffer.writeln(reply.content);
              topicBuffer.writeln();
            }
            topicHasContent = true;
          }
        }

        if (topicHasContent) {
          if (!topic.isCurrent && buffer.isNotEmpty) {
            buffer.writeln('---\n');
            buffer.writeln('**[${assistant.name} / ${topic.name}]**\n');
          }
          buffer.write(topicBuffer);
        }
      }
    }

    return buffer.toString().trim();
  }

  String? _buildContextDataJson() {
    bool hasSelection = false;
    for (final key in _selections.keys) {
      if (_selections[key] == true) {
        hasSelection = true;
        break;
      }
    }
    if (!hasSelection) return null;

    final roundJsonParts = <String>[];
    int totalCharCount = 0;

    for (final assistant in _assistants) {
      for (final topic in assistant.topics) {
        for (final round in topic.rounds) {
          final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
          final questionSelected = _selections['$roundKey:q'] == true;
          final selectedReplies = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).toList();

          if (!questionSelected && selectedReplies.isEmpty) continue;

          String? questionPart;
          if (questionSelected && round.question.isNotEmpty) {
            final questionPreview = round.question.length > 50
                ? '${round.question.substring(0, 50)}...'
                : round.question;
            questionPart = ',"questionPreview":"${_escapeJson(questionPreview)}"';
            totalCharCount += round.question.length;
          }

          final replyJsonParts = <String>[];
          for (var reply in selectedReplies) {
            replyJsonParts.add('{"model":"${_escapeJson(reply.modelName)}","charCount":${reply.charCount}}');
            totalCharCount += reply.charCount;
          }

          final repliesJson = replyJsonParts.join(',');
          roundJsonParts.add('{"index":${round.index}${questionPart ?? ''},"replies":[$repliesJson]}');
        }
      }
    }

    if (roundJsonParts.isEmpty) return null;

    final roundsJson = roundJsonParts.join(',');
    return '{"type":"multi","rounds":[$roundsJson],"charCount":$totalCharCount}';
  }

  String _escapeJson(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  void _notifyChange() {
    widget.onContextChanged?.call(_buildContextSnapshot(), _buildContextDataJson());
  }

  Map<String, int> _getStats() {
    int questions = 0;
    int replies = 0;
    int chars = 0;
    int topics = 0;

    for (final assistant in _assistants) {
      for (final topic in assistant.topics) {
        bool topicHasSelection = false;
        for (final round in topic.rounds) {
          final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
          if (_selections['$roundKey:q'] == true) {
            questions++;
            chars += round.question.length;
            topicHasSelection = true;
          }
          for (var reply in round.replies) {
            if (_selections['$roundKey:${reply.id}'] == true) {
              replies++;
              chars += reply.charCount;
              topicHasSelection = true;
            }
          }
        }
        if (topicHasSelection) topics++;
      }
    }

    return {'questions': questions, 'replies': replies, 'chars': chars, 'topics': topics};
  }

  String _formatChars(int count) {
    if (count < 1000) return '$count';
    if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 10000).toStringAsFixed(1)}w';
  }

  // ===== 加载话题 =====
  Future<void> _loadTopics() async {
    if (_isLoadingTopics || widget.onLoadTopics == null) return;

    setState(() => _isLoadingTopics = true);

    try {
      final topics = await widget.onLoadTopics!(null);
      setState(() {
        _isLoadingTopics = false;
        _hasLoadedTopics = true;
      });

      _groupTopicsByAssistant(topics);
    } catch (e) {
      setState(() {
        _isLoadingTopics = false;
        _hasLoadedTopics = true;
      });
    }
  }

  void _groupTopicsByAssistant(List<TopicSummary> topics) {
    _assistants.clear();
    final grouped = <String, _AssistantNode>{};

    final currentAssistantId = widget.currentAssistantId;
    final currentTopicId = widget.currentTopicId;

    for (final topic in topics) {
      final assistantId = topic.assistantId ?? 'unknown';
      final assistantName = topic.assistantName ?? '未知助手';
      final isCurrentAssistant = assistantId == currentAssistantId;
      final isCurrentTopic = topic.id == currentTopicId;

      if (!grouped.containsKey(assistantId)) {
        grouped[assistantId] = _AssistantNode(
          id: assistantId,
          name: assistantName,
          isCurrent: isCurrentAssistant,
          topics: [],
        );
      }

      if (isCurrentTopic) {
        grouped[assistantId]!.topics.add(_TopicNode(
          id: topic.id,
          name: topic.name,
          isCurrent: true,
          rounds: _currentTopicRounds,
          roundCount: _currentTopicRounds.length,
          isLoaded: true,
        ));
      } else {
        grouped[assistantId]!.topics.add(_TopicNode(
          id: topic.id,
          name: topic.name,
          isCurrent: false,
          rounds: [],
          roundCount: topic.roundCount,
          isLoaded: false,
        ));
      }
    }

    final sortedAssistants = grouped.values.toList()
      ..sort((a, b) {
        if (a.isCurrent && !b.isCurrent) return -1;
        if (!a.isCurrent && b.isCurrent) return 1;
        return a.name.compareTo(b.name);
      });

    for (final assistant in sortedAssistants) {
      assistant.topics.sort((a, b) {
        if (a.isCurrent && !b.isCurrent) return -1;
        if (!a.isCurrent && b.isCurrent) return 1;
        return 0;
      });
    }

    _assistants.addAll(sortedAssistants);

    _initDefaultExpansion();
    _initDefaultSelection();
    _notifyChange();

    setState(() {});
  }

  /// 加载话题详情（优先使用索引服务）
  Future<void> _loadTopicDetail(String assistantId, _TopicNode topic) async {
    if (topic.isLoaded) return;
    if (_loadingTopicIds.contains(topic.id)) return;

    setState(() => _loadingTopicIds.add(topic.id));

    try {
      // 优先使用索引服务
      if (_indexService.isInitialized) {
        await _indexService.loadTopicRounds(topic.id);
        final indexTopic = _indexService.getTopic(topic.id);

        if (indexTopic != null && indexTopic.isRoundsLoaded && mounted) {
          final rounds = indexTopic.rounds.map((r) => _RoundNode(
            index: r.index,
            question: r.questionPreview,
            replies: r.replies.map((reply) => _ReplyNode(
              id: reply.id,
              modelName: reply.modelName,
              content: reply.contentPreview,
              isMainline: reply.isMainline,
              charCount: reply.charCount,
            )).toList(),
          )).toList();

          setState(() {
            topic.rounds.clear();
            topic.rounds.addAll(rounds);
            topic.isLoaded = true;
            _loadingTopicIds.remove(topic.id);
          });
          return;
        }
      }

      // 回退到传统方式
      if (widget.onLoadTopicDetail == null) {
        setState(() => _loadingTopicIds.remove(topic.id));
        return;
      }

      final detail = await widget.onLoadTopicDetail!(topic.id);
      if (detail != null && mounted) {
        final rounds = _extractRoundsFromData(detail);
        setState(() {
          topic.rounds.clear();
          topic.rounds.addAll(rounds);
          topic.isLoaded = true;
          _loadingTopicIds.remove(topic.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTopicIds.remove(topic.id));
      }
    }
  }

  /// 加载回复完整内容（按需）
  Future<String> _loadReplyFullContent(String replyId) async {
    if (_indexService.isInitialized) {
      return _indexService.getReplyFullContent(replyId);
    }
    // 没有索引服务，返回空（UI 应该已经有预览数据）
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(stats, primary),
          Expanded(
            child: _buildTreeList(primary),
          ),
          if (!widget.readOnly) _buildFooter(stats, primary),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, int> stats, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                widget.readOnly ? '讨论内容' : '上下文',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
              // 只读模式下隐藏操作按钮
              if (!widget.readOnly) ...[
                const SizedBox(width: 16),
                _ActionChip(label: '推荐', icon: Icons.auto_awesome, onTap: _selectMainlineOnly),
                const SizedBox(width: 6),
                _ActionChip(label: '全选', icon: Icons.done_all, onTap: _selectAll),
                const SizedBox(width: 6),
                _ActionChip(label: '清空', icon: Icons.clear_all, onTap: _clearAll),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatChars(stats['chars']!),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreeList(Color primary) {
    if (_isLoadingTopics && _assistants.length <= 1) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            ),
            const SizedBox(height: 12),
            Text('加载话题列表...', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (_assistants.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('暂无话题', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _assistants.length,
      itemBuilder: (context, index) {
        return _buildAssistantNode(_assistants[index], primary);
      },
    );
  }

  Widget _buildAssistantNode(_AssistantNode assistant, Color primary) {
    return _buildSemanticAssistant(assistant, primary);
  }

  // ========================================
  // 风格一：语义化图标（简洁版 + 统计）
  // 设计原则：
  // 1. Checkbox 在行首
  // 2. 用缩进表示层级
  // 3. 保留统计数字帮助用户了解选中情况
  // ========================================

  /// 固定缩进量
  static const double _indentUnit = 20.0;

  Widget _buildSemanticAssistant(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);
    final stats = _countAssistantStats(assistant);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 助手行
          InkWell(
            onTap: () => _toggleAssistantExpand(assistant.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  // 展开箭头
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  // 助手图标
                  Icon(Icons.person_outline, size: 18, color: const Color(0xFF5C6BC0)),
                  const SizedBox(width: 8),
                  // 名称
                  Flexible(
                    child: Text(
                      assistant.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 当前标记（紧跟标题）
                  if (assistant.isCurrent) ...[
                    const SizedBox(width: 8),
                    _buildInlineTag('当前', _currentColor),
                  ],
                  // 选中状态标签（✓ + 字符数 / 仅字符数）
                  if (stats.selected > 0) ...[
                    const SizedBox(width: 8),
                    _buildSelectionLabel(stats),
                  ],
                  // 弹性空间
                  const Spacer(),
                ],
              ),
            ),
          ),
          // 展开的话题列表
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: _indentUnit, top: 4),
              child: Column(
                children: assistant.topics.map((t) => _buildSemanticTopic(assistant, t, primary)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSemanticTopic(_AssistantNode assistant, _TopicNode topic, Color primary) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);
    final stats = _countTopicStats(assistant, topic);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 话题行
          InkWell(
            onTap: () async {
              if (!topic.isLoaded && !isLoading) await _loadTopicDetail(assistant.id, topic);
              _toggleTopicExpand(topicKey);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  // 展开箭头
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 6),
                  // 话题图标
                  Icon(Icons.chat_bubble_outline, size: 15, color: const Color(0xFF7E57C2)),
                  const SizedBox(width: 8),
                  // 名称
                  Flexible(
                    child: Text(
                      topic.name,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 当前标记（紧跟标题）
                  if (topic.isCurrent) ...[
                    const SizedBox(width: 8),
                    _buildInlineTag('当前', _currentColor),
                  ],
                  // 选中状态标签（✓ + 字符数 / 仅字符数）
                  if (stats.selected > 0) ...[
                    const SizedBox(width: 8),
                    _buildSelectionLabel(stats, small: true),
                  ],
                  // 弹性空间
                  const Spacer(),
                  // 加载指示器
                  if (isLoading)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
          ),
          // 展开的轮次列表 - 简化容器（移除背景色避免阴影感）
          if (isExpanded && topic.isLoaded)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Column(
                children: topic.rounds.map((r) => _buildSemanticRound(assistant, topic, r, primary)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSemanticRound(_AssistantNode assistant, _TopicNode topic, _RoundNode round, Color primary) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final isExpanded = _expandedRounds.contains(roundKey);
    final isQuestionSelected = _selections['$roundKey:q'] == true;
    final selectedReplyCount = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).length;
    final isCurrent = topic.isCurrent && round.index == widget.currentRoundIndex;

    // 整体卡片设计：问题和回复在同一个容器里
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 问题行（卡片头部）
          InkWell(
            onTap: () => _toggleRoundExpand(roundKey),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(8),
              bottom: isExpanded ? Radius.zero : const Radius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Checkbox（只读模式下隐藏）
                  if (!widget.readOnly) ...[
                    _buildCheckbox(
                      isQuestionSelected,
                      () => _toggleRound(assistant.id, topic.id, round),
                      small: true,
                    ),
                    const SizedBox(width: 10),
                  ],
                  // 问题图标
                  Icon(Icons.help_outline, size: 14, color: const Color(0xFF42A5F5)),
                  const SizedBox(width: 4),
                  // Q 编号
                  Text(
                    'Q${round.index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 问题内容
                  Expanded(
                    child: Text(
                      round.question,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  // 当前标记
                  if (isCurrent) ...[
                    _buildInlineTag('当前', _currentColor),
                    const SizedBox(width: 8),
                  ],
                  // 回复选中统计
                  if (round.replies.isNotEmpty) ...[
                    Text(
                      '$selectedReplyCount/${round.replies.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: selectedReplyCount > 0 ? _selectedColor : Colors.grey[400],
                        fontWeight: selectedReplyCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // 展开箭头
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          // 展开时显示回复列表（在同一卡片内）
          if (isExpanded && round.replies.isNotEmpty) ...[
            // 分隔线
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            // 回复区域（淡色背景 + 左侧缩进，更紧凑）
            Container(
              padding: const EdgeInsets.only(left: 24, right: 6, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Column(
                children: round.replies.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reply = entry.value;
                  final isLast = index == round.replies.length - 1;
                  return _buildSemanticReply(assistant, topic, round, reply, isLast, primary);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSemanticReply(_AssistantNode assistant, _TopicNode topic, _RoundNode round, _ReplyNode reply, bool isLast, Color primary) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final replyKey = '$roundKey:${reply.id}';
    final isSelected = _selections[replyKey] == true;
    final isContentExpanded = _expandedReplies.contains(replyKey);

    return Column(
      children: [
        // 点击整行 = 选中（编辑模式）/ 展开（只读模式）
        InkWell(
          onTap: widget.readOnly
              ? () => _toggleReplyExpand(replyKey)
              : () => _toggleReply(assistant.id, topic.id, round, reply),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            decoration: BoxDecoration(
              color: reply.isMainline ? _mainlineColor.withAlpha(12) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Checkbox（只读模式下隐藏）
                    if (!widget.readOnly) ...[
                      _buildCheckbox(
                        isSelected,
                        () => _toggleReply(assistant.id, topic.id, round, reply),
                        small: true,
                        subtle: true,
                      ),
                      const SizedBox(width: 6),
                    ],
                    // 回复图标
                    Icon(
                      Icons.lightbulb_outline,
                      size: 12,
                      color: reply.isMainline ? _mainlineColor : const Color(0xFF26A69A),
                    ),
                    const SizedBox(width: 4),
                    // 模型名称
                    Expanded(
                      child: Text(
                        reply.modelName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 主线标记
                    if (reply.isMainline) ...[
                      Icon(Icons.star, size: 11, color: _mainlineColor),
                      const SizedBox(width: 4),
                    ],
                    // 字数
                    Text(
                      _formatChars(reply.charCount),
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 2),
                    // 展开箭头（独立点击区域）
                    GestureDetector(
                      onTap: () => _toggleReplyExpand(replyKey),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          isContentExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
                // 内容预览
                _buildReplyContent(reply, isContentExpanded, onCollapse: () => _toggleReplyExpand(replyKey)),
              ],
            ),
          ),
        ),
        // 分隔线（最后一个不显示，颜色更深）
        if (!isLast)
          Divider(height: 1, thickness: 1, color: Colors.grey[300], indent: 28),
      ],
    );
  }

  /// 内联标签（当前）
  Widget _buildInlineTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ========================================
  // 共用的辅助组件
  // ========================================

  Widget _buildCheckbox(bool isSelected, VoidCallback onTap, {bool small = false, bool subtle = false}) {
    final size = small ? 16.0 : 18.0;
    // subtle 模式：未选中时更淡，降低视觉重量
    final borderColor = isSelected
        ? _selectedColor
        : (subtle ? Colors.grey[300]! : Colors.grey[400]!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: subtle && !isSelected ? 1.0 : 1.5),
        ),
        child: isSelected ? Icon(Icons.check, size: size - 4, color: Colors.white) : null,
      ),
    );
  }

  Widget _buildReplyContent(_ReplyNode reply, bool isExpanded, {VoidCallback? onCollapse}) {
    // 优先使用缓存的完整内容，其次使用预览内容
    final cachedContent = _fullContentCache[reply.id];
    final displayContent = cachedContent ?? reply.content;

    // 清理内容：跳过开头的空行和标题行
    final cleanedContent = _cleanReplyContent(displayContent);
    // 获取前2行有效内容（跳过空行）
    final previewContent = _getPreviewLines(cleanedContent, 2);

    if (!isExpanded) {
      return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 2),
        child: Text(previewContent, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.3)),
      );
    }

    // 展开状态：显示完整内容或加载中
    final isLoading = _loadingReplyIds.contains(reply.id);

    return GestureDetector(
      onDoubleTap: onCollapse,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: isLoading && cachedContent == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      Text('加载中...', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: SelectableText(cleanedContent, style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5)),
              ),
      ),
    );
  }

  /// 清理回复内容：跳过开头的空行和无意义标题
  String _cleanReplyContent(String content) {
    final lines = content.split('\n');
    int startIndex = 0;

    // 跳过开头的空行和标题行
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();
      if (line.isEmpty ||
          RegExp(r'^#{1,3}\s*(回答|回复|Answer|Response|答案)[：:：]?\s*$', caseSensitive: false).hasMatch(line)) {
        startIndex = i + 1;
      } else {
        break;
      }
    }

    if (startIndex >= lines.length) return content.trim();
    return lines.sublist(startIndex).join('\n').trim();
  }

  /// 获取预览行：跳过空行，取前 N 行有效内容
  String _getPreviewLines(String content, int lineCount) {
    final lines = content.split('\n');
    final validLines = <String>[];

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        validLines.add(line);
        if (validLines.length >= lineCount) break;
      }
    }

    return validLines.join('\n');
  }

  // ========================================
  // 辅助方法：计算选中数量和字符数
  // ========================================

  /// 计算助手下的选中统计 (选中数, 总数, 选中字符数)
  ({int selected, int total, int chars}) _countAssistantStats(_AssistantNode assistant) {
    int selected = 0;
    int total = 0;
    int chars = 0;
    for (final topic in assistant.topics) {
      final stats = _countTopicStats(assistant, topic);
      selected += stats.selected;
      total += stats.total;
      chars += stats.chars;
    }
    return (selected: selected, total: total, chars: chars);
  }

  /// 计算话题下的选中统计 (选中数, 总数, 选中字符数)
  ({int selected, int total, int chars}) _countTopicStats(_AssistantNode assistant, _TopicNode topic) {
    int selected = 0;
    int total = 0;
    int chars = 0;
    for (final round in topic.rounds) {
      final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
      // 问题
      if (round.question.isNotEmpty) {
        total++;
        if (_selections['$roundKey:q'] == true) {
          selected++;
          chars += round.question.length;
        }
      }
      // 回复
      for (var reply in round.replies) {
        total++;
        if (_selections['$roundKey:${reply.id}'] == true) {
          selected++;
          chars += reply.charCount;
        }
      }
    }
    return (selected: selected, total: total, chars: chars);
  }

  /// 构建选中状态标签（全选 ✓ / 字符数）
  Widget _buildSelectionLabel(({int selected, int total, int chars}) stats, {bool small = false}) {
    if (stats.selected == 0) return const SizedBox.shrink();

    final isFullySelected = stats.selected == stats.total && stats.total > 0;
    final fontSize = small ? 10.0 : 11.0;

    if (isFullySelected) {
      // 全选：显示 ✓ 图标 + 字符数
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: fontSize + 2, color: _selectedColor),
          const SizedBox(width: 3),
          Text(
            _formatChars(stats.chars),
            style: TextStyle(fontSize: fontSize, color: _selectedColor, fontWeight: FontWeight.w500),
          ),
        ],
      );
    } else {
      // 部分选：只显示字符数
      return Text(
        _formatChars(stats.chars),
        style: TextStyle(fontSize: fontSize, color: _selectedColor, fontWeight: FontWeight.w500),
      );
    }
  }

  // ========================================
  // 辅助方法：展开/折叠操作
  // ========================================

  void _toggleAssistantExpand(String id) {
    setState(() {
      if (_expandedAssistants.contains(id)) {
        _expandedAssistants.remove(id);
      } else {
        _expandedAssistants.add(id);
      }
    });
  }

  void _toggleTopicExpand(String key) {
    setState(() {
      if (_expandedTopics.contains(key)) {
        _expandedTopics.remove(key);
      } else {
        _expandedTopics.add(key);
      }
    });
  }

  void _toggleRoundExpand(String key) {
    setState(() {
      if (_expandedRounds.contains(key)) {
        _expandedRounds.remove(key);
      } else {
        _expandedRounds.add(key);
      }
    });
  }

  void _toggleReplyExpand(String key) {
    final isExpanding = !_expandedReplies.contains(key);

    setState(() {
      if (isExpanding) {
        _expandedReplies.add(key);
      } else {
        _expandedReplies.remove(key);
      }
    });

    // 展开时，按需加载完整内容
    if (isExpanding) {
      _loadFullContentIfNeeded(key);
    }
  }

  /// 按需加载回复的完整内容
  Future<void> _loadFullContentIfNeeded(String replyKey) async {
    // 解析 key 获取 replyId（格式: assistantId:topicId:rN:replyId）
    final parts = replyKey.split(':');
    if (parts.length < 4) return;
    final replyId = parts.last;

    // 已缓存或正在加载，跳过
    if (_fullContentCache.containsKey(replyId)) return;
    if (_loadingReplyIds.contains(replyId)) return;

    setState(() => _loadingReplyIds.add(replyId));

    try {
      final fullContent = await _loadReplyFullContent(replyId);
      if (fullContent.isNotEmpty && mounted) {
        setState(() {
          _fullContentCache[replyId] = fullContent;
          _loadingReplyIds.remove(replyId);
        });
      } else {
        setState(() => _loadingReplyIds.remove(replyId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingReplyIds.remove(replyId));
      }
    }
  }

  Widget _buildFooter(Map<String, int> stats, Color primary) {
    final hasSelection = stats['questions']! > 0 || stats['replies']! > 0;
    final topicCount = stats['topics'] ?? 0;

    String statusText;
    if (!hasSelection) {
      statusText = '未选择';
    } else if (topicCount > 1) {
      statusText = '$topicCount话题 · ${stats['questions']}问 · ${stats['replies']}回复';
    } else {
      statusText = '${stats['questions']}问 + ${stats['replies']}回复';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Icon(
            hasSelection ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: hasSelection ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              color: hasSelection ? Colors.grey[700] : Colors.grey[500],
              fontWeight: hasSelection ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (widget.onClear != null)
            TextButton.icon(
              onPressed: widget.onClear,
              icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
              label: Text('清除', style: TextStyle(fontSize: 12, color: Colors.red[400])),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

// ============ 辅助组件 ============

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ 数据模型 ============

class _AssistantNode {
  final String id;
  final String name;
  final bool isCurrent;
  final List<_TopicNode> topics;

  _AssistantNode({
    required this.id,
    required this.name,
    required this.isCurrent,
    required this.topics,
  });
}

class _TopicNode {
  final String id;
  final String name;
  final bool isCurrent;
  final List<_RoundNode> rounds;
  final int roundCount;
  bool isLoaded;

  _TopicNode({
    required this.id,
    required this.name,
    required this.isCurrent,
    required this.rounds,
    this.roundCount = 0,
    this.isLoaded = true,
  });
}

class _RoundNode {
  final int index;
  final String question;
  final List<_ReplyNode> replies;

  _RoundNode({
    required this.index,
    required this.question,
    required this.replies,
  });
}

class _ReplyNode {
  final String id;
  final String modelName;
  final String content;
  final bool isMainline;
  final int charCount;

  _ReplyNode({
    required this.id,
    required this.modelName,
    required this.content,
    required this.isMainline,
    required this.charCount,
  });
}

// ============ 辅助函数 ============
