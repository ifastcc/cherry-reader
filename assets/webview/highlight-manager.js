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

(function() {
  'use strict';

  // ========== 高亮状态 ==========
  const highlightState = {
    highlightsMap: {},        // { messageId: [highlight, ...] }
    currentSelection: null,   // 当前选区信息
    editingHighlightId: null, // 正在编辑的高亮 ID
  };

  // ========== 搜索状态 ==========
  const searchState = {
    keyword: '',
    matches: [],
    currentIndex: -1,
    isActive: false,
  };

  // ========== 工具函数 ==========
  function debounce(fn, delay) {
    let timer = null;
    return function(...args) {
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

  // ========== 高亮恢复 ==========
  function applyHighlights(messageId, highlights) {
    if (!highlights || !Array.isArray(highlights)) return;

    highlightState.highlightsMap[messageId] = highlights;

    const container = document.querySelector(`[data-message-id="${messageId}"] .markdown-body`);
    if (!container) {
      console.warn(`[HighlightManager] Container not found for message: ${messageId}`);
      return;
    }

    for (const hl of highlights) {
      const success = recoverHighlight(container, hl);
      if (!success) {
        console.warn(`[HighlightManager] Failed to recover highlight: ${hl.id}`);
      }
    }
  }

  function recoverHighlight(container, highlight) {
    // 策略 1：Block 索引 + 内部偏移
    if (highlight.ranges && highlight.ranges.length > 0) {
      const success = tryBlockBasedRecovery(container, highlight);
      if (success) return true;
    }

    // 策略 2：前后文语义匹配
    if (highlight.prefix && highlight.suffix) {
      const success = tryContextBasedRecovery(container, highlight);
      if (success) return true;
    }

    // 策略 3：模糊文本搜索
    return tryFuzzyTextRecovery(container, highlight);
  }

  function tryBlockBasedRecovery(container, highlight) {
    // 验证所有 Block 是否存在且文本匹配
    for (const range of highlight.ranges) {
      const block = container.querySelector(`[data-block-index="${range.blockIndex}"]`);
      if (!block) return false;

      const blockText = block.textContent;
      const actualText = blockText.substring(range.start, range.end);
      if (actualText !== range.text) return false;
    }

    // 匹配成功，应用高亮
    for (const range of highlight.ranges) {
      const block = container.querySelector(`[data-block-index="${range.blockIndex}"]`);
      wrapTextRange(block, range.start, range.end, {
        tagName: 'mark',
        className: `highlight hl-${highlight.style || 'background'}`,
        attributes: {
          'data-highlight-id': highlight.id,
          'data-message-id': container.closest('[data-message-id]')?.dataset.messageId || '',
          'style': `--hl-color: ${hexToRgba(highlight.color)}`,
        },
      });
    }

    return true;
  }

  function tryContextBasedRecovery(container, highlight) {
    const fullText = container.textContent;
    const searchStr = (highlight.prefix || '') + highlight.text + (highlight.suffix || '');
    const idx = fullText.indexOf(searchStr);

    if (idx === -1) return false;

    const start = idx + (highlight.prefix?.length || 0);
    const end = start + highlight.text.length;

    wrapTextRangeGlobal(container, start, end, {
      tagName: 'mark',
      className: `highlight hl-${highlight.style || 'background'}`,
      attributes: {
        'data-highlight-id': highlight.id,
        'data-message-id': container.closest('[data-message-id]')?.dataset.messageId || '',
        'style': `--hl-color: ${hexToRgba(highlight.color)}`,
      },
    });

    return true;
  }

  function tryFuzzyTextRecovery(container, highlight) {
    const fullText = container.textContent;
    const idx = fullText.indexOf(highlight.text);

    if (idx === -1) return false;

    wrapTextRangeGlobal(container, idx, idx + highlight.text.length, {
      tagName: 'mark',
      className: `highlight hl-${highlight.style || 'background'}`,
      attributes: {
        'data-highlight-id': highlight.id,
        'data-message-id': container.closest('[data-message-id]')?.dataset.messageId || '',
        'style': `--hl-color: ${hexToRgba(highlight.color)}`,
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

  function wrapTextRangeGlobal(container, start, end, options) {
    wrapTextRange(container, start, end, options);
  }

  // ========== 文本选择处理 ==========
  function setupSelectionListener() {
    document.addEventListener('selectionchange', debounce(() => {
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

      // 找到所属的消息容器
      const messageEl = range.commonAncestorContainer.closest?.('[data-message-id]')
        || range.commonAncestorContainer.parentElement?.closest('[data-message-id]');
      if (!messageEl) {
        hideHighlightToolbar();
        return;
      }

      // 收集选区信息
      const ranges = collectSelectionRanges(messageEl, range);
      if (ranges.length === 0) {
        hideHighlightToolbar();
        return;
      }

      // 保存当前选区
      highlightState.currentSelection = {
        text,
        messageId: messageEl.dataset.messageId,
        roundIndex: parseInt(messageEl.closest('.round-card')?.dataset.roundIndex || '0', 10),
        ranges,
        prefix: getContextText(messageEl, range, 'prefix'),
        suffix: getContextText(messageEl, range, 'suffix'),
      };

      // 显示工具栏
      const rect = range.getBoundingClientRect();
      showHighlightToolbar(rect);
    }, 150));
  }

  function collectSelectionRanges(messageEl, range) {
    const markdownBody = messageEl.querySelector('.markdown-body');
    if (!markdownBody) return [];

    const ranges = [];
    const blocks = markdownBody.querySelectorAll('[data-block-index]');

    for (const block of blocks) {
      const blockIndex = parseInt(block.dataset.blockIndex, 10);
      const blockRange = document.createRange();
      blockRange.selectNodeContents(block);

      // 判断是否与 Block 有交集
      if (range.compareBoundaryPoints(Range.END_TO_START, blockRange) < 0 &&
          range.compareBoundaryPoints(Range.START_TO_END, blockRange) > 0) {
        
        const { start, end, text } = getInternalOffset(block, range);
        if (start < end && text) {
          ranges.push({
            blockIndex,
            start,
            end,
            text,
          });
        }
      }
    }

    return ranges;
  }

  function getInternalOffset(blockEl, selectionRange) {
    const walker = document.createTreeWalker(blockEl, NodeFilter.SHOW_TEXT);
    let currentOffset = 0;
    let startOffset = -1;
    let endOffset = -1;

    while (walker.nextNode()) {
      const node = walker.currentNode;
      const nodeLength = node.textContent.length;

      // 计算起始偏移
      if (startOffset === -1) {
        if (node === selectionRange.startContainer || 
            (selectionRange.startContainer.nodeType !== Node.TEXT_NODE && 
             blockEl.contains(selectionRange.startContainer))) {
          if (node === selectionRange.startContainer) {
            startOffset = currentOffset + selectionRange.startOffset;
          }
        }
      }

      // 简化：使用选中文本长度计算
      currentOffset += nodeLength;
    }

    // Fallback：基于文本内容计算
    const selectedText = selectionRange.toString();
    const blockText = blockEl.textContent;
    const idx = blockText.indexOf(selectedText);
    
    if (idx !== -1) {
      return {
        start: idx,
        end: idx + selectedText.length,
        text: selectedText,
      };
    }

    return { start: 0, end: 0, text: '' };
  }

  function getContextText(messageEl, range, type) {
    const markdownBody = messageEl.querySelector('.markdown-body');
    if (!markdownBody) return '';

    const fullText = markdownBody.textContent;
    const selectedText = range.toString();
    const idx = fullText.indexOf(selectedText);

    if (idx === -1) return '';

    if (type === 'prefix') {
      const start = Math.max(0, idx - 50);
      return fullText.substring(start, idx);
    } else {
      const end = Math.min(fullText.length, idx + selectedText.length + 50);
      return fullText.substring(idx + selectedText.length, end);
    }
  }

  // ========== 高亮工具栏 ==========
  function showHighlightToolbar(selectionRect) {
    const toolbar = document.getElementById('highlight-toolbar');
    if (!toolbar) return;

    // 计算位置
    const toolbarHeight = 44;
    const padding = 8;
    
    let top = selectionRect.top - toolbarHeight - padding;
    if (top < 60) {
      top = selectionRect.bottom + padding;
    }

    const left = Math.max(10, Math.min(
      selectionRect.left + selectionRect.width / 2 - 100,
      window.innerWidth - 220
    ));

    toolbar.style.top = `${top}px`;
    toolbar.style.left = `${left}px`;
    toolbar.classList.remove('hidden');
  }

  function hideHighlightToolbar() {
    const toolbar = document.getElementById('highlight-toolbar');
    if (toolbar) {
      toolbar.classList.add('hidden');
    }
  }

  function setupToolbarEvents() {
    const toolbar = document.getElementById('highlight-toolbar');
    if (!toolbar) return;

    toolbar.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();

      const colorBtn = e.target.closest('.color');
      const styleBtn = e.target.closest('.style-btn');

      if (colorBtn && highlightState.currentSelection) {
        const color = colorBtn.dataset.color;
        const style = toolbar.querySelector('.style-btn.active')?.dataset.style || 'background';
        createHighlight(color, style);
        hideHighlightToolbar();
        window.getSelection()?.removeAllRanges();
      }

      if (styleBtn) {
        toolbar.querySelectorAll('.style-btn').forEach(btn => btn.classList.remove('active'));
        styleBtn.classList.add('active');
      }
    });
  }

  function createHighlight(color, style) {
    const sel = highlightState.currentSelection;
    if (!sel) return;

    const highlight = {
      id: 'hl-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
      messageId: sel.messageId,
      text: sel.text,
      color: color,
      style: style,
      ranges: sel.ranges,
      prefix: sel.prefix,
      suffix: sel.suffix,
      createdAt: new Date().toISOString(),
    };

    // 应用高亮到 DOM
    const container = document.querySelector(`[data-message-id="${sel.messageId}"] .markdown-body`);
    if (container) {
      for (const range of sel.ranges) {
        const block = container.querySelector(`[data-block-index="${range.blockIndex}"]`);
        if (block) {
          wrapTextRange(block, range.start, range.end, {
            tagName: 'mark',
            className: `highlight hl-${style}`,
            attributes: {
              'data-highlight-id': highlight.id,
              'data-message-id': sel.messageId,
              'style': `--hl-color: ${hexToRgba(color)}`,
            },
          });
        }
      }
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

  // ========== 高亮点击编辑 ==========
  function setupHighlightClickListener() {
    document.addEventListener('click', (e) => {
      const highlightEl = e.target.closest('mark.highlight');
      
      // 点击其他区域关闭编辑弹窗
      if (!highlightEl && !e.target.closest('#highlight-editor')) {
        hideHighlightEditor();
        return;
      }

      if (highlightEl) {
        e.preventDefault();
        e.stopPropagation();

        const highlightId = highlightEl.dataset.highlightId;
        const rect = highlightEl.getBoundingClientRect();
        showHighlightEditor(highlightId, rect);
      }
    });
  }

  // ========== 高亮编辑弹窗 ==========
  function showHighlightEditor(highlightId, rect) {
    highlightState.editingHighlightId = highlightId;
    const editor = document.getElementById('highlight-editor');
    if (!editor) return;

    // 获取高亮信息
    const highlight = getHighlightById(highlightId);
    if (!highlight) return;

    // 更新选中状态
    editor.querySelectorAll('.color-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.color === highlight.color);
    });
    editor.querySelectorAll('.style-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.style === highlight.style);
    });

    // 计算位置
    const editorHeight = 160;
    const spaceAbove = rect.top;
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

  function hideHighlightEditor() {
    const editor = document.getElementById('highlight-editor');
    if (editor) {
      editor.classList.add('hidden');
    }
    highlightState.editingHighlightId = null;
  }

  function setupEditorEvents() {
    const editor = document.getElementById('highlight-editor');
    if (!editor) return;

    editor.addEventListener('click', (e) => {
      const highlightId = highlightState.editingHighlightId;
      if (!highlightId) return;

      const colorBtn = e.target.closest('.color-btn');
      const styleBtn = e.target.closest('.style-btn');
      const actionBtn = e.target.closest('.action-btn');

      if (colorBtn) {
        const newColor = colorBtn.dataset.color;
        updateHighlightColor(highlightId, newColor);
        editor.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
        colorBtn.classList.add('active');
      }

      if (styleBtn) {
        const newStyle = styleBtn.dataset.style;
        updateHighlightStyle(highlightId, newStyle);
        editor.querySelectorAll('.style-btn').forEach(b => b.classList.remove('active'));
        styleBtn.classList.add('active');
      }

      if (actionBtn) {
        if (actionBtn.classList.contains('copy')) {
          const hl = getHighlightById(highlightId);
          if (hl && window.FlutterBridge?.copyToClipboard) {
            window.FlutterBridge.copyToClipboard({ text: hl.text, showToast: true });
          }
        } else if (actionBtn.classList.contains('delete')) {
          removeHighlight(highlightId);
          hideHighlightEditor();
        } else if (actionBtn.classList.contains('note')) {
          if (window.FlutterBridge?.openNoteEditor) {
            window.FlutterBridge.openNoteEditor({ highlightId });
          }
        }
      }
    });
  }

  function getHighlightById(highlightId) {
    for (const highlights of Object.values(highlightState.highlightsMap)) {
      const hl = highlights.find(h => h.id === highlightId);
      if (hl) return hl;
    }
    return null;
  }

  // ========== 高亮更新 ==========
  function updateHighlightColor(highlightId, newColor) {
    const marks = document.querySelectorAll(`mark[data-highlight-id="${highlightId}"]`);
    marks.forEach(mark => {
      mark.style.setProperty('--hl-color', hexToRgba(newColor));
    });

    // 更新状态
    const hl = getHighlightById(highlightId);
    if (hl) {
      hl.color = newColor;
      if (window.FlutterBridge?.onHighlightUpdated) {
        window.FlutterBridge.onHighlightUpdated({ highlightId, color: newColor });
      }
    }
  }

  function updateHighlightStyle(highlightId, newStyle) {
    const marks = document.querySelectorAll(`mark[data-highlight-id="${highlightId}"]`);
    marks.forEach(mark => {
      mark.classList.remove('hl-background', 'hl-underline', 'hl-wavy', 'hl-box', 'hl-dashed');
      mark.classList.add(`hl-${newStyle}`);
    });

    // 更新状态
    const hl = getHighlightById(highlightId);
    if (hl) {
      hl.style = newStyle;
      if (window.FlutterBridge?.onHighlightUpdated) {
        window.FlutterBridge.onHighlightUpdated({ highlightId, style: newStyle });
      }
    }
  }

  // ========== 高亮删除 ==========
  function removeHighlight(highlightId) {
    const marks = document.querySelectorAll(`mark[data-highlight-id="${highlightId}"]`);
    
    marks.forEach(mark => {
      const parent = mark.parentNode;
      while (mark.firstChild) {
        parent.insertBefore(mark.firstChild, mark);
      }
      parent.removeChild(mark);
      parent.normalize();
    });

    // 更新状态
    for (const [messageId, highlights] of Object.entries(highlightState.highlightsMap)) {
      const idx = highlights.findIndex(h => h.id === highlightId);
      if (idx !== -1) {
        highlights.splice(idx, 1);
        if (window.FlutterBridge?.onHighlightDeleted) {
          window.FlutterBridge.onHighlightDeleted({ highlightId, messageId });
        }
        break;
      }
    }
  }

  // ========== 跳转高亮 ==========
  function scrollToHighlight(highlightId) {
    const mark = document.querySelector(`mark[data-highlight-id="${highlightId}"]`);
    if (!mark) return;

    mark.scrollIntoView({ behavior: 'smooth', block: 'center' });
    mark.classList.add('flash');
    setTimeout(() => mark.classList.remove('flash'), 1500);
  }

  // ========== 搜索高亮 ==========
  window.setSearchKeyword = function(keyword) {
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

    const containers = document.querySelectorAll('.markdown-body, .question-text');
    containers.forEach(container => {
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

  window.searchNext = function() {
    if (searchState.matches.length === 0) return;
    searchState.currentIndex = (searchState.currentIndex + 1) % searchState.matches.length;
    updateCurrentSearchMatch();
    if (window.FlutterBridge?.onSearchResult) {
      window.FlutterBridge.onSearchResult({
        total: searchState.matches.length,
        current: searchState.currentIndex,
      });
    }
  };

  window.searchPrev = function() {
    if (searchState.matches.length === 0) return;
    searchState.currentIndex = (searchState.currentIndex - 1 + searchState.matches.length) % searchState.matches.length;
    updateCurrentSearchMatch();
    if (window.FlutterBridge?.onSearchResult) {
      window.FlutterBridge.onSearchResult({
        total: searchState.matches.length,
        current: searchState.currentIndex,
      });
    }
  };

  window.closeSearch = function() {
    clearSearchHighlights();
    clearSearchState();
  };

  function highlightSearchMatches(container, keyword) {
    const walker = document.createTreeWalker(
      container,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode: (node) => {
          if (node.parentElement?.classList.contains('search-match')) {
            return NodeFilter.FILTER_REJECT;
          }
          return NodeFilter.FILTER_ACCEPT;
        }
      }
    );

    const nodesToProcess = [];
    while (walker.nextNode()) {
      const node = walker.currentNode;
      if (node.textContent.toLowerCase().includes(keyword.toLowerCase())) {
        nodesToProcess.push(node);
      }
    }

    nodesToProcess.reverse().forEach(node => {
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
        fragment.appendChild(document.createTextNode(text.substring(lastIndex, matchIndex)));
      }

      const mark = document.createElement('mark');
      mark.className = 'search-match';
      mark.dataset.searchIndex = searchState.matches.length;
      mark.textContent = text.substring(matchIndex, matchIndex + keyword.length);
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
    searchState.matches.forEach(mark => mark.classList.remove('current'));
    const currentMark = searchState.matches[searchState.currentIndex];
    if (currentMark) {
      currentMark.classList.add('current');
      currentMark.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }

  function clearSearchHighlights() {
    const marks = document.querySelectorAll('mark.search-match');
    marks.forEach(mark => {
      const parent = mark.parentNode;
      while (mark.firstChild) {
        parent.insertBefore(mark.firstChild, mark);
      }
      parent.removeChild(mark);
      parent.normalize();
    });
  }

  function clearSearchState() {
    searchState.keyword = '';
    searchState.matches = [];
    searchState.currentIndex = -1;
    searchState.isActive = false;
  }

  // ========== 初始化 ==========
  function init() {
    console.log('[HighlightManager] Initializing...');
    setupSelectionListener();
    setupToolbarEvents();
    setupHighlightClickListener();
    setupEditorEvents();
    console.log('[HighlightManager] Ready');
  }

  // ========== 公开 API ==========
  window.HighlightManager = {
    applyHighlights,
    scrollToHighlight,
    removeHighlight,
    updateHighlightColor,
    updateHighlightStyle,
  };

  // ========== 自动初始化 ==========
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
