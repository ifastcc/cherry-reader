import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'knowledge/knowledge_hub_screen.dart';

/// 主页面（底部导航）
///
/// 包含两个一级页面：
/// - 对话（HomeScreen）
/// - 知识库（KnowledgeHubScreen）
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
        children: const [
          // 对话页面
          HomeScreen(),

          // 知识库页面
          KnowledgeHubScreen(),
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
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic),
            label: '知识库',
          ),
        ],
      ),
    );
  }
}
