import 'package:flutter/material.dart';
import '../models/domain/search_result_model.dart';
import '../services/search_service.dart';
import '../services/cherry_extractor.dart';
import '../widgets/search_result_card.dart';
import 'conversation_screen.dart';

/// 搜索页面
class SearchScreen extends StatefulWidget {
  final CherryExtractor extractor;

  const SearchScreen({super.key, required this.extractor});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<SearchResultGroup> _results = [];
  bool _isSearching = false;
  String? _error;
  SearchViewType _viewType = SearchViewType.time;

  // 防抖计时器
  DateTime? _lastSearchTime;
  static const _debounceMs = 300;

  @override
  void initState() {
    super.initState();
    // 确保 SearchService 已初始化
    SearchService.instance.init();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 执行搜索（带防抖）
  Future<void> _performSearch(String keyword) async {
    final now = DateTime.now();
    _lastSearchTime = now;

    // 空关键词清空结果
    if (keyword.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    // 防抖延迟
    await Future.delayed(const Duration(milliseconds: _debounceMs));

    // 检查是否是最新的搜索请求
    if (_lastSearchTime != now) return;

    try {
      final results = await SearchService.instance.search(
        keyword,
        viewType: _viewType,
      );

      // 再次检查是否是最新的搜索请求
      if (_lastSearchTime != now) return;

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && _lastSearchTime == now) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  /// 切换视图类型
  void _toggleViewType() {
    setState(() {
      _viewType = _viewType == SearchViewType.time
          ? SearchViewType.assistant
          : SearchViewType.time;
    });

    // 重新执行搜索以更新分组
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// 点击结果跳转到对话页面
  void _onResultTap(SearchResultModel result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          extractor: widget.extractor,
          topicId: result.topicId,
          topicName: result.topicName,
          // 【搜索定位】传递轮次索引，自动滚动到对应位置
          scrollToRoundIndex: result.roundIndex,
          // 【搜索高亮】传递搜索关键词，在内容中高亮显示
          highlightKeyword: _searchController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildSearchField(isDark),
        actions: [
          // 视图切换按钮
          IconButton(
            icon: Icon(
              _viewType == SearchViewType.time
                  ? Icons.access_time
                  : Icons.person_outline,
            ),
            tooltip: _viewType == SearchViewType.time ? '切换到助手视图' : '切换到时间视图',
            onPressed: _toggleViewType,
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  /// 搜索输入框
  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: '搜索话题或消息内容...',
        hintStyle: TextStyle(color: Colors.grey[500]),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              )
            : null,
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      onChanged: _performSearch,
      textInputAction: TextInputAction.search,
    );
  }

  /// 主体内容
  Widget _buildBody(bool isDark) {
    // 加载中（仅在无结果时显示全屏加载）
    if (_isSearching && _results.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 错误状态
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('搜索失败', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // 空状态
    if (_results.isEmpty) {
      return _buildEmptyState(isDark);
    }

    // 结果列表
    return _buildResultsList(isDark);
  }

  /// 空状态
  Widget _buildEmptyState(bool isDark) {
    final hasKeyword = _searchController.text.trim().isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasKeyword ? Icons.search_off : Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasKeyword ? '未找到匹配的结果' : '输入关键词开始搜索',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (hasKeyword) ...[
            const SizedBox(height: 8),
            Text(
              '尝试使用不同的关键词',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '可搜索话题名称或消息内容',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  /// 结果列表（分组显示）
  Widget _buildResultsList(bool isDark) {
    // 统计总结果数
    final totalCount =
        _results.fold<int>(0, (sum, group) => sum + group.results.length);

    return Column(
      children: [
        // 结果统计栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                '找到 $totalCount 条结果',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              // 视图类型指示
              GestureDetector(
                onTap: _toggleViewType,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _viewType == SearchViewType.time
                            ? Icons.access_time
                            : Icons.person_outline,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _viewType == SearchViewType.time ? '时间视图' : '助手视图',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        // 分组列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final group = _results[index];
              return _buildGroupSection(group, isDark, index);
            },
          ),
        ),
      ],
    );
  }

  /// 构建分组区块
  Widget _buildGroupSection(SearchResultGroup group, bool isDark, int index) {
    // 助手视图使用可折叠展开的 ExpansionTile
    if (_viewType == SearchViewType.assistant) {
      return _buildAssistantGroupSection(group, isDark, index);
    }

    // 时间视图保持原样
    return _buildTimeGroupSection(group, isDark);
  }

  /// 构建时间分组区块（直接展示）
  Widget _buildTimeGroupSection(SearchResultGroup group, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.groupTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${group.results.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        // 结果卡片列表
        ...group.results.map((result) => SearchResultCard(
              result: result,
              keyword: _searchController.text,
              onTap: () => _onResultTap(result),
            )),
      ],
    );
  }

  /// 构建助手分组区块（可折叠展开）
  Widget _buildAssistantGroupSection(SearchResultGroup group, bool isDark, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.smart_toy_outlined,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          group.groupTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${group.results.length} 条结果'),
        initiallyExpanded: index == 0, // 只展开第一个
        children: [
          // 使用 ConstrainedBox 限制最大高度，超出可滚动
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: group.results.length > 5 ? 360 : group.results.length * 72.0,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: group.results.length > 5
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: group.results.length,
              itemBuilder: (context, index) {
                final result = group.results[index];
                return SearchResultCard(
                  result: result,
                  keyword: _searchController.text,
                  onTap: () => _onResultTap(result),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
