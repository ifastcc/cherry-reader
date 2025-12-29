import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'notes_screen.dart';

/// 主页面（底部导航）
///
/// 包含两个一级页面：
/// - 对话（HomeScreen）
/// - 笔记（NotesScreen）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 对话页面
          const HomeScreen(),

          // 笔记页面
          NotesScreen(
            onNavigateToConversation: _navigateToConversation,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '对话',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '笔记',
          ),
        ],
      ),
    );
  }

  /// 从笔记跳转到对话
  ///
  /// TODO: Phase 9 - 实现完整的跳转功能
  /// 当前由于 ConversationScreen 需要 CherryExtractor，
  /// 而 extractor 是在 HomeScreen 中管理的，
  /// 需要重构架构才能实现跨页面跳转。
  void _navigateToConversation(String topicId, String? messageId) {
    // 切换到对话 Tab
    setState(() => _currentIndex = 0);

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已切换到对话页面，跳转到具体对话功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
