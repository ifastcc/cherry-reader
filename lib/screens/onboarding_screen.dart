import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/webdav_service.dart';
import '../services/local_folder_sync_service.dart';
import '../services/sync/sync_preferences.dart';
import '../utils/platform_utils.dart';

/// 首次启动引导页面
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  /// 检查是否需要显示引导
  ///
  /// 不显示引导的情况：
  /// 1. 已完成过引导（onboarding_completed = true）
  /// 2. 老用户：已有有效的 WebDAV 配置
  /// 3. 老用户：已有本地数据文件
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 已完成过引导
    if (prefs.getBool('onboarding_completed') ?? false) {
      return false;
    }

    // 2. 检查是否有有效的 WebDAV 配置（老用户）
    final webdavConfig = await WebDavService.loadConfig();
    if (webdavConfig.isValid) {
      // 老用户已有配置，自动标记引导完成
      await markOnboardingComplete();
      return false;
    }

    // 3. 检查是否有本地数据文件（老用户手动导入过）
    final lastFile = prefs.getString('last_file_path');
    if (lastFile != null && lastFile.isNotEmpty) {
      await markOnboardingComplete();
      return false;
    }

    // 新用户，显示引导
    return true;
  }

  /// 标记引导已完成
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  /// 重置引导状态（用于"重新查看引导"）
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 用户选择的数据加载模式
  DataLoadMode? _selectedMode;

  // WebDAV 配置控制器
  final _webdavUrlController = TextEditingController();
  final _webdavUsernameController = TextEditingController();
  final _webdavPasswordController = TextEditingController();
  final _webdavPathController = TextEditingController(text: '/cherry-studio');
  bool _obscurePassword = true;
  bool _isTestingConnection = false;
  bool _connectionTestPassed = false;

  // 本地文件夹配置控制器
  final _localFolderPathController = TextEditingController();
  bool _isValidatingFolder = false;
  bool _localFolderValidated = false;

  @override
  void dispose() {
    _pageController.dispose();
    _webdavUrlController.dispose();
    _webdavUsernameController.dispose();
    _webdavPasswordController.dispose();
    _webdavPathController.dispose();
    _localFolderPathController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _getTotalPages() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getTotalPages() {
    // 如果选择了 WebDAV 模式，多一个配置页
    if (_selectedMode == DataLoadMode.webdav) {
      return 4; // 欢迎 + 原理 + 选择模式 + WebDAV配置
    }
    // 如果选择了本地文件夹模式，也多一个配置页
    if (_selectedMode == DataLoadMode.localFolder) {
      return 4; // 欢迎 + 原理 + 选择模式 + 本地文件夹配置
    }
    return 3; // 欢迎 + 原理 + 选择模式
  }

  Future<void> _completeOnboarding() async {
    // 保存用户选择的模式
    if (_selectedMode != null) {
      await WebDavService.setLoadMode(_selectedMode!);
      await SyncPreferences.applyLegacyChoice(_selectedMode!);

      // 如果选择了 WebDAV，保存配置
      if (_selectedMode == DataLoadMode.webdav) {
        final config = WebDavConfig(
          url: _webdavUrlController.text.trim(),
          username: _webdavUsernameController.text.trim(),
          password: _webdavPasswordController.text.trim(),
          path: _webdavPathController.text.trim(),
        );
        await WebDavService.saveConfig(config);
      }

      // 如果选择了本地文件夹，保存配置
      if (_selectedMode == DataLoadMode.localFolder) {
        final config = LocalFolderConfig(
          folderPath: _localFolderPathController.text.trim(),
        );
        await LocalFolderSyncService.saveConfig(config);
      }
    }

    await OnboardingScreen.markOnboardingComplete();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestPassed = false;
    });

    final config = WebDavConfig(
      url: _webdavUrlController.text.trim(),
      username: _webdavUsernameController.text.trim(),
      password: _webdavPasswordController.text.trim(),
      path: _webdavPathController.text.trim(),
    );

    final (success, message) = await WebDavService.testConnection(config);

    setState(() {
      _isTestingConnection = false;
      _connectionTestPassed = success;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '连接成功' : '连接失败: $message'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 进度指示器
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(_getTotalPages(), (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 页面内容
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 禁止滑动，通过按钮导航
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildHowItWorksPage(),
                  _buildChooseModePage(),
                  if (_selectedMode == DataLoadMode.webdav) _buildWebDavConfigPage(),
                  if (_selectedMode == DataLoadMode.localFolder) _buildLocalFolderConfigPage(),
                ],
              ),
            ),

            // 底部导航按钮
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  /// 欢迎页
  Widget _buildWelcomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用高度动态调整间距
        final availableHeight = constraints.maxHeight;
        final isCompact = availableHeight < 600;
        final logoSize = isCompact ? 80.0 : 120.0;
        final titleSize = isCompact ? 28.0 : 32.0;
        final spacing = isCompact ? 16.0 : 32.0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 32,
            vertical: isCompact ? 16 : 32,
          ),
          child: Column(
            children: [
              // 上部弹性空间
              const Flexible(flex: 1, child: SizedBox()),

              // Logo / 图标
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(logoSize * 0.23),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: logoSize * 0.47,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: spacing),

              // 标题
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Cherry Reader',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        fontSize: titleSize,
                      ),
                ),
              ),

              SizedBox(height: isCompact ? 8 : 16),

              // 副标题
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '优雅地阅读你的 AI 对话',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),

              SizedBox(height: spacing * 1.5),

              // 特性列表 - 使用 Flexible 自适应
              Flexible(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFeatureItem(
                      icon: Icons.auto_stories,
                      title: '沉浸式阅读',
                      description: '专为阅读体验优化的界面设计',
                      compact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 8 : 16),
                    _buildFeatureItem(
                      icon: Icons.cloud_sync,
                      title: '自动同步',
                      description: '与 Cherry Studio 无缝连接',
                      compact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 8 : 16),
                    _buildFeatureItem(
                      icon: Icons.record_voice_over,
                      title: '语音朗读',
                      description: '支持 TTS 语音播放功能',
                      compact: isCompact,
                    ),
                  ],
                ),
              ),

              // 下部弹性空间
              const Flexible(flex: 1, child: SizedBox()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    bool compact = false,
  }) {
    final iconSize = compact ? 36.0 : 44.0;

    return Row(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(iconSize * 0.27),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: iconSize * 0.5,
          ),
        ),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 14 : 15,
                ),
              ),
              if (!compact || description.length < 20)
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: compact ? 12 : 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 工作原理页
  Widget _buildHowItWorksPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 550;
        final spacing = isCompact ? 24.0 : 48.0;

        return Padding(
          padding: EdgeInsets.all(isCompact ? 24 : 32),
          child: Column(
            children: [
              const Flexible(flex: 1, child: SizedBox()),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '工作原理',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),

              SizedBox(height: isCompact ? 8 : 12),

              Text(
                '了解数据如何流转',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isCompact ? 14 : 16,
                ),
              ),

              SizedBox(height: spacing),

              // 数据流图示
              Flexible(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFlowStep(
                      step: '1',
                      icon: Icons.chat_bubble_outline,
                      title: 'Cherry Studio',
                      description: '你在 Cherry Studio 中进行 AI 对话',
                      color: Colors.blue,
                      compact: isCompact,
                    ),
                    _buildFlowArrow(compact: isCompact),
                    _buildFlowStep(
                      step: '2',
                      icon: Icons.cloud_upload_outlined,
                      title: '备份到云端',
                      description: 'Cherry Studio 自动备份到 WebDAV',
                      color: Colors.orange,
                      compact: isCompact,
                    ),
                    _buildFlowArrow(compact: isCompact),
                    _buildFlowStep(
                      step: '3',
                      icon: Icons.menu_book_rounded,
                      title: 'Cherry Reader',
                      description: '本应用从 WebDAV 同步并展示',
                      color: Colors.green,
                      compact: isCompact,
                    ),
                  ],
                ),
              ),

              SizedBox(height: isCompact ? 16 : 32),

              // 提示卡片
              Container(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: isCompact ? 20 : 24),
                    SizedBox(width: isCompact ? 8 : 12),
                    Expanded(
                      child: Text(
                        '请确保 Cherry Studio 已开启 WebDAV 自动备份',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Flexible(flex: 1, child: SizedBox()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlowStep({
    required String step,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool compact = false,
  }) {
    final stepSize = compact ? 24.0 : 32.0;
    final iconBoxSize = compact ? 40.0 : 52.0;

    return Row(
      children: [
        // 步骤编号
        Container(
          width: stepSize,
          height: stepSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 12 : 16),
        // 图标
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(iconBoxSize * 0.27),
          ),
          child: Icon(icon, color: color, size: iconBoxSize * 0.5),
        ),
        SizedBox(width: compact ? 12 : 16),
        // 文字
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 14 : 16,
                ),
              ),
              if (!compact) const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: compact ? 11 : 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowArrow({bool compact = false}) {
    return Padding(
      padding: EdgeInsets.only(left: compact ? 11 : 15, top: compact ? 4 : 8, bottom: compact ? 4 : 8),
      child: Row(
        children: [
          Container(
            width: 2,
            height: compact ? 16 : 24,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  /// 选择模式页
  Widget _buildChooseModePage() {
    // 桌面端默认推荐本地文件夹
    final isDesktop = PlatformUtils.supportsLocalFolderSync;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 500;

        return Padding(
          padding: EdgeInsets.all(isCompact ? 24 : 32),
          child: Column(
            children: [
              const Flexible(flex: 1, child: SizedBox()),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '选择数据来源',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),

              SizedBox(height: isCompact ? 8 : 12),

              Text(
                '选择你喜欢的方式获取数据',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isCompact ? 14 : 16,
                ),
              ),

              SizedBox(height: isCompact ? 24 : 48),

              // 桌面端：本地文件夹选项（推荐）
              if (isDesktop) ...[
                _buildModeCard(
                  mode: DataLoadMode.localFolder,
                  icon: Icons.folder_copy,
                  title: '本地文件夹监听',
                  description: '选择 Cherry Studio 备份目录\n自动监听文件变化并加载',
                  isRecommended: true,
                  compact: isCompact,
                ),
                SizedBox(height: isCompact ? 12 : 16),
              ],

              // WebDAV 选项
              _buildModeCard(
                mode: DataLoadMode.webdav,
                icon: Icons.cloud_sync,
                title: 'WebDAV 自动同步',
                description: '配置一次，自动保持同步\n推荐与 Cherry Studio 配合使用',
                isRecommended: !isDesktop, // 移动端推荐
                compact: isCompact,
              ),

              SizedBox(height: isCompact ? 12 : 16),

              // 手动导入选项
              _buildModeCard(
                mode: DataLoadMode.manual,
                icon: Icons.folder_open,
                title: '手动导入文件',
                description: '手动选择 Cherry Studio 导出的\nZIP 或 JSON 文件',
                isRecommended: false,
                compact: isCompact,
              ),

              const Flexible(flex: 2, child: SizedBox()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeCard({
    required DataLoadMode mode,
    required IconData icon,
    required String title,
    required String description,
    required bool isRecommended,
    bool compact = false,
  }) {
    final isSelected = _selectedMode == mode;
    final iconBoxSize = compact ? 44.0 : 56.0;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(compact ? 14 : 20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(iconBoxSize * 0.25),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: iconBoxSize * 0.5,
              ),
            ),
            SizedBox(width: compact ? 12 : 16),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 14 : 16,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 6 : 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '推荐',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    compact ? description.replaceAll('\n', ' ') : description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: compact ? 11 : 13,
                      height: 1.4,
                    ),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            // 选中指示器
            Container(
              width: compact ? 20 : 24,
              height: compact ? 20 : 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: compact ? 12 : 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// WebDAV 配置页
  Widget _buildWebDavConfigPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '配置 WebDAV',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              '填写与 Cherry Studio 相同的配置',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Cherry Studio 配置提示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '配置说明',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '请在 Cherry Studio 中打开：\n设置 → 数据设置 → WebDAV\n\n将相同的配置填写到下方',
                  style: TextStyle(
                    color: Colors.amber[900],
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // WebDAV URL
          const Text(
            'WebDAV 地址',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _webdavUrlController,
            decoration: const InputDecoration(
              hintText: 'https://example.com/dav/',
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 20),

          // 用户名
          const Text(
            '用户名',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _webdavUsernameController,
            decoration: const InputDecoration(
              hintText: '你的用户名',
              prefixIcon: Icon(Icons.person),
            ),
          ),

          const SizedBox(height: 20),

          // 密码
          const Text(
            '密码',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _webdavPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: '你的密码',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 路径
          const Text(
            'WebDAV 路径',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _webdavPathController,
            decoration: const InputDecoration(
              hintText: '/cherry-studio',
              prefixIcon: Icon(Icons.folder),
              helperText: 'Cherry Studio 备份文件所在目录',
            ),
          ),

          const SizedBox(height: 24),

          // 测试连接按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isTestingConnection ? null : _testConnection,
              icon: _isTestingConnection
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _connectionTestPassed
                          ? Icons.check_circle
                          : Icons.wifi_find,
                      color: _connectionTestPassed ? Colors.green : null,
                    ),
              label: Text(
                _isTestingConnection
                    ? '测试中...'
                    : (_connectionTestPassed ? '连接成功' : '测试连接'),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: _connectionTestPassed ? Colors.green : null,
                side: _connectionTestPassed
                    ? const BorderSide(color: Colors.green)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 本地文件夹配置页
  Widget _buildLocalFolderConfigPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '选择备份目录',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              '选择 Cherry Studio 的备份文件夹',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 配置提示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[800], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '如何找到备份目录',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '在 Cherry Studio 中：\n'
                  '设置 → 数据设置 → 本地备份 → 备份目录\n\n'
                  '选择与 Cherry Studio 相同的备份目录即可',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 文件夹选择
          const Text(
            '备份文件夹',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _localFolderPathController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: '点击右侧按钮选择',
                    prefixIcon: Icon(Icons.folder),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _selectLocalFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 验证按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isValidatingFolder ? null : _validateLocalFolder,
              icon: _isValidatingFolder
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _localFolderValidated ? Icons.check_circle : Icons.search,
                      color: _localFolderValidated ? Colors.green : null,
                    ),
              label: Text(
                _isValidatingFolder
                    ? '验证中...'
                    : (_localFolderValidated ? '验证通过' : '验证文件夹'),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: _localFolderValidated ? Colors.green : null,
                side: _localFolderValidated
                    ? const BorderSide(color: Colors.green)
                    : null,
              ),
            ),
          ),
        ],
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
        _localFolderValidated = false; // 重置验证状态
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

    setState(() {
      _isValidatingFolder = true;
      _localFolderValidated = false;
    });

    final (success, message) = await LocalFolderSyncService.validateFolder(path);

    setState(() {
      _isValidatingFolder = false;
      _localFolderValidated = success;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ $message' : '❌ $message'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 底部导航按钮
  Widget _buildBottomNavigation() {
    final isLastPage = _currentPage == _getTotalPages() - 1;
    final canProceed = _currentPage != 2 || _selectedMode != null;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // 返回按钮
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('上一步'),
            )
          else
            const SizedBox(width: 100),

          const Spacer(),

          // 跳过按钮（仅在第一页显示）
          if (_currentPage == 0)
            TextButton(
              onPressed: () async {
                // 设置为手动模式并跳过引导
                await WebDavService.setLoadMode(DataLoadMode.manual);
                await SyncPreferences.applyLegacyChoice(DataLoadMode.manual);
                await OnboardingScreen.markOnboardingComplete();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
              child: Text(
                '跳过',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),

          const SizedBox(width: 8),

          // 下一步/完成按钮
          ElevatedButton(
            onPressed: canProceed
                ? (isLastPage ? _completeOnboarding : _nextPage)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isLastPage ? '开始使用' : '下一步'),
                if (!isLastPage) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
