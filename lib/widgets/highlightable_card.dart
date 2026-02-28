import 'package:flutter/material.dart';
import '../services/markdown_widget_cache.dart';
import 'unified_markdown_renderer.dart';

/// 统一的可高亮卡片组件
///
/// 整合了所有卡片类型的共同逻辑：
/// - Markdown 渲染（使用 UnifiedMarkdownRenderer）
/// - 文本选择（系统原生 SelectionArea）
///
/// 使用方式：
/// ```dart
/// HighlightableCard(
///   messageId: 'xxx',
///   content: 'Markdown 内容',
///   header: HeaderWidget(), // 可选的头部
///   cardType: CardType.assistant,
/// )
/// ```
class HighlightableCard extends StatefulWidget {
  /// 消息 ID，用于标注存储的 key
  final String messageId;

  /// Markdown 内容
  final String content;

  /// 卡片类型（影响样式）
  final CardType cardType;

  /// 自定义头部组件
  final Widget? header;

  /// 模型名称
  final String modelName;

  /// 模型颜色
  final Color modelColor;

  /// 是否显示时间戳
  final bool showTimestamp;

  /// 时间戳
  final String? timestamp;

  /// 卡片最大高度（超出滚动），设为 null 则自然撑开
  final double? maxHeight;

  /// 是否使用流式布局（无边框、自然撑开）
  final bool streamLayout;

  /// 自定义底部操作栏
  final Widget? actionBar;

  /// 讨论回调
  final VoidCallback? onDiscuss;

  /// 重新生成回调
  final VoidCallback? onRegenerate;

  /// 朗读回调
  final VoidCallback? onSpeak;

  /// 【可选】是否启用长文本折叠功能（默认关闭）
  final bool enableCollapse;

  // 可选的上下文参数
  final String? topicId;
  final int? roundIndex;
  final Map<String, dynamic>? contextData;

  /// 【搜索高亮】要高亮的搜索关键词（忽略大小写）
  final String? searchKeyword;

  /// 【精确定位】目标高亮 ID（用于闪烁提示）
  final String? targetHighlightId;

  const HighlightableCard({
    super.key,
    required this.messageId,
    required this.content,
    required this.modelName,
    this.cardType = CardType.assistant,
    this.header,
    this.modelColor = Colors.blue,
    this.showTimestamp = false,
    this.timestamp,
    this.maxHeight = 600,
    this.streamLayout = false,
    this.actionBar,
    this.onDiscuss,
    this.onRegenerate,
    this.onSpeak,
    this.enableCollapse = false,
    this.topicId,
    this.roundIndex,
    this.contextData,
    this.searchKeyword,
    this.targetHighlightId,
  });

  /// 创建助手回复卡片
  factory HighlightableCard.assistant({
    Key? key,
    required Map<String, dynamic> data,
    bool streamLayout = false,
    double? maxHeight = 600,
    Widget? actionBar,
    VoidCallback? onDiscuss,
    VoidCallback? onRegenerate,
    VoidCallback? onSpeak,
    bool enableCollapse = false,
    // 可选的上下文参数
    String? topicId,
    int? roundIndex,
    Map<String, dynamic>? contextData,
    String? searchKeyword,
    String? targetHighlightId,
  }) {
    final blocks = data['blocks'] as List<dynamic>? ?? [];
    final model = data['model'] as Map<String, dynamic>?;
    final modelName = model?['name'] as String? ?? 'Unknown Model';
    final messageId = data['id'] as String? ?? '';
    final timestamp = data['created_at'] as String? ?? '';

    // 提取纯文本内容
    // 按照 block 在列表中的顺序拼接（TopicService 已按 orderIndex 排序）
    String plainContent = '';
    // 支持的文本块类型
    final textBlockTypes = [
      'main_text',
      'thinking',
      'translation',
      'code',
      'error',
      'text',
    ];

    for (final block in blocks) {
      if (block is Map<String, dynamic> &&
          textBlockTypes.contains(block['type'])) {
        final content = block['content'] as String? ?? '';
        plainContent += content;
      }
    }

    return HighlightableCard(
      key: key,
      messageId: messageId,
      content: plainContent,
      modelName: modelName,
      modelColor: _getModelColor(modelName),
      cardType: CardType.assistant,
      showTimestamp: true,
      timestamp: timestamp,
      streamLayout: streamLayout,
      maxHeight: maxHeight,
      actionBar: actionBar,
      onDiscuss: onDiscuss,
      onRegenerate: onRegenerate,
      onSpeak: onSpeak,
      enableCollapse: enableCollapse,
      topicId: topicId,
      roundIndex: roundIndex,
      contextData: contextData,
      searchKeyword: searchKeyword,
      targetHighlightId: targetHighlightId,
    );
  }

  /// 创建 AI 分析卡片
  factory HighlightableCard.aiAnalysis({
    Key? key,
    required String content,
    bool enableCollapse = false,
  }) {
    final messageId = 'ai_analysis_${content.hashCode}';

    return HighlightableCard(
      key: key,
      messageId: messageId,
      content: content,
      modelName: 'AI 元分析',
      modelColor: const Color(0xFF8B5CF6),
      cardType: CardType.aiAnalysis,
      showTimestamp: false,
      enableCollapse: enableCollapse,
    );
  }

  /// 根据模型名称获取颜色
  static Color _getModelColor(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (name.contains('gpt') || name.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (name.contains('gemini') || name.contains('google')) {
      return const Color(0xFF4285F4);
    } else if (name.contains('qwen') || name.contains('通义')) {
      return const Color(0xFF6366F1);
    } else if (name.contains('deepseek')) {
      return const Color(0xFF06B6D4);
    } else if (name.contains('llama') || name.contains('meta')) {
      return const Color(0xFF0668E1);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }

  @override
  State<HighlightableCard> createState() => _HighlightableCardState();
}

/// 卡片类型
enum CardType { assistant, aiAnalysis, user }

class _HighlightableCardState extends State<HighlightableCard> {
  // 【新增】展开/收缩状态
  bool _expanded = false;

  // 折叠阈值（超过此字符数时默认折叠）
  static const int _collapseThreshold = 1000;
  // 折叠时显示的字符数
  static const int _collapsedPreviewLength = 500;

  // 【新增】判断内容是否需要折叠（仅在启用折叠功能时生效）
  bool get _isLongContent =>
      widget.enableCollapse && widget.content.length > _collapseThreshold;

  // 【新增】获取当前显示的内容
  String get _displayContent {
    if (!_isLongContent || _expanded) {
      return widget.content;
    }
    // 折叠模式：截取前 N 个字符
    return '${widget.content.substring(0, _collapsedPreviewLength)}...';
  }

  // 【新增】切换展开/收缩状态
  void _toggleExpand() {
    if (_isLongContent) {
      setState(() {
        _expanded = !_expanded;
      });
    }
  }

  /// 【简化】获取 memoized Markdown widget
  ///
  /// 使用 Widget 缓存服务，避免重复构建
  Widget _getMemoizedMarkdownWidget() {
    // 【新增】使用 _displayContent 而不是 widget.content，支持折叠显示
    final currentContent = _displayContent;
    final contentHash = currentContent.hashCode;

    // 使用全局缓存服务
    return MarkdownWidgetCache.instance.getOrBuild(
      key: '${widget.messageId}_${_expanded ? 'exp' : 'col'}',
      contentHash: contentHash,
      builder: () => UnifiedMarkdownRenderer(
        data: currentContent,
        scrollable: false,
        selectable: true,
        textStyle: const TextStyle(
          fontSize: 15,
          height: 1.8,
          color: Color(0xFF2C3E50),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoTime.substring(0, 16).replaceAll('T', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 流式布局模式
    if (widget.streamLayout) {
      return _buildStreamLayout();
    }

    // 传统卡片模式
    return _buildCardLayout();
  }

  /// 流式布局（无边框、自然撑开）
  Widget _buildStreamLayout() {
    return GestureDetector(
      // 双击展开/收缩
      // 双击展开/收缩 - 已移除，移动到 Header 以避免冲突
      // onDoubleTap: widget.enableCollapse ? _toggleExpand : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            GestureDetector(
              onDoubleTap: widget.enableCollapse ? _toggleExpand : null,
              child: _buildStreamHeader(),
            ),
            const SizedBox(height: 8),
            // 内容（自然撑开）
            _buildContent(),
            // 展开/收缩提示
            if (_isLongContent) _buildExpandHint(),
            // 操作栏
            if (widget.actionBar != null) ...[
              const SizedBox(height: 4),
              widget.actionBar!,
            ],
          ],
        ),
      ),
    );
  }

  /// 流式布局的头部（更简洁）
  Widget _buildStreamHeader() {
    return Row(
      children: [
        // 时间戳
        if (widget.showTimestamp && widget.timestamp != null)
          Text(
            _formatTime(widget.timestamp!),
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        const Spacer(),
      ],
    );
  }

  /// 传统卡片布局
  Widget _buildCardLayout() {
    return GestureDetector(
      // 双击展开/收缩
      // 双击展开/收缩 - 已移除，移动到 Header 以避免冲突
      // onDoubleTap: widget.enableCollapse ? _toggleExpand : null,
      child: widget.maxHeight != null
          ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxHeight!),
              child: _buildCardContent(),
            )
          : _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    return Container(
      // 背景透明，让父容器的淡色背景显示出来
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部 (固定)
          GestureDetector(
            behavior: HitTestBehavior.opaque, // 确保点击整个头部区域都能触发
            onDoubleTap: widget.enableCollapse ? _toggleExpand : null,
            child: _buildHeader(),
          ),
          const SizedBox(height: 6),
          // 内容 (可滚动)
          widget.maxHeight != null
              ? Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildContent(),
                        // 展开/收缩提示
                        if (_isLongContent) _buildExpandHint(),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContent(),
                    // 展开/收缩提示
                    if (_isLongContent) _buildExpandHint(),
                  ],
                ),
          // 操作栏
          if (widget.actionBar != null) ...[
            const SizedBox(height: 4),
            widget.actionBar!,
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 时间戳（移到左边）
        if (widget.showTimestamp && widget.timestamp != null) ...[
          Text(
            _formatTime(widget.timestamp!),
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
          const Spacer(),
        ],
      ],
    );
  }

  Widget _buildContent() {
    // 移除自定义选中弹窗（复制/添加笔记），仅保留系统原生文本选择能力。
    return SelectionArea(child: _getMemoizedMarkdownWidget());
  }

  /// 【新增】构建展开/收缩提示
  Widget _buildExpandHint() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _expanded ? Icons.unfold_less : Icons.unfold_more,
            size: 16,
            color: hintColor,
          ),
          const SizedBox(width: 4),
          Text(
            _expanded ? '双击收起' : '双击展开全文',
            style: TextStyle(fontSize: 12, color: hintColor),
          ),
          if (!_expanded) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isDark ? Colors.grey[700] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.content.length} 字',
                style: TextStyle(fontSize: 10, color: hintColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
