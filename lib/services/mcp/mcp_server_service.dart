import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../utils/platform_utils.dart';
import 'mcp_config.dart';
import 'mcp_protocol_handler.dart';

/// MCP Server 服务
///
/// 职责：
/// 1. 管理 HTTP 服务器生命周期
/// 2. 提供启动/停止接口
/// 3. 通过 Stream 通知状态变化
/// 4. 仅桌面端可用
class MCPServerService {
  static final MCPServerService _instance = MCPServerService._internal();
  factory MCPServerService() => _instance;
  static MCPServerService get instance => _instance;

  MCPServerService._internal();

  // HTTP 服务器实例
  HttpServer? _server;

  // 运行状态
  bool _isRunning = false;
  int _port = MCPServerConfig.defaultPort;
  List<String> _addresses = [];

  // 状态流
  final _statusController = StreamController<MCPServerStatus>.broadcast();
  Stream<MCPServerStatus> get statusStream => _statusController.stream;

  // 当前状态
  MCPServerStatus get currentStatus => _isRunning
      ? MCPServerStatus.running(port: _port, addresses: _addresses)
      : MCPServerStatus.stopped();

  // 配置
  MCPServerConfig _config = MCPServerConfig.defaults();
  MCPServerConfig get config => _config;

  // 协议处理器
  late final MCPProtocolHandler _protocolHandler;

  // 是否已初始化
  bool _initialized = false;

  /// 初始化服务
  ///
  /// 在 main.dart 中调用，仅桌面端有效
  Future<void> init() async {
    if (_initialized) return;

    if (!PlatformUtils.isDesktop) {
      debugPrint('⚠️ MCP Server 仅支持桌面端');
      return;
    }

    // 加载配置
    _config = await MCPServerConfig.load();

    // 初始化协议处理器
    _protocolHandler = MCPProtocolHandler();

    _initialized = true;
    debugPrint('✅ MCPServerService 初始化完成');

    // 如果配置了自动启动，则启动服务
    if (_config.autoStart && _config.enabled) {
      await start();
    }
  }

  /// 启动 MCP Server
  ///
  /// [port] 可选端口，不指定则使用配置中的端口
  Future<bool> start({int? port}) async {
    if (!_initialized) {
      debugPrint('❌ MCPServerService 未初始化');
      return false;
    }

    if (_isRunning) {
      debugPrint('⚠️ MCP Server 已在运行中');
      return true;
    }

    _port = port ?? _config.port;

    try {
      // 创建路由
      final router = _createRouter();

      // 创建中间件管道
      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);

      // 启动服务器
      // 绑定到 0.0.0.0 允许局域网访问
      _server = await shelf_io.serve(handler, '0.0.0.0', _port);

      _isRunning = true;
      _addresses = await _getLocalAddresses();

      // 通知状态变化
      _statusController.add(MCPServerStatus.running(
        port: _port,
        addresses: _addresses,
      ));

      debugPrint('✅ MCP Server 已启动: http://localhost:$_port/mcp');
      debugPrint('   可用地址: ${_addresses.join(", ")}');

      return true;
    } catch (e) {
      debugPrint('❌ MCP Server 启动失败: $e');
      _statusController.add(MCPServerStatus.error(e.toString()));
      return false;
    }
  }

  /// 停止 MCP Server
  Future<void> stop() async {
    if (!_isRunning || _server == null) {
      debugPrint('⚠️ MCP Server 未在运行');
      return;
    }

    await _server!.close(force: true);
    _server = null;
    _isRunning = false;
    _addresses = [];

    // 通知状态变化
    _statusController.add(MCPServerStatus.stopped());

    debugPrint('🔒 MCP Server 已停止');
  }

  /// 重启服务（更改端口后使用）
  Future<bool> restart({int? port}) async {
    await stop();
    return start(port: port);
  }

  /// 更新配置并保存
  Future<void> updateConfig(MCPServerConfig newConfig) async {
    _config = newConfig;
    await _config.save();
  }

  /// 创建路由
  Router _createRouter() {
    final router = Router();

    // MCP 主端点 - POST 用于发送 JSON-RPC 请求
    router.post('/mcp', _protocolHandler.handleRequest);

    // MCP 端点 - GET 用于建立 SSE 流（可选）
    router.get('/mcp', _protocolHandler.handleSSE);

    // 健康检查端点
    router.get('/health', _handleHealth);

    // 根路径信息
    router.get('/', _handleRoot);

    return router;
  }

  /// 处理健康检查请求
  Future<Response> _handleHealth(Request request) async {
    return Response.ok(
      '{"status":"ok","version":"1.0.0","protocol":"2025-03-26"}',
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 处理根路径请求
  Future<Response> _handleRoot(Request request) async {
    return Response.ok(
      '''{"name":"cherry-reader-mcp","description":"Cherry Reader MCP Server - Access your chat history via MCP protocol","endpoints":{"mcp":"/mcp","health":"/health"}}''',
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// CORS 中间件
  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        // 处理 OPTIONS 预检请求
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }

        // 处理正常请求，添加 CORS 头
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  /// CORS 头
  Map<String, String> get _corsHeaders => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization, MCP-Session-Id, MCP-Protocol-Version',
        'Access-Control-Expose-Headers': 'MCP-Session-Id',
      };

  /// 获取本机 IP 地址列表
  Future<List<String>> _getLocalAddresses() async {
    final addresses = <String>['127.0.0.1'];

    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            addresses.add(addr.address);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 获取本机 IP 失败: $e');
    }

    return addresses;
  }

  /// 生成指定工具的配置字符串
  String generateConfig(AIToolType tool) {
    final url = currentStatus.mcpEndpoint ?? 'http://localhost:$_port/mcp';
    return MCPConfigGenerator.generateConfig(tool, url);
  }

  /// 释放资源
  void dispose() {
    stop();
    _statusController.close();
  }
}
