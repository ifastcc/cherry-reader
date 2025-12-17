import 'package:flutter/material.dart';
import 'context_selector.dart' show TopicSummary;

/// 四种视觉风格
enum ContextSelectorStyle {
  /// 风格一：树形连接线（像 IDE 文件树）
  treeLine,

  /// 风格二：渐进缩进 + 左边框颜色
  leftBorder,

  /// 风格三：卡片嵌套 + 阴影层级
  nestedCard,

  /// 风格四：混合风格（卡片质感 + 极简连接线）
  hybrid,
}

/// Context 选择器 - 支持三种视觉风格切换
///
/// 核心功能与 V2 相同，但提供三种不同的视觉呈现方式，便于对比选择
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

  /// 初始风格
  final ContextSelectorStyle initialStyle;

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
    this.initialStyle = ContextSelectorStyle.treeLine,
  });

  @override
  State<ContextSelectorWithStyles> createState() => _ContextSelectorWithStylesState();
}

class _ContextSelectorWithStylesState extends State<ContextSelectorWithStyles> {
  late ContextSelectorStyle _currentStyle;

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
    _currentStyle = widget.initialStyle;
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
          _buildStyleSwitcher(primary),
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
      child: Row(
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
    );
  }

  /// 风格切换器
  Widget _buildStyleSwitcher(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Text('视觉风格:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 8),
          _buildStyleButton(
            ContextSelectorStyle.treeLine,
            '树形线',
            Icons.account_tree,
            primary,
          ),
          const SizedBox(width: 6),
          _buildStyleButton(
            ContextSelectorStyle.leftBorder,
            '左边框',
            Icons.format_indent_increase,
            primary,
          ),
          const SizedBox(width: 6),
          _buildStyleButton(
            ContextSelectorStyle.nestedCard,
            '嵌套卡片',
            Icons.layers,
            primary,
          ),
          const SizedBox(width: 6),
          _buildStyleButton(
            ContextSelectorStyle.hybrid,
            '混合',
            Icons.auto_awesome,
            primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleButton(ContextSelectorStyle style, String label, IconData icon, Color primary) {
    final isSelected = _currentStyle == style;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentStyle = style),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primary.withAlpha(20) : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? primary : Colors.grey[300]!,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? primary : Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? primary : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
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
      case ContextSelectorStyle.treeLine:
        return _buildTreeLineAssistant(assistant, primary);
      case ContextSelectorStyle.leftBorder:
        return _buildLeftBorderAssistant(assistant, primary);
      case ContextSelectorStyle.nestedCard:
        return _buildNestedCardAssistant(assistant, primary);
      case ContextSelectorStyle.hybrid:
        return _buildHybridAssistant(assistant, primary);
    }
  }

  // ========================================
  // 风格一：树形连接线
  // ========================================

  Widget _buildTreeLineAssistant(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 助手标题行
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedAssistants.remove(assistant.id);
              } else {
                _expandedAssistants.add(assistant.id);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: assistant.isCurrent ? primary.withAlpha(15) : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.smart_toy, size: 18, color: assistant.isCurrent ? primary : Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      assistant.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (assistant.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('当前', style: TextStyle(fontSize: 9, color: Colors.white)),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${assistant.topics.length} 话题',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),

          // 话题列表（带连接线）
          if (isExpanded)
            ...assistant.topics.asMap().entries.map((entry) {
              final index = entry.key;
              final topic = entry.value;
              final isLast = index == assistant.topics.length - 1;
              return _buildTreeLineTopic(assistant, topic, isLast, primary);
            }),
        ],
      ),
    );
  }

  Widget _buildTreeLineTopic(_AssistantNode assistant, _TopicNode topic, bool isLast, Color primary) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 话题标题行（带连接线）
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 树形连接线
            SizedBox(
              width: 28,
              child: CustomPaint(
                size: const Size(28, 44),
                painter: _TreeConnectorPainter(
                  isLast: isLast && !isExpanded,
                  hasChildren: isExpanded && topic.rounds.isNotEmpty,
                  color: Colors.grey[300]!,
                ),
              ),
            ),

            // 话题内容
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: topic.isCurrent ? Colors.white : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: topic.isCurrent ? primary.withAlpha(60) : Colors.grey[300]!,
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    if (!topic.isLoaded && !isLoading) {
                      await _loadTopicDetail(assistant.id, topic);
                    }
                    setState(() {
                      if (isExpanded) {
                        _expandedTopics.remove(topicKey);
                      } else {
                        _expandedTopics.add(topicKey);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(7),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(
                          isExpanded ? Icons.folder_open : Icons.folder,
                          size: 16,
                          color: topic.isCurrent ? primary : Colors.amber[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            topic.name,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (topic.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('当前', style: TextStyle(fontSize: 9, color: primary)),
                          ),
                        if (isLoading)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                          )
                        else
                          Text(
                            '${topic.isLoaded ? topic.rounds.length : topic.roundCount} 轮',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // 轮次和回复列表（简化的树形结构）
        if (isExpanded && topic.isLoaded)
          ...topic.rounds.asMap().entries.expand((entry) {
            final roundIndex = entry.key;
            final round = entry.value;
            final isLastRound = roundIndex == topic.rounds.length - 1;
            final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
            final isRoundExpanded = _expandedRounds.contains(roundKey);

            return [
              // 问题节点
              _buildTreeLineQuestion(
                assistant,
                topic,
                round,
                isLastRound && !isRoundExpanded,
                isLast,
                primary,
              ),
              // 回复节点（如果展开）
              if (isRoundExpanded)
                ...round.replies.asMap().entries.map((replyEntry) {
                  final replyIndex = replyEntry.key;
                  final reply = replyEntry.value;
                  final isLastReply = replyIndex == round.replies.length - 1;
                  return _buildTreeLineReply(
                    assistant,
                    topic,
                    round,
                    reply,
                    isLastReply,
                    isLastRound,
                    isLast,
                    primary,
                  );
                }),
            ];
          }),
      ],
    );
  }

  /// 问题节点（简化的连接线）
  Widget _buildTreeLineQuestion(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    bool isLastInBranch,
    bool isLastTopic,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final isExpanded = _expandedRounds.contains(roundKey);
    final isQuestionSelected = _selections['$roundKey:q'] == true;
    final selectedReplyCount = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).length;
    final isCurrent = topic.isCurrent && round.index == widget.currentRoundIndex;

    // 使用 IntrinsicHeight 让子组件可以使用 double.infinity
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 连接线区域 - 简化为两列
          SizedBox(
            width: 48,
            child: Row(
              children: [
                // 第一列：话题级垂直线（贯穿）
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Container(
                      width: 1.5,
                      color: isLastTopic ? Colors.transparent : Colors.grey[300],
                    ),
                  ),
                ),
                // 第二列：└─ 或 ├─ 连接符
                SizedBox(
                  width: 24,
                  child: CustomPaint(
                    painter: _SimpleTreeNodePainter(
                      isLast: isLastInBranch && !isExpanded,
                      nodeColor: isQuestionSelected ? primary : Colors.blue,
                      lineColor: Colors.grey[300]!,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 问题内容
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 4, bottom: 4, right: 8),
              decoration: BoxDecoration(
                color: isCurrent ? primary.withAlpha(8) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? primary.withAlpha(80)
                      : isQuestionSelected
                          ? primary.withAlpha(60)
                          : Colors.grey[200]!,
                  width: isCurrent || isQuestionSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expandedRounds.remove(roundKey);
                      } else {
                        _expandedRounds.add(roundKey);
                      }
                    }),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          // 勾选框
                          GestureDetector(
                            onTap: () => _toggleRound(assistant.id, topic.id, round),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: isQuestionSelected ? primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isQuestionSelected ? primary : Colors.grey[350]!,
                                  width: 1.5,
                                ),
                              ),
                              child: isQuestionSelected
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 问题图标和标签
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.help_outline, size: 12, color: Colors.blue[700]),
                                const SizedBox(width: 3),
                                Text(
                                  'Q${round.index + 1}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                                ),
                              ],
                            ),
                          ),

                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
                              child: const Text('当前', style: TextStyle(fontSize: 9, color: Colors.white)),
                            ),
                          ],

                          const Spacer(),

                          // 选中计数
                          if (selectedReplyCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$selectedReplyCount/${round.replies.length}',
                                style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.w600),
                              ),
                            ),

                          // 展开图标
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 问题内容预览
                  if (round.question.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Text(
                        round.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 回复节点（简化的连接线）
  Widget _buildTreeLineReply(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    _ReplyNode reply,
    bool isLastReply,
    bool isLastRound,
    bool isLastTopic,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final replyKey = '$roundKey:${reply.id}';
    final isSelected = _selections[replyKey] == true;
    final isContentExpanded = _expandedReplies.contains(replyKey);

    // 判断是否需要显示各级垂直线
    final showTopicLine = !isLastTopic; // 话题级：非最后话题时显示
    final showRoundLine = !isLastRound || !isLastReply; // 轮次级：非最后轮次，或还有更多回复时显示

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 连接线区域 - 三列
          SizedBox(
            width: 72,
            child: Row(
              children: [
                // 第一列：话题级垂直线
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Container(
                      width: 1.5,
                      color: showTopicLine ? Colors.grey[300] : Colors.transparent,
                    ),
                  ),
                ),
                // 第二列：轮次级垂直线
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Container(
                      width: 1.5,
                      color: showRoundLine ? Colors.grey[300] : Colors.transparent,
                    ),
                  ),
                ),
                // 第三列：回复节点连接符
                SizedBox(
                  width: 24,
                  child: CustomPaint(
                    painter: _SimpleTreeNodePainter(
                      isLast: isLastReply,
                      nodeColor: isSelected ? primary : (reply.isMainline ? Colors.amber : Colors.grey[400]!),
                      lineColor: Colors.grey[300]!,
                      nodeSize: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 回复内容
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 4, bottom: 4, right: 8),
              decoration: BoxDecoration(
                color: isSelected ? primary.withAlpha(8) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? primary.withAlpha(80)
                      : reply.isMainline
                          ? Colors.amber.withAlpha(180)
                          : Colors.grey[200]!,
                  width: isSelected || reply.isMainline ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      if (isContentExpanded) {
                        _expandedReplies.remove(replyKey);
                      } else {
                        _expandedReplies.add(replyKey);
                      }
                    }),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          // 勾选框
                          GestureDetector(
                            onTap: () => _toggleReply(assistant.id, topic.id, round, reply),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isSelected ? primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected ? primary : Colors.grey[350]!,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 模型图标
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 14,
                            color: reply.isMainline ? Colors.amber[700] : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),

                          // 模型名称
                          Expanded(
                            child: Text(
                              reply.modelName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 推荐标签
                          if (reply.isMainline)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '推荐',
                                style: TextStyle(fontSize: 9, color: Colors.amber[800], fontWeight: FontWeight.w600),
                              ),
                            ),

                          // 字数
                          Text(
                            _formatChars(reply.charCount),
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 4),

                          // 展开图标
                          Icon(
                            isContentExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 内容预览/全文
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Text(
                        _getPreviewText(reply.content),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
                      ),
                    ),
                    secondChild: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          reply.content,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5),
                        ),
                      ),
                    ),
                    crossFadeState: isContentExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 风格二：左边框颜色 - 渐进式层级颜色
  // ========================================

  // 层级颜色定义（从深到浅）
  static const _leftBorderColors = [
    Color(0xFF5C6BC0), // 助手层：靛蓝
    Color(0xFF7986CB), // 话题层：浅靛蓝
    Color(0xFF64B5F6), // 轮次层：蓝色
    Color(0xFF81C784), // 回复层：绿色
  ];

  Widget _buildLeftBorderAssistant(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);
    final levelColor = assistant.isCurrent ? primary : _leftBorderColors[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: levelColor, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 助手标题
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedAssistants.remove(assistant.id);
              } else {
                _expandedAssistants.add(assistant.id);
              }
            }),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [levelColor.withAlpha(8), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: levelColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.smart_toy, size: 18, color: levelColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assistant.name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${assistant.topics.length} 个话题',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  if (assistant.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('当前', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 22,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // 话题列表
          if (isExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 8, 10),
              child: Column(
                children: assistant.topics.map((topic) {
                  return _buildLeftBorderTopic(assistant, topic, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftBorderTopic(_AssistantNode assistant, _TopicNode topic, Color primary) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);
    final levelColor = topic.isCurrent ? primary : _leftBorderColors[1];

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: topic.isCurrent ? primary.withAlpha(5) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: levelColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () async {
              if (!topic.isLoaded && !isLoading) {
                await _loadTopicDetail(assistant.id, topic);
              }
              setState(() {
                if (isExpanded) {
                  _expandedTopics.remove(topicKey);
                } else {
                  _expandedTopics.add(topicKey);
                }
              });
            },
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.folder_open : Icons.folder,
                    size: 16,
                    color: levelColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topic.name,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (topic.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('当前', style: TextStyle(fontSize: 9, color: primary, fontWeight: FontWeight.w500)),
                    ),
                  if (isLoading)
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${topic.isLoaded ? topic.rounds.length : topic.roundCount}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 轮次列表
          if (isExpanded && topic.isLoaded)
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 6, 8),
              child: Column(
                children: topic.rounds.map((round) {
                  return _buildLeftBorderRound(assistant, topic, round, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftBorderRound(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final isExpanded = _expandedRounds.contains(roundKey);
    final isQuestionSelected = _selections['$roundKey:q'] == true;
    final selectedReplyCount = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).length;
    final isCurrent = topic.isCurrent && round.index == widget.currentRoundIndex;
    final levelColor = isCurrent ? primary : _leftBorderColors[2];

    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: levelColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedRounds.remove(roundKey);
              } else {
                _expandedRounds.add(roundKey);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleRound(assistant.id, topic.id, round),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isQuestionSelected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: isQuestionSelected ? primary : Colors.grey[350]!,
                          width: 1.5,
                        ),
                      ),
                      child: isQuestionSelected
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.help_outline, size: 14, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Q${round.index + 1}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
                      child: const Text('当前', style: TextStyle(fontSize: 9, color: Colors.white)),
                    ),
                  ],
                  const Spacer(),
                  if (selectedReplyCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$selectedReplyCount/${round.replies.length}',
                        style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          if (round.question.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text(
                round.question,
                maxLines: isExpanded ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),

          if (isExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(8, 2, 6, 8),
              child: Column(
                children: round.replies.map((reply) {
                  return _buildLeftBorderReply(assistant, topic, round, reply, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftBorderReply(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    _ReplyNode reply,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final replyKey = '$roundKey:${reply.id}';
    final isSelected = _selections[replyKey] == true;
    final isContentExpanded = _expandedReplies.contains(replyKey);

    // 主线回复用推荐色（绿色），普通回复用层级色
    final levelColor = reply.isMainline ? Colors.amber[600]! : _leftBorderColors[3];
    final bgColor = isSelected ? primary.withAlpha(10) : (reply.isMainline ? Colors.amber.withAlpha(8) : Colors.grey[50]!);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border(
          left: BorderSide(color: levelColor, width: 2.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isContentExpanded) {
                _expandedReplies.remove(replyKey);
              } else {
                _expandedReplies.add(replyKey);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleReply(assistant.id, topic.id, round, reply),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey[350]!,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 9, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.smart_toy_outlined, size: 12, color: reply.isMainline ? Colors.amber[700] : Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reply.modelName,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reply.isMainline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(3)),
                      child: Text('推荐', style: TextStyle(fontSize: 8, color: Colors.amber[800])),
                    ),
                  Text(_formatChars(reply.charCount), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: Text(
                _getPreviewText(reply.content),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ),
            secondChild: Container(
              constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: SingleChildScrollView(
                child: SelectableText(
                  reply.content,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.5),
                ),
              ),
            ),
            crossFadeState: isContentExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 风格三：嵌套卡片 + 阴影 - 渐进式阴影深度
  // ========================================

  Widget _buildNestedCardAssistant(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);

    // 助手层：最外层容器，使用较深的背景色
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: assistant.isCurrent
              ? [primary.withAlpha(12), primary.withAlpha(6)]
              : [Colors.grey[200]!, Colors.grey[150]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: assistant.isCurrent
            ? Border.all(color: primary.withAlpha(30), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 助手标题
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedAssistants.remove(assistant.id);
              } else {
                _expandedAssistants.add(assistant.id);
              }
            }),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 图标容器 - 有立体效果
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: assistant.isCurrent ? primary.withAlpha(25) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (assistant.isCurrent ? primary : Colors.grey).withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      size: 20,
                      color: assistant.isCurrent ? primary : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                assistant.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (assistant.isCurrent) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withAlpha(60),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text('当前', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${assistant.topics.length} 个话题',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 22,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 话题列表（白色卡片，有阴影层级）
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: assistant.topics.map((topic) {
                  return _buildNestedCardTopic(assistant, topic, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNestedCardTopic(_AssistantNode assistant, _TopicNode topic, Color primary) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);

    // 话题层：白色卡片，有明显阴影
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(topic.isCurrent ? 20 : 12),
            blurRadius: topic.isCurrent ? 12 : 8,
            offset: const Offset(0, 3),
          ),
          // 内发光效果（让卡片看起来更立体）
          BoxShadow(
            color: Colors.white.withAlpha(200),
            blurRadius: 1,
            offset: const Offset(0, -1),
            spreadRadius: -1,
          ),
        ],
        border: topic.isCurrent
            ? Border.all(color: primary.withAlpha(70), width: 2)
            : Border.all(color: Colors.grey.withAlpha(20), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () async {
              if (!topic.isLoaded && !isLoading) {
                await _loadTopicDetail(assistant.id, topic);
              }
              setState(() {
                if (isExpanded) {
                  _expandedTopics.remove(topicKey);
                } else {
                  _expandedTopics.add(topicKey);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: topic.isCurrent
                            ? [primary.withAlpha(20), primary.withAlpha(10)]
                            : [Colors.amber.withAlpha(40), Colors.amber.withAlpha(20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      size: 16,
                      color: topic.isCurrent ? primary : Colors.amber[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (topic.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('当前', style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.w500)),
                    ),
                  if (isLoading)
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${topic.isLoaded ? topic.rounds.length : topic.roundCount}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 轮次列表（轻微灰色背景，无边框）
          if (isExpanded && topic.isLoaded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: topic.rounds.map((round) {
                  return _buildNestedCardRound(assistant, topic, round, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNestedCardRound(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final isExpanded = _expandedRounds.contains(roundKey);
    final isQuestionSelected = _selections['$roundKey:q'] == true;
    final selectedReplyCount = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).length;
    final isCurrent = topic.isCurrent && round.index == widget.currentRoundIndex;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isCurrent ? 12 : 6),
            blurRadius: isCurrent ? 6 : 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: isCurrent ? Border.all(color: primary.withAlpha(50)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedRounds.remove(roundKey);
              } else {
                _expandedRounds.add(roundKey);
              }
            }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleRound(assistant.id, topic.id, round),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isQuestionSelected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isQuestionSelected ? primary : Colors.grey[350]!,
                          width: 1.5,
                        ),
                      ),
                      child: isQuestionSelected
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${round.index + 1}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      round.question.isNotEmpty
                          ? (round.question.length > 40 ? '${round.question.substring(0, 40)}...' : round.question)
                          : '(空问题)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
                      child: const Text('当前', style: TextStyle(fontSize: 9, color: Colors.white)),
                    ),
                  if (selectedReplyCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '$selectedReplyCount/${round.replies.length}',
                        style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // 回复列表
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                children: round.replies.map((reply) {
                  return _buildNestedCardReply(assistant, topic, round, reply, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNestedCardReply(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    _ReplyNode reply,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final replyKey = '$roundKey:${reply.id}';
    final isSelected = _selections[replyKey] == true;
    final isContentExpanded = _expandedReplies.contains(replyKey);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isSelected ? 10 : 5),
            blurRadius: isSelected ? 4 : 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: isSelected
            ? Border.all(color: primary.withAlpha(60))
            : reply.isMainline
                ? Border.all(color: Colors.amber.withAlpha(150))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isContentExpanded) {
                _expandedReplies.remove(replyKey);
              } else {
                _expandedReplies.add(replyKey);
              }
            }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleReply(assistant.id, topic.id, round, reply),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey[350]!,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: reply.isMainline ? Colors.amber[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      size: 12,
                      color: reply.isMainline ? Colors.amber[700] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reply.modelName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reply.isMainline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
                      child: Text('推荐', style: TextStyle(fontSize: 9, color: Colors.amber[800])),
                    ),
                  Text(_formatChars(reply.charCount), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  const SizedBox(width: 4),
                  Icon(
                    isContentExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                _getPreviewText(reply.content),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
            secondChild: Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SingleChildScrollView(
                child: SelectableText(
                  reply.content,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5),
                ),
              ),
            ),
            crossFadeState: isContentExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 风格四：混合风格（卡片质感 + 极简连接线）
  // ========================================

  Widget _buildHybridAssistant(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 助手标题行 - 简洁风格
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedAssistants.remove(assistant.id);
              } else {
                _expandedAssistants.add(assistant.id);
              }
            }),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: assistant.isCurrent ? primary.withAlpha(10) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: assistant.isCurrent
                    ? Border.all(color: primary.withAlpha(40), width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.smart_toy,
                    size: 20,
                    color: assistant.isCurrent ? primary : Colors.grey[600],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      assistant.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (assistant.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '当前',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  Text(
                    '${assistant.topics.length} 话题',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),

          // 话题列表（带极简连接线）
          if (isExpanded)
            Container(
              margin: const EdgeInsets.only(left: 24, top: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1.5),
                ),
              ),
              child: Column(
                children: assistant.topics.asMap().entries.map((entry) {
                  final index = entry.key;
                  final topic = entry.value;
                  final isLast = index == assistant.topics.length - 1;
                  return _buildHybridTopic(assistant, topic, isLast, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHybridTopic(
    _AssistantNode assistant,
    _TopicNode topic,
    bool isLast,
    Color primary,
  ) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);

    return Container(
      margin: EdgeInsets.only(left: 16, top: 6, bottom: isLast ? 6 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 话题卡片
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(topic.isCurrent ? 15 : 8),
                  blurRadius: topic.isCurrent ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: topic.isCurrent
                  ? Border.all(color: primary.withAlpha(60), width: 1.5)
                  : Border.all(color: Colors.grey.withAlpha(30), width: 1),
            ),
            child: InkWell(
              onTap: () async {
                if (!topic.isLoaded && !isLoading) {
                  await _loadTopicDetail(assistant.id, topic);
                }
                setState(() {
                  if (isExpanded) {
                    _expandedTopics.remove(topicKey);
                  } else {
                    _expandedTopics.add(topicKey);
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      size: 18,
                      color: topic.isCurrent ? primary : Colors.amber[700],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topic.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (topic.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '当前',
                          style: TextStyle(fontSize: 9, color: primary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (isLoading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${topic.isLoaded ? topic.rounds.length : topic.roundCount} 轮',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 轮次列表（带连接线和卡片）
          if (isExpanded && topic.isLoaded)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 6),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1.5),
                ),
              ),
              child: Column(
                children: topic.rounds.asMap().entries.map((entry) {
                  final roundIndex = entry.key;
                  final round = entry.value;
                  final isLastRound = roundIndex == topic.rounds.length - 1;
                  return _buildHybridRound(assistant, topic, round, isLastRound, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHybridRound(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    bool isLastRound,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final isExpanded = _expandedRounds.contains(roundKey);
    final isQuestionSelected = _selections['$roundKey:q'] == true;
    final selectedReplyCount = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).length;
    final isCurrent = topic.isCurrent && round.index == widget.currentRoundIndex;

    return Container(
      margin: EdgeInsets.only(left: 14, top: 6, bottom: isLastRound ? 6 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 问题卡片
          Container(
            decoration: BoxDecoration(
              color: isCurrent ? primary.withAlpha(6) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isCurrent ? 12 : 6),
                  blurRadius: isCurrent ? 6 : 3,
                  offset: const Offset(0, 1),
                ),
              ],
              border: isCurrent
                  ? Border.all(color: primary.withAlpha(50), width: 1.5)
                  : Border.all(color: Colors.grey.withAlpha(20), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expandedRounds.remove(roundKey);
                    } else {
                      _expandedRounds.add(roundKey);
                    }
                  }),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // 勾选框
                        GestureDetector(
                          onTap: () => _toggleRound(assistant.id, topic.id, round),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isQuestionSelected ? primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isQuestionSelected ? primary : Colors.grey[350]!,
                                width: 1.5,
                              ),
                            ),
                            child: isQuestionSelected
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Q标签
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.help_outline, size: 12, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Q${round.index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '当前',
                              style: TextStyle(fontSize: 9, color: Colors.white),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // 选中计数
                        if (selectedReplyCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$selectedReplyCount/${round.replies.length}',
                              style: TextStyle(
                                fontSize: 10,
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),

                // 问题内容预览
                if (round.question.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Text(
                      round.question,
                      maxLines: isExpanded ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                    ),
                  ),
              ],
            ),
          ),

          // 回复列表
          if (isExpanded)
            Container(
              margin: const EdgeInsets.only(left: 6, top: 6),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[200]!, width: 1.5),
                ),
              ),
              child: Column(
                children: round.replies.asMap().entries.map((entry) {
                  final replyIndex = entry.key;
                  final reply = entry.value;
                  final isLastReply = replyIndex == round.replies.length - 1;
                  return _buildHybridReply(assistant, topic, round, reply, isLastReply, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHybridReply(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    _ReplyNode reply,
    bool isLastReply,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final replyKey = '$roundKey:${reply.id}';
    final isSelected = _selections[replyKey] == true;
    final isContentExpanded = _expandedReplies.contains(replyKey);

    return Container(
      margin: EdgeInsets.only(left: 12, top: 5, bottom: isLastReply ? 5 : 0),
      decoration: BoxDecoration(
        color: isSelected ? primary.withAlpha(8) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isSelected ? 10 : 5),
            blurRadius: isSelected ? 4 : 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: isSelected
            ? Border.all(color: primary.withAlpha(60), width: 1.5)
            : reply.isMainline
                ? Border.all(color: Colors.amber.withAlpha(150), width: 1.5)
                : Border.all(color: Colors.grey.withAlpha(20), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isContentExpanded) {
                _expandedReplies.remove(replyKey);
              } else {
                _expandedReplies.add(replyKey);
              }
            }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // 勾选框
                  GestureDetector(
                    onTap: () => _toggleReply(assistant.id, topic.id, round, reply),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey[350]!,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 模型图标
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 14,
                    color: reply.isMainline ? Colors.amber[700] : Colors.grey[500],
                  ),
                  const SizedBox(width: 6),

                  // 模型名称
                  Expanded(
                    child: Text(
                      reply.modelName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 推荐标签
                  if (reply.isMainline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '推荐',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // 字数
                  Text(
                    _formatChars(reply.charCount),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 4),

                  Icon(
                    isContentExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // 内容预览/全文
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                _getPreviewText(reply.content),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
              ),
            ),
            secondChild: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SingleChildScrollView(
                child: SelectableText(
                  reply.content,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5),
                ),
              ),
            ),
            crossFadeState: isContentExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
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

/// 树形连接线画笔（用于风格一）
class _TreeConnectorPainter extends CustomPainter {
  final bool isLast;
  final bool hasChildren;
  final Color color;

  _TreeConnectorPainter({
    required this.isLast,
    required this.hasChildren,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 垂直线
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, isLast ? 22 : size.height),
      paint,
    );

    // 水平线
    canvas.drawLine(
      Offset(size.width / 2, 22),
      Offset(size.width, 22),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 简化的树节点画笔 - 画 ├─ 或 └─ 形状 + 节点圆点
class _SimpleTreeNodePainter extends CustomPainter {
  final bool isLast;
  final Color nodeColor;
  final Color lineColor;
  final double nodeSize;

  _SimpleTreeNodePainter({
    required this.isLast,
    required this.nodeColor,
    required this.lineColor,
    this.nodeSize = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 垂直线上半段（从顶部到中心）
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, centerY),
      linePaint,
    );

    // 如果不是最后一个，继续向下画线
    if (!isLast) {
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(centerX, size.height),
        linePaint,
      );
    }

    // 水平线（从中心到右侧）
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(size.width, centerY),
      linePaint,
    );

    // 节点圆点
    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      nodeSize / 2,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SimpleTreeNodePainter oldDelegate) {
    return oldDelegate.isLast != isLast ||
        oldDelegate.nodeColor != nodeColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.nodeSize != nodeSize;
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

String _getPreviewText(String content) {
  if (content.isEmpty) return '（暂无内容）';

  final lines = content.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }

  return '（仅空白 · ${content.length}字）';
}
