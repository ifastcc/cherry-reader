import 'package:flutter/material.dart';

/// Context 选择器 - 扁平化树形列表
///
/// 特点：
/// - 单列布局，问题和回复用缩进+连接线表示层级
/// - 直接勾选，无需展开详情面板
/// - 点击内容区可展开查看全文
class ContextSelector extends StatefulWidget {
  final Map<String, dynamic>? contextData;
  final String contextSnapshot;
  final int? currentRoundIndex;
  /// 回调：返回新的 snapshot 和基于选择生成的 contextDataJson
  final Function(String newSnapshot, String? contextDataJson)? onContextChanged;
  final VoidCallback? onClear;

  const ContextSelector({
    super.key,
    this.contextData,
    required this.contextSnapshot,
    this.currentRoundIndex,
    this.onContextChanged,
    this.onClear,
  });

  @override
  State<ContextSelector> createState() => _ContextSelectorState();
}

class _ContextSelectorState extends State<ContextSelector> {
  List<_QuestionGroup> _groups = [];
  final Map<String, bool> _selections = {};
  final Set<String> _expandedItems = {}; // 展开查看内容的项

  @override
  void initState() {
    super.initState();
    _parseContextData();
    _initDefaultSelection();
    // 初始化后通知父组件当前选择状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  @override
  void didUpdateWidget(ContextSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 检查 contextData 或 contextSnapshot 变化
    if (oldWidget.contextData != widget.contextData ||
        oldWidget.contextSnapshot != widget.contextSnapshot ||
        oldWidget.currentRoundIndex != widget.currentRoundIndex) {
      _parseContextData();
      _initDefaultSelection();
    }
  }

  void _parseContextData() {
    if (widget.contextData != null && widget.contextData!['rounds'] != null) {
      _groups = _extractFromData(widget.contextData!);
    } else {
      _groups = _extractFromMarkdown(widget.contextSnapshot);
    }
  }

  List<_QuestionGroup> _extractFromData(Map<String, dynamic> data) {
    final groups = <_QuestionGroup>[];
    final roundsData = data['rounds'] as List<dynamic>? ?? [];

    for (var roundData in roundsData) {
      if (roundData is! Map<String, dynamic>) continue;

      final index = roundData['index'] as int? ?? groups.length;
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

      final replies = <_ReplyItem>[];
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

        replies.add(_ReplyItem(
          id: id,
          modelName: modelName,
          content: content,
          isMainline: useful,
          charCount: content.length,
        ));
      }

      groups.add(_QuestionGroup(
        index: index,
        question: question,
        replies: replies,
      ));
    }

    return groups;
  }

  List<_QuestionGroup> _extractFromMarkdown(String snapshot) {
    final groups = <_QuestionGroup>[];
    final sections = snapshot.split('##').where((s) => s.trim().isNotEmpty).toList();

    String? currentQuestion;
    List<_ReplyItem> currentReplies = [];
    int groupIndex = 0;

    for (var section in sections) {
      final lines = section.trim().split('\n');
      final header = lines.first.trim();

      if (header.startsWith('用户问题')) {
        if (currentQuestion != null) {
          groups.add(_QuestionGroup(
            index: groupIndex++,
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

          currentReplies.add(_ReplyItem(
            id: 'reply_${groupIndex}_${currentReplies.length}',
            modelName: modelName,
            content: content,
            isMainline: false,
            charCount: content.length,
          ));
        }
      }
    }

    if (currentQuestion != null) {
      groups.add(_QuestionGroup(
        index: groupIndex,
        question: currentQuestion,
        replies: currentReplies,
      ));
    }

    return groups;
  }

  void _initDefaultSelection() {
    _selections.clear();
    final targetIndex = widget.currentRoundIndex ?? (_groups.isNotEmpty ? _groups.length - 1 : null);

    if (targetIndex != null && targetIndex < _groups.length) {
      final group = _groups[targetIndex];
      // 只有当问题非空时才选中问题
      if (group.question.isNotEmpty) {
        _selections[group.questionId] = true;
      }
      for (var reply in group.replies) {
        _selections[reply.id] = true;
      }
    }
    setState(() {});
  }

  void _selectMainlineOnly() {
    _selections.clear();
    for (var group in _groups) {
      // 只有当问题非空时才选中问题
      if (group.question.isNotEmpty) {
        _selections[group.questionId] = true;
      }
      final mainlineReplies = group.replies.where((r) => r.isMainline).toList();
      if (mainlineReplies.isNotEmpty) {
        for (var reply in mainlineReplies) {
          _selections[reply.id] = true;
        }
      } else if (group.replies.isNotEmpty) {
        _selections[group.replies.first.id] = true;
      }
    }
    setState(() {});
    _notifyChange();
  }

  void _selectAll() {
    _selections.clear();
    for (var group in _groups) {
      // 只有当问题非空时才选中问题
      if (group.question.isNotEmpty) {
        _selections[group.questionId] = true;
      }
      for (var reply in group.replies) {
        _selections[reply.id] = true;
      }
    }
    setState(() {});
    _notifyChange();
  }

  void _clearAll() {
    setState(() => _selections.clear());
    _notifyChange();
  }

  void _toggleQuestion(String questionId, _QuestionGroup group) {
    setState(() {
      final isSelected = _selections[questionId] == true;
      if (isSelected) {
        // 取消选择问题及其所有回复
        _selections.remove(questionId);
        for (var reply in group.replies) {
          _selections.remove(reply.id);
        }
      } else {
        // 选择问题及其所有回复
        _selections[questionId] = true;
        for (var reply in group.replies) {
          _selections[reply.id] = true;
        }
      }
    });
    _notifyChange();
  }

  void _toggleReply(String replyId, _QuestionGroup group) {
    setState(() {
      final isSelected = _selections[replyId] == true;
      if (isSelected) {
        _selections.remove(replyId);
      } else {
        _selections[replyId] = true;
        // 选择回复时自动选中问题
        _selections[group.questionId] = true;
      }
    });
    _notifyChange();
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedItems.contains(id)) {
        _expandedItems.remove(id);
      } else {
        _expandedItems.add(id);
      }
    });
  }

  String _buildContextSnapshot() {
    final buffer = StringBuffer();
    for (var group in _groups) {
      if (_selections[group.questionId] == true) {
        buffer.writeln('## 用户问题\n');
        buffer.writeln(group.question);
        buffer.writeln();
      }

      final selectedReplies = group.replies.where((r) => _selections[r.id] == true).toList();
      if (selectedReplies.isNotEmpty) {
        buffer.writeln('## 模型回复\n');
        for (var reply in selectedReplies) {
          buffer.writeln('### ${reply.modelName}\n');
          buffer.writeln(reply.content);
          buffer.writeln();
        }
      }
    }
    return buffer.toString().trim();
  }

  void _notifyChange() {
    widget.onContextChanged?.call(_buildContextSnapshot(), _buildContextDataJson());
  }

  /// 基于当前选择生成 contextDataJson
  ///
  /// 格式: {"type":"multi","rounds":[{"index":0,"questionPreview":"...","replies":[{"model":"GPT-4","charCount":1234}]}]}
  String? _buildContextDataJson() {
    if (_groups.isEmpty) return null;

    // 检查是否有任何选中
    bool hasSelection = false;
    for (var group in _groups) {
      if (_selections[group.questionId] == true) {
        hasSelection = true;
        break;
      }
      for (var reply in group.replies) {
        if (_selections[reply.id] == true) {
          hasSelection = true;
          break;
        }
      }
      if (hasSelection) break;
    }
    if (!hasSelection) return null;

    final roundJsonParts = <String>[];
    int totalCharCount = 0;

    for (var group in _groups) {
      final isQuestionSelected = _selections[group.questionId] == true;
      final selectedReplies = group.replies.where((r) => _selections[r.id] == true).toList();

      // 如果这一轮没有任何选中，跳过
      if (!isQuestionSelected && selectedReplies.isEmpty) continue;

      // 问题预览
      String? questionPart;
      if (isQuestionSelected && group.question.isNotEmpty) {
        final questionPreview = group.question.length > 50
            ? '${group.question.substring(0, 50)}...'
            : group.question;
        questionPart = ',"questionPreview":"${_escapeJson(questionPreview)}"';
        totalCharCount += group.question.length;
      }

      // 回复列表
      final replyJsonParts = <String>[];
      for (var reply in selectedReplies) {
        replyJsonParts.add('{"model":"${_escapeJson(reply.modelName)}","charCount":${reply.charCount}}');
        totalCharCount += reply.charCount;
      }

      final repliesJson = replyJsonParts.join(',');
      roundJsonParts.add('{"index":${group.index}${questionPart ?? ''},"replies":[$repliesJson]}');
    }

    if (roundJsonParts.isEmpty) return null;

    final roundsJson = roundJsonParts.join(',');
    return '{"type":"multi","rounds":[$roundsJson],"charCount":$totalCharCount}';
  }

  /// 转义 JSON 字符串中的特殊字符
  String _escapeJson(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  Map<String, int> _getStats() {
    int questions = 0;
    int replies = 0;
    int chars = 0;

    for (var group in _groups) {
      if (_selections[group.questionId] == true) {
        questions++;
        chars += group.question.length;
      }
      for (var reply in group.replies) {
        if (_selections[reply.id] == true) {
          replies++;
          chars += reply.charCount;
        }
      }
    }

    return {'questions': questions, 'replies': replies, 'chars': chars};
  }

  String _formatChars(int count) {
    if (count < 1000) return '$count';
    if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 10000).toStringAsFixed(1)}w';
  }

  @override
  Widget build(BuildContext context) {
    if (_groups.isEmpty) {
      return _buildEmpty();
    }

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

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_outlined, size: 32, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            '无上下文内容',
            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, int> stats, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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

  Widget _buildTreeList(Color primary) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final isCurrent = widget.currentRoundIndex == group.index;
        final isQuestionSelected = _selections[group.questionId] == true;
        final selectedReplyCount = group.replies.where((r) => _selections[r.id] == true).length;
        final hasQuestion = group.question.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 问题行（只有当有问题内容时才显示）
            if (hasQuestion)
              _TreeNode(
                isRoot: true,
                isLast: group.replies.isEmpty,
                isSelected: isQuestionSelected,
                isCurrent: isCurrent,
                isExpanded: _expandedItems.contains(group.questionId),
                title: 'Q${group.index + 1}',
                subtitle: group.question,
                badge: selectedReplyCount > 0 ? '$selectedReplyCount/${group.replies.length}' : null,
                charCount: _formatChars(group.question.length),
                onToggleSelect: () => _toggleQuestion(group.questionId, group),
                onToggleExpand: () => _toggleExpand(group.questionId),
                primary: primary,
              ),

            // 回复列表
            ...group.replies.asMap().entries.map((entry) {
              final replyIndex = entry.key;
              final reply = entry.value;
              final isLastReply = replyIndex == group.replies.length - 1;
              final isReplySelected = _selections[reply.id] == true;

              return _TreeNode(
                isRoot: !hasQuestion, // 没有问题时，回复作为根节点
                isLast: isLastReply,
                isSelected: isReplySelected,
                isMainline: reply.isMainline,
                isExpanded: _expandedItems.contains(reply.id),
                title: reply.modelName,
                subtitle: reply.content,
                charCount: _formatChars(reply.charCount),
                onToggleSelect: () => _toggleReply(reply.id, group),
                onToggleExpand: () => _toggleExpand(reply.id),
                primary: primary,
              );
            }),

            if (index < _groups.length - 1) const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildFooter(Map<String, int> stats, Color primary) {
    final hasSelection = stats['questions']! > 0 || stats['replies']! > 0;

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
            hasSelection ? '${stats['questions']}问 + ${stats['replies']}回复' : '未选择',
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

/// 树形节点 - 支持展开内容
class _TreeNode extends StatelessWidget {
  final bool isRoot;
  final bool isLast;
  final bool isSelected;
  final bool isCurrent;
  final bool isMainline;
  final bool isExpanded;
  final String title;
  final String subtitle;
  final String? badge;
  final String charCount;
  final VoidCallback onToggleSelect;
  final VoidCallback onToggleExpand;
  final Color primary;

  const _TreeNode({
    required this.isRoot,
    required this.isLast,
    required this.isSelected,
    this.isCurrent = false,
    this.isMainline = false,
    required this.isExpanded,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.charCount,
    required this.onToggleSelect,
    required this.onToggleExpand,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 树形连接线
          SizedBox(
            width: isRoot ? 0 : 24,
            child: isRoot
                ? null
                : CustomPaint(
                    painter: _TreeLinePainter(
                      isLast: isLast,
                      color: Colors.grey[300]!,
                    ),
                  ),
          ),

          // 内容区
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: isRoot ? 0 : 8,
                bottom: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected ? primary.withAlpha(8) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? primary.withAlpha(80)
                      : isMainline
                          ? Colors.amber.withAlpha(150)
                          : Colors.grey[200]!,
                  width: isSelected || isMainline ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 标题行
                  InkWell(
                    onTap: onToggleExpand,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Row(
                        children: [
                          // 勾选框
                          GestureDetector(
                            onTap: onToggleSelect,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isSelected ? primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected ? primary : Colors.grey[350]!,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 图标
                          Icon(
                            isRoot ? Icons.help_outline : Icons.smart_toy_outlined,
                            size: 16,
                            color: isRoot ? Colors.blue : (isMainline ? Colors.amber[700] : Colors.grey[500]),
                          ),
                          const SizedBox(width: 6),

                          // 标题
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
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
                                if (isMainline) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '推荐',
                                      style: TextStyle(fontSize: 9, color: Colors.amber[800], fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 选择计数
                          if (badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? primary.withAlpha(20) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? primary : Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // 字数
                          Text(
                            charCount,
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 4),

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

                  // 预览/全文
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: Text(
                        _getPreviewText(subtitle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isEmptyContent(subtitle) ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                          fontStyle: _isEmptyContent(subtitle) ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                    secondChild: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.5),
                        ),
                      ),
                    ),
                    crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
}

/// 树形连接线画笔
class _TreeLinePainter extends CustomPainter {
  final bool isLast;
  final Color color;

  _TreeLinePainter({required this.isLast, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 垂直线
    if (!isLast) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, 20),
        paint,
      );
    }

    // 水平线
    canvas.drawLine(
      Offset(size.width / 2, 20),
      Offset(size.width, 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============ 数据模型 ============

class _QuestionGroup {
  final int index;
  final String question;
  final List<_ReplyItem> replies;

  _QuestionGroup({
    required this.index,
    required this.question,
    required this.replies,
  });

  String get questionId => 'q_$index';
}

class _ReplyItem {
  final String id;
  final String modelName;
  final String content;
  final bool isMainline;
  final int charCount;

  _ReplyItem({
    required this.id,
    required this.modelName,
    required this.content,
    required this.isMainline,
    required this.charCount,
  });
}

// ============ 辅助函数 ============

/// 智能提取预览文本：跳过空行，找到第一段有意义的内容
String _getPreviewText(String content) {
  if (content.isEmpty) return '（暂无内容）';

  // 按行分割，找第一个非空行
  final lines = content.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }

  return '（仅空白 · ${content.length}字）';
}

/// 判断内容是否为空或仅空白
bool _isEmptyContent(String content) {
  return content.isEmpty || content.trim().isEmpty;
}
