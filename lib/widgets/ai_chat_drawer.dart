import 'package:flutter/material.dart';
import '../models/isar/unified_conversation_entity.dart';
import '../models/isar/prompt_template_entity.dart';
import '../services/unified_conversation_service.dart';
import '../services/prompt_template_service.dart';
import 'package:intl/intl.dart';

/// AI 分析抽屉菜单
///
/// 包含：
/// - 对话历史列表
/// - 模板管理
/// - 导出功能
/// - 设置入口
class AIChatDrawer extends StatefulWidget {
  /// 当前活跃对话 ID
  final String? activeConversationId;

  /// 当前 context ID（用于过滤对话）
  final String? contextId;

  /// 选择对话回调
  final void Function(String conversationId)? onSelectConversation;

  /// 新建对话回调
  final VoidCallback? onNewConversation;

  /// 删除对话回调
  final void Function(String conversationId)? onDeleteConversation;

  /// 打开设置回调
  final VoidCallback? onOpenSettings;

  /// 导出对话回调
  final VoidCallback? onExport;

  const AIChatDrawer({
    Key? key,
    this.activeConversationId,
    this.contextId,
    this.onSelectConversation,
    this.onNewConversation,
    this.onDeleteConversation,
    this.onOpenSettings,
    this.onExport,
  }) : super(key: key);

  @override
  State<AIChatDrawer> createState() => _AIChatDrawerState();
}

class _AIChatDrawerState extends State<AIChatDrawer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _conversationService = UnifiedConversationService.instance;
  final _templateService = PromptTemplateService.instance;

  List<UnifiedConversationEntity> _conversations = [];
  List<TaskTemplateEntity> _templates = [];
  bool _loading = true;
  bool _showAllDiscussions = false; // 是否显示全部讨论

  /// 从 contextId 中提取 topicId
  ///
  /// contextId 格式：topicId:groupIndex（如 'abc123:2'）
  String? get _topicId {
    final contextId = widget.contextId;
    if (contextId == null) return null;
    final colonIndex = contextId.indexOf(':');
    if (colonIndex > 0) {
      return contextId.substring(0, colonIndex);
    }
    return null;
  }

  /// 是否可以切换到全部讨论模式
  bool get _canShowAll => _topicId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      List<UnifiedConversationEntity> conversations;

      if (_showAllDiscussions && _topicId != null) {
        // 显示全部讨论：按话题前缀匹配
        conversations = await _conversationService.getConversationsByTopicPrefix(_topicId!);
      } else if (widget.contextId != null) {
        // 显示当前上下文的讨论
        conversations = await _conversationService.getConversationsByContext(widget.contextId!);
      } else {
        // 无上下文：显示所有对话
        conversations = await _conversationService.getConversations();
      }

      final templates = await _templateService.getAllTemplates();

      setState(() {
        _conversations = conversations;
        _templates = templates;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      child: Column(
        children: [
          // 头部
          _buildHeader(),

          // Tab 栏
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: '对话历史'),
              Tab(text: '模板'),
            ],
          ),

          // 内容区
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConversationList(),
                      _buildTemplateList(),
                    ],
                  ),
          ),

          // 底部操作栏
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'AI 分析',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pop(context);
              widget.onNewConversation?.call();
            },
            tooltip: '新建对话',
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return Column(
      children: [
        // 切换按钮（仅在有话题 ID 时显示）
        if (_canShowAll)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: _ScopeToggle(
                    isAllMode: _showAllDiscussions,
                    onChanged: (value) {
                      setState(() => _showAllDiscussions = value);
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ),

        // 对话列表
        Expanded(
          child: _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _showAllDiscussions ? '该话题暂无讨论' : '当前轮次暂无讨论',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onNewConversation?.call();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('开始新对话'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    final isActive = conv.conversationId == widget.activeConversationId;

                    return _ConversationTile(
                      conversation: conv,
                      isActive: isActive,
                      showRoundInfo: _showAllDiscussions, // 全部模式下显示轮次信息
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelectConversation?.call(conv.conversationId);
                      },
                      onDelete: () => _confirmDelete(conv),
                      onRename: (newTitle) => _renameConversation(conv, newTitle),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTemplateList() {
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无模板',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showTemplateEditor(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('创建模板'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 添加新建按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            onPressed: () => _showTemplateEditor(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新建模板'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 模板列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];

              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  child: Icon(
                    template.isBuiltIn ? Icons.lock : Icons.description,
                    size: 16,
                    color: Colors.purple,
                  ),
                ),
                title: Text(
                  template.name,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: template.description != null
                    ? Text(
                        template.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 查看内容
                    IconButton(
                      icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.grey[500]),
                      onPressed: () => _showTemplateDetail(template),
                      tooltip: '查看内容',
                    ),
                    // 编辑按钮（仅非内置模板）
                    if (!template.isBuiltIn)
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[500]),
                        onPressed: () => _showTemplateEditor(template),
                        tooltip: '编辑',
                      ),
                  ],
                ),
                onTap: () => _showTemplateDetail(template),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _FooterButton(
            icon: Icons.cleaning_services_outlined,
            label: '清理',
            onTap: _showCleanupDialog,
          ),
          _FooterButton(
            icon: Icons.file_download_outlined,
            label: '导出',
            onTap: () {
              Navigator.pop(context);
              widget.onExport?.call();
            },
          ),
          _FooterButton(
            icon: Icons.settings_outlined,
            label: '设置',
            onTap: () {
              Navigator.pop(context);
              widget.onOpenSettings?.call();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(UnifiedConversationEntity conv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话'),
        content: Text('确定要删除"${conv.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 关闭抽屉
              widget.onDeleteConversation?.call(conv.conversationId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 重命名对话
  Future<void> _renameConversation(
    UnifiedConversationEntity conv,
    String newTitle,
  ) async {
    await _conversationService.updateTitle(conv.conversationId, newTitle);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已重命名为"$newTitle"'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showCleanupDialog() {
    // 在进入 dialog 前保存 ScaffoldMessenger 引用，避免 dialog 关闭后 context 失效
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.orange[400]),
            const SizedBox(width: 8),
            const Text('清理对话'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前共 ${_conversations.length} 个对话'),
            const SizedBox(height: 16),
            const Text('确定要删除全部对话吗？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // 二次确认
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认删除全部'),
                  content: Text('确定要删除全部 ${_conversations.length} 个对话吗？此操作不可恢复！'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('确认删除'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final count = await _conversationService.deleteAllConversations();
                await _loadData();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('已删除全部 $count 个对话')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除全部'),
          ),
        ],
      ),
    );
  }

  void _showTemplateDetail(TaskTemplateEntity template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description, color: Colors.purple[400]),
            const SizedBox(width: 8),
            Expanded(child: Text(template.name)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              template.content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ),
        ),
        actions: [
          if (!template.isBuiltIn)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showTemplateEditor(template);
              },
              child: const Text('编辑'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showTemplateEditor(TaskTemplateEntity? template) {
    final nameController = TextEditingController(text: template?.name ?? '');
    final contentController =
        TextEditingController(text: template?.content ?? '');
    final descController =
        TextEditingController(text: template?.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(template == null ? '新建模板' : '编辑模板'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '模板名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '模板内容',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (template != null && !template.isBuiltIn)
            TextButton(
              onPressed: () async {
                // 确认删除
                final confirm = await showDialog<bool>(
                  context: dialogContext,
                  builder: (ctx) => AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除模板"${template.name}"吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _templateService.deleteTemplate(template.templateId);
                  await _loadData();
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final content = contentController.text.trim();

              if (name.isEmpty || content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名称和内容不能为空')),
                );
                return;
              }

              if (template == null) {
                await _templateService.createTemplate(
                  name: name,
                  content: content,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                );
              } else {
                template.name = name;
                template.content = content;
                template.description = descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim();
                await _templateService.updateTemplate(template);
              }

              await _loadData();
              Navigator.pop(dialogContext);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

/// 对话列表项
class _ConversationTile extends StatelessWidget {
  final UnifiedConversationEntity conversation;
  final bool isActive;
  final bool showRoundInfo; // 是否显示轮次信息（全部模式下）
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(String newTitle)? onRename; // 重命名回调

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    this.showRoundInfo = false,
    required this.onTap,
    required this.onDelete,
    this.onRename,
  });

  /// 从 contextId 中提取轮次信息
  String? get _roundInfo {
    if (!showRoundInfo) return null;
    final contextId = conversation.contextId;
    final colonIndex = contextId.indexOf(':');
    if (colonIndex > 0 && colonIndex < contextId.length - 1) {
      final indexStr = contextId.substring(colonIndex + 1);
      final index = int.tryParse(indexStr);
      if (index != null) {
        return '第${index + 1}轮';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(DateTime.fromMillisecondsSinceEpoch(conversation.updatedAt));
    final roundInfo = _roundInfo;

    return ListTile(
      selected: isActive,
      selectedTileColor: Colors.blue.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: isActive ? Colors.blue : Colors.grey[200],
        child: Icon(
          _getContextTypeIcon(conversation.contextType),
          size: 16,
          color: isActive ? Colors.white : Colors.grey[600],
        ),
      ),
      title: Row(
        children: [
          if (roundInfo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                roundInfo,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${conversation.roundCount} 轮，${conversation.messageCount} 条 · $timeStr',
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 重命名按钮
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[400]),
            onPressed: () => _showRenameDialog(context),
            tooltip: '重命名',
          ),
          // 删除按钮
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[400]),
            onPressed: onDelete,
            tooltip: '删除',
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  IconData _getContextTypeIcon(ConversationContextType type) {
    switch (type) {
      case ConversationContextType.topic:
        return Icons.chat;
      case ConversationContextType.messageGroup:
        return Icons.analytics;
      case ConversationContextType.singleMessage:
        return Icons.comment;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';

    return DateFormat('MM/dd').format(time);
  }

  /// 显示重命名对话框
  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名对话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '对话名称',
            border: OutlineInputBorder(),
            hintText: '输入新的对话名称',
          ),
          onSubmitted: (value) {
            final newTitle = value.trim();
            if (newTitle.isNotEmpty && newTitle != conversation.title) {
              onRename?.call(newTitle);
            }
            Navigator.pop(dialogContext);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != conversation.title) {
                onRename?.call(newTitle);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 底部操作按钮
class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _FooterButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// 范围切换按钮
///
/// 用于切换"当前轮次"和"全部讨论"
class _ScopeToggle extends StatelessWidget {
  final bool isAllMode;
  final ValueChanged<bool> onChanged;

  const _ScopeToggle({
    required this.isAllMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: '当前轮次',
              icon: Icons.filter_alt_outlined,
              isSelected: !isAllMode,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: '全部讨论',
              icon: Icons.view_list_outlined,
              isSelected: isAllMode,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.blue : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
