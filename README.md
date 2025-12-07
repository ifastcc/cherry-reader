<div align="center">

<img src="assets/logo.jpg" width="120" height="120" alt="Cherry Viewer Logo" />

# Cherry Viewer

**Cherry Studio 聊天记录的沉浸式阅读器**

📖 导出 EPUB  •  🖊️ 智能标注  •  🤖 AI 深度分析

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)

</div>

---

## 💡 为什么需要 Cherry Viewer？

Cherry Viewer 是 **Cherry Studio** 的增强伴侣，专门解决以下痛点：

| 痛点 | Cherry Viewer 的解决方案 |
|------|-------------------------|
| **多模型回答难比较** — 同时问了 GPT、Claude、Gemini，但很难直观对比哪个答得更好 | AI 自动梳理各模型回答的异同，帮你整合多视角观点 |
| **针对性讨论太繁琐** — 想就某个回复的某个点深入追问，却要复制大量上下文 | 讨论直接挂载在对应回复上，作为元信息保存，干净整洁 |
| **精彩对话想听不想看** — 长对话用眼睛读太累，想在通勤时用耳朵听 | 内置 TTS 语音朗读，随时随地收听 AI 对话精华 |

## ✨ 核心功能

### 📖 沉浸式阅读体验
*   **完美解析**: 1:1 还原 Cherry Studio 对话结构，支持 Markdown、代码高亮和数学公式。
*   **全屏模式**: 摒弃干扰，专为长文阅读设计的清爽界面。
*   **流畅性能**: 基于 Flutter 高性能渲染，秒开超长对话记录。

### 📚 EPUB 电子书导出
*   **一键导出**: 将对话记录导出为标准的 EPUB 格式。
*   **多端同步**: 完美适配 Apple Books、Kindle、微信读书等主流阅读器。
*   **排版优化**: 自动生成目录和章节，保留代码块格式。

### 🖊️ 深度学习工具
*   **智能标注**: 像在书上做笔记一样，对关键内容进行多色高亮。
*   **AI 洞察**: (可选) 集成 AI 分析功能，自动生成对话摘要、提取关键知识点。
*   **本地存储**: 所有标注和阅读进度本地保存，隐私无忧。

## 🚀 快速开始

### 安装
```bash
git clone https://github.com/ifastcc/cherry-viewer.git
cd cherry-viewer/flutter_viewer
flutter pub get

# 运行 MacOS 版本
flutter run -d macos

# 运行 Android 版本
flutter run -d android
```

### 配置 (可选)
如需启用 AI 总结功能，请创建 `.env` 文件并配置 API Key（支持 OpenAI 格式）：
```bash
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
```

## 🤝 贡献
欢迎提交 PR 或 Issue！

---
<div align="center">
Made with ❤️ for the AI Community
</div>
