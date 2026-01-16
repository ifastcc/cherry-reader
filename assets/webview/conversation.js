/**
 * 对话页面主逻辑
 * 
 * 功能：
 * - 框架初始化
 * - Markdown 渲染 + Block 索引注入
 * - 对话数据加载与渲染
 * - Tab 切换与 Swiper 滑动
 * - 能量条
 * - 侧滑抽屉
 * - Sticky Header
 * - 滚动事件处理
 */

(function() {
  'use strict';

  // ========== 全局状态 ==========
  const state = {
    topicId: null,
    topicName: '',
    isDarkMode: false,
    totalRounds: 0,
    loadedRounds: new Set(),
    currentRoundIndex: 0,
    scrollProgress: 0,
    isInitialized: false,
  };

  // ========== 模型颜色映射 ==========
  const MODEL_COLORS = {
    'claude': '#8B5CF6',
    'gpt': '#10B981',
    'gemini': '#4285F4',
    'deepseek': '#1E88E5',
    'qwen': '#FF6B35',
    'default': '#6B7280',
  };

  // ========== Markdown 渲染器 ==========
  let md = null;

  function initMarkdownRenderer() {
    if (!window.markdownit) {
      console.error('[Conversation] markdown-it not loaded');
      return;
    }

    md = window.markdownit({
      html: true,
      linkify: true,
      breaks: true,
      typographer: false,
    });

    // 配置 Prism 自动加载路径
    if (window.Prism && window.Prism.plugins && window.Prism.plugins.autoloader) {
      window.Prism.plugins.autoloader.languages_path = './vendor/prism-components/';
    }
  }

  // 渲染 Markdown 并注入 Block 索引
  function renderMarkdown(content, messageId) {
    if (!md) {
      initMarkdownRenderer();
    }

    if (!md) {
      // Fallback：简单的 HTML 转义
      return `<p data-block-index="0">${escapeHtml(content)}</p>`;
    }

    // 解析 Markdown 为 tokens
    const tokens = md.parse(content, {});
    
    // 为每个 Block 级元素注入索引
    let blockIndex = 0;
    
    function processTokens(tokens) {
      for (const token of tokens) {
        // Block 级开始标签
        if (token.type === 'paragraph_open' ||
            token.type === 'heading_open' ||
            token.type === 'list_item_open' ||
            token.type === 'blockquote_open' ||
            token.type === 'code_block' ||
            token.type === 'fence' ||
            token.type === 'table_open' ||
            token.type === 'hr') {
          token.attrPush(['data-block-index', String(blockIndex++)]);
        }
        
        // 递归处理子 tokens
        if (token.children) {
          processTokens(token.children);
        }
      }
    }

    processTokens(tokens);
    
    // 渲染为 HTML
    let html = md.renderer.render(tokens, md.options, {});
    
    return html;
  }

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // ========== 轮次渲染 ==========
  function renderRound(round) {
    const container = document.getElementById('conversation-container');
    if (!container) return;

    const roundEl = document.createElement('article');
    roundEl.className = 'round-card';
    roundEl.dataset.roundIndex = round.index;

    // 问题区
    const questionHtml = renderQuestionSection(round);
    
    // 回复区
    const replyHtml = renderReplySection(round);

    roundEl.innerHTML = questionHtml + replyHtml;
    container.appendChild(roundEl);

    // 注册 Tab 切换事件
    setupTabSwitch(roundEl, round.index);

    // 代码高亮（延迟执行）
    scheduleCodeHighlight(roundEl);

    // 标记为已加载
    state.loadedRounds.add(round.index);
  }

  function renderQuestionSection(round) {
    const user = round.userMessage || {};
    const qLabel = `Q${round.index + 1}`;
    const questionContent = renderMarkdown(user.content || '', user.id || '');

    return `
      <section class="question-section">
        <div class="color-bar"></div>
        <div class="content">
          <span class="q-label">${qLabel}</span>
          <div class="question-text" data-message-id="${user.id || ''}">
            ${questionContent}
          </div>
        </div>
      </section>
    `;
  }

  function renderReplySection(round) {
    const replies = round.assistantReplies || [];
    if (replies.length === 0) {
      return '';
    }

    // Tab 栏
    const tabsHtml = replies.map((reply, idx) => {
      const modelColor = getModelColor(reply.modelId || reply.modelName || '');
      const isActive = idx === 0 ? 'active' : '';
      const mainlineBadge = reply.isMainline ? '<span class="mainline-badge">★</span>' : '';
      
      return `
        <button class="tab ${isActive}" data-index="${idx}" data-model="${reply.modelId || ''}"
                style="--model-color: ${modelColor}">
          <span class="model-dot" style="background:${modelColor}"></span>
          <span class="model-name">${reply.modelName || 'AI'}</span>
          ${mainlineBadge}
        </button>
      `;
    }).join('');

    // Swiper 内容
    const slidesHtml = replies.map((reply, idx) => {
      const isActive = idx === 0 ? 'active' : '';
      const replyContent = renderMarkdown(reply.content || '', reply.id || '');
      
      return `
        <div class="swiper-slide ${isActive}" data-message-id="${reply.id || ''}" data-reply-index="${idx}">
          <div class="markdown-body">
            ${replyContent}
          </div>
        </div>
      `;
    }).join('');

    return `
      <section class="reply-section">
        <div class="tab-bar" data-round-index="${round.index}">
          ${tabsHtml}
        </div>
        <div class="reply-swiper">
          <div class="swiper-wrapper">
            ${slidesHtml}
          </div>
        </div>
      </section>
    `;
  }

  function getModelColor(modelId) {
    const lowerModel = (modelId || '').toLowerCase();
    for (const [key, color] of Object.entries(MODEL_COLORS)) {
      if (lowerModel.includes(key)) {
        return color;
      }
    }
    return MODEL_COLORS.default;
  }

  // ========== Tab 切换 ==========
  function setupTabSwitch(roundEl, roundIndex) {
    const tabBar = roundEl.querySelector('.tab-bar');
    const swiperWrapper = roundEl.querySelector('.swiper-wrapper');
    
    if (!tabBar || !swiperWrapper) return;

    const tabs = tabBar.querySelectorAll('.tab');
    const slides = swiperWrapper.querySelectorAll('.swiper-slide');

    tabBar.addEventListener('click', (e) => {
      const tab = e.target.closest('.tab');
      if (!tab) return;

      const index = parseInt(tab.dataset.index, 10);
      switchToSlide(roundEl, index);
    });

    // 触摸滑动支持
    setupSwipeGesture(roundEl);
  }

  function switchToSlide(roundEl, index) {
    const tabBar = roundEl.querySelector('.tab-bar');
    const swiperWrapper = roundEl.querySelector('.swiper-wrapper');
    
    if (!tabBar || !swiperWrapper) return;

    const tabs = tabBar.querySelectorAll('.tab');
    const slides = swiperWrapper.querySelectorAll('.swiper-slide');

    // 更新 Tab 状态
    tabs.forEach((tab, i) => {
      tab.classList.toggle('active', i === index);
    });

    // 更新 Slide 状态
    slides.forEach((slide, i) => {
      slide.classList.toggle('active', i === index);
    });

    // 滑动动画
    swiperWrapper.style.transform = `translateX(-${index * 100}%)`;

    // 通知 Flutter
    const roundIndex = parseInt(roundEl.dataset.roundIndex, 10);
    const activeSlide = slides[index];
    const messageId = activeSlide ? activeSlide.dataset.messageId : null;

    if (window.FlutterBridge && window.FlutterBridge.onTabChanged) {
      window.FlutterBridge.onTabChanged({
        roundIndex,
        replyIndex: index,
        messageId,
      });
    }
  }

  // ========== 滑动手势（触摸 + 鼠标）==========
  function setupSwipeGesture(roundEl) {
    const swiperWrapper = roundEl.querySelector('.swiper-wrapper');
    if (!swiperWrapper) return;

    const slides = roundEl.querySelectorAll('.swiper-slide');
    let startX = 0;
    let startY = 0;
    let currentX = 0;
    let isDragging = false;
    let isHorizontal = null;

    // 通用开始拖动
    function handleDragStart(clientX, clientY) {
      startX = clientX;
      startY = clientY;
      currentX = clientX;
      isDragging = true;
      isHorizontal = null;
      swiperWrapper.style.transition = 'none';
      swiperWrapper.classList.add('dragging');
    }

    // 通用拖动中
    function handleDragMove(clientX, clientY, e) {
      if (!isDragging) return;

      currentX = clientX;
      const currentY = clientY;
      const diffX = currentX - startX;
      const diffY = currentY - startY;

      // 判断滑动方向
      if (isHorizontal === null) {
        isHorizontal = Math.abs(diffX) > Math.abs(diffY);
      }

      if (!isHorizontal) return;

      // 阻止默认行为
      if (e && e.preventDefault) e.preventDefault();

      // 计算当前偏移
      const currentSlideIndex = getCurrentSlideIndex(roundEl);
      const translateX = -currentSlideIndex * 100 + (diffX / swiperWrapper.offsetWidth * 100);
      
      // 限制边界
      const maxTranslate = 0;
      const minTranslate = -(slides.length - 1) * 100;
      const clampedTranslate = Math.max(minTranslate, Math.min(maxTranslate, translateX));

      swiperWrapper.style.transform = `translateX(${clampedTranslate}%)`;
    }

    // 通用拖动结束
    function handleDragEnd() {
      if (!isDragging) return;
      isDragging = false;
      swiperWrapper.classList.remove('dragging');

      if (!isHorizontal) return;

      swiperWrapper.style.transition = 'transform 0.35s cubic-bezier(0.25, 0.46, 0.45, 0.94)';

      const diffX = currentX - startX;
      const threshold = swiperWrapper.offsetWidth * 0.15;
      const currentSlideIndex = getCurrentSlideIndex(roundEl);
      
      let newIndex = currentSlideIndex;
      if (diffX > threshold && currentSlideIndex > 0) {
        newIndex = currentSlideIndex - 1;
      } else if (diffX < -threshold && currentSlideIndex < slides.length - 1) {
        newIndex = currentSlideIndex + 1;
      }

      switchToSlide(roundEl, newIndex);
    }

    // 触摸事件
    swiperWrapper.addEventListener('touchstart', (e) => {
      handleDragStart(e.touches[0].clientX, e.touches[0].clientY);
    }, { passive: true });

    swiperWrapper.addEventListener('touchmove', (e) => {
      handleDragMove(e.touches[0].clientX, e.touches[0].clientY, e);
    }, { passive: false });

    swiperWrapper.addEventListener('touchend', handleDragEnd);

    // 鼠标事件（桌面端）
    swiperWrapper.addEventListener('mousedown', (e) => {
      if (e.button !== 0) return; // 只响应左键
      handleDragStart(e.clientX, e.clientY);
      e.preventDefault();
    });

    document.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      handleDragMove(e.clientX, e.clientY, e);
    });

    document.addEventListener('mouseup', handleDragEnd);

    // ======== macOS 触控板两指水平滚动 ========
    let wheelAccumulatorX = 0;
    let wheelTimeout = null;
    const WHEEL_THRESHOLD = 60; // 触发切换的阈值

    swiperWrapper.addEventListener('wheel', (e) => {
      // 只响应水平滚动为主的手势
      if (Math.abs(e.deltaX) < Math.abs(e.deltaY)) return;
      
      // 阻止默认行为防止页面滚动
      e.preventDefault();
      
      wheelAccumulatorX += e.deltaX;
      
      // 清除之前的超时
      if (wheelTimeout) clearTimeout(wheelTimeout);
      
      // 延迟重置累积量
      wheelTimeout = setTimeout(() => {
        wheelAccumulatorX = 0;
      }, 150);
      
      // 检查是否超过阈值
      if (Math.abs(wheelAccumulatorX) > WHEEL_THRESHOLD) {
        const currentSlideIndex = getCurrentSlideIndex(roundEl);
        
        if (wheelAccumulatorX > 0 && currentSlideIndex < slides.length - 1) {
          // 向左滑 -> 下一个
          switchToSlide(roundEl, currentSlideIndex + 1);
          wheelAccumulatorX = 0;
        } else if (wheelAccumulatorX < 0 && currentSlideIndex > 0) {
          // 向右滑 -> 上一个
          switchToSlide(roundEl, currentSlideIndex - 1);
          wheelAccumulatorX = 0;
        }
      }
    }, { passive: false });
  }


  function getCurrentSlideIndex(roundEl) {
    const activeSlide = roundEl.querySelector('.swiper-slide.active');
    return activeSlide ? parseInt(activeSlide.dataset.replyIndex, 10) : 0;
  }

  // ========== 代码高亮 ==========
  function scheduleCodeHighlight(container) {
    requestIdleCallback(() => {
      const codeBlocks = container.querySelectorAll('pre code');
      codeBlocks.forEach((code) => {
        if (window.Prism) {
          window.Prism.highlightElement(code);
        }
      });
    }, { timeout: 500 });
  }

  // requestIdleCallback polyfill
  window.requestIdleCallback = window.requestIdleCallback || function(cb, opts) {
    const start = Date.now();
    return setTimeout(() => {
      cb({
        didTimeout: false,
        timeRemaining: () => Math.max(0, 50 - (Date.now() - start))
      });
    }, opts?.timeout || 1);
  };

  // ========== 能量条 ==========
  function initEnergyBar() {
    const energyBar = document.getElementById('energy-bar');
    if (!energyBar) return;

    energyBar.innerHTML = '';

    for (let i = 0; i < state.totalRounds; i++) {
      const cell = document.createElement('div');
      cell.className = 'energy-cell';
      cell.dataset.roundIndex = i;
      
      // 获取该轮次的主线模型颜色
      const color = getEnergyColor(i);
      
      cell.innerHTML = `
        <div class="empty" style="background:${color}"></div>
        <div class="fill" style="background:${color}"></div>
      `;
      
      cell.addEventListener('click', () => {
        scrollToRound(i);
      });

      energyBar.appendChild(cell);
    }
  }

  function getEnergyColor(roundIndex) {
    // TODO: 从数据中获取实际颜色
    return MODEL_COLORS.default;
  }

  function updateEnergyBar() {
    const energyBar = document.getElementById('energy-bar');
    if (!energyBar) return;

    const cells = energyBar.querySelectorAll('.energy-cell');
    cells.forEach((cell, i) => {
      const fill = cell.querySelector('.fill');
      if (!fill) return;

      if (i < state.currentRoundIndex) {
        // 已滚过的轮次
        fill.style.height = '100%';
        cell.classList.remove('active');
      } else if (i === state.currentRoundIndex) {
        // 当前轮次
        fill.style.height = `${state.scrollProgress * 100}%`;
        cell.classList.add('active');
      } else {
        // 未到达的轮次
        fill.style.height = '0';
        cell.classList.remove('active');
      }
    });
  }

  // ========== 侧滑抽屉 ==========
  function initEdgeDrawer() {
    const drawer = document.getElementById('edge-drawer');
    if (!drawer) return;

    const trigger = drawer.querySelector('.drawer-trigger');
    const upBtn = drawer.querySelector('.nav-btn.up');
    const downBtn = drawer.querySelector('.nav-btn.down');
    const ttsBtn = drawer.querySelector('.action-btn.tts');
    const discussBtn = drawer.querySelector('.action-btn.discuss');

    trigger?.addEventListener('click', () => {
      drawer.classList.toggle('closed');
    });

    upBtn?.addEventListener('click', () => {
      if (state.currentRoundIndex > 0) {
        scrollToRound(state.currentRoundIndex - 1);
      }
    });

    downBtn?.addEventListener('click', () => {
      if (state.currentRoundIndex < state.totalRounds - 1) {
        scrollToRound(state.currentRoundIndex + 1);
      }
    });

    ttsBtn?.addEventListener('click', () => {
      if (window.FlutterBridge && window.FlutterBridge.playTTS) {
        window.FlutterBridge.playTTS({ roundIndex: state.currentRoundIndex });
      }
    });

    discussBtn?.addEventListener('click', () => {
      if (window.FlutterBridge && window.FlutterBridge.openDiscussion) {
        window.FlutterBridge.openDiscussion({ roundIndex: state.currentRoundIndex });
      }
    });
  }

  function updateEdgeDrawer() {
    const drawer = document.getElementById('edge-drawer');
    if (!drawer) return;

    const indicator = drawer.querySelector('.round-indicator');
    const upBtn = drawer.querySelector('.nav-btn.up');
    const downBtn = drawer.querySelector('.nav-btn.down');

    if (indicator) {
      indicator.textContent = `${state.currentRoundIndex + 1}/${state.totalRounds}`;
    }

    if (upBtn) {
      upBtn.disabled = state.currentRoundIndex <= 0;
    }

    if (downBtn) {
      downBtn.disabled = state.currentRoundIndex >= state.totalRounds - 1;
    }
  }

  // ========== Sticky Header ==========
  function initStickyHeader() {
    // 滚动时检查是否需要显示 Sticky Header
  }

  function updateStickyHeader() {
    const stickyHeader = document.getElementById('sticky-header');
    if (!stickyHeader) return;

    const currentRound = document.querySelector(`.round-card[data-round-index="${state.currentRoundIndex}"]`);
    if (!currentRound) return;

    const inlineTabBar = currentRound.querySelector('.tab-bar');
    if (!inlineTabBar) {
      stickyHeader.classList.add('hidden');
      return;
    }

    const tabBarRect = inlineTabBar.getBoundingClientRect();
    const isTabVisible = tabBarRect.top >= 0;

    if (isTabVisible) {
      stickyHeader.classList.add('hidden');
    } else {
      // 更新 Sticky Header 内容
      const roundLabel = stickyHeader.querySelector('.round-label');
      const tabList = stickyHeader.querySelector('.tab-list');
      
      if (roundLabel) {
        roundLabel.textContent = `Q${state.currentRoundIndex + 1}`;
      }

      if (tabList) {
        tabList.innerHTML = inlineTabBar.innerHTML;
        // 重新绑定事件
        tabList.querySelectorAll('.tab').forEach(tab => {
          tab.addEventListener('click', (e) => {
            const index = parseInt(tab.dataset.index, 10);
            switchToSlide(currentRound, index);
            // 同步 Sticky Header 的选中状态
            tabList.querySelectorAll('.tab').forEach((t, i) => {
              t.classList.toggle('active', i === index);
            });
          });
        });
      }

      stickyHeader.classList.remove('hidden');
    }
  }

  // ========== 滚动处理 ==========
  let scrollTicking = false;

  function onScroll() {
    if (!scrollTicking) {
      requestAnimationFrame(() => {
        calculateCurrentRound();
        updateEnergyBar();
        updateEdgeDrawer();
        updateStickyHeader();
        scrollTicking = false;
      });
      scrollTicking = true;
    }
  }

  function calculateCurrentRound() {
    const container = document.getElementById('conversation-container');
    if (!container) return;

    const rounds = container.querySelectorAll('.round-card');
    const viewportTop = 60; // Sticky Header 高度

    let currentIndex = 0;
    let progress = 0;

    for (let i = 0; i < rounds.length; i++) {
      const round = rounds[i];
      const rect = round.getBoundingClientRect();
      
      if (rect.top <= viewportTop && rect.bottom > viewportTop) {
        currentIndex = i;
        progress = (viewportTop - rect.top) / rect.height;
        break;
      } else if (rect.top > viewportTop) {
        currentIndex = Math.max(0, i - 1);
        break;
      } else if (i === rounds.length - 1) {
        currentIndex = i;
        progress = 1;
      }
    }

    state.currentRoundIndex = currentIndex;
    state.scrollProgress = Math.max(0, Math.min(1, progress));
  }

  function scrollToRound(index) {
    const round = document.querySelector(`.round-card[data-round-index="${index}"]`);
    if (round) {
      round.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  // ========== 初始化 ==========
  function init() {
    console.log('[Conversation] Initializing...');
    
    initMarkdownRenderer();
    initEnergyBar();
    initEdgeDrawer();
    initStickyHeader();
    initLazyLoader(); // 添加懒加载

    window.addEventListener('scroll', onScroll, { passive: true });

    state.isInitialized = true;
    document.body.classList.add('framework-ready');
    
    console.log('[Conversation] Framework ready');
  }

  // ========== 懒加载（IntersectionObserver） ==========
  let lazyObserver = null;
  const pendingRounds = new Set();

  function initLazyLoader() {
    if (!('IntersectionObserver' in window)) {
      console.warn('[Conversation] IntersectionObserver not supported');
      return;
    }

    lazyObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const roundIndex = parseInt(entry.target.dataset.roundIndex, 10);
          if (!isNaN(roundIndex) && !state.loadedRounds.has(roundIndex)) {
            requestRoundData([roundIndex]);
          }
          // 懒加载代码高亮
          scheduleCodeHighlight(entry.target);
        }
      });
    }, {
      rootMargin: '200px 0px', // 提前 200px 加载
      threshold: 0.01,
    });
  }

  function observeRound(element) {
    if (lazyObserver && element) {
      lazyObserver.observe(element);
    }
  }

  function requestRoundData(indices) {
    const needed = indices.filter(i => !state.loadedRounds.has(i) && !pendingRounds.has(i));
    if (needed.length === 0) return;

    needed.forEach(i => pendingRounds.add(i));

    if (window.FlutterBridge && window.FlutterBridge.requestRounds) {
      window.FlutterBridge.requestRounds({ indices: needed });
    }
  }

  // ========== 框架初始化（预热时调用） ==========
  window.initFramework = function() {
    init();
  };

  // ========== 加载对话数据（打开页面时调用） ==========
  window.loadConversation = function(data) {
    console.log('[Conversation] Loading conversation data...');
    
    // 清空现有内容
    const container = document.getElementById('conversation-container');
    if (container) {
      container.innerHTML = '';
    }

    // 重置状态
    state.loadedRounds.clear();
    
    // 注入新数据
    window.initConversation(data);
  };

  // ========== 初始化对话（首次加载或数据切换） ==========
  window.initConversation = function(data) {
    console.log('[Conversation] Initializing conversation...');
    
    const { topicId, topicName, isDarkMode, totalRounds, rounds, ...rest } = data;

    // 更新状态
    state.topicId = topicId;
    state.topicName = topicName || '';
    state.isDarkMode = isDarkMode || false;
    state.totalRounds = totalRounds || (rounds ? rounds.length : 0);

    // 设置主题
    document.body.classList.toggle('theme-dark', state.isDarkMode);

    // 渲染轮次
    if (rounds && Array.isArray(rounds)) {
      for (const round of rounds) {
        renderRound(round);
      }
    }

    // 初始化能量条
    initEnergyBar();

    // 恢复高亮（交给 highlight-manager.js）
    if (rounds && window.HighlightManager) {
      for (const round of rounds) {
        if (round.highlights) {
          for (const [messageId, highlights] of Object.entries(round.highlights)) {
            window.HighlightManager.applyHighlights(messageId, highlights);
          }
        }
      }
    }

    // 处理初始滚动
    if (rest.scrollToHighlightId && window.HighlightManager) {
      setTimeout(() => {
        window.HighlightManager.scrollToHighlight(rest.scrollToHighlightId);
      }, 100);
    } else if (rest.scrollToRoundIndex != null) {
      setTimeout(() => {
        scrollToRound(rest.scrollToRoundIndex);
      }, 100);
    }

    // 通知 Flutter 就绪
    if (window.FlutterBridge && window.FlutterBridge.onContentReady) {
      window.FlutterBridge.onContentReady({
        scrollHeight: document.body.scrollHeight,
        roundCount: state.loadedRounds.size,
      });
    }

    console.log('[Conversation] Initialization complete');
  };

  // ========== 增量加载轮次 ==========
  window.appendRounds = function(rounds) {
    if (!rounds || !Array.isArray(rounds)) return;

    for (const round of rounds) {
      if (!state.loadedRounds.has(round.index)) {
        renderRound(round);
      }
    }

    // 更新能量条
    updateEnergyBar();
  };

  // ========== 状态更新接口 ==========
  window.setDarkMode = function(isDark) {
    state.isDarkMode = isDark;
    document.body.classList.toggle('theme-dark', isDark);
  };

  window.scrollToRound = scrollToRound;

  // ========== FlutterBridge 实际绑定 ==========
  // 通过 flutter_inappwebview 与 Flutter 通信
  window.FlutterBridge = {
    onContentReady: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onContentReady', data);
      } else {
        console.log('[FlutterBridge] onContentReady:', data);
      }
    },
    onScrollChanged: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onScrollChanged', data);
      }
    },
    onTabChanged: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onTabChanged', data);
      }
    },
    onHighlightCreated: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onHighlightCreated', data);
      }
    },
    onHighlightUpdated: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onHighlightUpdated', data);
      }
    },
    onHighlightDeleted: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onHighlightDeleted', data);
      }
    },
    onHighlightTapped: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onHighlightTapped', data);
      }
    },
    onSearchResult: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onSearchResult', data);
      }
    },
    playTTS: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('playTTS', data);
      }
    },
    openDiscussion: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('openDiscussion', data);
      }
    },
    openNoteEditor: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('openNoteEditor', data);
      }
    },
    showToast: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('showToast', data);
      }
    },
    copyToClipboard: (data) => {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('copyToClipboard', data);
      }
    },
    requestRounds: async (data) => {
      if (window.flutter_inappwebview) {
        const result = await window.flutter_inappwebview.callHandler('requestRounds', data);
        return result ? JSON.parse(result) : null;
      }
      return null;
    },
  };

  // ========== 自动初始化 ==========
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
