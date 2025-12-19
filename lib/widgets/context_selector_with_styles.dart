import 'package:flutter/material.dart';
import 'context_selector.dart' show TopicSummary;

/// UI 风格枚举
enum ContextStyleVariant {
  semantic,    // 语义化图标（有边框卡片）
  textOnly,    // 纯文字标签
  compact,     // 简约语义（综合版：语义图标 + 极简布局）
}

/// 风格描述
const _styleNames = {
  ContextStyleVariant.semantic: '语义图标',
  ContextStyleVariant.textOnly: '纯文字',
  ContextStyleVariant.compact: '简约语义',
};

/// Context 选择器 - 混合风格（卡片质感 + 极简连接线 + 层级颜色）
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
  final Future<List<TopicSummary>> Function(String? assistantId)? onLoadTopics;
  final Future<Map<String, dynamic>?> Function(String topicId)? onLoadTopicDetail;

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

/// 层级灰度（用于边框和图标，不用于背景）
const _levelGrays = [
  Color(0xFF616161), // L0 助手层
  Color(0xFF757575), // L1 话题层
  Color(0xFF9E9E9E), // L2 轮次层
  Color(0xFFBDBDBD), // L3 回复层
];

class _ContextSelectorWithStylesState extends State<ContextSelectorWithStyles> {

  // ===== UI 风格 =====
  ContextStyleVariant _currentStyle = ContextStyleVariant.semantic;

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
  List<TopicSummary>? _availableTopics;
  final Set<String> _loadingTopicIds = {};

  final ScrollController _scrollController = ScrollController();

  // 暂存当前话题的轮次数据
  List<_RoundNode> _currentTopicRounds = [];

  @override
  void initState() {
    super.initState();
    _parseContextData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onLoadTopics != null) {
        _loadTopics();
      }
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
    if (oldWidget.contextData != widget.contextData ||
        oldWidget.currentRoundIndex != widget.currentRoundIndex) {
      _parseContextData();
      _initDefaultSelection();
      _initDefaultExpansion();
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

    for (final assistant in _assistants) {
      for (final topic in assistant.topics) {
        if (topic.isCurrent && topic.rounds.isNotEmpty) {
          final roundIdx = targetIndex ?? topic.rounds.length - 1;
          if (roundIdx < topic.rounds.length) {
            final round = topic.rounds[roundIdx];
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
    }
  }

  void _initDefaultExpansion() {
    _expandedAssistants.clear();
    _expandedTopics.clear();
    _expandedRounds.clear();

    for (final assistant in _assistants) {
      if (assistant.isCurrent) {
        _expandedAssistants.add(assistant.id);
        for (final topic in assistant.topics) {
          if (topic.isCurrent) {
            _expandedTopics.add(_getTopicKey(assistant.id, topic.id));
            final targetIndex = widget.currentRoundIndex ?? (topic.rounds.isNotEmpty ? topic.rounds.length - 1 : -1);
            if (targetIndex >= 0 && targetIndex < topic.rounds.length) {
              _expandedRounds.add(_getRoundKey(assistant.id, topic.id, targetIndex));
            }
          }
        }
      }
    }
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
        _availableTopics = topics;
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

  Future<void> _loadTopicDetail(String assistantId, _TopicNode topic) async {
    if (topic.isLoaded || widget.onLoadTopicDetail == null) return;
    if (_loadingTopicIds.contains(topic.id)) return;

    setState(() => _loadingTopicIds.add(topic.id));

    try {
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
      setState(() => _loadingTopicIds.remove(topic.id));
    }
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
          _buildFooter(stats, primary),
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
                '上下文',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
              const SizedBox(width: 16),
              _ActionChip(label: '推荐', icon: Icons.auto_awesome, onTap: _selectMainlineOnly),
              const SizedBox(width: 6),
              _ActionChip(label: '全选', icon: Icons.done_all, onTap: _selectAll),
              const SizedBox(width: 6),
              _ActionChip(label: '清空', icon: Icons.clear_all, onTap: _clearAll),
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
          // 风格切换按钮行
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ContextStyleVariant.values.map((style) {
                final isSelected = _currentStyle == style;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _currentStyle = style),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? primary.withAlpha(20) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _styleNames[style]!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? primary : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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
    switch (_currentStyle) {
      case ContextStyleVariant.semantic:
        return _buildSemanticAssistant(assistant, primary);
      case ContextStyleVariant.textOnly:
        return _buildTextOnlyAssistant(assistant, primary);
      case ContextStyleVariant.compact:
        return _buildCompactAssistant(assistant, primary);
    }
  }

  // ========================================
  // 风格一：语义化图标
  // 层级设计：助手(L0) > 话题(L1) > 轮次(L2) > 回复(L3)
  // 文字大小：15 > 14 > 12 > 11
  // 间距递减：10 > 8 > 6 > 4
  // ========================================

  Widget _buildSemanticAssistant(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);
    int selectedCount = _countAssistantSelections(assistant);
    final hasSelection = selectedCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _toggleAssistantExpand(assistant.id),
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      // 选中竖条
                      if (hasSelection)
                        Container(
                          width: 3,
                          height: 28,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 20, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Icon(Icons.person, size: 20, color: const Color(0xFF5C6BC0)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(assistant.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]))),
                      if (hasSelection) _buildSelectionBadge(selectedCount),
                      Text('${assistant.topics.length} 话题', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                ),
                if (assistant.isCurrent) _buildCornerTag('当前', _currentColor),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Column(children: assistant.topics.map((t) => _buildSemanticTopic(assistant, t, primary)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildSemanticTopic(_AssistantNode assistant, _TopicNode topic, Color primary) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);
    int selectedCount = _countTopicSelections(assistant, topic);
    final hasSelection = selectedCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () async {
              if (!topic.isLoaded && !isLoading) await _loadTopicDetail(assistant.id, topic);
              _toggleTopicExpand(topicKey);
            },
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      // 选中竖条
                      if (hasSelection)
                        Container(
                          width: 3,
                          height: 22,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Icon(Icons.chat_bubble_outline, size: 17, color: const Color(0xFF7E57C2)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(topic.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (hasSelection) _buildSelectionBadge(selectedCount, small: true),
                      if (isLoading)
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey[400]))
                      else ...[
                        Text('${topic.isLoaded ? topic.rounds.length : topic.roundCount} 轮', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                        const SizedBox(width: 4),
                        Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: Colors.grey[400]),
                      ],
                    ],
                  ),
                ),
                if (topic.isCurrent) _buildCornerTag('当前', _currentColor),
              ],
            ),
          ),
          if (isExpanded && topic.isLoaded)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Column(children: topic.rounds.map((r) => _buildSemanticRound(assistant, topic, r, primary)).toList()),
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
    final hasSelection = isQuestionSelected || selectedReplyCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 轮次头部（问题行）
          InkWell(
            onTap: () => _toggleRoundExpand(roundKey),
            borderRadius: BorderRadius.vertical(top: const Radius.circular(8), bottom: isExpanded ? Radius.zero : const Radius.circular(8)),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      // 左侧选中竖条（只在选中时显示）
                      if (hasSelection)
                        Container(
                          width: 3,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      // 蓝色问题标识条
                      Container(
                        width: 3,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      _buildCheckbox(isQuestionSelected, () => _toggleRound(assistant.id, topic.id, round), small: true),
                      const SizedBox(width: 8),
                      Icon(Icons.help_outline, size: 14, color: const Color(0xFF42A5F5)),
                      const SizedBox(width: 6),
                      Text('Q${round.index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(width: 10),
                      Expanded(child: Text(round.question, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                      if (selectedReplyCount > 0) _buildRatioTag('$selectedReplyCount/${round.replies.length}'),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
                if (isCurrent) _buildCornerTag('当前', _currentColor),
              ],
            ),
          ),
          // 分隔线 + 回复列表
          if (isExpanded) ...[
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Column(
                children: round.replies.asMap().entries.map((e) {
                  final isLast = e.key == round.replies.length - 1;
                  return _buildSemanticReply(assistant, topic, round, e.value, isLast, primary);
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
        InkWell(
          onTap: () => _toggleReplyExpand(replyKey),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: reply.isMainline ? _mainlineColor.withAlpha(60) : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 左侧选中竖条
                    if (isSelected)
                      Container(
                        width: 2,
                        height: 16,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    _buildCheckbox(isSelected, () => _toggleReply(assistant.id, topic.id, round, reply), small: true),
                    const SizedBox(width: 6),
                    Icon(Icons.lightbulb_outline, size: 12, color: reply.isMainline ? _mainlineColor : const Color(0xFF26A69A)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(reply.modelName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                    if (reply.isMainline) Text('★', style: TextStyle(fontSize: 10, color: _mainlineColor)),
                    const SizedBox(width: 4),
                    Text(_formatChars(reply.charCount), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    const SizedBox(width: 4),
                    Icon(isContentExpanded ? Icons.expand_less : Icons.expand_more, size: 14, color: Colors.grey[400]),
                  ],
                ),
                _buildReplyContent(reply, isContentExpanded, onCollapse: () => _toggleReplyExpand(replyKey)),
              ],
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 6),
      ],
    );
  }

  /// 右上角标签
  Widget _buildCornerTag(String text, Color color) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(color: color.withAlpha(60), width: 0.5),
        ),
        child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ========================================
  // 风格二：纯文字标签
  // ========================================

  Widget _buildTextOnlyAssistant(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);
    int selectedCount = _countAssistantSelections(assistant);
    final hasSelection = selectedCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _toggleAssistantExpand(assistant.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hasSelection ? _selectedColor.withAlpha(10) : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: hasSelection ? Border.all(color: _selectedColor.withAlpha(60), width: 1.5) : null,
              ),
              child: Row(
                children: [
                  if (hasSelection) _buildSelectionBar(3, 24),
                  Text(isExpanded ? '▼' : '▶', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  const SizedBox(width: 10),
                  Expanded(child: Text(assistant.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]))),
                  if (assistant.isCurrent) _buildCurrentTag(),
                  if (hasSelection) _buildSelectionBadge(selectedCount),
                  Text('${assistant.topics.length}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(children: assistant.topics.asMap().entries.map((e) => _buildTextOnlyTopic(assistant, e.value, e.key == assistant.topics.length - 1, primary)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildTextOnlyTopic(_AssistantNode assistant, _TopicNode topic, bool isLast, Color primary) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);
    int selectedCount = _countTopicSelections(assistant, topic);
    final hasSelection = selectedCount > 0;

    return Container(
      margin: EdgeInsets.only(top: 4, bottom: isLast ? 4 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () async {
              if (!topic.isLoaded && !isLoading) await _loadTopicDetail(assistant.id, topic);
              _toggleTopicExpand(topicKey);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: hasSelection ? _selectedColor.withAlpha(8) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: hasSelection ? Border.all(color: _selectedColor.withAlpha(50), width: 1) : Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  if (hasSelection) _buildSelectionBar(2, 20),
                  Text(isExpanded ? '▼' : '▶', style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                  const SizedBox(width: 8),
                  Expanded(child: Text(topic.name, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (topic.isCurrent) _buildCurrentTag(small: true),
                  if (hasSelection) _buildSelectionBadge(selectedCount, small: true),
                  if (isLoading) SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey[400])),
                ],
              ),
            ),
          ),
          if (isExpanded && topic.isLoaded)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(children: topic.rounds.asMap().entries.map((e) => _buildTextOnlyRound(assistant, topic, e.value, e.key == topic.rounds.length - 1, primary)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildTextOnlyRound(_AssistantNode assistant, _TopicNode topic, _RoundNode round, bool isLast, Color primary) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final isExpanded = _expandedRounds.contains(roundKey);
    final isQuestionSelected = _selections['$roundKey:q'] == true;
    final selectedReplyCount = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).length;
    final isCurrent = topic.isCurrent && round.index == widget.currentRoundIndex;
    final hasSelection = isQuestionSelected || selectedReplyCount > 0;

    return Container(
      margin: EdgeInsets.only(top: 4, bottom: isLast ? 4 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _toggleRoundExpand(roundKey),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: hasSelection ? _selectedColor.withAlpha(6) : Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: hasSelection ? Border.all(color: _selectedColor.withAlpha(40)) : null,
              ),
              child: Row(
                children: [
                  if (hasSelection) _buildSelectionBar(2, 16),
                  _buildCheckbox(isQuestionSelected, () => _toggleRound(assistant.id, topic.id, round), small: true),
                  const SizedBox(width: 8),
                  Text('Q${round.index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  Expanded(child: Text(round.question, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                  if (isCurrent) _buildCurrentTag(small: true),
                  if (selectedReplyCount > 0) _buildRatioTag('$selectedReplyCount/${round.replies.length}'),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(children: round.replies.asMap().entries.map((e) => _buildTextOnlyReply(assistant, topic, round, e.value, e.key == round.replies.length - 1, primary)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildTextOnlyReply(_AssistantNode assistant, _TopicNode topic, _RoundNode round, _ReplyNode reply, bool isLast, Color primary) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final replyKey = '$roundKey:${reply.id}';
    final isSelected = _selections[replyKey] == true;
    final isContentExpanded = _expandedReplies.contains(replyKey);

    return Container(
      margin: EdgeInsets.only(top: 3, bottom: isLast ? 3 : 0),
      child: InkWell(
        onTap: () => _toggleReplyExpand(replyKey),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? _selectedColor.withAlpha(8) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isSelected ? _selectedColor.withAlpha(50) : reply.isMainline ? _mainlineColor.withAlpha(60) : Colors.grey[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelected) _buildSelectionBar(2, 14),
                  _buildCheckbox(isSelected, () => _toggleReply(assistant.id, topic.id, round, reply), small: true),
                  const SizedBox(width: 6),
                  Expanded(child: Text(reply.modelName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]))),
                  if (reply.isMainline) _buildMainlineTag(),
                  Text(_formatChars(reply.charCount), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  const SizedBox(width: 4),
                  Icon(isContentExpanded ? Icons.expand_less : Icons.expand_more, size: 14, color: Colors.grey[400]),
                ],
              ),
              _buildReplyContent(reply, isContentExpanded, onCollapse: () => _toggleReplyExpand(replyKey)),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // 风格三：简约语义（综合版）
  // 特点：语义图标 + 极简布局 + 无边框卡片
  // ========================================

  Widget _buildCompactAssistant(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);
    int selectedCount = _countAssistantSelections(assistant);
    final hasSelection = selectedCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(left: hasSelection ? BorderSide(color: _selectedColor, width: 3) : BorderSide.none),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _toggleAssistantExpand(assistant.id),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: EdgeInsets.fromLTRB(hasSelection ? 9 : 12, 10, 12, 10),
              child: Row(
                children: [
                  // 语义图标：人物代表助手
                  Icon(Icons.person, size: 18, color: const Color(0xFF5C6BC0)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(assistant.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]))),
                  if (assistant.isCurrent) _buildCurrentTag(small: true),
                  if (hasSelection) _buildCompactBadge(selectedCount),
                  Text('${assistant.topics.length}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  const SizedBox(width: 6),
                  Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 18, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(children: assistant.topics.asMap().entries.map((e) => _buildCompactTopic(assistant, e.value, e.key == assistant.topics.length - 1, primary)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactTopic(_AssistantNode assistant, _TopicNode topic, bool isLast, Color primary) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);
    int selectedCount = _countTopicSelections(assistant, topic);
    final hasSelection = selectedCount > 0;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 4 : 2),
      decoration: BoxDecoration(
        border: Border(left: hasSelection ? BorderSide(color: _selectedColor.withAlpha(150), width: 2) : BorderSide.none),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () async {
              if (!topic.isLoaded && !isLoading) await _loadTopicDetail(assistant.id, topic);
              _toggleTopicExpand(topicKey);
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.fromLTRB(hasSelection ? 10 : 12, 7, 10, 7),
              child: Row(
                children: [
                  // 语义图标：对话气泡代表话题
                  Icon(Icons.chat_bubble_outline, size: 15, color: const Color(0xFF7E57C2)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(topic.name, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (topic.isCurrent) _buildCurrentTag(small: true),
                  if (hasSelection) _buildCompactBadge(selectedCount),
                  if (isLoading)
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey[400]))
                  else ...[
                    Text('${topic.isLoaded ? topic.rounds.length : topic.roundCount}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    const SizedBox(width: 4),
                    Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: Colors.grey[400]),
                  ],
                ],
              ),
            ),
          ),
          if (isExpanded && topic.isLoaded)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(children: topic.rounds.asMap().entries.map((e) => _buildCompactRound(assistant, topic, e.value, e.key == topic.rounds.length - 1, primary)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactRound(_AssistantNode assistant, _TopicNode topic, _RoundNode round, bool isLast, Color primary) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final isExpanded = _expandedRounds.contains(roundKey);
    final isQuestionSelected = _selections['$roundKey:q'] == true;
    final selectedReplyCount = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).length;
    final isCurrent = topic.isCurrent && round.index == widget.currentRoundIndex;
    final hasSelection = isQuestionSelected || selectedReplyCount > 0;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 4 : 2),
      decoration: BoxDecoration(
        color: hasSelection ? _selectedColor.withAlpha(6) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _toggleRoundExpand(roundKey),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _buildCheckbox(isQuestionSelected, () => _toggleRound(assistant.id, topic.id, round), small: true),
                  const SizedBox(width: 8),
                  // 语义图标：问号代表问题
                  Icon(Icons.help_outline, size: 14, color: const Color(0xFF42A5F5)),
                  const SizedBox(width: 6),
                  Text('Q${round.index + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: hasSelection ? _selectedColor : Colors.grey[600])),
                  const SizedBox(width: 8),
                  Expanded(child: Text(round.question, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                  if (isCurrent) _buildCurrentTag(small: true),
                  if (selectedReplyCount > 0) Text('$selectedReplyCount/${round.replies.length}', style: TextStyle(fontSize: 10, color: _selectedColor)),
                  const SizedBox(width: 4),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: Column(children: round.replies.asMap().entries.map((e) => _buildCompactReply(assistant, topic, round, e.value, e.key == round.replies.length - 1, primary)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactReply(_AssistantNode assistant, _TopicNode topic, _RoundNode round, _ReplyNode reply, bool isLast, Color primary) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final replyKey = '$roundKey:${reply.id}';
    final isSelected = _selections[replyKey] == true;
    final isContentExpanded = _expandedReplies.contains(replyKey);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 2),
      child: InkWell(
        onTap: () => _toggleReplyExpand(replyKey),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? _selectedColor.withAlpha(10) : null,
            borderRadius: BorderRadius.circular(4),
            border: reply.isMainline && !isSelected ? Border.all(color: _mainlineColor.withAlpha(60)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCheckbox(isSelected, () => _toggleReply(assistant.id, topic.id, round, reply), small: true),
                  const SizedBox(width: 6),
                  // 语义图标：灯泡代表AI回答
                  Icon(Icons.lightbulb_outline, size: 12, color: reply.isMainline ? _mainlineColor : const Color(0xFF26A69A)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(reply.modelName, style: TextStyle(fontSize: 11, color: isSelected ? _selectedColor : Colors.grey[600]))),
                  if (reply.isMainline) Text('★', style: TextStyle(fontSize: 10, color: _mainlineColor)),
                  const SizedBox(width: 4),
                  Text(_formatChars(reply.charCount), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  const SizedBox(width: 4),
                  Icon(isContentExpanded ? Icons.expand_less : Icons.expand_more, size: 14, color: Colors.grey[400]),
                ],
              ),
              _buildReplyContent(reply, isContentExpanded, onCollapse: () => _toggleReplyExpand(replyKey)),
            ],
          ),
        ),
      ),
    );
  }

  /// 简约版选中数量标记
  Widget _buildCompactBadge(int count) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Text('✓$count', style: TextStyle(fontSize: 11, color: _selectedColor, fontWeight: FontWeight.w500)),
    );
  }

  // ========================================
  // 共用的辅助组件
  // ========================================

  Widget _buildSelectionBar(double width, double height) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(color: _selectedColor, borderRadius: BorderRadius.circular(width / 2)),
    );
  }

  Widget _buildCurrentTag({bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 5 : 8, vertical: small ? 2 : 3),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _currentColor.withAlpha(20),
        borderRadius: BorderRadius.circular(small ? 4 : 6),
        border: Border.all(color: _currentColor.withAlpha(60)),
      ),
      child: Text('当前', style: TextStyle(fontSize: small ? 9 : 10, color: _currentColor, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSelectionBadge(int count, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 5 : 8, vertical: small ? 2 : 3),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: _selectedColor.withAlpha(20), borderRadius: BorderRadius.circular(small ? 8 : 10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: small ? 10 : 12, color: _selectedColor),
          SizedBox(width: small ? 3 : 4),
          Text('$count', style: TextStyle(fontSize: small ? 10 : 11, color: _selectedColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRatioTag(String ratio) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(color: _selectedColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
      child: Text(ratio, style: TextStyle(fontSize: 10, color: _selectedColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMainlineTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(color: _mainlineColor.withAlpha(25), borderRadius: BorderRadius.circular(4), border: Border.all(color: _mainlineColor.withAlpha(60))),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: _mainlineColor),
          SizedBox(width: 3),
          Text('主线', style: TextStyle(fontSize: 9, color: _mainlineColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected, VoidCallback onTap, {bool small = false}) {
    final size = small ? 16.0 : 18.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? _selectedColor : Colors.grey[400]!, width: 1.5),
        ),
        child: isSelected ? Icon(Icons.check, size: size - 4, color: Colors.white) : null,
      ),
    );
  }

  Widget _buildReplyContent(_ReplyNode reply, bool isExpanded, {VoidCallback? onCollapse}) {
    // 清理内容：跳过开头的空行和标题行
    final cleanedContent = _cleanReplyContent(reply.content);

    if (!isExpanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Text(cleanedContent, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4)),
      );
    }
    return GestureDetector(
      onDoubleTap: onCollapse,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: SingleChildScrollView(
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

  // ========================================
  // 辅助方法：计算选中数量
  // ========================================

  int _countAssistantSelections(_AssistantNode assistant) {
    int count = 0;
    for (final topic in assistant.topics) {
      count += _countTopicSelections(assistant, topic);
    }
    return count;
  }

  int _countTopicSelections(_AssistantNode assistant, _TopicNode topic) {
    int count = 0;
    for (final round in topic.rounds) {
      final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
      if (_selections['$roundKey:q'] == true) count++;
      for (var reply in round.replies) {
        if (_selections['$roundKey:${reply.id}'] == true) count++;
      }
    }
    return count;
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
    setState(() {
      if (_expandedReplies.contains(key)) {
        _expandedReplies.remove(key);
      } else {
        _expandedReplies.add(key);
      }
    });
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
