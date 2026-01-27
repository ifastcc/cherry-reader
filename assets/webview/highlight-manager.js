/**
 * 高亮管理器
 *
 * 功能：
 * - 高亮恢复（HTML 注入 <mark> 标签）
 * - 高亮创建（文本选择 → 工具栏）
 * - 高亮更新（颜色/样式）
 * - 高亮删除
 * - 高亮编辑弹窗
 * - 搜索高亮
 */

(function () {
  "use strict";

  // ========== 高亮状态 ==========
  const highlightState = {
    highlightsMap: {}, // { messageId: [highlight, ...] }
    currentSelection: null, // 当前选区信息
    editingHighlightId: null, // 正在编辑的高亮 ID
  };

  // ========== 搜索状态 ==========
  const searchState = {
    keyword: "",
    matches: [],
    currentIndex: -1,
    isActive: false,
  };

  // ========== 工具函数 ==========
  function debounce(fn, delay) {
    let timer = null;
    return function (...args) {
      clearTimeout(timer);
      timer = setTimeout(() => fn.apply(this, args), delay);
    };
  }

  function hexToRgba(hex, alpha = 0.6) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (result) {
      const r = parseInt(result[1], 16);
      const g = parseInt(result[2], 16);
      const b = parseInt(result[3], 16);
      return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }
    return `rgba(255, 241, 118, ${alpha})`;
  }

  function getScrollBehavior() {
    try {
      if (window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches) {
        return "auto";
      }
    } catch (_) {}
    return window.flutter_inappwebview ? "auto" : "smooth";
  }

  function closestTarget(target, selector) {
    if (!target) return null;
    if (target.closest) return target.closest(selector);
    return target.parentElement?.closest?.(selector) || null;
  }

  // ========== 高亮恢复 ==========
  function applyHighlights(messageId, highlights) {
    if (!highlights || !Array.isArray(highlights)) return;

    highlightState.highlightsMap[messageId] = highlights;

    const container = document.querySelector(
      `[data-message-id="${messageId}"]`,
    );
    if (!container) {
      console.warn(
        `[HighlightManager] Container not found for message: ${messageId}`,
      );
      return;
    }

    clearMessageHighlights(container);

    const sorted = [...highlights].sort(
      (a, b) => (b.start || 0) - (a.start || 0),
    );
    for (const hl of sorted) {
      const success = recoverHighlight(container, hl);
      if (!success) {
        console.warn(
          `[HighlightManager] Failed to recover highlight: ${hl.id}`,
        );
      }
    }
  }

  function recoverHighlight(container, highlight) {
    if (
      typeof highlight.start === "number" &&
      typeof highlight.end === "number" &&
      highlight.end > highlight.start
    ) {
      return tryOffsetBasedRecovery(container, highlight);
    }

    if (highlight.prefix && highlight.suffix && highlight.text) {
      const success = tryContextBasedRecovery(container, highlight);
      if (success) return true;
    }

    if (highlight.text) {
      return tryFuzzyTextRecovery(container, highlight);
    }

    return false;
  }

  function clearMessageHighlights(container) {
    const marks = container.querySelectorAll(
      "mark.highlight[data-highlight-id]",
    );
    marks.forEach((mark) => {
      const parent = mark.parentNode;
      while (mark.firstChild) {
        parent.insertBefore(mark.firstChild, mark);
      }
      parent.removeChild(mark);
      parent.normalize();
    });
  }

  function tryOffsetBasedRecovery(container, highlight) {
    const fullText = container.textContent || "";
    const start = Math.max(0, highlight.start);
    const end = Math.min(fullText.length, highlight.end);
    if (end <= start) return false;

    if (highlight.text) {
      const actualText = fullText.substring(start, end);
      if (actualText !== highlight.text) return false;
    }

    wrapTextRange(container, start, end, {
      tagName: "mark",
      className: `highlight hl-${highlight.style || "background"}`,
      attributes: {
        "data-highlight-id": highlight.id,
        "data-message-id":
          container.closest("[data-message-id]")?.dataset.messageId || "",
        style: `--hl-color: ${hexToRgba(highlight.color)}`,
      },
    });

    return true;
  }

  function tryContextBasedRecovery(container, highlight) {
    const fullText = container.textContent;
    const searchStr =
      (highlight.prefix || "") + highlight.text + (highlight.suffix || "");
    const idx = fullText.indexOf(searchStr);

    if (idx === -1) return false;

    const start = idx + (highlight.prefix?.length || 0);
    const end = start + highlight.text.length;

    wrapTextRange(container, start, end, {
      tagName: "mark",
      className: `highlight hl-${highlight.style || "background"}`,
      attributes: {
        "data-highlight-id": highlight.id,
        "data-message-id":
          container.closest("[data-message-id]")?.dataset.messageId || "",
        style: `--hl-color: ${hexToRgba(highlight.color)}`,
      },
    });

    return true;
  }

  function tryFuzzyTextRecovery(container, highlight) {
    const fullText = container.textContent;
    const idx = fullText.indexOf(highlight.text);

    if (idx === -1) return false;

    wrapTextRange(container, idx, idx + highlight.text.length, {
      tagName: "mark",
      className: `highlight hl-${highlight.style || "background"}`,
      attributes: {
        "data-highlight-id": highlight.id,
        "data-message-id":
          container.closest("[data-message-id]")?.dataset.messageId || "",
        style: `--hl-color: ${hexToRgba(highlight.color)}`,
      },
    });

    return true;
  }

  // ========== 文本包裹 ==========
  function wrapTextRange(rootEl, start, end, options) {
    const walker = document.createTreeWalker(rootEl, NodeFilter.SHOW_TEXT);
    let currentOffset = 0;
    const nodesToWrap = [];

    while (walker.nextNode()) {
      const node = walker.currentNode;
      const nodeLength = node.textContent.length;
      const nodeStart = currentOffset;
      const nodeEnd = currentOffset + nodeLength;

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

    // 倒序处理
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

      try {
        range.surroundContents(wrapper);
      } catch (e) {
        // 处理跨元素情况
        const extracted = range.extractContents();
        wrapper.appendChild(extracted);
        range.insertNode(wrapper);
      }
    }
  }

  function escapeRegex(str) {
    return String(str).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  function findTextOffsets(fullText, text, occurrence = 0) {
    if (!text) return null;
    const target = String(text);
    if (!target.trim()) return null;
    const occ = Math.max(0, Number(occurrence) || 0);

    let fromIndex = 0;
    let idx = -1;
    for (let i = 0; i <= occ; i++) {
      idx = fullText.indexOf(target, fromIndex);
      if (idx === -1) break;
      fromIndex = idx + target.length;
    }
    if (idx !== -1) return { start: idx, end: idx + target.length };

    const parts = target.trim().split(/\s+/).map(escapeRegex);
    if (!parts.length) return null;
    const pattern = parts.join("\\s+");
    const re = new RegExp(pattern, "g");
    let match = null;
    for (let i = 0; i <= occ; i++) {
      match = re.exec(fullText);
      if (!match) break;
    }
    if (!match) return null;

    return { start: match.index, end: match.index + match[0].length };
  }

  function createRangeFromOffsets(rootEl, start, end) {
    const walker = document.createTreeWalker(rootEl, NodeFilter.SHOW_TEXT);
    let currentOffset = 0;
    let startNode = null;
    let startOffset = 0;
    let endNode = null;
    let endOffset = 0;

    const s = Math.max(0, start);
    const e = Math.max(s, end);

    while (walker.nextNode()) {
      const node = walker.currentNode;
      const nodeLength = node.textContent.length;
      const nodeStart = currentOffset;
      const nodeEnd = currentOffset + nodeLength;

      if (!startNode && s >= nodeStart && s <= nodeEnd) {
        startNode = node;
        startOffset = Math.min(nodeLength, Math.max(0, s - nodeStart));
      }
      if (!endNode && e >= nodeStart && e <= nodeEnd) {
        endNode = node;
        endOffset = Math.min(nodeLength, Math.max(0, e - nodeStart));
      }

      currentOffset = nodeEnd;
      if (startNode && endNode) break;
    }

    if (!startNode || !endNode) return null;

    const range = document.createRange();
    range.setStart(startNode, startOffset);
    range.setEnd(endNode, endOffset);
    return range;
  }

  function flashRange(range) {
    let rect = range.getBoundingClientRect();
    if (
      (!rect || (rect.width === 0 && rect.height === 0)) &&
      range.getClientRects
    ) {
      const rects = Array.from(range.getClientRects());
      rect = rects.find((r) => r.width > 0 && r.height > 0) || rect;
    }
    if (!rect) return;

    const el = document.createElement("div");
    el.setAttribute("data-jump-flash", "1");
    el.style.position = "absolute";
    el.style.left = `${Math.max(0, rect.left + window.scrollX - 6)}px`;
    el.style.top = `${Math.max(0, rect.top + window.scrollY - 4)}px`;
    el.style.width = `${Math.max(10, rect.width + 12)}px`;
    el.style.height = `${Math.max(12, rect.height + 8)}px`;
    el.style.borderRadius = "8px";
    el.style.pointerEvents = "none";
    el.style.boxShadow = "0 0 0 2px rgba(255, 193, 7, 0.9)";
    el.style.background = "rgba(255, 193, 7, 0.18)";
    el.style.zIndex = "9999";
    el.style.transition = "opacity 450ms ease";
    document.body.appendChild(el);

    requestAnimationFrame(() => {
      el.style.opacity = "0";
      setTimeout(() => el.remove(), 480);
    });
  }

  function scrollRangeIntoView(range) {
    let rect = range.getBoundingClientRect();
    if (
      (!rect || (rect.width === 0 && rect.height === 0)) &&
      range.getClientRects
    ) {
      const rects = Array.from(range.getClientRects());
      rect = rects.find((r) => r.width > 0 && r.height > 0) || rect;
    }
    if (!rect) return false;

    const top = window.scrollY + rect.top - window.innerHeight * 0.32;
    window.scrollTo({
      top: Math.max(0, top),
      behavior: getScrollBehavior(),
    });
    flashRange(range);
    return true;
  }

  function scrollToTextRange(messageId, start, end) {
    if (!messageId) return false;
    const container = document.querySelector(
      `[data-message-id="${messageId}"]`,
    );
    if (!container) return false;
    const fullText = container.textContent || "";
    const s = Math.max(0, Math.min(Number(start) || 0, fullText.length));
    const e = Math.max(s, Math.min(Number(end) || s, fullText.length));
    const range = createRangeFromOffsets(container, s, e);
    if (!range) return false;
    return scrollRangeIntoView(range);
  }

  function scrollToText(messageId, text, occurrence = 0) {
    if (!messageId) return false;
    const container = document.querySelector(
      `[data-message-id="${messageId}"]`,
    );
    if (!container) return false;
    const fullText = container.textContent || "";
    const offsets = findTextOffsets(fullText, text, occurrence);
    if (!offsets) return false;
    const range = createRangeFromOffsets(container, offsets.start, offsets.end);
    if (!range) return false;
    return scrollRangeIntoView(range);
  }

  // ========== 文本选择处理 ==========

  function setupSelectionListener() {
    let isPointerDown = false;

    document.addEventListener(
      "mousedown",
      () => {
        isPointerDown = true;
        document.body.classList.add("is-selecting");
      },
      true,
    );
    document.addEventListener(
      "mouseup",
      () => {
        isPointerDown = false;
        document.body.classList.remove("is-selecting");
      },
      true,
    );
    document.addEventListener(
      "touchstart",
      () => {
        isPointerDown = true;
        document.body.classList.add("is-selecting");
      },
      true,
    );
    document.addEventListener(
      "touchend",
      () => {
        isPointerDown = false;
        document.body.classList.remove("is-selecting");
      },
      true,
    );

    document.addEventListener(
      "touchcancel",
      () => {
        isPointerDown = false;
        document.body.classList.remove("is-selecting");
      },
      true,
    );

    window.addEventListener("blur", () => {
      isPointerDown = false;
      document.body.classList.remove("is-selecting");
    });

    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState !== "visible") {
        isPointerDown = false;
        document.body.classList.remove("is-selecting");
      }
    });

    function processSelection() {
      const selection = window.getSelection();
      if (!selection || selection.isCollapsed) {
        hideHighlightToolbar();
        highlightState.currentSelection = null;
        return;
      }

      const range = selection.getRangeAt(0);
      const text = selection.toString().trim();
      if (!text || text.length < 2) {
        hideHighlightToolbar();
        return;
      }

      const messageEl =
        range.commonAncestorContainer.closest?.("[data-message-id]") ||
        range.commonAncestorContainer.parentElement?.closest(
          "[data-message-id]",
        );
      if (!messageEl) {
        hideHighlightToolbar();
        return;
      }

      const offsets = getGlobalOffsets(messageEl, range);
      if (!offsets) {
        hideHighlightToolbar();
        return;
      }

      const fullText = messageEl.textContent || "";
      const exact = fullText.substring(offsets.start, offsets.end);
      if (!exact || exact.length < 2) {
        hideHighlightToolbar();
        return;
      }

      highlightState.currentSelection = {
        messageId: messageEl.dataset.messageId,
        roundIndex: parseInt(
          messageEl.closest(".round-card")?.dataset.roundIndex || "0",
          10,
        ),
        start: offsets.start,
        end: offsets.end,
        text: exact,
        prefix: fullText.substring(
          Math.max(0, offsets.start - 50),
          offsets.start,
        ),
        suffix: fullText.substring(
          offsets.end,
          Math.min(fullText.length, offsets.end + 50),
        ),
      };

      if (window.FlutterBridge?.onTextSelected) {
        window.FlutterBridge.onTextSelected({
          text: exact,
          messageId: messageEl.dataset.messageId,
          start: offsets.start,
          end: offsets.end,
        });
      }

      if (!isPointerDown) {
        const rect = range.getBoundingClientRect();
        showHighlightToolbar(rect);
      }
    }

    const debouncedProcess = debounce(processSelection, 120);
    document.addEventListener("selectionchange", debouncedProcess);
    document.addEventListener(
      "mouseup",
      () => {
        setTimeout(processSelection, 0);
      },
      true,
    );
    document.addEventListener(
      "touchend",
      () => {
        setTimeout(processSelection, 0);
      },
      true,
    );
  }

  function getGlobalOffsets(rootEl, range) {
    if (!rootEl || !range) return null;
    if (
      !rootEl.contains(range.startContainer) ||
      !rootEl.contains(range.endContainer)
    ) {
      return null;
    }

    const startPoint = normalizePoint(
      rootEl,
      range.startContainer,
      range.startOffset,
      true,
    );
    const endPoint = normalizePoint(
      rootEl,
      range.endContainer,
      range.endOffset,
      false,
    );
    if (!startPoint || !endPoint) return null;

    const start = computeOffset(rootEl, startPoint.node, startPoint.offset);
    const end = computeOffset(rootEl, endPoint.node, endPoint.offset);
    if (start == null || end == null) return null;
    if (end <= start) return null;
    return { start, end };
  }

  function normalizePoint(rootEl, container, offset, isStart) {
    if (container.nodeType === Node.TEXT_NODE) {
      return { node: container, offset };
    }

    if (isStart) {
      const ref = container.childNodes[offset] || container;
      const node = firstTextNode(ref) || nextTextNodeFrom(rootEl, ref);
      if (!node) return null;
      return { node, offset: 0 };
    }

    const ref = container.childNodes[offset - 1] || container;
    const node = lastTextNode(ref) || prevTextNodeFrom(rootEl, ref);
    if (!node) return null;
    return { node, offset: node.textContent.length };
  }

  function firstTextNode(node) {
    if (!node) return null;
    if (node.nodeType === Node.TEXT_NODE) return node;
    const walker = document.createTreeWalker(node, NodeFilter.SHOW_TEXT);
    return walker.nextNode();
  }

  function lastTextNode(node) {
    if (!node) return null;
    if (node.nodeType === Node.TEXT_NODE) return node;
    const walker = document.createTreeWalker(node, NodeFilter.SHOW_TEXT);
    let last = null;
    while (walker.nextNode()) {
      last = walker.currentNode;
    }
    return last;
  }

  function nextTextNodeFrom(rootEl, fromNode) {
    const walker = document.createTreeWalker(rootEl, NodeFilter.SHOW_TEXT);
    walker.currentNode = fromNode;
    return walker.nextNode();
  }

  function prevTextNodeFrom(rootEl, fromNode) {
    const walker = document.createTreeWalker(rootEl, NodeFilter.SHOW_TEXT);
    walker.currentNode = fromNode;
    return walker.previousNode();
  }

  function computeOffset(rootEl, targetTextNode, localOffset) {
    const walker = document.createTreeWalker(rootEl, NodeFilter.SHOW_TEXT);
    let total = 0;
    while (walker.nextNode()) {
      const node = walker.currentNode;
      if (node === targetTextNode) {
        return total + localOffset;
      }
      total += node.textContent.length;
    }
    return null;
  }

  // ========== 高亮工具栏 ==========
  function showHighlightToolbar(selectionRect) {
    const toolbar = document.getElementById("highlight-toolbar");
    if (!toolbar) return;

    // 计算位置
    const toolbarHeight = toolbar.offsetHeight || 44;
    const padding = 8;

    let top = selectionRect.top - toolbarHeight - padding;
    if (top < 60) {
      top = selectionRect.bottom + padding;
    }

    const toolbarWidth = toolbar.offsetWidth || 220;
    const left = Math.max(
      12,
      Math.min(
        selectionRect.left + selectionRect.width / 2 - toolbarWidth / 2,
        window.innerWidth - toolbarWidth - 12,
      ),
    );

    toolbar.style.top = `${top}px`;
    toolbar.style.left = `${left}px`;
    toolbar.classList.remove("hidden");
  }

  function hideHighlightToolbar() {
    const toolbar = document.getElementById("highlight-toolbar");
    if (toolbar) {
      toolbar.classList.add("hidden");
    }
  }

  function setupToolbarEvents() {
    const toolbar = document.getElementById("highlight-toolbar");
    if (!toolbar) return;

    toolbar.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();

      const actionBtn = closestTarget(e.target, ".toolbar-action");
      const colorBtn = closestTarget(e.target, ".color");

      if (actionBtn && highlightState.currentSelection) {
        const action = actionBtn.dataset.action;
        const sel = highlightState.currentSelection;

        if (action === "copy" && window.FlutterBridge?.copyToClipboard) {
          window.FlutterBridge.copyToClipboard({
            text: sel.text,
            showToast: true,
          });
          hideHighlightToolbar();
          window.getSelection()?.removeAllRanges();
          return;
        }

        if (
          action === "annotate" &&
          window.FlutterBridge?.openAnnotationEditor
        ) {
          window.FlutterBridge.openAnnotationEditor({
            text: sel.text,
            messageId: sel.messageId,
            selectionStart: sel.start,
            selectionEnd: sel.end,
            prefix: sel.prefix,
            suffix: sel.suffix,
          });
          hideHighlightToolbar();
          window.getSelection()?.removeAllRanges();
          return;
        }
      }

      if (colorBtn && highlightState.currentSelection) {
        const color = colorBtn.dataset.color;
        createHighlight(color, "background");
        hideHighlightToolbar();
        window.getSelection()?.removeAllRanges();
      }
    });
  }

  function createHighlight(color, style) {
    const sel = highlightState.currentSelection;
    if (!sel) return;

    const highlight = {
      id: "hl-" + Date.now() + "-" + Math.random().toString(36).slice(2, 11),
      messageId: sel.messageId,
      start: sel.start,
      end: sel.end,
      text: sel.text,
      color: color,
      style: style,
      prefix: sel.prefix,
      suffix: sel.suffix,
      createdAt: new Date().toISOString(),
    };

    // 应用高亮到 DOM
    const container = document.querySelector(
      `[data-message-id="${sel.messageId}"]`,
    );
    if (container) {
      wrapTextRange(container, sel.start, sel.end, {
        tagName: "mark",
        className: `highlight hl-${style}`,
        attributes: {
          "data-highlight-id": highlight.id,
          "data-message-id": sel.messageId,
          style: `--hl-color: ${hexToRgba(color)}`,
        },
      });
    }

    // 保存到状态
    if (!highlightState.highlightsMap[sel.messageId]) {
      highlightState.highlightsMap[sel.messageId] = [];
    }
    highlightState.highlightsMap[sel.messageId].push(highlight);

    // 通知 Flutter
    if (window.FlutterBridge && window.FlutterBridge.onHighlightCreated) {
      window.FlutterBridge.onHighlightCreated(highlight);
    }
  }

  // ========== 高亮点击处理 ==========
  function setupHighlightClickListener() {
    let lastOpenedAt = 0;

    function shouldIgnoreBecauseSelecting() {
      const sel = window.getSelection?.();
      if (!sel) return false;
      if (!sel.isCollapsed) return true;
      const text = sel.toString?.() || "";
      return text.trim().length > 0;
    }

    function tryOpenFromEvent(e) {
      if (shouldIgnoreBecauseSelecting()) return false;

      const highlightEl = closestTarget(e.target, "mark.highlight");
      const editorEl = closestTarget(e.target, "#highlight-editor");

      if (!highlightEl && !editorEl) {
        hideHighlightEditor();
        return true;
      }

      if (highlightEl && !editorEl) {
        e.preventDefault();
        e.stopPropagation();
        lastOpenedAt = Date.now();

        const highlightId = highlightEl.dataset.highlightId;
        const rect = highlightEl.getBoundingClientRect();
        showHighlightEditor(highlightId, rect);
        return true;
      }

      return false;
    }

    document.addEventListener(
      "touchend",
      (e) => {
        tryOpenFromEvent(e);
      },
      true,
    );

    document.addEventListener(
      "mouseup",
      (e) => {
        tryOpenFromEvent(e);
      },
      true,
    );

    document.addEventListener("click", (e) => {
      if (Date.now() - lastOpenedAt < 450) return;
      tryOpenFromEvent(e);
    });
  }

  // ========== 高亮编辑弹窗（微信读书风格）==========
  function showHighlightEditor(highlightId, rect) {
    highlightState.editingHighlightId = highlightId;
    const editor = document.getElementById("highlight-editor");
    if (!editor) return;

    // 获取高亮信息
    const highlight = getHighlightById(highlightId);
    if (!highlight) return;

    // 更新样式选中状态
    editor.querySelectorAll(".style-toggle").forEach((btn) => {
      btn.classList.toggle("active", btn.dataset.style === highlight.style);
    });

    // 更新颜色选中状态
    editor.querySelectorAll(".color-dot").forEach((btn) => {
      btn.classList.toggle("active", btn.dataset.color === highlight.color);
    });

    // 计算位置（显示在高亮上方或下方）
    const editorHeight = 48;
    const padding = 8;
    let top = rect.top - editorHeight - padding;

    if (top < 60) {
      top = rect.bottom + padding;
    }

    // 计算水平位置（居中对齐高亮）
    const editorWidth = 360; // 估算宽度
    const left = Math.max(
      12,
      Math.min(
        rect.left + rect.width / 2 - editorWidth / 2,
        window.innerWidth - editorWidth - 12,
      ),
    );

    editor.style.top = `${top}px`;
    editor.style.left = `${left}px`;
    editor.classList.remove("hidden");
  }

  function hideHighlightEditor() {
    const editor = document.getElementById("highlight-editor");
    if (editor) {
      editor.classList.add("hidden");
    }
    highlightState.editingHighlightId = null;
  }

  function setupEditorEvents() {
    const editor = document.getElementById("highlight-editor");
    if (!editor) return;

    editor.addEventListener("click", (e) => {
      const highlightId = highlightState.editingHighlightId;
      if (!highlightId) return;

      const styleToggle = closestTarget(e.target, ".style-toggle");
      const colorDot = closestTarget(e.target, ".color-dot");
      const actionIcon = closestTarget(e.target, ".action-icon");

      if (styleToggle) {
        const newStyle = styleToggle.dataset.style;
        updateHighlightStyle(highlightId, newStyle);
        editor
          .querySelectorAll(".style-toggle")
          .forEach((b) => b.classList.remove("active"));
        styleToggle.classList.add("active");
      }

      if (colorDot) {
        const newColor = colorDot.dataset.color;
        updateHighlightColor(highlightId, newColor);
        editor
          .querySelectorAll(".color-dot")
          .forEach((b) => b.classList.remove("active"));
        colorDot.classList.add("active");
      }

      if (actionIcon) {
        if (actionIcon.classList.contains("copy")) {
          const hl = getHighlightById(highlightId);
          if (hl && window.FlutterBridge?.copyToClipboard) {
            window.FlutterBridge.copyToClipboard({
              text: hl.text,
              showToast: true,
            });
          }
          hideHighlightEditor();
        } else if (actionIcon.classList.contains("delete")) {
          removeHighlight(highlightId);
          hideHighlightEditor();
        }
      }
    });
  }

  function getHighlightById(highlightId) {
    for (const highlights of Object.values(highlightState.highlightsMap)) {
      const hl = highlights.find((h) => h.id === highlightId);
      if (hl) return hl;
    }
    return null;
  }

  // ========== 高亮更新 ==========
  function updateHighlightColor(highlightId, newColor) {
    const marks = document.querySelectorAll(
      `mark[data-highlight-id="${highlightId}"]`,
    );
    marks.forEach((mark) => {
      mark.style.setProperty("--hl-color", hexToRgba(newColor));
    });

    // 更新状态
    const hl = getHighlightById(highlightId);
    if (hl) {
      hl.color = newColor;
      if (window.FlutterBridge?.onHighlightUpdated) {
        window.FlutterBridge.onHighlightUpdated({
          messageId: hl.messageId,
          highlightId,
          color: hl.color,
          style: hl.style,
        });
      }
    }
  }

  function updateHighlightStyle(highlightId, newStyle) {
    const marks = document.querySelectorAll(
      `mark[data-highlight-id="${highlightId}"]`,
    );
    marks.forEach((mark) => {
      mark.classList.remove(
        "hl-background",
        "hl-underline",
        "hl-wavy",
        "hl-box",
        "hl-dashed",
      );
      mark.classList.add(`hl-${newStyle}`);
    });

    // 更新状态
    const hl = getHighlightById(highlightId);
    if (hl) {
      hl.style = newStyle;
      if (window.FlutterBridge?.onHighlightUpdated) {
        window.FlutterBridge.onHighlightUpdated({
          messageId: hl.messageId,
          highlightId,
          color: hl.color,
          style: hl.style,
        });
      }
    }
  }

  // ========== 高亮删除 ==========
  function removeHighlight(highlightId) {
    const marks = document.querySelectorAll(
      `mark[data-highlight-id="${highlightId}"]`,
    );

    marks.forEach((mark) => {
      const parent = mark.parentNode;
      while (mark.firstChild) {
        parent.insertBefore(mark.firstChild, mark);
      }
      parent.removeChild(mark);
      parent.normalize();
    });

    // 更新状态
    for (const [messageId, highlights] of Object.entries(
      highlightState.highlightsMap,
    )) {
      const idx = highlights.findIndex((h) => h.id === highlightId);
      if (idx !== -1) {
        const removed = highlights[idx];
        highlights.splice(idx, 1);
        if (window.FlutterBridge?.onHighlightDeleted) {
          window.FlutterBridge.onHighlightDeleted({
            highlightId,
            messageId,
            text: removed?.text || "",
          });
        }
        break;
      }
    }
  }

  // ========== 跳转高亮 ==========
  function scrollToHighlight(highlightId) {
    let mark = document.querySelector(
      `mark[data-highlight-id="${highlightId}"]`,
    );
    if (!mark) {
      let messageId = null;
      for (const [mid, highlights] of Object.entries(
        highlightState.highlightsMap,
      )) {
        if (!Array.isArray(highlights)) continue;
        if (highlights.some((h) => h?.id === highlightId)) {
          messageId = mid;
          break;
        }
      }

      if (messageId) {
        applyHighlights(messageId, highlightState.highlightsMap[messageId]);
        mark = document.querySelector(
          `mark[data-highlight-id="${highlightId}"]`,
        );
        if (!mark) {
          const host = document.querySelector(
            `[data-message-id="${messageId}"]`,
          );
          host?.scrollIntoView({
            behavior: getScrollBehavior(),
            block: "center",
          });
          return;
        }
      } else {
        return;
      }
    }

    mark.scrollIntoView({ behavior: getScrollBehavior(), block: "center" });
    mark.classList.add("flash");
    setTimeout(() => mark.classList.remove("flash"), 1500);
  }

  // ========== 搜索高亮 ==========
  window.setSearchKeyword = function (keyword) {
    clearSearchHighlights();

    if (!keyword || !keyword.trim()) {
      clearSearchState();
      if (window.FlutterBridge?.onSearchResult) {
        window.FlutterBridge.onSearchResult({ total: 0, current: -1 });
      }
      return;
    }

    searchState.keyword = keyword.trim();
    searchState.isActive = true;
    searchState.matches = [];

    const containers = document.querySelectorAll(
      ".markdown-body, .question-text",
    );
    containers.forEach((container) => {
      highlightSearchMatches(container, searchState.keyword);
    });

    if (searchState.matches.length > 0) {
      searchState.currentIndex = 0;
      updateCurrentSearchMatch();
    }

    if (window.FlutterBridge?.onSearchResult) {
      window.FlutterBridge.onSearchResult({
        total: searchState.matches.length,
        current: searchState.currentIndex,
      });
    }
  };

  window.searchNext = function () {
    if (searchState.matches.length === 0) return;
    searchState.currentIndex =
      (searchState.currentIndex + 1) % searchState.matches.length;
    updateCurrentSearchMatch();
    if (window.FlutterBridge?.onSearchResult) {
      window.FlutterBridge.onSearchResult({
        total: searchState.matches.length,
        current: searchState.currentIndex,
      });
    }
  };

  window.searchPrev = function () {
    if (searchState.matches.length === 0) return;
    searchState.currentIndex =
      (searchState.currentIndex - 1 + searchState.matches.length) %
      searchState.matches.length;
    updateCurrentSearchMatch();
    if (window.FlutterBridge?.onSearchResult) {
      window.FlutterBridge.onSearchResult({
        total: searchState.matches.length,
        current: searchState.currentIndex,
      });
    }
  };

  window.closeSearch = function () {
    clearSearchHighlights();
    clearSearchState();
  };

  function highlightSearchMatches(container, keyword) {
    const walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, {
      acceptNode: (node) => {
        if (node.parentElement?.classList.contains("search-match")) {
          return NodeFilter.FILTER_REJECT;
        }
        return NodeFilter.FILTER_ACCEPT;
      },
    });

    const nodesToProcess = [];
    while (walker.nextNode()) {
      const node = walker.currentNode;
      if (node.textContent.toLowerCase().includes(keyword.toLowerCase())) {
        nodesToProcess.push(node);
      }
    }

    nodesToProcess.reverse().forEach((node) => {
      wrapSearchMatches(node, keyword);
    });
  }

  function wrapSearchMatches(textNode, keyword) {
    const text = textNode.textContent;
    const lowerText = text.toLowerCase();
    const lowerKeyword = keyword.toLowerCase();
    const fragment = document.createDocumentFragment();
    let lastIndex = 0;
    let matchIndex;

    while ((matchIndex = lowerText.indexOf(lowerKeyword, lastIndex)) !== -1) {
      if (matchIndex > lastIndex) {
        fragment.appendChild(
          document.createTextNode(text.substring(lastIndex, matchIndex)),
        );
      }

      const mark = document.createElement("mark");
      mark.className = "search-match";
      mark.dataset.searchIndex = searchState.matches.length;
      mark.textContent = text.substring(
        matchIndex,
        matchIndex + keyword.length,
      );
      fragment.appendChild(mark);

      searchState.matches.push(mark);
      lastIndex = matchIndex + keyword.length;
    }

    if (lastIndex < text.length) {
      fragment.appendChild(document.createTextNode(text.substring(lastIndex)));
    }

    textNode.parentNode.replaceChild(fragment, textNode);
  }

  function updateCurrentSearchMatch() {
    searchState.matches.forEach((mark) => mark.classList.remove("current"));
    const currentMark = searchState.matches[searchState.currentIndex];
    if (currentMark) {
      currentMark.classList.add("current");
      currentMark.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }

  function clearSearchHighlights() {
    const marks = document.querySelectorAll("mark.search-match");
    marks.forEach((mark) => {
      const parent = mark.parentNode;
      while (mark.firstChild) {
        parent.insertBefore(mark.firstChild, mark);
      }
      parent.removeChild(mark);
      parent.normalize();
    });
  }

  function clearSearchState() {
    searchState.keyword = "";
    searchState.matches = [];
    searchState.currentIndex = -1;
    searchState.isActive = false;
  }

  // ========== 初始化 ==========
  function init() {
    console.log("[HighlightManager] Initializing...");
    setupSelectionListener();
    setupToolbarEvents();
    setupHighlightClickListener();
    setupEditorEvents();
    console.log("[HighlightManager] Ready");
  }

  // ========== 公开 API ==========
  window.HighlightManager = {
    applyHighlights,
    scrollToHighlight,
    scrollToTextRange,
    scrollToText,
    removeHighlight,
    updateHighlightColor,
    updateHighlightStyle,
  };

  // ========== 自动初始化 ==========
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
