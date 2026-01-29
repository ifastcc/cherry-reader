import 'package:flutter/foundation.dart';

/// WebView 话题详情页的导航参数
class WebViewNavigationParams {
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

  const WebViewNavigationParams({
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
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebViewNavigationParams &&
          runtimeType == other.runtimeType &&
          topicId == other.topicId;

  @override
  int get hashCode => topicId.hashCode;
}

/// WebView 导航状态管理器
/// 
/// 控制 WebView 话题详情页的显示/隐藏，实现保活效果：
/// - WebView 始终存在于 Widget 树中
/// - 通过 Offstage 控制显示/隐藏
/// - 避免每次进入时重新创建 WebView
class WebViewNavigationController extends ChangeNotifier {
  /// 是否显示 WebView 页面
  bool _isVisible = false;
  
  /// 当前显示的话题参数
  WebViewNavigationParams? _currentParams;
  
  /// 是否正在执行退出动画
  bool _isExiting = false;

  /// 是否显示 WebView 页面
  bool get isVisible => _isVisible;
  
  /// 当前话题 ID
  String? get currentTopicId => _currentParams?.topicId;
  
  /// 当前话题名称
  String? get currentTopicName => _currentParams?.topicName;
  
  /// 当前导航参数
  WebViewNavigationParams? get currentParams => _currentParams;
  
  /// 是否正在退出
  bool get isExiting => _isExiting;

  /// 显示 WebView 话题详情页
  void showWebView({
    required String topicId,
    required String topicName,
    String? conversationDataJson,
    int? scrollToGroupIndex,
    String? scrollToMessageId,
    String? scrollToHighlightId,
    int? scrollToTextStart,
    int? scrollToTextEnd,
    String? scrollToQuotedText,
    int? scrollToQuotedTextOccurrence,
  }) {
    final newParams = WebViewNavigationParams(
      topicId: topicId,
      topicName: topicName,
      conversationDataJson: conversationDataJson,
      scrollToGroupIndex: scrollToGroupIndex,
      scrollToMessageId: scrollToMessageId,
      scrollToHighlightId: scrollToHighlightId,
      scrollToTextStart: scrollToTextStart,
      scrollToTextEnd: scrollToTextEnd,
      scrollToQuotedText: scrollToQuotedText,
      scrollToQuotedTextOccurrence: scrollToQuotedTextOccurrence,
    );
    
    if (_currentParams?.topicId == topicId) {
      _currentParams = newParams;
      _isVisible = true;
      _isExiting = false;
      notifyListeners();
      debugPrint('[WebViewNav] Update params: $topicId');
      return;
    }
    
    // 不同话题，更新参数
    _currentParams = newParams;
    _isVisible = true;
    _isExiting = false;
    notifyListeners();
    
    debugPrint('[WebViewNav] Show: $topicId');
  }

  /// 隐藏 WebView 话题详情页
  void hideWebView() {
    if (!_isVisible) return;
    
    _isVisible = false;
    _isExiting = false;
    notifyListeners();
    
    debugPrint('[WebViewNav] Hide');
  }

  /// 开始退出动画
  void startExiting() {
    _isExiting = true;
    notifyListeners();
  }

  /// 切换到新话题（复用现有 WebView）
  void switchToTopic({
    required String topicId,
    required String topicName,
    int? scrollToGroupIndex,
    String? scrollToMessageId,
    String? scrollToHighlightId,
    int? scrollToTextStart,
    int? scrollToTextEnd,
    String? scrollToQuotedText,
    int? scrollToQuotedTextOccurrence,
  }) {
    _currentParams = WebViewNavigationParams(
      topicId: topicId,
      topicName: topicName,
      scrollToGroupIndex: scrollToGroupIndex,
      scrollToMessageId: scrollToMessageId,
      scrollToHighlightId: scrollToHighlightId,
      scrollToTextStart: scrollToTextStart,
      scrollToTextEnd: scrollToTextEnd,
      scrollToQuotedText: scrollToQuotedText,
      scrollToQuotedTextOccurrence: scrollToQuotedTextOccurrence,
    );
    _isVisible = true;
    _isExiting = false;
    notifyListeners();
    
    debugPrint('[WebViewNav] Switch to: $topicId');
  }

  /// 清理状态（释放 WebView）
  void clear() {
    _currentParams = null;
    _isVisible = false;
    _isExiting = false;
    notifyListeners();
    
    debugPrint('[WebViewNav] Clear');
  }
}
