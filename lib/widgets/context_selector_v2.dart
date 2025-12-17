import 'package:flutter/material.dart';
import 'context_selector.dart' show TopicSummary;

/// Context 选择器 V2 - 4 层树形结构
///
/// 层级结构：助手 → 话题 → 轮次 → 回复
/// 特点：
/// - 搜索功能：快速定位话题
/// - 粘性面包屑：始终知道当前位置
/// - 智能展开：只展开焦点路径
/// - 视觉层级：透明度递减表示层级深度
/// - 支持跨话题、跨助手选择
class ContextSelectorV2 extends StatefulWidget {
  final Map<String, dynamic>? contextData;
  final String contextSnapshot;
  final int? currentRoundIndex;

  /// 当前话题信息（用于区分）
  final String? currentTopicId;
  final String? currentTopicName;
  final String? currentAssistantId;
  final String? currentAssistantName;

  /// 回调：返回新的 snapshot 和基于选择生成的 contextDataJson
  final Function(String newSnapshot, String? contextDataJson)? onContextChanged;
  final VoidCallback? onClear;

  /// 按需加载其他话题的回调
  final Future<List<TopicSummary>> Function(String? assistantId)? onLoadTopics;

  /// 加载话题详情的回调
  final Future<Map<String, dynamic>?> Function(String topicId)? onLoadTopicDetail;

  const ContextSelectorV2({
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
  State<ContextSelectorV2> createState() => _ContextSelectorV2State();
}

class _ContextSelectorV2State extends State<ContextSelectorV2> {
  // ===== 4 层数据结构 =====
  final List<_AssistantNode> _assistants = [];
  final Map<String, bool> _selections = {};

  // ===== 展开状态 =====
  final Set<String> _expandedAssistants = {};
  final Set<String> _expandedTopics = {};
  final Set<String> _expandedRounds = {};
  final Set<String> _expandedReplies = {};

  // ===== 搜索 =====
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ===== 加载状态 =====
  bool _isLoadingTopics = false;
  bool _hasLoadedTopics = false;
  List<TopicSummary>? _availableTopics;
  final Set<String> _loadingTopicIds = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _parseContextData();
    // 注意：不在这里调用 _initDefaultSelection 和 _initDefaultExpansion
    // 因为数据会在 _groupTopicsByAssistant 中加载后初始化
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 自动加载话题列表
      if (widget.onLoadTopics != null) {
        _loadTopics();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ContextSelectorV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contextData != widget.contextData ||
        oldWidget.currentRoundIndex != widget.currentRoundIndex) {
      _parseContextData();
      _initDefaultSelection();
      _initDefaultExpansion();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // 暂存当前话题的轮次数据
  List<_RoundNode> _currentTopicRounds = [];

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

      // 如果是当前话题，填入已解析的轮次数据
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

    // 按是否当前助手排序：当前助手在最前面
    final sortedAssistants = grouped.values.toList()
      ..sort((a, b) {
        if (a.isCurrent && !b.isCurrent) return -1;
        if (!a.isCurrent && b.isCurrent) return 1;
        return a.name.compareTo(b.name);
      });

    // 对每个助手的话题列表排序：当前话题在最前面
    for (final assistant in sortedAssistants) {
      assistant.topics.sort((a, b) {
        if (a.isCurrent && !b.isCurrent) return -1;
        if (!a.isCurrent && b.isCurrent) return 1;
        return 0; // 保持原有顺序
      });
    }

    _assistants.addAll(sortedAssistants);

    // 自动展开当前助手和当前话题，并选中当前轮次
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

  // ===== 搜索过滤 =====
  bool _matchesSearch(_AssistantNode assistant) {
    if (_searchQuery.isEmpty) return true;
    if (assistant.name.toLowerCase().contains(_searchQuery)) return true;
    for (final topic in assistant.topics) {
      if (topic.name.toLowerCase().contains(_searchQuery)) return true;
    }
    return false;
  }

  bool _topicMatchesSearch(_TopicNode topic) {
    if (_searchQuery.isEmpty) return true;
    return topic.name.toLowerCase().contains(_searchQuery);
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
          _buildSearchBar(primary),
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

  Widget _buildSearchBar(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      color: Colors.white,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '搜索话题...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 16, color: Colors.grey[500]),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildTreeList(Color primary) {
    final filteredAssistants = _assistants.where(_matchesSearch).toList();

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

    if (filteredAssistants.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? '暂无话题' : '未找到匹配的话题',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filteredAssistants.length,
      itemBuilder: (context, index) {
        return _buildAssistantNode(filteredAssistants[index], primary);
      },
    );
  }

  Widget _buildAssistantNode(_AssistantNode assistant, Color primary) {
    final isExpanded = _expandedAssistants.contains(assistant.id);
    final filteredTopics = assistant.topics.where(_topicMatchesSearch).toList();
    final topicCount = filteredTopics.length;

    // 计算该助手下选中的内容数
    int selectedCount = 0;
    for (final topic in assistant.topics) {
      for (final round in topic.rounds) {
        final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
        for (var reply in round.replies) {
          if (_selections['$roundKey:${reply.id}'] == true) {
            selectedCount++;
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: assistant.isCurrent ? primary.withAlpha(80) : Colors.grey[300]!,
          width: assistant.isCurrent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(assistant.isCurrent ? 12 : 6),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 助手标题
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedAssistants.remove(assistant.id);
                } else {
                  _expandedAssistants.add(assistant.id);
                }
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(9),
              bottom: isExpanded ? Radius.zero : const Radius.circular(9),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: assistant.isCurrent ? primary.withAlpha(8) : null,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(9),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(9),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: assistant.isCurrent ? primary.withAlpha(20) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      size: 16,
                      color: assistant.isCurrent ? primary : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 10),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (assistant.isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '当前',
                                  style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$topicCount 个话题${selectedCount > 0 ? ' · 已选 $selectedCount' : ''}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // 话题列表
          if (isExpanded && filteredTopics.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                children: filteredTopics.asMap().entries.map((entry) {
                  final index = entry.key;
                  final topic = entry.value;
                  return _buildTopicNode(assistant, topic, index == filteredTopics.length - 1, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicNode(_AssistantNode assistant, _TopicNode topic, bool isLast, Color primary) {
    final topicKey = _getTopicKey(assistant.id, topic.id);
    final isExpanded = _expandedTopics.contains(topicKey);
    final isLoading = _loadingTopicIds.contains(topic.id);

    // 计算该话题下选中的回复数
    int selectedCount = 0;
    for (final round in topic.rounds) {
      final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
      for (var reply in round.replies) {
        if (_selections['$roundKey:${reply.id}'] == true) {
          selectedCount++;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 话题标题
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: topic.isCurrent ? primary.withAlpha(5) : null,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: topic.isCurrent ? primary : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      topic.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
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
                      child: Text(
                        '当前',
                        style: TextStyle(fontSize: 9, color: primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (selectedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (isLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                    )
                  else ...[
                    Text(
                      '${topic.isLoaded ? topic.rounds.length : topic.roundCount} 轮',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
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
              color: Colors.grey[50],
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
              child: Column(
                children: topic.rounds.asMap().entries.map((entry) {
                  final roundIndex = entry.key;
                  final round = entry.value;
                  return _buildRoundNode(assistant, topic, round, roundIndex == topic.rounds.length - 1, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundNode(
    _AssistantNode assistant,
    _TopicNode topic,
    _RoundNode round,
    bool isLast,
    Color primary,
  ) {
    final roundKey = _getRoundKey(assistant.id, topic.id, round.index);
    final isExpanded = _expandedRounds.contains(roundKey);
    final isQuestionSelected = _selections['$roundKey:q'] == true;
    final selectedReplyCount = round.replies.where((r) => _selections['$roundKey:${r.id}'] == true).length;
    final isCurrent = topic.isCurrent && round.index == widget.currentRoundIndex;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? primary.withAlpha(60) : Colors.grey[200]!,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 轮次标题
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedRounds.remove(roundKey);
                } else {
                  _expandedRounds.add(roundKey);
                }
              });
            },
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
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '当前',
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const Spacer(),
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
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // 问题预览
          if (round.question.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Text(
                round.question,
                maxLines: isExpanded ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
              ),
            ),

          // 回复列表
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: round.replies.asMap().entries.map((entry) {
                  final reply = entry.value;
                  return _buildReplyNode(assistant, topic, round, reply, primary);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyNode(
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
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: isSelected ? primary.withAlpha(8) : Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? primary.withAlpha(60)
              : reply.isMainline
                  ? Colors.amber.withAlpha(150)
                  : Colors.grey[200]!,
          width: isSelected || reply.isMainline ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isContentExpanded) {
                  _expandedReplies.remove(replyKey);
                } else {
                  _expandedReplies.add(replyKey);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
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
                      child: isSelected
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 14,
                    color: reply.isMainline ? Colors.amber[700] : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reply.modelName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reply.isMainline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                  Text(
                    _formatChars(reply.charCount),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
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

          // 内容预览
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                _getPreviewText(reply.content),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
              ),
            ),
            secondChild: Container(
              constraints: const BoxConstraints(maxHeight: 200),
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
