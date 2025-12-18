# MCP 服务重构方案

> 状态：v0.3 精简接口
> 日期：2025-12-17

## 背景

现有 MCP 服务提供了 7 个工具，存在冗余和体验问题。本次重构目标：**保持 7 个接口，但每个都有清晰定位**。

### 用户的核心需求

1. **时间维度回顾**：了解今天/昨天/本周/本月都在关注什么
2. **主题关联检索**：找到过去相关的讨论（特别是有上下文的人生话题）
3. **深度作为权重**：轮次数反映投入程度，是重要的 meta 信息

---

## 第一性原理分析

### AI 调用 MCP 工具的目的是什么？

| 目的 | 频率 | 需要什么 |
|------|------|---------|
| 了解"我最近在关注什么" | **高** | 时间范围 + 用户问题 |
| 找相关历史讨论 | **高** | 主题搜索 |
| 深入看某个话题 | 中 | 读取对话内容 |
| 精确搜索关键词 | 低 | 全文搜索 |
| 了解数据规模 | 低（仅初次） | 概览统计 |

### 需求一：总结"我在关注什么"

**核心问题**：AI 需要什么信息？

**答案**：**用户问了什么问题**

- 用户的问题 = 用户的关注点
- 用户的问题通常短（几十到几百字）
- AI 的回复是"答案"，不是"关注点"

### 需求二：查看相关讨论

**核心问题**：需要返回什么？

**答案**：**两步走**

1. **先找到相关话题**（轻量，返回列表 + 首轮问题）
2. **再按需深入**（复用 `get_conversation`）

---

## 现有接口问题分析

| 接口 | 用途 | 问题 |
|------|------|------|
| `get_overview` | 全局概览 | OK，但只用一次 |
| `list_topics` | 话题列表 | 信息密度低，只有标题 |
| `get_topic_info` | 话题详情 | **和 get_conversation 重叠** |
| `get_conversation` | 读对话 | OK，核心工具 |
| `search_conversations` | 搜索 | OK，但缺少过滤参数 |
| `get_activity_summary` | 活动统计 | **只有数字，没有内容** |
| `get_related_topics` | 相关话题 | **关联逻辑太弱（同助手+时间）** |

**冗余点**：

1. `get_topic_info` ≈ `get_conversation` 的弱化版
2. `get_activity_summary` 返回数字统计，AI 无法了解"在关注什么"
3. `get_related_topics` 关联逻辑太弱，跨助手的相关话题找不到

---

## 重构方案总览

### 接口变更

| 变更 | 接口 | 说明 |
|------|------|------|
| 🗑️ 删除 | `get_activity_summary` | 被 `get_user_queries` 替代 |
| 🗑️ 删除 | `get_topic_info` | 被 `get_topic_digest` 替代 |
| 🗑️ 删除 | `get_related_topics` | 被 `find_related_discussions` 替代 |
| ✅ 保留 | `get_overview` | 精简返回字段 |
| ✅ 保留 | `get_conversation` | 核心工具，不变 |
| ✅ 保留 | `search_conversations` | 增加过滤参数 |
| ✅ 保留 | `list_topics` | 增加 `first_query_preview` |
| ✨ 新增 | `get_user_queries` | 时间维度：我最近问了什么 |
| ✨ 新增 | `find_related_discussions` | 主题搜索：找相关历史 |
| ✨ 新增 | `get_topic_digest` | 快速了解单个话题 |

### 最终接口列表（7 个）

```
核心工具（高频使用）:
├─ get_user_queries         [新] 时间维度回顾
├─ find_related_discussions [新] 主题关联搜索
├─ get_conversation         [保留] 深入读取对话
└─ search_conversations     [增强] 精确关键词搜索

辅助工具（低频使用）:
├─ get_topic_digest         [新] 快速了解单个话题
├─ get_overview             [保留] 初次使用概览
└─ list_topics              [增强] 分页浏览话题
```

---

## 新增接口详细设计

### 1. `get_user_queries` - 时间维度回顾

> 替代 `get_activity_summary`

**意图**：回答"我最近在关注什么"

**设计理念**：
- 只返回用户的问题（不返回 AI 回复）
- 按话题分组，保持上下文
- 按投入深度（round_count）排序

**参数**：

```json
{
  "type": "object",
  "properties": {
    "period": {
      "type": "string",
      "enum": ["today", "yesterday", "this_week", "this_month", "last_7_days", "last_30_days", "custom"],
      "description": "时间范围，默认 today"
    },
    "start_date": {
      "type": "string",
      "description": "自定义开始日期（period=custom 时），格式 YYYY-MM-DD"
    },
    "end_date": {
      "type": "string",
      "description": "自定义结束日期（period=custom 时），格式 YYYY-MM-DD"
    },
    "min_rounds": {
      "type": "integer",
      "description": "最小轮次（过滤浅层对话），默认 1"
    },
    "assistant_ids": {
      "type": "array",
      "items": {"type": "string"},
      "description": "只看指定助手（可选）"
    },
    "limit": {
      "type": "integer",
      "description": "返回话题数量，默认 30"
    }
  }
}
```

**返回示例**：

```json
{
  "period": "today",
  "period_range": {
    "start": "2025-12-17T00:00:00+08:00",
    "end": "2025-12-17T23:59:59+08:00"
  },
  "topics": [
    {
      "topic_id": "topic-001",
      "topic_name": "身体中西医分析",
      "assistant_id": "848f...",
      "assistant_name": "思考日常",
      "round_count": 5,
      "depth_tier": "medium",
      "created_at": "2025-12-17T09:30:00+08:00",
      "updated_at": "2025-12-17T11:20:00+08:00",
      "user_queries": [
        {"round": 0, "query": "我想了解一下中医怎么看性欲问题..."},
        {"round": 1, "query": "那西医怎么解释？"},
        {"round": 2, "query": "这两种观点有什么矛盾吗？"},
        {"round": 3, "query": "如果从调理角度，应该怎么做？"},
        {"round": 4, "query": "最近夜尿多，有时候乏力，这和之前说的有关系吗？"}
      ]
    },
    {
      "topic_id": "topic-002",
      "topic_name": "Flutter状态管理",
      "assistant_id": "abc...",
      "assistant_name": "Claude",
      "round_count": 3,
      "depth_tier": "shallow",
      "created_at": "2025-12-17T14:00:00+08:00",
      "updated_at": "2025-12-17T14:30:00+08:00",
      "user_queries": [
        {"round": 0, "query": "Provider和Riverpod怎么选？"},
        {"round": 1, "query": "性能差异大吗？"},
        {"round": 2, "query": "迁移成本呢？"}
      ]
    }
  ],
  "summary": {
    "total_topics": 2,
    "total_rounds": 8,
    "top_assistants": [
      {"name": "思考日常", "topic_count": 1, "round_count": 5},
      {"name": "Claude", "topic_count": 1, "round_count": 3}
    ],
    "depth_distribution": {"shallow": 1, "medium": 1, "deep": 0}
  }
}
```

**为什么比 `get_activity_summary` 更好**：

| 维度 | get_activity_summary | get_user_queries |
|------|---------------------|------------------|
| 返回内容 | 数字统计 | 用户问题列表 |
| AI 能否了解"关注什么" | ❌ 不能 | ✅ 能 |
| 需要后续调用 | 需要多次 get_conversation | 一次搞定 |

---

### 2. `find_related_discussions` - 主题关联搜索

> 替代 `get_related_topics`

**意图**：回答"找找我之前关于 XXX 的讨论"

**设计理念**：
- 搜索首轮问题内容（不只是标题）
- 支持跨助手搜索
- 返回"线索"，让 AI 决定是否深入

**参数**：

```json
{
  "type": "object",
  "properties": {
    "query": {
      "type": "string",
      "description": "想查找的主题，如'人生意义'、'职业规划'、'自我价值'"
    },
    "search_scope": {
      "type": "string",
      "enum": ["first_query", "topic_name", "all_queries", "full_content"],
      "description": "搜索范围，默认 first_query"
    },
    "time_range_days": {
      "type": "integer",
      "description": "搜索范围（天），0 表示全部，默认 0"
    },
    "min_rounds": {
      "type": "integer",
      "description": "最小轮次，默认 1"
    },
    "limit": {
      "type": "integer",
      "description": "返回数量，默认 10"
    }
  },
  "required": ["query"]
}
```

**返回示例**：

```json
{
  "query": "自我价值",
  "search_scope": "first_query",
  "total_found": 8,
  "related_topics": [
    {
      "topic_id": "topic-old-001",
      "topic_name": "关于人生方向的思考",
      "assistant_name": "自我反思",
      "first_query": "我最近一直在想，工作到底是为了什么，总觉得自我价值感很低...",
      "last_query": "所以你觉得找到'心流'状态很重要？",
      "round_count": 31,
      "depth_tier": "deep",
      "relevance": {
        "source": "first_query",
        "match_snippet": "...自我价值感很低..."
      },
      "updated_at": "2025-10-15T23:30:00+08:00"
    },
    {
      "topic_id": "topic-old-002",
      "topic_name": "创作焦虑与自我怀疑",
      "assistant_name": "思考心理学",
      "first_query": "为什么每次要开始创作的时候，我都会有强烈的逃避心理？",
      "last_query": "这和童年经历有关系吗？",
      "round_count": 18,
      "depth_tier": "deep",
      "relevance": {
        "source": "topic_name",
        "match_snippet": null
      },
      "updated_at": "2025-11-20T21:00:00+08:00"
    }
  ]
}
```

**为什么比 `get_related_topics` 更好**：

| 维度 | get_related_topics | find_related_discussions |
|------|-------------------|-------------------------|
| 关联逻辑 | 同助手 + 时间接近 | 内容搜索 |
| 跨助手 | ❌ 不支持 | ✅ 支持 |
| 搜索范围 | 无 | 首轮问题/标题/全文 |

---

### 3. `get_topic_digest` - 话题摘要

> 替代 `get_topic_info`

**意图**：快速了解一个话题，不需要读全部对话

**参数**：

```json
{
  "type": "object",
  "properties": {
    "topic_id": {
      "type": "string",
      "description": "话题 ID"
    }
  },
  "required": ["topic_id"]
}
```

**返回示例**：

```json
{
  "topic_id": "topic-001",
  "topic_name": "关于人生方向的思考",
  "assistant_name": "自我反思",
  "first_round": {
    "user_query": "我最近一直在想，工作到底是为了什么，总觉得自我价值感很低...",
    "assistant_response": "这是一个很深刻的问题。自我价值感低落往往和几个因素有关...[截断至500字]"
  },
  "last_round": {
    "user_query": "所以你觉得找到'心流'状态很重要？",
    "assistant_response": "是的，心流状态是一个很好的指标...[截断至500字]"
  },
  "all_user_queries": [
    "我最近一直在想，工作到底是为了什么...",
    "你说的外部认可依赖是什么意思？",
    "我确实很在意别人怎么看我...",
    "...",
    "所以你觉得找到'心流'状态很重要？"
  ],
  "metrics": {
    "round_count": 31,
    "depth_tier": "deep",
    "time_span_hours": 3.5,
    "created_at": "2025-10-15T20:00:00+08:00",
    "updated_at": "2025-10-15T23:30:00+08:00"
  }
}
```

**为什么比 `get_topic_info` 更好**：

| 维度 | get_topic_info | get_topic_digest |
|------|---------------|------------------|
| 首轮问题 | 只有 preview（还有 bug） | 完整内容 |
| 末轮内容 | ❌ 没有 | ✅ 有 |
| 所有用户问题 | ❌ 没有 | ✅ 有 |
| AI 回复 | ❌ 没有 | 首尾轮各 500 字 |

---

## 保留接口的增强

### 1. `search_conversations` - 增加过滤参数

```diff
{
  "keyword": "焦虑",
  "limit": 20,
+ "start_date": "2025-12-01",
+ "end_date": "2025-12-17",
+ "assistant_ids": ["848f...", "abc..."],
+ "role": "user"
}
```

### 2. `list_topics` - 增加首轮问题预览

```diff
{
  "topics": [
    {
      "id": "...",
      "name": "...",
      "round_count": 15,
+     "first_query_preview": "用户首个问题的前100字..."
    }
  ]
}
```

### 3. `get_overview` - 精简返回

保持现有功能，可选精简不常用字段。

### 4. `get_conversation` - 保持不变

这是核心工具，设计已经很好：
- `queries_only` 模式：只看用户问题
- `mainline` 模式：主线对话
- `full` 模式：完整对话

---

## 调用流程对比

### 场景 1：回答"我今天在关注什么"

**旧流程**（需要多次调用）：

```
AI: get_activity_summary(days=1)     → 只有数字统计
AI: list_topics(start_date=today)    → 只有标题和 ID
AI: get_conversation(id1)            → 读第一个话题
AI: get_conversation(id2)            → 读第二个话题
... 重复 N 次
```

**新流程**（一次调用）：

```
AI: get_user_queries(period="today")
    → 直接得到：所有话题 + 每个话题的全部用户问题
```

### 场景 2：回答"找找关于人生意义的讨论"

**旧流程**（效果差）：

```
AI: search_conversations(keyword="人生意义")
    → 可能找不到（用户可能没用这个词）

AI: get_related_topics(topic_id=xxx)
    → 只看同助手，跨助手的相关话题找不到
```

**新流程**（效果好）：

```
AI: find_related_discussions(query="人生意义")
    → 搜索所有助手的首轮问题
    → 返回相关话题 + 首末轮问题

AI: 如果需要深入
    → get_topic_digest(topic_id="xxx")
    → 或 get_conversation(topic_id="xxx", mode="mainline")
```

---

## 实现优先级

| 优先级 | 任务 | 工作量 |
|--------|------|--------|
| **P0** | 实现 `get_user_queries` | 中 |
| **P0** | 删除 `get_activity_summary` | 小 |
| **P1** | 实现 `find_related_discussions` | 中 |
| **P1** | 删除 `get_related_topics` | 小 |
| **P2** | 实现 `get_topic_digest` | 小 |
| **P2** | 删除 `get_topic_info` | 小 |
| **P3** | 增强 `search_conversations` | 小 |
| **P3** | 增强 `list_topics` | 小 |

---

## 删除接口的迁移说明

### `get_activity_summary` → `get_user_queries`

| 旧用法 | 新用法 |
|--------|--------|
| `get_activity_summary(days=7)` | `get_user_queries(period="last_7_days")` |
| 返回数字统计 | 返回用户问题列表 + 统计 |

### `get_topic_info` → `get_topic_digest`

| 旧用法 | 新用法 |
|--------|--------|
| `get_topic_info(topic_id)` | `get_topic_digest(topic_id)` |
| 返回元数据 + 首条消息预览 | 返回首尾轮完整内容 + 所有用户问题 |

### `get_related_topics` → `find_related_discussions`

| 旧用法 | 新用法 |
|--------|--------|
| `get_related_topics(topic_id)` | `find_related_discussions(query="主题词")` |
| 同助手 + 时间关联 | 内容搜索 + 跨助手 |

---

## 未来扩展方向

### 1. 预摘要与缓存（高价值）

对活跃话题按轮次阈值做增量摘要，存储在 DB 或缓存：
- `get_user_queries` / `find_related_discussions` 优先返回已有摘要
- 调用者不必自己总结长对话
- 可暴露 `refresh_topic_summary` 工具按需重算

```dart
// 摘要缓存示例
class TopicSummaryCache {
  String topicId;
  String summary;           // AI 生成的摘要
  List<String> keyQueries;  // 代表性问题（3-5条）
  int lastRoundIndex;       // 上次摘要时的轮次
  DateTime updatedAt;
}
```

### 2. MCP Resources 暴露长文本

用 MCP resources 暴露常用固定视图，避免大 JSON 走 tools/call：

```
resources:
  - topic/{id}/mainline    → 主线对话 Markdown
  - topic/{id}/queries     → 所有用户问题列表
  - topic/{id}/summary     → 话题摘要
```

工具只做动态查询，resources 返回可流式的纯文本/Markdown。

### 3. 写入型接口

让 AI 成为"知识标注工"：

```typescript
update_topic_metadata({
  topic_id: "...",
  tags: ["自我反思", "创作"],
  summary: "讨论了创作焦虑的根源",
  importance_score: 4
})
```

### 4. Embedding 检索

对首轮问题做 embedding，支持语义相似度搜索：
- 当关键词搜索效果不够好时启用
- 可以找到"语义相关但用词不同"的话题

### 5. 主题聚类

自动将相似话题分组：
- "自我价值" 相关的 8 个话题
- "技术学习" 相关的 15 个话题

### 6. 调用提示规范（MCP Prompts）

在 MCP prompts 里提供标准调用范式：

```markdown
## 周报调用范式
1. get_user_queries(period="this_week", min_rounds=3)
2. 按 assistant 分组，按 round_count 排序
3. 提取每个领域的关键问题

## 回忆话题调用范式
1. find_related_discussions(query="主题词")
2. 对感兴趣的话题调用 get_topic_digest
3. 如需深入，调用 get_conversation(mode="mainline")
```

---

## 开放问题

1. **深度分级阈值**：shallow(<5) / medium(5-15) / deep(>15) 是否合理？
2. **搜索范围默认值**：`find_related_discussions` 默认搜索 `first_query` 还是 `all_queries`？
3. **时区处理**：period="today" 应该用服务器时区还是客户端时区？

---

*文档版本：v0.4*
*更新日期：2025-12-17*
*变更：整合第三方反馈，扩充未来方向（预摘要缓存、MCP Resources、调用提示规范）*
