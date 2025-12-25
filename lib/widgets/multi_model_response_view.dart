import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/multi_model_service.dart';
import 'unified_markdown_renderer.dart';

/// 多模型回复展示组件 - 横向并排布局
///
/// 参考 Cherry Studio 设计：
/// 1. 横向并排展示多个模型回复
/// 2. 每个回复卡片底部有独立的操作按钮
/// 3. 流式实时更新
class MultiModelResponseView extends StatelessWidget {
  /// 模型回复 Map
  final Map<String, ModelResponse> responses;

  /// 重试回调
  final Function(String modelKey)? onRetry;

  /// 编辑回调
  final Function(String modelKey, String content)? onEdit;

  /// 删除回调
  final Function(String modelKey)? onDelete;

  /// 翻译回调
  final Function(String modelKey)? onTranslate;

  /// 朗读回调
  final Function(String modelKey)? onSpeak;

  /// 选择模型回调（用于采纳某个回复）
  final Function(String modelKey)? onModelSelect;

  const MultiModelResponseView({
    super.key,
    required this.responses,
    this.onRetry,
    this.onEdit,
    this.onDelete,
    this.onTranslate,
    this.onSpeak,
    this.onModelSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return const Center(child: Text('没有回复'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 横向滚动展示所有模型回复
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: responses.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ModelResponseCard(
                modelKey: entry.key,
                response: entry.value,
                isDark: isDark,
                onRetry: onRetry != null ? () => onRetry!(entry.key) : null,
                onEdit: onEdit != null
                    ? (content) => onEdit!(entry.key, content)
                    : null,
                onDelete: onDelete != null ? () => onDelete!(entry.key) : null,
                onTranslate:
                    onTranslate != null ? () => onTranslate!(entry.key) : null,
                onSpeak: onSpeak != null ? () => onSpeak!(entry.key) : null,
                onSelect:
                    onModelSelect != null ? () => onModelSelect!(entry.key) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 单个模型回复卡片
class _ModelResponseCard extends StatefulWidget {
  final String modelKey;
  final ModelResponse response;
  final bool isDark;
  final VoidCallback? onRetry;
  final Function(String content)? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTranslate;
  final VoidCallback? onSpeak;
  final VoidCallback? onSelect;

  const _ModelResponseCard({
    required this.modelKey,
    required this.response,
    required this.isDark,
    this.onRetry,
    this.onEdit,
    this.onDelete,
    this.onTranslate,
    this.onSpeak,
    this.onSelect,
  });

  @override
  State<_ModelResponseCard> createState() => _ModelResponseCardState();
}

class _ModelResponseCardState extends State<_ModelResponseCard> {
  String _content = '';
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _content = widget.response.fullContent;
    _subscribeToStream();
  }

  @override
  void didUpdateWidget(_ModelResponseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 response 对象变了，需要重新订阅
    if (oldWidget.response != widget.response) {
      _subscription?.cancel();
      _content = widget.response.fullContent;
      _subscribeToStream();
    }
  }

  void _subscribeToStream() {
    // 如果已经完成，不需要订阅
    if (widget.response.isComplete) return;

    // 监听流式更新
    _subscription = widget.response.contentStream.listen(
      (content) {
        if (mounted) {
          setState(() {
            _content = content;
          });
        }
      },
      onError: (error) {
        // 错误已在 response 中处理
      },
      onDone: () {
        // 流完成时取消订阅引用，避免内存泄漏
        _subscription = null;
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelColor = _getModelColor(widget.response.modelName);
    final cardWidth = MediaQuery.of(context).size.width * 0.75;
    final minWidth = 320.0;
    final maxWidth = 500.0;
    final width = cardWidth.clamp(minWidth, maxWidth);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部：模型名称和状态
          _buildHeader(modelColor),

          // 内容区域
          Expanded(
            child: _buildContent(),
          ),

          // 底部操作栏
          _buildActionBar(modelColor),
        ],
      ),
    );
  }

  /// 顶部头部：模型名称 + 状态
  Widget _buildHeader(Color modelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: modelColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(
          bottom: BorderSide(
            color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // 模型图标
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: modelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getModelIcon(widget.response.modelName),
              size: 16,
              color: modelColor,
            ),
          ),
          const SizedBox(width: 8),
          // 模型名称
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.response.modelName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.response.providerName.isNotEmpty)
                  Text(
                    widget.response.providerName,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          // 状态指示
          _buildStatusIndicator(modelColor),
        ],
      ),
    );
  }

  /// 状态指示器
  Widget _buildStatusIndicator(Color modelColor) {
    if (widget.response.error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 12, color: Colors.red[400]),
            const SizedBox(width: 2),
            Text(
              '失败',
              style: TextStyle(fontSize: 10, color: Colors.red[400]),
            ),
          ],
        ),
      );
    }

    if (!widget.response.isComplete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(modelColor),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Thinking...',
            style: TextStyle(
              fontSize: 10,
              color: modelColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Icon(Icons.check_circle, size: 16, color: Colors.green[400]);
  }

  /// 内容区域
  Widget _buildContent() {
    if (widget.response.error != null) {
      return _buildErrorContent();
    }

    if (_content.isEmpty && !widget.response.isComplete) {
      return _buildLoadingContent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: UnifiedMarkdownRenderer(
        data: _content,
        scrollable: false,
        selectable: true,
        textStyle: TextStyle(
          fontSize: 14,
          height: 1.7,
          color: widget.isDark ? Colors.grey[200] : const Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getModelColor(widget.response.modelName),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '正在思考...',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
            const SizedBox(height: 8),
            Text(
              '调用失败',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.response.error ?? '未知错误',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 底部操作栏 - Cherry Studio 风格
  Widget _buildActionBar(Color modelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
        border: Border(
          top: BorderSide(
            color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // 复制
          _ActionIconButton(
            icon: Icons.copy_outlined,
            tooltip: '复制',
            onTap: () {
              Clipboard.setData(ClipboardData(text: _content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已复制到剪贴板'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          // 重试
          if (widget.onRetry != null)
            _ActionIconButton(
              icon: Icons.refresh_outlined,
              tooltip: '重试',
              onTap: widget.onRetry!,
            ),
          // @提及
          _ActionIconButton(
            icon: Icons.alternate_email,
            tooltip: '@提及',
            onTap: () {
              // TODO: 实现 @提及功能
            },
          ),
          // 翻译
          if (widget.onTranslate != null)
            _ActionIconButton(
              icon: Icons.translate_outlined,
              tooltip: '翻译',
              onTap: widget.onTranslate!,
            ),
          // 编辑
          if (widget.onEdit != null)
            _ActionIconButton(
              icon: Icons.edit_outlined,
              tooltip: '编辑',
              onTap: () => widget.onEdit!(_content),
            ),
          // 删除
          if (widget.onDelete != null)
            _ActionIconButton(
              icon: Icons.delete_outline,
              tooltip: '删除',
              onTap: widget.onDelete!,
            ),

          const Spacer(),

          // 字数统计
          Text(
            '${_content.length}字',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),

          // 更多
          _ActionIconButton(
            icon: Icons.more_horiz,
            tooltip: '更多',
            onTap: () => _showMoreActions(context),
          ),
        ],
      ),
    );
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('采纳此回复'),
              onTap: () {
                Navigator.pop(context);
                widget.onSelect?.call();
              },
            ),
            if (widget.onSpeak != null)
              ListTile(
                leading: const Icon(Icons.volume_up_outlined),
                title: const Text('朗读'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSpeak!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 分享功能
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getModelColor(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (name.contains('gpt') || name.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (name.contains('gemini') || name.contains('google')) {
      return const Color(0xFF4285F4);
    } else if (name.contains('qwen') || name.contains('通义')) {
      return const Color(0xFF6366F1);
    } else if (name.contains('deepseek')) {
      return const Color(0xFF06B6D4);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }

  IconData _getModelIcon(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return Icons.auto_awesome;
    } else if (name.contains('gpt') || name.contains('openai')) {
      return Icons.smart_toy_outlined;
    } else if (name.contains('gemini') || name.contains('google')) {
      return Icons.diamond_outlined;
    } else if (name.contains('qwen') || name.contains('通义')) {
      return Icons.cloud_outlined;
    } else if (name.contains('deepseek')) {
      return Icons.explore_outlined;
    } else {
      return Icons.memory;
    }
  }
}

/// 操作图标按钮
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
