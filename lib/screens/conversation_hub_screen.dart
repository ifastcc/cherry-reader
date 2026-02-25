import 'package:flutter/material.dart';
import '../services/repository_provider.dart';
import 'conversation_screen.dart';
import 'home_screen.dart';

/// 对话主屏（单页 + 左侧抽屉列表）
///
/// - 主区域显示话题详情
/// - 左侧抽屉显示助手/话题列表
class ConversationHubScreen extends StatefulWidget {
  const ConversationHubScreen({super.key});

  @override
  State<ConversationHubScreen> createState() => ConversationHubScreenState();
}

class ConversationHubScreenState extends State<ConversationHubScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  String? _activeTopicId;
  String? _activeTopicName;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _loadInitialTopic();
  }

  Future<void> _loadInitialTopic() async {
    try {
      final topics = await RepositoryProvider.instance.topicRepository.getAllTopics();
      if (topics.isNotEmpty) {
        topics.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final latest = topics.first;
        if (!mounted) return;
        setState(() {
          _activeTopicId = latest.topicId;
          _activeTopicName = latest.name;
          _isLoadingInitial = false;
        });
        return;
      }
    } catch (_) {
      // 忽略错误，降级为空状态
    }

    if (!mounted) return;
    setState(() {
      _isLoadingInitial = false;
    });
  }

  void _selectTopic(String topicId, String topicName) {
    setState(() {
      _activeTopicId = topicId;
      _activeTopicName = topicName;
    });
    Navigator.of(context).pop();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  /// 处理主按钮点击（由 MainScreen 触发）
  void handleMainAction() {
    _homeKey.currentState?.handleMainAction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: HomeScreen(
          key: _homeKey,
          embedMode: true,
          onSelectTopic: _selectTopic,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeTopicId == null) {
      return _buildEmptyState();
    }

    return ConversationScreen(
      key: ValueKey(_activeTopicId),
      topicId: _activeTopicId!,
      topicName: _activeTopicName ?? '未命名话题',
      onOpenDrawer: _openDrawer,
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            const Text('暂无话题'),
            const SizedBox(height: 8),
            Text(
              '从左侧抽屉选择话题，或先导入数据。',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openDrawer,
              icon: const Icon(Icons.menu),
              label: const Text('打开助手列表'),
            ),
          ],
        ),
      ),
    );
  }
}
