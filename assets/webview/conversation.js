/**
 * 对话页面主逻辑 - 大纲导航版
 *
 * 功能：
 * - 框架初始化
 * - Markdown 渲染
 * - 大纲导航交互
 * - 回复切换
 * - 底部工具栏
 */

(function () {
  "use strict";

  // ========== 全局状态 ==========
  const state = {
    topicId: null,
    topicName: "",
    isDarkMode: false,
    totalRounds: 0,
    rounds: [],
    currentRoundIndex: 0,
    currentReplyIndex: 0,
    isInitialized: false,
    outlineCompact: null,
    outlineRoundExpansionOverrides: {},
    outlineExpansionMode: "auto",
    isProgrammaticScroll: false,
    programmaticScrollTimer: null,
    roundObserver: null,
    roundObserverTargets: new Set(),
  };

  function getScrollBehavior() {
    try {
      if (window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches) {
        return "auto";
      }
    } catch (_) {}
    return window.flutter_inappwebview ? "auto" : "smooth";
  }

  // ========== 模型颜色映射 ==========
  const MODEL_COLORS = {
    claude: "#8B5CF6",
    gpt: "#10B981",
    gemini: "#4285F4",
    deepseek: "#1E88E5",
    qwen: "#FF6B35",
    default: "#6B7280",
  };

  // ========== Markdown 渲染器 ==========
  let md = null;

  function initMarkdownRenderer() {
    if (!window.markdownit) {
      console.error("[Conversation] markdown-it not loaded");
      return;
    }

    md = window.markdownit({
      html: true,
      linkify: true,
      breaks: true,
      typographer: false,
    });

    // 配置 Prism 自动加载路径
    if (
      window.Prism &&
      window.Prism.plugins &&
      window.Prism.plugins.autoloader
    ) {
      window.Prism.plugins.autoloader.languages_path =
        "./vendor/prism-components/";
    }
  }

  function renderMarkdown(content, messageId) {
    if (!md) {
      initMarkdownRenderer();
    }

    if (!md) {
      return `<p data-block-index="0">${escapeHtml(content)}</p>`;
    }

    const tokens = md.parse(content, {});

    let blockIndex = 0;
    function processTokens(tokens) {
      for (const token of tokens) {
        if (
          token.type === "paragraph_open" ||
          token.type === "heading_open" ||
          token.type === "list_item_open" ||
          token.type === "blockquote_open" ||
          token.type === "code_block" ||
          token.type === "fence" ||
          token.type === "table_open" ||
          token.type === "hr"
        ) {
          token.attrPush(["data-block-index", String(blockIndex++)]);
        }
        if (token.children) {
          processTokens(token.children);
        }
      }
    }

    processTokens(tokens);
    return md.renderer.render(tokens, md.options, {});
  }

  function escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  function getModelColor(modelId) {
    const lowerModel = (modelId || "").toLowerCase();
    for (const [key, color] of Object.entries(MODEL_COLORS)) {
      if (lowerModel.includes(key)) {
        return color;
      }
    }
    return MODEL_COLORS.default;
  }

  function truncateText(text, maxLength) {
    if (!text) return "";
    const plainText = text
      .replace(/[#*`\[\]()]/g, "")
      .replace(/\s+/g, " ")
      .trim();
    if (plainText.length <= maxLength) return plainText;
    return plainText.substring(0, maxLength) + "...";
  }

  function toPlainText(text) {
    if (!text) return "";
    return text
      .replace(/[#*`\[\]()]/g, "")
      .replace(/\s+/g, " ")
      .trim();
  }

  function truncatePlainText(plainText, maxLength) {
    if (!plainText) return "";
    if (plainText.length <= maxLength) return plainText;
    return plainText.substring(0, maxLength) + "...";
  }

  // ========== 轮次渲染（简化版）==========
  function renderRound(round) {
    const container = document.getElementById("conversation-container");
    if (!container) return;

    const roundEl = document.createElement("article");
    roundEl.className = "round-card";
    roundEl.dataset.roundIndex = round.index;

    // 问题区
    const questionHtml = renderQuestionSection(round);

    // 回复区（只显示当前选中的回复）
    const replyHtml = renderReplySection(round, 0);

    roundEl.innerHTML = questionHtml + replyHtml;
    container.appendChild(roundEl);

    // 检查是否需要折叠
    checkQuestionCollapse(roundEl);

    // 代码高亮
    scheduleCodeHighlight(roundEl);
  }

  function renderQuestionSection(round) {
    const user = round.userMessage || {};
    const qLabel = `Q${round.index + 1}`;
    const questionContent = renderMarkdown(user.content || "", user.id || "");
    return `
      <section class="question-section">
        <div class="color-bar"></div>
        <div class="content">
          <div style="display:flex;align-items:center">
            <span class="q-label">${qLabel}</span>
            <span class="question-expand-hint">（双击展开）</span>
          </div>
          <div class="question-text" data-message-id="${user.id || ""}">
            ${questionContent}
          </div>
        </div>
      </section>
    `;
  }

  function checkQuestionCollapse(roundEl) {
    const questionSection = roundEl.querySelector(".question-section");
    const questionText = roundEl.querySelector(".question-text");
    if (!questionSection || !questionText) return;

    // 绑定双击事件
    questionSection.addEventListener("dblclick", () => {
      if (questionSection.classList.contains("collapsible")) {
        questionSection.classList.toggle("collapsed");
        // 更新提示文案
        const hint = questionSection.querySelector(".question-expand-hint");
        if (hint) {
          hint.textContent = questionSection.classList.contains("collapsed")
            ? "（双击展开）"
            : "（双击收起）";
        }
      }
    });

    // 检查高度（延迟执行确保渲染完成）
    requestAnimationFrame(() => {
      const maxHeight = window.innerHeight * 0.35; // 约1/3屏幕高度
      if (questionText.scrollHeight > maxHeight) {
        questionSection.classList.add("collapsible", "collapsed");
      }
    });
  }

  function renderReplySection(round, replyIndex) {
    const replies = round.assistantReplies || [];
    if (replies.length === 0) {
      return '<section class="reply-section"><p style="color:var(--text-tertiary)">暂无回复</p></section>';
    }

    const reply = replies[replyIndex] || replies[0];
    const modelColor = getModelColor(reply.modelId || reply.modelName || "");
    const replyContent = renderMarkdown(reply.content || "", reply.id || "");
    const mainlineStar = reply.isMainline
      ? '<span class="mainline-star">★</span>'
      : "";

    return `
      <section class="reply-section" data-round-index="${round.index}" data-current-reply="${replyIndex}">
        <div class="reply-header">
          <div class="reply-model-badge" style="--model-color: ${modelColor}">
            <span class="model-dot" style="background: ${modelColor}"></span>
            <span>${reply.modelName || "AI"}</span>
            ${mainlineStar}
          </div>
        </div>
        <div class="reply-content markdown-body" data-message-id="${reply.id || ""}">
          ${replyContent}
        </div>
      </section>
    `;
  }

  // ========== 切换回复 ==========
  function switchReply(roundIndex, replyIndex) {
    const round = state.rounds.find((r) => r.index === roundIndex);
    if (!round) return;

    const replies = round.assistantReplies || [];
    if (replyIndex < 0 || replyIndex >= replies.length) return;

    // 更新状态
    state.currentRoundIndex = roundIndex;
    state.currentReplyIndex = replyIndex;

    // 更新主内容区
    const roundEl = document.querySelector(
      `.round-card[data-round-index="${roundIndex}"]`,
    );
    if (roundEl) {
      const oldReplySection = roundEl.querySelector(".reply-section");
      if (oldReplySection) {
        const newReplyHtml = renderReplySection(round, replyIndex);
        oldReplySection.outerHTML = newReplyHtml;
        scheduleCodeHighlight(roundEl);
        const replyMessageId = replies[replyIndex]?.id || null;
        if (
          replyMessageId &&
          window.HighlightManager &&
          round.highlights &&
          round.highlights[replyMessageId]
        ) {
          window.HighlightManager.applyHighlights(
            replyMessageId,
            round.highlights[replyMessageId],
          );
        }
      }
    }

    // 更新大纲导航高亮
    updateOutlineActive();

    // 更新底部工具栏
    updateToolbar();

    // 滚动到该轮次
    scrollToRound(roundIndex);

    // 通知 Flutter
    if (window.FlutterBridge && window.FlutterBridge.onTabChanged) {
      const reply = replies[replyIndex];
      window.FlutterBridge.onTabChanged({
        roundIndex,
        replyIndex,
        messageId: reply?.id || null,
      });
    }
  }

  function scrollToRound(index) {
    const round = document.querySelector(
      `.round-card[data-round-index="${index}"]`,
    );
    if (round) {
      state.isProgrammaticScroll = true;
      if (state.programmaticScrollTimer) {
        clearTimeout(state.programmaticScrollTimer);
      }
      state.programmaticScrollTimer = setTimeout(() => {
        state.isProgrammaticScroll = false;
        state.programmaticScrollTimer = null;
      }, 520);
      round.scrollIntoView({ behavior: getScrollBehavior(), block: "start" });
    }
  }

  // ========== 大纲导航 ==========
  function initOutlineSidebar() {
    const sidebar = document.getElementById("outline-sidebar");
    if (!sidebar) return;
    document.body.classList.add("has-sidebar");

    // 折叠/展开侧边栏
    const handle = document.querySelector(".sidebar-handle");
    const OUTLINE_SIDEBAR_OPEN_KEY = "cv_outline_sidebar_open";
    const mobileQuery = window.matchMedia?.("(max-width: 768px)") ?? null;

    function getEffectiveViewportWidth() {
      const w = window.visualViewport?.width;
      return typeof w === "number" && w > 0 ? w : window.innerWidth || 0;
    }

    function isMobile() {
      const width = getEffectiveViewportWidth();
      if (width) return width <= 768;
      return mobileQuery?.matches ?? false;
    }

    let viewportSyncPending = false;
    function scheduleViewportSync() {
      if (viewportSyncPending) return;
      viewportSyncPending = true;
      requestAnimationFrame(() => {
        viewportSyncPending = false;
        applySidebarOpen(state.outlineSidebarOpen);
      });
    }

    function applySidebarOpen(open) {
      state.outlineSidebarOpen = !!open;

      document.body.classList.toggle("force-mobile", isMobile());

      if (isMobile()) {
        sidebar.classList.toggle("mobile-visible", state.outlineSidebarOpen);
        sidebar.classList.remove("collapsed");
        document.body.classList.remove("sidebar-collapsed");
      } else {
        sidebar.classList.toggle("collapsed", !state.outlineSidebarOpen);
        sidebar.classList.remove("mobile-visible");
        document.body.classList.toggle(
          "sidebar-collapsed",
          !state.outlineSidebarOpen,
        );
      }

      try {
        localStorage.setItem(
          OUTLINE_SIDEBAR_OPEN_KEY,
          state.outlineSidebarOpen ? "1" : "0",
        );
      } catch (_) {}
    }

    function readInitialSidebarOpen() {
      try {
        const saved = localStorage.getItem(OUTLINE_SIDEBAR_OPEN_KEY);
        if (saved === "1" || saved === "0") {
          return saved === "1";
        }
      } catch (_) {}
      return false;
    }

    applySidebarOpen(readInitialSidebarOpen());

    if (mobileQuery?.addEventListener) {
      mobileQuery.addEventListener("change", scheduleViewportSync);
    } else if (mobileQuery?.addListener) {
      mobileQuery.addListener(scheduleViewportSync);
    }

    window.visualViewport?.addEventListener?.("resize", scheduleViewportSync);
    window.addEventListener("resize", scheduleViewportSync, { passive: true });

    handle?.addEventListener("click", () => {
      applySidebarOpen(!state.outlineSidebarOpen);
    });

    document.addEventListener(
      "click",
      (event) => {
        if (!state.outlineSidebarOpen) return;
        if (!isMobile()) return;

        const selection = window.getSelection?.();
        if (selection && !selection.isCollapsed) return;

        const target = event.target;
        if (!(target instanceof Node)) return;
        if (sidebar.contains(target)) return;
        if (handle && handle.contains(target)) return;

        applySidebarOpen(false);
      },
      true,
    );

    const modeToggle = sidebar.querySelector(".outline-mode-toggle");
    const expandToggle = sidebar.querySelector(".outline-expand-toggle");

    const OUTLINE_COMPACT_KEY = "cv_outline_compact";

    function applyOutlineCompact(isCompact) {
      state.outlineCompact = !!isCompact;
      document.body.classList.toggle("outline-compact", state.outlineCompact);
      try {
        localStorage.setItem(
          OUTLINE_COMPACT_KEY,
          state.outlineCompact ? "1" : "0",
        );
      } catch (_) {}
    }

    try {
      const saved = localStorage.getItem(OUTLINE_COMPACT_KEY);
      if (saved === "1" || saved === "0") {
        applyOutlineCompact(saved === "1");
      } else {
        applyOutlineCompact(
          window.matchMedia?.("(max-width: 520px)")?.matches ?? true,
        );
      }
    } catch (_) {
      applyOutlineCompact(
        window.matchMedia?.("(max-width: 520px)")?.matches ?? true,
      );
    }

    modeToggle?.addEventListener("click", () => {
      applyOutlineCompact(!state.outlineCompact);
    });

    function syncExpandToggleState() {
      const isAll = state.outlineExpansionMode === "all";
      sidebar.classList.toggle("outline-all-expanded", isAll);
      if (expandToggle) {
        const label = isAll ? "收起全部" : "展开全部";
        expandToggle.setAttribute("aria-label", label);
        expandToggle.setAttribute("title", label);
      }
    }

    expandToggle?.addEventListener("click", () => {
      state.outlineExpansionMode =
        state.outlineExpansionMode === "all" ? "none" : "all";
      syncExpandToggleState();
      state.outlineRoundExpansionOverrides = {};
      applyOutlineExpansionState();
    });

    syncExpandToggleState();
  }

  function setRoundExpanded(item, expanded) {
    item.classList.toggle("expanded", expanded);
    const btn = item.querySelector(".outline-round");
    btn?.setAttribute("aria-expanded", expanded ? "true" : "false");
  }

  function getRoundOverride(roundIndex) {
    if (!state.outlineRoundExpansionOverrides) return undefined;
    const key = String(roundIndex);
    if (
      !Object.prototype.hasOwnProperty.call(
        state.outlineRoundExpansionOverrides,
        key,
      )
    ) {
      return undefined;
    }
    return !!state.outlineRoundExpansionOverrides[key];
  }

  function setSingleRoundOverride(roundIndex, expanded) {
    state.outlineRoundExpansionOverrides = { [String(roundIndex)]: !!expanded };
  }

  function applyOutlineExpansionState() {
    const nav = document.querySelector(".outline-nav");
    if (!nav) return;
    nav.querySelectorAll(".outline-item").forEach((item) => {
      const roundIndex = parseInt(item.dataset.roundIndex, 10);
      let shouldExpand = false;
      if (state.outlineExpansionMode === "all") {
        shouldExpand = true;
      } else if (state.outlineExpansionMode === "none") {
        shouldExpand = false;
      } else {
        const override = getRoundOverride(roundIndex);
        shouldExpand =
          override !== undefined
            ? override
            : roundIndex === state.currentRoundIndex;
      }
      setRoundExpanded(item, shouldExpand);
    });
  }

  function renderOutlineNav(rounds) {
    const nav = document.querySelector(".outline-nav");
    if (!nav || !rounds || rounds.length === 0) return;

    const html = rounds
      .map((round, idx) => {
        const roundKey =
          typeof round?.index === "number" && Number.isFinite(round.index)
            ? round.index
            : idx;
        const user = round.userMessage || {};
        const replies = round.assistantReplies || [];

        const plainQuestion = toPlainText(user.content || "");
        const questionTitle = truncatePlainText(
          plainQuestion || `Q${idx + 1}`,
          52,
        );

        const repliesHtml = replies
          .map((reply, replyIdx) => {
            const modelColor = getModelColor(
              reply.modelId || reply.modelName || "",
            );
            const isActive = idx === 0 && replyIdx === 0 ? "active" : "";
            const replyPreview = truncatePlainText(
              toPlainText(reply.content || ""),
              120,
            );
            const modelName = reply.modelName || "AI";
            const mainlineStar = reply.isMainline
              ? '<span class="outline-leaf-mainline" aria-hidden="true">★</span>'
              : "";

            return `
          <button
            class="outline-leaf ${isActive}"
            type="button"
            data-round-index="${roundKey}"
            data-reply-index="${replyIdx}"
            style="--model-color: ${modelColor}"
          >
            <span class="outline-leaf-dot" aria-hidden="true"></span>
            <span class="outline-leaf-body">
              <span class="outline-leaf-meta">
                <span class="outline-leaf-model">${escapeHtml(modelName)}</span>
                ${mainlineStar}
              </span>
              <span class="outline-leaf-preview">${escapeHtml(replyPreview)}</span>
            </span>
          </button>
        `;
          })
          .join("");

        const isExpanded =
          roundKey === state.currentRoundIndex ? "expanded" : "";
        const isActive = roundKey === state.currentRoundIndex ? "active" : "";

        return `
        <div
          class="outline-item ${isExpanded} ${isActive}"
          data-round-index="${roundKey}"
        >
          <button
            class="outline-round"
            type="button"
            data-round-index="${roundKey}"
            aria-expanded="${roundKey === state.currentRoundIndex ? "true" : "false"}"
          >
            <span class="outline-round-rail" aria-hidden="true"></span>
            <span class="outline-round-badge">Q${idx + 1}</span>
            <span class="outline-round-title">${escapeHtml(questionTitle)}</span>
            <span class="outline-round-count">${replies.length}</span>
            <svg
              class="outline-chevron"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2.2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M9 18l6-6-6-6"></path>
            </svg>
          </button>
          <div class="outline-children">
            ${repliesHtml}
          </div>
        </div>
      `;
      })
      .join("");

    nav.innerHTML = html;

    // 绑定事件
    nav.querySelectorAll(".outline-round").forEach((btn) => {
      btn.addEventListener("click", () => {
        const item = btn.closest(".outline-item");
        const roundIndex = parseInt(item.dataset.roundIndex, 10);
        const isExpanded = item.classList.contains("expanded");
        const nextExpanded = !isExpanded;

        if (state.outlineExpansionMode === "none") {
          state.outlineExpansionMode = "auto";
          state.outlineRoundExpansionOverrides = {};
          setSingleRoundOverride(roundIndex, true);
        } else if (state.outlineExpansionMode === "auto") {
          setSingleRoundOverride(roundIndex, nextExpanded);
        }

        scrollToRound(roundIndex);
        state.currentRoundIndex = roundIndex;
        updateOutlineActive();
      });
    });

    nav.querySelectorAll(".outline-leaf").forEach((leaf) => {
      leaf.addEventListener("click", (e) => {
        e.stopPropagation();
        const roundIndex = parseInt(leaf.dataset.roundIndex, 10);
        const replyIndex = parseInt(leaf.dataset.replyIndex, 10);
        switchReply(roundIndex, replyIndex);
      });
    });
    applyOutlineExpansionState();
  }

  function updateOutlineActive() {
    const nav = document.querySelector(".outline-nav");
    if (!nav) return;

    // 更新问题高亮
    nav.querySelectorAll(".outline-item").forEach((item) => {
      const roundIndex = parseInt(item.dataset.roundIndex, 10);
      item.classList.toggle("active", roundIndex === state.currentRoundIndex);
    });

    // 更新回复高亮
    nav.querySelectorAll(".outline-leaf").forEach((leaf) => {
      const roundIndex = parseInt(leaf.dataset.roundIndex, 10);
      const replyIndex = parseInt(leaf.dataset.replyIndex, 10);
      const isActive =
        roundIndex === state.currentRoundIndex &&
        replyIndex === state.currentReplyIndex;
      leaf.classList.toggle("active", isActive);
    });

    applyOutlineExpansionState();

    const currentItem = nav.querySelector(
      `.outline-item[data-round-index="${state.currentRoundIndex}"]`,
    );

    // 【新增】导航区自动滚动到当前项，确保可见
    if (currentItem) {
      const navRect = nav.getBoundingClientRect();
      const itemRect = currentItem.getBoundingClientRect();

      // 只在当前项不在可视区域内时滚动
      if (itemRect.top < navRect.top || itemRect.bottom > navRect.bottom) {
        currentItem.scrollIntoView({
          behavior: getScrollBehavior(),
          block: "nearest",
        });
      }
    }
  }

  // ========== 底部工具栏 ==========
  function initToolbar() {
    const toolbar = document.getElementById("content-toolbar");
    if (!toolbar) return;

    const prevBtn = toolbar.querySelector(".nav-btn.prev");
    const nextBtn = toolbar.querySelector(".nav-btn.next");
    const ttsBtn = toolbar.querySelector(".action-btn.tts");
    const discussBtn = toolbar.querySelector(".action-btn.discuss");
    const copyBtn = toolbar.querySelector(".action-btn.copy");

    prevBtn?.addEventListener("click", () => {
      if (state.currentReplyIndex > 0) {
        switchReply(state.currentRoundIndex, state.currentReplyIndex - 1);
      }
    });

    nextBtn?.addEventListener("click", () => {
      const round = state.rounds[state.currentRoundIndex];
      const maxReply = (round?.assistantReplies?.length || 1) - 1;
      if (state.currentReplyIndex < maxReply) {
        switchReply(state.currentRoundIndex, state.currentReplyIndex + 1);
      }
    });

    ttsBtn?.addEventListener("click", () => {
      if (window.FlutterBridge && window.FlutterBridge.playTTS) {
        window.FlutterBridge.playTTS({ roundIndex: state.currentRoundIndex });
      }
    });

    discussBtn?.addEventListener("click", () => {
      if (window.FlutterBridge && window.FlutterBridge.openDiscussion) {
        window.FlutterBridge.openDiscussion({
          roundIndex: state.currentRoundIndex,
        });
      }
    });

    copyBtn?.addEventListener("click", () => {
      const round = state.rounds[state.currentRoundIndex];
      const reply = round?.assistantReplies?.[state.currentReplyIndex];
      if (reply?.content) {
        if (window.FlutterBridge && window.FlutterBridge.copyToClipboard) {
          window.FlutterBridge.copyToClipboard({ text: reply.content });
        } else {
          navigator.clipboard.writeText(reply.content).then(() => {
            console.log("[Toolbar] Copied to clipboard");
          });
        }
      }
    });
  }

  function updateToolbar() {
    const toolbar = document.getElementById("content-toolbar");
    if (!toolbar) return;

    const round = state.rounds[state.currentRoundIndex];
    const totalReplies = round?.assistantReplies?.length || 0;

    const indicator = toolbar.querySelector(".reply-indicator");
    const prevBtn = toolbar.querySelector(".nav-btn.prev");
    const nextBtn = toolbar.querySelector(".nav-btn.next");

    if (indicator) {
      indicator.textContent = `${state.currentReplyIndex + 1}/${totalReplies}`;
    }

    if (prevBtn) {
      prevBtn.disabled = state.currentReplyIndex <= 0;
    }

    if (nextBtn) {
      nextBtn.disabled = state.currentReplyIndex >= totalReplies - 1;
    }
  }

  // ========== 代码高亮 ==========
  function scheduleCodeHighlight(container) {
    requestIdleCallback(
      () => {
        const codeBlocks = container.querySelectorAll("pre code");
        codeBlocks.forEach((code) => {
          if (window.Prism) {
            window.Prism.highlightElement(code);
          }
        });
      },
      { timeout: 500 },
    );
  }

  window.requestIdleCallback =
    window.requestIdleCallback ||
    function (cb, opts) {
      const start = Date.now();
      return setTimeout(() => {
        cb({
          didTimeout: false,
          timeRemaining: () => Math.max(0, 50 - (Date.now() - start)),
        });
      }, opts?.timeout || 1);
    };

  // ========== 滚动处理 ==========
  let scrollTicking = false;

  function onScroll() {
    if (!scrollTicking) {
      requestAnimationFrame(() => {
        calculateCurrentRound();
        updateOutlineActive();
        scrollTicking = false;
      });
      scrollTicking = true;
    }
  }

  function calculateCurrentRound() {
    const container = document.getElementById("conversation-container");
    if (!container) return;
    if (state.isProgrammaticScroll) return;

    const rounds = container.querySelectorAll(".round-card");
    const viewportTop = 80;

    for (let i = 0; i < rounds.length; i++) {
      const round = rounds[i];
      const rect = round.getBoundingClientRect();

      if (rect.top <= viewportTop && rect.bottom > viewportTop) {
        const newIndex = parseInt(round.dataset.roundIndex, 10);
        if (newIndex !== state.currentRoundIndex) {
          state.currentRoundIndex = newIndex;
          if (state.outlineExpansionMode === "auto") {
            state.outlineRoundExpansionOverrides = {};
          }
          // 获取该轮次当前显示的回复索引
          const replySection = round.querySelector(".reply-section");
          state.currentReplyIndex = parseInt(
            replySection?.dataset.currentReply || "0",
            10,
          );
          updateToolbar();
        }
        break;
      }
    }
  }

  function ensureRoundObserver() {
    if (!("IntersectionObserver" in window)) return;
    if (state.roundObserver) return;

    state.roundObserver = new IntersectionObserver(
      (entries) => {
        if (state.isProgrammaticScroll) return;
        const candidates = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        const chosen = candidates[0];
        if (!chosen) return;

        const newIndex = parseInt(chosen.target.dataset.roundIndex, 10);
        if (Number.isNaN(newIndex)) return;
        if (newIndex === state.currentRoundIndex) return;

        state.currentRoundIndex = newIndex;
        if (state.outlineExpansionMode === "auto") {
          state.outlineRoundExpansionOverrides = {};
        }
        const replySection = chosen.target.querySelector(".reply-section");
        state.currentReplyIndex = parseInt(
          replySection?.dataset.currentReply || "0",
          10,
        );
        updateToolbar();
        updateOutlineActive();
      },
      {
        root: null,
        rootMargin: "-80px 0px -65% 0px",
        threshold: [0, 0.1, 0.25, 0.5, 0.75],
      },
    );
  }

  function refreshRoundObserverTargets() {
    ensureRoundObserver();
    if (!state.roundObserver) return;
    const rounds = document.querySelectorAll(".round-card");
    rounds.forEach((el) => {
      if (state.roundObserverTargets.has(el)) return;
      state.roundObserver.observe(el);
      state.roundObserverTargets.add(el);
    });
  }

  // ========== 初始化 ==========
  function init() {
    if (state.isInitialized) return;
    console.log("[Conversation] Initializing...");

    if (window.flutter_inappwebview) {
      document.body.classList.add("host-flutter");
    }

    initMarkdownRenderer();
    initOutlineSidebar();
    initToolbar();

    window.addEventListener("scroll", onScroll, { passive: true });

    state.isInitialized = true;
    document.body.classList.add("framework-ready");

    console.log("[Conversation] Framework ready");
  }

  // ========== 对外 API ==========
  window.initFramework = function () {
    init();
  };

  window.loadConversation = function (data) {
    console.log("[Conversation] Loading conversation data...", data);

    const container = document.getElementById("conversation-container");
    if (container) {
      container.innerHTML = "";
    }

    if (state.roundObserver) {
      state.roundObserver.disconnect();
      state.roundObserver = null;
    }
    state.roundObserverTargets = new Set();

    state.currentRoundIndex = 0;
    state.currentReplyIndex = 0;

    window.initConversation(data);
  };

  window.initConversation = function (data) {
    console.log("[Conversation] Initializing conversation...");

    const { topicId, topicName, isDarkMode, totalRounds, rounds, ...rest } =
      data;

    state.topicId = topicId;
    state.topicName = topicName || "";
    state.isDarkMode = isDarkMode || false;
    state.totalRounds = totalRounds || (rounds ? rounds.length : 0);
    state.rounds = rounds || [];

    document.body.classList.toggle("theme-dark", state.isDarkMode);

    const firstRoundIndex =
      rounds && Array.isArray(rounds) && rounds.length
        ? typeof rounds[0]?.index === "number"
          ? rounds[0].index
          : 0
        : 0;
    const initialRoundIndex =
      rest.scrollToRoundIndex != null
        ? rest.scrollToRoundIndex
        : firstRoundIndex;
    state.currentRoundIndex = initialRoundIndex;
    state.currentReplyIndex = 0;
    if (state.outlineExpansionMode === "auto") {
      state.outlineRoundExpansionOverrides = {};
    }

    // 渲染轮次
    if (rounds && Array.isArray(rounds)) {
      for (const round of rounds) {
        renderRound(round);
      }
    }

    // 渲染大纲导航
    renderOutlineNav(rounds);
    refreshRoundObserverTargets();
    updateOutlineActive();

    // 更新工具栏
    updateToolbar();

    // 恢复高亮
    if (rounds && window.HighlightManager) {
      for (const round of rounds) {
        if (round.highlights) {
          for (const [messageId, highlights] of Object.entries(
            round.highlights,
          )) {
            window.HighlightManager.applyHighlights(messageId, highlights);
          }
        }
      }
    }

    function findHighlightMessageId(highlightId) {
      if (!highlightId || !rounds || !Array.isArray(rounds)) return null;
      for (const round of rounds) {
        const highlightsByMessage = round?.highlights;
        if (!highlightsByMessage) continue;
        for (const [messageId, highlights] of Object.entries(
          highlightsByMessage,
        )) {
          if (!Array.isArray(highlights)) continue;
          if (highlights.some((h) => h?.id === highlightId)) return messageId;
        }
      }
      return null;
    }

    function findMessageLocation(messageId) {
      if (!messageId || !rounds || !Array.isArray(rounds)) return null;
      for (const round of rounds) {
        const userId = round?.userMessage?.id;
        if (userId && userId === messageId) {
          return { roundIndex: round.index, replyIndex: null, role: "user" };
        }
        const replies = round?.assistantReplies || [];
        for (let i = 0; i < replies.length; i++) {
          if (replies[i]?.id === messageId) {
            return {
              roundIndex: round.index,
              replyIndex: i,
              role: "assistant",
            };
          }
        }
      }
      return null;
    }

    function scrollToMessage(messageId) {
      const el = document.querySelector(`[data-message-id="${messageId}"]`);
      if (!el) return false;
      el.scrollIntoView({ behavior: getScrollBehavior(), block: "center" });
      return true;
    }

    // 处理初始滚动
    const targetHighlightId = rest.scrollToHighlightId || null;
    const targetMessageId =
      findHighlightMessageId(targetHighlightId) ||
      rest.scrollToMessageId ||
      null;
    const targetLocation = findMessageLocation(targetMessageId);

    if (targetLocation && typeof targetLocation.roundIndex === "number") {
      if (typeof targetLocation.replyIndex === "number") {
        switchReply(targetLocation.roundIndex, targetLocation.replyIndex);
      } else {
        scrollToRound(targetLocation.roundIndex);
      }
    }

    if (targetHighlightId && window.HighlightManager) {
      setTimeout(() => {
        window.HighlightManager.scrollToHighlight(targetHighlightId);
      }, 120);
    } else if (targetMessageId) {
      setTimeout(() => {
        let didScroll = false;
        if (window.HighlightManager) {
          const start = rest.scrollToTextStart;
          const end =
            rest.scrollToTextEnd != null
              ? rest.scrollToTextEnd
              : start != null
                ? start + 1
                : null;
          const quote = rest.scrollToQuotedText;
          const occurrence =
            rest.scrollToQuotedTextOccurrence != null
              ? rest.scrollToQuotedTextOccurrence
              : 0;

          if (
            start != null &&
            end != null &&
            typeof window.HighlightManager.scrollToTextRange === "function"
          ) {
            didScroll = window.HighlightManager.scrollToTextRange(
              targetMessageId,
              start,
              end,
            );
          } else if (
            quote &&
            typeof window.HighlightManager.scrollToText === "function"
          ) {
            didScroll = window.HighlightManager.scrollToText(
              targetMessageId,
              quote,
              occurrence,
            );
          }
        }

        if (
          !didScroll &&
          !scrollToMessage(targetMessageId) &&
          rest.scrollToRoundIndex != null
        ) {
          scrollToRound(rest.scrollToRoundIndex);
        }
      }, 120);
    } else if (rest.scrollToRoundIndex != null) {
      setTimeout(() => {
        scrollToRound(rest.scrollToRoundIndex);
      }, 120);
    }

    // 通知 Flutter 就绪
    if (window.FlutterBridge && window.FlutterBridge.onContentReady) {
      window.FlutterBridge.onContentReady({
        scrollHeight: document.body.scrollHeight,
        roundCount: state.rounds.length,
      });
    }

    console.log("[Conversation] Initialization complete");
  };

  window.appendRounds = function (rounds) {
    if (!rounds || !Array.isArray(rounds)) return;
    for (const round of rounds) {
      renderRound(round);
    }
    refreshRoundObserverTargets();
  };

  window.setDarkMode = function (isDark) {
    state.isDarkMode = isDark;
    document.body.classList.toggle("theme-dark", isDark);
  };

  window.scrollToRound = scrollToRound;

  window.navigateTo = function (params) {
    const p = params || {};
    const rounds = state.rounds || [];

    function findHighlightMessageId(highlightId) {
      if (!highlightId || !rounds || !Array.isArray(rounds)) return null;
      for (const round of rounds) {
        const highlightsByMessage = round?.highlights;
        if (!highlightsByMessage) continue;
        for (const [messageId, highlights] of Object.entries(
          highlightsByMessage,
        )) {
          if (!Array.isArray(highlights)) continue;
          if (highlights.some((h) => h?.id === highlightId)) return messageId;
        }
      }
      return null;
    }

    function findMessageLocation(messageId) {
      if (!messageId || !rounds || !Array.isArray(rounds)) return null;
      for (const round of rounds) {
        const userId = round?.userMessage?.id;
        if (userId && userId === messageId) {
          return { roundIndex: round.index, replyIndex: null, role: "user" };
        }
        const replies = round?.assistantReplies || [];
        for (let i = 0; i < replies.length; i++) {
          if (replies[i]?.id === messageId) {
            return {
              roundIndex: round.index,
              replyIndex: i,
              role: "assistant",
            };
          }
        }
      }
      return null;
    }

    function scrollToMessageId(messageId) {
      const el = document.querySelector(`[data-message-id="${messageId}"]`);
      if (!el) return false;
      el.scrollIntoView({ behavior: getScrollBehavior(), block: "center" });
      return true;
    }

    const targetHighlightId = p.scrollToHighlightId || null;
    const targetMessageId =
      findHighlightMessageId(targetHighlightId) || p.scrollToMessageId || null;
    const targetLocation = findMessageLocation(targetMessageId);

    if (targetLocation && typeof targetLocation.roundIndex === "number") {
      if (typeof targetLocation.replyIndex === "number") {
        switchReply(targetLocation.roundIndex, targetLocation.replyIndex);
      } else {
        scrollToRound(targetLocation.roundIndex);
      }
    } else if (p.scrollToRoundIndex != null) {
      scrollToRound(p.scrollToRoundIndex);
    }

    setTimeout(() => {
      if (targetHighlightId && window.HighlightManager) {
        window.HighlightManager.scrollToHighlight(targetHighlightId);
        return;
      }

      if (targetMessageId) {
        let didScroll = false;
        if (window.HighlightManager) {
          const start = p.scrollToTextStart;
          const end =
            p.scrollToTextEnd != null
              ? p.scrollToTextEnd
              : start != null
                ? start + 1
                : null;
          const quote = p.scrollToQuotedText;
          const occurrence =
            p.scrollToQuotedTextOccurrence != null
              ? p.scrollToQuotedTextOccurrence
              : 0;

          if (
            start != null &&
            end != null &&
            typeof window.HighlightManager.scrollToTextRange === "function"
          ) {
            didScroll = window.HighlightManager.scrollToTextRange(
              targetMessageId,
              start,
              end,
            );
          } else if (
            quote &&
            typeof window.HighlightManager.scrollToText === "function"
          ) {
            didScroll = window.HighlightManager.scrollToText(
              targetMessageId,
              quote,
              occurrence,
            );
          }
        }

        if (!didScroll) {
          if (
            !scrollToMessageId(targetMessageId) &&
            p.scrollToRoundIndex != null
          ) {
            scrollToRound(p.scrollToRoundIndex);
          }
        }
        return;
      }

      if (p.scrollToRoundIndex != null) {
        scrollToRound(p.scrollToRoundIndex);
      }
    }, 120);

    return true;
  };

  // ========== FlutterBridge ==========
  window.FlutterBridge = {
    onContentReady: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("onContentReady", data);
      } else {
        console.log("[FlutterBridge] onContentReady:", data);
      }
    },
    onScrollChanged: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("onScrollChanged", data);
      }
    },
    onTabChanged: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("onTabChanged", data);
      }
    },
    onHighlightCreated: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("onHighlightCreated", data);
      }
    },
    onHighlightUpdated: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("onHighlightUpdated", data);
      }
    },
    onHighlightDeleted: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("onHighlightDeleted", data);
      }
    },
    onHighlightTapped: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("onHighlightTapped", data);
      }
    },
    playTTS: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("playTTS", data);
      }
    },
    openDiscussion: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("openDiscussion", data);
      }
    },
    openAnnotationEditor: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("openAnnotationEditor", data);
      }
    },
    copyToClipboard: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("copyToClipboard", data);
      }
    },
    showToast: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler("showToast", data);
      }
    },
  };

  // ========== 自动初始化 ==========
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
