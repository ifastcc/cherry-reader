import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/data_persistence_manager.dart';

// SharedPreferences 键名常量
const String _keyApiUrl = 'openai_api_url';
const String _keyApiKey = 'openai_api_key';
const String _keyModel = 'openai_model';

/// 设置页面 - 管理 AI 分析的 API 配置
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _apiUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;

  bool _isLoading = true;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 优先读取 SharedPreferences，如果没有则从 .env 读取
    final apiUrl =
        prefs.getString(_keyApiUrl) ??
        dotenv.env['OPENAI_BASE_URL'] ??
        'https://api.openai.com/v1';
    final apiKey =
        prefs.getString(_keyApiKey) ?? dotenv.env['OPENAI_API_KEY'] ?? '';
    final model =
        prefs.getString(_keyModel) ??
        dotenv.env['OPENAI_MODEL'] ??
        'gpt-4-turbo-preview';

    setState(() {
      _apiUrlController.text = apiUrl;
      _apiKeyController.text = apiKey;
      _modelController.text = model;
      _isLoading = false;
    });
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyApiUrl, _apiUrlController.text.trim());
    await prefs.setString(_keyApiKey, _apiKeyController.text.trim());
    await prefs.setString(_keyModel, _modelController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 设置已保存'), backgroundColor: Colors.green),
      );
    }
  }

  /// 重置为 .env 默认值
  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置为 .env 文件中的默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiUrl);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyModel);

    // 重新加载（会从 .env 读取）
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已重置为默认值')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefault,
            tooltip: '重置为默认值',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 说明卡片
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[300],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'AI 分析配置',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '配置 OpenAI 兼容的 API 用于生成对话分析。'
                              '支持 OpenAI、Azure OpenAI、Claude 等兼容接口。',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // API URL
                    TextFormField(
                      controller: _apiUrlController,
                      decoration: const InputDecoration(
                        labelText: 'API URL',
                        hintText: 'https://api.openai.com/v1',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                        helperText: 'OpenAI 兼容的 API 地址',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入 API URL';
                        }
                        if (!value.startsWith('http://') &&
                            !value.startsWith('https://')) {
                          return 'URL 必须以 http:// 或 https:// 开头';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Model
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: '模型名称',
                        hintText: 'gpt-4-turbo-preview',
                        prefixIcon: Icon(Icons.smart_toy),
                        border: OutlineInputBorder(),
                        helperText: '如 gpt-4、gpt-3.5-turbo、claude-3-opus 等',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入模型名称';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // API Key
                    TextFormField(
                      controller: _apiKeyController,
                      obscureText: _obscureApiKey,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'sk-...',
                        prefixIcon: const Icon(Icons.key),
                        border: const OutlineInputBorder(),
                        helperText: 'API 密钥（将安全存储在本地）',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureApiKey = !_obscureApiKey;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入 API Key';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // 保存按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('保存设置'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 数据管理部分
                    _buildDataManagementSection(),
                  ],
                ),
              ),
            ),
    );
  }

  /// 构建数据管理部分
  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.blue[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '数据管理',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 显示App数据目录
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('数据文件位置'),
              subtitle: FutureBuilder<String>(
                future: DataPersistenceManager.getAppDataFilePath(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('加载中...');
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: '复制路径',
                onPressed: () async {
                  final path =
                      await DataPersistenceManager.getAppDataFilePath();
                  await Clipboard.setData(ClipboardData(text: path));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 路径已复制'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ),

            const Divider(),

            // 清除缓存按钮
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('清除缓存'),
              subtitle: const Text('保留数据文件，仅清除解析缓存'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('清除缓存'),
                    content: const Text('确定要清除缓存吗？下次启动时会重新解析数据文件。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('清除'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await DataPersistenceManager.clearCache();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 缓存已清除'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 获取保存的 API 配置（全局函数）
Future<Map<String, String>> getApiConfig() async {
  final prefs = await SharedPreferences.getInstance();

  return {
    'apiUrl':
        prefs.getString(_keyApiUrl) ??
        dotenv.env['OPENAI_BASE_URL'] ??
        'https://api.openai.com/v1',
    'apiKey': prefs.getString(_keyApiKey) ?? dotenv.env['OPENAI_API_KEY'] ?? '',
    'model':
        prefs.getString(_keyModel) ??
        dotenv.env['OPENAI_MODEL'] ??
        'gpt-4-turbo-preview',
  };
}
