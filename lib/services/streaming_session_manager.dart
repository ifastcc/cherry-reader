import 'dart:async';

/// 流式响应会话状态
enum StreamingSessionStatus {
  streaming,  // 正在流式输出
  completed,  // 完成
  error,      // 错误
}

/// 流式响应会话
///
/// 管理单个对话的流式响应，支持后台继续运行
class StreamingSession {
  final String conversationId;
  final String messageId;  // 正在生成的消息 ID
  final DateTime startTime;

  StreamingSessionStatus _status = StreamingSessionStatus.streaming;
  String _content = '';
  String? _error;

  // 用于通知观察者的控制器（broadcast 允许多个监听者）
  final _contentController = StreamController<String>.broadcast();
  final _statusController = StreamController<StreamingSessionStatus>.broadcast();

  StreamingSession({
    required this.conversationId,
    required this.messageId,
  }) : startTime = DateTime.now();

  // ========== 属性 ==========

  StreamingSessionStatus get status => _status;
  String get content => _content;
  String? get error => _error;
  bool get isActive => _status == StreamingSessionStatus.streaming;

  /// 内容流（观察者可以监听）
  Stream<String> get contentStream => _contentController.stream;

  /// 状态流
  Stream<StreamingSessionStatus> get statusStream => _statusController.stream;

  // ========== 内部方法（由 Manager 调用）==========

  /// 追加内容
  void appendContent(String chunk) {
    _content += chunk;
    if (!_contentController.isClosed) {
      _contentController.add(_content);
    }
  }

  /// 标记完成
  void complete() {
    _status = StreamingSessionStatus.completed;
    if (!_statusController.isClosed) {
      _statusController.add(_status);
    }
    _close();
  }

  /// 标记错误
  void setError(String error) {
    _error = error;
    _status = StreamingSessionStatus.error;
    if (!_statusController.isClosed) {
      _statusController.add(_status);
    }
    _close();
  }

  void _close() {
    _contentController.close();
    _statusController.close();
  }
}

/// 流式响应会话管理器（单例）
///
/// 管理所有正在进行的流式响应，支持：
/// 1. 后台继续运行（widget dispose 不影响）
/// 2. 重新连接（widget 重新创建时可以获取最新状态）
/// 3. 多模型响应管理
class StreamingSessionManager {
  static StreamingSessionManager? _instance;
  static StreamingSessionManager get instance {
    _instance ??= StreamingSessionManager._();
    return _instance!;
  }

  StreamingSessionManager._();

  // 按 conversationId 索引的 session
  final Map<String, StreamingSession> _sessions = {};

  // 多模型响应的 session（key: conversationId, value: Map<modelKey, session>）
  final Map<String, Map<String, StreamingSession>> _multiModelSessions = {};

  // ========== 单模型会话管理 ==========

  /// 创建新的流式会话
  StreamingSession createSession({
    required String conversationId,
    required String messageId,
  }) {
    // 如果已有活跃会话，先清理
    _sessions.remove(conversationId);

    final session = StreamingSession(
      conversationId: conversationId,
      messageId: messageId,
    );
    _sessions[conversationId] = session;
    return session;
  }

  /// 获取会话（如果存在）
  StreamingSession? getSession(String conversationId) {
    return _sessions[conversationId];
  }

  /// 检查是否有活跃会话
  bool hasActiveSession(String conversationId) {
    final session = _sessions[conversationId];
    return session != null && session.isActive;
  }

  /// 移除会话
  void removeSession(String conversationId) {
    _sessions.remove(conversationId);
  }

  /// 清理已完成的会话（可选：保留最近 N 分钟的）
  void cleanupCompletedSessions({Duration? maxAge}) {
    final now = DateTime.now();
    _sessions.removeWhere((id, session) {
      if (session.isActive) return false;
      if (maxAge == null) return true;
      return now.difference(session.startTime) > maxAge;
    });
  }

  // ========== 多模型会话管理 ==========

  /// 创建多模型响应会话组
  Map<String, StreamingSession> createMultiModelSessions({
    required String conversationId,
    required Map<String, String> modelMessageIds,  // modelKey -> messageId
  }) {
    // 清理旧的
    _multiModelSessions.remove(conversationId);

    final sessions = <String, StreamingSession>{};
    for (final entry in modelMessageIds.entries) {
      final session = StreamingSession(
        conversationId: conversationId,
        messageId: entry.value,
      );
      sessions[entry.key] = session;
    }

    _multiModelSessions[conversationId] = sessions;
    return sessions;
  }

  /// 获取多模型会话组
  Map<String, StreamingSession>? getMultiModelSessions(String conversationId) {
    return _multiModelSessions[conversationId];
  }

  /// 检查是否有活跃的多模型会话
  bool hasActiveMultiModelSession(String conversationId) {
    final sessions = _multiModelSessions[conversationId];
    if (sessions == null) return false;
    return sessions.values.any((s) => s.isActive);
  }

  /// 移除多模型会话组
  void removeMultiModelSessions(String conversationId) {
    _multiModelSessions.remove(conversationId);
  }

  // ========== 统计和调试 ==========

  /// 获取活跃会话数量
  int get activeSessionCount {
    int count = _sessions.values.where((s) => s.isActive).length;
    for (final group in _multiModelSessions.values) {
      count += group.values.where((s) => s.isActive).length;
    }
    return count;
  }

  /// 获取所有会话的状态（调试用）
  Map<String, dynamic> getDebugInfo() {
    return {
      'singleSessions': _sessions.map((k, v) => MapEntry(k, {
        'messageId': v.messageId,
        'status': v.status.name,
        'contentLength': v.content.length,
      })),
      'multiModelSessions': _multiModelSessions.map((k, v) => MapEntry(k,
        v.map((mk, s) => MapEntry(mk, {
          'messageId': s.messageId,
          'status': s.status.name,
          'contentLength': s.content.length,
        }))
      )),
      'activeCount': activeSessionCount,
    };
  }
}
