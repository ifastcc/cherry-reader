<div align="center">

# 🍒 Cherry Reader

**一个沉浸式的 Cherry Studio 聊天记录阅读器**

支持标注、AI 分析和流畅的阅读体验

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Web-lightgrey.svg)](https://github.com/ifastcc/cherry-reader)

[English](README.md) | 简体中文

</div>

---

## ✨ 特性

<table>
<tr>
<td width="50%">

### 📖 沉浸式阅读
专为长时间阅读优化的界面设计，让你舒适地回顾每一段对话

### 🎨 智能标注
高亮、批注你的重要对话内容，像读书一样做笔记

### 🤖 AI 洞察分析
实时生成对话总结和深度分析，提取关键信息

</td>
<td width="50%">

### 📊 横向对比阅读
流畅的多模型回复对比卡片，一目了然

### 🌐 跨平台支持
macOS 桌面 + Web 浏览器，随处访问

### ⚡ 纯 Dart 实现
无需 Python 后端，高性能渲染

</td>
</tr>
</table>

## 🚀 快速开始

### 前置要求

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.0+
- macOS 12+ (桌面版) 或现代浏览器 (Web 版)

### 安装与运行

```bash
# 1. 克隆项目
git clone https://github.com/ifastcc/cherry-reader.git
cd cherry-reader

# 2. 安装依赖
flutter pub get

# 3. 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 运行应用
flutter run -d macos    # macOS 桌面版（推荐）
flutter run -d chrome   # Web 版
```

### 或使用便捷脚本

```bash
./run.sh        # macOS 桌面版
./run.sh web    # Web 版
```

## ⚙️ 配置 AI 分析功能

> AI 分析功能是可选的。如果不配置，仍可正常浏览和标注聊天记录。

### 方式一：使用 `.env` 文件（推荐）

```bash
# 1. 复制示例配置
cp .env.example .env

# 2. 编辑 .env 文件
OPENAI_API_KEY=your_api_key_here
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4
```

### 方式二：应用内设置

启动应用后，在设置页面中配置 API 信息（会保存在本地）。

## 🏗️ 技术架构

### 支持平台

| 平台 | 状态 | 说明 |
|------|------|------|
| 🖥️ macOS | ✅ 推荐 | 桌面端完整体验，适合长时间阅读 |
| 🌐 Web | ✅ 支持 | 无需安装，浏览器直接使用 |
| 📱 iOS | ✅ 支持 | iPhone/iPad 完美适配 |
| 🤖 Android | 🚧 计划中 | 待添加原生配置 |
| 💻 Windows/Linux | 🚧 计划中 | 考虑支持其他桌面平台 |

### 项目结构

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

### 从 Python MVP 迁移的架构对应

<details>
<summary>点击查看详细对应关系</summary>

| Python 文件 | Dart 文件 | 说明 |
|------------|----------|------|
| `types.py` | `models/*.dart` | 数据类型定义 |
| `extractor.py` | `services/cherry_extractor.dart` | 核心提取器（完整翻译） |
| `analysis_cache_manager.py` | `services/analysis_cache_manager.dart` | 缓存管理（完整翻译） |
| `streamlit_viewer.py` (UI部分) | `screens/*.dart`, `widgets/*.dart` | UI 组件（Flutter 原生实现）|
| OpenAI streaming API | `services/openai_service.dart` | SSE 流式解析 |

</details>

## 📊 性能对比

| 功能 | Python (Streamlit) | Flutter (Dart) |
|------|-------------------|----------------|
| 💾 加载 117MB 数据 | ~2秒 | ~1.5秒 |
| 📇 构建索引 | ~1秒 | ~0.5秒 |
| 🎨 UI 渲染 | 每次重新加载整个页面 | 只重绘变化的部分 |
| ⚡ 流式更新 | 阻塞式 | 真正异步 |
| 📦 打包大小 | 需要Python运行时 | 单一可执行文件 |

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

## 🗺️ 开发路线图

### 🚧 进行中
- [ ] 🎙️ TTS 语音朗读功能
- [ ] 📝 高级标注功能（笔记、分类）

### 📋 计划中
- [ ] 🔍 搜索和过滤功能
- [ ] 📤 数据导出功能（JSON/Markdown）
- [ ] ✍️ 自定义 AI 分析 prompt
- [ ] 📊 数据可视化图表
- [ ] 📎 文件附件查看
- [ ] 🌓 深色/浅色主题切换
- [x] 📱 iOS 移动端支持
- [ ] 🤖 Android 移动端支持

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

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

在提交 PR 前，请确保：
- 运行 `dart format .` 格式化代码
- 运行 `flutter analyze` 检查代码质量
- 测试你的更改在 macOS 和 Web 平台上都能正常工作

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️ Star！**

 Made with ❤️ by [ifastcc](https://github.com/ifastcc)

</div>
