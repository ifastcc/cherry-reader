import 'package:flutter/material.dart';
import 'conversation_hub_screen.dart';

/// 主页面（仅保留对话入口）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return const ConversationHubScreen();
  }
}
