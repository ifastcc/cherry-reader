import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import 'tools/tool_registry.dart';

/// MCP 协议处理器
///
/// 实现 MCP 规范 2025-03-26 的 Streamable HTTP 传输
/// - POST /mcp: 处理 JSON-RPC 请求
/// - GET /mcp: 建立 SSE 流（可选）
class MCPProtocolHandler {
  /// 协议版本
  static const String protocolVersion = '2025-03-26';

  /// 服务器信息
  static const String serverName = 'cherry-reader-mcp';
  static const String serverVersion = '1.0.0';

  /// 工具注册表
  late final ToolRegistry _toolRegistry;

  /// Session 管理
  final Map<String, _Session> _sessions = {};
  final _uuid = const Uuid();

  MCPProtocolHandler() {
    _toolRegistry = ToolRegistry();
  }

  /// 处理 POST 请求（JSON-RPC）
  Future<Response> handleRequest(Request request) async {
    try {
      // 读取请求体
      final body = await request.readAsString();
      if (body.isEmpty) {
        return _jsonRpcError(null, -32700, 'Parse error: Empty body');
      }

      // 解析 JSON
      final dynamic json;
      try {
        json = jsonDecode(body);
      } catch (e) {
        return _jsonRpcError(null, -32700, 'Parse error: Invalid JSON');
      }

      // 验证 JSON-RPC 格式
      if (json is! Map<String, dynamic>) {
        return _jsonRpcError(null, -32600, 'Invalid Request: Not an object');
      }

      if (json['jsonrpc'] != '2.0') {
        return _jsonRpcError(
            json['id'], -32600, 'Invalid Request: jsonrpc must be "2.0"');
      }

      final method = json['method'] as String?;
      final params = json['params'] as Map<String, dynamic>?;
      final id = json['id'];

      // 获取或创建 Session
      final sessionId = request.headers['mcp-session-id'] ?? _uuid.v4();

      // 处理方法
      final result = await _handleMethod(method, params, sessionId);

      // 构建响应
      final responseBody = jsonEncode({
        'jsonrpc': '2.0',
        'result': result,
        'id': id,
      });

      return Response.ok(
        responseBody,
        headers: {
          'Content-Type': 'application/json',
          'Mcp-Session-Id': sessionId,
        },
      );
    } catch (e, stack) {
      debugPrint('❌ MCP 请求处理错误: $e\n$stack');
      return _jsonRpcError(null, -32603, 'Internal error: $e');
    }
  }

  /// 处理 GET 请求（SSE 流）
  Future<Response> handleSSE(Request request) async {
    // 检查 Accept 头
    final accept = request.headers['accept'] ?? '';
    if (!accept.contains('text/event-stream')) {
      return Response(
        405,
        body: 'Method Not Allowed: Use POST for JSON-RPC requests',
      );
    }

    final sessionId = request.headers['mcp-session-id'];
    if (sessionId == null) {
      return Response(
        400,
        body: 'Bad Request: Mcp-Session-Id header required for SSE',
      );
    }

    // 创建 SSE 流
    final controller = StreamController<List<int>>();

    // 发送初始连接消息
    _sendSSEEvent(controller, 'connected', {'sessionId': sessionId});

    // 保存 session
    _sessions[sessionId] = _Session(
      id: sessionId,
      sseController: controller,
      createdAt: DateTime.now(),
    );

    // 返回 SSE 响应
    return Response.ok(
      controller.stream,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Mcp-Session-Id': sessionId,
      },
    );
  }

  /// 发送 SSE 事件
  void _sendSSEEvent(
    StreamController<List<int>> controller,
    String event,
    Map<String, dynamic> data,
  ) {
    final eventData = 'event: $event\ndata: ${jsonEncode(data)}\n\n';
    controller.add(utf8.encode(eventData));
  }

  /// 处理 MCP 方法
  Future<dynamic> _handleMethod(
    String? method,
    Map<String, dynamic>? params,
    String sessionId,
  ) async {
    if (method == null) {
      throw Exception('Method is required');
    }

    switch (method) {
      // 初始化
      case 'initialize':
        return _handleInitialize(params);

      // 列出可用工具
      case 'tools/list':
        return _toolRegistry.listTools();

      // 调用工具
      case 'tools/call':
        final toolName = params?['name'] as String?;
        final arguments = params?['arguments'] as Map<String, dynamic>?;
        return _toolRegistry.callTool(toolName, arguments ?? {});

      // 列出资源（暂不实现）
      case 'resources/list':
        return {'resources': []};

      // 读取资源（暂不实现）
      case 'resources/read':
        return {'contents': []};

      // 列出提示词模板（暂不实现）
      case 'prompts/list':
        return {'prompts': []};

      // 获取提示词（暂不实现）
      case 'prompts/get':
        throw Exception('Prompt not found');

      // ping
      case 'ping':
        return {};

      // 通知类方法（无返回值）
      case 'notifications/initialized':
      case 'notifications/cancelled':
        return {};

      default:
        throw Exception('Method not found: $method');
    }
  }

  /// 处理初始化请求
  Map<String, dynamic> _handleInitialize(Map<String, dynamic>? params) {
    final clientInfo = params?['clientInfo'] as Map<String, dynamic>?;
    debugPrint('📱 MCP 客户端连接: ${clientInfo?['name'] ?? 'Unknown'}');

    return {
      'protocolVersion': protocolVersion,
      'capabilities': {
        'tools': {
          'listChanged': false,
        },
        'resources': {
          'subscribe': false,
          'listChanged': false,
        },
        'prompts': {
          'listChanged': false,
        },
      },
      'serverInfo': {
        'name': serverName,
        'version': serverVersion,
      },
    };
  }

  /// 构建 JSON-RPC 错误响应
  Response _jsonRpcError(dynamic id, int code, String message) {
    return Response.ok(
      jsonEncode({
        'jsonrpc': '2.0',
        'error': {
          'code': code,
          'message': message,
        },
        'id': id,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 清理过期 Session
  void cleanupSessions() {
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final entry in _sessions.entries) {
      if (now.difference(entry.value.createdAt).inHours > 1) {
        entry.value.sseController?.close();
        expiredIds.add(entry.key);
      }
    }

    for (final id in expiredIds) {
      _sessions.remove(id);
    }
  }
}

/// Session 信息
class _Session {
  final String id;
  final StreamController<List<int>>? sseController;
  final DateTime createdAt;

  _Session({
    required this.id,
    this.sseController,
    required this.createdAt,
  });
}
