import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/data_persistence_manager.dart';
import '../services/webdav_service.dart';

// SharedPreferences 键名常量
const String _keyApiUrl = 'openai_api_url';
const String _keyApiKey = 'openai_api_key';
const String _keyModel = 'openai_model';
const String _keyColumnsPerView = 'columns_per_view';

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

  // WebDAV 配置
  late TextEditingController _webdavUrlController;
  late TextEditingController _webdavUsernameController;
  late TextEditingController _webdavPasswordController;
  late TextEditingController _webdavPathController;
  DataLoadMode _loadMode = DataLoadMode.manual;
  bool _isTestingConnection = false;

  bool _isLoading = true;
  bool _obscureApiKey = true;
  bool _obscureWebdavPassword = true;
  int _columnsPerView = 2;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController();
    _webdavUrlController = TextEditingController();
    _webdavUsernameController = TextEditingController();
    _webdavPasswordController = TextEditingController();
    _webdavPathController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _webdavUrlController.dispose();
    _webdavUsernameController.dispose();
    _webdavPasswordController.dispose();
    _webdavPathController.dispose();
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

    // 加载 WebDAV 配置
    final loadMode = await WebDavService.getLoadMode();
    final webdavConfig = await WebDavService.loadConfig();

    // 加载列数设置
    final columnsPerView = prefs.getInt(_keyColumnsPerView) ?? 2;

    setState(() {
      _apiUrlController.text = apiUrl;
      _apiKeyController.text = apiKey;
      _modelController.text = model;
      _loadMode = loadMode;
      _webdavUrlController.text = webdavConfig.url;
      _webdavUsernameController.text = webdavConfig.username;
      _webdavPasswordController.text = webdavConfig.password;
      _webdavPathController.text = webdavConfig.path;
      _columnsPerView = columnsPerView;
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

                    // WebDAV 配置部分
                    _buildWebDavSection(),

                    const SizedBox(height: 16),

                    // 显示设置部分
                    _buildDisplaySettingsSection(),

                    const SizedBox(height: 16),

                    // 数据管理部分
                    _buildDataManagementSection(),

                    const SizedBox(height: 16),

                    // 反馈部分
                    _buildFeedbackSection(),
                  ],
                ),
              ),
            ),
    );
  }

  /// 构建显示设置部分
  Widget _buildDisplaySettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.display_settings, color: Colors.blue[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '显示设置',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '配置对话查看器的显示选项',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 列数设置
            ListTile(
              leading: const Icon(Icons.view_column),
              title: const Text('每屏显示卡片列数'),
              subtitle: Text('当前设置: $_columnsPerView 列'),
              trailing: DropdownButton<int>(
                value: _columnsPerView,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 列')),
                  DropdownMenuItem(value: 2, child: Text('2 列')),
                  DropdownMenuItem(value: 3, child: Text('3 列')),
                  DropdownMenuItem(value: 4, child: Text('4 列')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _columnsPerView = value);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt(_keyColumnsPerView, value);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ 列数设置已保存'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 WebDAV 配置部分
  Widget _buildWebDavSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, color: Colors.blue[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '数据加载配置',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '支持手动加载或从 WebDAV 自动同步 Cherry Studio 备份文件',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 模式切换
            SegmentedButton<DataLoadMode>(
              segments: const [
                ButtonSegment(
                  value: DataLoadMode.manual,
                  label: Text('手动加载'),
                  icon: Icon(Icons.folder_open),
                ),
                ButtonSegment(
                  value: DataLoadMode.webdav,
                  label: Text('WebDAV'),
                  icon: Icon(Icons.cloud),
                ),
              ],
              selected: {_loadMode},
              onSelectionChanged: (Set<DataLoadMode> selected) async {
                final mode = selected.first;
                setState(() => _loadMode = mode);
                await WebDavService.setLoadMode(mode);
              },
            ),

            // WebDAV 配置表单
            if (_loadMode == DataLoadMode.webdav) ...[
              const SizedBox(height: 24),

              // WebDAV URL
              TextFormField(
                controller: _webdavUrlController,
                decoration: const InputDecoration(
                  labelText: 'WebDAV 地址',
                  hintText: 'https://example.com/dav/',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                  helperText: 'WebDAV 服务器地址',
                ),
              ),

              const SizedBox(height: 16),

              // 用户名
              TextFormField(
                controller: _webdavUsernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // 密码
              TextFormField(
                controller: _webdavPasswordController,
                obscureText: _obscureWebdavPassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureWebdavPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureWebdavPassword = !_obscureWebdavPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 路径
              TextFormField(
                controller: _webdavPathController,
                decoration: const InputDecoration(
                  labelText: '备份文件路径',
                  hintText: '/cherry-studio',
                  prefixIcon: Icon(Icons.folder),
                  border: OutlineInputBorder(),
                  helperText: 'Cherry Studio 备份文件所在目录',
                ),
              ),

              const SizedBox(height: 24),

              // 按钮行
              Row(
                children: [
                  // 测试连接按钮
                  OutlinedButton.icon(
                    onPressed: _isTestingConnection ? null : _testWebDavConnection,
                    icon: _isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_isTestingConnection ? '测试中...' : '测试连接'),
                  ),
                  const SizedBox(width: 16),
                  // 保存按钮
                  ElevatedButton.icon(
                    onPressed: _saveWebDavConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('保存配置'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 测试 WebDAV 连接
  Future<void> _testWebDavConnection() async {
    setState(() => _isTestingConnection = true);

    final config = WebDavConfig(
      url: _webdavUrlController.text.trim(),
      username: _webdavUsernameController.text.trim(),
      password: _webdavPasswordController.text.trim(),
      path: _webdavPathController.text.trim(),
    );

    final (success, message) = await WebDavService.testConnection(config);

    setState(() => _isTestingConnection = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ $message' : '❌ $message'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 保存 WebDAV 配置
  Future<void> _saveWebDavConfig() async {
    final config = WebDavConfig(
      url: _webdavUrlController.text.trim(),
      username: _webdavUsernameController.text.trim(),
      password: _webdavPasswordController.text.trim(),
      path: _webdavPathController.text.trim(),
    );

    await WebDavService.saveConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ WebDAV 配置已保存'),
          backgroundColor: Colors.green,
        ),
      );
    }
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

  /// 构建反馈部分
  Widget _buildFeedbackSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.feedback, color: Colors.blue[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '反馈与建议',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('发送邮件反馈'),
              subtitle: const Text('jimmyhe66@gmail.com'),
              onTap: _sendFeedbackEmail,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFeedbackEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jimmyhe66@gmail.com',
      queryParameters: {
        'subject': 'Cherry Viewer 反馈与建议',
      },
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开邮件客户端')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开邮件客户端: $e')),
        );
      }
    }
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

/// 获取保存的列数设置（全局函数）
Future<int> getColumnsPerView() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_keyColumnsPerView) ?? 2;
}
