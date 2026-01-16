import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/highlight_data.dart';
import '../services/conversation_bridge.dart';
import '../services/highlight_service.dart';
import '../services/topic_service.dart';

/// WebView 版话题详情页
/// 
/// 使用 WebView 渲染整个对话内容，支持：
/// - 完美的文本选择体验
/// - Markdown 富文本渲染
/// - 高亮创建/编辑/删除
/// - 能量条、Tab 切换、Swiper 滑动
class WebViewConversationScreen extends StatefulWidget {
  final String topicId;
  final String topicName;
  final int? scrollToGroupIndex;
  final String? scrollToMessageId;
  final String? scrollToHighlightId;

  const WebViewConversationScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    this.scrollToGroupIndex,
    this.scrollToMessageId,
    this.scrollToHighlightId,
  });

  @override
  State<WebViewConversationScreen> createState() => _WebViewConversationScreenState();
}

class _WebViewConversationScreenState extends State<WebViewConversationScreen> {
  InAppWebViewController? _controller;
  ConversationBridge? _bridge;
  
  bool _isLoading = true;
  bool _isSearchMode = false;
  bool _isExiting = false; // 【新增】退出时的淡出遮盖
  int _searchTotal = 0;
  int _searchCurrent = -1;
  final TextEditingController _searchController = TextEditingController();
  
  // 对话数据
  Map<String, dynamic>? _conversationData;
  List<Map<String, dynamic>> _groups = [];
  Map<String, List<Map<String, dynamic>>> _highlightsMap = {};
  
  // 当前状态
  int _currentRoundIndex = 0;
  
  late final TopicService _topicService;

  @override
  void initState() {
    super.initState();
    _topicService = TopicService();
    _loadConversationData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 【新增】优雅退出：先淡出遮盖再 pop
  Future<bool> _handleWillPop() async {
    if (_isExiting) return true;
    
    setState(() {
      _isExiting = true;
    });
    
    // 等待淡出动画完成
    await Future.delayed(const Duration(milliseconds: 150));
    
    return true;
  }


  /// 加载对话数据
  Future<void> _loadConversationData() async {
    try {
      // 使用 TopicService 加载对话数据
      final conv = await _topicService.getTopicFullData(widget.topicId);
      if (conv == null) {
        debugPrint('[WebViewConversation] Conversation not found: ${widget.topicId}');
        return;
      }
      
      // 提取轮次数据
      _groups = _extractGroups(conv);
      
      // 加载高亮数据
      await _loadHighlights();
      
      setState(() {
        _conversationData = conv;
      });
    } catch (e) {
      debugPrint('[WebViewConversation] Failed to load data: $e');
    }
  }

  List<Map<String, dynamic>> _extractGroups(Map<String, dynamic> conv) {
    final groups = <Map<String, dynamic>>[];
    final messages = conv['messages'] as List? ?? [];
    
    Map<String, dynamic>? currentUserMessage;
    List<Map<String, dynamic>> currentReplies = [];

    for (final msg in messages) {
      final role = msg['role'] as String?;
      
      // 【关键修复】从 blocks 中提取完整的 markdown 内容
      final content = _extractContentFromBlocks(msg);
      final processedMsg = Map<String, dynamic>.from(msg);
      processedMsg['content'] = content;
      
      if (role == 'user') {
        if (currentUserMessage != null) {
          groups.add({
            'userMessage': currentUserMessage,
            'assistantReplies': currentReplies,
          });
        }
        currentUserMessage = processedMsg;
        currentReplies = [];
      } else if (role == 'assistant') {
        currentReplies.add(processedMsg);
      }
    }
    
    if (currentUserMessage != null) {
      groups.add({
        'userMessage': currentUserMessage,
        'assistantReplies': currentReplies,
      });
    }
    
    debugPrint('[WebViewConversation] Extracted ${groups.length} groups');
    
    return groups;
  }

  /// 【关键】从 blocks 数组中提取并合并得到完整的 markdown 字符串
  String _extractContentFromBlocks(Map<String, dynamic> msg) {
    // 优先使用 content 字段（如果存在）
    final directContent = msg['content'] as String?;
    if (directContent != null && directContent.isNotEmpty) {
      return directContent;
    }
    
    // 从 blocks 中提取
    final blocks = msg['blocks'] as List?;
    if (blocks == null || blocks.isEmpty) {
      return '';
    }
    
    final buffer = StringBuffer();
    for (final block in blocks) {
      final blockContent = block['content'] as String?;
      if (blockContent != null && blockContent.isNotEmpty) {
        if (buffer.isNotEmpty) {
          buffer.write('\n');
        }
        buffer.write(blockContent);
      }
    }
    
    return buffer.toString();
  }


  Future<void> _loadHighlights() async {
    // 从 HighlightService 加载所有消息的高亮  
    final highlightService = HighlightService();
    _highlightsMap = {};
    
    for (final group in _groups) {
      final replies = group['assistantReplies'] as List? ?? [];
      for (final reply in replies) {
        final messageId = reply['id'] as String?;
        if (messageId != null) {
          final highlights = await highlightService.loadHighlights(messageId);
          if (highlights.isNotEmpty) {
            _highlightsMap[messageId] = highlights.map((h) => ConversationDataConverter.convertHighlight(h.toJson())).toList();
          }
        }
      }
    }
    
    debugPrint('[WebViewConversation] Loaded highlights for ${_highlightsMap.length} messages');
  }

  void _setupBridge(InAppWebViewController controller) {
    _bridge = ConversationBridge(controller);
    
    _bridge!.onContentReady = (data) {
      debugPrint('[WebViewConversation] Content ready: $data');
      setState(() {
        _isLoading = false;
      });
    };

    _bridge!.onScrollChanged = (data) {
      final roundIndex = data['currentRound'] as int?;
      if (roundIndex != null) {
        setState(() {
          _currentRoundIndex = roundIndex;
        });
      }
    };

    _bridge!.onTabChanged = (data) {
      debugPrint('[WebViewConversation] Tab changed: $data');
    };

    _bridge!.onHighlightCreated = (data) async {
      debugPrint('[WebViewConversation] Highlight created: $data');
      await _saveHighlight(data);
    };

    _bridge!.onHighlightUpdated = (data) async {
      debugPrint('[WebViewConversation] Highlight updated: $data');
      await _updateHighlight(data);
    };

    _bridge!.onHighlightDeleted = (data) async {
      debugPrint('[WebViewConversation] Highlight deleted: $data');
      await _deleteHighlight(data);
    };

    _bridge!.onSearchResult = (data) {
      setState(() {
        _searchTotal = data['total'] as int? ?? 0;
        _searchCurrent = data['current'] as int? ?? -1;
      });
    };

    _bridge!.onPlayTTS = (data) {
      debugPrint('[WebViewConversation] Play TTS: $data');
      // TODO: 调用 TTS 服务
    };

    _bridge!.onOpenDiscussion = (data) {
      debugPrint('[WebViewConversation] Open discussion: $data');
      // TODO: 跳转到讨论页面
    };

    _bridge!.onRequestRounds = (indices) async {
      // 返回请求的轮次数据
      final rounds = <Map<String, dynamic>>[];
      for (final index in indices) {
        if (index >= 0 && index < _groups.length) {
          rounds.add(ConversationDataConverter.convertGroup(
            _groups[index],
            index,
            _highlightsMap,
          ));
        }
      }
      return rounds;
    };

    _bridge!.registerHandlers();
  }

  Future<void> _injectConversationData() async {
    if (_bridge == null || _groups.isEmpty) return;

    // 转换数据格式
    final data = ConversationDataConverter.convertConversation(
      topicId: widget.topicId,
      topicName: widget.topicName,
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      groups: _groups.take(3).toList(), // 首屏只加载 3 轮
      highlightsMap: _highlightsMap,
      scrollToRoundIndex: widget.scrollToGroupIndex,
      scrollToMessageId: widget.scrollToMessageId,
      scrollToHighlightId: widget.scrollToHighlightId,
    );

    // 更新总轮次数
    data['totalRounds'] = _groups.length;

    await _bridge!.initConversation(data);
  }

  // ========== 高亮操作 ==========
  
  Future<void> _saveHighlight(Map<String, dynamic> data) async {
    try {
      final messageId = data['messageId'] as String?;
      if (messageId == null) return;
      
      final highlightService = HighlightService();
      
      // 构建 HighlightData
      final ranges = (data['ranges'] as List?)?.map((r) => HighlightRange(
        blockIndex: r['blockIndex'] as int? ?? 0,
        start: r['start'] as int? ?? 0,
        end: r['end'] as int? ?? 0,
        text: r['text'] as String? ?? '',
      )).toList() ?? [];
      
      final highlight = HighlightData(
        id: data['id'] as String?,
        messageId: messageId,
        text: data['text'] as String? ?? '',
        color: data['color'] as String? ?? '#FFF176',
        style: data['style'] as String? ?? 'background',
        ranges: ranges,
        prefix: data['prefix'] as String? ?? '',
        suffix: data['suffix'] as String? ?? '',
      );
      
      await highlightService.addHighlight(
        messageId,
        highlight,
        topicId: widget.topicId,
        topicName: widget.topicName,
      );
      
      debugPrint('[WebViewConversation] Highlight saved: ${highlight.id}');
    } catch (e) {
      debugPrint('[WebViewConversation] Failed to save highlight: $e');
    }
  }

  Future<void> _updateHighlight(Map<String, dynamic> data) async {
    try {
      final messageId = data['messageId'] as String?;
      final highlightId = data['highlightId'] as String?;
      if (messageId == null || highlightId == null) return;
      
      final highlightService = HighlightService();
      final newColor = data['color'] as String? ?? '#FFF176';
      final newStyle = data['style'] as String? ?? 'background';
      
      await highlightService.updateHighlightStyle(
        messageId,
        highlightId,
        newColor,
        newStyle,
      );
      
      debugPrint('[WebViewConversation] Highlight updated: $highlightId');
    } catch (e) {
      debugPrint('[WebViewConversation] Failed to update highlight: $e');
    }
  }

  Future<void> _deleteHighlight(Map<String, dynamic> data) async {
    try {
      final messageId = data['messageId'] as String?;
      final highlightId = data['highlightId'] as String?;
      if (messageId == null || highlightId == null) return;
      
      final highlightService = HighlightService();
      await highlightService.removeHighlight(messageId, highlightId);
      
      debugPrint('[WebViewConversation] Highlight deleted: $highlightId');
    } catch (e) {
      debugPrint('[WebViewConversation] Failed to delete highlight: $e');
    }
  }

  // ========== 搜索 ==========
  
  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
  }

  void _exitSearchMode() {
    _bridge?.closeSearch();
    setState(() {
      _isSearchMode = false;
      _searchTotal = 0;
      _searchCurrent = -1;
    });
    _searchController.clear();
  }

  void _onSearchChanged(String value) {
    _bridge?.setSearchKeyword(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF8F9FA);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // 先显示遮盖
        setState(() {
          _isExiting = true;
        });
        
        // 等待一小段时间让遮盖层渲染
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(isDark),
        body: Container(
          color: bgColor,
          child: Stack(
            children: [
              // WebView
              if (_conversationData != null && !_isExiting)
                InAppWebView(
                  initialFile: 'assets/webview/conversation.html',
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: false,
                    supportZoom: false,
                    useHybridComposition: true,
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    _setupBridge(controller);
                  },
                  onLoadStop: (controller, url) async {
                    await _bridge?.setDarkMode(isDark);
                    await _injectConversationData();
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint('[WebView Console] ${consoleMessage.message}');
                  },
                ),
              
              // 加载指示器
              if (_isLoading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const CircularProgressIndicator(),
                  ),
                ),
              
              // 【新增】退出时的遮盖层
              if (_isExiting)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: 1.0,
                  child: Container(color: bgColor),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    if (_isSearchMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _exitSearchMode,
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchTotal > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${_searchCurrent + 1}/$_searchTotal',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: _searchTotal > 0 ? () => _bridge?.searchPrev() : null,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: _searchTotal > 0 ? () => _bridge?.searchNext() : null,
          ),
        ],
      );
    }

    return AppBar(
      title: Text(
        widget.topicName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _enterSearchMode,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: 显示更多选项
          },
        ),
      ],
    );
  }
}
