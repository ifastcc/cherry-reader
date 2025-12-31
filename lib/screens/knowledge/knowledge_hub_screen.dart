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
  State<KnowledgeHubScreen> createState() => _KnowledgeHubScreenState();
}

class _KnowledgeHubScreenState extends State<KnowledgeHubScreen> {
  final KnowledgeService _knowledgeService = KnowledgeService();

  // 状态
  List<KnowledgeItem> _items = [];
  List<String> _allTags = [];
  bool _isLoading = true;
  String? _error;

  // 筛选状态
  String? _selectedTag;
  String _searchQuery = '';
  bool _isSearching = false;

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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
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
        filteredItems =
            items.where((item) => item.tags.contains(_selectedTag)).toList();
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
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // 标签筛选（有标签时显示）
          if (_allTags.isNotEmpty) _buildTagFilter(context),
          // 内容区域
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState(context)
                    : _items.isEmpty
                        ? KnowledgeEmptyState(onCreateNote: _handleCreateNote)
                        : _buildItemList(context),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
            _loadData();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索知识库...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _loadData();
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _loadData();
              },
            ),
        ],
      );
    }

    return AppBar(
      title: const Text('知识库'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 12),
                  Text('刷新'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Icons.bar_chart, size: 20),
                  SizedBox(width: 12),
                  Text('统计'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadData();
                break;
              case 'stats':
                _showStatsDialog();
                break;
            }
          },
        ),
      ],
    );
  }

  /// 标签筛选
  Widget _buildTagFilter(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _allTags.length,
        itemBuilder: (context, index) {
          final tag = _allTags[index];
          final isSelected = _selectedTag == tag;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('#$tag'),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedTag = isSelected ? null : tag);
                _loadData();
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 知识项列表
  Widget _buildItemList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return KnowledgeCard(
            item: item,
            onTap: () => _handleItemTap(item),
            onSourceTap: item.hasSource ? () => _handleSourceTap(item) : null,
            onDelete: () => _handleDelete(item),
          );
        },
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.error,
            ),
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

  /// FAB
  Widget _buildFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 每日回顾按钮
        if (_items.isNotEmpty)
          FloatingActionButton.small(
            heroTag: 'daily_review',
            onPressed: _handleDailyReview,
            child: const Icon(Icons.auto_awesome),
          ),
        const SizedBox(height: 12),
        // 新建笔记按钮
        FloatingActionButton(
          heroTag: 'create_note',
          onPressed: _handleCreateNote,
          child: const Icon(Icons.add),
        ),
      ],
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
    ).then((_) => _loadData());
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
      _loadData();
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
      onCreated: _loadData,
    );
  }

  void _handleDailyReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DailyReviewScreen(),
      ),
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
