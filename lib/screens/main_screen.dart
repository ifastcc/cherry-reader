import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'knowledge/knowledge_hub_screen.dart';
import '../widgets/floating_dock.dart';

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
  
  // Keys to access child states for the central button action
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<KnowledgeHubScreenState> _knowledgeKey = GlobalKey<KnowledgeHubScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Content Area
          IndexedStack(
            index: _currentIndex,
            children: [
              // 对话页面
              HomeScreen(key: _homeKey),

              // 知识库页面
              KnowledgeHubScreen(key: _knowledgeKey),
            ],
          ),

          // Floating Dock at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingDock(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              centerIcon: Icon(
                _currentIndex == 0 ? Icons.add_circle_outline : Icons.add_circle,
              ),
              onCenterAction: _handleCenterAction,
            ),
          ),
        ],
      ),
    );
  }

  void _handleCenterAction() {
    if (_currentIndex == 0) {
      // Home Action: Load File or Insight
      // We need to access HomeScreen state.
      // This requires HomeScreenState to be public.
      _homeKey.currentState?.handleMainAction();
    } else {
      // Knowledge Action: Create Note
      _knowledgeKey.currentState?.handleMainAction();
    }
  }
}
