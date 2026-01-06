import 'dart:ui';

import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';
import '../../services/knowledge_service.dart';
import '../../widgets/knowledge/knowledge_card.dart';
import '../../widgets/knowledge/quick_capture_sheet.dart';
import 'knowledge_editor_screen.dart';
import 'daily_review_screen.dart';

/// 知识库主页
///
/// 统一展示所有知识条目（不区分类型）
/// 时间线视图，按时间倒序显示
class KnowledgeHubScreen extends StatefulWidget {
  const KnowledgeHubScreen({super.key});

  @override
  State<KnowledgeHubScreen> createState() => KnowledgeHubScreenState();
}

class KnowledgeHubScreenState extends State<KnowledgeHubScreen> {
  final KnowledgeService _knowledgeService = KnowledgeService();

  // 状态
  List<KnowledgeItem> _items = [];
  List<String> _allTags = [];
  bool _isLoading = true;
  String? _error;

  // 筛选/搜索状态
  String? _selectedTag;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    setState(() {
      _isLoading = showLoading;
      _error = null;
    });

    try {
      // 并行加载数据
      final results = await Future.wait([
        _knowledgeService.getAllItems(),
        _knowledgeService.getAllTags(),
      ]);

      final items = results[0] as List<KnowledgeItem>;
      final tags = results[1] as List<String>;

      // 应用标签筛选
      List<KnowledgeItem> filteredItems = items;
      if (_selectedTag != null) {
        filteredItems = items
            .where((item) => item.tags.contains(_selectedTag))
            .toList();
      }

      // 应用搜索筛选
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filteredItems = filteredItems.where((item) {
          return item.content.toLowerCase().contains(query) ||
              (item.quotedText?.toLowerCase().contains(query) ?? false) ||
              item.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }

      setState(() {
        _items = filteredItems;
        _allTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: () => _loadData(showLoading: false),
        edgeOffset: 120,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildHeroHeader(context),
            if (_allTags.isNotEmpty)
              SliverToBoxAdapter(child: _buildTagFilter(context)),
            _buildContentArea(context),
          ],
        ),
      ),
    );
  }

  /// 处理主按钮点击
  void handleMainAction() {
    _handleCreateNote();
  }

  SliverAppBar _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 320,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.65),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                primary: false,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '知识库',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '快速查看、筛选和整理你的片段',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: '统计',
                            icon: const Icon(Icons.bar_chart_rounded),
                            onPressed: _showStatsDialog,
                          ),
                          IconButton(
                            tooltip: '刷新',
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: () => _loadData(showLoading: false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildHeroStat(
                            context,
                            label: '条目',
                            value: _items.length,
                            icon: Icons.auto_awesome_mosaic,
                          ),
                          const SizedBox(width: 10),
                          _buildHeroStat(
                            context,
                            label: '标签',
                            value: _allTags.length,
                            icon: Icons.tag,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildSearchField(context),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (_items.isNotEmpty)
                            FilledButton.icon(
                              onPressed: _handleDailyReview,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('每日回顾'),
                            ),
                          if (_items.isNotEmpty) const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.9),
                            ),
                            onPressed: _handleCreateNote,
                            icon: const Icon(Icons.add),
                            label: const Text('新建记录'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 标签筛选
  Widget _buildTagFilter(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemBuilder: (context, index) {
          final tag = _allTags[index];
          final isSelected = _selectedTag == tag;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedTag = isSelected ? null : tag);
              _loadData(showLoading: false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primary.withOpacity(0.85),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : theme.colorScheme.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : theme.colorScheme.outline.withOpacity(0.25),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tag,
                    size: 14,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _allTags.length,
      ),
    );
  }

  /// 内容区域（加载态、错误态、列表）
  Widget _buildContentArea(BuildContext context) {
    if (_isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                '正在整理你的知识...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(context),
      );
    }

    if (_items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: KnowledgeEmptyState(onCreateNote: _handleCreateNote),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const SizedBox(height: 6);
          }
          final itemIndex = index ~/ 2;
          final item = _items[itemIndex];
          return KnowledgeCard(
            item: item,
            onTap: () => _handleItemTap(item),
            onSourceTap: item.hasSource ? () => _handleSourceTap(item) : null,
            onDelete: () => _handleDelete(item),
          );
        }, childCount: _items.length * 2 - 1),
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '未知错误',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }



  // ==================== 事件处理 ====================

  void _handleItemTap(KnowledgeItem item) {
    // 高亮不能编辑，只能查看
    if (item.type == KnowledgeType.highlight) {
      // 跳转到来源（如果有）
      if (item.hasSource) {
        _handleSourceTap(item);
      }
      return;
    }

    // 标注和笔记可以编辑
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KnowledgeEditorScreen(item: item),
      ),
    ).then((_) => _loadData(showLoading: false));
  }

  void _handleSourceTap(KnowledgeItem item) {
    // TODO: 实现跳转到原对话
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('跳转到来源: ${item.sourceTopicName ?? item.sourceTopicId}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDelete(KnowledgeItem item) async {
    try {
      await _knowledgeService.deleteItem(item);
      _loadData(showLoading: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleCreateNote() {
    QuickCaptureSheet.show(
      context: context,
      initialType: KnowledgeType.note,
      onCreated: () => _loadData(showLoading: false),
    );
  }

  void _handleDailyReview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DailyReviewScreen()),
    );
  }

  void _showStatsDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('知识库统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(
              Icons.auto_awesome_mosaic,
              '知识条目',
              _items.length,
              theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              Icons.tag,
              '标签数',
              _allTags.length,
              theme.colorScheme.secondary,
            ),
          ],
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

  Widget _buildStatRow(IconData icon, String label, int count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          '$count',
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildHeroStat(
    BuildContext context, {
    required String label,
    required int value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索知识库、标签或来源...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _loadData(showLoading: false);
                  },
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadData(showLoading: false);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
