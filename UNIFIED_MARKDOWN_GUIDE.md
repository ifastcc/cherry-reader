# 统一 Markdown 组件使用指南

## 设计理念

`UnifiedMarkdownView` 是一个智能的、自适应的 Markdown 渲染组件，它：

✅ **自动选择渲染方式** - 根据 `scrollable` 参数决定使用 `ListView` 还是 `Column`
✅ **避免布局冲突** - 彻底解决 "unbounded height" 和 mouse_tracker 错误
✅ **统一高亮实现** - 所有场景使用相同的高亮逻辑
✅ **高度可配置** - 支持自定义样式、可选择性、高亮回调等

## 核心参数

```dart
UnifiedMarkdownView(
  data: markdownContent,           // Markdown 文本
  scrollable: false,                // 是否独立滚动
  selectable: true,                 // 是否可选择文本
  highlights: highlightList,        // 高亮列表
  onHighlightTap: (id, details) {}, // 点击高亮回调
  padding: EdgeInsets.all(16),      // 内边距
  baseTextStyle: TextStyle(...),    // 正文样式
  headingStyle: TextStyle(...),     // 标题样式
  codeStyle: TextStyle(...),        // 代码样式
)
```

## 使用场景

### 1. 对话卡片中的消息（非滚动）

```dart
// 在 ConversationCard 中
UnifiedMarkdownView(
  data: messageContent,
  scrollable: false,        // ❗ 重要：卡片本身在 ListView 中，不需要独立滚动
  selectable: true,
  padding: EdgeInsets.all(12),
)
```

### 2. 全屏阅读器（独立滚动）

```dart
// 在 FullscreenReaderScreen 中
Positioned.fill(
  child: UnifiedMarkdownView(
    data: fullContent,
    scrollable: true,        // ❗ 需要独立滚动
    selectable: true,
    highlights: _highlights,
    onHighlightTap: _showHighlightMenu,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  ),
)
```

### 3. AI 分析流式卡片（非滚动）

```dart
// 在 StreamingAnalysisCard 中
UnifiedMarkdownView(
  data: _currentStreamContent,
  scrollable: false,        // ❗ 在 HorizontalScrollView 中，不需要独立滚动
  selectable: true,
  baseTextStyle: TextStyle(fontSize: 15, color: Colors.grey[800]),
)
```

### 4. 思考过程展开内容（非滚动）

```dart
// 在 ExpansionTile.children 中
Padding(
  padding: EdgeInsets.all(12),
  child: UnifiedMarkdownView(
    data: thinkingContent,
    scrollable: false,      // ❗ 在 ExpansionTile 中，不需要独立滚动
    selectable: false,      // 思考过程可以不支持选择
    baseTextStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
  ),
)
```

## 迁移指南

### 从 CustomMarkdownView 迁移

**之前**：
```dart
CustomMarkdownView(
  data: content,
  highlights: highlights,
  onHighlightTap: onTap,
  selectable: true,
  padding: EdgeInsets.all(16),
)
```

**之后**：
```dart
UnifiedMarkdownView(
  data: content,
  scrollable: false,  // ❗ 新增：明确指定是否滚动
  highlights: highlights,
  onHighlightTap: onTap,
  selectable: true,
  padding: EdgeInsets.all(16),
)
```

### 从 CollapsibleMarkdown 迁移

**之前**：
```dart
CollapsibleMarkdown(
  content: content,
  highlights: highlights,
)
```

**之后**：
```dart
UnifiedMarkdownView(
  data: content,
  scrollable: false,  // ❗ 在可折叠组件中不需要滚动
  highlights: highlights,
  selectable: true,
)
```

### 从 HighlightedMarkdown 迁移

**之前**：
```dart
HighlightedMarkdown(
  data: content,
  highlights: highlights,
  selectable: true,
)
```

**之后**：
```dart
UnifiedMarkdownView(
  data: content,
  scrollable: false,
  highlights: highlights,
  selectable: true,
)
```

### 从 flutter_markdown 的 Markdown 迁移

**之前**：
```dart
Markdown(
  data: content,
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  styleSheet: MarkdownStyleSheet(...),
)
```

**之后**：
```dart
UnifiedMarkdownView(
  data: content,
  scrollable: false,  // shrinkWrap + NeverScrollable = scrollable: false
  selectable: true,
  baseTextStyle: TextStyle(...),  // 替代 styleSheet
)
```

## 完整迁移步骤

### 1. 替换 ConversationCard

**文件**: `lib/widgets/conversation_card.dart`

找到所有 `CollapsibleMarkdown`、`HighlightedMarkdown`、`Markdown` 的使用，替换为：

```dart
UnifiedMarkdownView(
  data: content,
  scrollable: false,
  selectable: true,
)
```

### 2. 替换 FullscreenReaderScreen

**文件**: `lib/screens/fullscreen_reader_screen.dart`

```dart
// 替换 CustomMarkdownView
Positioned.fill(
  child: UnifiedMarkdownView(
    data: widget.content,
    scrollable: true,  // ❗ 唯一需要 scrollable: true 的地方
    highlights: _highlights.map(...).toList(),
    onHighlightTap: (id, details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showHighlightMenu(id, details.globalPosition);
        }
      });
    },
    selectable: true,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  ),
)
```

### 3. 替换 SelectableAssistantCard

**文件**: `lib/widgets/selectable_assistant_card.dart`

找到所有 `Markdown` 使用，替换为 `UnifiedMarkdownView`。

### 4. 替换 StreamingAnalysisCard

**文件**: `lib/widgets/streaming_analysis_card.dart`

```dart
UnifiedMarkdownView(
  data: _currentStreamContent,
  scrollable: false,
  selectable: true,
)
```

### 5. 删除旧组件（可选）

迁移完成后，可以删除以下文件：
- `lib/widgets/custom_markdown_view.dart`
- `lib/widgets/collapsible_markdown.dart`
- `lib/widgets/highlighted_markdown.dart`
- `lib/widgets/markdown_with_latex.dart`

## 黄金规则 🏆

### 何时使用 `scrollable: true`
**只有一种情况**：组件是页面的主要内容区域，需要独立滚动。
- ✅ 全屏阅读器
- ✅ 独立的详情页面

### 何时使用 `scrollable: false`
**所有其他情况**：组件嵌入在其他滚动容器中。
- ✅ ListView 中的卡片
- ✅ ExpansionTile 的 children
- ✅ HorizontalScrollView 中的内容
- ✅ Dialog 中的内容
- ✅ Column/Row 中的子组件

## 验证步骤

迁移完成后，运行以下测试：

```bash
# 1. 清理编译缓存
flutter clean

# 2. 重新生成代码
dart run build_runner build --delete-conflicting-outputs

# 3. 运行应用
flutter run -d macos

# 4. 测试以下场景：
# - ✅ 主页加载数据，浏览对话列表（不应有 unbounded height 错误）
# - ✅ 展开思考过程（ExpansionTile 应正常工作）
# - ✅ 进入全屏阅读器（应能滚动和选择文本）
# - ✅ 添加高亮（点击应有反应）
# - ✅ AI 流式分析（应流畅更新）
# - ✅ 移动鼠标（不应有 mouse_tracker 错误）
```

## 常见问题

### Q: 为什么有些地方文本显示不全？
A: 检查是否错误地设置了 `scrollable: true`。在卡片中应该用 `scrollable: false`。

### Q: 为什么全屏阅读器不能滚动？
A: 确保 `scrollable: true` 并且使用 `Positioned.fill` 包装。

### Q: 高亮点击没反应？
A: 确保传入了 `onHighlightTap` 回调，并且使用了 `WidgetsBinding.instance.addPostFrameCallback`。

### Q: 还是有 mouse_tracker 错误？
A: 检查是否所有 `GestureDetector.onTap` 中的 `setState` 都用 `addPostFrameCallback` 包装了。

## 性能优化

`UnifiedMarkdownView` 已经做了以下优化：
- ✅ 避免不必要的 ListView 嵌套
- ✅ 使用 `SelectableText.rich` 而不是 `SelectionArea`
- ✅ 最小化重建范围
- ✅ 高效的 AST 解析

对于大量文本，考虑：
- 使用 `RepaintBoundary` 包装
- 延迟加载长内容
- 分页显示

## 下一步

1. **立即迁移**: 按照迁移指南逐个文件替换
2. **测试验证**: 确保所有场景都能正常工作
3. **清理代码**: 删除旧的 Markdown 组件文件
4. **文档更新**: 更新项目文档，说明使用新组件

---

**记住**: `scrollable: true` 只用于全屏阅读这一种场景，其他所有地方都用 `scrollable: false`！
