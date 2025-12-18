import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'mcp_tool_base.dart';
import 'get_conversation_tool.dart';
import 'get_user_queries_tool.dart';
import 'find_related_discussions_tool.dart';

/// 工具注册表
///
/// 管理所有 MCP 工具的注册和调用
///
/// 工具列表（3 个）：
/// - recall_my_conversations: 时间维度回顾（这周/这月聊了什么）
/// - search_past_discussions: 搜索历史讨论
/// - read_conversation_detail: 读取对话详情
class ToolRegistry {
  late final Map<String, MCPTool> _tools;

  ToolRegistry() {
    _tools = {
      'recall_my_conversations': GetUserQueriesTool(),
      'search_past_discussions': FindRelatedDiscussionsTool(),
      'read_conversation_detail': GetConversationTool(),
    };
  }

  /// 列出所有工具
  Map<String, dynamic> listTools() {
    return {
      'tools': _tools.values.map((t) => t.definition).toList(),
    };
  }

  /// 调用工具
  Future<Map<String, dynamic>> callTool(
    String? name,
    Map<String, dynamic> arguments,
  ) async {
    if (name == null) {
      return _errorResult('Tool name is required');
    }

    final tool = _tools[name];
    if (tool == null) {
      return _errorResult('Unknown tool: $name');
    }

    try {
      debugPrint('🔧 调用工具: $name');
      debugPrint('   参数: $arguments');

      final result = await tool.execute(arguments);

      debugPrint('✅ 工具执行成功: $name');

      return {
        'content': [
          {
            'type': 'text',
            'text': result is String ? result : jsonEncode(result),
          },
        ],
      };
    } catch (e, stack) {
      debugPrint('❌ 工具执行失败: $name - $e');
      debugPrint('$stack');
      return _errorResult('Error executing $name: $e');
    }
  }

  /// 构建错误结果
  Map<String, dynamic> _errorResult(String message) {
    return {
      'content': [
        {
          'type': 'text',
          'text': message,
        },
      ],
      'isError': true,
    };
  }

  /// 获取工具数量
  int get toolCount => _tools.length;

  /// 获取所有工具名称
  List<String> get toolNames => _tools.keys.toList();
}
