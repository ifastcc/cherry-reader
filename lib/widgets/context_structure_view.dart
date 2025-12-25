import 'dart:convert';
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

    // 优先从 contextDataJson 解析（必须非空且有内容）
    if (widget.contextDataJson != null && widget.contextDataJson!.isNotEmpty) {
      _parseFromJson(widget.contextDataJson!);

      // 【补充预览】如果同时有 contextSnapshot，从中提取预览内容
      if (widget.contextSnapshot != null && widget.contextSnapshot!.isNotEmpty) {
        _supplementPreviewFromSnapshot(widget.contextSnapshot!);
      }
    }
    // 否则从 contextSnapshot 解析（必须非空且有内容）
    else if (widget.contextSnapshot != null && widget.contextSnapshot!.isNotEmpty) {
      _parseFromSnapshot(widget.contextSnapshot!);
    }

    // 计算摘要
    _calculateSummary();
  }

  /// 从 contextSnapshot 中补充预览内容到已解析的 rounds
  void _supplementPreviewFromSnapshot(String snapshot) {
    if (_rounds.isEmpty) return;

    // 单回复模式（只有一个回复）：直接用整个 snapshot 作为预览源
    if (_rounds.length == 1 && _rounds[0].replies.length == 1) {
      final preview = _extractPreview(snapshot, 150);
      final oldReply = _rounds[0].replies[0];
      _rounds[0] = _RoundInfo(
        index: 0,
        questionSelected: _rounds[0].questionSelected,
        questionPreview: _rounds[0].questionPreview,
        replies: [
          _ReplyInfo(
            model: oldReply.model,
            charCount: oldReply.charCount,
            selected: oldReply.selected,
            preview: preview,
          ),
        ],
      );
      return;
    }

    // 多轮模式：尝试从 Markdown 格式中提取每个模型的内容
    // 如果不是 Markdown 格式，就无法精确匹配，跳过
    if (!snapshot.contains('##')) return;

    // 解析 Markdown 获取每个模型的内容
    final modelContents = <String, String>{};
    final sections = snapshot.split('##').where((s) => s.trim().isNotEmpty);

    for (final section in sections) {
      if (section.trim().startsWith('模型回复')) {
        final replyBlocks = section.split('###').where((s) => s.trim().isNotEmpty).skip(1);
        for (final block in replyBlocks) {
          final lines = block.trim().split('\n');
          if (lines.isEmpty) continue;

          final modelLine = lines.first.trim();
          final content = lines.skip(1).join('\n').trim();
          String modelName = modelLine.contains(':')
              ? modelLine.split(':').last.trim()
              : modelLine;

          modelContents[modelName] = content;
        }
      }
    }

    // 补充预览到现有 rounds
    for (var i = 0; i < _rounds.length; i++) {
      final round = _rounds[i];
      final updatedReplies = <_ReplyInfo>[];

      for (final reply in round.replies) {
        final content = modelContents[reply.model];
        final preview = content != null ? _extractPreview(content, 60) : null;

        updatedReplies.add(_ReplyInfo(
          model: reply.model,
          charCount: reply.charCount,
          selected: reply.selected,
          preview: preview ?? reply.preview,
        ));
      }

      _rounds[i] = _RoundInfo(
        index: round.index,
        questionSelected: round.questionSelected,
        questionPreview: round.questionPreview,
        replies: updatedReplies,
      );
    }
  }

  void _parseFromJson(String json) {
    // 使用 Dart JSON 解析器（更可靠）
    try {
      final data = _parseJsonSafe(json);
      if (data == null) return;

      final type = data['type'] as String?;

      if (type == 'single') {
        // 单回复模式
        final modelName = data['modelName'] as String? ?? 'AI';
        final charCount = data['charCount'] as int? ?? 0;

        _rounds = [
          _RoundInfo(
            index: 0,
            questionSelected: false,
            questionPreview: null,
            replies: [
              _ReplyInfo(
                model: modelName,
                charCount: charCount,
                selected: true,
              ),
            ],
          ),
        ];
      } else if (type == 'multi') {
        // 多轮模式
        final rounds = data['rounds'] as List<dynamic>?;
        if (rounds == null) return;

        for (final roundData in rounds) {
          if (roundData is! Map<String, dynamic>) continue;

          final index = roundData['index'] as int? ?? 0;
          final questionPreview = roundData['questionPreview'] as String?;
          final repliesData = roundData['replies'] as List<dynamic>? ?? [];

          final replies = <_ReplyInfo>[];
          for (final replyData in repliesData) {
            if (replyData is! Map<String, dynamic>) continue;

            final model = replyData['model'] as String? ?? 'Unknown';
            final charCount = replyData['charCount'] as int? ?? 0;

            replies.add(_ReplyInfo(
              model: model,
              charCount: charCount,
              selected: true,
            ));
          }

          _rounds.add(_RoundInfo(
            index: index,
            questionSelected: questionPreview != null,
            questionPreview: questionPreview,
            replies: replies,
          ));
        }
      }
    } catch (e) {
      // JSON 解析失败，回退到旧的正则解析
      _parseFromJsonLegacy(json);
    }
  }

  /// 安全解析 JSON
  Map<String, dynamic>? _parseJsonSafe(String json) {
    try {
      // 使用 dart:convert 的 jsonDecode
      final dynamic result = jsonDecode(json);
      if (result is Map<String, dynamic>) {
        return result;
      }
    } catch (_) {}
    return null;
  }

  /// 旧的正则解析（备用）
  void _parseFromJsonLegacy(String json) {
    final isSingle = json.contains('"type":"single"');

    if (isSingle) {
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
    }
  }

  void _parseFromSnapshot(String snapshot) {
    // 从 markdown 格式解析
    // ## 用户问题
    // ...
    // ## 模型回复
    // ### Model1
    // ...

    // 【修复】如果不是 markdown 格式（没有 ## 分隔符），将整个内容作为单条回复处理
    if (!snapshot.contains('##')) {
      // 提取预览：单回复显示更多内容（3行约150字符）
      final preview = _extractPreview(snapshot, 150);
      _rounds = [
        _RoundInfo(
          index: 0,
          questionSelected: false,
          questionPreview: null,
          replies: [
            _ReplyInfo(
              model: '原文内容',
              charCount: snapshot.length,
              selected: true,
              preview: preview,
            ),
          ],
        ),
      ];
      return;
    }

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

          // 多回复模式：每个回复显示 1 行预览（约 60 字符）
          final preview = _extractPreview(content, 60);

          currentReplies.add(_ReplyInfo(
            model: modelName,
            charCount: content.length,
            selected: true,
            preview: preview,
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

  /// 提取内容预览
  ///
  /// 清理换行和多余空格，截取指定长度
  String _extractPreview(String content, int maxLength) {
    if (content.isEmpty) return '';

    // 清理内容：替换多个换行为单个空格，去除首尾空白
    final cleaned = content
        .replaceAll(RegExp(r'\n+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.length <= maxLength) return cleaned;

    // 尝试在单词边界截断
    final truncated = cleaned.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');
    if (lastSpace > maxLength * 0.7) {
      return '${truncated.substring(0, lastSpace)}...';
    }
    return '$truncated...';
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

            // 判断是否为单回复模式（显示更多预览）
            final isSingleReply = round.replies.length == 1 && _rounds.length == 1;

            return _buildTreeNode(
              isRoot: !hasQuestion,
              isLast: isLastReply,
              title: reply.model,
              subtitle: reply.charCount > 0 ? '${_formatCharCount(reply.charCount)}字' : null,
              isSelected: reply.selected,
              icon: Icons.smart_toy_outlined,
              color: Colors.purple,
              preview: reply.preview,
              showMultilinePreview: isSingleReply,  // 单回复显示多行预览
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
    String? preview,
    bool showMultilinePreview = false,
  }) {
    // 单回复显示多行预览布局
    if (showMultilinePreview && preview != null && preview.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: isRoot ? 0 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：勾选 + 图标 + 标题 + 字数
            Row(
              children: [
                // 勾选图标
                Container(
                  width: 16,
                  height: 16,
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
                Icon(icon, size: 14, color: color.withOpacity(0.8)),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // 第二行：预览内容（多行）
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 6),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  preview,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 多回复模式：一行显示（标题 + 字数 + 预览）
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

          // 字数
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],

          // 预览（多回复模式下显示在同一行）
          if (preview != null && preview.isNotEmpty && !showMultilinePreview) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                preview,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
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
  final String? preview;  // 内容预览

  _ReplyInfo({
    required this.model,
    required this.charCount,
    required this.selected,
    this.preview,
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
