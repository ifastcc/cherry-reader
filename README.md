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

## 功能

导入 Cherry Studio 导出的对话数据，提供：

- **阅读体验**：全屏专注模式，流畅渲染长对话
- **多模型对比**：同一问题的多个模型回答，AI 自动分析共识与分歧
- **讨论挂载**：在任意回复下开启独立讨论，不污染原对话
- **TTS 朗读**：Azure 语音，边下载边播放
- **EPUB 导出**：适配各类阅读器
- **高亮标注**：多色标记，本地持久化
- **MCP Server**：让 Cursor / Claude Code / VS Code 等 AI 编程助手访问你的聊天记录

## 安装

### 桌面端（macOS / Windows / Linux）

从 [Releases](https://github.com/ifastcc/cherry-reader/releases) 下载：

| 平台 | 文件 | 说明 |
|------|------|------|
| macOS | `Cherry.Reader-x.x.x-macos.dmg` | 拖入应用程序 |
| Windows | `Cherry.Reader-x.x.x-windows.zip` | 解压后运行 exe |
| Linux | `Cherry.Reader-x.x.x-linux.tar.gz` | 解压后运行 |

### iOS / iPadOS

[App Store](https://apps.apple.com/cn/app/cherry-reader/id6755708214)

### 源码构建

```bash
git clone https://github.com/ifastcc/cherry-reader.git
cd cherry-reader/flutter_viewer
flutter pub get
flutter run -d macos  # 或 ios / android / windows / linux
```

## 配置

在设置中配置（AI 分析功能需要）：

| 配置项 | 说明 |
|-------|------|
| API Key | OpenAI / Claude / 兼容格式 |
| Base URL | 自定义 API 地址 |
| Azure TTS | 语音朗读密钥 |

## MCP Server（桌面端）

桌面版内置 MCP Server，让 AI 编程助手（Cursor、Claude Code、VS Code Copilot、Cline 等）访问你的 Cherry Studio 聊天记录。

**启用**：设置 → MCP 服务 → 开启

> 纯本地运行（localhost:9527），数据不离开你的设备。

### 快速配置

```bash
# Claude Code
claude mcp add --transport http cherry-reader http://localhost:9527/mcp
```

应用内提供 Cursor、VS Code、Cline、Cherry Studio 等工具的一键复制配置。

### MCP Tools Reference

#### `recall_my_conversations`

回顾某段时间内聊过的内容。适合问「这周聊了什么」「最近在关注什么」。

```typescript
// 参数
{
  period?: "today" | "yesterday" | "this_week" | "this_month" | "last_7_days" | "last_30_days" | "custom",
  start_date?: string,      // period=custom 时，格式 YYYY-MM-DD
  end_date?: string,        // period=custom 时，格式 YYYY-MM-DD
  min_rounds?: number,      // 最小轮次，默认 1
  assistant_filter?: string, // 按助手名称筛选，如 "Claude GPT"
  limit?: number            // 返回数量，默认 100，最大 500
}

// 返回
{
  period: string,
  topics: [{
    topic_id: string,
    topic_name: string,
    assistant_name: string,
    round_count: number,
    user_queries: [{ round: number, query: string }]
  }]
}
```

#### `search_past_discussions`

搜索历史讨论。支持语义搜索和关键词搜索。

```typescript
// 参数
{
  query: string,            // 必填，如 "人生意义"、"职业规划"
  assistant_filter?: string,
  search_mode?: "semantic" | "keyword",  // 默认 semantic
  min_score?: number,       // 语义搜索最小相似度 0-1，默认 0.5
  time_range_days?: number, // 搜索范围（天），0=全部
  min_rounds?: number,
  limit?: number            // 默认 30
}

// 返回
{
  query: string,
  search_mode: string,
  related_topics: [{
    topic_id: string,
    topic_name: string,
    round_count: number,
    score: number | null,
    user_queries: [{ round: number, query: string }]
  }]
}
```

#### `read_conversation_detail`

读取对话详情。

```typescript
// 参数
{
  topic_id?: string,        // 与 topic_name 二选一
  topic_name?: string,      // 支持模糊匹配
  mode?: "queries_only" | "mainline" | "full",  // 默认 mainline
  start_round?: number,     // 默认 0
  round_count?: number,     // 默认 10
  include_thinking?: boolean // 是否包含 AI 思考过程，默认 false
}

// 返回
{
  topic_id: string,
  topic_name?: string,
  mode: string,
  start_round: number,
  round_count: number,
  rounds: [{
    round: number,
    messages: [{
      id: string,
      role: string,
      model: string,
      useful: boolean,
      content: string,
      created_at: string
    }]
  }]
}
```

### 使用示例

在 Cursor / Claude Code 中：

```
"帮我回顾一下这周和 Claude 聊了什么"
"之前讨论过 React 状态管理吗？找一下"
"读一下那个关于职业规划的对话"
```

## 贡献

[Issue](https://github.com/ifastcc/cherry-reader/issues) 和 PR 欢迎。

---

<div align="center">

[下载 Cherry Reader](https://apps.apple.com/cn/app/cherry-reader/id6755708214) · [Releases（桌面端）](https://github.com/ifastcc/cherry-reader/releases)

</div>
