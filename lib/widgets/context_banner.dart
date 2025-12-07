import 'package:flutter/material.dart';
import '../models/structured_context.dart';
import '../models/isar/unified_conversation_entity.dart';

/// 极简 Context Banner 组件
///
/// 设计理念：极简
/// - 一行显示：图标 + "Context" + 摘要 + 编辑按钮
/// - 不需要展开/折叠，需要看详情就点编辑
/// - 清晰告诉用户"有上下文"即可
class ContextBanner extends StatelessWidget {
  /// 结构化上下文数据
  final StructuredContext? context;

  /// 原始 context 快照
  final String? contextSnapshot;

  /// 上下文类型
  final ConversationContextType contextType;

  /// 点击编辑回调（如果为 null，则不显示编辑按钮）
  final VoidCallback? onEdit;

  /// 清除上下文回调
  final VoidCallback? onClear;

  const ContextBanner({
    Key? key,
    this.context,
    this.contextSnapshot,
    this.contextType = ConversationContextType.topic,
    this.onEdit,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext buildContext) {
    // 如果没有 context，不显示
    if (context == null && contextSnapshot == null) {
      return const SizedBox.shrink();
    }

    final summary = context?.summaryDescription ?? _getDefaultSummary();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.orange.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // 图标
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(width: 10),

          // 标题 + 摘要
          Expanded(
            child: Row(
              children: [
                Text(
                  'Context',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 编辑按钮（如果有回调）
          if (onEdit != null)
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '编辑',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDefaultSummary() {
    if (contextSnapshot == null) return '无内容';
    final length = contextSnapshot!.length;
    if (length >= 10000) {
      return '${(length / 10000).toStringAsFixed(1)}万字';
    } else if (length >= 1000) {
      return '${(length / 1000).toStringAsFixed(1)}千字';
    }
    return '$length 字';
  }
}
