import 'package:flutter/material.dart';

/// 布局方案类型枚举
enum LayoutSchemeType {
  /// 方案 A: 分离式导航（底部导航 + FAB）
  classicNav,
  
  /// 方案 B: 中央 Dock（优化版当前设计）
  centerDock,
  
  /// 方案 C: 顶部分段控件 + FAB
  segmented,
  
  /// 方案 D: 手势导航 + FAB
  gestureNav,
  
  /// 方案 E: 侧边抽屉 + FAB
  drawer,
}

/// 布局方案元数据
extension LayoutSchemeTypeExtension on LayoutSchemeType {
  /// 显示名称
  String get displayName {
    switch (this) {
      case LayoutSchemeType.classicNav:
        return '经典导航';
      case LayoutSchemeType.centerDock:
        return '中央 Dock';
      case LayoutSchemeType.segmented:
        return '顶部分段';
      case LayoutSchemeType.gestureNav:
        return '手势导航';
      case LayoutSchemeType.drawer:
        return '侧边抽屉';
    }
  }

  /// 描述
  String get description {
    switch (this) {
      case LayoutSchemeType.classicNav:
        return '底部导航栏 + 悬浮操作按钮，符合 Material Design 规范';
      case LayoutSchemeType.centerDock:
        return '浮动 Dock 导航条，中央按钮执行主操作';
      case LayoutSchemeType.segmented:
        return '顶部分段控件切换页面，底部空间完全释放';
      case LayoutSchemeType.gestureNav:
        return '左右滑动切换页面，极简沉浸体验';
      case LayoutSchemeType.drawer:
        return '侧边抽屉菜单，腾出更多内容空间';
    }
  }

  /// 图标
  IconData get icon {
    switch (this) {
      case LayoutSchemeType.classicNav:
        return Icons.view_compact_rounded;
      case LayoutSchemeType.centerDock:
        return Icons.dock_rounded;
      case LayoutSchemeType.segmented:
        return Icons.segment_rounded;
      case LayoutSchemeType.gestureNav:
        return Icons.swipe_rounded;
      case LayoutSchemeType.drawer:
        return Icons.menu_rounded;
    }
  }

  /// 存储键值
  String get storageKey => name;

  /// 从存储键值解析
  static LayoutSchemeType fromStorageKey(String key) {
    return LayoutSchemeType.values.firstWhere(
      (type) => type.storageKey == key,
      orElse: () => LayoutSchemeType.centerDock, // 默认使用中央 Dock
    );
  }
}

/// 布局方案上下文数据
/// 
/// 用于向各布局方案传递必要的页面状态和回调
class LayoutSchemeContext {
  /// 当前选中的页面索引 (0: 对话, 1: 知识库)
  final int selectedIndex;
  
  /// 页面切换回调
  final ValueChanged<int> onDestinationSelected;
  
  /// 主操作回调（对话页: AI洞见, 知识库页: 新建笔记）
  final VoidCallback onMainAction;
  
  /// 对话页面 Widget
  final Widget homeScreen;
  
  /// 知识库页面 Widget
  final Widget knowledgeScreen;
  
  /// 主操作按钮图标（可选，用于某些布局自定义）
  final IconData? mainActionIcon;

  const LayoutSchemeContext({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onMainAction,
    required this.homeScreen,
    required this.knowledgeScreen,
    this.mainActionIcon,
  });
}

/// 布局方案抽象接口
/// 
/// 所有布局方案都必须实现此接口
abstract class LayoutScheme extends StatelessWidget {
  /// 布局方案上下文
  final LayoutSchemeContext context;

  const LayoutScheme({
    super.key,
    required this.context,
  });

  /// 获取布局方案类型
  LayoutSchemeType get type;
}
