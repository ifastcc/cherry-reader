# 快速修复方案

## 问题根源

你的应用中有多个地方使用了 `Markdown` widget（这是一个滚动的 ListView），
但它们被嵌套在其他滚动容器或没有明确高度的容器中，导致：
```
Vertical viewport was given unbounded height
```

## 快速修复

将所有 **不需要独立滚动** 的 `Markdown` 改为 `MarkdownBody`：

### 1. lib/widgets/highlighted_markdown.dart (行 35)
```dart
// 修改前
return Markdown(
  data: widget.content,
  shrinkWrap: true,
  ...
);

// 修改后  
return MarkdownBody(
  data: widget.content,
  ...
);
```

### 2. lib/widgets/selectable_assistant_card.dart (行 291)
```dart
// 修改前
Markdown(
  data: blockContent,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  ...
);

// 修改后
MarkdownBody(
  data: blockContent,
  ...
);
```

### 3. lib/widgets/markdown_with_latex.dart (行 67, 134, 147)
将所有 `Markdown(` 改为 `MarkdownBody(`

### 4. lib/widgets/conversation_card.dart (行 1028)
已经修复 ✅

## 执行修复

运行以下命令批量替换：

```bash
cd /Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer

# 备份
cp lib/widgets/highlighted_markdown.dart lib/widgets/highlighted_markdown.dart.bak
cp lib/widgets/selectable_assistant_card.dart lib/widgets/selectable_assistant_card.dart.bak
cp lib/widgets/markdown_with_latex.dart lib/widgets/markdown_with_latex.dart.bak

# 自动替换（需要手动验证）
sed -i '' 's/return Markdown(/return MarkdownBody(/g' lib/widgets/highlighted_markdown.dart
sed -i '' 's/child: Markdown(/child: MarkdownBody(/g' lib/widgets/selectable_assistant_card.dart lib/widgets/markdown_with_latex.dart

# 清理 shrinkWrap 和 physics 参数（MarkdownBody 不需要）
# 需要手动清理每个文件中的这些行
```

## 验证

1. 删除 `shrinkWrap` 和 `physics` 参数（MarkdownBody 不支持）
2. 运行 `flutter run -d macos`
3. 检查是否还有 "unbounded height" 错误

## 如果还有问题

最极端的解决方案：暂时禁用全部 Markdown 渲染，改用纯文本：
```dart
Text(content)
```

这样可以快速验证问题是否真的出在 Markdown 上。
