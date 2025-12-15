<div align="center">

<img src="assets/logo.jpg" width="120" height="120" alt="Cherry Reader Logo" />

# Cherry Reader

**把 AI 对话变成知识资产**

<a href="https://apps.apple.com/cn/app/cherry-reader/id6755708214">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="50">
</a>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev/)

</div>

---

## 🎯 一句话说清楚

> **你和 AI 的每一次深度对话，都值得被沉淀、被回顾、被深化。**
>
> Cherry Reader 是 Cherry Studio 的知识管理伴侣 —— 让你的 AI 对话不再是"用完即弃"的消耗品。

---

## 😤 这些痛点你一定有

### 1. 多模型回答，根本比不过来

用 Cherry Studio 同时问 GPT、Claude、Gemini 同一个问题，结果三个模型各说各的：

```
你：@GPT-4 @Claude @Gemini 解释一下量子纠缠

GPT-4：量子纠缠是...（500字）
Claude：从物理学角度看...（800字）
Gemini：简单来说...（300字）
```

**痛点**：三个回答摊在面前，哪个更准确？有什么异同？根本没法快速对比。

**Cherry Reader 的解决方案**：

- AI 自动分析多模型回答的**共识与分歧**
- 一键生成**对比摘要**，帮你快速决策
- 支持针对某个模型的回答**继续追问**

---

### 2. 想深入讨论，却要复制大量上下文

AI 给了一个很棒的回答，你想就其中某个点深入追问。但是：

- 新开对话？上下文全丢了
- 继续追问？会打乱原来的对话主线
- 复制粘贴？太麻烦，而且容易丢失格式

**Cherry Reader 的解决方案**：

- **讨论挂载**：在任意 AI 回复下方开启独立讨论
- 讨论内容作为"元信息"保存，**不污染原对话**
- 随时回来继续，完整的上下文自动带入

---

### 3. 精彩对话，只能躺在软件里吃灰

你和 AI 聊了一个超棒的技术方案、写了一篇深度文章、讨论了一个复杂问题...

然后呢？**就这样躺在 Cherry Studio 里，再也不会打开了。**

**Cherry Reader 的解决方案**：

| 你想要的 | Cherry Reader 提供的 |
|---------|---------------------|
| 通勤时复习 | **TTS 语音朗读**，边走边听 |
| 导入阅读器 | **EPUB 导出**，适配 Apple Books / Kindle / 微信读书 |
| 标记重点 | **多色高亮标注**，像在书上做笔记 |
| 快速回顾 | **AI 自动摘要**，一眼看完核心观点 |

---

## ✨ 核心功能

<table>
<tr>
<td width="50%">

### 📖 沉浸式阅读
- 1:1 还原 Cherry Studio 对话结构
- 全屏专注模式，摒弃干扰
- 流畅渲染 500+ 消息的超长对话

</td>
<td width="50%">

### 🤖 AI 深度分析
- 多模型回答智能对比
- 自动生成对话摘要
- 上下文智能选择

</td>
</tr>
<tr>
<td>

### 🎧 TTS 语音朗读
- Azure 高质量语音
- 智能分段，标题停顿
- 边下载边播放，无需等待

</td>
<td>

### 📚 EPUB 电子书导出
- 标准格式，多端兼容
- 自动生成目录章节
- 完美保留代码块格式

</td>
</tr>
<tr>
<td>

### 🖊️ 高亮标注
- 全屏阅读模式下选中标注
- 5+ 种高亮颜色
- 本地持久化存储

</td>
<td>

### 💬 讨论挂载
- 在任意回复下展开讨论
- 不污染原对话主线
- 支持流式生成回复

</td>
</tr>
</table>

---

## 📱 下载

### iOS / iPadOS

<a href="https://apps.apple.com/cn/app/cherry-reader/id6755708214">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="40">
</a>

### 源码构建（macOS / Android）

```bash
git clone https://github.com/ifastcc/cherry-viewer.git
cd cherry-viewer/flutter_viewer
flutter pub get
flutter run -d macos  # 或 android
```

---

## 🔧 配置

在应用**设置**中配置 AI 服务（可选，用于 AI 分析功能）：

| 配置项 | 说明 |
|-------|------|
| API Key | 支持 OpenAI / Claude / 任何兼容格式 |
| Base URL | 自定义 API 地址 |
| Azure TTS | 语音朗读服务密钥 |

---

## 🗺️ 路线图

- [x] iOS App Store 上架
- [ ] Android Google Play
- [ ] macOS App Store
- [ ] 更多 AI 分析模板
- [ ] WebDAV 云同步优化

---

## 🤝 贡献

欢迎提交 [Issue](https://github.com/ifastcc/cherry-viewer/issues) 或 PR！

---

<div align="center">

**让每一段 AI 对话都值得回味**

[下载 Cherry Reader](https://apps.apple.com/cn/app/cherry-reader/id6755708214)

</div>
