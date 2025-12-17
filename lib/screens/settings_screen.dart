import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/data_persistence_manager.dart';
import '../services/webdav_service.dart';
import '../services/local_folder_sync_service.dart';
import '../services/streaming_tts_service.dart';
import '../services/tts_cache_manager.dart';
import '../services/ai_provider_service.dart';
import '../services/cherry_export_service.dart';
import '../services/isar_database.dart';
import '../services/version_service.dart';
import '../models/domain/data_version.dart';
import '../models/isar/assistant_entity.dart';
import '../models/isar/topic_entity.dart';
import '../models/isar/message_entity.dart';
import '../models/isar/message_block_entity.dart';
import '../models/tts_settings.dart';
import '../providers/tts_provider.dart';
import '../utils/platform_utils.dart';
import 'package:just_audio/just_audio.dart';
import 'ai_provider_screen.dart';
import 'onboarding_screen.dart';
import '../services/prompt_template_service.dart';
import '../models/isar/prompt_template_entity.dart';

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

  // 本地文件夹配置
  late TextEditingController _localFolderPathController;
  bool _isValidatingFolder = false;
  bool _localFolderAutoLoad = true;  // 自动加载新版本（默认开启）

  // TTS 配置
  // late TextEditingController _azureKeyController; // Deprecated: single key
  late TextEditingController _azureRegionController;
  final List<TextEditingController> _azureKeyControllers = []; // Multiple keys
  
  TtsSettings _ttsSettings = TtsSettings();
  List<Map<String, String>> _availableVoices = [];
  bool _isLoadingVoices = false;
  // bool _obscureAzureKey = true; // Managed per key row now
  
  // Voice Preview & Favorites
  bool _isPreviewingVoice = false;
  String? _previewingVoiceName;
  final AudioPlayer _previewPlayer = AudioPlayer();

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
    _localFolderPathController = TextEditingController();
    // _azureKeyController = TextEditingController();
    _azureRegionController = TextEditingController();
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
    _localFolderPathController.dispose();
    // _azureKeyController.dispose();
    for (var controller in _azureKeyControllers) {
      controller.dispose();
    }
    _azureRegionController.dispose();
    _previewPlayer.dispose();
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

    // 加载本地文件夹配置
    final localFolderConfig = await LocalFolderSyncService.loadConfig();
    final localFolderAutoLoad = await LocalFolderSyncService.getAutoLoad();

    // 加载列数设置
    final columnsPerView = prefs.getInt(_keyColumnsPerView) ?? 2;

    // 加载 TTS 设置
    final ttsJson = prefs.getString(TtsSettings.prefKey);
    if (ttsJson != null) {
      _ttsSettings = TtsSettings.fromJson(jsonDecode(ttsJson));
    } else {
      _ttsSettings = TtsSettings();
    }

    setState(() {
      _apiUrlController.text = apiUrl;
      _apiKeyController.text = apiKey;
      _modelController.text = model;
      _loadMode = loadMode;
      _webdavUrlController.text = webdavConfig.url;
      _webdavUsernameController.text = webdavConfig.username;
      _webdavPasswordController.text = webdavConfig.password;
      _webdavPathController.text = webdavConfig.path;
      _localFolderPathController.text = localFolderConfig.folderPath;
      _localFolderAutoLoad = localFolderAutoLoad;
      _columnsPerView = columnsPerView;
      
      // Load Azure Keys
      _azureKeyControllers.clear();
      if (_ttsSettings.azureApiKeys.isNotEmpty) {
        for (var key in _ttsSettings.azureApiKeys) {
          _azureKeyControllers.add(TextEditingController(text: key));
        }
      } else if (_ttsSettings.azureApiKey.isNotEmpty) {
        // Migration from single key
        _azureKeyControllers.add(TextEditingController(text: _ttsSettings.azureApiKey));
        _ttsSettings.azureApiKeys = [_ttsSettings.azureApiKey];
        _ttsSettings.azureApiKey = ''; // Clear old single key
      } else {
        // Default empty slot
        _azureKeyControllers.add(TextEditingController());
      }
      
      _azureRegionController.text = _ttsSettings.azureRegion;
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

    // 保存 TTS 设置
    _ttsSettings.azureApiKeys = _azureKeyControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    // Sync legacy key for backward compatibility
    if (_ttsSettings.azureApiKeys.isNotEmpty) {
      _ttsSettings.azureApiKey = _ttsSettings.azureApiKeys.first;
    } else {
      _ttsSettings.azureApiKey = '';
    }

    _ttsSettings.azureRegion = _azureRegionController.text.trim();
    await prefs.setString(TtsSettings.prefKey, jsonEncode(_ttsSettings.toJson()));

    // 通知 TtsProvider 重新加载配置
    if (mounted) {
      final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
      await ttsProvider.reloadSettings();
    }

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

                    const SizedBox(height: 16),

                    // Provider 管理入口
                    _buildProviderManagementCard(),

                    const SizedBox(height: 16),

                    // AI 偏好设置
                    _buildAIPreferencesCard(),

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

                    // 【新增】版本管理部分
                    _buildVersionManagementSection(),

                    const SizedBox(height: 16),

                    // 显示设置部分
                    _buildDisplaySettingsSection(),

                    const SizedBox(height: 16),

                    // TTS 设置部分
                    _buildTtsSettingsSection(),

                    const SizedBox(height: 16),

                    // 数据管理部分
                    _buildDataManagementSection(),

                    const SizedBox(height: 16),

                    // 关于与帮助部分
                    _buildAboutSection(),

                    const SizedBox(height: 16),

                    // 反馈部分
                    _buildFeedbackSection(),
                  ],
                ),
              ),
            ),
    );
  }

  /// 【新增】构建版本管理部分
  Widget _buildVersionManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.purple[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '版本管理',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '管理导入的数据版本，支持切换历史版本',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // 使用 FutureBuilder 获取版本列表
            FutureBuilder<List<DataVersion>>(
              future: VersionService.instance.listVersions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final versions = snapshot.data ?? [];

                if (versions.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        const Text('暂无版本数据'),
                      ],
                    ),
                  );
                }

                // 找到当前活跃版本
                final activeVersion = versions.firstWhere(
                  (v) => v.status == VersionStatus.active,
                  orElse: () => versions.first,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 当前版本信息
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '当前版本: ${activeVersion.displayName}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${activeVersion.topicCount} 话题 • ${activeVersion.formattedSize}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          if (activeVersion.isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock, size: 14, color: Colors.orange[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '已锁定',
                                    style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 锁定开关
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('锁定当前版本'),
                      subtitle: Text(
                        '锁定后不会自动切换到新版本',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      value: activeVersion.isLocked,
                      onChanged: (value) async {
                        await VersionService.instance.setVersionLocked(value);
                        setState(() {}); // 刷新 UI
                      },
                    ),

                    const Divider(),

                    // 历史版本列表
                    if (versions.length > 1) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '历史版本',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ...versions
                          .where((v) => v.status != VersionStatus.active)
                          .map((version) => _buildVersionListItem(version)),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建版本列表项
  Widget _buildVersionListItem(DataVersion version) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.archive, color: Colors.grey[400], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(version.displayName),
                Text(
                  '${version.topicCount} 话题 • ${version.formattedSize}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final success = await VersionService.instance.activateVersion(
                version.versionId,
                force: true,
              );
              if (success && mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已切换到版本: ${version.displayName}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('切换'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red[300],
            onPressed: () => _confirmDeleteVersion(version),
          ),
        ],
      ),
    );
  }

  /// 确认删除版本
  Future<void> _confirmDeleteVersion(DataVersion version) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除版本'),
        content: Text('确定要删除版本 "${version.displayName}" 吗？\n\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await VersionService.instance.deleteVersion(version.versionId);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('版本已删除'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
              PlatformUtils.supportsLocalFolderSync
                  ? '支持手动加载、本地文件夹监听或 WebDAV 自动同步'
                  : '支持手动加载或从 WebDAV 自动同步 Cherry Studio 备份文件',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 模式切换
            SegmentedButton<DataLoadMode>(
              segments: [
                const ButtonSegment(
                  value: DataLoadMode.manual,
                  label: Text('手动加载'),
                  icon: Icon(Icons.folder_open),
                ),
                // 仅桌面端显示本地文件夹选项
                if (PlatformUtils.supportsLocalFolderSync)
                  const ButtonSegment(
                    value: DataLoadMode.localFolder,
                    label: Text('本地文件夹'),
                    icon: Icon(Icons.folder_copy),
                  ),
                const ButtonSegment(
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

            // 本地文件夹配置表单
            if (_loadMode == DataLoadMode.localFolder) ...[
              const SizedBox(height: 24),

              // 说明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '如何找到备份目录',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cherry Studio：设置 → 数据设置 → 本地备份 → 备份目录',
                      style: TextStyle(color: Colors.blue[800], fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 文件夹路径
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _localFolderPathController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: '备份文件夹路径',
                        hintText: '点击右侧按钮选择文件夹',
                        prefixIcon: Icon(Icons.folder),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _selectLocalFolder,
                    tooltip: '选择文件夹',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 自动加载开关
              SwitchListTile(
                title: const Text('检测到新版本时自动加载'),
                subtitle: const Text('关闭后需手动点击状态栏加载'),
                value: _localFolderAutoLoad,
                onChanged: (value) async {
                  setState(() => _localFolderAutoLoad = value);
                  await LocalFolderSyncService.setAutoLoad(value);
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // 验证和保存按钮
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isValidatingFolder ? null : _validateLocalFolder,
                    icon: _isValidatingFolder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isValidatingFolder ? '验证中...' : '验证文件夹'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _saveLocalFolderConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('保存配置'),
                  ),
                ],
              ),
            ],

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

  /// 选择本地文件夹
  Future<void> _selectLocalFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择 Cherry Studio 备份目录',
    );

    if (result != null) {
      setState(() {
        _localFolderPathController.text = result;
      });
    }
  }

  /// 验证本地文件夹
  Future<void> _validateLocalFolder() async {
    final path = _localFolderPathController.text.trim();
    if (path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先选择文件夹'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isValidatingFolder = true);

    final (success, message) = await LocalFolderSyncService.validateFolder(path);

    setState(() => _isValidatingFolder = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ $message' : '❌ $message'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 保存本地文件夹配置
  Future<void> _saveLocalFolderConfig() async {
    final config = LocalFolderConfig(
      folderPath: _localFolderPathController.text.trim(),
    );

    await LocalFolderSyncService.saveConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 本地文件夹配置已保存'),
          backgroundColor: Colors.green,
        ),
      );
    }
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

            // 数据统计
            _buildDataStatisticsTile(),

            const Divider(),

            // 导出数据
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.green),
              title: const Text('导出数据'),
              subtitle: const Text('导出为 Cherry Studio 兼容的备份格式'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showExportDialog,
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

  /// 构建数据统计磁贴
  Widget _buildDataStatisticsTile() {
    return FutureBuilder<Map<String, int>>(
      future: _getDataStatistics(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final isLoading = !snapshot.hasData;

        return ListTile(
          leading: const Icon(Icons.analytics_outlined, color: Colors.purple),
          title: const Text('数据统计'),
          subtitle: isLoading
              ? const Text('加载中...')
              : Text(
                  '${stats!['assistants']} 个助手 · ${stats['topics']} 个话题 · ${stats['messages']} 条消息',
                  style: const TextStyle(fontSize: 12),
                ),
          trailing: IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => setState(() {}),
            tooltip: '刷新统计',
          ),
        );
      },
    );
  }

  /// 获取数据统计
  Future<Map<String, int>> _getDataStatistics() async {
    try {
      final db = IsarDatabase();
      final isar = await db.instance;

      final assistantsCount = await isar.assistantEntitys.count();
      final topicsCount = await isar.topicEntitys.count();
      final messagesCount = await isar.messageEntitys.count();
      final blocksCount = await isar.messageBlockEntitys.count();

      return {
        'assistants': assistantsCount,
        'topics': topicsCount,
        'messages': messagesCount,
        'blocks': blocksCount,
      };
    } catch (e) {
      return {'assistants': 0, 'topics': 0, 'messages': 0, 'blocks': 0};
    }
  }

  /// 显示导出对话框
  Future<void> _showExportDialog() async {
    final stats = await _getDataStatistics();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: Colors.green[400]),
            const SizedBox(width: 8),
            const Text('导出数据'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('将当前数据导出为 Cherry Studio 兼容的备份格式。'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 数据概览', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('• ${stats['assistants']} 个助手', style: TextStyle(color: Colors.grey[600])),
                  Text('• ${stats['topics']} 个话题', style: TextStyle(color: Colors.grey[600])),
                  Text('• ${stats['messages']} 条消息', style: TextStyle(color: Colors.grey[600])),
                  Text('• ${stats['blocks']} 个消息块', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '💡 导出的 ZIP 文件可以通过 Cherry Studio 的「恢复」功能导入',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportAsJson();
            },
            icon: const Icon(Icons.code, size: 18),
            label: const Text('导出 JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportAsZip();
            },
            icon: const Icon(Icons.folder_zip, size: 18),
            label: const Text('导出 ZIP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// 导出为 ZIP
  Future<void> _exportAsZip() async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在导出...'),
            ],
          ),
        ),
      );

      final db = IsarDatabase();
      final exportService = CherryExportService(db);

      // 让用户选择保存位置
      final fileName = 'cherry-studio-export-${DateTime.now().millisecondsSinceEpoch}.zip';

      String? outputPath;

      // 尝试使用文件选择器
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null) {
        outputPath = result;
      } else {
        // 用户取消
        if (mounted) Navigator.pop(context);
        return;
      }

      await exportService.exportToZip(outputPath);

      // 关闭加载指示器
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 已导出到: $outputPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 关闭加载指示器
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 导出为 JSON
  Future<void> _exportAsJson() async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在导出...'),
            ],
          ),
        ),
      );

      final db = IsarDatabase();
      final exportService = CherryExportService(db);

      // 让用户选择保存位置
      final fileName = 'cherry-studio-export-${DateTime.now().millisecondsSinceEpoch}.json';

      String? outputPath;

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        outputPath = result;
      } else {
        // 用户取消
        if (mounted) Navigator.pop(context);
        return;
      }

      await exportService.exportToJson(outputPath);

      // 关闭加载指示器
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 已导出到: $outputPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 关闭加载指示器
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 构建关于与帮助部分
  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '关于与帮助',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 重新查看引导
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('新手引导'),
              subtitle: const Text('重新查看首次使用引导'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('重新查看引导'),
                    content: const Text('是否重新查看新手引导？\n\n这将返回引导页面，你可以重新配置数据来源。'),
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

                if (confirmed == true && mounted) {
                  await OnboardingScreen.resetOnboarding();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/onboarding',
                    (route) => false,
                  );
                }
              },
            ),

            const Divider(),

            // 应用信息
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于 Cherry Reader'),
              subtitle: const Text('查看应用信息'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Cherry Reader',
                  applicationVersion: '1.0.0',
                  applicationIcon: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  children: [
                    const Text('优雅地阅读你的 AI 对话'),
                    const SizedBox(height: 8),
                    const Text(
                      '专为 Cherry Studio 用户打造的对话阅读器，'
                      '支持 WebDAV 自动同步、语音朗读等功能。',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                );
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

  /// 构建 TTS 设置部分
  /// 构建 TTS 设置部分
  Widget _buildTtsSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over, color: Colors.blue[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '语音合成配置 (Azure TTS)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '配置 Microsoft Azure Speech 服务以启用语音朗读功能',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://portal.azure.com/#create/Microsoft.CognitiveServicesSpeechServices')),
              child: Row(
                children: [
                  Icon(Icons.link, size: 14, color: Colors.blue[300]),
                  const SizedBox(width: 4),
                  Text(
                    '获取 Azure Speech Key',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Azure Region
            TextFormField(
              controller: _azureRegionController,
              decoration: const InputDecoration(
                labelText: 'Azure Region',
                hintText: 'eastus',
                prefixIcon: Icon(Icons.public),
                border: OutlineInputBorder(),
                helperText: '例如: eastus, japaneast, southeastasia',
              ),
            ),
            const SizedBox(height: 16),

            // Azure Keys List
            const Text('Azure Subscription Keys', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._azureKeyControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              final isCurrent = index == _ttsSettings.currentKeyIndex;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        obscureText: true, // Always obscure for security
                        decoration: InputDecoration(
                          labelText: 'Key ${index + 1}${isCurrent ? " (当前使用)" : ""}',
                          hintText: 'Enter Key',
                          prefixIcon: Icon(
                            Icons.vpn_key, 
                            color: isCurrent ? Colors.green : null
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_azureKeyControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeApiKey(index),
                        tooltip: '删除 Key',
                      ),
                  ],
                ),
              );
            }).toList(),
            
            // Add Key Button
            OutlinedButton.icon(
              onPressed: _addApiKey,
              icon: const Icon(Icons.add),
              label: const Text('添加备用 Key'),
            ),
            
            const SizedBox(height: 16),

            // 获取声音列表按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingVoices ? null : _fetchVoices,
                icon: _isLoadingVoices
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download),
                label: const Text('获取可用声音列表'),
              ),
            ),

            if (_availableVoices.isNotEmpty || _ttsSettings.defaultVoiceName.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('默认发音人'),
                subtitle: Text(
                  _ttsSettings.defaultVoiceName.isNotEmpty
                      ? (_availableVoices.isNotEmpty
                          ? _availableVoices.firstWhere(
                              (v) => v['shortName'] == _ttsSettings.defaultVoiceName,
                              orElse: () => {
                                'localName': _ttsSettings.defaultVoiceLocalName.isNotEmpty
                                    ? _ttsSettings.defaultVoiceLocalName
                                    : '未知语音 (${_ttsSettings.defaultVoiceName})',
                                'shortName': ''
                              },
                            )['localName'] as String
                          : (_ttsSettings.defaultVoiceLocalName.isNotEmpty
                              ? _ttsSettings.defaultVoiceLocalName
                              : _ttsSettings.defaultVoiceName))
                      : '点击选择',
                  style: TextStyle(
                    color: _ttsSettings.defaultVoiceName.isNotEmpty
                        ? Colors.blue[300]
                        : Colors.grey,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showVoicePickerDialog(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade700),
                ),
              ),
            ],

            // 朗读节奏设置
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.speed, color: Colors.green[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '朗读节奏',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '控制标题、段落之间的停顿时长',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 12),

            // 节奏倍率滑块
            Row(
              children: [
                const Text('节奏: '),
                Expanded(
                  child: Slider(
                    value: _ttsSettings.rhythmScale,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: _getRhythmLabel(_ttsSettings.rhythmScale),
                    onChanged: (value) {
                      setState(() {
                        _ttsSettings.rhythmScale = value;
                      });
                    },
                    onChangeEnd: (value) async {
                      // 保存设置
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(TtsSettings.prefKey, jsonEncode(_ttsSettings.toJson()));
                      // 通知 TtsProvider
                      if (mounted) {
                        final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
                        await ttsProvider.reloadSettings();
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    _getRhythmLabel(_ttsSettings.rhythmScale),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[300],
                    ),
                  ),
                ),
              ],
            ),

            // 预设按钮
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildRhythmPresetChip('快速', 0.6, Icons.fast_forward),
                _buildRhythmPresetChip('正常', 1.0, Icons.play_arrow),
                _buildRhythmPresetChip('舒缓', 1.3, Icons.slow_motion_video),
                _buildRhythmPresetChip('有声书', 1.5, Icons.menu_book),
              ],
            ),

            // TTS 缓存管理
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.storage, color: Colors.orange[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '语音缓存',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCacheManagementTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheManagementTile() {
    return FutureBuilder<int>(
      future: _getTtsCacheSize(),
      builder: (context, snapshot) {
        final sizeText = snapshot.hasData
            ? _formatCacheSize(snapshot.data!)
            : '计算中...';

        return ListTile(
          leading: const Icon(Icons.folder_open),
          title: const Text('清除语音缓存'),
          subtitle: Text('当前缓存: $sizeText'),
          trailing: TextButton.icon(
            onPressed: () => _clearTtsCache(),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('清除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade700),
          ),
        );
      },
    );
  }

  Future<int> _getTtsCacheSize() async {
    final cacheManager = TtsCacheManager();
    return await cacheManager.getCacheSize();
  }

  String _formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _clearTtsCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除语音缓存'),
        content: const Text('确定要清除所有语音缓存吗？\n已缓存的语音将需要重新生成。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final cacheManager = TtsCacheManager();
      await cacheManager.clearCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音缓存已清除')),
        );
        setState(() {}); // 刷新缓存大小显示
      }
    }
  }

  Future<void> _fetchVoices() async {
    final keys = _azureKeyControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (keys.isEmpty || _azureRegionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入 Region 和至少一个 Key')),
      );
      return;
    }

    setState(() => _isLoadingVoices = true);

    try {
      final service = StreamingTtsService(
        apiKeys: keys,
        region: _azureRegionController.text.trim(),
      );
      final voices = await service.getVoices();

      // Filter for Chinese voices primarily, or sort them
      final chineseVoices = voices.where((v) => v['locale']?.startsWith('zh') ?? false).toList();
      final otherVoices = voices.where((v) => !(v['locale']?.startsWith('zh') ?? false)).toList();

      setState(() {
        _availableVoices = [...chineseVoices, ...otherVoices];
        _isLoadingVoices = false;
      });

      // 自动保存 TTS 配置(关键修复!)
      _ttsSettings.azureApiKeys = keys;
      if (keys.isNotEmpty) {
        _ttsSettings.azureApiKey = keys.first;
      }
      _ttsSettings.azureRegion = _azureRegionController.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TtsSettings.prefKey, jsonEncode(_ttsSettings.toJson()));

      // 通知 TtsProvider 重新加载配置
      if (mounted) {
        final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
        await ttsProvider.reloadSettings();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 成功获取 ${voices.length} 个声音并保存配置'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingVoices = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  // Helper Methods
  
  void _addApiKey() {
    setState(() {
      _azureKeyControllers.add(TextEditingController());
    });
  }
  
  void _removeApiKey(int index) {
    if (_azureKeyControllers.length > 1) {
      setState(() {
        _azureKeyControllers[index].dispose();
        _azureKeyControllers.removeAt(index);
      });
    } else {
      // Don't remove the last one, just clear it
      _azureKeyControllers[index].clear();
    }
  }
  
  Future<void> _previewVoice(String voiceName) async {
    // Stop any existing playback first
    try {
      await _previewPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping preview player: $e');
    }

    if (_isPreviewingVoice && _previewingVoiceName == voiceName) {
      setState(() {
        _isPreviewingVoice = false;
        _previewingVoiceName = null;
      });
      return; // Toggle off
    }
    
    // Check keys
    final keys = _azureKeyControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
        
    if (keys.isEmpty || _azureRegionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 Azure TTS')),
      );
      return;
    }
    
    setState(() {
      _isPreviewingVoice = true;
      _previewingVoiceName = voiceName;
    });
    
    try {
      final service = StreamingTtsService(
        apiKeys: keys,
        region: _azureRegionController.text.trim(),
      );
      
      final audioPath = await service.previewVoice(voiceName: voiceName);

      await _previewPlayer.setFilePath(audioPath);
      await _previewPlayer.play();

      // 监听播放完成
      _previewPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() {
            _isPreviewingVoice = false;
            _previewingVoiceName = null;
          });
        }
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPreviewingVoice = false;
          _previewingVoiceName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('试听失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _toggleFavorite(String voiceName) {
    setState(() {
      if (_ttsSettings.favoriteVoices.contains(voiceName)) {
        _ttsSettings.favoriteVoices.remove(voiceName);
      } else {
        _ttsSettings.favoriteVoices.add(voiceName);
      }
    });
    // Auto save? Maybe not, wait for explicit save.
    // But user might expect immediate feedback. 
    // Let's just update state for now, save happens on "Save Settings".
  }

  /// 显示语音选择器对话框
  Future<void> _showVoicePickerDialog() async {
    // 如果没有加载声音，尝试自动加载
    if (_availableVoices.isEmpty) {
       await _fetchVoices();
       if (_availableVoices.isEmpty) return; // 加载失败或取消
    }

    String searchQuery = '';
    String? selectedLocale = 'all'; // 'all', 'zh', 'en', etc.

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 1. 过滤语音列表
          var filteredVoices = _availableVoices.where((voice) {
            final matchesSearch = searchQuery.isEmpty ||
                (voice['localName']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                (voice['shortName']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
            
            final matchesLocale = selectedLocale == 'all' ||
                (voice['locale']?.toString().startsWith(selectedLocale ?? '') ?? false);
            
            return matchesSearch && matchesLocale;
          }).toList();
          
          // 2. 分离收藏和非收藏
          final favoriteItems = <Map<String, String>>[];
          final otherItems = <Map<String, String>>[];
          
          // 按收藏顺序添加
          for (var shortName in _ttsSettings.favoriteVoices) {
            // 只有在过滤结果中存在的才显示
            try {
              final voice = filteredVoices.firstWhere((v) => v['shortName'] == shortName);
              favoriteItems.add(voice);
            } catch (_) {}
          }
          
          // 添加其他
          for (var voice in filteredVoices) {
            if (!_ttsSettings.favoriteVoices.contains(voice['shortName'])) {
              otherItems.add(voice);
            }
          }

          return AlertDialog(
            title: const Text('选择默认发音人'),
            contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            content: SizedBox(
              width: double.maxFinite,
              height: 600,
              child: Column(
                children: [
                  // 搜索框
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索语音...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() => searchQuery = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 语言过滤器
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('全部'),
                            selected: selectedLocale == 'all',
                            onSelected: (selected) {
                              if (selected) setDialogState(() => selectedLocale = 'all');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('中文'),
                            selected: selectedLocale == 'zh',
                            onSelected: (selected) {
                              if (selected) setDialogState(() => selectedLocale = 'zh');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('英语'),
                            selected: selectedLocale == 'en',
                            onSelected: (selected) {
                              if (selected) setDialogState(() => selectedLocale = 'en');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('日语'),
                            selected: selectedLocale == 'ja',
                            onSelected: (selected) {
                              if (selected) setDialogState(() => selectedLocale = 'ja');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 列表内容
                  Expanded(
                    child: ListView(
                      children: [
                        // 收藏部分
                        if (favoriteItems.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Text('已收藏 (长按拖拽排序)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: favoriteItems.length,
                            onReorder: (oldIndex, newIndex) {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = favoriteItems.removeAt(oldIndex);
                              favoriteItems.insert(newIndex, item);
                              
                              // Update settings
                              final shortName = item['shortName']!;
                              _ttsSettings.favoriteVoices.remove(shortName);
                              _ttsSettings.favoriteVoices.insert(newIndex, shortName);
                              
                              setDialogState(() {});
                            },
                            itemBuilder: (context, index) {
                              final voice = favoriteItems[index];
                              return _buildVoiceTile(voice, true, setDialogState, Key(voice['shortName']!));
                            },
                          ),
                          const Divider(),
                        ],
                        
                        // 其他部分
                        if (otherItems.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Text('所有语音', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ...otherItems.map((voice) => _buildVoiceTile(voice, false, setDialogState, null)),
                        ],
                        
                        if (favoriteItems.isEmpty && otherItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('没有找到匹配的语音')),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _previewPlayer.stop();
                  Navigator.pop(context);
                },
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVoiceTile(Map<String, String> voice, bool isFavorite, StateSetter setDialogState, Key? key) {
    final shortName = voice['shortName'] as String;
    final localName = voice['localName'] as String;
    final locale = voice['locale'] as String?;
    final gender = voice['gender'] as String?;
    final isSelected = shortName == _ttsSettings.defaultVoiceName;
    final isPreviewing = _isPreviewingVoice && _previewingVoiceName == shortName;

    return ListTile(
      key: key,
      selected: isSelected,
      leading: IconButton(
        icon: Icon(isPreviewing ? Icons.stop_circle : Icons.play_circle_outline),
        color: isPreviewing ? Colors.red : Colors.blue,
        onPressed: () async {
          await _previewVoice(shortName);
          setDialogState(() {});
        },
      ),
      title: Text(
        localName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '$shortName${locale != null ? ' • $locale' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.orange : Colors.grey,
            ),
            onPressed: () {
              _toggleFavorite(shortName);
              setDialogState(() {});
            },
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: Colors.blue[300]),
        ],
      ),
      onTap: () {
        setState(() {
          _ttsSettings.defaultVoiceName = shortName;
          _ttsSettings.defaultVoiceLocalName = localName; // 保存本地名称
        });
        setDialogState(() {}); // Refresh to show checkmark
      },
    );
  }

  /// 构建 AI 偏好设置卡片
  Widget _buildAIPreferencesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.purple[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'AI 偏好设置',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '配置全局 System Prompt，对所有 AI 对话生效',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 12),

            // 当前偏好
            FutureBuilder<UserPreferenceEntity?>(
              future: PromptTemplateService.instance.getActivePreference(),
              builder: (context, snapshot) {
                final pref = snapshot.data;
                return ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.purple[300]),
                  title: Text(pref?.name ?? '默认偏好'),
                  subtitle: Text(
                    pref?.systemPrompt.split('\n').first ?? '点击编辑偏好设置',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () => _showPreferenceEditor(pref),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示偏好编辑器
  void _showPreferenceEditor(UserPreferenceEntity? preference) async {
    // 如果没有偏好，先获取
    preference ??= await PromptTemplateService.instance.getActivePreference();

    final nameController = TextEditingController(text: preference?.name ?? '默认偏好');
    final contentController = TextEditingController(text: preference?.systemPrompt ?? '');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑 AI 偏好'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Prompt 会添加到所有 AI 对话的开头',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '偏好名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'System Prompt',
                  hintText: '例如：\n- 总是使用简体中文回答\n- 从第一性原理思考\n- 回复简洁',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
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
            onPressed: () async {
              final name = nameController.text.trim();
              final content = contentController.text.trim();

              if (preference != null) {
                preference.name = name;
                preference.systemPrompt = content;
                await PromptTemplateService.instance.updatePreference(preference);
              } else {
                await PromptTemplateService.instance.createPreference(
                  name: name,
                  systemPrompt: content,
                  setActive: true,
                );
              }

              Navigator.pop(context);
              setState(() {}); // 刷新界面

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI 偏好已保存'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 构建 Provider 管理入口卡片
  Widget _buildProviderManagementCard() {
    final providerService = AIProviderService.instance;
    final activeProvider = providerService.activeProvider;
    final activeModel = providerService.activeModel;
    final hasProviders = providerService.providers.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.green[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'AI Provider 管理',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (hasProviders)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${providerService.validProviders.length} 个可用',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasProviders
                  ? '当前: ${activeProvider?.name ?? "未选择"} / ${activeModel?.displayName ?? "未选择模型"}'
                  : '从 Cherry Studio 备份导入 AI 配置，快速使用多个模型',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AIProviderScreen(),
                        ),
                      ).then((_) => setState(() {})); // 返回时刷新状态
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: Text(hasProviders ? '管理 Provider' : '导入配置'),
                  ),
                ),
                if (hasProviders) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _useProviderConfig,
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('应用到上方'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取节奏倍率的显示文本
  String _getRhythmLabel(double scale) {
    if (scale <= 0.6) return '快速';
    if (scale <= 0.8) return '较快';
    if (scale <= 1.1) return '正常';
    if (scale <= 1.3) return '舒缓';
    if (scale <= 1.5) return '慢速';
    return '很慢';
  }

  /// 构建节奏预设按钮
  Widget _buildRhythmPresetChip(String label, double scale, IconData icon) {
    final isSelected = (_ttsSettings.rhythmScale - scale).abs() < 0.05;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : null),
      label: Text(label),
      backgroundColor: isSelected ? Colors.green : null,
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      onPressed: () async {
        setState(() {
          _ttsSettings.rhythmScale = scale;
        });
        // 保存设置
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(TtsSettings.prefKey, jsonEncode(_ttsSettings.toJson()));
        // 通知 TtsProvider
        if (mounted) {
          final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
          await ttsProvider.reloadSettings();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已切换到「$label」节奏'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  /// 将 Provider 配置应用到传统配置字段
  void _useProviderConfig() {
    final config = AIProviderService.instance.getActiveConfig();
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个有效的 Provider 和模型')),
      );
      return;
    }

    setState(() {
      _apiUrlController.text = config.baseUrl;
      _apiKeyController.text = config.apiKey;
      _modelController.text = config.modelId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已应用 Provider 配置: ${config.modelId}'),
        backgroundColor: Colors.green,
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

/// 获取保存的列数设置（全局函数）
Future<int> getColumnsPerView() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_keyColumnsPerView) ?? 2;
}
