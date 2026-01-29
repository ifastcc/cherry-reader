import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'no_scrollbar_behavior.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'services/analysis_cache_manager.dart';
import 'services/repository_provider.dart';
import 'services/ai_provider_service.dart';
import 'services/version_service.dart';
import 'services/mcp/mcp_server_service.dart';
import 'services/tts_cache_migration.dart';
import 'services/topic_index_service.dart';
import 'services/webview_pool.dart';
import 'utils/platform_utils.dart';

import 'package:provider/provider.dart';
import 'providers/tts_provider.dart';
import 'providers/webview_navigation_controller.dart';
import 'screens/webview_conversation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  await dotenv.load(fileName: ".env");

  // 初始化 RepositoryProvider（会自动初始化 IsarDatabase）
  // 必须在其他依赖数据库的服务之前初始化
  await RepositoryProvider.init();

  // 初始化版本服务（管理多版本数据库实例）
  // 必须在 RepositoryProvider 之后初始化
  await VersionService.instance.init();

  // 崩溃恢复：清理未完成的导入版本
  await VersionService.instance.recoverFromCrash();

  // 初始化话题索引服务（常驻内存，加速 Context 编辑器）
  // 必须在 RepositoryProvider 之后初始化
  await TopicIndexService.instance.init();

  // 初始化缓存管理器（后续会迁移到 Isar）
  await AnalysisCacheManager().init();

  // 初始化 AI Provider 服务
  await AIProviderService.instance.init();

  // 初始化 MCP Server（仅桌面端）
  if (PlatformUtils.isDesktop) {
    await MCPServerService.instance.init();
  }

  // TTS 缓存迁移检查
  await TtsCacheMigration.migrateIfNeeded();

  // WebView 预热
  // 延迟 500ms 后异步预热，不阻塞应用启动
  Future.delayed(const Duration(milliseconds: 500), () {
    WebViewPool.instance.warmUp();
  });

  // 检查是否需要显示引导页
  final showOnboarding = await OnboardingScreen.shouldShowOnboarding();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TtsProvider()),
        ChangeNotifierProvider(create: (_) => WebViewNavigationController()),
      ],
      child: CherryViewerApp(showOnboarding: showOnboarding),
    ),
  );
}

class CherryViewerApp extends StatelessWidget {
  final bool showOnboarding;

  const CherryViewerApp({Key? key, this.showOnboarding = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: NoScrollbarBehavior(),
      title: 'Cherry Reader',
      debugShowCheckedModeBanner: false,
      // 路由配置
      routes: {
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      theme: ThemeData(
        // 使用 Material 3 设计语言
        useMaterial3: true,
        brightness: Brightness.light,

        // 主色调：柔和的蓝色
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F62FE), // IBM 蓝
          brightness: Brightness.light,
          surface: const Color(0xFFFAFAFC), // 极浅灰蓝色背景
        ),

        // 背景色：温暖的浅灰色
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),

        // 卡片样式：干净的白色卡片
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0, // 扁平化设计
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.12), width: 1),
          ),
        ),

        // AppBar 样式：无边界融入背景
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F6FA),
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.5,
          ),
        ),

        // 输入框样式：柔和的边框
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 2),
          ),
        ),

        // 文本主题：现代易读
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: -1,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
            height: 1.6,
            letterSpacing: 0.2,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C7D),
            height: 1.5,
          ),
        ),

        // 浮动按钮样式
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF0F62FE),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: showOnboarding 
          ? const OnboardingScreen() 
          : const WebViewOverlayScreen(),
    );
  }
}

/// 带 WebView 覆盖层的主屏幕
/// 
/// 使用 Stack 实现 WebView 始终存活，通过 Visibility 控制显示
class WebViewOverlayScreen extends StatelessWidget {
  const WebViewOverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebViewNavigationController>(
      builder: (context, controller, child) {
        return Stack(
          children: [
            // 底层：MainScreen（始终显示）
            const MainScreen(),
            
            // 顶层：WebView 覆盖层
            if (controller.currentParams != null)
              Visibility(
                visible: controller.isVisible,
                maintainState: true, // 保持状态，不销毁
                child: WebViewConversationScreen(
                  key: ValueKey(controller.currentParams!.topicId),
                  topicId: controller.currentParams!.topicId,
                  topicName: controller.currentParams!.topicName,
                  conversationDataJson:
                      controller.currentParams!.conversationDataJson,
                  scrollToGroupIndex: controller.currentParams!.scrollToGroupIndex,
                  scrollToMessageId: controller.currentParams!.scrollToMessageId,
                  scrollToHighlightId: controller.currentParams!.scrollToHighlightId,
                  scrollToTextStart: controller.currentParams!.scrollToTextStart,
                  scrollToTextEnd: controller.currentParams!.scrollToTextEnd,
                  scrollToQuotedText: controller.currentParams!.scrollToQuotedText,
                  scrollToQuotedTextOccurrence: controller.currentParams!.scrollToQuotedTextOccurrence,
                  onBack: () => controller.hideWebView(),
                ),
              ),
          ],
        );
      },
    );
  }
}
