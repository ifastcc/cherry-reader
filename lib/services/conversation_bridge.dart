import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView ↔ Flutter 通信桥接层
/// 
/// 负责：
/// - 注册 JavaScript Handler 处理回调
/// - 封装 Flutter → JS 的调用
/// - 数据序列化/反序列化
class ConversationBridge {
  final InAppWebViewController controller;
  
  // 回调函数
  void Function(Map<String, dynamic>)? onContentReady;
  void Function(Map<String, dynamic>)? onScrollChanged;
  void Function(Map<String, dynamic>)? onTabChanged;
  void Function(Map<String, dynamic>)? onTextSelected;
  void Function(Map<String, dynamic>)? onHighlightCreated;
  void Function(Map<String, dynamic>)? onHighlightUpdated;
  void Function(Map<String, dynamic>)? onHighlightDeleted;
  void Function(Map<String, dynamic>)? onHighlightTapped;
  void Function(Map<String, dynamic>)? onSearchResult;
  void Function(Map<String, dynamic>)? onPlayTTS;
  void Function(Map<String, dynamic>)? onOpenDiscussion;
  void Function(Map<String, dynamic>)? onOpenNoteEditor;
  
  // 轮次数据请求回调
  Future<List<Map<String, dynamic>>> Function(List<int>)? onRequestRounds;

  ConversationBridge(this.controller);

  /// 注册所有 JavaScript Handler
  void registerHandlers() {
    // 内容就绪
    controller.addJavaScriptHandler(
      handlerName: 'onContentReady',
      callback: (args) {
        if (args.isNotEmpty && onContentReady != null) {
          onContentReady!(_parseArgs(args[0]));
        }
      },
    );

    // 滚动变化
    controller.addJavaScriptHandler(
      handlerName: 'onScrollChanged',
      callback: (args) {
        if (args.isNotEmpty && onScrollChanged != null) {
          onScrollChanged!(_parseArgs(args[0]));
        }
      },
    );

    // Tab 切换
    controller.addJavaScriptHandler(
      handlerName: 'onTabChanged',
      callback: (args) {
        if (args.isNotEmpty && onTabChanged != null) {
          onTabChanged!(_parseArgs(args[0]));
        }
      },
    );

    // 文本选择
    controller.addJavaScriptHandler(
      handlerName: 'onTextSelected',
      callback: (args) {
        if (args.isNotEmpty && onTextSelected != null) {
          onTextSelected!(_parseArgs(args[0]));
        }
      },
    );

    // 高亮创建
    controller.addJavaScriptHandler(
      handlerName: 'onHighlightCreated',
      callback: (args) {
        if (args.isNotEmpty && onHighlightCreated != null) {
          onHighlightCreated!(_parseArgs(args[0]));
        }
      },
    );

    // 高亮更新
    controller.addJavaScriptHandler(
      handlerName: 'onHighlightUpdated',
      callback: (args) {
        if (args.isNotEmpty && onHighlightUpdated != null) {
          onHighlightUpdated!(_parseArgs(args[0]));
        }
      },
    );

    // 高亮删除
    controller.addJavaScriptHandler(
      handlerName: 'onHighlightDeleted',
      callback: (args) {
        if (args.isNotEmpty && onHighlightDeleted != null) {
          onHighlightDeleted!(_parseArgs(args[0]));
        }
      },
    );

    // 高亮点击
    controller.addJavaScriptHandler(
      handlerName: 'onHighlightTapped',
      callback: (args) {
        if (args.isNotEmpty && onHighlightTapped != null) {
          onHighlightTapped!(_parseArgs(args[0]));
        }
      },
    );

    // 搜索结果
    controller.addJavaScriptHandler(
      handlerName: 'onSearchResult',
      callback: (args) {
        if (args.isNotEmpty && onSearchResult != null) {
          onSearchResult!(_parseArgs(args[0]));
        }
      },
    );

    // 播放 TTS
    controller.addJavaScriptHandler(
      handlerName: 'playTTS',
      callback: (args) {
        if (args.isNotEmpty && onPlayTTS != null) {
          onPlayTTS!(_parseArgs(args[0]));
        }
      },
    );

    // 打开讨论
    controller.addJavaScriptHandler(
      handlerName: 'openDiscussion',
      callback: (args) {
        if (args.isNotEmpty && onOpenDiscussion != null) {
          onOpenDiscussion!(_parseArgs(args[0]));
        }
      },
    );

    // 打开笔记编辑器
    controller.addJavaScriptHandler(
      handlerName: 'openNoteEditor',
      callback: (args) {
        if (args.isNotEmpty && onOpenNoteEditor != null) {
          onOpenNoteEditor!(_parseArgs(args[0]));
        }
      },
    );

    // 显示 Toast
    controller.addJavaScriptHandler(
      handlerName: 'showToast',
      callback: (args) {
        if (args.isNotEmpty) {
          final data = _parseArgs(args[0]);
          final message = data['message'] as String? ?? '';
          // TODO: 显示 Toast
          debugPrint('[ConversationBridge] showToast: $message');
        }
      },
    );

    // 复制到剪贴板
    controller.addJavaScriptHandler(
      handlerName: 'copyToClipboard',
      callback: (args) async {
        if (args.isNotEmpty) {
          final data = _parseArgs(args[0]);
          final text = data['text'] as String? ?? '';
          await Clipboard.setData(ClipboardData(text: text));
          if (data['showToast'] == true) {
            // TODO: 显示复制成功 Toast
            debugPrint('[ConversationBridge] Copied to clipboard: ${text.substring(0, text.length.clamp(0, 50))}...');
          }
        }
      },
    );

    // 请求更多轮次
    controller.addJavaScriptHandler(
      handlerName: 'requestRounds',
      callback: (args) async {
        if (args.isEmpty || onRequestRounds == null) return null;
        
        final data = _parseArgs(args[0]);
        final indices = (data['indices'] as List?)?.cast<int>() ?? [];
        
        if (indices.isEmpty) return null;
        
        final rounds = await onRequestRounds!(indices);
        return jsonEncode(rounds);
      },
    );
  }

  Map<String, dynamic> _parseArgs(dynamic arg) {
    if (arg is Map) {
      return Map<String, dynamic>.from(arg);
    }
    if (arg is String) {
      try {
        return jsonDecode(arg) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  // ========== Flutter → JS 调用 ==========

  /// 初始化对话数据
  Future<void> initConversation(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    await controller.evaluateJavascript(
      source: 'window.initConversation($jsonStr)',
    );
  }

  /// 加载对话数据（切换话题时）
  Future<void> loadConversation(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    await controller.evaluateJavascript(
      source: 'window.loadConversation($jsonStr)',
    );
  }

  /// 追加更多轮次
  Future<void> appendRounds(List<Map<String, dynamic>> rounds) async {
    final jsonStr = jsonEncode(rounds);
    await controller.evaluateJavascript(
      source: 'window.appendRounds($jsonStr)',
    );
  }

  /// 设置暗色模式
  Future<void> setDarkMode(bool isDark) async {
    await controller.evaluateJavascript(
      source: 'window.setDarkMode($isDark)',
    );
  }

  /// 滚动到指定轮次
  Future<void> scrollToRound(int index) async {
    await controller.evaluateJavascript(
      source: 'window.scrollToRound($index)',
    );
  }

  /// 滚动到指定高亮
  Future<void> scrollToHighlight(String highlightId) async {
    await controller.evaluateJavascript(
      source: 'window.HighlightManager.scrollToHighlight("$highlightId")',
    );
  }

  /// 设置搜索关键词
  Future<void> setSearchKeyword(String keyword) async {
    final escapedKeyword = jsonEncode(keyword);
    await controller.evaluateJavascript(
      source: 'window.setSearchKeyword($escapedKeyword)',
    );
  }

  /// 搜索下一个
  Future<void> searchNext() async {
    await controller.evaluateJavascript(source: 'window.searchNext()');
  }

  /// 搜索上一个
  Future<void> searchPrev() async {
    await controller.evaluateJavascript(source: 'window.searchPrev()');
  }

  /// 关闭搜索
  Future<void> closeSearch() async {
    await controller.evaluateJavascript(source: 'window.closeSearch()');
  }

  /// 更新高亮样式
  Future<void> updateHighlight(String highlightId, {String? color, String? style}) async {
    if (color != null) {
      await controller.evaluateJavascript(
        source: 'window.HighlightManager.updateHighlightColor("$highlightId", "$color")',
      );
    }
    if (style != null) {
      await controller.evaluateJavascript(
        source: 'window.HighlightManager.updateHighlightStyle("$highlightId", "$style")',
      );
    }
  }

  /// 删除高亮
  Future<void> removeHighlight(String highlightId) async {
    await controller.evaluateJavascript(
      source: 'window.HighlightManager.removeHighlight("$highlightId")',
    );
  }
}

/// 将对话数据转换为 WebView 所需的格式
class ConversationDataConverter {
  /// 转换完整对话数据
  static Map<String, dynamic> convertConversation({
    required String topicId,
    required String topicName,
    required bool isDarkMode,
    required List<Map<String, dynamic>> groups,
    required Map<String, List<Map<String, dynamic>>> highlightsMap,
    int? scrollToRoundIndex,
    String? scrollToMessageId,
    String? scrollToHighlightId,
    String? searchKeyword,
  }) {
    final rounds = <Map<String, dynamic>>[];
    
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      rounds.add(convertGroup(group, i, highlightsMap));
    }

    return {
      'topicId': topicId,
      'topicName': topicName,
      'isDarkMode': isDarkMode,
      'totalRounds': groups.length,
      'rounds': rounds,
      'scrollToRoundIndex': scrollToRoundIndex,
      'scrollToMessageId': scrollToMessageId,
      'scrollToHighlightId': scrollToHighlightId,
      'searchKeyword': searchKeyword ?? '',
    };
  }

  /// 转换单个轮次
  static Map<String, dynamic> convertGroup(
    Map<String, dynamic> group,
    int index,
    Map<String, List<Map<String, dynamic>>> highlightsMap,
  ) {
    final userMessage = group['userMessage'] as Map<String, dynamic>?;
    final assistantReplies = (group['assistantReplies'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];

    // 收集该轮次的高亮
    final roundHighlights = <String, List<Map<String, dynamic>>>{};
    
    for (final reply in assistantReplies) {
      final messageId = reply['id'] as String?;
      if (messageId != null && highlightsMap.containsKey(messageId)) {
        roundHighlights[messageId] = highlightsMap[messageId]!;
      }
    }

    return <String, dynamic>{
      'index': index,
      'userMessage': userMessage != null ? <String, dynamic>{
        'id': userMessage['id'],
        'content': userMessage['content'] ?? '',
      } : null,
      'assistantReplies': assistantReplies.map((reply) {
        // 【修复】从嵌套的 model 对象中提取模型信息
        final model = reply['model'] as Map<String, dynamic>?;
        final modelName = model?['name'] as String? ?? reply['modelName'] as String? ?? 'AI';
        final modelId = model?['id'] as String? ?? reply['modelId'] as String? ?? '';
        
        return <String, dynamic>{
          'id': reply['id'],
          'modelName': modelName,
          'modelId': modelId,
          'content': reply['content'] ?? '',
          'isMainline': reply['isMainline'] ?? false,
        };
      }).toList(),
      'highlights': roundHighlights,
    };
  }

  /// 转换高亮数据为 v3.0 格式
  static Map<String, dynamic> convertHighlight(Map<String, dynamic> highlight) {
    // 颜色格式转换：0xFFFFF176 → #FFF176
    final color = highlight['color'];
    String colorStr;
    if (color is int) {
      colorStr = '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    } else if (color is String) {
      colorStr = color.startsWith('#') ? color : '#$color';
    } else {
      colorStr = '#FFF176';
    }

    return {
      'id': highlight['id'],
      'messageId': highlight['messageId'],
      'text': highlight['text'] ?? '',
      'color': colorStr,
      'style': highlight['style'] ?? highlight['styleType'] ?? 'background',
      'ranges': highlight['ranges'] ?? [],
      'prefix': highlight['prefix'] ?? '',
      'suffix': highlight['suffix'] ?? '',
      'createdAt': highlight['createdAt'],
    };
  }
}
