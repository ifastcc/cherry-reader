import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/data_persistence_manager.dart';
import '../services/webdav_service.dart';
import '../services/local_folder_sync_service.dart';
import '../services/lan_http_sync/lan_http_sync_config.dart';
import '../services/lan_http_sync/lan_http_sync_pull_prefs.dart';
import '../services/lan_http_sync/lan_http_sync_server_service.dart';
import '../services/sync/sync_preferences.dart';
import '../services/sync/sync_source_type.dart';
import '../services/streaming_tts_service.dart';
import '../services/tts_cache_manager.dart';
import '../services/ai_provider_service.dart';
import '../services/cherry_export_service.dart';
import '../services/app_db.dart';
import '../services/mcp/mcp_server_service.dart';
import '../services/mcp/mcp_config.dart';
import '../models/tts_settings.dart';
import '../providers/tts_provider.dart';
import '../utils/platform_utils.dart';
import 'package:just_audio/just_audio.dart';
import 'ai_provider_screen.dart';
import 'onboarding_screen.dart';
import '../services/prompt_template_service.dart';
import '../services/insight_service.dart';
import '../services/perspective_storage.dart';
import '../models/isar/prompt_template_entity.dart';
import '../models/isar/perspective_entity.dart';
import 'lan_transfer_receive_screen.dart';
import 'lan_transfer_send_screen.dart';
import 'lan_http_sync_pull_screen.dart';
import '../services/sync/server_sync_service.dart';

// SharedPreferences 键名常量
const String _keyApiUrl = 'openai_api_url';
const String _keyApiKey = 'openai_api_key';
const String _keyModel = 'openai_model';

/// 设置页面 - 管理 AI 分析的 API 配置
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  late TextEditingController _apiUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;

  // WebDAV 配置
  late TextEditingController _webdavUrlController;
  late TextEditingController _webdavUsernameController;
  late TextEditingController _webdavPasswordController;
  late TextEditingController _webdavPathController;
  bool _isTestingConnection = false;

  // 本地文件夹配置
  late TextEditingController _localFolderPathController;
  bool _isValidatingFolder = false;
  bool _localFolderAutoLoad = true; // 自动加载新版本（默认开启）

  bool _autoWebDavEnabled = false;
  bool _autoLocalFolderEnabled = false;
  bool _autoLanReceiveEnabled = false;
  bool _autoHttpPullEnabled = false;
  bool _autoServerSyncEnabled = false;

  final Map<SyncSourceType, bool> _syncSourceExpanded = {};
  final Map<String, bool> _syncToolExpanded = {};

  late TextEditingController _httpPullBaseUrlController;
  late TextEditingController _httpPullTokenController;
  bool _isTestingHttpPull = false;
  String? _httpPullTestMessage;

  // 同步服务器配置
  late TextEditingController _serverSyncUrlController;
  late TextEditingController _serverSyncTokenController;
  bool _isTestingServerSync = false;
  bool _isSyncingNow = false;
  String? _serverSyncTestMessage;
  ServerSyncMode _serverSyncMode = ServerSyncMode.pullOnly;
  ServerSyncConflictPolicy _serverSyncConflictPolicy =
      ServerSyncConflictPolicy.serverWins;
  List<ServerSyncPendingConflict> _serverSyncPendingConflicts = const [];
  bool _isResolvingServerSyncConflict = false;
  String? _resolvingServerSyncConflictKey;

  LanHttpSyncConfig? _lanHttpSyncConfig;
  LanHttpSyncServerStatus _lanHttpSyncStatus = const LanHttpSyncStopped();
  StreamSubscription<LanHttpSyncServerStatus>? _lanHttpSyncStatusSubscription;
  late TextEditingController _lanHttpSyncPortController;

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

  // TTS 自动保存（防抖）
  Timer? _ttsSaveTimer;

  bool _isLoading = true;
  bool _obscureWebdavPassword = true;
  String _currentViewMode = 'timeline';
  bool _useWebViewConversation = false; // WebView 版话题详情页开关

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
    _httpPullBaseUrlController = TextEditingController();
    _httpPullTokenController = TextEditingController();
    _lanHttpSyncPortController = TextEditingController();
    _serverSyncUrlController = TextEditingController();
    _serverSyncTokenController = TextEditingController();
    // _azureKeyController = TextEditingController();
    _azureRegionController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    // 取消防抖 Timer 并立即保存 TTS 设置
    _ttsSaveTimer?.cancel();
    _saveTtsSettingsSync();
    _lanHttpSyncStatusSubscription?.cancel();

    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _webdavUrlController.dispose();
    _webdavUsernameController.dispose();
    _webdavPasswordController.dispose();
    _webdavPathController.dispose();
    _localFolderPathController.dispose();
    _httpPullBaseUrlController.dispose();
    _httpPullTokenController.dispose();
    _lanHttpSyncPortController.dispose();
    _serverSyncUrlController.dispose();
    _serverSyncTokenController.dispose();
    // _azureKeyController.dispose();
    for (var controller in _azureKeyControllers) {
      controller.dispose();
    }
    _azureRegionController.dispose();
    _previewPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// TTS 设置变化时调用（防抖保存）
  void _onTtsSettingsChanged() {
    _ttsSaveTimer?.cancel();
    _ttsSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveTtsSettingsAsync();
    });
  }

  /// 异步保存 TTS 设置
  Future<void> _saveTtsSettingsAsync() async {
    // 收集当前的 API Keys
    final keys = _azureKeyControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    _ttsSettings.azureApiKeys = keys;
    if (keys.isNotEmpty) {
      _ttsSettings.azureApiKey = keys.first;
    }
    _ttsSettings.azureRegion = _azureRegionController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      TtsSettings.prefKey,
      jsonEncode(_ttsSettings.toJson()),
    );

    // 通知 TtsProvider
    if (mounted) {
      final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
      await ttsProvider.reloadSettings();
    }

    debugPrint('🔐 TTS 设置已自动保存');
  }

  /// 同步保存 TTS 设置（在 dispose 中使用）
  void _saveTtsSettingsSync() {
    final keys = _azureKeyControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    _ttsSettings.azureApiKeys = keys;
    if (keys.isNotEmpty) {
      _ttsSettings.azureApiKey = keys.first;
    }
    _ttsSettings.azureRegion = _azureRegionController.text.trim();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(TtsSettings.prefKey, jsonEncode(_ttsSettings.toJson()));
    });
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

    // 加载视图模式
    final viewMode = prefs.getString('home_view_mode') ?? 'timeline';

    // 加载 WebView 话题详情页开关
    final useWebViewConversation =
        prefs.getBool('use_webview_conversation') ?? false;

    await SyncPreferences.migrateFromLegacyIfNeeded();
    final autoSources = await SyncPreferences.getAutoSources();

    final webdavConfig = await WebDavService.loadConfig();

    // 加载本地文件夹配置
    final localFolderConfig = await LocalFolderSyncService.loadConfig();
    final localFolderAutoLoad = await LocalFolderSyncService.getAutoLoad();

    final httpPullPrefs = await LanHttpSyncPullPrefs.load();

    // 加载同步服务器配置
    final serverSyncUrl = await ServerSyncService.getServerUrl();
    final serverSyncToken = await ServerSyncService.getServerToken();
    final serverSyncMode = await ServerSyncService.getSyncMode();
    final serverSyncConflictPolicy =
        await ServerSyncService.getConflictPolicy();

    final webdavConfigured = webdavConfig.isValid;
    final localFolderConfigured = localFolderConfig.folderPath
        .trim()
        .isNotEmpty;
    final httpPullConfigured =
        httpPullPrefs.baseUrl.trim().isNotEmpty &&
        httpPullPrefs.baseUrl.trim() != 'http://';
    final serverSyncConfigured =
        serverSyncUrl.trim().isNotEmpty && serverSyncToken.trim().isNotEmpty;

    LanHttpSyncConfig? lanHttpSyncConfig;
    LanHttpSyncServerStatus lanHttpSyncStatus = const LanHttpSyncStopped();
    if (PlatformUtils.isDesktop) {
      await LanHttpSyncServerService.instance.init();
      lanHttpSyncConfig = LanHttpSyncServerService.instance.config;
      lanHttpSyncStatus = LanHttpSyncServerService.instance.currentStatus;
    }

    // 加载 TTS 设置
    final ttsJson = prefs.getString(TtsSettings.prefKey);
    if (ttsJson != null) {
      _ttsSettings = TtsSettings.fromJson(jsonDecode(ttsJson));
    } else {
      _ttsSettings = TtsSettings();
    }

    if (!mounted) return;
    setState(() {
      _currentViewMode = viewMode;
      _useWebViewConversation = useWebViewConversation;
      _apiUrlController.text = apiUrl;
      _apiKeyController.text = apiKey;
      _modelController.text = model;
      _autoWebDavEnabled = autoSources[SyncSourceType.webdav] ?? false;
      _autoLocalFolderEnabled =
          autoSources[SyncSourceType.localFolder] ?? false;
      _autoLanReceiveEnabled = autoSources[SyncSourceType.lanReceive] ?? false;
      _autoHttpPullEnabled = autoSources[SyncSourceType.httpPull] ?? false;
      _autoServerSyncEnabled = autoSources[SyncSourceType.serverSync] ?? false;
      _webdavUrlController.text = webdavConfig.url;
      _webdavUsernameController.text = webdavConfig.username;
      _webdavPasswordController.text = webdavConfig.password;
      _webdavPathController.text = webdavConfig.path;
      _localFolderPathController.text = localFolderConfig.folderPath;
      _localFolderAutoLoad = localFolderAutoLoad;
      _httpPullBaseUrlController.text = httpPullPrefs.baseUrl;
      _httpPullTokenController.text = httpPullPrefs.token;
      _serverSyncUrlController.text = serverSyncUrl;
      _serverSyncTokenController.text = serverSyncToken;
      _serverSyncMode = serverSyncMode;
      _serverSyncConflictPolicy = serverSyncConflictPolicy;
      _lanHttpSyncConfig = lanHttpSyncConfig;
      _lanHttpSyncStatus = lanHttpSyncStatus;
      _lanHttpSyncPortController.text =
          (lanHttpSyncConfig?.port ?? LanHttpSyncConfig.defaultPort).toString();

      _syncSourceExpanded[SyncSourceType.webdav] =
          (autoSources[SyncSourceType.webdav] ?? false) && !webdavConfigured;
      _syncSourceExpanded[SyncSourceType.localFolder] =
          (autoSources[SyncSourceType.localFolder] ?? false) &&
          !localFolderConfigured;
      _syncSourceExpanded[SyncSourceType.httpPull] =
          (autoSources[SyncSourceType.httpPull] ?? false) &&
          !httpPullConfigured;
      _syncSourceExpanded[SyncSourceType.lanReceive] =
          (autoSources[SyncSourceType.lanReceive] ?? false) == true;
      _syncSourceExpanded[SyncSourceType.serverSync] =
          (autoSources[SyncSourceType.serverSync] ?? false) &&
          !serverSyncConfigured;
      _syncToolExpanded['httpServer'] =
          (lanHttpSyncStatus is LanHttpSyncRunning);

      // Load Azure Keys
      _azureKeyControllers.clear();
      if (_ttsSettings.azureApiKeys.isNotEmpty) {
        for (var key in _ttsSettings.azureApiKeys) {
          _azureKeyControllers.add(TextEditingController(text: key));
        }
      } else if (_ttsSettings.azureApiKey.isNotEmpty) {
        // Migration from single key
        _azureKeyControllers.add(
          TextEditingController(text: _ttsSettings.azureApiKey),
        );
        _ttsSettings.azureApiKeys = [_ttsSettings.azureApiKey];
        _ttsSettings.azureApiKey = ''; // Clear old single key
      } else {
        // Default empty slot
        _azureKeyControllers.add(TextEditingController());
      }

      _azureRegionController.text = _ttsSettings.azureRegion;
      _isLoading = false;
    });

    await _refreshServerSyncConflicts(silent: true);

    if (PlatformUtils.isDesktop) {
      _lanHttpSyncStatusSubscription?.cancel();
      _lanHttpSyncStatusSubscription = LanHttpSyncServerService
          .instance
          .statusStream
          .listen((status) {
            if (!mounted) return;
            setState(() {
              _lanHttpSyncStatus = status;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // ========== 界面设置 ==========
                  _buildSectionHeader(
                    '界面设置',
                    Icons.dashboard_customize_outlined,
                  ),
                  _buildInterfaceSection(),
                  const SizedBox(height: 24),

                  // ========== 数据与同步 ==========
                  _buildSectionHeader('数据与同步', Icons.cloud_sync_outlined),
                  _buildSyncSettingsSection(),
                  const SizedBox(height: 24),

                  // ========== 知识管理 ==========
                  _buildSectionHeader('知识管理', Icons.psychology),
                  _buildPerspectiveManagementSection(),
                  const SizedBox(height: 24),

                  // ========== 智能模型 ==========
                  _buildSectionHeader('智能模型', Icons.auto_awesome),
                  _buildProviderManagementCard(),
                  const SizedBox(height: 12),
                  _buildAIPreferencesCard(),
                  const SizedBox(height: 24),

                  // ========== 语音服务 ==========
                  _buildSectionHeader('语音服务', Icons.record_voice_over),
                  _buildTtsSettingsSection(),
                  const SizedBox(height: 24),

                  // ========== 高级设置 ==========
                  _buildSectionHeader('高级设置', Icons.build),
                  if (PlatformUtils.isDesktop) ...[
                    _buildMCPServerSection(),
                    const SizedBox(height: 12),
                  ],
                  _buildDataManagementSection(),
                  const SizedBox(height: 24),

                  // ========== 关于 ==========
                  _buildSectionHeader('关于', Icons.info_outline),
                  _buildAboutSection(),
                  const SizedBox(height: 12),
                  _buildFeedbackSection(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 MCP Server 设置部分（仅桌面端）
  Widget _buildMCPServerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 启用开关 + 状态
            StreamBuilder<MCPServerStatus>(
              stream: MCPServerService.instance.statusStream,
              initialData: MCPServerService.instance.currentStatus,
              builder: (context, snapshot) {
                final isRunning = snapshot.data?.isRunning ?? false;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'MCP Server',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isRunning
                                      ? Colors.green.withValues(alpha: 26)
                                      : Colors.grey.withValues(alpha: 26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isRunning ? '运行中' : '已停止',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isRunning
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '允许 Claude Code、Cursor 等访问数据',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isRunning,
                      onChanged: (value) async {
                        if (value) {
                          await MCPServerService.instance.start();
                        } else {
                          await MCPServerService.instance.stop();
                        }
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),

            // 自动启动开关
            FutureBuilder<MCPServerConfig>(
              future: MCPServerConfig.load(),
              builder: (context, snapshot) {
                final config = snapshot.data ?? MCPServerConfig.defaults();
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('应用启动时自动开启'),
                  value: config.autoStart,
                  onChanged: (value) async {
                    final newConfig = config.copyWith(
                      autoStart: value,
                      enabled: value,
                    );
                    await MCPServerService.instance.updateConfig(newConfig);
                    setState(() {});
                  },
                );
              },
            ),

            const Divider(),

            // 连接信息（仅运行时显示）
            StreamBuilder<MCPServerStatus>(
              stream: MCPServerService.instance.statusStream,
              initialData: MCPServerService.instance.currentStatus,
              builder: (context, snapshot) {
                final status = snapshot.data;
                if (status == null || !status.isRunning) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '连接信息',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    // 网络地址列表
                    ...status.addresses.map(
                      (addr) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                'http://$addr:${status.port}/mcp',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: 'http://$addr:${status.port}/mcp',
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('地址已复制'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              tooltip: '复制地址',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 配置生成器
                    const Text(
                      'AI 工具配置',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    // 工具选择下拉框
                    _buildConfigGeneratorSection(status),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建配置生成器部分
  Widget _buildConfigGeneratorSection(MCPServerStatus status) {
    AIToolType selectedTool = AIToolType.claudeCode;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<AIToolType>(
              initialValue: selectedTool,
              decoration: const InputDecoration(
                labelText: '选择 AI 工具',
                isDense: true,
              ),
              items: AIToolType.values.map((tool) {
                return DropdownMenuItem(
                  value: tool,
                  child: Text(tool.displayName),
                );
              }).toList(),
              onChanged: (tool) {
                if (tool != null) {
                  setLocalState(() {
                    selectedTool = tool;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    MCPServerService.instance.generateConfig(selectedTool),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: MCPServerService.instance.generateConfig(
                            selectedTool,
                          ),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('配置已复制到剪贴板'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制配置'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建界面设置部分
  Widget _buildInterfaceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('首页视图模式', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'timeline',
                  label: Text('时间线'),
                  icon: Icon(Icons.view_timeline_outlined),
                ),
                ButtonSegment(
                  value: 'tree',
                  label: Text('话题分组'),
                  icon: Icon(Icons.account_tree_outlined),
                ),
              ],
              selected: {_currentViewMode},
              onSelectionChanged: (Set<String> newSelection) async {
                final mode = newSelection.first;
                setState(() => _currentViewMode = mode);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('home_view_mode', mode);
              },
            ),
            const Divider(height: 24),
            // WebView 话题详情页开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '使用 WebView 话题详情页',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '实验性功能：更好的文本选择和高亮体验',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              value: _useWebViewConversation,
              onChanged: (value) async {
                setState(() => _useWebViewConversation = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('use_webview_conversation', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAutoSyncCard(),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Text(
              '同步来源（可多选）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildSyncSourcesCard(),
            if (PlatformUtils.isDesktop) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              const Text(
                '局域网工具',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSyncLanToolsCard(),
            ],
          ],
        ),
      ),
    );
  }

  bool get _webdavConfigValid =>
      _webdavUrlController.text.trim().isNotEmpty &&
      _webdavUsernameController.text.trim().isNotEmpty &&
      _webdavPasswordController.text.trim().isNotEmpty &&
      _webdavPathController.text.trim().isNotEmpty;

  bool get _localFolderConfigValid =>
      _localFolderPathController.text.trim().isNotEmpty;

  bool get _httpPullConfigValid {
    final v = _httpPullBaseUrlController.text.trim();
    return v.isNotEmpty && v != 'http://';
  }

  bool get _serverSyncConfigValid =>
      _serverSyncUrlController.text.trim().isNotEmpty &&
      _serverSyncTokenController.text.trim().isNotEmpty;

  Future<void> _setAutoSource(SyncSourceType type, bool enabled) async {
    // 互斥逻辑：serverSync 与其他同步源互斥
    final isServerSync = type == SyncSourceType.serverSync;
    final otherFileBasedSources = [
      SyncSourceType.webdav,
      SyncSourceType.localFolder,
      SyncSourceType.lanReceive,
      SyncSourceType.httpPull,
    ];

    setState(() {
      switch (type) {
        case SyncSourceType.webdav:
          _autoWebDavEnabled = enabled;
          break;
        case SyncSourceType.localFolder:
          _autoLocalFolderEnabled = enabled;
          break;
        case SyncSourceType.lanReceive:
          _autoLanReceiveEnabled = enabled;
          break;
        case SyncSourceType.httpPull:
          _autoHttpPullEnabled = enabled;
          break;
        case SyncSourceType.serverSync:
          _autoServerSyncEnabled = enabled;
          break;
        case SyncSourceType.manualImport:
          break;
      }

      // 启用 serverSync 时禁用其他源
      if (enabled && isServerSync) {
        _autoWebDavEnabled = false;
        _autoLocalFolderEnabled = false;
        _autoLanReceiveEnabled = false;
        _autoHttpPullEnabled = false;
      }
      // 启用其他源时禁用 serverSync
      if (enabled && !isServerSync && type != SyncSourceType.manualImport) {
        _autoServerSyncEnabled = false;
      }
    });

    await SyncPreferences.setAutoSourceEnabled(type, enabled);

    // 持久化互斥状态
    if (enabled && isServerSync) {
      for (final other in otherFileBasedSources) {
        await SyncPreferences.setAutoSourceEnabled(other, false);
      }
    }
    if (enabled && !isServerSync && type != SyncSourceType.manualImport) {
      await SyncPreferences.setAutoSourceEnabled(
        SyncSourceType.serverSync,
        false,
      );
    }

    if (!mounted) return;
    if (!enabled) return;
    final shouldReveal = switch (type) {
      SyncSourceType.webdav => !_webdavConfigValid,
      SyncSourceType.localFolder => !_localFolderConfigValid,
      SyncSourceType.httpPull => !_httpPullConfigValid,
      SyncSourceType.serverSync => !_serverSyncConfigValid,
      SyncSourceType.lanReceive => true,
      SyncSourceType.manualImport => false,
    };
    if (shouldReveal) {
      setState(() {
        _syncSourceExpanded[type] = true;
      });
    }
  }

  String _buildSourceStatusText({
    required bool enabled,
    required bool configured,
    String? extra,
  }) {
    final parts = <String>[
      enabled ? '已启用' : '未启用',
      configured ? '已配置' : '未配置',
      if (extra != null && extra.trim().isNotEmpty) extra.trim(),
    ];
    return parts.join(' · ');
  }

  Widget _buildPanelActionRow(List<Widget> actions) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 12, runSpacing: 12, children: actions);
  }

  InputDecoration _panelInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  Widget _buildAutoSyncCard() {
    final selected = <String>[];
    if (_autoServerSyncEnabled) selected.add('同步服务器');
    if (_autoLocalFolderEnabled) selected.add('本地文件夹');
    if (_autoWebDavEnabled) selected.add('WebDAV');
    if (_autoHttpPullEnabled) selected.add('HTTP 拉取');
    if (_autoLanReceiveEnabled) selected.add('局域网接收');

    final summary = selected.isEmpty ? '未选择来源' : selected.join(' + ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                '同步',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '应用会自动按已选来源检查并导入“最新版本”；也可以在首页选择 ZIP 手动导入。',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          '来源：$summary',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildSyncSourcesCard() {
    final items = <Widget>[
      _buildSyncSourceItem(
        type: SyncSourceType.serverSync,
        icon: Icons.sync_outlined,
        description: '与自建同步服务器增量双向同步（与其他来源互斥）',
        enabled: _autoServerSyncEnabled,
        configured: _serverSyncConfigValid,
        body: _buildServerSyncConfigCard(),
      ),
      _buildSyncSourceItem(
        type: SyncSourceType.webdav,
        icon: Icons.cloud_sync_outlined,
        description: '从 WebDAV 拉取最新备份',
        enabled: _autoWebDavEnabled,
        configured: _webdavConfigValid,
        body: _buildWebDavConfigCard(),
      ),
      if (PlatformUtils.supportsLocalFolderSync)
        _buildSyncSourceItem(
          type: SyncSourceType.localFolder,
          icon: Icons.folder_copy_outlined,
          description: '监听本地备份目录并导入',
          enabled: _autoLocalFolderEnabled,
          configured: _localFolderConfigValid,
          body: _buildLocalFolderConfigCard(),
        ),
      if (PlatformUtils.isMobile)
        _buildSyncSourceItem(
          type: SyncSourceType.httpPull,
          icon: Icons.download_outlined,
          description: '从桌面端 HTTP 同步源下载最新备份',
          enabled: _autoHttpPullEnabled,
          configured: _httpPullConfigValid,
          body: _buildHttpPullConfigCard(),
        ),
      if (PlatformUtils.isMobile)
        _buildSyncSourceItem(
          type: SyncSourceType.lanReceive,
          icon: Icons.wifi_tethering_outlined,
          description: '接收电脑推送的备份 ZIP',
          enabled: _autoLanReceiveEnabled,
          configured: true,
          body: _buildLanReceiveSourceCard(),
        ),
    ];

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) children.add(const Divider(height: 1));
      children.add(items[i]);
    }

    return Column(children: children);
  }

  Widget _buildSyncLanToolsCard() {
    final items = <Widget>[
      _buildSyncToolItem(
        id: 'httpServer',
        icon: Icons.router_outlined,
        title: 'HTTP 同步源（桌面端）',
        subtitle: () {
          final status = _lanHttpSyncStatus;
          final isRunning = status is LanHttpSyncRunning;
          final port = isRunning
              ? status.port
              : (_lanHttpSyncConfig?.port ?? LanHttpSyncConfig.defaultPort);
          return isRunning ? '运行中：$port' : '未运行';
        }(),
        body: _buildLanHttpSyncServerCard(),
      ),
      _buildSyncToolItem(
        id: 'lanPush',
        icon: Icons.send_outlined,
        title: '局域网推送',
        subtitle: PlatformUtils.isDesktop
            ? '桌面端推送 / HTTP 同步源'
            : '手机端接收 / HTTP 拉取',
        body: _buildLanSyncSection(),
      ),
    ];

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) children.add(const Divider(height: 1));
      children.add(items[i]);
    }

    return Column(children: children);
  }

  Widget _buildSyncSourceItem({
    required SyncSourceType type,
    required IconData icon,
    required String description,
    required bool enabled,
    required bool configured,
    required Widget body,
  }) {
    final expanded = _syncSourceExpanded[type] ?? false;
    final status = _buildSourceStatusText(
      enabled: enabled,
      configured: configured,
    );

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: Checkbox(
            value: enabled,
            onChanged: (v) => _setAutoSource(type, v == true),
          ),
          title: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '$status · $description',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.35,
            ),
          ),
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () {
            setState(() => _syncSourceExpanded[type] = !expanded);
          },
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: body,
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildSyncToolItem({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget body,
  }) {
    final expanded = _syncToolExpanded[id] ?? false;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Icon(icon, color: Colors.grey[700]),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.35,
            ),
          ),
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () {
            setState(() => _syncToolExpanded[id] = !expanded);
          },
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: body,
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Future<void> _saveServerSyncConfig({bool showToast = true}) async {
    await ServerSyncService.saveConfig(
      serverUrl: _serverSyncUrlController.text.trim(),
      token: _serverSyncTokenController.text.trim(),
    );
    await ServerSyncService.saveSyncBehavior(
      mode: _serverSyncMode,
      conflictPolicy: _serverSyncConflictPolicy,
    );
    await _refreshServerSyncConflicts(silent: true);
    if (!showToast || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('同步服务器配置已保存'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _refreshServerSyncConflicts({bool silent = false}) async {
    if (!_serverSyncConfigValid) {
      if (!mounted) return;
      setState(() => _serverSyncPendingConflicts = const []);
      return;
    }

    try {
      final service = ServerSyncService(AppDb());
      final conflicts = await service.getPendingConflicts();
      if (!mounted) return;
      setState(() => _serverSyncPendingConflicts = conflicts);
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _serverSyncTestMessage = '读取冲突列表失败：${e.toString().split('\n').first}';
        });
      }
    }
  }

  Future<void> _clearServerSyncConflicts() async {
    if (_isResolvingServerSyncConflict) return;
    setState(() {
      _isResolvingServerSyncConflict = true;
      _resolvingServerSyncConflictKey = null;
      _serverSyncTestMessage = '正在清空冲突列表...';
    });
    await _saveServerSyncConfig(showToast: false);

    try {
      final service = ServerSyncService(AppDb());
      await service.clearPendingConflicts();
      await _refreshServerSyncConflicts(silent: true);
      if (!mounted) return;
      setState(() {
        _isResolvingServerSyncConflict = false;
        _serverSyncTestMessage = '冲突列表已清空';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResolvingServerSyncConflict = false;
        _serverSyncTestMessage = '清空冲突失败：${e.toString().split('\n').first}';
      });
    }
  }

  Future<void> _resolveServerSyncConflict(
    ServerSyncPendingConflict conflict,
    ServerSyncConflictPolicy policy,
  ) async {
    if (_isResolvingServerSyncConflict) return;
    final key = '${conflict.operation}:${conflict.topicId}';
    setState(() {
      _isResolvingServerSyncConflict = true;
      _resolvingServerSyncConflictKey = key;
      _serverSyncTestMessage = policy == ServerSyncConflictPolicy.localWins
          ? '按本地优先处理冲突中...'
          : '按服务端优先处理冲突中...';
    });
    await _saveServerSyncConfig(showToast: false);

    try {
      final service = ServerSyncService(AppDb());
      final result = await service.resolvePendingConflict(
        conflict: conflict,
        policy: policy,
        onStatus: (msg) {
          if (!mounted) return;
          setState(() => _serverSyncTestMessage = msg);
        },
      );
      await _refreshServerSyncConflicts(silent: true);
      if (!mounted) return;
      setState(() {
        _isResolvingServerSyncConflict = false;
        _resolvingServerSyncConflictKey = null;
        _serverSyncTestMessage = result.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResolvingServerSyncConflict = false;
        _resolvingServerSyncConflictKey = null;
        _serverSyncTestMessage = '处理冲突失败：${e.toString().split('\n').first}';
      });
    }
  }

  String _conflictOperationLabel(String operation) {
    switch (operation) {
      case 'delete':
        return '删除冲突';
      case 'upsert':
      default:
        return '更新冲突';
    }
  }

  String _conflictStatusLabel(String status) {
    switch (status) {
      case 'stale':
        return '本地版本落后';
      case 'conflict':
        return '版本冲突';
      default:
        return status;
    }
  }

  String _conflictReasonLabel(String? reason) {
    if (reason == null || reason.trim().isEmpty) return '未知原因';
    switch (reason) {
      case 'stale':
        return '本地版本落后（可选择本地回写）';
      case 'conflict':
        return '版本冲突（需选择本地/服务端）';
      case 'revision_mismatch':
        return '版本号不匹配';
      case 'topic_not_found_for_expected_revision':
        return '服务端版本已变化（目标不存在）';
      default:
        return reason;
    }
  }

  String _formatConflictTime(int? ms) {
    if (ms == null || ms <= 0) return '-';
    return DateTime.fromMillisecondsSinceEpoch(
      ms,
    ).toLocal().toString().split('.').first;
  }

  Future<void> _testServerSync() async {
    if (_isTestingServerSync) return;
    setState(() {
      _isTestingServerSync = true;
      _serverSyncTestMessage = '测试中...';
    });
    await _saveServerSyncConfig(showToast: false);

    try {
      final url = _serverSyncUrlController.text.trim().replaceAll(
        RegExp(r'/+$'),
        '',
      );
      final token = _serverSyncTokenController.text.trim();
      final resp = await http
          .get(
            Uri.parse(
              '$url/api/sync/changes?cursor=0&limit=1&includePayload=0',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _isTestingServerSync = false;
          _serverSyncTestMessage =
              '连接成功 · 认证通过 · 变更条数 ${data['totalChanges'] ?? 0}';
        });
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        setState(() {
          _isTestingServerSync = false;
          _serverSyncTestMessage = '认证失败：请检查 Token';
        });
      } else {
        setState(() {
          _isTestingServerSync = false;
          _serverSyncTestMessage = '连接失败：HTTP ${resp.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTestingServerSync = false;
        _serverSyncTestMessage = '连接失败：${e.toString().split('\n').first}';
      });
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncingNow) return;
    setState(() {
      _isSyncingNow = true;
      _serverSyncTestMessage = '正在同步...';
    });
    await _saveServerSyncConfig(showToast: false);

    try {
      final service = ServerSyncService(AppDb());
      final result = await service.syncNow(
        onStatus: (msg) {
          if (!mounted) return;
          setState(() => _serverSyncTestMessage = msg);
        },
      );
      await _refreshServerSyncConflicts(silent: true);
      if (!mounted) return;
      setState(() {
        _isSyncingNow = false;
        _serverSyncTestMessage = result.summaryLine;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSyncingNow = false;
        _serverSyncTestMessage = '同步失败：${e.toString().split('\n').first}';
      });
    }
  }

  Widget _buildServerSyncConfigCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '支持增量拉取与推送，可按策略自动处理冲突。启用后其他同步来源将自动关闭。',
                  style: TextStyle(color: Colors.orange[800], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ServerSyncMode>(
          initialValue: _serverSyncMode,
          decoration: _panelInputDecoration(
            labelText: '同步模式',
            prefixIcon: Icons.swap_horiz,
          ),
          items: ServerSyncMode.values
              .map(
                (mode) =>
                    DropdownMenuItem(value: mode, child: Text(mode.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _serverSyncMode = value);
          },
        ),
        if (_serverSyncMode != ServerSyncMode.pullOnly) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<ServerSyncConflictPolicy>(
            initialValue: _serverSyncConflictPolicy,
            decoration: _panelInputDecoration(
              labelText: '冲突策略',
              prefixIcon: Icons.merge_type,
            ),
            items: ServerSyncConflictPolicy.values
                .map(
                  (policy) => DropdownMenuItem(
                    value: policy,
                    child: Text(policy.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _serverSyncConflictPolicy = value);
            },
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _serverSyncUrlController,
          decoration: _panelInputDecoration(
            labelText: '服务器地址',
            hintText: 'http://192.168.1.10:3456',
            prefixIcon: Icons.dns_outlined,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _serverSyncTokenController,
          obscureText: true,
          decoration: _panelInputDecoration(
            labelText: '认证 Token',
            hintText: '同步服务器的 SYNC_TOKEN',
            prefixIcon: Icons.key_outlined,
          ),
        ),
        if (_serverSyncTestMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _serverSyncTestMessage!,
            style: TextStyle(
              fontSize: 12,
              color:
                  _serverSyncTestMessage!.contains('成功') ||
                      _serverSyncTestMessage!.contains('完成')
                  ? Colors.green[700]
                  : _serverSyncTestMessage!.contains('失败')
                  ? Colors.red[700]
                  : Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.red[700],
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '待处理冲突：${_serverSyncPendingConflicts.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[800],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isResolvingServerSyncConflict
                        ? null
                        : () => _refreshServerSyncConflicts(),
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: '刷新冲突列表',
                  ),
                  IconButton(
                    onPressed:
                        _isResolvingServerSyncConflict ||
                            _serverSyncPendingConflicts.isEmpty
                        ? null
                        : _clearServerSyncConflicts,
                    icon: const Icon(Icons.clear_all, size: 18),
                    tooltip: '清空冲突列表',
                  ),
                ],
              ),
              if (_serverSyncPendingConflicts.isEmpty)
                Text(
                  '暂无待手动处理的冲突',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              if (_serverSyncPendingConflicts.isNotEmpty) ...[
                const SizedBox(height: 6),
                ..._serverSyncPendingConflicts.take(8).map((conflict) {
                  final key = '${conflict.operation}:${conflict.topicId}';
                  final busy =
                      _isResolvingServerSyncConflict &&
                      _resolvingServerSyncConflictKey == key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conflict.topicId,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_conflictOperationLabel(conflict.operation)} · ${_conflictStatusLabel(conflict.status)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '原因：${_conflictReasonLabel(conflict.reason)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '发现于 ${_formatConflictTime(conflict.detectedAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '服务端 revision: ${conflict.serverRevision?.toString() ?? '-'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '本地更新时间: ${_formatConflictTime(conflict.localUpdatedAt)} · 服务端更新时间: ${_formatConflictTime(conflict.serverUpdatedAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '服务端客户端时间: ${_formatConflictTime(conflict.serverClientUpdatedAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => _resolveServerSyncConflict(
                                      conflict,
                                      ServerSyncConflictPolicy.serverWins,
                                    ),
                              child: const Text('服务端优先'),
                            ),
                            ElevatedButton(
                              onPressed: busy
                                  ? null
                                  : () => _resolveServerSyncConflict(
                                      conflict,
                                      ServerSyncConflictPolicy.localWins,
                                    ),
                              child: const Text('本地优先回写'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (_serverSyncPendingConflicts.length > 8)
                  Text(
                    '仅展示前 8 条冲突，请先处理后再刷新。',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildPanelActionRow([
          OutlinedButton.icon(
            onPressed: _isTestingServerSync ? null : _testServerSync,
            icon: _isTestingServerSync
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find),
            label: Text(_isTestingServerSync ? '测试中...' : '测试连接'),
          ),
          ElevatedButton.icon(
            onPressed: _saveServerSyncConfig,
            icon: const Icon(Icons.save),
            label: const Text('保存配置'),
          ),
          OutlinedButton.icon(
            onPressed: _isSyncingNow ? null : _syncNow,
            icon: _isSyncingNow
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_isSyncingNow ? '同步中...' : '立即同步'),
          ),
        ]),
      ],
    );
  }

  Widget _buildWebDavConfigCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '用于从 WebDAV 拉取 Cherry Studio 备份文件。',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _webdavUrlController,
          decoration: _panelInputDecoration(
            labelText: 'WebDAV 地址',
            hintText: 'https://example.com/dav/',
            prefixIcon: Icons.link,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _webdavUsernameController,
          decoration: _panelInputDecoration(
            labelText: '用户名',
            prefixIcon: Icons.person,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _webdavPasswordController,
          obscureText: _obscureWebdavPassword,
          decoration: _panelInputDecoration(
            labelText: '密码',
            prefixIcon: Icons.lock,
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
        const SizedBox(height: 12),
        TextFormField(
          controller: _webdavPathController,
          decoration: _panelInputDecoration(
            labelText: '备份文件路径',
            hintText: '/cherry-studio',
            prefixIcon: Icons.folder,
          ),
        ),
        const SizedBox(height: 12),
        _buildPanelActionRow([
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
          ElevatedButton.icon(
            onPressed: _saveWebDavConfig,
            icon: const Icon(Icons.save),
            label: const Text('保存配置'),
          ),
        ]),
      ],
    );
  }

  Widget _buildLocalFolderConfigCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '监听桌面端 Cherry Studio 的备份目录，检测到新备份即可导入。',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cherry Studio：设置 → 数据设置 → 本地备份 → 备份目录',
                  style: TextStyle(color: Colors.blue[800], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _localFolderPathController,
                readOnly: true,
                decoration: _panelInputDecoration(
                  labelText: '备份目录',
                  hintText: '点击右侧按钮选择文件夹',
                  prefixIcon: Icons.folder,
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
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('检测到新版本时自动导入'),
          subtitle: Text(
            '关闭后需在首页手动触发导入',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          value: _localFolderAutoLoad,
          onChanged: (value) async {
            setState(() => _localFolderAutoLoad = value);
            await LocalFolderSyncService.setAutoLoad(value);
          },
        ),
        const SizedBox(height: 12),
        _buildPanelActionRow([
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
          ElevatedButton.icon(
            onPressed: _saveLocalFolderConfig,
            icon: const Icon(Icons.save),
            label: const Text('保存配置'),
          ),
        ]),
      ],
    );
  }

  Future<void> _saveHttpPullPrefs() async {
    await LanHttpSyncPullPrefs.save(
      baseUrl: _httpPullBaseUrlController.text,
      token: _httpPullTokenController.text,
    );
  }

  Future<void> _testHttpPull() async {
    if (_isTestingHttpPull) return;
    setState(() {
      _isTestingHttpPull = true;
      _httpPullTestMessage = '测试中...';
    });
    await _saveHttpPullPrefs();

    final info = await LanHttpSyncPullPrefs.fetchLatestInfo(
      baseUrl: _httpPullBaseUrlController.text,
      token: _httpPullTokenController.text,
    );

    if (!mounted) return;
    setState(() {
      _isTestingHttpPull = false;
      _httpPullTestMessage = info == null
          ? '不可用：请检查地址、令牌、网络'
          : '可用：${info.name} · ${(info.size / 1024 / 1024).toStringAsFixed(1)}MB';
    });
  }

  Future<void> _importHttpPullFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final raw = data?.text ?? '';
    final parsed = LanHttpSyncPullPrefs.parseImportText(raw);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('剪贴板内容不可识别：请复制桌面端“导入串/下载地址”'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _httpPullBaseUrlController.text = parsed.baseUrl;
    _httpPullTokenController.text = parsed.token;
    await _saveHttpPullPrefs();

    if (!mounted) return;
    setState(() => _httpPullTestMessage = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已从剪贴板导入'), duration: Duration(seconds: 2)),
    );
  }

  Widget _buildHttpPullConfigCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '适合不方便用 WebDAV 时：桌面端开启同步源，手机端通过 HTTP 下载最新备份。',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _httpPullBaseUrlController,
          decoration: _panelInputDecoration(
            labelText: '桌面端地址',
            hintText: 'http://192.168.1.10:9531',
            prefixIcon: Icons.link,
          ),
          onChanged: (_) => _saveHttpPullPrefs(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _httpPullTokenController,
          decoration: _panelInputDecoration(
            labelText: '令牌（可选）',
            prefixIcon: Icons.key,
          ),
          onChanged: (_) => _saveHttpPullPrefs(),
        ),
        const SizedBox(height: 12),
        _buildPanelActionRow([
          OutlinedButton.icon(
            onPressed: _importHttpPullFromClipboard,
            icon: const Icon(Icons.content_paste),
            label: const Text('从剪贴板导入'),
          ),
          OutlinedButton.icon(
            onPressed: _isTestingHttpPull ? null : _testHttpPull,
            icon: _isTestingHttpPull
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find),
            label: Text(_isTestingHttpPull ? '测试中...' : '测试连接'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await _saveHttpPullPrefs();
              if (!mounted) return;
              await Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanHttpSyncPullScreen(),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('打开下载页'),
          ),
        ]),
        if (_httpPullTestMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _httpPullTestMessage!,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ],
    );
  }

  Widget _buildLanReceiveSourceCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '电脑端可扫描并推送备份 ZIP 到手机；手机端需要打开接收页。',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
        ),
        const SizedBox(height: 12),
        _buildPanelActionRow([
          OutlinedButton.icon(
            onPressed: () async {
              final received = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanTransferReceiveScreen(),
                ),
              );
              if (!mounted) return;
              if (received == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 已接收备份文件，返回首页后点右上角“同步”导入'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pop();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('保持接收页打开，发送完成后返回首页可导入（右上角“同步”）'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.wifi_tethering_outlined),
            label: const Text('打开接收页'),
          ),
        ]),
      ],
    );
  }

  Future<void> _applyLanHttpSyncConfig(LanHttpSyncConfig next) async {
    await LanHttpSyncServerService.instance.updateConfig(next);
    if (!PlatformUtils.isDesktop) return;

    if (!next.enabled) {
      await LanHttpSyncServerService.instance.stop();
      return;
    }
    if (LanHttpSyncServerService.instance.currentStatus is LanHttpSyncRunning) {
      await LanHttpSyncServerService.instance.restart(port: next.port);
    } else {
      await LanHttpSyncServerService.instance.start(port: next.port);
    }
  }

  Widget _buildLanHttpSyncServerCard() {
    final cfg = _lanHttpSyncConfig;
    final status = _lanHttpSyncStatus;
    final isRunning = status is LanHttpSyncRunning;
    final enabled = cfg?.enabled ?? false;
    final addresses = isRunning ? status.addresses : const <String>[];
    final port = isRunning
        ? status.port
        : (cfg?.port ?? LanHttpSyncConfig.defaultPort);
    final token = cfg?.token ?? '';
    final preferredAddress = addresses.isEmpty
        ? null
        : addresses.firstWhere(
            (e) => !(e.startsWith('127.') || e == 'localhost'),
            orElse: () => addresses.first,
          );
    final preferredBaseUrl = preferredAddress == null
        ? ''
        : 'http://$preferredAddress:$port';
    final importText = preferredBaseUrl.isEmpty
        ? ''
        : LanHttpSyncPullPrefs.buildImportString(
            baseUrl: preferredBaseUrl,
            token: token,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('运行 HTTP 同步源'),
          subtitle: Text(
            !enabled
                ? '已关闭'
                : (status is LanHttpSyncRunning)
                ? '运行中：$port'
                : (status is LanHttpSyncError)
                ? '启动失败：${status.message}'
                : '启动中...',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          value: enabled,
          onChanged: (value) async {
            final current = _lanHttpSyncConfig ?? LanHttpSyncConfig.defaults();
            final next = current.copyWith(enabled: value, autoStart: value);
            setState(() => _lanHttpSyncConfig = next);
            await _applyLanHttpSyncConfig(next);
          },
        ),
        Text(
          '打开开关即启动 HTTP 服务；手机端可通过「HTTP 拉取」下载最新备份。',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
        ),
        const SizedBox(height: 12),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lanHttpSyncPortController,
                decoration: _panelInputDecoration(
                  labelText: '端口',
                  prefixIcon: Icons.numbers,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                final raw = _lanHttpSyncPortController.text.trim();
                final nextPort = int.tryParse(raw);
                if (nextPort == null || nextPort <= 0 || nextPort > 65535)
                  return;
                final current =
                    _lanHttpSyncConfig ?? LanHttpSyncConfig.defaults();
                final next = current.copyWith(port: nextPort);
                setState(() => _lanHttpSyncConfig = next);
                await _applyLanHttpSyncConfig(next);
              },
              child: const Text('保存端口'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          token.isEmpty ? '令牌：无' : '令牌：$token',
          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        _buildPanelActionRow([
          OutlinedButton.icon(
            onPressed: token.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: token));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制令牌'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
            icon: const Icon(Icons.copy),
            label: const Text('复制令牌'),
          ),
          TextButton.icon(
            onPressed: () async {
              final current =
                  _lanHttpSyncConfig ?? LanHttpSyncConfig.defaults();
              final next = current.copyWith(
                token: LanHttpSyncConfig.generateToken(),
              );
              setState(() => _lanHttpSyncConfig = next);
              await _applyLanHttpSyncConfig(next);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重置令牌'),
          ),
        ]),
        if (addresses.isNotEmpty) ...[
          const Divider(height: 24),
          Text(
            '当前 URL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  preferredBaseUrl,
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              ),
              IconButton(
                onPressed: preferredBaseUrl.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: preferredBaseUrl),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已复制 URL'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                icon: const Icon(Icons.copy),
                tooltip: '复制',
              ),
            ],
          ),
          if (importText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '导入串（复制到手机端「HTTP 拉取」即可一键导入）',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    importText,
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: importText));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制导入串'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: '复制',
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '下载地址',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...addresses.map((addr) {
            final url = 'http://$addr:$port/lan-sync/latest.zip';
            final withToken = token.isEmpty ? url : '$url?token=$token';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      withToken,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: withToken));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已复制下载地址'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: '复制',
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildLanSyncSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PlatformUtils.isDesktop
              ? '桌面端可扫描手机并推送备份；手机端需要打开接收页。'
              : '手机端需要保持接收页打开，电脑端才能发现并发送备份。',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
        ),
        const SizedBox(height: 12),
        if (PlatformUtils.isMobile) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wifi_tethering_outlined),
            title: const Text('手机端：打开接收页'),
            subtitle: Text(
              '打开后电脑端即可发现并发送备份 ZIP',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final received = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanTransferReceiveScreen(),
                ),
              );
              if (!mounted) return;
              if (received == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 已接收备份文件，返回首页后点右上角“同步”导入'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pop();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('保持接收页打开，发送完成后返回首页可导入（右上角“同步”）'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ] else ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.send_outlined),
            title: const Text('桌面端：扫描并推送到手机'),
            subtitle: Text(
              '选择备份来源（WebDAV/本地目录/手动 ZIP）→ 推送到手机',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanTransferSendScreen(),
                ),
              );
            },
          ),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wifi_tethering_outlined),
            title: const Text('移动端：需要打开接收页'),
            subtitle: Text(
              '在手机上：设置 → 数据与同步 → 局域网同步工具 → 手机端：打开接收页',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: const Icon(Icons.info_outline),
            onTap: null,
          ),
        ],
      ],
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

    final (success, message) = await LocalFolderSyncService.validateFolder(
      path,
    );

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
      child: Column(
        children: [
          // 数据统计
          _buildDataStatisticsTile(),
          const Divider(height: 1),
          // 导出数据
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.green),
            title: const Text('导出数据'),
            subtitle: Text(
              '导出为 Cherry Studio 兼容格式',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: _showExportDialog,
          ),
          const Divider(height: 1),
          // 清除缓存
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.orange),
            title: const Text('清除缓存'),
            subtitle: Text(
              '保留数据文件，仅清除解析缓存',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清除缓存'),
                  content: const Text('下次启动时会重新解析数据文件'),
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
                      content: Text('缓存已清除'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
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
          subtitle: Text(
            isLoading
                ? '加载中...'
                : '${stats!['assistants']} 助手 · ${stats['topics']} 话题 · ${stats['messages']} 消息',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        );
      },
    );
  }

  /// 获取数据统计
  Future<Map<String, int>> _getDataStatistics() async {
    try {
      final db = AppDb();
      await db.init();
      final sql = db.importDb;

      final assistantsCount =
          (await sql
                  .customSelect('SELECT COUNT(*) AS c FROM assistants')
                  .getSingle())
              .read<int>('c');
      final topicsCount =
          (await sql
                  .customSelect('SELECT COUNT(*) AS c FROM topics')
                  .getSingle())
              .read<int>('c');
      final messagesCount =
          (await sql
                  .customSelect('SELECT COUNT(*) AS c FROM messages')
                  .getSingle())
              .read<int>('c');
      final blocksCount =
          (await sql
                  .customSelect('SELECT COUNT(*) AS c FROM message_blocks')
                  .getSingle())
              .read<int>('c');

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
                  Text(
                    '📊 数据概览',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${stats['assistants']} 个助手',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '• ${stats['topics']} 个话题',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '• ${stats['messages']} 条消息',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '• ${stats['blocks']} 个消息块',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportAsZip();
            },
            icon: const Icon(Icons.folder_zip, size: 18),
            label: const Text('导出 ZIP'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

      final db = AppDb();
      await db.init();
      final exportService = CherryExportService(db);

      // 让用户选择保存位置
      final fileName =
          'cherry-studio-export-${DateTime.now().millisecondsSinceEpoch}.zip';

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
          SnackBar(content: Text('❌ 导出失败: $e'), backgroundColor: Colors.red),
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

      final db = AppDb();
      await db.init();
      final exportService = CherryExportService(db);

      // 让用户选择保存位置
      final fileName =
          'cherry-studio-export-${DateTime.now().millisecondsSinceEpoch}.json';

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
          SnackBar(content: Text('❌ 导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 构建关于与帮助部分
  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('新手引导'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('重新查看引导'),
                  content: const Text('将返回引导页面重新配置'),
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

              if (confirmed != true || !mounted) return;
              await OnboardingScreen.resetOnboarding();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于 Cherry Reader'),
            trailing: const Icon(Icons.chevron_right, size: 18),
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
                children: const [Text('Cherry Studio 对话的阅读器与知识管理工具')],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建反馈部分
  Widget _buildFeedbackSection() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.email_outlined),
        title: const Text('反馈建议'),
        subtitle: Text(
          'jimmyhe66@gmail.com',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: _sendFeedbackEmail,
      ),
    );
  }

  Future<void> _sendFeedbackEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jimmyhe66@gmail.com',
      queryParameters: {'subject': 'Cherry Viewer 反馈与建议'},
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法打开邮件客户端')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开邮件客户端: $e')));
      }
    }
  }

  /// 构建 TTS 设置部分
  Widget _buildTtsSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Azure 配置链接
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(
                  'https://portal.azure.com/#create/Microsoft.CognitiveServicesSpeechServices',
                ),
              ),
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
              onChanged: (_) => _onTtsSettingsChanged(),
            ),
            const SizedBox(height: 16),

            // Azure Keys List
            const Text(
              'Azure Subscription Keys',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                          labelText:
                              'Key ${index + 1}${isCurrent ? " (当前使用)" : ""}',
                          hintText: 'Enter Key',
                          prefixIcon: Icon(
                            Icons.vpn_key,
                            color: isCurrent ? Colors.green : null,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _onTtsSettingsChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_azureKeyControllers.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeApiKey(index),
                        tooltip: '删除 Key',
                      ),
                  ],
                ),
              );
            }),

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

            if (_availableVoices.isNotEmpty ||
                _ttsSettings.defaultVoiceName.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('默认发音人'),
                subtitle: Text(
                  _ttsSettings.defaultVoiceName.isNotEmpty
                      ? (_availableVoices.isNotEmpty
                            ? _availableVoices.firstWhere(
                                    (v) =>
                                        v['shortName'] ==
                                        _ttsSettings.defaultVoiceName,
                                    orElse: () => {
                                      'localName':
                                          _ttsSettings
                                              .defaultVoiceLocalName
                                              .isNotEmpty
                                          ? _ttsSettings.defaultVoiceLocalName
                                          : '未知语音 (${_ttsSettings.defaultVoiceName})',
                                      'shortName': '',
                                    },
                                  )['localName']
                                  as String
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
                      await prefs.setString(
                        TtsSettings.prefKey,
                        jsonEncode(_ttsSettings.toJson()),
                      );
                      // 通知 TtsProvider
                      if (mounted) {
                        final ttsProvider = Provider.of<TtsProvider>(
                          context,
                          listen: false,
                        );
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
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('语音缓存已清除')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先输入 Region 和至少一个 Key')));
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
      final chineseVoices = voices
          .where((v) => v['locale']?.startsWith('zh') ?? false)
          .toList();
      final otherVoices = voices
          .where((v) => !(v['locale']?.startsWith('zh') ?? false))
          .toList();

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
      await prefs.setString(
        TtsSettings.prefKey,
        jsonEncode(_ttsSettings.toJson()),
      );

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
    if (!mounted) return;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先配置 Azure TTS')));
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
      if (!mounted) return;
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
            final matchesSearch =
                searchQuery.isEmpty ||
                (voice['localName']?.toString().toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                (voice['shortName']?.toString().toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ??
                    false);

            final matchesLocale =
                selectedLocale == 'all' ||
                (voice['locale']?.toString().startsWith(selectedLocale ?? '') ??
                    false);

            return matchesSearch && matchesLocale;
          }).toList();

          // 2. 分离收藏和非收藏
          final favoriteItems = <Map<String, String>>[];
          final otherItems = <Map<String, String>>[];

          // 按收藏顺序添加
          for (var shortName in _ttsSettings.favoriteVoices) {
            // 只有在过滤结果中存在的才显示
            try {
              final voice = filteredVoices.firstWhere(
                (v) => v['shortName'] == shortName,
              );
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
                              if (selected)
                                setDialogState(() => selectedLocale = 'all');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('中文'),
                            selected: selectedLocale == 'zh',
                            onSelected: (selected) {
                              if (selected)
                                setDialogState(() => selectedLocale = 'zh');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('英语'),
                            selected: selectedLocale == 'en',
                            onSelected: (selected) {
                              if (selected)
                                setDialogState(() => selectedLocale = 'en');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('日语'),
                            selected: selectedLocale == 'ja',
                            onSelected: (selected) {
                              if (selected)
                                setDialogState(() => selectedLocale = 'ja');
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: Text(
                              '已收藏 (长按拖拽排序)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
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
                              _ttsSettings.favoriteVoices.insert(
                                newIndex,
                                shortName,
                              );

                              setDialogState(() {});
                            },
                            itemBuilder: (context, index) {
                              final voice = favoriteItems[index];
                              return _buildVoiceTile(
                                voice,
                                true,
                                setDialogState,
                                Key(voice['shortName']!),
                              );
                            },
                          ),
                          const Divider(),
                        ],

                        // 其他部分
                        if (otherItems.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: Text(
                              '所有语音',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...otherItems.map(
                            (voice) => _buildVoiceTile(
                              voice,
                              false,
                              setDialogState,
                              null,
                            ),
                          ),
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

  Widget _buildVoiceTile(
    Map<String, String> voice,
    bool isFavorite,
    StateSetter setDialogState,
    Key? key,
  ) {
    final shortName = voice['shortName']!;
    final localName = voice['localName']!;
    final locale = voice['locale'];
    final isSelected = shortName == _ttsSettings.defaultVoiceName;
    final isPreviewing =
        _isPreviewingVoice && _previewingVoiceName == shortName;

    return ListTile(
      key: key,
      selected: isSelected,
      leading: IconButton(
        icon: Icon(
          isPreviewing ? Icons.stop_circle : Icons.play_circle_outline,
        ),
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
          if (isSelected) Icon(Icons.check_circle, color: Colors.blue[300]),
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
      child: FutureBuilder<UserPreferenceEntity?>(
        future: PromptTemplateService.instance.getActivePreference(),
        builder: (context, snapshot) {
          final pref = snapshot.data;
          return ListTile(
            leading: Icon(Icons.tune, color: Colors.purple[300]),
            title: Text(pref?.name ?? '默认偏好'),
            subtitle: Text(
              pref?.systemPrompt.isNotEmpty == true
                  ? pref!.systemPrompt.split('\n').first
                  : '配置全局 System Prompt',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPreferenceEditor(pref),
          );
        },
      ),
    );
  }

  /// 显示偏好编辑器
  void _showPreferenceEditor(UserPreferenceEntity? preference) async {
    // 如果没有偏好，先获取
    preference ??= await PromptTemplateService.instance.getActivePreference();

    final nameController = TextEditingController(
      text: preference?.name ?? '默认偏好',
    );
    final contentController = TextEditingController(
      text: preference?.systemPrompt ?? '',
    );

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
                await PromptTemplateService.instance.updatePreference(
                  preference,
                );
              } else {
                await PromptTemplateService.instance.createPreference(
                  name: name,
                  systemPrompt: content,
                  setActive: true,
                );
              }

              if (!mounted) return;
              Navigator.of(this.context).pop();
              setState(() {}); // 刷新界面

              ScaffoldMessenger.of(this.context).showSnackBar(
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
      child: ListTile(
        leading: Icon(
          hasProviders ? Icons.check_circle : Icons.cloud_outlined,
          color: hasProviders ? Colors.green : Colors.grey,
        ),
        title: Text(
          hasProviders
              ? '${activeProvider?.name ?? "未选择"} / ${activeModel?.displayName ?? "未选择"}'
              : '配置 AI Provider',
        ),
        subtitle: Text(
          hasProviders
              ? '${providerService.validProviders.length} 个可用'
              : '从 Cherry Studio 导入或手动添加',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIProviderScreen()),
          ).then((_) => setState(() {}));
        },
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
        await prefs.setString(
          TtsSettings.prefKey,
          jsonEncode(_ttsSettings.toJson()),
        );
        // 通知 TtsProvider
        if (mounted) {
          final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
          await ttsProvider.reloadSettings();
          if (!mounted) return;
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

  /// 构建洞察视角管理区域
  Widget _buildPerspectiveManagementSection() {
    return FutureBuilder<List<PerspectiveEntity>>(
      future: InsightService.instance.getAllPerspectives(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final perspectives = snapshot.data!;
        // 按 sortOrder 排序
        perspectives.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        // 只需要自定义视角
        final customPerspectives = perspectives
            .where((p) => !p.isBuiltin)
            .toList();

        // 按分组组织自定义视角
        final customGrouped = <String, List<PerspectiveEntity>>{};
        for (final p in customPerspectives) {
          customGrouped.putIfAbsent(p.category, () => []).add(p);
        }

        // 内置分组顺序（用于判断自定义视角是否归类到内置分组）
        const builtinCategoryOrder = [
          BuiltinPerspectives.categoryReview,
          BuiltinPerspectives.categorySelf,
          BuiltinPerspectives.categoryThinking,
          BuiltinPerspectives.categoryMaster,
        ];

        // 自定义分组顺序（排除内置分组后按字母排序）
        final customCategoryOrder =
            customGrouped.keys
                .where((c) => !builtinCategoryOrder.contains(c))
                .toList()
              ..sort();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 自定义视角标题
                Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    const Text(
                      '自定义视角',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showPerspectiveEditor(null),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '创建自己的分析视角和 Prompt 模板',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 12),

                if (customPerspectives.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '点击“添加”创建你的第一个视角',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // 按自定义分组展示
                  for (final category in customCategoryOrder) ...[
                    _buildCustomCategoryHeader(
                      category,
                      customGrouped[category]!.length,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: customGrouped[category]!
                          .map((p) => _buildCustomPerspectiveChip(p))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // 归类到内置分组的自定义视角
                  for (final category in builtinCategoryOrder) ...[
                    if (customGrouped.containsKey(category)) ...[
                      _buildCustomCategoryHeader(
                        category,
                        customGrouped[category]!.length,
                        isBuiltinCategory: true,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: customGrouped[category]!
                            .map((p) => _buildCustomPerspectiveChip(p))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建自定义分组标题
  Widget _buildCustomCategoryHeader(
    String category,
    int perspectiveCount, {
    bool isBuiltinCategory = false,
  }) {
    // 如果是内置分组，使用内置配色
    final name = isBuiltinCategory
        ? BuiltinPerspectives.categoryNames[category] ?? category
        : category;
    final icon = isBuiltinCategory
        ? BuiltinPerspectives.categoryIcons[category] ?? '📌'
        : '📌';
    final color = isBuiltinCategory
        ? BuiltinPerspectives.categoryColors[category] ?? Colors.teal
        : Colors.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$perspectiveCount',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  /// 构建自定义视角 Chip
  Widget _buildCustomPerspectiveChip(PerspectiveEntity perspective) {
    return GestureDetector(
      onLongPress: () => _showPerspectiveEditor(perspective),
      child: Tooltip(
        message: '${perspective.description}\n长按编辑',
        child: InputChip(
          avatar: Text(perspective.icon, style: const TextStyle(fontSize: 14)),
          label: Text(
            perspective.name,
            style: TextStyle(
              fontSize: 12,
              color: perspective.isEnabled ? Colors.white : null,
            ),
          ),
          selected: perspective.isEnabled,
          selectedColor: Colors.blue,
          checkmarkColor: Colors.white,
          onSelected: (selected) async {
            await InsightService.instance.togglePerspectiveEnabled(
              perspective.perspectiveId,
              selected,
            );
            setState(() {}); // 刷新列表
          },
          onDeleted: () => _confirmDeletePerspective(perspective),
          deleteIconColor: perspective.isEnabled ? Colors.white70 : Colors.grey,
        ),
      ),
    );
  }

  /// 确认删除视角
  Future<void> _confirmDeletePerspective(PerspectiveEntity perspective) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(perspective.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('删除「${perspective.name}」'),
          ],
        ),
        content: const Text('确定要删除这个自定义视角吗？\n此操作不可撤销。'),
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

    if (confirmed == true) {
      final success = await InsightService.instance.deleteCustomPerspective(
        perspective.perspectiveId,
      );

      if (mounted) {
        if (success) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除「${perspective.name}」'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// 显示视角编辑对话框
  Future<void> _showPerspectiveEditor(PerspectiveEntity? perspective) async {
    final isEditing = perspective != null;

    final nameController = TextEditingController(text: perspective?.name ?? '');
    final iconController = TextEditingController(
      text: perspective?.icon ?? '🔍',
    );
    final descController = TextEditingController(
      text: perspective?.description ?? '',
    );
    final promptController = TextEditingController(
      text: perspective?.promptTemplate ?? _defaultPromptTemplate,
    );
    final customCategoryController = TextEditingController();

    // 初始化分组选择
    String selectedCategory = perspective?.category ?? '';
    bool isCustomCategory =
        perspective != null &&
        !BuiltinPerspectives.categoryOrder.contains(perspective.category);
    if (isCustomCategory) {
      customCategoryController.text = perspective.category;
    }

    // 获取现有的自定义分组
    final existingCustomCategories = await InsightService.instance
        .getCustomCategories();

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit : Icons.add_circle_outline),
              const SizedBox(width: 8),
              Text(isEditing ? '编辑视角' : '添加自定义视角'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息行
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图标
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: iconController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                          decoration: const InputDecoration(
                            labelText: '图标',
                            hintText: '🔍',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 名称
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '视角名称',
                            hintText: '例如：批判思维',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 分组选择
                  Row(
                    children: [
                      const Text(
                        '分组',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '可选择现有分组或输入新分组',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 内置分组选项
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...BuiltinPerspectives.categoryOrder.map((category) {
                        final isSelected =
                            !isCustomCategory && selectedCategory == category;
                        final name =
                            BuiltinPerspectives.categoryNames[category] ??
                            category;
                        final icon =
                            BuiltinPerspectives.categoryIcons[category] ?? '📁';
                        return ChoiceChip(
                          avatar: Text(
                            icon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          label: Text(name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                selectedCategory = category;
                                isCustomCategory = false;
                                customCategoryController.clear();
                              });
                            }
                          },
                        );
                      }),
                      // 现有自定义分组
                      ...existingCustomCategories.map((category) {
                        final isSelected =
                            isCustomCategory && selectedCategory == category;
                        return ChoiceChip(
                          avatar: const Text(
                            '📌',
                            style: TextStyle(fontSize: 12),
                          ),
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: Colors.teal.withValues(alpha: 0.2),
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                selectedCategory = category;
                                isCustomCategory = true;
                                customCategoryController.text = category;
                              });
                            }
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 自定义分组输入
                  TextField(
                    controller: customCategoryController,
                    decoration: InputDecoration(
                      labelText: '自定义分组',
                      hintText: '输入新的分组名称...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.add, size: 18),
                      suffixIcon: customCategoryController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setDialogState(() {
                                  customCategoryController.clear();
                                  isCustomCategory = false;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value.trim().isNotEmpty) {
                          selectedCategory = value.trim();
                          isCustomCategory = true;
                        } else {
                          isCustomCategory = false;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 描述
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: '简短描述',
                      hintText: '例如：用批判性思维审视你的想法',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Prompt 模板
                  const Text(
                    'Prompt 模板',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使用 {queries} 作为用户提问列表的占位符',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: promptController,
                    decoration: const InputDecoration(
                      hintText: '请分析以下提问...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 12,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final icon = iconController.text.trim();
                final desc = descController.text.trim();
                final prompt = promptController.text.trim();
                final category = isCustomCategory
                    ? customCategoryController.text.trim()
                    : selectedCategory;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请输入视角名称')));
                  return;
                }

                if (category.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请选择或输入分组名称')));
                  return;
                }

                if (!prompt.contains('{queries}')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prompt 模板必须包含 {queries} 占位符'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'name': name,
                  'icon': icon.isEmpty ? '🔍' : icon,
                  'description': desc,
                  'promptTemplate': prompt,
                  'category': category,
                });
              },
              child: Text(isEditing ? '保存' : '创建'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      if (isEditing) {
        // 更新现有视角
        perspective.name = result['name'];
        perspective.icon = result['icon'];
        perspective.description = result['description'];
        perspective.promptTemplate = result['promptTemplate'];
        perspective.category = result['category'];
        perspective.updatedAt = DateTime.now().millisecondsSinceEpoch;

        await InsightService.instance.updateCustomPerspective(perspective);

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已更新「${result['name']}」'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 创建新视角
        final newPerspective = PerspectiveEntity.create(
          perspectiveId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: result['name'],
          icon: result['icon'],
          description: result['description'],
          promptTemplate: result['promptTemplate'],
          isBuiltin: false,
          sortOrder: 200, // 自定义视角排在内置视角后面
          isEnabled: true,
          category: result['category'],
        );

        await InsightService.instance.addCustomPerspective(newPerspective);

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已创建「${result['name']}」'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  /// 默认 Prompt 模板
  static const String _defaultPromptTemplate = '''你是一位专业的分析师。请分析以下用户提问。

用户提问列表：
{queries}

请从以下角度分析：

## 一、问题识别
识别用户提问中的核心问题和关注点。

## 二、深入分析
对这些问题进行深入分析。

## 三、建议
给出具体的建议。

用第二人称"你"来表述，语气温和但有洞察力。''';
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
