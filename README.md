<div align="center">

<img src="assets/logo.jpg" width="120" height="120" alt="Cherry Reader" />

# Cherry Reader

**Chat History Reader & MCP Server for Cherry Studio**

Cherry Studio 对话的阅读器与知识管理工具

<a href="https://apps.apple.com/cn/app/cherry-reader/id6755708214">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="App Store" height="40">
</a>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev/)

</div>

---

## 截图

<!-- 横向可滚动画廊 -->
<div align="center">
<table>
  <tr>
    <td><img src="assets/screenshots/home.png" width="280" alt="首页" /></td>
    <td><img src="assets/screenshots/conversation.png" width="280" alt="对话" /></td>
    <td><img src="assets/screenshots/multi-model.png" width="280" alt="多模型对比" /></td>
    <td><img src="assets/screenshots/highlight.png" width="280" alt="高亮标注" /></td>
  </tr>
  <tr>
    <td align="center"><b>话题列表</b></td>
    <td align="center"><b>对话阅读</b></td>
    <td align="center"><b>多模型对比</b></td>
    <td align="center"><b>高亮标注</b></td>
  </tr>
</table>
</div>

---

## 功能

### 阅读体验

| 功能 | 说明 |
|------|------|
| **全屏专注模式** | 隐藏侧边栏，沉浸式阅读长对话 |
| **TTS 语音朗读** | Azure 语音引擎，边下载边播放，支持倍速调节 |
| **EPUB 导出** | 导出为电子书，在 Kindle、Books 等阅读器中继续阅读 |
| **高亮标注** | 5 种颜色标记重要内容，本地持久化存储 |

### 多模型对比

Cherry Studio 支持 `@提及` 多个模型回答同一问题。Cherry Reader 提供：

| 功能 | 说明 |
|------|------|
| **并排展示** | 多个模型的回答左右对照显示 |
| **AI 共识分析** | 自动分析各模型回答的共识点与分歧点 |
| **主线标识** | 金色边框标记对话主线（你选择保留的回答） |

### 讨论挂载

在任意 AI 回复下开启独立讨论，深入探索某个观点，不污染原对话上下文。

### MCP Server（桌面端）

让 AI 编程助手（Cursor、Claude Code、VS Code、Cline 等）访问你的聊天记录。

| 工具 | 用途 |
|------|------|
| `recall_my_conversations` | 回顾某段时间的对话（"这周聊了什么"） |
| `search_past_discussions` | 语义/关键词搜索历史讨论 |
| `read_conversation_detail` | 读取完整对话内容 |

**启用**：设置 → MCP 服务 → 开启（localhost:9527，数据不离开设备）

---

## 安装

### 下载

| 平台 | 来源 |
|------|------|
| **iOS / iPadOS** | [App Store](https://apps.apple.com/cn/app/cherry-reader/id6755708214) |
| **macOS / Windows / Linux** | [GitHub Releases](https://github.com/ifastcc/cherry-reader/releases) |

### 源码运行

```bash
git clone https://github.com/ifastcc/cherry-reader.git
cd cherry-reader/flutter_viewer
./run.sh          # macOS (默认)
./run.sh ios      # iOS 模拟器
./run.sh profile  # 性能分析模式
```

---

## MCP 配置

```bash
# Claude Code
claude mcp add --transport http cherry-reader http://localhost:9527/mcp
```

其他工具（Cursor、VS Code、Cline）的配置可在应用内一键复制。

---

<div align="center">

[App Store](https://apps.apple.com/cn/app/cherry-reader/id6755708214) · [GitHub Releases](https://github.com/ifastcc/cherry-reader/releases) · [Issues](https://github.com/ifastcc/cherry-reader/issues)

</div>
