import 'package:flutter/material.dart';
import '../models/isar/prompt_template_entity.dart';
import '../models/isar/unified_conversation_entity.dart';

/// 分析确认视图
///
/// 设计理念：首次进入时的"确认页面"
/// - 清晰展示即将分析的内容（Context 预览）
/// - 选择分析模板
/// - 可选追加问题
/// - 一键开始分析
///
/// 替代原来的 ContextBanner + 空白欢迎页 + 底部输入框分散布局
class AnalysisConfirmView extends StatefulWidget {
  /// Context 数据（结构化）
  final Map<String, dynamic>? contextData;

  /// Context 快照（Markdown）
  final String? contextSnapshot;

  /// 上下文类型
  final ConversationContextType contextType;

  /// 当前轮次索引
  final int? currentRoundIndex;

  /// 可用模板列表
  final List<TaskTemplateEntity> templates;

  /// 默认选中的模板
  final TaskTemplateEntity? selectedTemplate;

  /// 模板变更回调
  final void Function(TaskTemplateEntity?)? onTemplateChanged;

  /// 编辑 Context 回调
  final VoidCallback? onEditContext;

  /// 开始分析回调（传入追加问题）
  final void Function(String? additionalQuery)? onStartAnalysis;

  /// 当前模型名称
  final String? modelName;

  const AnalysisConfirmView({
    super.key,
    this.contextData,
    this.contextSnapshot,
    this.contextType = ConversationContextType.topic,
    this.currentRoundIndex,
    required this.templates,
    this.selectedTemplate,
    this.onTemplateChanged,
    this.onEditContext,
    this.onStartAnalysis,
    this.modelName,
  });

  @override
  State<AnalysisConfirmView> createState() => _AnalysisConfirmViewState();
}

class _AnalysisConfirmViewState extends State<AnalysisConfirmView> {
  final _queryController = TextEditingController();
  late TaskTemplateEntity? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.selectedTemplate;
  }

  @override
  void didUpdateWidget(AnalysisConfirmView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTemplate != widget.selectedTemplate) {
      _selectedTemplate = widget.selectedTemplate;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<_RoundPreview> _parseRounds() {
    final rounds = <_RoundPreview>[];

    if (widget.contextData != null && widget.contextData!['rounds'] != null) {
      final roundsData = widget.contextData!['rounds'] as List<dynamic>? ?? [];
      for (var i = 0; i < roundsData.length; i++) {
        final roundData = roundsData[i] as Map<String, dynamic>;
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

        final replyCount = repliesData.length;
        final models = repliesData.map((r) {
          final model = (r as Map<String, dynamic>)['model'] as Map<String, dynamic>?;
          return model?['name'] as String? ?? 'Unknown';
        }).toList();

        rounds.add(_RoundPreview(
          index: i,
          question: question,
          replyCount: replyCount,
          models: models,
          isCurrent: widget.currentRoundIndex == i,
        ));
      }
    }

    return rounds;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final rounds = _parseRounds();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题区域
          _buildHeader(primary),

          const SizedBox(height: 24),

          // Context 预览卡片
          _buildContextPreview(rounds, primary),

          const SizedBox(height: 20),

          // 模板选择
          _buildTemplateSection(primary),

          const SizedBox(height: 20),

          // 追加问题输入
          _buildQueryInput(primary),

          const SizedBox(height: 24),

          // 开始分析按钮
          _buildStartButton(primary),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.psychology_outlined, size: 24, color: primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '分析确认',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '确认分析内容和模板',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (widget.modelName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  widget.modelName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContextPreview(List<_RoundPreview> rounds, Color primary) {
    if (rounds.isEmpty) {
      return _buildEmptyContext();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Context',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${rounds.length} 轮对话',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.onEditContext != null)
                  TextButton.icon(
                    onPressed: widget.onEditContext,
                    icon: Icon(Icons.edit_outlined, size: 16, color: primary),
                    label: Text(
                      '编辑',
                      style: TextStyle(fontSize: 13, color: primary),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
          ),

          // 轮次预览列表
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < rounds.length && i < 5; i++)
                  _buildRoundCard(rounds[i], primary),
                if (rounds.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... 还有 ${rounds.length - 5} 轮',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundCard(_RoundPreview round, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: round.isCurrent ? primary.withAlpha(10) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: round.isCurrent ? primary.withAlpha(60) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 轮次编号
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: round.isCurrent ? primary : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${round.index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: round.isCurrent ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 问题内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  round.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildMiniTag(
                      '${round.replyCount} 回复',
                      Icons.chat_bubble_outline,
                      Colors.grey,
                    ),
                    ...round.models.take(3).map((m) => _buildMiniTag(
                      m,
                      Icons.smart_toy_outlined,
                      Colors.blue,
                    )),
                  ],
                ),
              ],
            ),
          ),

          // 当前标记
          if (round.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '当前',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContext() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '无上下文内容',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: Colors.purple[400]),
              const SizedBox(width: 8),
              const Text(
                '分析模板',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_selectedTemplate != null)
                TextButton(
                  onPressed: () => _showTemplateContent(_selectedTemplate!),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '查看内容',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 模板选择 Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTemplateChip(null, '不使用模板', primary),
              ...widget.templates.map((t) => _buildTemplateChip(t, t.name, primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(TaskTemplateEntity? template, String label, Color primary) {
    final isSelected = _selectedTemplate?.templateId == template?.templateId;

    // 根据模板类型获取图标和颜色
    IconData? typeIcon;
    Color? typeColor;
    if (template != null) {
      switch (template.targetType) {
        case TemplateTargetType.multiModel:
          typeIcon = Icons.compare_arrows;
          typeColor = Colors.blue;
          break;
        case TemplateTargetType.singleReply:
          typeIcon = Icons.chat_bubble_outline;
          typeColor = Colors.green;
          break;
        case TemplateTargetType.any:
          typeIcon = null; // 通用类型不显示图标
          break;
      }
    }

    return InkWell(
      onTap: () {
        setState(() => _selectedTemplate = template);
        widget.onTemplateChanged?.call(template);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withAlpha(30) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (typeIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  typeIcon,
                  size: 14,
                  color: isSelected ? typeColor : typeColor?.withAlpha(150),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.purple : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.check, size: 14, color: Colors.purple[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryInput(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 18, color: Colors.blue[400]),
              const SizedBox(width: 8),
              const Text(
                '追加问题',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(可选)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _queryController,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: '输入你想额外问的问题...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primary),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(Color primary) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          final query = _queryController.text.trim();
          widget.onStartAnalysis?.call(query.isEmpty ? null : query);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              '开始分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateContent(TaskTemplateEntity template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description, color: Colors.purple[400], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                template.name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              template.content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 轮次预览数据
class _RoundPreview {
  final int index;
  final String question;
  final int replyCount;
  final List<String> models;
  final bool isCurrent;

  _RoundPreview({
    required this.index,
    required this.question,
    required this.replyCount,
    required this.models,
    required this.isCurrent,
  });
}
