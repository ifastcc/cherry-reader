import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/ai_provider.dart';
import '../services/ai_provider_service.dart';

/// AI Provider 管理页面
///
/// 功能：
/// 1. 显示已导入的 Provider 列表
/// 2. 选择当前使用的 Provider 和 Model
/// 3. 从 Cherry Studio 备份导入
/// 4. 手动添加/编辑 Provider
class AIProviderScreen extends StatefulWidget {
  const AIProviderScreen({Key? key}) : super(key: key);

  @override
  State<AIProviderScreen> createState() => _AIProviderScreenState();
}

class _AIProviderScreenState extends State<AIProviderScreen> {
  final _providerService = AIProviderService.instance;
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    await _providerService.init();
    setState(() => _isLoading = false);
  }

  /// 从 Cherry Studio 备份导入
  Future<void> _importFromCherryStudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: '选择 Cherry Studio 备份文件',
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    setState(() => _isImporting = true);

    try {
      final count = await _providerService.importFromCherryStudioZip(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 成功导入 $count 个 Provider'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  /// 显示添加/编辑 Provider 对话框
  Future<void> _showProviderDialog([AIProvider? provider]) async {
    final isNew = provider == null;
    final nameController = TextEditingController(text: provider?.name ?? '');
    final apiKeyController = TextEditingController(text: provider?.apiKey ?? '');
    final apiHostController = TextEditingController(
      text: provider?.apiHost ?? 'https://api.openai.com/v1',
    );
    var selectedType = provider?.type ?? AIProviderType.openai;

    final result = await showDialog<AIProvider>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isNew ? '添加 Provider' : '编辑 Provider'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名称
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '例如: My OpenAI',
                  ),
                ),
                const SizedBox(height: 16),

                // 类型
                DropdownButtonFormField<AIProviderType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: '类型'),
                  items: AIProviderType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // API Host
                TextField(
                  controller: apiHostController,
                  decoration: const InputDecoration(
                    labelText: 'API Host',
                    hintText: 'https://api.openai.com/v1',
                  ),
                ),
                const SizedBox(height: 16),

                // API Key
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-...',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newProvider = AIProvider(
                  id: provider?.id ?? 'manual-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  type: selectedType,
                  apiKey: apiKeyController.text.trim(),
                  apiHost: apiHostController.text.trim(),
                  models: provider?.models ?? [],
                  enabled: true,
                  source: ProviderSource.manual, // 标记为手动添加
                );
                Navigator.pop(context, newProvider);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _providerService.addProvider(result);
      setState(() {});
    }
  }

  /// 删除 Provider
  Future<void> _deleteProvider(AIProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除 Provider'),
        content: Text('确定要删除 "${provider.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _providerService.removeProvider(provider.id);
      setState(() {});
    }
  }

  /// 选择 Model
  Future<void> _showModelSelector(AIProvider provider) async {
    if (provider.models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该 Provider 没有可用的模型')),
      );
      return;
    }

    final result = await showDialog<AIModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择模型 - ${provider.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.models.length,
            itemBuilder: (context, index) {
              final model = provider.models[index];
              final isActive = model.id == _providerService.activeModelId;
              return ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.circle_outlined,
                  color: isActive ? Colors.green : Colors.grey,
                ),
                title: Text(model.displayName),
                subtitle: model.description != null
                    ? Text(model.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                onTap: () => Navigator.pop(context, model),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _providerService.setActiveProvider(provider.id);
      await _providerService.setActiveModel(result.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Provider 管理'),
        actions: [
          // 从 Cherry Studio 导入按钮
          IconButton(
            icon: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            tooltip: '从 Cherry Studio 导入',
            onPressed: _isImporting ? null : _importFromCherryStudio,
          ),
          // 添加按钮
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加 Provider',
            onPressed: () => _showProviderDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final providers = _providerService.providers;

    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无 AI Provider',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角导入 Cherry Studio 备份\n或手动添加 Provider',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _importFromCherryStudio,
              icon: const Icon(Icons.download),
              label: const Text('从 Cherry Studio 导入'),
            ),
          ],
        ),
      );
    }

    // 当前激活的配置
    final activeProvider = _providerService.activeProvider;
    final activeModel = _providerService.activeModel;

    return Column(
      children: [
        // 当前配置卡片
        if (activeProvider != null)
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        '当前使用',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Provider: ${activeProvider.name}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Model: ${activeModel?.displayName ?? "未选择"}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'API Host: ${activeProvider.apiHost}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

        // Provider 列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final isActive = provider.id == activeProvider?.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isActive ? Colors.green[50] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.grey[300],
                    child: Icon(
                      _getProviderIcon(provider.type),
                      color: isActive ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    provider.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.type.displayName),
                      Text(
                        '${provider.models.length} 个模型',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 选择模型按钮
                      IconButton(
                        icon: const Icon(Icons.smart_toy),
                        tooltip: '选择模型',
                        onPressed: () => _showModelSelector(provider),
                      ),
                      // 编辑按钮
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: '编辑',
                        onPressed: () => _showProviderDialog(provider),
                      ),
                      // 删除按钮
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: '删除',
                        onPressed: () => _deleteProvider(provider),
                      ),
                    ],
                  ),
                  onTap: () => _showModelSelector(provider),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getProviderIcon(AIProviderType type) {
    switch (type) {
      case AIProviderType.openai:
        return Icons.auto_awesome;
      case AIProviderType.anthropic:
        return Icons.psychology;
      case AIProviderType.gemini:
        return Icons.diamond;
      case AIProviderType.azureOpenai:
        return Icons.cloud;
      default:
        return Icons.smart_toy;
    }
  }
}
