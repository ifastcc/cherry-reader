/// MCP 工具基类
///
/// 所有 MCP 工具都需要继承此类并实现:
/// - name: 工具名称（用于 tools/call）
/// - description: 工具描述（显示给 AI）
/// - inputSchema: 参数 JSON Schema
/// - execute: 执行逻辑
abstract class MCPTool {
  /// 工具名称
  String get name;

  /// 工具描述
  String get description;

  /// 输入参数的 JSON Schema
  Map<String, dynamic> get inputSchema;

  /// 获取工具定义（用于 tools/list）
  Map<String, dynamic> get definition => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
      };

  /// 执行工具
  ///
  /// [arguments] 调用参数
  /// 返回执行结果
  Future<dynamic> execute(Map<String, dynamic> arguments);
}
