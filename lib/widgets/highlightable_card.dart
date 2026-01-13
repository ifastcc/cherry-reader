import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/foundation.dart'; 
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:gpt_markdown_custom/gpt_markdown.dart';
import '../models/highlight_data.dart';
import '../models/isar/knowledge_entry.dart' show SelectionRange;
import '../models/isar/unified_conversation_entity.dart';
import '../services/highlight_service.dart';
import '../services/unified_conversation_service.dart';
import '../screens/ai_chat_screen.dart';
import 'unified_markdown_renderer.dart';
import 'highlight_style_menu.dart';
import 'knowledge/quick_capture_sheet.dart';
import 'floating_selection_toolbar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; // For RenderMetaData lookup
import 'package:gpt_markdown_custom/gpt_markdown.dart'; // Ensure GptMarkdownV2/MetaData is available
import '../services/highlight_recovery_service.dart';

/// 统一的可高亮卡片组件
///
/// 整合了所有卡片类型的共同逻辑：
/// - 标注加载/保存（使用 HighlightService）
/// - Markdown 渲染（使用 UnifiedMarkdownRenderer）
/// - 文本选择和高亮标注
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
    final textBlockTypes = ['main_text', 'thinking', 'translation', 'code', 'error', 'text'];

    for (final block in blocks) {
      if (block is Map<String, dynamic> && textBlockTypes.contains(block['type'])) {
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

class _HighlightableCardState extends State<HighlightableCard> with SingleTickerProviderStateMixin {
  final HighlightService _highlightService = HighlightService();
  final HighlightRecoveryService _recoveryService = HighlightRecoveryService();

  List<HighlightData> _highlights = [];
  String _selectedText = '';
  int _selectionStart = 0;
  int _selectionEnd = 0;
  String _selectionPrefix = '';
  String _selectionSuffix = '';
  // 【双向 HitTest】选区的 Block 信息
  int? _selectionStartBlockIndex;
  int? _selectionEndBlockIndex;
  int _currentStyleIndex = 0;

  // 讨论数量
  int _discussionCount = 0;
  // 【性能优化】标记是否已加载过讨论数量，避免重复加载
  bool _discussionCountLoaded = false;
  
  // 【精确定位】闪烁动画控制器
  AnimationController? _blinkController;
  Animation<double>? _blinkAnimation;

  // 【性能优化】Markdown 渲染缓存（memo 模式）
  Widget? _cachedMarkdownWidget;
  String? _lastRenderedContent;
  int? _lastRenderedHighlightsHash;

  // 【核心修复】缓存解析结果（包含纯文本和 Block Registry）
  MarkdownParseResult? _cachedParseResult;
  
  // 【Bug Fix】防止重复触发高亮
  bool _isProcessingHighlight = false;

  // 【新增】展开/收缩状态
  bool _expanded = false;

  // 折叠阈值（超过此字符数时默认折叠）
  static const int _collapseThreshold = 1000;
  // 折叠时显示的字符数
  static const int _collapsedPreviewLength = 500;

  Color get _currentHighlightColor =>
      kHighlightStyles[_currentStyleIndex].color;
  String get _currentHighlightType => kHighlightStyles[_currentStyleIndex].type;

  // 【新增】判断内容是否需要折叠（仅在启用折叠功能时生效）
  bool get _isLongContent => widget.enableCollapse && widget.content.length > _collapseThreshold;

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
        // 展开/收缩时清除 Markdown 缓存，因为内容变化了
        _cachedMarkdownWidget = null;
        _cachedParseResult = null;  // 同时清除解析结果缓存
      });
    }
  }

  // 【新增】SelectableRegion Key for accessing selection state
  final GlobalKey<SelectableRegionState> _selectableRegionKey = GlobalKey();

  /// 【重构】使用单次解析架构从 Markdown 获取纯文本和 Block Registry
  MarkdownParseResult _getParseResultFromMarkdown(String markdown) {
    // 使用 V2 解析器生成完整结果
    return GptMarkdownV2.generateParseResult(
      context,
      markdown,
      const GptMarkdownConfig(), // 使用默认配置，确保与渲染一致
    );
  }

  /// 【核心重构】使用双向 HitTest 直接获取选区的 Block 范围
  /// 
  /// 策略（符合第一性原理）:
  /// 1. 对选择起点进行 HitTest，获取起始 Block
  /// 2. 对选择终点进行 HitTest，获取结束 Block
  /// 3. 直接使用 Block 范围，不再通过文本反向搜索
  /// 
  /// 返回: (startBlockIndex, globalStart, endBlockIndex, globalEnd, selectedText)
  (int?, int?, int?, int?, String)? _resolveSelection() {
     if (_selectedText.isEmpty) return null;
     if (_cachedParseResult == null) return null;
     
     final fullText = _cachedParseResult!.plainText;
     final registry = _cachedParseResult!.blocks;
     
     // 【双向 HitTest】获取起点和终点的 Block
     int? startBlockIndex;
     int? endBlockIndex;
     
     if (_selectionStartPosition != null) {
        startBlockIndex = _hitTestBlockIndex(_selectionStartPosition!);
     }
     if (_selectionEndPosition != null) {
        endBlockIndex = _hitTestBlockIndex(_selectionEndPosition!);
     }
     
     // 如果 HitTest 成功，直接使用 Block 信息计算全局偏移
     int globalStart = -1;
     int globalEnd = -1;
     
     if (startBlockIndex != null && endBlockIndex != null) {
       // 【理想路径】双向 HitTest 成功
       print('🎯 [HitTest] Start Block: $startBlockIndex, End Block: $endBlockIndex');
       
       // 找到涉及的所有 Block
       final minBlock = min(startBlockIndex, endBlockIndex);
       final maxBlock = max(startBlockIndex, endBlockIndex);
       
       // 在这些 Block 中搜索选中文本
       for (final block in registry) {
         if (block.index >= minBlock && block.index <= maxBlock) {
           // 在此 Block 内搜索选中文本
           final textInBlock = block.text;
           
           // 如果选中文本完全在这个 Block 内
           final idx = textInBlock.indexOf(_selectedText);
           if (idx != -1) {
             globalStart = block.globalStart + idx;
             globalEnd = globalStart + _selectedText.length;
             break;
           }
           
           // 如果选中文本跨越多个 Block，需要在全文中搜索
           // 但限制搜索范围为 Block 范围附近
         }
       }
       
       // 如果在单个 Block 内没找到（跨 Block 选择的情况）
       if (globalStart == -1) {
         // 获取 Block 范围的全局偏移
         int rangeStart = fullText.length;
         int rangeEnd = 0;
         for (final block in registry) {
           if (block.index >= minBlock && block.index <= maxBlock) {
             rangeStart = min(rangeStart, block.globalStart);
             rangeEnd = max(rangeEnd, block.globalEnd);
           }
         }
         
         // 在该范围内搜索（包含 Block 间的换行符）
         if (rangeStart < rangeEnd && rangeEnd <= fullText.length) {
           final rangeText = fullText.substring(rangeStart, rangeEnd);
           final idx = rangeText.indexOf(_selectedText);
           if (idx != -1) {
             globalStart = rangeStart + idx;
             globalEnd = globalStart + _selectedText.length;
             print('🔗 [HitTest] Cross-block selection found at [$globalStart, $globalEnd]');
           }
         }
       }
     }
     
     // 【回退路径】如果 HitTest 失败，使用全局搜索
     if (globalStart == -1) {
       // 优先使用单个 Block 的 HitTest 结果
       final anyBlockIndex = startBlockIndex ?? endBlockIndex;
       if (anyBlockIndex != null) {
         try {
           final block = registry.firstWhere((b) => b.index == anyBlockIndex);
           // 在该 Block 附近搜索
           final matches = _selectedText.allMatches(fullText);
           int minDistance = 999999999;
           
           for (final match in matches) {
             if (match.start < block.globalEnd && match.end > block.globalStart) {
               // 重叠，优先选择
               globalStart = match.start;
               globalEnd = match.end;
               break;
             }
             final dist = min((match.start - block.globalEnd).abs(), (block.globalStart - match.end).abs());
             if (dist < minDistance) {
               minDistance = dist;
               globalStart = match.start;
               globalEnd = match.end;
             }
           }
         } catch (_) {}
       }
       
       // 最终回退：全局搜索
       if (globalStart == -1) {
         globalStart = fullText.indexOf(_selectedText);
         globalEnd = globalStart + _selectedText.length;
       }
     }
     
     if (globalStart == -1) return null;
     
     return (startBlockIndex, globalStart, endBlockIndex, globalEnd, _selectedText);
  }

  @override
  void initState() {
    super.initState();
    _loadHighlights();
    // 【性能优化】延迟加载讨论数量，不阻塞首次渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_discussionCountLoaded) {
        _loadDiscussionCount();
      }
    });
    // 【精确定位】初始化闪烁动画
    _initBlinkAnimationIfNeeded();
  }

  @override
  void didUpdateWidget(HighlightableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 【精确定位】检查目标高亮是否变化
    if (widget.targetHighlightId != oldWidget.targetHighlightId) {
      _initBlinkAnimationIfNeeded();
    }
  }

  /// 【精确定位】初始化闪烁动画（如果需要）
  void _initBlinkAnimationIfNeeded() {
    // 如果没有目标高亮，清理动画
    if (widget.targetHighlightId == null) {
      _blinkController?.dispose();
      _blinkController = null;
      _blinkAnimation = null;
      return;
    }
    
    // 检查目标高亮是否在当前卡片中
    final hasTargetHighlight = _highlights.any((h) => h.id == widget.targetHighlightId);
    if (!hasTargetHighlight) {
      // 目标高亮不在当前卡片，清理动画
      _blinkController?.dispose();
      _blinkController = null;
      _blinkAnimation = null;
      return;
    }
    
    // 创建闪烁动画（3 次闪烁）
    _blinkController?.dispose();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _blinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController!, curve: Curves.easeInOut),
    );
    
    // 闪烁 3 次后停止
    int blinkCount = 0;
    _blinkController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        blinkCount++;
        if (blinkCount < 3) {
          _blinkController!.reverse();
        }
      } else if (status == AnimationStatus.dismissed && blinkCount < 3) {
        _blinkController!.forward();
      }
    });
    
    _blinkController!.forward();
    debugPrint('✨ [闪烁动画] 启动目标高亮闪烁: ${widget.targetHighlightId}');
  }

  Future<void> _loadDiscussionCount() async {
    if (_discussionCountLoaded) return; // 避免重复加载
    _discussionCountLoaded = true;

    final conversations = await UnifiedConversationService.instance
        .getConversationsByContext(widget.messageId);
    if (mounted) {
      setState(() {
        _discussionCount = conversations.length;
      });
    }
  }

  Future<void> _loadHighlights() async {
    final highlights = await _highlightService.loadHighlights(widget.messageId);
    if (mounted) {
      setState(() {
        _highlights = highlights;
        // 高亮变化时清除 Markdown 缓存
        _cachedMarkdownWidget = null;
        _cachedParseResult = null;  // 同时清除解析结果缓存
      });
      // 【精确定位】高亮加载完成后，尝试初始化闪烁动画
      _initBlinkAnimationIfNeeded();
    }
  }

  /// 【性能优化】获取 memoized Markdown widget
  ///
  /// 只有在 content 或 highlights 变化时才重新创建
  Widget _getMemoizedMarkdownWidget() {
    // 【优化】计算更健壮的 hash，包含 ID、颜色、样式
    final highlightsHash = Object.hashAll(
      _highlights.map((h) => Object.hash(h.id, h.color, h.styleType, h.start, h.end)),
    ) + (widget.searchKeyword?.hashCode ?? 0);
    // 【新增】使用 _displayContent 而不是 widget.content，支持折叠显示
    final currentContent = _displayContent;

    // 检查是否需要重新渲染
    final needsRebuild =
        _cachedMarkdownWidget == null ||
        _lastRenderedContent != currentContent ||
        _lastRenderedHighlightsHash != highlightsHash;

    debugPrint('🔄 [MemoizedMarkdown] needsRebuild=$needsRebuild, cacheNull=${_cachedMarkdownWidget == null}, contentChanged=${_lastRenderedContent != currentContent}, hashChanged=${_lastRenderedHighlightsHash != highlightsHash}');
    debugPrint('🔄 [MemoizedMarkdown] currentHash=$highlightsHash, lastHash=$_lastRenderedHighlightsHash, highlightsCount=${_highlights.length}');

    if (needsRebuild) {
      debugPrint('🔄 [MemoizedMarkdown] Rebuilding markdown widget...');
      // 【重构】使用新的单次解析架构
      _cachedParseResult ??= _getParseResultFromMarkdown(currentContent);
      final plainText = _cachedParseResult!.plainText;
      
      // 用户手动标注的高亮
      List<HighlightData> validRecoveredHighlights = [];

      // 【新架构】从每个 HighlightData 的 selections 解析多个 HighlightRange
      final List<HighlightRange> userHighlights = [];
      
      for (final h in _highlights) {
        // 尝试恢复/修正高亮位置
        final recovered = _recoveryService.recover(
          h, 
          plainText, 
          registry: _cachedParseResult?.blocks,
        );
        
        // 如果恢复后位置越界，则放弃该高亮
        if (recovered.start >= plainText.length || recovered.end > plainText.length) {
          continue;
        }
        
        validRecoveredHighlights.add(recovered);
        
        // 【Bug Fix】使用原始 h 的 color/styleType，因为 recovered 可能来自缓存（包含旧的样式）
        final effectiveColor = h.color;
        final effectiveStyleType = h.styleType;
        
        // 【新架构】从 effectiveSelections 生成多个 HighlightRange
        final selections = recovered.effectiveSelections;
        
        // 【精确定位】检查是否为目标高亮
        final isTargetHighlight = widget.targetHighlightId != null && h.id == widget.targetHighlightId;
        
        if (selections.isNotEmpty) {
          // 有 selections，为每个选区创建 HighlightRange
          for (int i = 0; i < selections.length; i++) {
            final sel = selections[i];
            userHighlights.add(HighlightRange(
              id: '${recovered.id}_$i',  // 唯一 ID
              start: sel.globalStart,
              end: sel.globalEnd,
              color: Color(effectiveColor),  // 【Bug Fix】使用原始颜色
              styleType: effectiveStyleType,  // 【Bug Fix】使用原始样式
              text: sel.text,
              prefix: sel.prefix,
              suffix: sel.suffix,
              blockIndex: sel.blockIndex,
              blockContentHash: sel.blockContentHash,
              blockInternalStart: sel.internalStart,
              blockInternalEnd: sel.internalEnd,
              isTarget: isTargetHighlight,  // 【精确定位】标记目标高亮
            ));
          }
        } else {
          // 无 selections，fallback 到旧字段
          userHighlights.add(HighlightRange(
            id: recovered.id,
            start: recovered.start,
            end: recovered.end,
            color: Color(effectiveColor),  // 【Bug Fix】使用原始颜色
            styleType: effectiveStyleType,  // 【Bug Fix】使用原始样式
            text: recovered.text,
            prefix: recovered.prefix,
            suffix: recovered.suffix,
            blockIndex: recovered.blockIndex,
            blockContentHash: recovered.blockContentHash,
            blockInternalStart: recovered.blockInternalStart,
            blockInternalEnd: recovered.blockInternalEnd,
            isTarget: isTargetHighlight,  // 【精确定位】标记目标高亮
          ));
        }
      }

      // 【新架构】Lazy Migration 逻辑简化 - 新数据已经包含 selections，不需要迁移

      // 【搜索高亮】生成搜索关键词的高亮范围（也在纯文本中匹配）
      final searchHighlights = _generateSearchHighlights(plainText);

      // 合并高亮（搜索高亮 + 用户高亮）
      final allHighlights = [...searchHighlights, ...userHighlights];

      // Debug Log for Highlights
      if (allHighlights.isNotEmpty) {
          print('🔍 [HighlightableCard] Passing ${allHighlights.length} ranges to Renderer');
          for (var h in allHighlights) {
             print('  - H: "${h.text}" Block:${h.blockIndex} [${h.start}, ${h.end}] ID:${h.id}');
          }
      } else {
          print('🔍 [HighlightableCard] No highlights to render.');
      }

      _cachedMarkdownWidget = UnifiedMarkdownRenderer(
        data: currentContent,
        scrollable: false,
        selectable: true,
        highlights: allHighlights.map((h) {
          // If blockIndex is present, we MUST use internal offsets for rendering
          // because GptMarkdownVisitor expects local coordinates within the block.
          final isBlockAnchored = h.blockIndex != null && h.blockInternalStart != null && h.blockInternalEnd != null;
          
          return HighlightRange(
            id: h.id,
            start: isBlockAnchored ? h.blockInternalStart! : h.start,
            end: isBlockAnchored ? h.blockInternalEnd! : h.end,
            color: h.color,
            styleType: h.styleType,
            text: h.text,
            prefix: h.prefix,
            suffix: h.suffix,
            blockIndex: h.blockIndex,
            blockContentHash: h.blockContentHash,
            blockInternalStart: h.blockInternalStart,
            blockInternalEnd: h.blockInternalEnd,
            groupId: h.groupId,
            isTarget: h.isTarget,  // 【精确定位】传递目标标记
          );
        }).toList(),
        onHighlightTap: (id, details) {
          // 搜索高亮不响应点击
          if (id.startsWith('search_')) return;
          
          // 【新架构】ID 可能是 "originalId_0" 格式，需要提取原始 ID
          final originalId = id.contains('_') ? id.substring(0, id.lastIndexOf('_')) : id;

          final highlight = _highlights.firstWhere(
            (h) => h.id == originalId || h.id == id,
            orElse: () => _highlights.first,
          );
          _showHighlightMenu(highlight);
        },
        textStyle: const TextStyle(
          fontSize: 15,
          height: 1.8,
          color: Color(0xFF2C3E50),
          letterSpacing: 0.3,
        ),
      );

      _lastRenderedContent = currentContent;
      _lastRenderedHighlightsHash = highlightsHash;
    }

    return _cachedMarkdownWidget!;
  }

  /// 【搜索高亮】根据搜索关键词生成高亮范围
  List<HighlightRange> _generateSearchHighlights(String content) {
    final keyword = widget.searchKeyword;
    if (keyword == null || keyword.isEmpty) return [];

    final highlights = <HighlightRange>[];
    final lowerContent = content.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    int startIndex = 0;
    int matchCount = 0;

    while (true) {
      final index = lowerContent.indexOf(lowerKeyword, startIndex);
      if (index == -1) break;

      highlights.add(HighlightRange(
        id: 'search_$matchCount',
        start: index,
        end: index + keyword.length,
        color: const Color(0xFFFFEB3B), // 黄色高亮
        styleType: 'background',
        text: keyword,
      ));

      startIndex = index + keyword.length;
      matchCount++;

      // 限制最多高亮 50 个匹配，避免性能问题
      if (matchCount >= 50) break;
    }

    return highlights;
  }

  /// 【新架构】一次选择 = 一条记录
  /// 
  /// 收集所有涉及的 Block 选区信息，创建单条 HighlightData
  Future<void> _addHighlightFromSelection(String text, int start, int end, {String prefix = '', String suffix = ''}) async {
    // 【Bug Fix】防抖动/防重复点击
    if (_isProcessingHighlight) {
      print('⚠️ [AddHighlight] Skipped duplicate trigger.');
      return;
    }
    _isProcessingHighlight = true;
    
    try {
      // 1. 获取 Block Registry
      _cachedParseResult ??= _getParseResultFromMarkdown(_displayContent);
      final registry = _cachedParseResult!.blocks;
      
      // 2. 查找涉及的 Block
      print('🔍 [AddHighlight] Selection: [$start, $end] Text: "${text.substring(0, min(10, text.length))}..."');
      print('🔍 [AddHighlight] Registry Size: ${registry.length}');

      final intersectingBlocks = registry.where((b) {
        final intersectStart = max(start, b.globalStart);
        final intersectEnd = min(end, b.globalEnd);
        return intersectStart < intersectEnd;
      }).toList();

      // Filter out container blocks (keep only leaves)
      // If block A contains block B, and both are in the list, remove A.
      final leafBlocks = intersectingBlocks.where((bA) {
          // Keep bA if no other block bB is strictly inside bA
          // (Actually, we want to keep bA if it is NOT a container of another selected block)
          // "Strictly inside" means bB.globalStart >= bA.globalStart && bB.globalEnd <= bA.globalEnd
          // Check if bA contains any OTHER block in the list
          final containsOther = intersectingBlocks.any((bB) => 
             bA != bB && 
             bB.globalStart >= bA.globalStart && 
             bB.globalEnd <= bA.globalEnd
          );
          return !containsOther;
      }).toList();
      
      // Use leafBlocks for processing
      final blocksToProcess = leafBlocks.isNotEmpty ? leafBlocks : intersectingBlocks;
      
      // 3. 【新架构】收集所有选区信息
      final List<SelectionRange> selections = [];
      final int contextLength = 20;
      
      if (blocksToProcess.isEmpty) {
        print('⚠️ [AddHighlight] No intersecting blocks found! Using Global Offset only.');
        // Fallback: 无 Block 信息，selections 为空，依赖全局偏移
      } else {
        // 为每个 Block 收集选区信息
        for (final block in blocksToProcess) {
          final intersectStart = max(start, block.globalStart);
          final intersectEnd = min(end, block.globalEnd);
          
          final internalStart = intersectStart - block.globalStart;
          final internalEnd = intersectEnd - block.globalStart;
          final subText = _cachedParseResult!.plainText.substring(intersectStart, intersectEnd);
          
          // 提取 Block Local 语义上下文
          String blockLocalPrefix = '';
          if (internalStart > 0) {
            final pStart = max(0, internalStart - contextLength);
            blockLocalPrefix = block.text.substring(pStart, internalStart);
          }
          
          String blockLocalSuffix = '';
          if (internalEnd < block.text.length) {
            final sEnd = min(block.text.length, internalEnd + contextLength);
            blockLocalSuffix = block.text.substring(internalEnd, sEnd);
          }
          
          selections.add(SelectionRange(
            blockIndex: block.index,
            internalStart: internalStart,
            internalEnd: internalEnd,
            text: subText,
            blockContentHash: block.contentHash,
            globalStart: intersectStart,
            globalEnd: intersectEnd,
            prefix: blockLocalPrefix,
            suffix: blockLocalSuffix,
          ));
        }
      }
      
      // 4. 【新架构】创建单条高亮记录
      final highlight = HighlightData(
        text: text,  // 完整的引用文本（保留换行）
        start: start,
        end: end,
        prefix: prefix,
        suffix: suffix,
        color: _currentHighlightColor.value,
        styleType: _currentHighlightType,
        selections: selections.isNotEmpty ? selections : null,
        // 单个 Block 时也填充旧字段（兼容性）
        blockIndex: selections.length == 1 ? selections.first.blockIndex : null,
        blockContentHash: selections.length == 1 ? selections.first.blockContentHash : null,
        blockInternalStart: selections.length == 1 ? selections.first.internalStart : null,
        blockInternalEnd: selections.length == 1 ? selections.first.internalEnd : null,
      );
      
      print('✅ [AddHighlight] Creating single highlight with ${selections.length} selections');
      
      // 5. 保存到服务
      final highlights = await _highlightService.addHighlight(
        widget.messageId,
        highlight,
        topicId: widget.topicId,
        topicName: widget.contextData?['topicName'] as String?,
      );

      // 6. 重新加载高亮
      if (mounted) {
        setState(() {
          _highlights = highlights;
          _cachedMarkdownWidget = null;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已添加高亮'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _isProcessingHighlight = false;
        });
      }
    }
  }

  // _createAndAddHighlight 已移除 - 逻辑合并到 _addHighlightFromSelection

  /// 【新架构】删除高亮 - 一条记录就是一个高亮
  void _removeHighlight(HighlightData highlight) {
    _highlightService.removeHighlight(widget.messageId, highlight.id).then((highlights) {
      if (mounted) {
        setState(() {
          _highlights = highlights;
          _cachedMarkdownWidget = null;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除高亮'), duration: Duration(seconds: 1)),
    );
  }

  /// 【新架构】更新高亮样式 - 一条记录就是一个高亮
  Future<void> _updateHighlightStyle(
    HighlightData highlight,
    int newColor,
    String newType,
  ) async {
    debugPrint('🎨 [UpdateStyle] START - ID: ${highlight.id}, OldColor: ${highlight.color}, NewColor: $newColor, Type: $newType');
    debugPrint('🎨 [UpdateStyle] MessageId: ${widget.messageId}, mounted: $mounted');
    
    final highlights = await _highlightService.updateHighlightStyle(
      widget.messageId, 
      highlight.id, 
      newColor, 
      newType,
    );
    
    debugPrint('🎨 [UpdateStyle] Received ${highlights.length} highlights');
    for (final h in highlights) {
      debugPrint('🎨 [UpdateStyle]   - ID: ${h.id}, Color: ${h.color}, Type: ${h.styleType}');
    }
    
    if (mounted) {
      debugPrint('🎨 [UpdateStyle] Calling setState to update UI...');
      setState(() {
        _highlights = highlights;
        // 【Bug Fix】同时清除 Markdown Widget 缓存和解析结果缓存
        _cachedMarkdownWidget = null;
        _cachedParseResult = null;
        // 【调试】记录缓存清除
        debugPrint('🎨 [UpdateStyle] Cache cleared: _cachedMarkdownWidget=null, _cachedParseResult=null');
      });
      debugPrint('🎨 [UpdateStyle] setState completed');
    } else {
      debugPrint('🎨 [UpdateStyle] WARNING: Widget not mounted, skipping setState');
    }
  }

  void _showHighlightMenu(HighlightData highlight) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final center = Offset(overlay.size.width / 2, overlay.size.height / 2);

    HighlightStyleMenu.show(
      context: context,
      position: center,
      highlightId: highlight.id,
      currentColor: highlight.color,
      currentStyleType: highlight.styleType,
      onStyleChanged: (highlightId, newColor, newType) {
        _updateHighlightStyle(highlight, newColor, newType);
      },
      onDelete: (highlightId) {
        _removeHighlight(highlight);
      },
    );
  }

  /// 显示快速记录弹窗（创建标注）
  void _showQuickCaptureSheet() {
    QuickCaptureSheet.show(
      context: context,
      selectedText: _selectedText,
      selectionStart: _selectionStart,
      selectionEnd: _selectionEnd,
      messageId: widget.messageId,
      topicId: widget.topicId,
      topicName: widget.contextData?['topicName'] as String?,
      onCreated: () {
        // 创建完成后重新加载高亮
        _loadHighlights();
      },
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

  /// 进入讨论界面（直接进入 AIChatScreen）
  void _showDiscussionSheet() {
    // 构建单回复的 contextData
    final contextData = {
      'rounds': [
        {
          'index': 0,
          'question': null, // 单回复讨论没有问题
          'replies': [
            {
              'id': widget.messageId,
              'model': {'name': widget.modelName},
              'useful': true,
              'blocks': [
                {'type': 'main_text', 'content': widget.content}
              ],
            }
          ],
        }
      ],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          initialContextId: widget.messageId,
          initialContextSnapshot: widget.content,
          initialTitle: '讨论',
          initialContextData: contextData,
          contextTypeFilter: ConversationContextType.singleMessage,
        ),
      ),
    );
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
            // 标注标签 - 已移除，避免重复显示 (inline 高亮已足够)
            // if (_highlights.isNotEmpty) _buildHighlightTags(),
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
                        // 标注标签 - 已移除
                        // if (_highlights.isNotEmpty) _buildHighlightTags(),
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
                    // if (_highlights.isNotEmpty) _buildHighlightTags(),
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

  // ... (existing state variables)
  
  // 浮动工具栏 Overlay
  OverlayEntry? _toolbarOverlay;
  Offset? _lastPointerPosition;
  
  // 【双向 HitTest】选择起点和终点位置
  Offset? _selectionStartPosition;
  Offset? _selectionEndPosition;

  @override
  void dispose() {
    _hideFloatingToolbar();
    // 【精确定位】清理闪烁动画
    _blinkController?.dispose();
    super.dispose();
  }

  void _hideFloatingToolbar() {
    _toolbarOverlay?.remove();
    _toolbarOverlay = null;
  }

  void _showFloatingToolbar(Offset position) {
    _hideFloatingToolbar();

    _toolbarOverlay = OverlayEntry(
      builder: (context) => FloatingSelectionToolbar(
        position: position,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: _selectedText));
          _hideFloatingToolbar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
          );
        },
        onHighlight: () {
          _addHighlightFromSelection(
            _selectedText, 
            _selectionStart, 
            _selectionEnd,
            prefix: _selectionPrefix,
            suffix: _selectionSuffix,
          );
          _hideFloatingToolbar();
        },
        highlightColor: _currentHighlightColor,
      ),
    );

    Overlay.of(context).insert(_toolbarOverlay!);
  }

  Widget _buildContent() {
    Widget contentWidget = Listener(
      onPointerDown: (event) {
        _hideFloatingToolbar();
        // 【双向 HitTest】记录选择起点
        _selectionStartPosition = event.position;
      },
      onPointerUp: (event) {
        _lastPointerPosition = event.position;
        // 【双向 HitTest】记录选择终点
        _selectionEndPosition = event.position;
        
        if (_selectedText.isNotEmpty) {
           Future.delayed(const Duration(milliseconds: 100), () {
             if (mounted && _selectedText.isNotEmpty) {
               _showFloatingToolbar(event.position);
             }
           });
        }
      },
      child: SelectionArea(
        onSelectionChanged: (selection) {
          if (selection != null) {
            final newSelectedText = selection.plainText;
            if (newSelectedText != _selectedText) {
               if (newSelectedText.isEmpty) {
                  _hideFloatingToolbar();
               }
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedText = newSelectedText;
                      // 【重构】使用新的单次解析架构获取纯文本，确保坐标一致
                      
                      _selectedText = newSelectedText;
                      // 【重构】Ensuring parse result is available
                      _cachedParseResult ??= _getParseResultFromMarkdown(_displayContent);
                      
                      // 【双向 HitTest】使用 _resolveSelection 解析坐标和 Block 信息
                      final resolution = _resolveSelection();
                      if (resolution != null) {
                        // 存储 Block 信息
                        _selectionStartBlockIndex = resolution.$1;
                        _selectionEndBlockIndex = resolution.$3;
                        _selectionStart = resolution.$2!;
                        _selectionEnd = resolution.$4!;
                        
                        print('📌 [Selection] Block: $_selectionStartBlockIndex -> $_selectionEndBlockIndex, Global: [$_selectionStart, $_selectionEnd]');
                      
                        // 提取上下文
                        const contextLen = 20;
                        final fullText = _cachedParseResult!.plainText;
                        final realStart = max(0, _selectionStart);
                        final realEnd = min(fullText.length, _selectionEnd);
                        
                        _selectionPrefix = fullText.substring(
                          max(0, realStart - contextLen), 
                          realStart
                        );
                        _selectionSuffix = fullText.substring(
                          realEnd,
                          min(fullText.length, realEnd + contextLen)
                        );
                      }
                    });
                  }
                });
            }
          }
        },
        child: _getMemoizedMarkdownWidget(),
      ),
    );
    
    // 【精确定位】如果有闪烁动画，包装闪烁边框效果
    if (_blinkAnimation != null && _blinkController != null) {
      return AnimatedBuilder(
        animation: _blinkAnimation!,
        builder: (context, child) {
          final opacity = _blinkAnimation!.value * 0.6;
          final targetHighlight = _highlights.firstWhere(
            (h) => h.id == widget.targetHighlightId,
            orElse: () => _highlights.first,
          );
          final highlightColor = Color(targetHighlight.color);
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: highlightColor.withValues(alpha: opacity),
                  blurRadius: 12 + 8 * _blinkAnimation!.value,
                  spreadRadius: 2 * _blinkAnimation!.value,
                ),
              ],
            ),
            child: child,
          );
        },
        child: contentWidget,
      );
    }
    
    return contentWidget;
  }


  
  /// Perform a hit test to find the block index at the given position
  int? _hitTestBlockIndex(Offset position) {
      // 使用 RenderBox 的 global hitTest
      // 我们需要 Context。
      // 注意：position 是 global 还是 local?
      // PointerEvent.position 是 global.
      // 我们需要从 RenderView 开始 hitTest?
      
      final result = BoxHitTestResult();
      // 获取 RenderView
      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) return null;
      
      // 转换本地坐标
      final localPosition = renderObject.globalToLocal(position);
      
      if (renderObject.hitTest(result, position: localPosition)) {
          // 遍历命中路径，寻找 MetaData
          for (final entry in result.path) {
              final target = entry.target;
              if (target is RenderMetaData) {
                  final data = target.metaData;
                  if (data is Map && data.containsKey('blockIndex')) {
                      return data['blockIndex'] as int;
                  }
              }
          }
      }
      return null;
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
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
            ),
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
                style: TextStyle(
                  fontSize: 10,
                  color: hintColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
