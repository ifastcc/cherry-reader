import 'package:flutter/material.dart';
import 'conversation_hub_screen.dart';
import 'knowledge/knowledge_hub_screen.dart';
import '../widgets/layouts/layouts.dart';

/// 主页面
///
/// 包含两个一级页面：
/// - 对话（ConversationHubScreen）
/// - 知识库（KnowledgeHubScreen）
/// 
/// 使用手势导航布局（左右滑动切换页面）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // Keys to access child states for the central button action
  final GlobalKey<ConversationHubScreenState> _homeKey =
      GlobalKey<ConversationHubScreenState>();
  final GlobalKey<KnowledgeHubScreenState> _knowledgeKey = GlobalKey<KnowledgeHubScreenState>();

  // 缓存子页面实例，避免每次 build 都创建新对象
  late final Widget _homeScreen;
  late final Widget _knowledgeScreen;

  @override
  void initState() {
    super.initState();
    // 在 initState 中创建子页面实例，确保整个生命周期只创建一次
    _homeScreen = ConversationHubScreen(key: _homeKey);
    _knowledgeScreen = KnowledgeHubScreen(key: _knowledgeKey);
  }

  @override
  Widget build(BuildContext context) {
    // 创建布局上下文
    final layoutContext = LayoutSchemeContext(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
      },
      onMainAction: _handleCenterAction,
      homeScreen: _homeScreen,
      knowledgeScreen: _knowledgeScreen,
    );

    // 使用手势导航布局
    return GestureNavLayout(context: layoutContext);
  }

  void _handleCenterAction() {
    if (_currentIndex == 0) {
      // Home Action: Load File or Insight
      _homeKey.currentState?.handleMainAction();
    } else {
      // Knowledge Action: Create Note
      _knowledgeKey.currentState?.handleMainAction();
    }
  }
}
