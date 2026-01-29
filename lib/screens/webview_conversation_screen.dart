import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../models/highlight_data.dart';
import '../models/knowledge_item.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../providers/tts_provider.dart';
import '../services/conversation_bridge.dart';
import '../services/highlight_service.dart';
import '../services/knowledge_entry_service.dart';
import '../services/topic_service.dart';
import '../widgets/knowledge/quick_capture_sheet.dart';
import 'tts_player_screen.dart';
import 'ai_chat_screen.dart';

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
  final String? conversationDataJson;
  final int? scrollToGroupIndex;
  final String? scrollToMessageId;
  final String? scrollToHighlightId;
  final int? scrollToTextStart;
  final int? scrollToTextEnd;
  final String? scrollToQuotedText;
  final int? scrollToQuotedTextOccurrence;
  
  /// 返回回调（用于 Stack 架构）
  /// 如果提供，则调用此回调而非 Navigator.pop
  final VoidCallback? onBack;

  const WebViewConversationScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    this.conversationDataJson,
    this.scrollToGroupIndex,
    this.scrollToMessageId,
    this.scrollToHighlightId,
    this.scrollToTextStart,
    this.scrollToTextEnd,
    this.scrollToQuotedText,
    this.scrollToQuotedTextOccurrence,
    this.onBack,
  });

  @override
  State<WebViewConversationScreen> createState() => _WebViewConversationScreenState();
}

class _WebViewConversationScreenState extends State<WebViewConversationScreen> {
  InAppWebViewController? _controller;
  ConversationBridge? _bridge;
  Map<String, dynamic>? _pendingNavigationPayload;
  
  bool _isLoading = true;
  bool _isSearchMode = false;
  bool _isExiting = false; // 【新增】退出时的淡出遮盖
  String? _fatalError;
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
  void didUpdateWidget(covariant WebViewConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topicId != oldWidget.topicId) return;

    final shouldNavigate = widget.scrollToGroupIndex != oldWidget.scrollToGroupIndex ||
        widget.scrollToMessageId != oldWidget.scrollToMessageId ||
        widget.scrollToHighlightId != oldWidget.scrollToHighlightId ||
        widget.scrollToTextStart != oldWidget.scrollToTextStart ||
        widget.scrollToTextEnd != oldWidget.scrollToTextEnd ||
        widget.scrollToQuotedText != oldWidget.scrollToQuotedText ||
        widget.scrollToQuotedTextOccurrence != oldWidget.scrollToQuotedTextOccurrence;

    if (shouldNavigate) {
      _pendingNavigationPayload = _buildNavigationPayload();
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildNavigationPayload() {
    return <String, dynamic>{
      'scrollToRoundIndex': widget.scrollToGroupIndex,
      'scrollToMessageId': widget.scrollToMessageId,
      'scrollToHighlightId': widget.scrollToHighlightId,
      'scrollToTextStart': widget.scrollToTextStart,
      'scrollToTextEnd': widget.scrollToTextEnd,
      'scrollToQuotedText': widget.scrollToQuotedText,
      'scrollToQuotedTextOccurrence': widget.scrollToQuotedTextOccurrence,
    };
  }

  Future<void> _tryNavigate() async {
    if (_controller == null || _pendingNavigationPayload == null) return;
    if (_isLoading) return;
    final payload = _pendingNavigationPayload;
    _pendingNavigationPayload = null;
    await _controller!.evaluateJavascript(
      source: 'window.navigateTo(${jsonEncode(payload)})',
    );
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
      if (widget.conversationDataJson != null &&
          widget.conversationDataJson!.isNotEmpty) {
        final decoded = jsonDecode(widget.conversationDataJson!);
        if (decoded is Map<String, dynamic>) {
          _groups = _extractGroups(decoded);
          await _loadHighlights();
          if (mounted) {
            setState(() {
              _conversationData = decoded;
              _fatalError = null;
            });
          }
          return;
        }
      }

      // 使用 TopicService 加载对话数据
      final conv = await _topicService.getTopicFullData(widget.topicId);
      if (conv == null) {
        debugPrint('[WebViewConversation] Conversation not found: ${widget.topicId}');
        if (mounted) {
          setState(() {
            _fatalError = 'Conversation not found: ${widget.topicId}';
            _isLoading = false;
          });
        }
        return;
      }
      
      // 提取轮次数据
      _groups = _extractGroups(conv);
      
      // 加载高亮数据
      await _loadHighlights();
      
      setState(() {
        _conversationData = conv;
        _fatalError = null;
      });
    } catch (e) {
      debugPrint('[WebViewConversation] Failed to load data: $e');
      if (mounted) {
        setState(() {
          _fatalError = 'Failed to load conversation: $e';
          _isLoading = false;
        });
      }
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

  Future<void> _refreshHighlightsForMessage(String messageId) async {
    if (messageId.isEmpty) return;
    final highlightService = HighlightService();
    final highlights = await highlightService.loadHighlights(messageId);

    if (highlights.isNotEmpty) {
      _highlightsMap[messageId] =
          highlights.map((h) => ConversationDataConverter.convertHighlight(h.toJson())).toList();
    } else {
      _highlightsMap.remove(messageId);
    }

    final payload = _highlightsMap[messageId] ?? const <Map<String, dynamic>>[];
    await _controller?.evaluateJavascript(
      source:
          'window.HighlightManager && window.HighlightManager.applyHighlights(${jsonEncode(messageId)}, ${jsonEncode(payload)})',
    );
  }

  void _setupBridge(InAppWebViewController controller) {
    _bridge = ConversationBridge(controller);
    
    _bridge!.onContentReady = (data) {
      debugPrint('[WebViewConversation] Content ready: $data');
      setState(() {
        _isLoading = false;
      });
      _tryNavigate();
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

    _bridge!.onTextSelected = (data) {
      debugPrint('[WebViewConversation] Text selected: $data');
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

    _bridge!.onOpenAnnotationEditor = (data) async {
      final selectedText = data['text'] as String? ?? '';
      final messageId = data['messageId'] as String? ?? '';
      final selectionStart = data['selectionStart'] as int?;
      final selectionEnd = data['selectionEnd'] as int?;
      if (!mounted || messageId.isEmpty) return;

      await QuickCaptureSheet.show(
        context: context,
        selectedText: selectedText,
        selectionStart: selectionStart,
        selectionEnd: selectionEnd,
        messageId: messageId,
        topicId: widget.topicId,
        topicName: widget.topicName,
        initialType: KnowledgeType.annotation,
        onCreated: () {
          _refreshHighlightsForMessage(messageId);
        },
      );
    };

    _bridge!.onSearchResult = (data) {
      setState(() {
        _searchTotal = data['total'] as int? ?? 0;
        _searchCurrent = data['current'] as int? ?? -1;
      });
    };

    _bridge!.onPlayTTS = (data) async {
      debugPrint('[WebViewConversation] Play TTS: $data');
      final roundIndex = data['roundIndex'] as int? ?? _currentRoundIndex;
      
      // 获取当前轮次的 assistant 回复内容
      if (roundIndex >= 0 && roundIndex < _groups.length) {
        final group = _groups[roundIndex];
        final replies = group['assistantReplies'] as List? ?? [];
        if (replies.isNotEmpty) {
          // 默认使用第一个回复（主线）
          final reply = replies.first as Map<String, dynamic>;
          final content = reply['content'] as String? ?? '';
          final messageId = reply['id'] as String? ?? '';
          
          if (content.isNotEmpty && mounted) {
            // 使用 TtsProvider 启动朗读
            final ttsProvider = context.read<TtsProvider>();
            await ttsProvider.startReading(
              messageId: messageId,
              text: content,
              title: widget.topicName,
            );
            
            // 跳转到 TTS 播放页面
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TtsPlayerScreen()),
              );
            }
          }
        }
      }
    };

    _bridge!.onOpenDiscussion = (data) {
      debugPrint('[WebViewConversation] Open discussion: $data');
      final roundIndex = data['roundIndex'] as int? ?? _currentRoundIndex;
      final replyIndex = data['replyIndex'] as int? ?? 0;
      
      // 获取对应的回复数据
      if (roundIndex >= 0 && roundIndex < _groups.length) {
        final group = _groups[roundIndex];
        final replies = group['assistantReplies'] as List? ?? [];
        if (replyIndex >= 0 && replyIndex < replies.length) {
          final reply = replies[replyIndex] as Map<String, dynamic>;
          _openSingleMessageDiscussion(reply);
        } else if (replies.isNotEmpty) {
          // 默认使用第一个回复
          _openSingleMessageDiscussion(replies.first as Map<String, dynamic>);
        }
      }
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

    int? targetGroupIndex = widget.scrollToGroupIndex;
    if (targetGroupIndex == null && widget.scrollToMessageId != null) {
      targetGroupIndex = _findGroupIndexForMessageId(widget.scrollToMessageId!);
      if (targetGroupIndex == -1) {
        targetGroupIndex = null;
      }
    }

    final initialLoadCount = min(
      _groups.length,
      max(3, (targetGroupIndex ?? -1) + 1),
    );

    // 转换数据格式
    final data = ConversationDataConverter.convertConversation(
      topicId: widget.topicId,
      topicName: widget.topicName,
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      groups: _groups.take(initialLoadCount).toList(),
      highlightsMap: _highlightsMap,
      scrollToRoundIndex: widget.scrollToGroupIndex,
      scrollToMessageId: widget.scrollToMessageId,
      scrollToHighlightId: widget.scrollToHighlightId,
      scrollToTextStart: widget.scrollToTextStart,
      scrollToTextEnd: widget.scrollToTextEnd,
      scrollToQuotedText: widget.scrollToQuotedText,
      scrollToQuotedTextOccurrence: widget.scrollToQuotedTextOccurrence,
    );

    // 更新总轮次数
    data['totalRounds'] = _groups.length;

    await _bridge!.initConversation(data);
  }

  int _findGroupIndexForMessageId(String messageId) {
    for (int i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      final user = group['userMessage'] as Map<String, dynamic>?;
      if (user?['id'] == messageId) return i;
      final replies = group['assistantReplies'] as List? ?? [];
      for (final reply in replies) {
        if (reply is Map && reply['id'] == messageId) return i;
      }
    }
    return -1;
  }

  // ========== 高亮操作 ==========
  
  Future<void> _saveHighlight(Map<String, dynamic> data) async {
    try {
      final messageId = data['messageId'] as String?;
      if (messageId == null) return;
      
      final highlightService = HighlightService();
      
      // 构建 HighlightData
      final highlight = HighlightData(
        id: data['id'] as String?,
        messageId: messageId,
        start: data['start'] as int? ?? 0,
        end: data['end'] as int? ?? 0,
        text: data['text'] as String? ?? '',
        color: data['color'] as String? ?? '#FFF176',
        style: data['style'] as String? ?? 'background',
        ranges: const [],
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
      highlightService.clearCache(messageId);

      final text = data['text'] as String? ?? '';
      if (text.isNotEmpty) {
        final entryService = KnowledgeEntryService();
        final entry = await entryService.getEntry(highlightId);
        if (entry == null) {
          await entryService.deleteByMessageAndQuotedText(messageId, text);
          highlightService.clearCache(messageId);
        }
      }
      
      debugPrint('[WebViewConversation] Highlight deleted: $highlightId');
    } catch (e) {
      debugPrint('[WebViewConversation] Failed to delete highlight: $e');
    }
  }

  // ========== 讨论 ==========
  
  void _openSingleMessageDiscussion(Map<String, dynamic> reply) {
    final model = reply['model'] as Map<String, dynamic>?;
    final modelName = model?['name'] as String? ?? reply['modelName'] as String? ?? 'Assistant';
    final messageId = reply['id'] as String? ?? '';
    final content = reply['content'] as String? ?? '';

    // 构建上下文数据
    final contextData = {
      'rounds': [
        {
          'index': 0,
          'question': null,
          'replies': [reply],
        }
      ],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          initialContextId: messageId,
          initialContextSnapshot: content,
          initialTitle: '讨论: $modelName',
          initialContextData: contextData,
          contextTypeFilter: ConversationContextType.singleMessage,
        ),
      ),
    );
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
      canPop: widget.onBack == null, // 如果没有 onBack，允许正常 pop
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // 使用 onBack 回调（Stack 架构）
        if (widget.onBack != null) {
          widget.onBack!();
          return;
        }
        
        // 兼容 Navigator.push 模式：先显示遮盖再 pop
        setState(() {
          _isExiting = true;
        });
        
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
              if (_fatalError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fatalError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _fatalError = null;
                                  _isLoading = true;
                                });
                                _loadConversationData();
                              },
                              child: const Text('重试'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                if (widget.onBack != null) {
                                  widget.onBack!();
                                } else {
                                  Navigator.of(context).maybePop();
                                }
                              },
                              child: const Text('返回'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              // WebView
              if (_fatalError == null && _conversationData != null && !_isExiting)
                InAppWebView(
                  initialFile: 'assets/webview/conversation.html',
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: false,
                    supportZoom: false,
                    useHybridComposition: true,
                    cacheEnabled: false,
                    clearCache: true,
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    verticalScrollBarEnabled: false,
                    horizontalScrollBarEnabled: false,
                    disallowOverScroll: true,
                    overScrollMode: OverScrollMode.NEVER,
                    alwaysBounceVertical: false,
                    alwaysBounceHorizontal: false,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    _setupBridge(controller);
                  },
                  onLoadStart: (controller, url) {
                    debugPrint('[WebViewConversation] Load start: $url');
                  },
                  onLoadStop: (controller, url) async {
                    await controller.evaluateJavascript(
                      source: 'window.initFramework && window.initFramework()',
                    );
                    await _bridge?.setDarkMode(isDark);
                    await _injectConversationData();
                  },
                  onReceivedError: (controller, request, error) {
                    debugPrint('[WebViewConversation] Load error: ${error.description}');
                    if (mounted) {
                      setState(() {
                        _fatalError = 'WebView load error: ${error.description}';
                        _isLoading = false;
                      });
                    }
                  },
                  onReceivedHttpError: (controller, request, errorResponse) {
                    debugPrint(
                      '[WebViewConversation] HTTP error: ${errorResponse.statusCode} ${errorResponse.reasonPhrase}',
                    );
                    if (mounted) {
                      setState(() {
                        _fatalError =
                            'WebView HTTP error: ${errorResponse.statusCode} ${errorResponse.reasonPhrase ?? ''}';
                        _isLoading = false;
                      });
                    }
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.of(context).maybePop();
          }
        },
      ),
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
