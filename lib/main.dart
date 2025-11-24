import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'no_scrollbar_behavior.dart';
import 'screens/home_screen.dart';
import 'services/analysis_cache_manager.dart';
import 'services/isar_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  await dotenv.load(fileName: ".env");

  // 初始化 Isar 数据库（优先初始化，提供高性能存储）
  await IsarDatabase().init();

  // 初始化缓存管理器（后续会迁移到 Isar）
  await AnalysisCacheManager().init();

  runApp(const CherryViewerApp());
}

class CherryViewerApp extends StatelessWidget {
  const CherryViewerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: NoScrollbarBehavior(),
      title: 'Cherry Studio Viewer',
      debugShowCheckedModeBanner: false,
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
      home: const HomeScreen(),
    );
  }
}
