import 'package:flutter/material.dart';

import '../models/isar/perspective_entity.dart';
import '../widgets/unified_markdown_renderer.dart';
import '../services/insight_service.dart';
import '../services/perspective_storage.dart';
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

  // 视角（按分组组织）
  Map<String, List<PerspectiveEntity>> _groupedPerspectives = {};
  String? _selectedPerspectiveId;

  // 选中的提问
  List<QueryItem> _selectedQueries = [];
  
  // 助手筛选
  List<Map<String, String>> _assistants = [];  // 全部助手列表
  Set<String> _selectedAssistants = {};  // 选中的助手名称
  int _assistantFilterVersion = 0;  // 用于重建 QuerySelectorCompactStyle

  // 状态
  bool _isLoading = true;
  bool _isGenerating = false;
  String _streamingContent = '';
  bool _showResult = false;  // 显示生成结果

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    await _loadAssistants();
    await _loadPerspectives();
  }

  Future<void> _loadAssistants() async {
    try {
      final assistants = await _service.getAssistantList();
      final allNames = assistants
          .map((a) => a['name'] ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
      setState(() {
        _assistants = assistants;
        _selectedAssistants = allNames;  // 默认全选
      });
    } catch (e) {
      print('❌ 加载助手列表失败: $e');
    }
  }

  Future<void> _loadPerspectives() async {
    setState(() => _isLoading = true);

    try {
      // 按分组加载启用的视角
      final grouped = await _service.getEnabledPerspectivesGrouped();
      setState(() {
        _groupedPerspectives = grouped;
        
        // 设置默认选中的视角（优先内置分组，其次自定义分组）
        if (_selectedPerspectiveId == null && grouped.isNotEmpty) {
          // 优先从内置分组选择
          // 1. 尝试默认选中 "朋友视角"
          // ignore: unnecessary_cast
          final friendPerspectives = grouped.values
              .expand((list) => list)
              .where((p) => p.perspectiveId == 'builtin_friend_perspective')
              .toList();

          if (friendPerspectives.isNotEmpty) {
            _selectedPerspectiveId = friendPerspectives.first.perspectiveId;
          } else {
            // 2. 否则按默认顺序选择
            for (final category in BuiltinPerspectives.categoryOrder) {
              if (grouped.containsKey(category) && grouped[category]!.isNotEmpty) {
                _selectedPerspectiveId = grouped[category]!.first.perspectiveId;
                break;
              }
            }
          }
          // 如果没有内置分组，从任意分组选择第一个
          _selectedPerspectiveId ??= grouped.values.first.first.perspectiveId;
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
    // 从 QuerySelectorCompactStyle 同步助手筛选状态
    if (filters != null) {
      setState(() => _selectedAssistants = filters);
    } else {
      // null 表示全选
      final allNames = _assistants
          .map((a) => a['name'] ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
      setState(() => _selectedAssistants = allNames);
    }
  }

  void _onPerspectiveSelected(PerspectiveEntity perspective) {
    setState(() {
      _selectedPerspectiveId = perspective.perspectiveId;
    });
  }

  // ============ 弹窗 ============

  void _showPerspectiveDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildPerspectiveSheet(),
    );
  }

  void _showAssistantDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildAssistantSheet(),
    );
  }

  Widget _buildAssistantSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allNames = _assistants
        .map((a) => a['name'] ?? '')
        .where((n) => n.isNotEmpty)
        .toSet();
    
    return StatefulBuilder(
      builder: (context, setSheetState) {
        final allSelected = _selectedAssistants.length == allNames.length;
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // 拖动手柄
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Text('选择要分析的助手', style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            if (allSelected) {
                              _selectedAssistants.clear();
                            } else {
                              _selectedAssistants = Set.from(allNames);
                            }
                          });
                        },
                        child: Text(allSelected ? '取消全选' : '全选'),
                      ),
                    ],
                  ),
                ),
                // 助手列表
                Expanded(
                  child: FutureBuilder<List<AssistantStats>>(
                    future: _service.getAssistantStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final stats = snapshot.data!;
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: stats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _buildAssistantCard(
                            stats[index],
                            theme,
                            colorScheme,
                            setSheetState,
                          );
                        },
                      );
                    },
                  ),
                ),
                // 底部按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedAssistants.isEmpty ? null : () {
                        setState(() {
                          _assistantFilterVersion++;
                        });
                        Navigator.pop(context);
                      },
                      child: Text('确认 (已选 ${_selectedAssistants.length}/${allNames.length})'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssistantCard(
    AssistantStats stats,
    ThemeData theme,
    ColorScheme colorScheme,
    StateSetter setSheetState,
  ) {
    final isSelected = _selectedAssistants.contains(stats.name);
    
    // 格式化时间
    String timeText = '';
    if (stats.latestTime != null) {
      final now = DateTime.now();
      final diff = now.difference(stats.latestTime!);
      if (diff.inDays == 0) {
        timeText = '今天更新';
      } else if (diff.inDays == 1) {
        timeText = '昨天更新';
      } else if (diff.inDays < 7) {
        timeText = '${diff.inDays}天前更新';
      } else if (diff.inDays < 30) {
        timeText = '${diff.inDays ~/ 7}周前更新';
      } else if (diff.inDays < 365) {
        timeText = '${diff.inDays ~/ 30}月前更新';
      } else {
        timeText = '${diff.inDays ~/ 365}年前更新';
      }
    }
    
    return Material(
      color: isSelected 
          ? colorScheme.primary.withValues(alpha: 0.06)
          : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setSheetState(() {
            if (isSelected) {
              _selectedAssistants.remove(stats.name);
            } else {
              _selectedAssistants.add(stats.name);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // 勾选框
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: 14),
              // 助手信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${stats.topicCount} 个话题',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        if (stats.messageCount > 0) ...[
                          Text(
                            ' · ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          Text(
                            '${stats.messageCount} 条提问',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                        if (timeText.isNotEmpty) ...[
                          Text(
                            ' · ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          Text(
                            timeText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerspectiveSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 统计总视角数
    int totalCount = 0;
    for (final perspectives in _groupedPerspectives.values) {
      totalCount += perspectives.length;
    }
    
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 拖动手柄
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text('发现洞察视角', style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                  const Spacer(),
                  Text(
                    '共 $totalCount 个',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            // 分类横向滚动列表
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // 按分类顺序构建横向滚动行
                  for (final category in BuiltinPerspectives.categoryOrder)
                    if (_groupedPerspectives.containsKey(category) &&
                        _groupedPerspectives[category]!.isNotEmpty)
                      _buildCategoryRow(
                        category,
                        _groupedPerspectives[category]!,
                        theme,
                        colorScheme,
                      ),
                  // 自定义分类
                  for (final category in _groupedPerspectives.keys)
                    if (!BuiltinPerspectives.categoryOrder.contains(category) &&
                        _groupedPerspectives[category]!.isNotEmpty)
                      _buildCategoryRow(
                        category,
                        _groupedPerspectives[category]!,
                        theme,
                        colorScheme,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分类行（标题 + 横向滚动卡片）
  Widget _buildCategoryRow(
    String category,
    List<PerspectiveEntity> perspectives,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final displayName = BuiltinPerspectives.categoryOrder.contains(category)
        ? BuiltinPerspectives.getCategoryDisplayName(category)
        : category;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类标题
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // 横向滚动卡片列表
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: perspectives.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildHorizontalCard(perspectives[index], theme, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  /// 构建横向滚动卡片
  Widget _buildHorizontalCard(
    PerspectiveEntity perspective,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = perspective.perspectiveId == _selectedPerspectiveId;
    
    return GestureDetector(
      onTap: () {
        _onPerspectiveSelected(perspective);
        Navigator.pop(context);
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标 + 选中标记
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(perspective.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // 标题
            Text(
              perspective.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 描述
            Expanded(
              child: Text(
                perspective.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 获取助手筛选摘要 ============

  String _getAssistantSummary() {
    final allNames = _assistants
        .map((a) => a['name'] ?? '')
        .where((n) => n.isNotEmpty)
        .toSet();
    final allSelected = _selectedAssistants.length == allNames.length;
    return allSelected
        ? '全部助手'
        : _selectedAssistants.length == 1
            ? _selectedAssistants.first
            : '${_selectedAssistants.length}个助手';
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
      final allNames = _assistants
          .map((a) => a['name'] ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
      final allSelected = _selectedAssistants.length == allNames.length;
      final filterLabel = allSelected
          ? '全部'
          : _selectedAssistants.length == 1
              ? _selectedAssistants.first
              : '${_selectedAssistants.length}个助手';

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

      // 生成完成后显示结果
      if (mounted) {
        setState(() {
          _showResult = true;
        });
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

  void _openHistoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InsightHistoryView(),
      ),
    );
  }

  void _resetToSelection() {
    setState(() {
      _showResult = false;
      _streamingContent = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 正在生成或已有结果时显示生成/结果视图
    final showGeneratingOrResult = _isGenerating || _showResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 洞察'),
        leading: showGeneratingOrResult
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _resetToSelection,
                tooltip: '返回选择',
              )
            : null,
        actions: [
          TextButton.icon(
            onPressed: _openHistoryPage,
            icon: const Icon(Icons.history),
            label: const Text('历史洞察'),
          ),
        ],
      ),
      body: showGeneratingOrResult
          ? _buildGeneratingView(theme, colorScheme)
          : _buildMainView(theme, colorScheme),
    );
  }

  Widget _buildGeneratingView(ThemeData theme, ColorScheme colorScheme) {
    final selectedPerspective = _findSelectedPerspective();

    return Column(
      children: [
        // 状态栏 - 根据状态显示不同内容
        if (_isGenerating)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  width: 18,
                  height: 18,
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
                  onPressed: _resetToSelection,
                  child: const Text('取消'),
                ),
              ],
            ),
          )
        else if (_showResult)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '洞察生成完成',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.tertiary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _startInsight,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重新生成'),
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
        // 双下拉筛选器
        _buildDualDropdown(theme, colorScheme),

        // 话题选择（占据剩余空间）
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: QuerySelectorCompactStyle(
              key: ValueKey('assistant_filter_$_assistantFilterVersion'),
              onSelectionChanged: _onSelectionChanged,
              onAssistantFilterChanged: _onAssistantFilterChanged,
              initialAssistantFilters: _selectedAssistants,
            ),
          ),
        ),

        // 底部按钮
        _buildBottomButton(colorScheme),
      ],
    );
  }

  /// 双下拉筛选器
  Widget _buildDualDropdown(ThemeData theme, ColorScheme colorScheme) {
    final selectedPerspective = _findSelectedPerspective();
    final categoryColor = selectedPerspective != null
        ? BuiltinPerspectives.categoryColors[selectedPerspective.category] ?? colorScheme.primary
        : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // 视角下拉
          Expanded(
            child: _buildDropdownButton(
              context: context,
              icon: selectedPerspective?.icon ?? '🔮',
              label: selectedPerspective?.name ?? '选择视角',
              color: categoryColor,
              onTap: _showPerspectiveDialog,
            ),
          ),
          const SizedBox(width: 12),
          // 助手下拉
          Expanded(
            child: _buildDropdownButton(
              context: context,
              icon: '👤',
              label: _getAssistantSummary(),
              color: colorScheme.secondary,
              onTap: _showAssistantDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton({
    required BuildContext context,
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 查找当前选中的视角
  PerspectiveEntity? _findSelectedPerspective() {
    for (final perspectives in _groupedPerspectives.values) {
      for (final p in perspectives) {
        if (p.perspectiveId == _selectedPerspectiveId) {
          return p;
        }
      }
    }
    return null;
  }

  /// 底部按钮
  Widget _buildBottomButton(ColorScheme colorScheme) {
    final selectedPerspective = _findSelectedPerspective();

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
