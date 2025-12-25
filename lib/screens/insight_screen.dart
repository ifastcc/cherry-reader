import 'package:flutter/material.dart';

import '../models/isar/perspective_entity.dart';
import '../widgets/unified_markdown_renderer.dart';
import '../services/insight_service.dart';
import '../widgets/query_selector_compact_style.dart';
import '../widgets/insight_history_view.dart';

/// 洞察页面
///
/// AI 洞察功能的主页面
class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final _service = InsightService.instance;

  // 视角
  List<PerspectiveEntity> _perspectives = [];
  String? _selectedPerspectiveId;

  // 选中的提问
  List<QueryItem> _selectedQueries = [];
  Set<String>? _assistantFilters;  // 多选助手过滤

  // 状态
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _showHistory = false;
  String _streamingContent = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    await _loadPerspectives();
  }

  Future<void> _loadPerspectives() async {
    setState(() => _isLoading = true);

    try {
      // 只加载启用的视角
      final perspectives = await _service.getEnabledPerspectives();
      setState(() {
        _perspectives = perspectives;
        if (perspectives.isNotEmpty && _selectedPerspectiveId == null) {
          _selectedPerspectiveId = perspectives.first.perspectiveId;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 加载视角失败: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSelectionChanged(List<QueryItem> queries) {
    setState(() {
      _selectedQueries = queries;
    });
  }

  void _onAssistantFilterChanged(Set<String>? filters) {
    setState(() {
      _assistantFilters = filters;
    });
  }

  void _onPerspectiveSelected(PerspectiveEntity perspective) {
    setState(() {
      _selectedPerspectiveId = perspective.perspectiveId;
    });
  }

  Future<void> _startInsight() async {
    if (_selectedQueries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要分析的提问')),
      );
      return;
    }

    if (_selectedPerspectiveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分析视角')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _streamingContent = '';
    });

    try {
      // 计算 timeRangeLabel
      final filterLabel = _assistantFilters == null || _assistantFilters!.isEmpty
          ? '全部'
          : _assistantFilters!.length == 1
              ? _assistantFilters!.first
              : '${_assistantFilters!.length}个助手';

      await for (final chunk in _service.generateInsightStream(
        perspectiveId: _selectedPerspectiveId!,
        selectedQueries: _selectedQueries,
        assistantFilter: filterLabel,
        timeRangeLabel: filterLabel,
      )) {
        if (!mounted) break;
        setState(() {
          _streamingContent += chunk;
        });
      }

      // 生成完成后显示历史
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('洞察生成完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 洞察'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showHistory = true),
            icon: const Icon(Icons.history),
            label: const Text('历史洞察'),
          ),
        ],
      ),
      body: _showHistory
          ? _buildHistoryView()
          : _isGenerating
              ? _buildGeneratingView(theme, colorScheme)
              : _buildMainView(theme, colorScheme),
    );
  }

  Widget _buildHistoryView() {
    return InsightHistoryView(
      onClose: () => setState(() => _showHistory = false),
    );
  }

  Widget _buildGeneratingView(ThemeData theme, ColorScheme colorScheme) {
    final selectedPerspective = _perspectives
        .where((p) => p.perspectiveId == _selectedPerspectiveId)
        .firstOrNull;

    return Column(
      children: [
        // 状态栏
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '正在生成洞察...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isGenerating = false;
                    _streamingContent = '';
                  });
                },
                child: const Text('取消'),
              ),
            ],
          ),
        ),

        // 内容
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 视角标题
                if (selectedPerspective != null)
                  Row(
                    children: [
                      Text(
                        selectedPerspective.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedPerspective.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // 流式内容
                if (_streamingContent.isNotEmpty)
                  UnifiedMarkdownRenderer(
                    data: _streamingContent,
                    selectable: true,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainView(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 视角选择（横向滚动 Chips，固定在顶部）
        _buildPerspectiveChips(theme, colorScheme),

        // 话题选择（占据剩余空间）
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: QuerySelectorCompactStyle(
              onSelectionChanged: _onSelectionChanged,
              onAssistantFilterChanged: _onAssistantFilterChanged,
            ),
          ),
        ),

        // 底部按钮
        _buildBottomButton(colorScheme),
      ],
    );
  }

  /// 视角选择 Chips（横向滚动）
  Widget _buildPerspectiveChips(ThemeData theme, ColorScheme colorScheme) {
    final selectedPerspective = _perspectives
        .where((p) => p.perspectiveId == _selectedPerspectiveId)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签行
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '分析视角',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (selectedPerspective != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${selectedPerspective.icon} ${selectedPerspective.name}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Chips 横向滚动
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _perspectives.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final perspective = _perspectives[index];
                final isSelected = perspective.perspectiveId == _selectedPerspectiveId;

                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Text(
                    perspective.icon,
                    style: const TextStyle(fontSize: 14),
                  ),
                  label: Text(perspective.name),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (_) => _onPerspectiveSelected(perspective),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 底部按钮
  Widget _buildBottomButton(ColorScheme colorScheme) {
    final selectedPerspective = _perspectives
        .where((p) => p.perspectiveId == _selectedPerspectiveId)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _selectedQueries.isEmpty || _selectedPerspectiveId == null
                ? null
                : _startInsight,
            icon: const Icon(Icons.insights),
            label: Text(
              _selectedQueries.isEmpty
                  ? '请选择提问'
                  : selectedPerspective != null
                      ? '${selectedPerspective.icon} 开始洞察 (${_selectedQueries.length} 条)'
                      : '开始洞察 (${_selectedQueries.length} 条)',
            ),
          ),
        ),
      ),
    );
  }

}
