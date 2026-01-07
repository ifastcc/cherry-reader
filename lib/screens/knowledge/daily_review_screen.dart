import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';
import '../../services/knowledge_service.dart';
import 'knowledge_editor_screen.dart';

/// 每日回顾全屏页
///
/// 沉浸式体验，垂直翻页浏览随机知识项
class DailyReviewScreen extends StatefulWidget {
  /// 指定回顾数量（默认10条）
  final int count;

  const DailyReviewScreen({
    super.key,
    this.count = 10,
  });

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  final KnowledgeService _knowledgeService = KnowledgeService();
  final PageController _pageController = PageController();

  List<KnowledgeItem> _items = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadReviewItems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 使用遗忘曲线算法获取回顾内容
      final items = await _knowledgeService.getItemsForReview(count: widget.count);
      
      // 如果没有足够的回顾内容，补充随机内容
      if (items.length < widget.count) {
        final randomItems = await _knowledgeService.getRandomItems(
            count: widget.count - items.length);
        // 去重添加
        for (var item in randomItems) {
           if (!items.any((e) => e.id == item.id)) {
             items.add(item);
           }
        }
      }
      
      setState(() {
        _items = items;
        _isLoading = false;
      });
      
      // 记录第一条的回顾
      if (_items.isNotEmpty) {
        _recordReview(_items[0]);
      }
    } catch (e) {
      if (mounted) // Check mounted
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    if (index < _items.length) {
      _recordReview(_items[index]);
    }
  }

  Future<void> _recordReview(KnowledgeItem item) async {
    try {
      await _knowledgeService.recordReview(item.id);
    } catch (e) {
      debugPrint('记录回顾失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '每日回顾',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReviewItems,
            tooltip: '换一批',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReviewItems,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_mosaic_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '还没有任何知识积累',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '开始阅读并添加高亮、标注或笔记吧',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // 背景渐变
        _buildGradientBackground(),
        // 垂直翻页
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _items.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) => _buildReviewCard(context, index),
        ),
        // 右侧进度指示器
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: _buildProgressIndicator(),
        ),
        // 底部提示
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: _buildBottomHint(),
        ),
      ],
    );
  }

  Widget _buildGradientBackground() {
    // 根据当前卡片类型改变背景色调
    final item = _items.isNotEmpty ? _items[_currentPage] : null;
    final color = item?.displayColor ?? Colors.blue;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            Colors.black,
            Colors.black,
            color.withOpacity(0.2),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, int index) {
    final item = _items[index];

    return GestureDetector(
      onTap: () => _handleItemTap(item),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 80,
          60, // 右侧留空给进度指示器
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型标签
            _buildTypeLabel(item),
            const SizedBox(height: 24),
            // 主要内容
            Expanded(
              child: _buildContent(item),
            ),
            // 来源
            if (item.hasSource) _buildSourceInfo(item),
            // 标签
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTags(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeLabel(KnowledgeItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: item.displayColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.typeIcon,
            size: 16,
            color: item.displayColor,
          ),
          const SizedBox(width: 6),
          Text(
            item.typeName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: item.displayColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(KnowledgeItem item) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 引用原文（高亮/标注）
          if (item.quotedText != null && item.quotedText!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: item.displayColor,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                item.quotedText!,
                style: TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.6,
                ),
              ),
            ),
            // 标注的评论
            if (item.type == KnowledgeType.annotation &&
                item.content.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                item.content,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ] else ...[
            // 笔记内容
            Text(
              item.content,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceInfo(KnowledgeItem item) {
    return GestureDetector(
      onTap: () => _handleSourceTap(item),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 14,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '来自《${item.sourceTopicName ?? "对话"}》',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(KnowledgeItem item) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: item.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_items.length, (index) {
          final isActive = index == _currentPage;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 8,
              height: isActive ? 24 : 8,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? _items[index].displayColor
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomHint() {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Column(
        children: [
          Text(
            '${_currentPage + 1} / ${_items.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.keyboard_arrow_up,
            size: 20,
            color: Colors.white.withOpacity(0.3),
          ),
          Text(
            '上滑查看更多',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  void _handleItemTap(KnowledgeItem item) {
    // 高亮不可编辑
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
    ).then((_) => _loadReviewItems());
  }

  void _handleSourceTap(KnowledgeItem item) {
    // TODO: 实现跳转到原对话
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('跳转到来源: ${item.sourceTopicName ?? item.sourceTopicId}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[800],
      ),
    );
  }
}
