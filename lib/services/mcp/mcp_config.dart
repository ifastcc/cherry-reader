import 'package:shared_preferences/shared_preferences.dart';

/// MCP Server 配置
///
/// 管理 MCP Server 的启用状态、端口等配置
/// 使用 SharedPreferences 持久化存储
class MCPServerConfig {
  static const String _keyEnabled = 'mcp_server_enabled';
  static const String _keyAutoStart = 'mcp_server_auto_start';
  static const String _keyPort = 'mcp_server_port';
  static const String _keyEnableVectorSearch = 'mcp_server_vector_search';
  static const String _keyEmbeddingApiKey = 'mcp_server_embedding_api_key';
  static const String _keyEmbeddingModel = 'mcp_server_embedding_model';

  /// 默认端口
  static const int defaultPort = 9527;

  /// 是否启用 MCP Server
  final bool enabled;

  /// 应用启动时是否自动启动
  final bool autoStart;

  /// 服务端口
  final int port;

  /// 是否启用向量搜索（预留）
  final bool enableVectorSearch;

  /// Embedding API Key（预留）
  final String? embeddingApiKey;

  /// Embedding 模型（预留）
  final String embeddingModel;

  MCPServerConfig({
    required this.enabled,
    required this.autoStart,
    required this.port,
    this.enableVectorSearch = false,
    this.embeddingApiKey,
    this.embeddingModel = 'text-embedding-3-small',
  });

  /// 默认配置
  factory MCPServerConfig.defaults() => MCPServerConfig(
        enabled: false,
        autoStart: false,
        port: defaultPort,
        enableVectorSearch: false,
        embeddingModel: 'text-embedding-3-small',
      );

  /// 从 SharedPreferences 加载配置
  static Future<MCPServerConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MCPServerConfig(
      enabled: prefs.getBool(_keyEnabled) ?? false,
      autoStart: prefs.getBool(_keyAutoStart) ?? false,
      port: prefs.getInt(_keyPort) ?? defaultPort,
      enableVectorSearch: prefs.getBool(_keyEnableVectorSearch) ?? false,
      embeddingApiKey: prefs.getString(_keyEmbeddingApiKey),
      embeddingModel:
          prefs.getString(_keyEmbeddingModel) ?? 'text-embedding-3-small',
    );
  }

  /// 保存配置到 SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setBool(_keyAutoStart, autoStart);
    await prefs.setInt(_keyPort, port);
    await prefs.setBool(_keyEnableVectorSearch, enableVectorSearch);
    if (embeddingApiKey != null) {
      await prefs.setString(_keyEmbeddingApiKey, embeddingApiKey!);
    } else {
      await prefs.remove(_keyEmbeddingApiKey);
    }
    await prefs.setString(_keyEmbeddingModel, embeddingModel);
  }

  /// 创建副本
  MCPServerConfig copyWith({
    bool? enabled,
    bool? autoStart,
    int? port,
    bool? enableVectorSearch,
    String? embeddingApiKey,
    String? embeddingModel,
  }) {
    return MCPServerConfig(
      enabled: enabled ?? this.enabled,
      autoStart: autoStart ?? this.autoStart,
      port: port ?? this.port,
      enableVectorSearch: enableVectorSearch ?? this.enableVectorSearch,
      embeddingApiKey: embeddingApiKey ?? this.embeddingApiKey,
      embeddingModel: embeddingModel ?? this.embeddingModel,
    );
  }

  @override
  String toString() =>
      'MCPServerConfig(enabled: $enabled, autoStart: $autoStart, port: $port)';
}

/// MCP Server 状态
class MCPServerStatus {
  final bool isRunning;
  final int? port;
  final List<String> addresses;
  final String? error;

  MCPServerStatus._({
    required this.isRunning,
    this.port,
    this.addresses = const [],
    this.error,
  });

  /// 运行中状态
  factory MCPServerStatus.running({
    required int port,
    required List<String> addresses,
  }) =>
      MCPServerStatus._(
        isRunning: true,
        port: port,
        addresses: addresses,
      );

  /// 已停止状态
  factory MCPServerStatus.stopped() => MCPServerStatus._(isRunning: false);

  /// 错误状态
  factory MCPServerStatus.error(String message) => MCPServerStatus._(
        isRunning: false,
        error: message,
      );

  /// 获取主要地址（优先返回非 localhost 的地址）
  String? get primaryAddress {
    if (addresses.isEmpty) return null;
    // 优先返回局域网地址
    for (final addr in addresses) {
      if (addr != '127.0.0.1' && addr != 'localhost') {
        return addr;
      }
    }
    return addresses.first;
  }

  /// 获取完整的 MCP 端点 URL
  String? get mcpEndpoint {
    if (!isRunning || port == null) return null;
    final addr = primaryAddress ?? '127.0.0.1';
    return 'http://$addr:$port/mcp';
  }
}

/// AI 编程工具类型
enum AIToolType {
  claudeCode('Claude Code', 'claude_code'),
  cursor('Cursor', 'cursor'),
  vscode('VS Code Copilot', 'vscode'),
  geminiCli('Gemini CLI', 'gemini_cli'),
  codex('OpenAI Codex CLI', 'codex'),
  windsurf('Windsurf', 'windsurf'),
  jetbrains('JetBrains IDEs', 'jetbrains'),
  cline('Cline', 'cline'),
  rooCode('Roo Code', 'roo_code'),
  claudeDesktop('Claude Desktop', 'claude_desktop'),
  cherryStudio('Cherry Studio', 'cherry_studio');

  final String displayName;
  final String id;

  const AIToolType(this.displayName, this.id);
}

/// 配置生成器
class MCPConfigGenerator {
  /// 生成指定工具的配置字符串
  static String generateConfig(AIToolType tool, String url) {
    switch (tool) {
      case AIToolType.claudeCode:
        return '''# 命令行添加
claude mcp add --transport http cherry-reader $url

# 或编辑 ~/.claude.json
{
  "mcpServers": {
    "cherry-reader": {
      "type": "http",
      "url": "$url"
    }
  }
}''';

      case AIToolType.cursor:
        return '''# 文件位置: ~/.cursor/mcp.json 或 项目目录/.cursor/mcp.json
{
  "mcpServers": {
    "cherry-reader": {
      "type": "http",
      "url": "$url"
    }
  }
}''';

      case AIToolType.vscode:
        return '''# 文件位置: .vscode/mcp.json
# 启用: 设置 > Chat > Mcp > Enabled
{
  "servers": {
    "cherry-reader": {
      "type": "http",
      "url": "$url"
    }
  }
}''';

      case AIToolType.geminiCli:
        return '''# 文件位置: ~/.gemini/settings.json
{
  "mcpServers": {
    "cherry-reader": {
      "httpUrl": "$url"
    }
  }
}''';

      case AIToolType.codex:
        return '''# 文件位置: ~/.codex/config.toml
[mcp_servers.cherry-reader]
url = "$url"''';

      case AIToolType.windsurf:
        return '''# 文件位置: ~/.codeium/windsurf/mcp_config.json
{
  "mcpServers": {
    "cherry-reader": {
      "serverUrl": "$url"
    }
  }
}''';

      case AIToolType.jetbrains:
        return '''# 设置路径: Settings > Tools > AI Assistant > MCP Servers
{
  "servers": {
    "cherry-reader": {
      "type": "http",
      "url": "$url"
    }
  }
}''';

      case AIToolType.cline:
        return '''# 文件位置: ~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
{
  "mcpServers": {
    "cherry-reader": {
      "url": "$url",
      "disabled": false
    }
  }
}''';

      case AIToolType.rooCode:
        return '''# 文件位置: 项目目录/.roo/mcp.json
{
  "mcpServers": {
    "cherry-reader": {
      "type": "streamableHttp",
      "url": "$url"
    }
  }
}''';

      case AIToolType.claudeDesktop:
        return '''# 文件位置:
#   macOS: ~/Library/Application Support/Claude/claude_desktop_config.json
#   Windows: %APPDATA%\\Claude\\claude_desktop_config.json
{
  "mcpServers": {
    "cherry-reader": {
      "url": "$url"
    }
  }
}''';

      case AIToolType.cherryStudio:
        return '''{
  "mcpServers": {
    "cherry-reader": {
      "type": "streamableHttp",
      "url": "$url",
      "name": "Cherry Reader",
      "description": "访问 Cherry Reader 的聊天记录数据"
    }
  }
}''';
    }
  }
}
