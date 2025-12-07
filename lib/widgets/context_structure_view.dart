import 'package:flutter/material.dart';

/// 上下文结构视图（只读）
///
/// 用于在聊天消息中展示 context 的树形结构和选中状态
/// 特点：
/// - 只读，不可编辑
/// - 点击展开/收起
/// - 限制最大高度，超出内部滚动
/// - 展示多轮对话结构 + 勾选状态
class ContextStructureView extends StatefulWidget {
  /// 结构化的选中信息 JSON
  /// 格式: {"type":"multi","rounds":[{"index":0,"question":"..","replies":[{"model":"GPT-4","charCount":1234}]}]}
  final String? contextDataJson;

  /// 原始 contextSnapshot（用于解析结构）
  final String? contextSnapshot;

  /// 初始是否展开
  final bool initialExpanded;

  /// 最大展开高度
  final double maxExpandedHeight;

  const ContextStructureView({
    super.key,
    this.contextDataJson,
    this.contextSnapshot,
    this.initialExpanded = false,
    this.maxExpandedHeight = 200,
  });

  @override
  State<ContextStructureView> createState() => _ContextStructureViewState();
}

class _ContextStructureViewState extends State<ContextStructureView>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late List<_RoundInfo> _rounds;
  late _ContextSummary _summary;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialExpanded;
    _parseData();
  }

  @override
  void didUpdateWidget(ContextStructureView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contextDataJson != widget.contextDataJson ||
        oldWidget.contextSnapshot != widget.contextSnapshot) {
      _parseData();
    }
  }

  void _parseData() {
    _rounds = [];
    _summary = _ContextSummary();

    // 优先从 contextDataJson 解析
    if (widget.contextDataJson != null) {
      _parseFromJson(widget.contextDataJson!);
    }
    // 否则从 contextSnapshot 解析
    else if (widget.contextSnapshot != null) {
      _parseFromSnapshot(widget.contextSnapshot!);
    }

    // 计算摘要
    _calculateSummary();
  }

  void _parseFromJson(String json) {
    // 解析 type
    final isSingle = json.contains('"type":"single"');

    if (isSingle) {
      // 单回复模式
      final modelMatch = RegExp(r'"modelName":"([^"]*)"').firstMatch(json);
      final charMatch = RegExp(r'"charCount":(\d+)').firstMatch(json);

      _rounds = [
        _RoundInfo(
          index: 0,
          questionSelected: false,
          questionPreview: null,
          replies: [
            _ReplyInfo(
              model: modelMatch?.group(1) ?? 'AI',
              charCount: int.tryParse(charMatch?.group(1) ?? '0') ?? 0,
              selected: true,
            ),
          ],
        ),
      ];
    } else {
      // 多轮模式 - 解析新格式的 rounds
      // 新格式: {"index":0,"questionPreview":"...","replies":[{"model":"GPT-4","charCount":1234},...]}

      // 使用正则提取每个 round 的完整 JSON
      final roundPattern = RegExp(r'\{"index":(\d+)(?:,"questionPreview":"([^"]*)")?,"replies":\[(.*?)\]\}');
      final matches = roundPattern.allMatches(json);

      for (final match in matches) {
        final index = int.tryParse(match.group(1) ?? '0') ?? 0;
        final questionPreview = match.group(2)?.replaceAll('\\n', '\n');
        final repliesStr = match.group(3) ?? '';

        // 解析回复列表
        final replies = <_ReplyInfo>[];
        final replyPattern = RegExp(r'\{"model":"([^"]*)","charCount":(\d+)\}');
        final replyMatches = replyPattern.allMatches(repliesStr);

        for (final replyMatch in replyMatches) {
          replies.add(_ReplyInfo(
            model: replyMatch.group(1) ?? 'Unknown',
            charCount: int.tryParse(replyMatch.group(2) ?? '0') ?? 0,
            selected: true,
          ));
        }

        // 如果没有解析到回复，尝试旧格式兼容
        if (replies.isEmpty) {
          // 旧格式: "models":["GPT-4","Claude"]
          final oldModelsPattern = RegExp(r'"models":\[([^\]]*)\]');
          final oldMatch = oldModelsPattern.firstMatch(json);
          if (oldMatch != null) {
            final modelsStr = oldMatch.group(1) ?? '';
            final modelNames = RegExp(r'"([^"]*)"')
                .allMatches(modelsStr)
                .map((m) => m.group(1) ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
            for (final modelName in modelNames) {
              replies.add(_ReplyInfo(
                model: modelName,
                charCount: 0,
                selected: true,
              ));
            }
          }
        }

        _rounds.add(_RoundInfo(
          index: index,
          questionSelected: questionPreview != null,
          questionPreview: questionPreview,
          replies: replies,
        ));
      }

      // 如果新格式没有解析到，尝试完全旧格式兼容
      if (_rounds.isEmpty) {
        final oldRoundsPattern = RegExp(r'"index":(\d+),"replyCount":(\d+),"models":\[([^\]]*)\]');
        final oldMatches = oldRoundsPattern.allMatches(json);

        for (final match in oldMatches) {
          final index = int.tryParse(match.group(1) ?? '0') ?? 0;
          final replyCount = int.tryParse(match.group(2) ?? '0') ?? 0;
          final modelsStr = match.group(3) ?? '';

          final modelNames = RegExp(r'"([^"]*)"')
              .allMatches(modelsStr)
              .map((m) => m.group(1) ?? '')
              .where((s) => s.isNotEmpty)
              .toList();

          final replies = <_ReplyInfo>[];
          for (int i = 0; i < replyCount && i < modelNames.length; i++) {
            replies.add(_ReplyInfo(
              model: modelNames[i],
              charCount: 0,
              selected: true,
            ));
          }

          while (replies.length < replyCount) {
            replies.add(_ReplyInfo(
              model: '回复 ${replies.length + 1}',
              charCount: 0,
              selected: true,
            ));
          }

          _rounds.add(_RoundInfo(
            index: index,
            questionSelected: true,
            questionPreview: null,
            replies: replies,
          ));
        }
      }
    }
  }

  void _parseFromSnapshot(String snapshot) {
    // 从 markdown 格式解析
    // ## 用户问题
    // ...
    // ## 模型回复
    // ### Model1
    // ...

    final sections = snapshot.split('##').where((s) => s.trim().isNotEmpty).toList();

    String? currentQuestion;
    List<_ReplyInfo> currentReplies = [];
    int roundIndex = 0;

    for (var section in sections) {
      final lines = section.trim().split('\n');
      final header = lines.first.trim();

      if (header.startsWith('用户问题')) {
        // 如果已有问题，先保存
        if (currentQuestion != null || currentReplies.isNotEmpty) {
          _rounds.add(_RoundInfo(
            index: roundIndex++,
            questionSelected: currentQuestion != null,
            questionPreview: currentQuestion != null
                ? _truncate(currentQuestion, 50)
                : null,
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

          currentReplies.add(_ReplyInfo(
            model: modelName,
            charCount: content.length,
            selected: true,
          ));
        }
      }
    }

    // 保存最后一轮
    if (currentQuestion != null || currentReplies.isNotEmpty) {
      _rounds.add(_RoundInfo(
        index: roundIndex,
        questionSelected: currentQuestion != null,
        questionPreview: currentQuestion != null
            ? _truncate(currentQuestion, 50)
            : null,
        replies: currentReplies,
      ));
    }
  }

  void _calculateSummary() {
    int totalRounds = _rounds.length;
    int totalReplies = 0;
    int totalChars = widget.contextSnapshot?.length ?? 0;

    for (final round in _rounds) {
      totalReplies += round.replies.where((r) => r.selected).length;
    }

    _summary = _ContextSummary(
      roundCount: totalRounds,
      replyCount: totalReplies,
      charCount: totalChars,
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatCharCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else if (count > 0) {
      return '$count';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏（可点击展开/收起）
          _buildHeader(),

          // 展开的树形结构
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hasContent = _rounds.isNotEmpty;

    return InkWell(
      onTap: hasContent ? () => setState(() => _expanded = !_expanded) : null,
      borderRadius: BorderRadius.circular(_expanded ? 0 : 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // 图标
            Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 8),

            // 标题
            Text(
              '要讨论的内容',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(width: 8),

            // 摘要信息
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getSummaryText(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),

            // 展开/收起图标
            if (hasContent)
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.orange[600],
              ),
          ],
        ),
      ),
    );
  }

  String _getSummaryText() {
    if (_rounds.isEmpty) return '无内容';

    final parts = <String>[];

    if (_summary.roundCount > 1) {
      parts.add('${_summary.roundCount}轮');
    }

    if (_summary.replyCount > 0) {
      parts.add('${_summary.replyCount}条回复');
    }

    if (_summary.charCount > 0) {
      parts.add('${_formatCharCount(_summary.charCount)}字');
    }

    return parts.isEmpty ? '无内容' : parts.join(' · ');
  }

  Widget _buildExpandedContent() {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxExpandedHeight),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.orange.withOpacity(0.2)),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _rounds.map((round) => _buildRoundItem(round)).toList(),
        ),
      ),
    );
  }

  Widget _buildRoundItem(_RoundInfo round) {
    final isLastRound = round.index == _rounds.length - 1;

    return Padding(
      padding: EdgeInsets.only(bottom: isLastRound ? 0 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 问题行（如果有）
          if (round.questionSelected && round.questionPreview != null)
            _buildTreeNode(
              isRoot: true,
              isLast: round.replies.isEmpty,
              title: 'Q${round.index + 1}',
              subtitle: round.questionPreview,
              isSelected: true,
              icon: Icons.help_outline,
              color: Colors.blue,
            ),

          // 回复列表
          ...round.replies.asMap().entries.map((entry) {
            final replyIndex = entry.key;
            final reply = entry.value;
            final isLastReply = replyIndex == round.replies.length - 1;
            final hasQuestion = round.questionSelected && round.questionPreview != null;

            return _buildTreeNode(
              isRoot: !hasQuestion,
              isLast: isLastReply,
              title: reply.model,
              subtitle: reply.charCount > 0 ? '${_formatCharCount(reply.charCount)}字' : null,
              isSelected: reply.selected,
              icon: Icons.smart_toy_outlined,
              color: Colors.purple,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTreeNode({
    required bool isRoot,
    required bool isLast,
    required String title,
    String? subtitle,
    required bool isSelected,
    required IconData icon,
    required Color color,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 树形连接线
          if (!isRoot)
            SizedBox(
              width: 20,
              child: CustomPaint(
                painter: _TreeLinePainter(
                  isLast: isLast,
                  color: Colors.grey[300]!,
                ),
              ),
            ),

          // 勾选图标
          Container(
            width: 16,
            height: 16,
            margin: EdgeInsets.only(left: isRoot ? 0 : 4),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isSelected ? color : Colors.grey[350]!,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check, size: 10, color: color)
                : null,
          ),
          const SizedBox(width: 6),

          // 图标
          Icon(icon, size: 14, color: color.withOpacity(0.8)),
          const SizedBox(width: 4),

          // 标题
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),

          // 副标题
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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

    final midX = size.width / 2;
    final midY = size.height / 2;

    // 垂直线
    if (!isLast) {
      canvas.drawLine(
        Offset(midX, 0),
        Offset(midX, size.height),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(midX, 0),
        Offset(midX, midY),
        paint,
      );
    }

    // 水平线
    canvas.drawLine(
      Offset(midX, midY),
      Offset(size.width, midY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============ 数据模型 ============

class _RoundInfo {
  final int index;
  final bool questionSelected;
  final String? questionPreview;
  final List<_ReplyInfo> replies;

  _RoundInfo({
    required this.index,
    required this.questionSelected,
    this.questionPreview,
    required this.replies,
  });
}

class _ReplyInfo {
  final String model;
  final int charCount;
  final bool selected;

  _ReplyInfo({
    required this.model,
    required this.charCount,
    required this.selected,
  });
}

class _ContextSummary {
  final int roundCount;
  final int replyCount;
  final int charCount;

  _ContextSummary({
    this.roundCount = 0,
    this.replyCount = 0,
    this.charCount = 0,
  });
}
