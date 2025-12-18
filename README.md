<div align="center">

<img src="assets/logo.jpg" width="120" height="120" alt="Cherry Reader" />

# Cherry Reader

Cherry Studio 对话的阅读器与知识管理工具

<a href="https://apps.apple.com/cn/app/cherry-reader/id6755708214">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="App Store" height="40">
</a>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev/)

</div>

---

## 是什么

导入 Cherry Studio 导出的对话数据，提供：

- **阅读体验**：全屏专注模式，流畅渲染长对话
- **多模型对比**：同一问题的多个模型回答，AI 自动分析共识与分歧
- **讨论挂载**：在任意回复下开启独立讨论，不污染原对话
- **TTS 朗读**：Azure 语音，边下载边播放
- **EPUB 导出**：适配各类阅读器
- **高亮标注**：多色标记，本地持久化

## 安装

**iOS / iPadOS**：[App Store](https://apps.apple.com/cn/app/cherry-reader/id6755708214)

**源码构建**：

```bash
git clone https://github.com/ifastcc/cherry-viewer.git
cd cherry-viewer/flutter_viewer
flutter pub get
flutter run -d macos  # 或 ios / android
```

## 配置

在设置中配置（AI 分析功能需要）：

| 配置项 | 说明 |
|-------|------|
| API Key | OpenAI / Claude / 兼容格式 |
| Base URL | 自定义 API 地址 |
| Azure TTS | 语音朗读密钥 |

## MCP 服务（桌面端）

桌面版（macOS / Windows / Linux）内置 MCP Server，让 AI 编程助手访问你的聊天记录。

**启用**：设置 → MCP 服务 → 开启（默认端口 9527）

**工具**：
| 名称 | 功能 |
|------|------|
| `recall_my_conversations` | 回顾指定时间段的对话 |
| `search_past_discussions` | 搜索历史讨论 |
| `read_conversation_detail` | 读取对话详情 |

**配置示例**：

```bash
# Claude Code
claude mcp add --transport http cherry-reader http://localhost:9527/mcp
```

应用内提供 Cursor、VS Code、Cline、Cherry Studio 等工具的一键复制配置。

## 贡献

[Issue](https://github.com/ifastcc/cherry-viewer/issues) 和 PR 欢迎。

---

<div align="center">

[下载 Cherry Reader](https://apps.apple.com/cn/app/cherry-reader/id6755708214)

</div>
