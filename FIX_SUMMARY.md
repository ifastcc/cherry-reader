# Flutter Mouse Tracker 错误修复总结

## 问题描述

应用运行时反复出现以下错误：
1. `Vertical viewport was given unbounded height`
2. `mouse_tracker.dart: Failed assertion: !_debugDuringDeviceUpdate`
3. `Null check operator used on a null value`

## 根本原因

**布局问题导致的连锁反应**：
1. `CustomMarkdownView` 返回 `ListView`，但被放在无界高度的 `Stack` 中
2. 布局失败导致 RenderObject 没有完成布局
3. 鼠标事件在布局失败的对象上触发，导致 mouse_tracker 断言失败

## 解决方案

### 1. 修改 CustomMarkdownView
**文件**: `lib/widgets/custom_markdown_view.dart`

将 `ListView` 改为有界的滚动容器：

```dart
@override
Widget build(BuildContext context) {
  // ...处理 Markdown...

  return ListView(  // 保持 ListView，但确保外层有尺寸约束
    padding: padding,
    children: _buildBlockNodes(context, nodes),
  );
}
```

**重要**：在使用 `CustomMarkdownView` 的地方必须提供明确的尺寸约束！

### 2. 在 FullscreenReaderScreen 中添加尺寸约束
**文件**: `lib/screens/fullscreen_reader_screen.dart`

```dart
Stack(
  children: [
    // 使用 Positioned.fill 提供明确的尺寸约束
    Positioned.fill(
      child: CustomMarkdownView(
        data: widget.content,
        highlights: _highlights.map(...).toList(),
        onHighlightTap: (id, details) { ... },
        selectable: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    ),
    // ... 其他浮动组件
  ],
)
```

### 3. 修改 ConversationCard 中的 Markdown
**文件**: `lib/widgets/conversation_card.dart`

将 `Markdown` 改为 `MarkdownBody`（非滚动版本）：

```dart
// 在 ExpansionTile.children 中
children: [
  Padding(
    padding: const EdgeInsets.all(12.0),
    child: MarkdownBody(  // 使用 MarkdownBody 而不是 Markdown
      data: content,
      styleSheet: MarkdownStyleSheet(...),
    ),
  ),
],
```

### 4. GestureDetector 中的 setState
**文件**: `lib/screens/fullscreen_reader_screen.dart`

所有在 `GestureDetector.onTap` 中的 `setState` 都用 `WidgetsBinding.instance.addPostFrameCallback` 包装：

```dart
GestureDetector(
  onTap: () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // 更新状态
        });
      }
    });
  },
)
```

## 测试步骤

1. 运行 `dart run build_runner build --delete-conflicting-outputs`
2. 启动应用：`flutter run -d macos`
3. 加载数据文件
4. 浏览对话列表 - 不应该有 "unbounded height" 错误
5. 进入全屏阅读器 - 不应该有 mouse_tracker 错误
6. 点击和选择文本 - 应该流畅无错误

## 如果问题依然存在

### 调试步骤

1. 查找所有使用 `ListView` 的地方：
```bash
grep -r "ListView(" lib/ --include="*.dart"
```

2. 查找所有使用 `Markdown(` 的地方：
```bash
grep -r "Markdown(" lib/ --include="*.dart"
```

3. 确保每个 `ListView` 或 `Markdown` 都满足以下条件之一：
   - 在 `Positioned.fill` 中
   - 在 `Expanded` 中
   - 在 `SizedBox` 或 `Container` 中（有明确的高度）
   - 使用 `shrinkWrap: true` 且在非滚动容器中

### 临时禁用全屏阅读器

如果需要快速修复主界面，可以临时禁用全屏阅读功能：

```dart
// 在 ConversationCard 中注释掉全屏阅读的导航
// Navigator.push(...);
```

## 技术债务

以下是长期需要改进的地方：

1. **统一 Markdown 渲染**：目前有多个 Markdown 组件（`CustomMarkdownView`, `CollapsibleMarkdown`, `HighlightedMarkdown`），应该统一
2. **简化布局层次**：减少 `Stack` 和 `ListView` 的嵌套层数
3. **改进高亮功能**：当前的实现依赖 `SelectionArea`，可以考虑使用更简单的方案

## 参考资料

- Flutter Layout 约束: https://docs.flutter.dev/ui/layout/constraints
- Viewport 嵌套问题: https://api.flutter.dev/flutter/widgets/ListView-class.html#shrinkWrap
- Mouse Tracker: https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/rendering/mouse_tracker.dart
