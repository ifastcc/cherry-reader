# Cherry Reader

一个沉浸式的 Cherry Studio 聊天记录阅读器，支持标注、AI 分析和流畅的阅读体验。

## 🎯 特性

✅ **沉浸式阅读** - 专为长时间阅读优化的界面设计
✅ **智能标注** - 高亮、批注你的重要对话内容
✅ **AI 洞察分析** - 实时生成对话总结和深度分析
✅ **横向对比阅读** - 流畅的多模型回复对比卡片
✅ **跨平台支持** - Web/Desktop/Mobile 统一代码
✅ **纯 Dart 实现** - 无需 Python 后端，高性能渲染

## 📦 安装

### 1. 安装 Flutter SDK

```bash
# macOS
brew install flutter

# 或从官网下载
https://flutter.dev/docs/get-started/install
```

### 2. 克隆项目

```bash
git clone https://github.com/yourusername/cherry-reader.git
cd cherry-reader
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 生成 JSON 序列化代码

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🚀 运行

### Web 版

```bash
flutter run -d chrome
```

### macOS 桌面版

```bash
flutter run -d macos
```

### 所有可用设备

```bash
flutter devices
flutter run -d <device_id>
```

## ⚙️ 配置

### 环境变量配置

**推荐方式：使用 `.env` 文件**

1. 复制示例配置：
```bash
cp .env.example .env
```

2. 编辑 `.env` 文件，填写你的配置：
```bash
# OpenAI API 配置
OPENAI_API_KEY=your_api_key_here
OPENAI_BASE_URL=https://api.openai.com/v1  # 或你的代理地址
OPENAI_MODEL=gpt-4
```

3. 运行应用（会自动加载 `.env` 配置）：
```bash
flutter run -d macos
```

**旧方式（不推荐）：命令行参数**
```bash
export OPENAI_API_KEY="sk-..."
flutter run -d macos --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY
```

## 📂 项目结构

```
lib/
├── main.dart                           # 应用入口
├── models/                             # 数据模型（翻译自 Python types.py）
│   ├── message_role.dart
│   ├── message_block_type.dart
│   ├── message_block_status.dart
│   ├── model_info.dart
│   ├── usage.dart
│   ├── metrics.dart
│   ├── file_metadata.dart
│   ├── message_block.dart
│   ├── message.dart
│   ├── topic.dart
│   └── export_data.dart
├── services/                           # 业务逻辑
│   ├── cherry_extractor.dart          # 数据提取器（翻译自 Python extractor.py）
│   ├── analysis_cache_manager.dart    # 缓存管理（翻译自 Python analysis_cache_manager.py）
│   └── openai_service.dart             # OpenAI 流式 API
├── widgets/                            # UI 组件
│   ├── conversation_card.dart          # 对话卡片
│   ├── streaming_analysis_card.dart    # 流式分析卡片
│   └── horizontal_scroll_view.dart     # 横向滚动容器
└── screens/                            # 页面
    ├── home_screen.dart                # 主页
    └── conversation_screen.dart        # 对话详情页
```

## 🔄 从 Python MVP 迁移的对应关系

| Python 文件                     | Dart 文件                           | 说明                       |
| ------------------------------- | ----------------------------------- | -------------------------- |
| `types.py`                      | `models/*.dart`                     | 数据类型定义               |
| `extractor.py`                  | `services/cherry_extractor.dart`    | 核心提取器（完整翻译）     |
| `analysis_cache_manager.py`    | `services/analysis_cache_manager.dart` | 缓存管理（完整翻译）       |
| `streamlit_viewer.py` (UI部分)  | `screens/*.dart`, `widgets/*.dart`  | UI 组件（Flutter 原生实现）|
| OpenAI streaming API            | `services/openai_service.dart`      | SSE 流式解析               |

## 🎨 核心功能实现

### 1. 数据加载

```dart
// 从 ZIP 或 JSON 加载
final extractor = CherryExtractor(zipPath: 'cherry-studio.zip');
await extractor.load();

// 按 Assistant 分组
final grouped = extractor.getTopicsByAssistant();
```

### 2. 横向滚动卡片

```dart
HorizontalScrollView(
  cards: [
    ConversationCard.assistant(reply1),
    ConversationCard.assistant(reply2),
    ConversationCard.aiAnalysis(analysis),
  ],
  trailing: IconButton(
    icon: Icon(Icons.add_circle_outline),
    onPressed: () => _generateAnalysis(),
  ),
)
```

### 3. 流式 AI 分析

```dart
final stream = _openaiService.streamChatCompletion(
  model: 'gpt-4-turbo-preview',
  messages: [{'role': 'user', 'content': prompt}],
);

await for (final chunk in stream) {
  setState(() {
    _currentStreamContent += chunk;
  });
}
```

## 📊 性能对比

| 功能              | Python (Streamlit) | Flutter (Dart)   |
| ----------------- | ------------------ | ---------------- |
| 加载 117MB 数据   | ~2秒               | ~1.5秒           |
| 构建索引          | ~1秒               | ~0.5秒           |
| UI 渲染           | 每次重新加载整个页面 | 只重绘变化的部分 |
| 流式更新          | 阻塞式             | 真正异步         |
| 打包大小          | 需要Python运行时    | 单一可执行文件   |

## 🛠️ 开发指南

### 修改数据模型

1. 编辑 `lib/models/*.dart`
2. 运行 `flutter pub run build_runner build --delete-conflicting-outputs`

### 修改 UI 样式

- 主题配置：`lib/main.dart` 中的 `ThemeData`
- 卡片样式：`lib/widgets/conversation_card.dart`
- 颜色方案：参考 Streamlit 版本的 CSS 渐变

### 添加新功能

Flutter 的响应式架构让添加新功能更简单：

```dart
// 使用 setState 更新 UI
setState(() {
  _data = newData;
});

// 使用 FutureBuilder 处理异步
FutureBuilder(
  future: _loadData(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return _buildContent(snapshot.data);
    }
    return CircularProgressIndicator();
  },
)
```

## 📝 TODO

- [ ] 实现搜索和过滤功能
- [ ] 添加数据导出功能（JSON/Markdown）
- [ ] 支持自定义 AI 分析 prompt
- [ ] 添加数据可视化图表
- [ ] 实现文件附件查看
- [ ] 支持深色/浅色主题切换

## 🐛 故障排除

### 编译错误

```bash
# 清理缓存
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 运行时错误

```bash
# 查看详细日志
flutter run --verbose

# 检查依赖
flutter doctor
```

## 📄 许可证

MIT License
