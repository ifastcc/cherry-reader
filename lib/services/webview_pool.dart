import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView 预热池
/// 
/// 用于预加载 WebView 实例，提升首次加载速度
class WebViewPool {
  static WebViewPool? _instance;
  static WebViewPool get instance => _instance ??= WebViewPool._();
  
  WebViewPool._();
  
  HeadlessInAppWebView? _prewarmedWebView;
  bool _isWarming = false;
  bool _isReady = false;
  
  /// 是否已预热完成
  bool get isReady => _isReady;
  
  /// 预热 WebView
  /// 
  /// 在应用启动后调用，提前加载 HTML/CSS/JS
  Future<void> warmUp() async {
    if (_isWarming || _isReady) return;
    _isWarming = true;
    
    try {
      debugPrint('[WebViewPool] Starting warm-up...');
      
      _prewarmedWebView = HeadlessInAppWebView(
        initialFile: 'assets/webview/conversation.html',
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          transparentBackground: true,
          supportZoom: false,
          cacheEnabled: true,
          clearCache: false,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
        ),
        onWebViewCreated: (controller) {
          debugPrint('[WebViewPool] HeadlessWebView created');
        },
        onLoadStop: (controller, url) async {
          // 调用框架初始化
          await controller.evaluateJavascript(source: 'window.initFramework && window.initFramework()');
          _isReady = true;
          debugPrint('[WebViewPool] Warm-up complete');
        },
        onReceivedError: (controller, request, error) {
          debugPrint('[WebViewPool] Load error: ${error.type} - ${error.description}');
        },
      );
      
      await _prewarmedWebView!.run();
    } catch (e) {
      debugPrint('[WebViewPool] Warm-up failed: $e');
    } finally {
      _isWarming = false;
    }
  }
  
  /// 获取预热的 WebView 控制器
  /// 
  /// 返回后会清空预热实例，调用方需要自行管理
  InAppWebViewController? takeController() {
    if (!_isReady || _prewarmedWebView == null) return null;
    
    final controller = _prewarmedWebView!.webViewController;
    _prewarmedWebView = null;
    _isReady = false;
    
    // 后台重新预热一个新的
    Future.delayed(const Duration(seconds: 2), () {
      warmUp();
    });
    
    return controller;
  }
  
  /// 释放资源
  Future<void> dispose() async {
    await _prewarmedWebView?.dispose();
    _prewarmedWebView = null;
    _isReady = false;
    _isWarming = false;
  }
}
