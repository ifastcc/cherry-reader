import 'dart:ui';

import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';
import '../../services/knowledge_service.dart';
import '../../widgets/knowledge/knowledge_card.dart'; // for KnowledgeEmptyState
import '../../widgets/knowledge/quick_capture_sheet.dart';
import '../../widgets/knowledge/knowledge_timeline_view.dart';
import '../../widgets/knowledge/knowledge_source_view.dart';
import '../../widgets/knowledge/knowledge_tag_view.dart';
import 'knowledge_editor_screen.dart';
import 'daily_review_screen.dart';
import '../conversation_screen.dart';

/// 知识库主页
///
/// 核心重构：
/// - 移除 Hero Header，改为紧凑头部
/// - 支持多视图切换 (时间线/来源/标签)
/// - 内容优先
class KnowledgeHubScreen extends StatefulWidget {
  const KnowledgeHubScreen({super.key});

  @override
  State<KnowledgeHubScreen> createState() => KnowledgeHubScreenState();
}

class KnowledgeHubScreenState extends State<KnowledgeHubScreen> {
  final KnowledgeService _knowledgeService = KnowledgeService();


  // 数据状态
  List<KnowledgeItem> _allItems = [];
  Map<String?, List<KnowledgeItem>> _groupedBySource = {};
  Map<String, int> _tagStats = {};
  
  // 辅助数据
  Map<String, String> _topicNames = {}; // topicId -> topicName map for source view
  
  bool _isLoading = true;
  String? _error;

  // 搜索状态
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
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // 获取所有数据
      // 我们先获取所有条目，因为各个视图大多是基于全量数据的不同组织形式
      // 可以在本地经行分组，避免多次数据库查询请求
      final items = await _knowledgeService.getAllItems();
      final tagStats = await _knowledgeService.getTagStatistics();
      
      // 也可以调用 getItemsGroupedByTopic 但为了构建 topicNames 映射，我们手动处理一下或者单独获取
      // 这里为了简单，我们基于 _allItems 构建视图所需数据
      
      final groupedBySource = <String?, List<KnowledgeItem>>{};
      final topicNames = <String, String>{};
      
      const noSourceKey = '__no_source__';

      for (var item in items) {
        // Source Grouping
        final key = item.sourceTopicId; // null is handled later or key is nullable
        // We use topicId as key. If null, we put in a specific "No Source" group
        
        final groupKey = key; // can be null
        groupedBySource.putIfAbsent(groupKey, () => []).add(item);
        
        if (item.sourceTopicId != null && item.sourceTopicName != null) {
          topicNames[item.sourceTopicId!] = item.sourceTopicName!;
        }
      }

      // 搜索过滤
      List<KnowledgeItem> filteredItems = items;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filteredItems = items.where((item) {
          return item.content.toLowerCase().contains(query) ||
              (item.quotedText?.toLowerCase().contains(query) ?? false) ||
              item.tags.any((tag) => tag.toLowerCase().contains(query)) ||
              (item.sourceTopicName?.toLowerCase().contains(query) ?? false);
        }).toList();
        
        // 如果有搜索，分组视图也应该只显示匹配的结果
        // 重新分组 filteredItems
        groupedBySource.clear();
        for (var item in filteredItems) {
           final groupKey = item.sourceTopicId;
           groupedBySource.putIfAbsent(groupKey, () => []).add(item);
        }
      } else {
        filteredItems = items;
      }

      if (mounted) {
        setState(() {
          _allItems = filteredItems;
          _groupedBySource = groupedBySource;
          _tagStats = tagStats;
          _topicNames = topicNames;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    
    // 动态计算 Header 高度
    // Spacer: topPadding + 60
    // Search Row: 44 (height) + 8 (bottom padding) = 52
    // Divider: 1
    // Total: topPadding + 113
    final headerHeight = topPadding + 113;

    final headerSliver = SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        minHeight: headerHeight,
        maxHeight: headerHeight,
        child: Container(
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              // 1. 顶部留白，避让全局导航胶囊
              SizedBox(height: topPadding + 60), 
              
              // 2. 搜索栏 + 每日回顾
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: _buildCompactSearchField(context)),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: '每日回顾',
                      onPressed: _handleDailyReview,
                      icon: const Icon(Icons.auto_awesome_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadData(showLoading: false),
        edgeOffset: headerHeight,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            headerSliver,
            _buildCurrentView(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(context),
      );
    }
    
    // 如果没有数据（且不在搜索状态），显示空状态
    // 注意：KnowledgeTagView 等组件内部也会处理空状态，但如果是全局空，可以在这里统一处理
    // 不过每个 View 处理可能更好，因为"标签视图"空可能是没有标签但有笔记
    
    // 默认只展示时间线视图，移除 Tab 切换逻辑
    return KnowledgeTimelineView(
      items: _allItems,
      onItemTap: _handleItemTap,
      onSourceTap: _handleSourceTap,
      onDelete: _handleDelete,
      onCreateNote: _handleCreateNote,
    );
  }



  Widget _buildCompactSearchField(BuildContext context) {
    final theme = Theme.of(context);

    // 使用 SizedBox 固定高度，TextField 内部通过 contentPadding 和 TextAlignVertical 居中
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: '搜索知识库...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontSize: 14,
          ),
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          filled: true,
          isDense: true,
          // 移除默认边框，使用圆角背景
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          // 聚焦时显示外边框，或者也可以不要边框只改变背景色
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          // 图标作为 prefixIcon，包含在输入框内部
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          // 清除按钮作为 suffixIcon
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _loadData(showLoading: false);
                  },
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
        ),
        onChanged: (value) {
          if (value != _searchQuery) {
            _searchQuery = value;
            _loadData(showLoading: false);
          }
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(_error ?? '未知错误'),
          TextButton(
            onPressed: _loadData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  // ==================== 事件处理 ====================

  void _handleItemTap(KnowledgeItem item) {
    if (item.type == KnowledgeType.highlight) {
      if (item.hasSource) {
        _handleSourceTap(item);
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KnowledgeEditorScreen(item: item),
      ),
    ).then((_) => _loadData(showLoading: false));
  }

  void _handleSourceTap(KnowledgeItem item) {
    if (!item.hasSource || item.sourceTopicId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法跳转：无来源信息'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          topicId: item.sourceTopicId!,
          topicName: item.sourceTopicName ?? '未知话题',
          scrollToMessageId: item.sourceMessageId,
        ),
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
            duration: Duration(seconds: 2),
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

  // ==================== Public Actions ====================

  /// Main action handler called by parent screen (e.g. FloatingDock)
  void handleMainAction() {
    _handleCreateNote();
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
    ).then((_) => _loadData(showLoading: false));
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
