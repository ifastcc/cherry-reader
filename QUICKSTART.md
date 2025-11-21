# Cherry Viewer Flutter - 快速开始

## 🚀 3 分钟上手

### 1. 安装 Flutter（如未安装）

```bash
# macOS
brew install flutter

# 验证安装
flutter doctor
```

### 2. 初始化项目

```bash
cd /Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer

# 安装依赖
flutter pub get

# 生成 JSON 序列化代码
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 运行应用

```bash
# 方法 1: 使用启动脚本（推荐）
./run.sh

# 方法 2: 手动运行 macOS 版本
flutter run -d macos

# 方法 3: 运行 Web 版本
./run.sh web
```

## 📱 使用流程

1. **启动应用** → 点击"加载数据"按钮
2. **选择文件** → 选择 Cherry Studio 导出的 `.zip` 或 `.json` 文件
3. **查看话题** → 展开 Assistant 分组，点击任意话题
4. **AI 分析** → 点击"+"按钮生成元分析（需要 OpenAI API Key）

## ⚙️ OpenAI API Key 配置

### 方法 1: 环境变量（推荐）

```bash
# 设置环境变量
export OPENAI_API_KEY="sk-your-api-key-here"

# 运行应用
./run.sh
```

### 方法 2: 修改代码

编辑 `lib/screens/conversation_screen.dart`:

```dart
String _getApiKey() {
  // 直接返回你的 API Key
  return 'sk-your-api-key-here';
}
```

## 🛠️ 常见问题

### Q: 编译报错怎么办？

```bash
# 清理缓存
flutter clean

# 重新安装依赖
flutter pub get

# 重新生成代码
flutter pub run build_runner build --delete-conflicting-outputs
```

### Q: 如何查看所有可用设备？

```bash
flutter devices
```

### Q: 如何在特定设备上运行？

```bash
# 查看设备列表
flutter devices

# 在指定设备运行
flutter run -d <device_id>
```

### Q: 没有 OpenAI API Key 能用吗？

可以！除了 AI 分析功能，其他功能（数据加载、对话查看、统计等）都可以正常使用。

## 📊 性能提示

- **首次加载**: 可能需要 5-10 秒编译（之后会更快）
- **大文件**: 100MB+ 的数据包加载约 2-3 秒
- **流式生成**: AI 分析实时显示，无需等待全部完成

## 🔍 功能预览

| 功能              | 状态 | 说明                     |
| ----------------- | ---- | ------------------------ |
| ZIP/JSON 加载     | ✅   | 自动识别格式             |
| 按 Assistant 分组 | ✅   | 二级树形结构             |
| 多模型回复展示    | ✅   | 横向滚动，流畅对比       |
| AI 元分析         | ✅   | 流式生成，实时更新       |
| 缓存持久化        | ✅   | 基于 Topic ID            |
| Markdown 渲染     | ✅   | 支持代码高亮、表格等     |
| 思考过程折叠      | ✅   | ExpansionTile            |
| 统计信息          | ✅   | 话题数、Token 数等       |
| 搜索功能          | ⏳   | 待实现                   |
| 导出功能          | ⏳   | 待实现                   |

## 📝 下一步

查看完整文档：
- [README.md](README.md) - 完整功能介绍
- [FLUTTER_MIGRATION_SUMMARY.md](../FLUTTER_MIGRATION_SUMMARY.md) - 迁移技术细节

遇到问题？查看主项目文档：
- [../README.md](../README.md) - Cherry Viewer 总体介绍
- [../docs/](../docs/) - 数据结构文档

## 🎓 开发提示

### 修改 UI

编辑文件后，应用会自动热重载（Hot Reload）：
- 修改颜色、文本：立即生效
- 修改 widget 结构：按 `r` 键重新加载
- 添加新依赖：需要重启应用

### 调试

```bash
# 查看详细日志
flutter run --verbose

# 在 VS Code 中调试
按 F5 启动调试器
```

### 打包发布

```bash
# macOS 应用
flutter build macos

# Web 应用
flutter build web

# 生成的文件位置
build/macos/Build/Products/Release/cherry_viewer_flutter.app
build/web/
```

## 💡 提示

- **首次运行**: 会下载 Flutter 依赖，可能需要几分钟
- **网络问题**: 如果下载慢，可以配置 Flutter 镜像
- **API 费用**: AI 分析使用 GPT-4，注意 API 使用成本

祝使用愉快！🍒
