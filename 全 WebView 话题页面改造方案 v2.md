# 全 WebView 话题页面改造方案 v3.0
## 目标
将话题详情页从 Flutter 原生渲染完全改造为 WebView 渲染，最大化利用 Web 技术优势：
* ✅ 完美的文本选择体验（**WebView 原生 Selection API**，跨段落、跨 Block）
* ✅ 原生富文本复制（自动保留 HTML 格式）
* ✅ 灵活的高亮标注（CSS + JavaScript 实现）
* ✅ 与 Cherry Studio 一致的 Markdown 样式渲染
* ✅ 能量条、侧滑面板、选择菜单等**全部 Web 化**（减少通信开销）
## 核心设计原则
**极简原生，一切 Web 化**：原生只负责壳子和不可替代的能力（音频播放、页面跳转、数据持久化）
***
# 〇、关键技术选型
## 0.1 文本选择 API
**使用 WebView 原生 Selection API**（非 Flutter SelectionArea）
这是改用 WebView 的核心价值：
| 能力 | Flutter SelectionArea | WebView Selection API |
|------|----------------------|----------------------|
| 跨段落选择 | ❌ 很难 | ✅ 原生支持 |
| 获取选中坐标 | ❌ 基本不行 | ✅ `range.getBoundingClientRect()` |
| 精确 DOM 定位 | ❌ | ✅ `range.startContainer/endContainer` |
| 跨 Block 计算 | ❌ | ✅ 遍历 TreeWalker 计算 |
```js
// WebView 原生 Selection API
document.addEventListener('selectionchange', () => {
  const selection = window.getSelection();
  if (!selection.isCollapsed) {
    const range = selection.getRangeAt(0);
    const rect = range.getBoundingClientRect(); // ✅ 能拿到坐标！
    // ✅ 能精确定位 DOM 节点
  }
});
```
## 0.2 选择菜单：纯 JS 实现
**完全自定义**，不依赖系统菜单，更灵活：
```html
<div id="highlight-toolbar" class="hidden">
  <button class="color" data-color="0xFFFFF176" style="background:#FFF176"></button>
  <button class="color" data-color="0xFF81C784" style="background:#81C784"></button>
  <button class="style" data-style="underline">U̲</button>
  <button class="action copy">复制</button>
  <button class="action discuss">讨论</button>
</div>
```
优势：
* 完全自定义 UI（颜色选择器、样式切换、添加笔记）
* 响应更快（不需要跨 Flutter-JS 通信）
* 可以做复杂交互（长按预览、拖拽扩展选区等）
## 0.3 Markdown 渲染库选型
| 库 | 周下载量 | 特点 | 推荐度 |
|-----|---------|------|--------|
| **marked** | ~18M | 最流行但不安全，不遵循 CommonMark | ⭐⭐ |
| **markdown-it** | ~12M | 性能好、安全、插件扩展、CommonMark | ⭐⭐⭐⭐⭐ |
| **micromark** | ~16M | 最小最快、严格 CommonMark | ⭐⭐⭐⭐ |
| remark | - | AST 优先、学习曲线陡 | ⭐⭐⭐ |
**推荐：markdown-it**
理由：
* **安全** - 默认安全，不像 marked 有 XSS 风险
* **插件系统成熟** - 方便扩展（KaTeX、自定义容器）
* **100% CommonMark 兼容**
* **性能优秀** - 解析速度快，适合大文档
* **自定义 Renderer** - 可注入 Block 索引
```js
// markdown-it 自定义渲染器
const md = markdownit({ html: true, linkify: true });
let blockIndex = 0;
md.renderer.rules.paragraph_open = () => `<p data-block-index="${blockIndex++}">`;
md.renderer.rules.heading_open = (tokens, idx) => {
  const level = tokens[idx].tag;
  return `<${level} data-block-index="${blockIndex++}">`;
};
```
## 0.4 代码高亮库选型
| 库 | 体积 | 语言数 | 特点 | 推荐度 |
|-----|------|--------|------|--------|
| **highlight.js** | ~30KB core | 185+ | 自动检测、简单 | ⭐⭐⭐⭐ |
| **Prism.js** | ~2KB core | 300+ | 模块化、更轻量 | ⭐⭐⭐⭐⭐ |
| Shiki | ~500KB | VSCode 主题 | 最精确、较重 | ⭐⭐⭐ |
**推荐：Prism.js**
理由：
* 核心只有 2KB，按需加载语言
* 插件系统（行号、行高亮、复制按钮）
* 性能比 highlight.js 快 ~9%
* 更精确的语法高亮
## 0.5 WebView 引入第三方库：完全合适
**为什么可以用第三方库？**
* WebView 本质就是一个浏览器，与普通 Web 开发无异
* 成熟库的兼容性、性能、边界处理都比自己实现好
* 可以本地打包（放入 assets），无需网络请求
**库的引入方式**：
```html
<!-- 方式 1：本地 assets（推荐，离线可用） -->
<script src="./vendor/markdown-it.min.js"></script>
<script src="./vendor/prism-core.min.js"></script>
<script src="./vendor/prism-autoloader.min.js"></script>
<!-- 方式 2：CDN（备选，需网络） -->
<script src="https://cdn.jsdelivr.net/npm/markdown-it/dist/markdown-it.min.js"></script>
```
***
# 一、整体架构
## 1.1 页面结构
```warp-runnable-command
┌─────────────────────────────────────┐
│        InAppWebView (100vh)          │
│  ┌───────────────────────────────┐  │
│  │   [Sticky Header: Tab Bar]    │  │  ← position: sticky
│  ├───────────────────────────────┤  │
│  │                               │  │
│  │   轮次卡片 × N                │  │  ← 虚拟滚动/分页加载
│  │   ├─ 问题区 (Q标记 + 内容)    │  │
│  │   └─ 回复区 (Tab + Swiper)    │  │
│  │                               │  │
│  ├───────────────────────────────┤  │
│  │   [能量条] (右侧固定)         │  │  ← position: fixed
│  │   [侧滑抽屉] (右侧隐藏)       │  │  ← transform: translateX
│  │   [TTS Mini Player] (底部)    │  │  ← position: fixed
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```
## 1.2 通信架构
```warp-runnable-command
┌─────────────────┐     JSON/Call     ┌──────────────────┐
│                 │ ═══════════════►  │                  │
│   Flutter       │                   │   WebView (JS)   │
│   (Native)      │ ◄═══════════════  │                  │
│                 │   FlutterBridge   │                  │
└─────────────────┘                   └──────────────────┘
        │                                     │
        ▼                                     ▼
   原生功能：                            Web 渲染：
   - TTS 播放                           - Markdown 渲染
   - 页面跳转                           - 高亮标注
   - 数据持久化                         - Tab 切换
   - Toast 提示                         - 能量条
                                        - 侧滑抽屉
                                        - 搜索高亮
```
***
# 二、数据传递方案
## 2.0 数据传递方案对比
| 方案 | 原理 | 优势 | 劣势 | 推荐度 |
|------|------|------|------|--------|
| **A. JSON 注入** | Flutter 组装 JSON，通过 `evaluateJavascript` 注入 | 简单直接、离线可用、Flutter 完全控制 | 大数据可能卡顿 | ⭐⭐⭐⭐⭐ |
| B. Local HTTP Server | Flutter 启动本地服务器，WebView 通过 fetch 获取 | 天然支持分页 | 实现复杂、需管理生命周期 | ⭐⭐ |
| C. 预生成 HTML | Flutter 预先生成完整 HTML 文件 | 加载最快 | 无法动态更新、高亮更新麻烦 | ⭐⭐⭐ |
| D. JS 直读数据库 | 暴露 SQLite/Isar 接口给 JS | 数据实时性最好 | 架构混乱、安全风险 | ⭐ |
**推荐：A. JSON 注入 + 分批加载**
```dart
// Flutter 端
// 第一步：注入首屏数据（前 3 轮）
final initialData = {
  'topicId': topicId,
  'totalRounds': groups.length,
  'rounds': groups.take(3).map((g) => convertGroup(g)).toList(),
  'highlights': highlightMap,
};
webViewController.evaluateJavascript(
  source: 'window.initConversation(${jsonEncode(initialData)})'
);
// 第二步：WebView 请求更多数据时，Flutter 响应
webViewController.addJavaScriptHandler(
  handlerName: 'requestRounds',
  callback: (args) async {
    final indices = (args[0]['indices'] as List).cast<int>();
    final rounds = await loadRounds(indices);
    return jsonEncode(rounds);
  },
);
```
```js
// JS 端：滚动时请求更多轮次
async function loadMoreRounds(indices) {
  const data = await window.flutter_inappwebview.callHandler('requestRounds', { indices });
  appendRounds(JSON.parse(data));
}
```
## 2.1 初始化数据 (Flutter → JS)
```js
window.initConversation({
  // 元信息
  topicId: 'topic-xxx',
  topicName: '关于 AI 的讨论',
  isDarkMode: true,
  
  // 初始状态
  scrollToRoundIndex: null,
  scrollToMessageId: null,
  scrollToHighlightId: null,
  searchKeyword: '',
  
  // 对话数据（首屏 3 轮）
  totalRounds: 25,
  rounds: [
    {
      index: 0,
      userMessage: {
        id: 'msg-user-001',
        content: '用户问题的 Markdown 内容',
      },
      assistantReplies: [
        {
          id: 'msg-assistant-001',
          modelName: 'Claude 3.5 Sonnet',
          modelId: 'claude-3-5-sonnet',
          content: 'AI 回复的 Markdown 内容',
          isMainline: true,  // useful 字段
        },
        {
          id: 'msg-assistant-002',
          modelName: 'GPT-4o',
          modelId: 'gpt-4o',
          content: '另一个 AI 的回复',
          isMainline: false,
        },
      ],
      // 该轮次的高亮数据（v3.0 结构）
      highlights: {
        'msg-assistant-001': [
          {
            id: 'hl-001',
            messageId: 'msg-assistant-001',
            text: '高亮的文本',
            color: '#FFF176',              // CSS 十六进制
            style: 'background',
            ranges: [
              { blockIndex: 2, start: 10, end: 20, text: '高亮的文本' },
            ],
            prefix: '前面的一些内容用于恢复',
            suffix: '后面的一些内容用于恢复',
            createdAt: '2024-01-16T02:00:00Z',
          },
        ],
      },
    },
    // ... 更多轮次
  ],
});
```
## 2.2 增量加载 (Flutter → JS)
```js
// 懒加载更多轮次
window.appendRounds([
  { index: 3, userMessage: {...}, assistantReplies: [...], highlights: {...} },
  { index: 4, ... },
]);
```
## 2.3 状态更新 (Flutter → JS)
```js
window.setDarkMode(true);                    // 暗色模式
window.scrollToRound(5);                     // 跳转轮次
window.scrollToHighlight('hl-xxx');          // 跳转高亮
window.setSearchKeyword('关键词');            // 搜索高亮
window.updateHighlight('hl-xxx', {...});     // 更新高亮样式
三、JS → Flutter 通信协议
```
## 3.1 Bridge 接口定义
```js
const FlutterBridge = {
  // ========== 页面事件 ==========
  onContentReady(data) {
    // data: { scrollHeight, roundCount }
  },
  
  onScrollChanged(data) {
    // data: { currentRound, progress, isTabVisible }
    // 用于同步原生状态（如果需要）
  },
  
  // ========== 用户交互 ==========
  onTabChanged(data) {
    // data: { roundIndex, replyIndex, modelName }
  },
  
  onTextSelected(data) {
    // data: { 
    //   text, hasSelection, 
    //   roundIndex, replyIndex, messageId,
    //   rect: { x, y, width, height },
    //   // 新架构：支持跨 Block 选择
    //   selections: [{ blockIndex, internalStart, internalEnd, text }]
    // }
  },
  
  // ========== 高亮操作 ==========
  onHighlightCreated(data) {
    // data: {
    //   id, text, messageId, color, styleType,
    //   selections: [...],
    //   prefix, suffix
    // }
  },
  
  onHighlightTapped(data) {
    // data: { highlightId, messageId, rect: {...} }
  },
  
  onHighlightUpdated(data) {
    // data: { highlightId, messageId, color, styleType }
  },
  
  onHighlightDeleted(data) {
    // data: { highlightId, messageId }
  },
  
  // ========== 原生功能调用 ==========
  playTTS(data) {
    // data: { roundIndex, messageId? }
  },
  
  openDiscussion(data) {
    // data: { roundIndex, contextId }
  },
  
  showToast(data) {
    // data: { message, type: 'success'|'error'|'info' }
  },
  
  copyToClipboard(data) {
    // data: { text, html?, showToast: true }
  },
};
```
***
# 四、HTML/CSS 布局实现
## 4.1 HTML 结构
```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <link rel="stylesheet" href="conversation.css">
  <link rel="stylesheet" href="highlight.css">
</head>
<body class="theme-light">
  <!-- Sticky Tab Bar (当内联 Tab 滚出时显示) -->
  <header id="sticky-header" class="hidden">
    <span class="round-label">Q1</span>
    <div class="tab-list"></div>
  </header>
  <!-- 主内容区 -->
  <main id="conversation-container">
    <!-- 轮次卡片通过 JS 动态生成 -->
  </main>
  <!-- 能量条 (固定右侧) -->
  <aside id="energy-bar">
    <!-- 动态生成 -->
  </aside>
  <!-- 侧滑抽屉 -->
  <aside id="edge-drawer" class="closed">
    <div class="drawer-trigger"></div>
    <div class="drawer-content">
      <button class="nav-btn up">▲</button>
      <div class="round-indicator">1/25</div>
      <button class="nav-btn down">▼</button>
      <hr>
      <button class="action-btn tts">🎧 朗读</button>
      <button class="action-btn discuss">💬 讨论</button>
    </div>
  </aside>
  <!-- TTS Mini Player -->
  <footer id="tts-player" class="hidden">
    <div class="player-content">
      <span class="title">正在朗读...</span>
      <div class="controls">
        <button class="prev">⏮</button>
        <button class="play-pause">⏸</button>
        <button class="next">⏭</button>
      </div>
      <button class="close">✕</button>
    </div>
  </footer>
  <!-- 高亮工具栏 (选中文本时显示) -->
  <div id="highlight-toolbar" class="hidden">
    <button class="color" data-color="0xFFFFF176" style="background:#FFF176"></button>
    <button class="color" data-color="0xFF81C784" style="background:#81C784"></button>
    <button class="color" data-color="0xFF64B5F6" style="background:#64B5F6"></button>
    <button class="color" data-color="0xFFE57373" style="background:#E57373"></button>
    <button class="style" data-style="underline">U̲</button>
  </div>
  <script src="marked.min.js"></script>
  <script src="highlight.min.js"></script>
  <script src="conversation.js"></script>
  <script src="highlight-manager.js"></script>
</body>
</html>
```
## 4.2 轮次卡片 HTML 模板
```html
<article class="round-card" data-round-index="0">
  <!-- 问题区 -->
  <section class="question-section">
    <div class="color-bar"></div>
    <div class="content">
      <span class="q-label">Q1</span>
      <div class="question-text" data-message-id="msg-user-001">
        <!-- Markdown 渲染后的 HTML -->
      </div>
    </div>
  </section>
  
  <!-- 回复区 -->
  <section class="reply-section">
    <!-- Tab 选择器 -->
    <div class="tab-bar" data-round-index="0">
      <button class="tab active" data-index="0" data-model="claude-3-5">
        <span class="model-dot" style="background:#8B5CF6"></span>
        <span class="model-name">Claude 3.5</span>
        <span class="mainline-badge">★</span>
      </button>
      <button class="tab" data-index="1" data-model="gpt-4o">
        <span class="model-dot" style="background:#10B981"></span>
        <span class="model-name">GPT-4o</span>
      </button>
    </div>
    
    <!-- 回复内容 (Swiper) -->
    <div class="reply-swiper">
      <div class="swiper-wrapper">
        <div class="swiper-slide active" data-message-id="msg-assistant-001">
          <div class="markdown-body">
            <!-- Markdown 渲染后的 HTML + 高亮标记 -->
          </div>
        </div>
        <div class="swiper-slide" data-message-id="msg-assistant-002">
          <div class="markdown-body">
            <!-- ... -->
          </div>
        </div>
      </div>
    </div>
  </section>
</article>
```
## 4.3 核心 CSS
```css
/* ========== 主题变量 ========== */
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
  --text-primary: #1a1a1a;
  --text-secondary: #666666;
  --border-color: #e0e0e0;
  --question-color: #6366F1;
  --energy-bar-width: 6px;
}
.theme-dark {
  --bg-primary: #1a1a1a;
  --bg-secondary: #2d2d2d;
  --text-primary: #e0e0e0;
  --text-secondary: #999999;
  --border-color: #404040;
}
/* ========== 布局 ========== */
body {
  margin: 0;
  padding: 0;
  background: var(--bg-secondary);
  color: var(--text-primary);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  -webkit-tap-highlight-color: transparent;
}
#conversation-container {
  padding: 16px 12px 80px 12px;
  padding-right: calc(12px + var(--energy-bar-width) + 4px); /* 为能量条留空 */
}
/* ========== Sticky Header ========== */
#sticky-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--bg-primary);
  padding: 8px 16px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.06);
  display: flex;
  align-items: center;
  gap: 12px;
  transition: transform 0.2s, opacity 0.2s;
}
#sticky-header.hidden {
  transform: translateY(-100%);
  opacity: 0;
  pointer-events: none;
}
/* ========== 轮次卡片 ========== */
.round-card {
  background: var(--bg-primary);
  border-radius: 16px;
  border: 1px solid var(--border-color);
  margin-bottom: 24px;
  overflow: hidden;
  contain: layout style paint; /* 性能优化 */
}
.question-section {
  display: flex;
  background: color-mix(in srgb, var(--question-color) 5%, transparent);
}
.question-section .color-bar {
  width: 4px;
  background: var(--question-color);
  flex-shrink: 0;
}
.question-section .content {
  flex: 1;
  padding: 12px 14px;
}
.q-label {
  display: inline-block;
  padding: 4px 8px;
  background: color-mix(in srgb, var(--question-color) 12%, transparent);
  color: var(--question-color);
  border-radius: 6px;
  font-size: 12px;
  font-weight: 700;
  margin-bottom: 8px;
}
/* ========== Tab 选择器 ========== */
.tab-bar {
  display: flex;
  gap: 4px;
  padding: 10px 8px;
  overflow-x: auto;
  scrollbar-width: none;
}
.tab-bar::-webkit-scrollbar { display: none; }
.tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border: none;
  background: transparent;
  border-radius: 8px;
  font-size: 13px;
  color: var(--text-secondary);
  white-space: nowrap;
  cursor: pointer;
  transition: all 0.2s;
}
.tab.active {
  background: color-mix(in srgb, var(--model-color, #8B5CF6) 15%, transparent);
  color: var(--text-primary);
  font-weight: 600;
}
.model-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}
.mainline-badge {
  color: #F59E0B;
  font-size: 10px;
}
/* ========== Swiper 内容区 ========== */
.reply-swiper {
  overflow: hidden;
}
.swiper-wrapper {
  display: flex;
  transition: transform 0.3s ease-out;
}
.swiper-slide {
  flex: 0 0 100%;
  min-width: 100%;
  padding: 0 14px 14px;
  box-sizing: border-box;
}
/* ========== 能量条 ========== */
#energy-bar {
  position: fixed;
  right: 0;
  top: 60px;
  bottom: 80px;
  width: var(--energy-bar-width);
  display: flex;
  flex-direction: column;
  z-index: 50;
}
.energy-cell {
  flex: 1;
  position: relative;
  cursor: pointer;
  border-bottom: 1px solid var(--bg-primary);
}
.energy-cell:last-child { border-bottom: none; }
.energy-cell .empty {
  position: absolute;
  inset: 0;
  opacity: 0.25;
}
.energy-cell .fill {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 0;
  transition: height 0.15s ease-out;
}
/* ========== 侧滑抽屉 ========== */
#edge-drawer {
  position: fixed;
  right: 0;
  bottom: 100px;
  display: flex;
  z-index: 60;
  transition: transform 0.2s ease-out;
}
#edge-drawer.closed {
  transform: translateX(calc(100% - 18px));
}
.drawer-trigger {
  width: 18px;
  height: 48px;
  background: var(--bg-primary);
  border-radius: 10px 0 0 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: -2px 0 6px rgba(0,0,0,0.08);
}
.drawer-content {
  background: var(--bg-primary);
  padding: 10px 8px;
  border-radius: 14px 0 0 14px;
  box-shadow: -3px 0 10px rgba(0,0,0,0.12);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}
```
***
# 五、高亮系统实现
## 5.0 高亮数据结构重构
### 5.0.1 新数据结构设计 (v3.0)
**设计原则**：
* 简化字段，移除冗余
* 统一颜色格式为 CSS 兼容的十六进制字符串
* 保留 Block 概念但简化命名
* 不兼容旧数据，重新设计
```ts
// ========== 新版高亮数据结构 (WebView 优先) ==========
interface Highlight {
  id: string;                    // UUID
  messageId: string;             // 关联的消息 ID
  text: string;                  // 完整高亮文本
  color: string;                 // CSS 颜色 '#FFF176'（不含透明度）
  style: 'background' | 'underline' | 'wavy' | 'box' | 'dashed';  // 样式类型
  // 定位信息：每个 Block 内的范围
  ranges: HighlightRange[];
  // 恢复上下文（fallback 用）
  prefix: string;                // 前 50 字符
  suffix: string;                // 后 50 字符
  // 元数据
  createdAt: string;             // ISO 时间戳
}
interface HighlightRange {
  blockIndex: number;            // Block 索引
  start: number;                 // Block 内起始偏移
  end: number;                   // Block 内结束偏移
  text: string;                  // 该范围的文本（用于验证）
}
```
### 5.0.2 Flutter 端数据模型重构
```dart
// lib/models/highlight_data.dart
/// 高亮范围（单个 Block 内）
class HighlightRange {
  final int blockIndex;
  final int start;
  final int end;
  final String text;
  HighlightRange({
    required this.blockIndex,
    required this.start,
    required this.end,
    required this.text,
  });
  Map<String, dynamic> toJson() => {
    'blockIndex': blockIndex,
    'start': start,
    'end': end,
    'text': text,
  };
  factory HighlightRange.fromJson(Map<String, dynamic> json) => HighlightRange(
    blockIndex: json['blockIndex'] as int,
    start: json['start'] as int,
    end: json['end'] as int,
    text: json['text'] as String,
  );
}
/// 高亮数据模型 v3.0
class HighlightData {
  final String id;
  final String messageId;
  final String text;
  final String color;            // CSS 十六进制 '#FFF176'
  final String style;            // 'background' | 'underline' | 'wavy' | 'box' | 'dashed'
  final List<HighlightRange> ranges;
  final String prefix;
  final String suffix;
  final DateTime createdAt;
  HighlightData({
    String? id,
    required this.messageId,
    required this.text,
    required this.color,
    this.style = 'background',
    required this.ranges,
    this.prefix = '',
    this.suffix = '',
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
    'id': id,
    'messageId': messageId,
    'text': text,
    'color': color,
    'style': style,
    'ranges': ranges.map((r) => r.toJson()).toList(),
    'prefix': prefix,
    'suffix': suffix,
    'createdAt': createdAt.toIso8601String(),
  };
  factory HighlightData.fromJson(Map<String, dynamic> json) => HighlightData(
    id: json['id'] as String?,
    messageId: json['messageId'] as String,
    text: json['text'] as String,
    color: json['color'] as String,
    style: json['style'] as String? ?? 'background',
    ranges: (json['ranges'] as List).map((e) => 
      HighlightRange.fromJson(e as Map<String, dynamic>)
    ).toList(),
    prefix: json['prefix'] as String? ?? '',
    suffix: json['suffix'] as String? ?? '',
    createdAt: json['createdAt'] != null
      ? DateTime.parse(json['createdAt'] as String)
      : null,
  );
}
```
### 5.0.3 数据库存储重构
```dart
// lib/models/isar/knowledge_entry.dart 修改
@collection
class KnowledgeEntry {
  // ... 其他字段保持不变 ...
  /// 高亮颜色（CSS 十六进制格式 '#FFF176'）
  String? color;
  /// 样式类型 'background' | 'underline' | 'wavy' | 'box' | 'dashed'
  String? styleType;
  /// 高亮范围 JSON字符串
  /// 格式: [{"blockIndex":0,"start":10,"end":20,"text":"..."}]
  String? ranges;
  /// 恢复上下文
  String? prefix;  // 前 50 字符
  String? suffix;  // 后 50 字符
  // ❗移除废弃字段：
  // - start / end（全局偏移在 WebView 中无用）
  // - blockIndex / blockInternalStart / blockInternalEnd（改用 ranges）
  // - blockContentHash（不再需要）
  // - groupId（废弃）
  // - selections（改用 ranges，命名更清晰）
}
```
### 5.0.4 新旧数据对比
| 旧字段 | 新字段 | 说明 |
|--------|--------|------|
| `color: int (0xFFFFF176)` | `color: string ('#FFF176')` | CSS 友好，无需转换 |
| `styleType` | `style` | 简化命名 |
| `selections` | `ranges` | 更清晰的命名 |
| `internalStart/internalEnd` | `start/end` | 在 range 内已隐含 "Block 内" |
| `start/end (全局)` | 移除 | WebView 中不需要 |
| `blockContentHash` | 移除 | 改用 text 验证 |
| `groupId` | 移除 | 废弃概念 |
| `globalStart/globalEnd` | 移除 | 用 prefix/suffix 替代 |
## 5.1 高亮数据示例
```js
// 单个高亮示例
const highlight = {
  id: 'hl-a1b2c3d4',
  messageId: 'msg-assistant-001',
  text: '这是被高亮的文本',
  color: '#FFF176',              // 黄色
  style: 'background',
  ranges: [
    { blockIndex: 2, start: 10, end: 22, text: '这是被高亮的文本' },
  ],
  prefix: '前面的一些文本内容用于恢复定位',
  suffix: '后面的一些文本内容用于恢复定位',
  createdAt: '2024-01-16T02:00:00Z',
};
// 跨 Block 高亮示例
const crossBlockHighlight = {
  id: 'hl-e5f6g7h8',
  messageId: 'msg-assistant-001',
  text: '段落尾部...\n列表开头',
  color: '#81C784',              // 绿色
  style: 'underline',
  ranges: [
    { blockIndex: 1, start: 50, end: 60, text: '段落尾部...' },
    { blockIndex: 2, start: 0, end: 8, text: '列表开头' },
  ],
  prefix: '前置文本',
  suffix: '后置文本',
  createdAt: '2024-01-16T02:05:00Z',
};
```
## 5.2 Markdown → HTML 渲染 + Block 索引
```js
// 核心：渲染 Markdown 时为每个 Block 添加 data-block-index
function renderMarkdown(content, messageId) {
  // 使用 marked.js 自定义 renderer
  const renderer = new marked.Renderer();
  let blockIndex = 0;
  
  // 为每个段落添加 Block 标记
  renderer.paragraph = (text) => {
    return `<p data-block-index="${blockIndex++}">${text}</p>`;
  };
  
  renderer.heading = (text, level) => {
    return `<h${level} data-block-index="${blockIndex++}">${text}</h${level}>`;
  };
  
  renderer.listitem = (text) => {
    return `<li data-block-index="${blockIndex++}">${text}</li>`;
  };
  
  renderer.code = (code, language) => {
    const highlighted = hljs.highlightAuto(code, [language]).value;
    return `<pre data-block-index="${blockIndex++}"><code class="hljs language-${language}">${highlighted}</code></pre>`;
  };
  
  return marked.parse(content, { renderer });
}
```
## 5.3 高亮恢复：HTML 注入
```js
// 恢复高亮：在渲染后的 HTML 中注入 <mark> 标签
function applyHighlights(containerEl, highlights) {
  for (const hl of highlights) {
    for (const sel of hl.selections) {
      // 1. 找到对应的 Block 元素
      const blockEl = containerEl.querySelector(`[data-block-index="${sel.blockIndex}"]`);
      if (!blockEl) continue;
      
      // 2. 在 Block 内定位并包裹文本
      wrapTextRange(blockEl, sel.internalStart, sel.internalEnd, {
        tagName: 'mark',
        className: `highlight hl-${hl.styleType}`,
        attributes: {
          'data-highlight-id': hl.id,
          'data-message-id': containerEl.dataset.messageId,
          'style': `--hl-color: ${intColorToRgba(hl.color)}`,
        },
      });
    }
  }
}
// 核心算法：在 DOM 中按文本偏移包裹指定范围
function wrapTextRange(rootEl, start, end, options) {
  const walker = document.createTreeWalker(rootEl, NodeFilter.SHOW_TEXT);
  let currentOffset = 0;
  const nodesToWrap = [];
  
  while (walker.nextNode()) {
    const node = walker.currentNode;
    const nodeLength = node.textContent.length;
    const nodeStart = currentOffset;
    const nodeEnd = currentOffset + nodeLength;
    
    // 计算与目标范围的交集
    const overlapStart = Math.max(start, nodeStart);
    const overlapEnd = Math.min(end, nodeEnd);
    
    if (overlapStart < overlapEnd) {
      nodesToWrap.push({
        node,
        start: overlapStart - nodeStart,
        end: overlapEnd - nodeStart,
      });
    }
    
    currentOffset = nodeEnd;
    if (currentOffset >= end) break;
  }
  
  // 倒序处理，避免偏移变化
  for (let i = nodesToWrap.length - 1; i >= 0; i--) {
    const { node, start: s, end: e } = nodesToWrap[i];
    const range = document.createRange();
    range.setStart(node, s);
    range.setEnd(node, e);
    
    const wrapper = document.createElement(options.tagName);
    wrapper.className = options.className;
    for (const [k, v] of Object.entries(options.attributes || {})) {
      wrapper.setAttribute(k, v);
    }
    range.surroundContents(wrapper);
  }
}
```
## 5.4 高亮样式 CSS
```css
/* ========== 高亮样式 ========== */
mark.highlight {
  --hl-color: rgba(255, 241, 118, 0.6);
  background: transparent;
  padding: 0;
  cursor: pointer;
  transition: filter 0.2s;
}
mark.highlight:hover {
  filter: brightness(0.95);
}
/* 背景高亮 */
mark.hl-background {
  background: var(--hl-color);
  border-radius: 2px;
}
/* 下划线高亮 */
mark.hl-underline {
  text-decoration: underline;
  text-decoration-color: var(--hl-color);
  text-decoration-thickness: 2px;
  text-underline-offset: 2px;
}
/* 波浪线高亮 */
mark.hl-wavy {
  text-decoration: underline wavy;
  text-decoration-color: var(--hl-color);
  text-underline-offset: 2px;
}
/* 边框高亮 */
mark.hl-box {
  border: 2px solid var(--hl-color);
  border-radius: 3px;
  padding: 0 2px;
  margin: 0 1px;
}
/* 虚线下划线高亮 */
mark.hl-dashed {
  text-decoration: underline dashed;
  text-decoration-color: var(--hl-color);
  text-decoration-thickness: 2px;
  text-underline-offset: 2px;
}
/* 高亮闪烁动画（跳转定位时） */
mark.highlight.flash {
  animation: highlight-flash 1.5s ease-out;
}
@keyframes highlight-flash {
  0%, 100% { filter: brightness(1); }
  25%, 75% { filter: brightness(1.3); box-shadow: 0 0 8px var(--hl-color); }
}
```
## 5.5 创建高亮：文本选择处理
```js
// 监听文本选择
document.addEventListener('selectionchange', debounce(() => {
  const selection = window.getSelection();
  if (!selection || selection.isCollapsed) {
    hideHighlightToolbar();
    return;
  }
  
  const range = selection.getRangeAt(0);
  const text = selection.toString().trim();
  if (!text) return;
  
  // 找到所属的消息容器
  const messageEl = range.commonAncestorContainer.closest?.('[data-message-id]')
    || range.commonAncestorContainer.parentElement?.closest('[data-message-id]');
  if (!messageEl) return;
  
  // 收集选区信息（支持跨 Block）
  const selections = collectSelections(messageEl, range);
  
  // 计算工具栏位置
  const rect = range.getBoundingClientRect();
  showHighlightToolbar(rect, {
    text,
    messageId: messageEl.dataset.messageId,
    roundIndex: messageEl.closest('.round-card').dataset.roundIndex,
    selections,
  });
}, 100));
// 收集跨 Block 的选区信息
function collectSelections(messageEl, range) {
  const selections = [];
  const walker = document.createTreeWalker(messageEl, NodeFilter.SHOW_TEXT);
  const blocks = messageEl.querySelectorAll('[data-block-index]');
  
  // 为每个 Block 计算内部偏移
  for (const block of blocks) {
    const blockIndex = parseInt(block.dataset.blockIndex);
    const blockRange = document.createRange();
    blockRange.selectNodeContents(block);
    
    // 判断 range 是否与该 Block 有交集
    if (range.compareBoundaryPoints(Range.END_TO_START, blockRange) < 0 &&
        range.compareBoundaryPoints(Range.START_TO_END, blockRange) > 0) {
      
      // 计算交集的内部偏移
      const { start, end, text } = getInternalOffset(block, range);
      if (start < end) {
        selections.push({
          blockIndex,
          internalStart: start,
          internalEnd: end,
          text,
        });
      }
    }
  }
  
  return selections;
}
// 计算选区在 Block 内的偏移
function getInternalOffset(blockEl, selectionRange) {
  const blockRange = document.createRange();
  blockRange.selectNodeContents(blockEl);
  
  // 计算起始偏移
  const startRange = document.createRange();
  startRange.setStart(blockEl, 0);
  startRange.setEnd(
    selectionRange.startContainer.compareDocumentPosition(blockEl) & Node.DOCUMENT_POSITION_CONTAINS
      ? selectionRange.startContainer
      : blockEl,
    selectionRange.startContainer.compareDocumentPosition(blockEl) & Node.DOCUMENT_POSITION_CONTAINS
      ? selectionRange.startOffset
      : 0
  );
  const start = startRange.toString().length;
  
  // 类似计算结束偏移...
  const end = start + selectionRange.toString().length;
  
  return { start, end, text: selectionRange.toString() };
}
```
## 5.6 高亮点击处理
```js
// 事件委托：监听高亮点击
document.addEventListener('click', (e) => {
  const highlightEl = e.target.closest('mark.highlight');
  if (!highlightEl) return;
  
  e.preventDefault();
  e.stopPropagation();
  
  const highlightId = highlightEl.dataset.highlightId;
  const messageId = highlightEl.dataset.messageId;
  const rect = highlightEl.getBoundingClientRect();
  
  // 通知 Flutter
  FlutterBridge.onHighlightTapped({
    highlightId,
    messageId,
    rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
  });
});
```
## 5.7 高亮实时更新（局部 DOM 操作）
**核心思路**：不重新渲染整个页面，只操作相关 DOM 节点
```js
// ========== 添加高亮 ==========
function addHighlightInPlace(messageId, highlight) {
  const container = document.querySelector(`[data-message-id="${messageId}"] .markdown-body`);
  if (!container) return;
  
  // 直接在现有 DOM 上包裹 <mark>
  for (const sel of highlight.selections) {
    const block = container.querySelector(`[data-block-index="${sel.blockIndex}"]`);
    if (!block) continue;
    
    wrapTextRange(block, sel.internalStart, sel.internalEnd, {
      tagName: 'mark',
      className: `highlight hl-${highlight.styleType}`,
      attributes: {
        'data-highlight-id': highlight.id,
        'data-message-id': messageId,
        'style': `--hl-color: ${intColorToRgba(highlight.color)}`,
      },
    });
  }
}
// ========== 删除高亮 ==========
function removeHighlightInPlace(highlightId) {
  // 找到所有相关的 <mark> 标签
  const marks = document.querySelectorAll(`mark[data-highlight-id="${highlightId}"]`);
  
  marks.forEach(mark => {
    // 保留内容，移除 <mark> 包裹
    const parent = mark.parentNode;
    while (mark.firstChild) {
      parent.insertBefore(mark.firstChild, mark);
    }
    parent.removeChild(mark);
    // 合并相邻文本节点
    parent.normalize();
  });
}
// ========== 更新高亮样式 ==========
function updateHighlightStyle(highlightId, newColor, newStyleType) {
  const marks = document.querySelectorAll(`mark[data-highlight-id="${highlightId}"]`);
  
  marks.forEach(mark => {
    // 移除旧样式类
    mark.classList.remove('hl-background', 'hl-underline', 'hl-wavy', 'hl-box', 'hl-dashed');
    // 添加新样式类
    mark.classList.add(`hl-${newStyleType}`);
    // 更新颜色
    mark.style.setProperty('--hl-color', intColorToRgba(newColor));
  });
}
// ========== 跳转到高亮并闪烁 ==========
function scrollToHighlightAndFlash(highlightId) {
  const mark = document.querySelector(`mark[data-highlight-id="${highlightId}"]`);
  if (!mark) return;
  
  // 滚动到可视区域
  mark.scrollIntoView({ behavior: 'smooth', block: 'center' });
  
  // 添加闪烁动画
  mark.classList.add('flash');
  setTimeout(() => mark.classList.remove('flash'), 1500);
}
```
## 5.8 高亮恢复策略（多级 Fallback）
**问题**：如果 Markdown 内容变化，Block 索引可能失效
```js
// 多级恢复策略
function recoverHighlight(container, highlight) {
  // 策略 1：Block 索引 + 内部偏移（最快）
  if (highlight.selections?.length > 0) {
    const success = tryBlockBasedRecovery(container, highlight);
    if (success) return true;
  }
  
  // 策略 2：前后文语义匹配
  if (highlight.prefix && highlight.suffix) {
    const success = tryContextBasedRecovery(container, highlight);
    if (success) return true;
  }
  
  // 策略 3：模糊文本搜索（Fallback）
  return tryFuzzyTextRecovery(container, highlight);
}
// Block 索引恢复
function tryBlockBasedRecovery(container, highlight) {
  for (const sel of highlight.selections) {
    const block = container.querySelector(`[data-block-index="${sel.blockIndex}"]`);
    if (!block) return false;
    
    // 验证文本匹配
    const blockText = block.textContent;
    const actualText = blockText.substring(sel.internalStart, sel.internalEnd);
    if (actualText !== sel.text) return false;
  }
  
  // 匹配成功，应用高亮
  applyHighlights(container, [highlight]);
  return true;
}
// 前后文语义匹配
function tryContextBasedRecovery(container, highlight) {
  const fullText = container.textContent;
  const searchStr = (highlight.prefix || '') + highlight.text + (highlight.suffix || '');
  const idx = fullText.indexOf(searchStr);
  
  if (idx === -1) return false;
  
  const start = idx + (highlight.prefix?.length || 0);
  const end = start + highlight.text.length;
  
  // 在容器中包裹文本
  wrapTextRangeGlobal(container, start, end, {
    tagName: 'mark',
    className: `highlight hl-${highlight.styleType}`,
    attributes: {
      'data-highlight-id': highlight.id,
      'style': `--hl-color: ${intColorToRgba(highlight.color)}`,
    },
  });
  return true;
}
```
## 5.9 关于 "Block" 概念的澄清
**Block 是我们自己定义的概念**，用于高亮定位，不是第三方库的概念。
**为什么需要 Block？**
* Markdown 渲染后的 HTML 结构可能比较复杂（嵌套 `<strong>`、`<em>` 等）
* 全局文本偏移会因为 HTML 标签而不稳定
* Block 级别的偏移更可靠，即使前面段落变化也不影响
**Block 的实现**：
```warp-runnable-command
Markdown 源文本                    渲染后的 HTML
────────────────────                ────────────────────
# 标题                            <h1 data-block-index="0">标题</h1>
这是一个段落。                     <p data-block-index="1">这是一个段落。</p>
- 列表项1                          <ul>
- 列表项2                            <li data-block-index="2">列表项1</li>
                                      <li data-block-index="3">列表项2</li>
                                    </ul>
```
**跨 Block 选择怎么处理？**
* 用户选择跨越多个 Block 的文本时，`collectSelections()` 会为每个 Block 生成独立的 selection
* 每个 selection 包含 `blockIndex` + `internalStart` + `internalEnd`
* 恢复时，每个 Block 独立注入 `<mark>` 标签
```js
// 跨 Block 高亮示例
highlight = {
  id: 'hl-001',
  text: '段落尾部...\n列表开头',  // 完整文本（包含换行）
  selections: [
    { blockIndex: 1, internalStart: 10, internalEnd: 20, text: '段落尾部...' },
    { blockIndex: 2, internalStart: 0, internalEnd: 8, text: '列表开头' },
  ],
};
```
## 5.10 搜索高亮（与存储高亮的区分）
### 5.10.1 两种高亮的对比
| 特性 | 存储高亮 (Highlight) | 搜索高亮 (Search Match) |
|------|------------------------|---------------------------|
| **生命周期** | 持久化到数据库 | 临时，关闭搜索后消失 |
| **创建方式** | 用户主动选中文本 | 自动匹配关键词 |
| **数量** | 用户控制，通常较少 | 可能很多（所有匹配项） |
| **样式** | 多色彩、多样式（背景/下划线/波浪线等） | 固定样式（黄色背景 + 当前项突出） |
| **交互** | 点击弹出编辑弹窗 | 支持上一项/下一项导航 |
| **DOM 标记** | `<mark class="highlight">` | `<mark class="search-match">` |
| **数据属性** | `data-highlight-id` | `data-search-index` |
### 5.10.2 搜索高亮 CSS
```css
/* ========== 搜索高亮样式 ========== */
mark.search-match {
  background: rgba(255, 235, 59, 0.4);  /* 淡黄色 */
  border-radius: 2px;
  padding: 0 1px;
  /* 关键：不继承存储高亮的样式 */
  text-decoration: none !important;
  border: none !important;
}
/* 当前焦点项 */
mark.search-match.current {
  background: rgba(255, 152, 0, 0.6);   /* 橙色，更突出 */
  box-shadow: 0 0 0 2px rgba(255, 152, 0, 0.3);
  outline: 2px solid #FF9800;
  outline-offset: 1px;
}
/* 重要：搜索高亮和存储高亮可以重叠 */
mark.highlight mark.search-match,
mark.search-match mark.highlight {
  /* 搜索高亮优先显示（因为是临时的、用户正在关注的） */
  background: rgba(255, 235, 59, 0.5) !important;
}
mark.highlight mark.search-match.current,
mark.search-match.current mark.highlight {
  background: rgba(255, 152, 0, 0.7) !important;
}
```
### 5.10.3 搜索状态管理
```js
// ========== 搜索状态 ==========
const searchState = {
  keyword: '',               // 当前搜索关键词
  matches: [],               // 所有匹配的 DOM 元素
  currentIndex: -1,          // 当前焦点索引
  isActive: false,           // 搜索是否激活
};
// 清理搜索状态
function clearSearchState() {
  searchState.keyword = '';
  searchState.matches = [];
  searchState.currentIndex = -1;
  searchState.isActive = false;
}
```
### 5.10.4 搜索高亮实现
```js
// 执行搜索（由 Flutter 调用）
window.setSearchKeyword = function(keyword) {
  // 1. 清除旧的搜索高亮
  clearSearchHighlights();
  // 2. 空关键词表示关闭搜索
  if (!keyword || !keyword.trim()) {
    clearSearchState();
    FlutterBridge.onSearchResult({ total: 0, current: -1 });
    return;
  }
  // 3. 执行新搜索
  searchState.keyword = keyword.trim();
  searchState.isActive = true;
  searchState.matches = [];
  // 4. 在所有已加载的内容中搜索
  const containers = document.querySelectorAll('.markdown-body, .question-text');
  containers.forEach(container => {
    highlightSearchMatches(container, searchState.keyword);
  });
  // 5. 跳转到第一个匹配
  if (searchState.matches.length > 0) {
    searchState.currentIndex = 0;
    updateCurrentSearchMatch();
  }
  // 6. 通知 Flutter
  FlutterBridge.onSearchResult({
    total: searchState.matches.length,
    current: searchState.currentIndex,
  });
};
// 在容器中高亮搜索匹配
function highlightSearchMatches(container, keyword) {
  const walker = document.createTreeWalker(
    container,
    NodeFilter.SHOW_TEXT,
    {
      acceptNode: (node) => {
        // 跳过已经是搜索高亮的节点（避免重复处理）
        if (node.parentElement?.classList.contains('search-match')) {
          return NodeFilter.FILTER_REJECT;
        }
        // 跳过代码块（可选，看产品需求）
        // if (node.parentElement?.closest('pre, code')) {
        //   return NodeFilter.FILTER_REJECT;
        // }
        return NodeFilter.FILTER_ACCEPT;
      }
    }
  );
  const nodesToProcess = [];
  while (walker.nextNode()) {
    const node = walker.currentNode;
    const text = node.textContent;
    // 不区分大小写搜索
    if (text.toLowerCase().includes(keyword.toLowerCase())) {
      nodesToProcess.push(node);
    }
  }
  // 倒序处理，避免偏移变化
  nodesToProcess.reverse().forEach(node => {
    wrapSearchMatches(node, keyword);
  });
}
// 包裹单个文本节点中的所有匹配
function wrapSearchMatches(textNode, keyword) {
  const text = textNode.textContent;
  const lowerText = text.toLowerCase();
  const lowerKeyword = keyword.toLowerCase();
  const fragment = document.createDocumentFragment();
  let lastIndex = 0;
  let matchIndex;
  while ((matchIndex = lowerText.indexOf(lowerKeyword, lastIndex)) !== -1) {
    // 添加匹配前的文本
    if (matchIndex > lastIndex) {
      fragment.appendChild(
        document.createTextNode(text.substring(lastIndex, matchIndex))
      );
    }
    // 创建搜索高亮标记
    const mark = document.createElement('mark');
    mark.className = 'search-match';
    mark.dataset.searchIndex = searchState.matches.length;
    mark.textContent = text.substring(matchIndex, matchIndex + keyword.length);
    fragment.appendChild(mark);
    // 记录匹配元素
    searchState.matches.push(mark);
    lastIndex = matchIndex + keyword.length;
  }
  // 添加剩余文本
  if (lastIndex < text.length) {
    fragment.appendChild(
      document.createTextNode(text.substring(lastIndex))
    );
  }
  // 替换原节点
  textNode.parentNode.replaceChild(fragment, textNode);
}
```
### 5.10.5 搜索导航
function
```js
// 跳转到下一个匹配
window.searchNext = function() {
  if (searchState.matches.length === 0) return;
  searchState.currentIndex = 
    (searchState.currentIndex + 1) % searchState.matches.length;
  updateCurrentSearchMatch();
  FlutterBridge.onSearchResult({
    total: searchState.matches.length,
    current: searchState.currentIndex,
  });
};
// 跳转到上一个匹配
window.searchPrev = function() {
  if (searchState.matches.length === 0) return;
  searchState.currentIndex = 
    (searchState.currentIndex - 1 + searchState.matches.length) % searchState.matches.length;
  updateCurrentSearchMatch();
  FlutterBridge.onSearchResult({
    total: searchState.matches.length,
    current: searchState.currentIndex,
  });
};
// 更新当前焦点
function updateCurrentSearchMatch() {
  // 移除所有 current 标记
  searchState.matches.forEach(mark => mark.classList.remove('current'));
  // 添加当前焦点
  const currentMark = searchState.matches[searchState.currentIndex];
  if (currentMark) {
    currentMark.classList.add('current');
    // 滚动到可视区域
    currentMark.scrollIntoView({
      behavior: 'smooth',
      block: 'center',
      inline: 'nearest'
    });
  }
}
```
### 5.10.6 清除搜索高亮
```js
// 清除所有搜索高亮（不影响存储高亮）
function clearSearchHighlights() {
  const marks = document.querySelectorAll('mark.search-match');
  marks.forEach(mark => {
    // 保留内容，移除 <mark> 包裹
    const parent = mark.parentNode;
    while (mark.firstChild) {
      parent.insertBefore(mark.firstChild, mark);
    }
    parent.removeChild(mark);
    // 合并相邻文本节点
    parent.normalize();
  });
}
// 关闭搜索（由 Flutter 调用）
window.closeSearch = function() {
  clearSearchHighlights();
  clearSearchState();
};
```
### 5.10.7 增量加载时的搜索处理
```js
// 当新轮次加载时，如果搜索激活，需要高亮新内容
function onRoundLoaded(roundEl) {
  // ... 其他初始化逻辑 ...
  // 如果搜索激活，高亮新加载的内容
  if (searchState.isActive && searchState.keyword) {
    const containers = roundEl.querySelectorAll('.markdown-body, .question-text');
    const prevCount = searchState.matches.length;
    containers.forEach(container => {
      highlightSearchMatches(container, searchState.keyword);
    });
    // 如果有新匹配，通知 Flutter
    if (searchState.matches.length > prevCount) {
      FlutterBridge.onSearchResult({
        total: searchState.matches.length,
        current: searchState.currentIndex,
      });
    }
  }
}
```
### 5.10.8 Flutter 端搜索 UI
```dart
// 搜索栏 Widget
class SearchBar extends StatefulWidget {
  final InAppWebViewController controller;
  final VoidCallback onClose;
  const SearchBar({required this.controller, required this.onClose});
  @override
  State<SearchBar> createState() => _SearchBarState();
}
class _SearchBarState extends State<SearchBar> {
  final _controller = TextEditingController();
  int _total = 0;
  int _current = -1;
  Timer? _debounce;
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () {
      widget.controller.evaluateJavascript(
        source: 'window.setSearchKeyword(${jsonEncode(value)})',
      );
    });
  }
  void _searchNext() {
    widget.controller.evaluateJavascript(source: 'window.searchNext()');
  }
  void _searchPrev() {
    widget.controller.evaluateJavascript(source: 'window.searchPrev()');
  }
  void _close() {
    widget.controller.evaluateJavascript(source: 'window.closeSearch()');
    widget.onClose();
  }
  // 接收 JS 回调更新状态
  void updateSearchResult(int total, int current) {
    setState(() {
      _total = total;
      _current = current;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索...',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // 结果计数
          if (_total > 0)
            Text(
              '${_current + 1}/$_total',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          // 导航按钮
          IconButton(
            icon: Icon(Icons.keyboard_arrow_up),
            onPressed: _total > 0 ? _searchPrev : null,
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down),
            onPressed: _total > 0 ? _searchNext : null,
          ),
          // 关闭
          IconButton(
            icon: Icon(Icons.close),
            onPressed: _close,
          ),
        ],
      ),
    );
  }
}
```
### 5.10.9 关键设计决策
**为什么搜索高亮和存储高亮要分开？**
1. **生命周期不同** - 搜索是临时的，不应污染持久化数据
2. **DOM 结构安全** - 两者使用不同的 class，互不影响
3. **可以共存** - 同一段文本可以同时有存储高亮和搜索高亮
4. **清除逻辑独立** - `clearSearchHighlights()` 只清搜索，不影响存储高亮
**DOM 嵌套情况处理：**
```html
<!-- 可能的嵌套情况 -->
<mark class="highlight hl-background" data-highlight-id="hl-001">
  这是<mark class="search-match">存储</mark>高亮的文本
</mark>
<!-- 或者 -->
<mark class="search-match">
  <mark class="highlight hl-background" data-highlight-id="hl-002">搜索</mark>
</mark>
```
CSS 已处理这种情况，搜索高亮优先突出显示。
***
## 5.11 高亮编辑弹窗（微信读书风格）
点击已有高亮时，显示样式编辑弹窗，支持修改颜色、样式、删除等操作（详见上文 5.10）。
***
# 七、Flutter 原生笔记列表页优化
## 7.1 问题：当前笔记卡片纯文本拼接
现有实现只是把 `prefix + text + suffix` 简单拼接成纯文本显示，存在以下问题：
* ❌ 丢失原文 Markdown 格式（粗体、列表、代码等）
* ❌ 上下文与高亮文本视觉无区分
* ❌ 缺乏沉浸感，难以快速定位
## 7.2 优化方案：带模糊上下文的富文本卡片
**设计目标**：微信读书风格，高亮文本突出，上下文淡化。
### 7.2.1 视觉效果
```warp-runnable-command
┌─────────────────────────────────────┐
│  [黄色条] │  📍 Q3 · Claude 3.5     │   ← 来源信息
├───────────┼─────────────────────────┤
│           │  ...前面的一些文本内容   │   ← prefix (淡化 50%)
│           │  ════════════════════   │
│           │  **高亮的核心文本**      │   ← text (正常 + 高亮背景)
│           │  可以是多行的 Markdown   │
│           │  - 保留列表格式          │
│           │  ════════════════════   │
│           │  ...后面的一些文本内容   │   ← suffix (淡化 50%)
├───────────┴─────────────────────────┤
│  📝 用户的笔记内容（如果有）        │   ← 可选笔记区
│  2024-01-16 02:00                    │   ← 时间戳
└─────────────────────────────────────┘
```
### 7.2.2 数据模型扩展
```dart
class NoteCardData {
  final String highlightId;
  final String messageId;
  final String topicName;
  final int roundIndex;              // Q几
  final String modelName;            // 来源模型
  // 内容（保留 Markdown 格式）
  final String prefix;               // 前 50 字符 Markdown
  final String highlightText;        // 高亮文本 Markdown
  final String suffix;               // 后 50 字符 Markdown
  // 样式
  final String color;                // '#FFF176'
  final String style;                // 'background' | 'underline' ...
  // 可选笔记
  final String? note;
  final DateTime createdAt;
}
```
### 7.2.3 Flutter Widget 实现
```dart
class NoteCard extends StatelessWidget {
  final NoteCardData data;
  const NoteCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final highlightColor = Color(
      int.parse(data.color.replaceFirst('#', '0xFF'))
    ).withOpacity(0.3);
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 头部：来源信息 =====
          _buildHeader(context),
          // ===== 内容区：上下文 + 高亮 =====
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prefix (淡化)
                if (data.prefix.isNotEmpty)
                  _buildContextText(data.prefix, isPrefix: true),
                // Highlight (突出)
                Container(
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: MarkdownBody(
                    data: data.highlightText,
                    styleSheet: _highlightMarkdownStyle(context),
                  ),
                ),
                // Suffix (淡化)
                if (data.suffix.isNotEmpty)
                  _buildContextText(data.suffix, isPrefix: false),
              ],
            ),
          ),
          // ===== 笔记区（如果有）=====
          if (data.note != null && data.note!.isNotEmpty)
            _buildNoteSection(context),
          // ===== 底部：时间戳 =====
          _buildFooter(context),
        ],
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Color(int.parse(data.color.replaceFirst('#', '0xFF'))),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text(
            'Q${data.roundIndex + 1} · ${data.modelName}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          Spacer(),
          // 可点击跳转到原文
          GestureDetector(
            onTap: () => _navigateToSource(context),
            child: Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  Widget _buildContextText(String text, {required bool isPrefix}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isPrefix ? 4 : 0,
        top: isPrefix ? 0 : 4,
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: isPrefix ? Alignment.topCenter : Alignment.bottomCenter,
          end: isPrefix ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            Colors.transparent,
            Colors.black,
          ],
          stops: [0.0, 0.3],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: Opacity(
          opacity: 0.5,
          child: MarkdownBody(
            data: text,
            styleSheet: _contextMarkdownStyle(context),
          ),
        ),
      ),
    );
  }
  MarkdownStyleSheet _highlightMarkdownStyle(BuildContext context) {
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 14, height: 1.5),
      strong: TextStyle(fontWeight: FontWeight.w600),
      // ...其他样式保持与 WebView 一致
    );
  }
  MarkdownStyleSheet _contextMarkdownStyle(BuildContext context) {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 13,
        height: 1.4,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
      ),
    );
  }
  Widget _buildNoteSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              data.note!,
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        _formatTime(data.createdAt),
        style: TextStyle(color: Colors.grey, fontSize: 11),
      ),
    );
  }
}
```
### 7.2.4 上下文渐隐效果 (ShaderMask)
```dart
// prefix 从上到下渐隐（...内容变清晰）
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.4],  // 前 40% 透明渐变
  ).createShader(bounds),
  blendMode: BlendMode.dstIn,
  child: ...
)
// suffix 从下到上渐隐（内容变清晰...）
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.4],
  ).createShader(bounds),
  blendMode: BlendMode.dstIn,
  child: ...
)
```
### 7.2.5 对比效果
**Before (纯文本拼接)**:
```warp-runnable-command
前面的文本内容这是高亮的核心文本后面的文本内容
```
**After (带模糊上下文的富文本)**:
```warp-runnable-command
            ...前面的一些文本内容用于恢复定位
       ╔═══════════════════════════════════╗
       ║  **这是高亮的核心文本**            ║  ← 带高亮背景色
       ║  - 支持列表                       ║
       ║  - `支持代码`                     ║
       ╚═══════════════════════════════════╝
            ...后面的一些文本内容用于恢复定位
```
### 7.2.6 依赖
```yaml
# pubspec.yaml
dependencies:
  flutter_markdown: ^0.6.18   # Markdown 渲染
```
**注意**：`flutter_markdown` 用于简单 Markdown 渲染足够，不需要完整的 WebView 能力。
  onHighlightDeleted(data) {
    // data: { highlightId, messageId }
  },

  // ========== 搜索 ==========
  onSearchResult(data) {
    // data: { total, current }
    // 搜索结果更新（匹配数、当前索引）
  },

  // ========== 原生功能调用 ==========
  playTTS(data) {
    // data: { roundIndex, messageId? }
  },

  openDiscussion(data) {
    // data: { roundIndex, contextId }
  },

  showToast(data) {
    // data: { message, type: 'success'|'error'|'info' }
  },

  copyToClipboard(data) {
    // data: { text, html?, showToast: true }
  },
};
```warp-runnable-command
***
# 四、HTML/CSS 布局实现
## 4\.1 HTML 结构
```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <link rel="stylesheet" href="conversation.css">
  <link rel="stylesheet" href="highlight.css">
</head>
<body class="theme-light">
  <!-- Sticky Tab Bar (当内联 Tab 滚出时显示) -->
  <header id="sticky-header" class="hidden">
    <span class="round-label">Q1</span>
    <div class="tab-list"></div>
  </header>
  <!-- 主内容区 -->
  <main id="conversation-container">
    <!-- 轮次卡片通过 JS 动态生成 -->
  </main>
  <!-- 能量条 (固定右侧) -->
  <aside id="energy-bar">
    <!-- 动态生成 -->
  </aside>
  <!-- 侧滑抽屉 -->
  <aside id="edge-drawer" class="closed">
    <div class="drawer-trigger"></div>
    <div class="drawer-content">
      <button class="nav-btn up">▲</button>
      <div class="round-indicator">1/25</div>
      <button class="nav-btn down">▼</button>
      <hr>
      <button class="action-btn tts">🎧 朗读</button>
      <button class="action-btn discuss">💬 讨论</button>
    </div>
  </aside>
  <!-- TTS Mini Player -->
  <footer id="tts-player" class="hidden">
    <div class="player-content">
      <span class="title">正在朗读...</span>
      <div class="controls">
        <button class="prev">⏮</button>
        <button class="play-pause">⏸</button>
        <button class="next">⏭</button>
      </div>
      <button class="close">✕</button>
    </div>
  </footer>
  <!-- 高亮工具栏 (选中文本时显示) -->
  <div id="highlight-toolbar" class="hidden">
    <button class="color" data-color="0xFFFFF176" style="background:#FFF176"></button>
    <button class="color" data-color="0xFF81C784" style="background:#81C784"></button>
    <button class="color" data-color="0xFF64B5F6" style="background:#64B5F6"></button>
    <button class="color" data-color="0xFFE57373" style="background:#E57373"></button>
    <button class="style" data-style="underline">U̲</button>
  </div>
  <script src="marked.min.js"></script>
  <script src="highlight.min.js"></script>
  <script src="conversation.js"></script>
  <script src="highlight-manager.js"></script>
</body>
</html>
```
## 4.2 轮次卡片 HTML 模板
```html
<article class="round-card" data-round-index="0">
  <!-- 问题区 -->
  <section class="question-section">
    <div class="color-bar"></div>
    <div class="content">
      <span class="q-label">Q1</span>
      <div class="question-text" data-message-id="msg-user-001">
        <!-- Markdown 渲染后的 HTML -->
      </div>
    </div>
  </section>
  
  <!-- 回复区 -->
  <section class="reply-section">
    <!-- Tab 选择器 -->
    <div class="tab-bar" data-round-index="0">
      <button class="tab active" data-index="0" data-model="claude-3-5">
        <span class="model-dot" style="background:#8B5CF6"></span>
        <span class="model-name">Claude 3.5</span>
        <span class="mainline-badge">★</span>
      </button>
      <button class="tab" data-index="1" data-model="gpt-4o">
        <span class="model-dot" style="background:#10B981"></span>
        <span class="model-name">GPT-4o</span>
      </button>
    </div>
    
    <!-- 回复内容 (Swiper) -->
    <div class="reply-swiper">
      <div class="swiper-wrapper">
        <div class="swiper-slide active" data-message-id="msg-assistant-001">
          <div class="markdown-body">
            <!-- Markdown 渲染后的 HTML + 高亮标记 -->
          </div>
        </div>
        <div class="swiper-slide" data-message-id="msg-assistant-002">
          <div class="markdown-body">
            <!-- ... -->
          </div>
        </div>
      </div>
    </div>
  </section>
</article>
```
## 4.3 核心 CSS
```css
/* ========== 主题变量 ========== */
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
  --text-primary: #1a1a1a;
  --text-secondary: #666666;
  --border-color: #e0e0e0;
  --question-color: #6366F1;
  --energy-bar-width: 6px;
}
.theme-dark {
  --bg-primary: #1a1a1a;
  --bg-secondary: #2d2d2d;
  --text-primary: #e0e0e0;
  --text-secondary: #999999;
  --border-color: #404040;
}
/* ========== 布局 ========== */
body {
  margin: 0;
  padding: 0;
  background: var(--bg-secondary);
  color: var(--text-primary);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  -webkit-tap-highlight-color: transparent;
}
#conversation-container {
  padding: 16px 12px 80px 12px;
  padding-right: calc(12px + var(--energy-bar-width) + 4px); /* 为能量条留空 */
}
/* ========== Sticky Header ========== */
#sticky-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--bg-primary);
  padding: 8px 16px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.06);
  display: flex;
  align-items: center;
  gap: 12px;
  transition: transform 0.2s, opacity 0.2s;
}
#sticky-header.hidden {
  transform: translateY(-100%);
  opacity: 0;
  pointer-events: none;
}
/* ========== 轮次卡片 ========== */
.round-card {
  background: var(--bg-primary);
  border-radius: 16px;
  border: 1px solid var(--border-color);
  margin-bottom: 24px;
  overflow: hidden;
  contain: layout style paint; /* 性能优化 */
}
.question-section {
  display: flex;
  background: color-mix(in srgb, var(--question-color) 5%, transparent);
}
.question-section .color-bar {
  width: 4px;
  background: var(--question-color);
  flex-shrink: 0;
}
.question-section .content {
  flex: 1;
  padding: 12px 14px;
}
.q-label {
  display: inline-block;
  padding: 4px 8px;
  background: color-mix(in srgb, var(--question-color) 12%, transparent);
  color: var(--question-color);
  border-radius: 6px;
  font-size: 12px;
  font-weight: 700;
  margin-bottom: 8px;
}
/* ========== Tab 选择器 ========== */
.tab-bar {
  display: flex;
  gap: 4px;
  padding: 10px 8px;
  overflow-x: auto;
  scrollbar-width: none;
}
.tab-bar::-webkit-scrollbar { display: none; }
.tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border: none;
  background: transparent;
  border-radius: 8px;
  font-size: 13px;
  color: var(--text-secondary);
  white-space: nowrap;
  cursor: pointer;
  transition: all 0.2s;
}
.tab.active {
  background: color-mix(in srgb, var(--model-color, #8B5CF6) 15%, transparent);
  color: var(--text-primary);
  font-weight: 600;
}
.model-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}
.mainline-badge {
  color: #F59E0B;
  font-size: 10px;
}
/* ========== Swiper 内容区 ========== */
.reply-swiper {
  overflow: hidden;
}
.swiper-wrapper {
  display: flex;
  transition: transform 0.3s ease-out;
}
.swiper-slide {
  flex: 0 0 100%;
  min-width: 100%;
  padding: 0 14px 14px;
  box-sizing: border-box;
}
/* ========== 能量条 ========== */
#energy-bar {
  position: fixed;
  right: 0;
  top: 60px;
  bottom: 80px;
  width: var(--energy-bar-width);
  display: flex;
  flex-direction: column;
  z-index: 50;
}
.energy-cell {
  flex: 1;
  position: relative;
  cursor: pointer;
  border-bottom: 1px solid var(--bg-primary);
}
.energy-cell:last-child { border-bottom: none; }
.energy-cell .empty {
  position: absolute;
  inset: 0;
  opacity: 0.25;
}
.energy-cell .fill {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 0;
  transition: height 0.15s ease-out;
}
/* ========== 侧滑抽屉 ========== */
#edge-drawer {
  position: fixed;
  right: 0;
  bottom: 100px;
  display: flex;
  z-index: 60;
  transition: transform 0.2s ease-out;
}
#edge-drawer.closed {
  transform: translateX(calc(100% - 18px));
}
.drawer-trigger {
  width: 18px;
  height: 48px;
  background: var(--bg-primary);
  border-radius: 10px 0 0 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: -2px 0 6px rgba(0,0,0,0.08);
}
.drawer-content {
  background: var(--bg-primary);
  padding: 10px 8px;
  border-radius: 14px 0 0 14px;
  box-shadow: -3px 0 10px rgba(0,0,0,0.12);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}
```
***
# 五、高亮系统实现
## 5.0 高亮数据结构重构
### 5.0.1 新数据结构设计 (v3.0)
**设计原则**：
* 简化字段，移除冗余
* 统一颜色格式为 CSS 兼容的十六进制字符串
* 保留 Block 概念但简化命名
* 不兼容旧数据，重新设计
```ts
// ========== 新版高亮数据结构 (WebView 优先) ==========
interface Highlight {
  id: string;                    // UUID
  messageId: string;             // 关联的消息 ID
  text: string;                  // 完整高亮文本
  color: string;                 // CSS 颜色 '#FFF176'（不含透明度）
  style: 'background' | 'underline' | 'wavy' | 'box' | 'dashed';  // 样式类型
  // 定位信息：每个 Block 内的范围
  ranges: HighlightRange[];
  // 恢复上下文（fallback 用）
  prefix: string;                // 前 50 字符
  suffix: string;                // 后 50 字符
  // 元数据
  createdAt: string;             // ISO 时间戳
}
interface HighlightRange {
  blockIndex: number;            // Block 索引
  start: number;                 // Block 内起始偏移
  end: number;                   // Block 内结束偏移
  text: string;                  // 该范围的文本（用于验证）
}
```
### 5.0.2 Flutter 端数据模型重构
```dart
// lib/models/highlight_data.dart
/// 高亮范围（单个 Block 内）
class HighlightRange {
  final int blockIndex;
  final int start;
  final int end;
  final String text;
  HighlightRange({
    required this.blockIndex,
    required this.start,
    required this.end,
    required this.text,
  });
  Map<String, dynamic> toJson() => {
    'blockIndex': blockIndex,
    'start': start,
    'end': end,
    'text': text,
  };
  factory HighlightRange.fromJson(Map<String, dynamic> json) => HighlightRange(
    blockIndex: json['blockIndex'] as int,
    start: json['start'] as int,
    end: json['end'] as int,
    text: json['text'] as String,
  );
}
/// 高亮数据模型 v3.0
class HighlightData {
  final String id;
  final String messageId;
  final String text;
  final String color;            // CSS 十六进制 '#FFF176'
  final String style;            // 'background' | 'underline' | 'wavy' | 'box' | 'dashed'
  final List<HighlightRange> ranges;
  final String prefix;
  final String suffix;
  final DateTime createdAt;
  HighlightData({
    String? id,
    required this.messageId,
    required this.text,
    required this.color,
    this.style = 'background',
    required this.ranges,
    this.prefix = '',
    this.suffix = '',
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
    'id': id,
    'messageId': messageId,
    'text': text,
    'color': color,
    'style': style,
    'ranges': ranges.map((r) => r.toJson()).toList(),
    'prefix': prefix,
    'suffix': suffix,
    'createdAt': createdAt.toIso8601String(),
  };
  factory HighlightData.fromJson(Map<String, dynamic> json) => HighlightData(
    id: json['id'] as String?,
    messageId: json['messageId'] as String,
    text: json['text'] as String,
    color: json['color'] as String,
    style: json['style'] as String? ?? 'background',
    ranges: (json['ranges'] as List).map((e) => 
      HighlightRange.fromJson(e as Map<String, dynamic>)
    ).toList(),
    prefix: json['prefix'] as String? ?? '',
    suffix: json['suffix'] as String? ?? '',
    createdAt: json['createdAt'] != null
      ? DateTime.parse(json['createdAt'] as String)
      : null,
  );
}
```
### 5.0.3 数据库存储重构
```dart
// lib/models/isar/knowledge_entry.dart 修改
@collection
class KnowledgeEntry {
  // ... 其他字段保持不变 ...
  /// 高亮颜色（CSS 十六进制格式 '#FFF176'）
  String? color;
  /// 样式类型 'background' | 'underline' | 'wavy' | 'box' | 'dashed'
  String? styleType;
  /// 高亮范围 JSON字符串
  /// 格式: [{"blockIndex":0,"start":10,"end":20,"text":"..."}]
  String? ranges;
  /// 恢复上下文
  String? prefix;  // 前 50 字符
  String? suffix;  // 后 50 字符
  // ❗移除废弃字段：
  // - start / end（全局偏移在 WebView 中无用）
  // - blockIndex / blockInternalStart / blockInternalEnd（改用 ranges）
  // - blockContentHash（不再需要）
  // - groupId（废弃）
  // - selections（改用 ranges，命名更清晰）
}
```
### 5.0.4 新旧数据对比
| 旧字段 | 新字段 | 说明 |
|--------|--------|------|
| `color: int (0xFFFFF176)` | `color: string ('#FFF176')` | CSS 友好，无需转换 |
| `styleType` | `style` | 简化命名 |
| `selections` | `ranges` | 更清晰的命名 |
| `internalStart/internalEnd` | `start/end` | 在 range 内已隐含 "Block 内" |
| `start/end (全局)` | 移除 | WebView 中不需要 |
| `blockContentHash` | 移除 | 改用 text 验证 |
| `groupId` | 移除 | 废弃概念 |
| `globalStart/globalEnd` | 移除 | 用 prefix/suffix 替代 |
## 5.1 高亮数据示例
```js
// 单个高亮示例
const highlight = {
  id: 'hl-a1b2c3d4',
  messageId: 'msg-assistant-001',
  text: '这是被高亮的文本',
  color: '#FFF176',              // 黄色
  style: 'background',
  ranges: [
    { blockIndex: 2, start: 10, end: 22, text: '这是被高亮的文本' },
  ],
  prefix: '前面的一些文本内容用于恢复定位',
  suffix: '后面的一些文本内容用于恢复定位',
  createdAt: '2024-01-16T02:00:00Z',
};
// 跨 Block 高亮示例
const crossBlockHighlight = {
  id: 'hl-e5f6g7h8',
  messageId: 'msg-assistant-001',
  text: '段落尾部...\n列表开头',
  color: '#81C784',              // 绿色
  style: 'underline',
  ranges: [
    { blockIndex: 1, start: 50, end: 60, text: '段落尾部...' },
    { blockIndex: 2, start: 0, end: 8, text: '列表开头' },
  ],
  prefix: '前置文本',
  suffix: '后置文本',
  createdAt: '2024-01-16T02:05:00Z',
};
```
## 5.2 Markdown → HTML 渲染 + Block 索引
```js
// 核心：渲染 Markdown 时为每个 Block 添加 data-block-index
function renderMarkdown(content, messageId) {
  // 使用 marked.js 自定义 renderer
  const renderer = new marked.Renderer();
  let blockIndex = 0;
  
  // 为每个段落添加 Block 标记
  renderer.paragraph = (text) => {
    return `<p data-block-index="${blockIndex++}">${text}</p>`;
  };
  
  renderer.heading = (text, level) => {
    return `<h${level} data-block-index="${blockIndex++}">${text}</h${level}>`;
  };
  
  renderer.listitem = (text) => {
    return `<li data-block-index="${blockIndex++}">${text}</li>`;
  };
  
  renderer.code = (code, language) => {
    const highlighted = hljs.highlightAuto(code, [language]).value;
    return `<pre data-block-index="${blockIndex++}"><code class="hljs language-${language}">${highlighted}</code></pre>`;
  };
  
  return marked.parse(content, { renderer });
}
```
## 5.3 高亮恢复：HTML 注入
```js
// 恢复高亮：在渲染后的 HTML 中注入 <mark> 标签
function applyHighlights(containerEl, highlights) {
  for (const hl of highlights) {
    for (const sel of hl.selections) {
      // 1. 找到对应的 Block 元素
      const blockEl = containerEl.querySelector(`[data-block-index="${sel.blockIndex}"]`);
      if (!blockEl) continue;
      
      // 2. 在 Block 内定位并包裹文本
      wrapTextRange(blockEl, sel.internalStart, sel.internalEnd, {
        tagName: 'mark',
        className: `highlight hl-${hl.styleType}`,
        attributes: {
          'data-highlight-id': hl.id,
          'data-message-id': containerEl.dataset.messageId,
          'style': `--hl-color: ${intColorToRgba(hl.color)}`,
        },
      });
    }
  }
}
// 核心算法：在 DOM 中按文本偏移包裹指定范围
function wrapTextRange(rootEl, start, end, options) {
  const walker = document.createTreeWalker(rootEl, NodeFilter.SHOW_TEXT);
  let currentOffset = 0;
  const nodesToWrap = [];
  
  while (walker.nextNode()) {
    const node = walker.currentNode;
    const nodeLength = node.textContent.length;
    const nodeStart = currentOffset;
    const nodeEnd = currentOffset + nodeLength;
    
    // 计算与目标范围的交集
    const overlapStart = Math.max(start, nodeStart);
    const overlapEnd = Math.min(end, nodeEnd);
    
    if (overlapStart < overlapEnd) {
      nodesToWrap.push({
        node,
        start: overlapStart - nodeStart,
        end: overlapEnd - nodeStart,
      });
    }
    
    currentOffset = nodeEnd;
    if (currentOffset >= end) break;
  }
  
  // 倒序处理，避免偏移变化
  for (let i = nodesToWrap.length - 1; i >= 0; i--) {
    const { node, start: s, end: e } = nodesToWrap[i];
    const range = document.createRange();
    range.setStart(node, s);
    range.setEnd(node, e);
    
    const wrapper = document.createElement(options.tagName);
    wrapper.className = options.className;
    for (const [k, v] of Object.entries(options.attributes || {})) {
      wrapper.setAttribute(k, v);
    }
    range.surroundContents(wrapper);
  }
}
```
## 5.4 高亮样式 CSS
```css
/* ========== 高亮样式 ========== */
mark.highlight {
  --hl-color: rgba(255, 241, 118, 0.6);
  background: transparent;
  padding: 0;
  cursor: pointer;
  transition: filter 0.2s;
}
mark.highlight:hover {
  filter: brightness(0.95);
}
/* 背景高亮 */
mark.hl-background {
  background: var(--hl-color);
  border-radius: 2px;
}
/* 下划线高亮 */
mark.hl-underline {
  text-decoration: underline;
  text-decoration-color: var(--hl-color);
  text-decoration-thickness: 2px;
  text-underline-offset: 2px;
}
/* 波浪线高亮 */
mark.hl-wavy {
  text-decoration: underline wavy;
  text-decoration-color: var(--hl-color);
  text-underline-offset: 2px;
}
/* 边框高亮 */
mark.hl-box {
  border: 2px solid var(--hl-color);
  border-radius: 3px;
  padding: 0 2px;
  margin: 0 1px;
}
/* 虚线下划线高亮 */
mark.hl-dashed {
  text-decoration: underline dashed;
  text-decoration-color: var(--hl-color);
  text-decoration-thickness: 2px;
  text-underline-offset: 2px;
}
/* 高亮闪烁动画（跳转定位时） */
mark.highlight.flash {
  animation: highlight-flash 1.5s ease-out;
}
@keyframes highlight-flash {
  0%, 100% { filter: brightness(1); }
  25%, 75% { filter: brightness(1.3); box-shadow: 0 0 8px var(--hl-color); }
}
```
## 5.5 创建高亮：文本选择处理
```js
// 监听文本选择
document.addEventListener('selectionchange', debounce(() => {
  const selection = window.getSelection();
  if (!selection || selection.isCollapsed) {
    hideHighlightToolbar();
    return;
  }
  
  const range = selection.getRangeAt(0);
  const text = selection.toString().trim();
  if (!text) return;
  
  // 找到所属的消息容器
  const messageEl = range.commonAncestorContainer.closest?.('[data-message-id]')
    || range.commonAncestorContainer.parentElement?.closest('[data-message-id]');
  if (!messageEl) return;
  
  // 收集选区信息（支持跨 Block）
  const selections = collectSelections(messageEl, range);
  
  // 计算工具栏位置
  const rect = range.getBoundingClientRect();
  showHighlightToolbar(rect, {
    text,
    messageId: messageEl.dataset.messageId,
    roundIndex: messageEl.closest('.round-card').dataset.roundIndex,
    selections,
  });
}, 100));
// 收集跨 Block 的选区信息
function collectSelections(messageEl, range) {
  const selections = [];
  const walker = document.createTreeWalker(messageEl, NodeFilter.SHOW_TEXT);
  const blocks = messageEl.querySelectorAll('[data-block-index]');
  
  // 为每个 Block 计算内部偏移
  for (const block of blocks) {
    const blockIndex = parseInt(block.dataset.blockIndex);
    const blockRange = document.createRange();
    blockRange.selectNodeContents(block);
    
    // 判断 range 是否与该 Block 有交集
    if (range.compareBoundaryPoints(Range.END_TO_START, blockRange) < 0 &&
        range.compareBoundaryPoints(Range.START_TO_END, blockRange) > 0) {
      
      // 计算交集的内部偏移
      const { start, end, text } = getInternalOffset(block, range);
      if (start < end) {
        selections.push({
          blockIndex,
          internalStart: start,
          internalEnd: end,
          text,
        });
      }
    }
  }
  
  return selections;
}
// 计算选区在 Block 内的偏移
function getInternalOffset(blockEl, selectionRange) {
  const blockRange = document.createRange();
  blockRange.selectNodeContents(blockEl);
  
  // 计算起始偏移
  const startRange = document.createRange();
  startRange.setStart(blockEl, 0);
  startRange.setEnd(
    selectionRange.startContainer.compareDocumentPosition(blockEl) & Node.DOCUMENT_POSITION_CONTAINS
      ? selectionRange.startContainer
      : blockEl,
    selectionRange.startContainer.compareDocumentPosition(blockEl) & Node.DOCUMENT_POSITION_CONTAINS
      ? selectionRange.startOffset
      : 0
  );
  const start = startRange.toString().length;
  
  // 类似计算结束偏移...
  const end = start + selectionRange.toString().length;
  
  return { start, end, text: selectionRange.toString() };
}
```
## 5.6 高亮点击处理
```js
// 事件委托：监听高亮点击
document.addEventListener('click', (e) => {
  const highlightEl = e.target.closest('mark.highlight');
  if (!highlightEl) return;
  
  e.preventDefault();
  e.stopPropagation();
  
  const highlightId = highlightEl.dataset.highlightId;
  const messageId = highlightEl.dataset.messageId;
  const rect = highlightEl.getBoundingClientRect();
  
  // 通知 Flutter
  FlutterBridge.onHighlightTapped({
    highlightId,
    messageId,
    rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
  });
});
```
## 5.7 高亮实时更新（局部 DOM 操作）
**核心思路**：不重新渲染整个页面，只操作相关 DOM 节点
```js
// ========== 添加高亮 ==========
function addHighlightInPlace(messageId, highlight) {
  const container = document.querySelector(`[data-message-id="${messageId}"] .markdown-body`);
  if (!container) return;
  
  // 直接在现有 DOM 上包裹 <mark>
  for (const sel of highlight.selections) {
    const block = container.querySelector(`[data-block-index="${sel.blockIndex}"]`);
    if (!block) continue;
    
    wrapTextRange(block, sel.internalStart, sel.internalEnd, {
      tagName: 'mark',
      className: `highlight hl-${highlight.styleType}`,
      attributes: {
        'data-highlight-id': highlight.id,
        'data-message-id': messageId,
        'style': `--hl-color: ${intColorToRgba(highlight.color)}`,
      },
    });
  }
}
// ========== 删除高亮 ==========
function removeHighlightInPlace(highlightId) {
  // 找到所有相关的 <mark> 标签
  const marks = document.querySelectorAll(`mark[data-highlight-id="${highlightId}"]`);
  
  marks.forEach(mark => {
    // 保留内容，移除 <mark> 包裹
    const parent = mark.parentNode;
    while (mark.firstChild) {
      parent.insertBefore(mark.firstChild, mark);
    }
    parent.removeChild(mark);
    // 合并相邻文本节点
    parent.normalize();
  });
}
// ========== 更新高亮样式 ==========
function updateHighlightStyle(highlightId, newColor, newStyleType) {
  const marks = document.querySelectorAll(`mark[data-highlight-id="${highlightId}"]`);
  
  marks.forEach(mark => {
    // 移除旧样式类
    mark.classList.remove('hl-background', 'hl-underline', 'hl-wavy', 'hl-box', 'hl-dashed');
    // 添加新样式类
    mark.classList.add(`hl-${newStyleType}`);
    // 更新颜色
    mark.style.setProperty('--hl-color', intColorToRgba(newColor));
  });
}
// ========== 跳转到高亮并闪烁 ==========
function scrollToHighlightAndFlash(highlightId) {
  const mark = document.querySelector(`mark[data-highlight-id="${highlightId}"]`);
  if (!mark) return;
  
  // 滚动到可视区域
  mark.scrollIntoView({ behavior: 'smooth', block: 'center' });
  
  // 添加闪烁动画
  mark.classList.add('flash');
  setTimeout(() => mark.classList.remove('flash'), 1500);
}
```
## 5.8 高亮恢复策略（多级 Fallback）
**问题**：如果 Markdown 内容变化，Block 索引可能失效
```js
// 多级恢复策略
function recoverHighlight(container, highlight) {
  // 策略 1：Block 索引 + 内部偏移（最快）
  if (highlight.selections?.length > 0) {
    const success = tryBlockBasedRecovery(container, highlight);
    if (success) return true;
  }
  
  // 策略 2：前后文语义匹配
  if (highlight.prefix && highlight.suffix) {
    const success = tryContextBasedRecovery(container, highlight);
    if (success) return true;
  }
  
  // 策略 3：模糊文本搜索（Fallback）
  return tryFuzzyTextRecovery(container, highlight);
}
// Block 索引恢复
function tryBlockBasedRecovery(container, highlight) {
  for (const sel of highlight.selections) {
    const block = container.querySelector(`[data-block-index="${sel.blockIndex}"]`);
    if (!block) return false;
    
    // 验证文本匹配
    const blockText = block.textContent;
    const actualText = blockText.substring(sel.internalStart, sel.internalEnd);
    if (actualText !== sel.text) return false;
  }
  
  // 匹配成功，应用高亮
  applyHighlights(container, [highlight]);
  return true;
}
// 前后文语义匹配
function tryContextBasedRecovery(container, highlight) {
  const fullText = container.textContent;
  const searchStr = (highlight.prefix || '') + highlight.text + (highlight.suffix || '');
  const idx = fullText.indexOf(searchStr);
  
  if (idx === -1) return false;
  
  const start = idx + (highlight.prefix?.length || 0);
  const end = start + highlight.text.length;
  
  // 在容器中包裹文本
  wrapTextRangeGlobal(container, start, end, {
    tagName: 'mark',
    className: `highlight hl-${highlight.styleType}`,
    attributes: {
      'data-highlight-id': highlight.id,
      'style': `--hl-color: ${intColorToRgba(highlight.color)}`,
    },
  });
  return true;
}
```
## 5.9 关于 "Block" 概念的澄清
**Block 是我们自己定义的概念**，用于高亮定位，不是第三方库的概念。
**为什么需要 Block？**
* Markdown 渲染后的 HTML 结构可能比较复杂（嵌套 `<strong>`、`<em>` 等）
* 全局文本偏移会因为 HTML 标签而不稳定
* Block 级别的偏移更可靠，即使前面段落变化也不影响
**Block 的实现**：
```warp-runnable-command
Markdown 源文本                    渲染后的 HTML
────────────────────                ────────────────────
# 标题                            <h1 data-block-index="0">标题</h1>
这是一个段落。                     <p data-block-index="1">这是一个段落。</p>
- 列表项1                          <ul>
- 列表项2                            <li data-block-index="2">列表项1</li>
                                      <li data-block-index="3">列表项2</li>
                                    </ul>
```
**跨 Block 选择怎么处理？**
* 用户选择跨越多个 Block 的文本时，`collectSelections()` 会为每个 Block 生成独立的 selection
* 每个 selection 包含 `blockIndex` + `internalStart` + `internalEnd`
* 恢复时，每个 Block 独立注入 `<mark>` 标签
```js
// 跨 Block 高亮示例
highlight = {
  id: 'hl-001',
  text: '段落尾部...\n列表开头',  // 完整文本（包含换行）
  selections: [
    { blockIndex: 1, internalStart: 10, internalEnd: 20, text: '段落尾部...' },
    { blockIndex: 2, internalStart: 0, internalEnd: 8, text: '列表开头' },
  ],
};
```
## 5.10 高亮编辑弹窗（微信读书风格）
点击已有高亮时，显示样式编辑弹窗，支持修改颜色、样式、删除等操作。
### 5.10.1 HTML 结构
```html
<!-- 高亮编辑弹窗 -->
<div id="highlight-editor" class="hidden">
  <div class="editor-arrow"></div>
  <div class="editor-content">
    <!-- 颜色选择区 -->
    <div class="color-row">
      <button class="color-btn" data-color="#FFF176" style="background:#FFF176"></button>
      <button class="color-btn" data-color="#81C784" style="background:#81C784"></button>
      <button class="color-btn" data-color="#64B5F6" style="background:#64B5F6"></button>
      <button class="color-btn" data-color="#E57373" style="background:#E57373"></button>
      <button class="color-btn" data-color="#BA68C8" style="background:#BA68C8"></button>
    </div>
    <!-- 样式选择区 -->
    <div class="style-row">
      <button class="style-btn" data-style="background" title="背景">
        <span class="preview bg">A</span>
      </button>
      <button class="style-btn" data-style="underline" title="下划线">
        <span class="preview ul">A</span>
      </button>
      <button class="style-btn" data-style="wavy" title="波浪线">
        <span class="preview wavy">A</span>
      </button>
      <button class="style-btn" data-style="box" title="边框">
        <span class="preview box">A</span>
      </button>
      <button class="style-btn" data-style="dashed" title="虚线">
        <span class="preview dashed">A</span>
      </button>
    </div>
    <!-- 操作按钮 -->
    <div class="action-row">
      <button class="action-btn copy">📋 复制</button>
      <button class="action-btn note">📝 笔记</button>
      <button class="action-btn delete">🗑️ 删除</button>
    </div>
  </div>
</div>
```
### 5.10.2 CSS 样式
```css
/* ========== 高亮编辑弹窗 ========== */
#highlight-editor {
  position: fixed;
  z-index: 200;
  transition: opacity 0.15s, transform 0.15s;
}
#highlight-editor.hidden {
  opacity: 0;
  transform: translateY(8px);
  pointer-events: none;
}
.editor-arrow {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 0;
  border-left: 8px solid transparent;
  border-right: 8px solid transparent;
}
#highlight-editor.arrow-top .editor-arrow {
  top: -8px;
  border-bottom: 8px solid var(--bg-primary);
}
#highlight-editor.arrow-bottom .editor-arrow {
  bottom: -8px;
  border-top: 8px solid var(--bg-primary);
}
.editor-content {
  background: var(--bg-primary);
  border-radius: 12px;
  padding: 12px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.15);
  min-width: 240px;
}
/* 颜色选择行 */
.color-row {
  display: flex;
  gap: 8px;
  justify-content: center;
  margin-bottom: 12px;
}
.color-btn {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 2px solid transparent;
  cursor: pointer;
  transition: all 0.15s;
}
.color-btn:hover {
  transform: scale(1.1);
}
.color-btn.active {
  border-color: var(--text-primary);
  box-shadow: 0 0 0 2px var(--bg-primary), 0 0 0 4px currentColor;
}
/* 样式选择行 */
.style-row {
  display: flex;
  gap: 6px;
  justify-content: center;
  margin-bottom: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--border-color);
}
.style-btn {
  width: 36px;
  height: 36px;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  background: transparent;
  cursor: pointer;
  transition: all 0.15s;
}
.style-btn:hover {
  background: var(--bg-secondary);
}
.style-btn.active {
  border-color: var(--question-color);
  background: color-mix(in srgb, var(--question-color) 10%, transparent);
}
.style-btn .preview {
  font-weight: 600;
  color: var(--text-primary);
}
.style-btn .preview.bg {
  background: rgba(255, 241, 118, 0.6);
  padding: 2px 4px;
  border-radius: 2px;
}
.style-btn .preview.ul {
  text-decoration: underline;
  text-decoration-color: #FFF176;
  text-decoration-thickness: 2px;
}
.style-btn .preview.wavy {
  text-decoration: underline wavy;
  text-decoration-color: #FFF176;
}
.style-btn .preview.box {
  border: 2px solid #FFF176;
  padding: 1px 3px;
  border-radius: 2px;
}
.style-btn .preview.dashed {
  text-decoration: underline dashed;
  text-decoration-color: #FFF176;
  text-decoration-thickness: 2px;
}
/* 操作按钮行 */
.action-row {
  display: flex;
  gap: 8px;
  justify-content: center;
}
.action-row .action-btn {
  flex: 1;
  padding: 8px 12px;
  border: none;
  border-radius: 8px;
  background: var(--bg-secondary);
  color: var(--text-primary);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s;
}
.action-row .action-btn:hover {
  background: var(--border-color);
}
.action-row .action-btn.delete {
  color: #E57373;
}
.action-row .action-btn.delete:hover {
  background: rgba(229, 115, 115, 0.15);
}
```
### 5.10.3 JavaScript 逻辑
```js
// 当前编辑的高亮 ID
let currentEditingHighlightId = null;
// 显示编辑弹窗
function showHighlightEditor(highlightId, rect) {
  currentEditingHighlightId = highlightId;
  const editor = document.getElementById('highlight-editor');
  const highlight = getHighlightById(highlightId);
  if (!highlight) return;
  // 更新选中状态
  editor.querySelectorAll('.color-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.color === highlight.color);
  });
  editor.querySelectorAll('.style-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.style === highlight.style);
  });
  // 计算位置（优先显示在上方）
  const editorHeight = 160;
  const spaceAbove = rect.top;
  const spaceBelow = window.innerHeight - rect.bottom;
  let top, arrowClass;
  if (spaceAbove > editorHeight + 16) {
    top = rect.top - editorHeight - 8;
    arrowClass = 'arrow-bottom';
  } else {
    top = rect.bottom + 8;
    arrowClass = 'arrow-top';
  }
  const left = Math.max(16, Math.min(
    rect.left + rect.width / 2 - 120,
    window.innerWidth - 256
  ));
  editor.style.top = `${top}px`;
  editor.style.left = `${left}px`;
  editor.className = arrowClass;
  editor.classList.remove('hidden');
}
// 隐藏编辑弹窗
function hideHighlightEditor() {
  document.getElementById('highlight-editor').classList.add('hidden');
  currentEditingHighlightId = null;
}
// 事件绑定
document.getElementById('highlight-editor').addEventListener('click', (e) => {
  const colorBtn = e.target.closest('.color-btn');
  const styleBtn = e.target.closest('.style-btn');
  const actionBtn = e.target.closest('.action-btn');
  if (colorBtn && currentEditingHighlightId) {
    const newColor = colorBtn.dataset.color;
    updateHighlightColor(currentEditingHighlightId, newColor);
    // 更新 UI
    document.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
    colorBtn.classList.add('active');
    // 通知 Flutter
    FlutterBridge.onHighlightUpdated({
      highlightId: currentEditingHighlightId,
      color: newColor,
    });
  }
  if (styleBtn && currentEditingHighlightId) {
    const newStyle = styleBtn.dataset.style;
    const currentColor = getHighlightById(currentEditingHighlightId)?.color;
    updateHighlightStyle(currentEditingHighlightId, currentColor, newStyle);
    // 更新 UI
    document.querySelectorAll('.style-btn').forEach(b => b.classList.remove('active'));
    styleBtn.classList.add('active');
    // 通知 Flutter
    FlutterBridge.onHighlightUpdated({
      highlightId: currentEditingHighlightId,
      style: newStyle,
    });
  }
  if (actionBtn) {
    if (actionBtn.classList.contains('copy')) {
      const hl = getHighlightById(currentEditingHighlightId);
      if (hl) FlutterBridge.copyToClipboard({ text: hl.text, showToast: true });
    } else if (actionBtn.classList.contains('delete')) {
      removeHighlightInPlace(currentEditingHighlightId);
      FlutterBridge.onHighlightDeleted({ highlightId: currentEditingHighlightId });
      hideHighlightEditor();
    } else if (actionBtn.classList.contains('note')) {
      FlutterBridge.openAnnotationEditor({ highlightId: currentEditingHighlightId });
    }
  }
});
// 点击其他区域关闭
document.addEventListener('click', (e) => {
  if (!e.target.closest('#highlight-editor') && 
      !e.target.closest('mark.highlight')) {
    hideHighlightEditor();
  }
});
```
***
# 六、性能优化策略
## 6.1 分页加载 + 虚拟滚动
```js
// 首屏只渲染 3 轮
const INITIAL_ROUNDS = 3;
const LOAD_BATCH_SIZE = 5;
let loadedRounds = new Set();
let pendingRounds = [];
// IntersectionObserver 监听滚动
const observer = new IntersectionObserver((entries) => {
  for (const entry of entries) {
    if (entry.isIntersecting) {
      const roundIndex = parseInt(entry.target.dataset.roundIndex);
      // 预加载前后各 2 轮
      loadRoundsRange(roundIndex - 2, roundIndex + 2);
    }
  }
}, { rootMargin: '200px' });
// 按需加载轮次
function loadRoundsRange(start, end) {
  const toLoad = [];
  for (let i = Math.max(0, start); i <= Math.min(end, totalRounds - 1); i++) {
    if (!loadedRounds.has(i)) {
      toLoad.push(i);
    }
  }
  if (toLoad.length > 0) {
    FlutterBridge.requestRounds({ indices: toLoad });
  }
}
```
## 6.2 代码高亮懒加载
```js
// 可见时再高亮代码
const codeObserver = new IntersectionObserver((entries) => {
  for (const entry of entries) {
    if (entry.isIntersecting) {
      const pre = entry.target;
      if (!pre.dataset.highlighted) {
        hljs.highlightElement(pre.querySelector('code'));
        pre.dataset.highlighted = 'true';
      }
      codeObserver.unobserve(pre);
    }
  }
}, { rootMargin: '100px' });
// 对所有 <pre> 注册观察
document.querySelectorAll('pre[data-block-index]').forEach(pre => {
  codeObserver.observe(pre);
});
```
## 6.3 滚动节流
```js
let ticking = false;
window.addEventListener('scroll', () => {
  if (!ticking) {
    requestAnimationFrame(() => {
      updateEnergyBar();
      updateStickyHeader();
      ticking = false;
    });
    ticking = true;
  }
});
```
## 6.4 WebView 预热（启动优化）
**问题**：WebView 首次创建时需要初始化引擎、加载资源，导致页面打开较慢。
**解决方案**：预热 WebView 实例，提前加载框架，打开页面时只需注入数据。
### 6.4.1 Flutter 端：WebView 池
```dart
// lib/services/webview_pool.dart
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
/// WebView 预热池
class WebViewPool {
  static HeadlessInAppWebView? _preloadedWebView;
  static InAppWebViewController? _preloadedController;
  static bool _isWarmedUp = false;
  /// 预热 WebView（在 App 启动或空闲时调用）
  static Future<void> warmUp() async {
    if (_isWarmedUp) return;
    _preloadedWebView = HeadlessInAppWebView(
      initialFile: 'assets/webview/conversation.html',
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          javaScriptEnabled: true,
          transparentBackground: true,
        ),
      ),
      onWebViewCreated: (controller) {
        _preloadedController = controller;
      },
      onLoadStop: (controller, url) async {
        // 初始化框架（不注入数据）
        await controller.evaluateJavascript(
          source: 'window.initFramework && window.initFramework()',
        );
        _isWarmedUp = true;
        print('[WebViewPool] Warmed up successfully');
      },
    );
    await _preloadedWebView!.run();
  }
  /// 获取预热的控制器（使用后会自动预热下一个）
  static InAppWebViewController? getPreloadedController() {
    final controller = _preloadedController;
    // 清空并预热下一个
    _preloadedController = null;
    _preloadedWebView?.dispose();
    _preloadedWebView = null;
    _isWarmedUp = false;
    // 异步预热下一个
    Future.delayed(Duration(milliseconds: 500), () => warmUp());
    return controller;
  }
  /// 是否已预热
  static bool get isWarmedUp => _isWarmedUp;
  /// 销毁预热实例
  static void dispose() {
    _preloadedWebView?.dispose();
    _preloadedWebView = null;
    _preloadedController = null;
    _isWarmedUp = false;
  }
}
```
### 6.4.2 使用预热的 WebView
```dart
// lib/screens/webview_conversation_screen.dart
class WebViewConversationScreen extends StatefulWidget {
  final String topicId;
  const WebViewConversationScreen({required this.topicId});
  @override
  State<WebViewConversationScreen> createState() => _WebViewConversationScreenState();
}
class _WebViewConversationScreenState extends State<WebViewConversationScreen> {
  InAppWebViewController? _controller;
  bool _usePreloaded = false;
  @override
  void initState() {
    super.initState();
    // 尝试使用预热的 WebView
    if (WebViewPool.isWarmedUp) {
      _controller = WebViewPool.getPreloadedController();
      _usePreloaded = _controller != null;
      if (_usePreloaded) {
        // 直接注入数据
        _injectConversationData();
      }
    }
  }
  Future<void> _injectConversationData() async {
    final data = await _loadConversationData(widget.topicId);
    await _controller?.evaluateJavascript(
      source: 'window.loadConversation(${jsonEncode(data)})',
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_usePreloaded && _controller != null) {
      // 使用预热的 WebView（需要特殊处理）
      return _buildWithPreloadedWebView();
    }
    // 正常创建 WebView
    return InAppWebView(
      initialFile: 'assets/webview/conversation.html',
      onWebViewCreated: (controller) => _controller = controller,
      onLoadStop: (controller, url) => _injectConversationData(),
    );
  }
}
```
### 6.4.3 JS 端：数据热切换
```js
// assets/webview/conversation.js
// 框架初始化（预热时调用）
window.initFramework = function() {
  // 初始化 markdown-it
  window.md = markdownit({ html: true, linkify: true, breaks: true });
  // 配置 Prism.js
  Prism.plugins.autoloader.languages_path = './vendor/prism-components/';
  // 设置主题
  document.body.classList.add('framework-ready');
  console.log('[Framework] Initialized');
};
// 加载对话数据（打开页面时调用）
window.loadConversation = function(data) {
  // 清空现有内容
  document.getElementById('conversation-container').innerHTML = '';
  // 重置状态
  loadedRounds.clear();
  highlightsMap = {};
  // 注入新数据
  window.initConversation(data);
};
// 初始化对话（首次加载或数据切换）
window.initConversation = function(data) {
  const { topicId, topicName, isDarkMode, totalRounds, rounds, ...rest } = data;
  // 设置主题
  document.body.classList.toggle('theme-dark', isDarkMode);
  // 渲染轮次
  for (const round of rounds) {
    renderRound(round);
    loadedRounds.add(round.index);
  }
  // 恢复高亮
  for (const round of rounds) {
    if (round.highlights) {
      for (const [messageId, highlights] of Object.entries(round.highlights)) {
        highlightsMap[messageId] = highlights;
        const container = document.querySelector(`[data-message-id="${messageId}"] .markdown-body`);
        if (container) applyHighlights(container, highlights);
      }
    }
  }
  // 处理初始滚动
  if (rest.scrollToHighlightId) {
    scrollToHighlightAndFlash(rest.scrollToHighlightId);
  } else if (rest.scrollToRoundIndex != null) {
    scrollToRound(rest.scrollToRoundIndex);
  }
  // 通知 Flutter 就绪
  FlutterBridge.onContentReady({
    scrollHeight: document.body.scrollHeight,
    roundCount: loadedRounds.size,
  });
};
```
### 6.4.4 预热时机
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 应用启动后预热 WebView
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // 延迟执行，避免影响启动性能
    Future.delayed(Duration(seconds: 2), () {
      WebViewPool.warmUp();
    });
  });
  runApp(MyApp());
}
```
### 6.4.5 预热效果对比
| 场景 | 无预热 | 有预热 |
|------|--------|--------|
| 首次打开 WebView | ~800ms | ~800ms |
| 后续打开 WebView | ~600ms | ~150ms |
| 切换话题 | ~600ms | ~100ms (仅数据切换) |
***
# 七、文件清单
## 7.1 新增文件
| 文件 | 用途 |
|------|------|
| `assets/webview/conversation.html` | WebView 入口页面 |
| `assets/webview/conversation.css` | 主样式 |
| `assets/webview/conversation.js` | 主逻辑（轮次渲染、Tab 切换、能量条） |
| `assets/webview/highlight-manager.js` | 高亮系统（创建、恢复、删除） |
| `assets/webview/highlight.css` | 高亮样式 |
| `assets/webview/vendor/marked.min.js` | Markdown 解析 |
| `assets/webview/vendor/highlight.min.js` | 代码高亮 |
| `lib/screens/webview_conversation_screen.dart` | WebView 版页面 |
| `lib/services/conversation_bridge.dart` | Flutter-JS 通信桥接 |
| `lib/services/webview_pool.dart` | WebView 预热池 |
## 7.2 修改文件
| 文件 | 改动 |
|------|------|
| `lib/models/highlight_data.dart` | 完全重写，使用 v3.0 数据结构 |
| `lib/models/isar/knowledge_entry.dart` | 移除废弃字段，添加 `ranges` 字段 |
| `lib/services/highlight_service.dart` | 适配新数据结构 |
| `lib/screens/conversation_screen.dart` | 添加开关跳转到 WebView 版本 |
| `pubspec.yaml` | 添加 assets 声明 |
***
# 八、实施阶段
## Phase 1: 基础框架 (2-3 天)
* 创建 HTML/CSS/JS 基础结构
* 实现 Flutter ↔ JS 通信桥接
* 实现 Markdown 渲染 + Block 索引
* 实现 Tab 切换（无动画）
## Phase 2: 交互完善 (2-3 天)
* 实现 Swiper 滑动切换
* 实现能量条
* 实现侧滑抽屉
* 实现 Sticky Header
* 实现 TTS Mini Player UI
## Phase 3: 高亮系统 (2-3 天)
* 实现高亮恢复（HTML 注入）
* 实现文本选择 → 高亮工具栏
* 实现高亮创建 → Flutter 存储
* 实现高亮点击 → 编辑/删除
## Phase 4: 性能优化 (1-2 天)
* 实现分页加载
* 实现代码高亮懒加载
* 实现滚动节流
* 测试大数据量（50+ 轮）
## Phase 5: 收尾测试 (1-2 天)
* 暗色模式测试
* 边缘情况处理
* 性能基准测试
* 回退开关配置
***
# 九、风险与回退
| 风险 | 缓解措施 |
|------|----------|
| WebView 首屏慢 | 分页加载 + Skeleton 占位 |
| 高亮恢复失败 | 多策略定位（Block + 语义 + 模糊搜索） |
| 滚动性能问题 | CSS contain + requestAnimationFrame 节流 |
| 大数据量 DOM 过多 | IntersectionObserver 虚拟化 |
**回退方案**：保留原生 `conversation_screen.dart`，通过配置开关切换：
```dart
if (AppSettings.useWebViewConversation) {
  return WebViewConversationScreen(...);
} else {
  return ConversationScreen(...);
}
```
