# Drift / SQLite 重构方案（从第一性原理出发）

> 文档版本：0.1  
> 最后更新：2026-02-03  
> 状态：草案（可执行）

本方案不把“迁移到 SQLite”视为语法替换（Isar API → SQL API），而是把每一次数据库调用还原为：**我们到底在维护什么事实（facts）**、**需要什么查询能力**、**需要什么一致性/性能边界**，然后再选择最合适的 SQLite/Drift 实现方式（表结构、索引、事务、流式监听、FTS、迁移策略）。

---

## 1. 目标与非目标

### 1.1 目标
- 保持现有用户可见功能与数据语义不变（导入、浏览、搜索、标注/笔记、讨论、洞察、AI 对话等）。
- 保持或提升关键性能：导入速度、长话题分页、搜索速度、首页/索引构建速度。
- 支持响应式更新（现有 `watch*` 能力在 Drift 中等价实现）。
- 可控迁移：支持灰度切换、回滚（至少开发期可回退到 Isar）。

### 1.2 非目标（阶段 1 不做）
- 不强行复刻 Isar 的全部查询 DSL；改成“以用例为中心”的查询集合。
- 不在第一阶段实现跨版本多库切换（如果未来仍要版本化导入，建议单独一章方案）。

---

## 2. 现有数据域的第一性原理拆解

把数据库内容分成 3 类“事实域”，因为它们的写入模式、查询模式、迁移策略完全不同：

### 2.1 导入事实域（Imported Facts，主要只增量覆盖）
“从 Cherry Studio 备份导入得到的事实”。对应目前的：
- Assistant / Topic / Message / MessageBlock / File（`lib/models/isar/*_entity.dart`）
- 以及你新增的导入审计元数据：ImportArtifact / ImportJob / ProvenanceRecord

本质需求：
- **幂等导入**：同一 externalId 重复导入时可覆盖更新（Upsert）。
- **可追溯**：每条导入事实能回答“来自哪个来源、何时见到、指纹是什么”。
- **高性能读**：按 topic 分页读 message / blocks、按时间排序 topic。

### 2.2 用户事实域（User Facts，强一致+频繁写）
“用户在应用内产生或修改的事实”，对应目前：
- KnowledgeEntry（高亮/标注/笔记）
- Discussion / DiscussionMessage
- UnifiedConversation / UnifiedMessage（AI 对话）
- UserPreference / TaskTemplate
- Perspective / Insight（含内置/自定义视角）

本质需求：
- **强一致性**：写入后立即可读；部分场景需要事务（例如删除会级联删除消息）。
- **响应式更新**：UI 订阅某个范围的数据变化（watch by message / by conversation）。
- **可迁移**：模型演进、字段新增需要可迁移 schema。

### 2.3 派生/缓存域（Derived/Caches，可重建）
例如 TopicIndexService 内存索引、部分统计缓存等。原则：**尽量不落库**，或者落库也能随时重建。

---

## 3. 数据库调用到底在“做什么”（意图 → SQLite/Drift 方案）

这一节按“用例”而不是按“文件”组织；每个用例给出等价 SQLite 实现方式。

### 3.1 导入（写入密集、需要事务、需要 Upsert）
涉及主要代码：
- `DataImportService`（批量写入 + provenance/job/artifact）
- `DataImportManager`（封装进度映射）
- `HomeScreen._loadFile`（加载 extractor → 导入）

意图拆解：
- 创建导入工件（artifact）+ 创建导入任务（job: running）
- 分批事务写入：Topic/Message/Block/File/Assistant（50 topics 一批）
- 对每条事实写 provenance：`(sourceType, entityType, externalId)` 唯一，更新 `lastSeenAt`
- 成功：job → succeeded + stats；失败：job → failed + error

SQLite/Drift 方案：
- 使用 Drift `transaction()` 包住每批写入；使用 `batch((b) { ... })` 批量执行。
- Upsert：SQLite 原生 `INSERT INTO ... ON CONFLICT(...) DO UPDATE SET ...`；Drift 用 `insertOnConflictUpdate` 或 `customInsert` + `ON CONFLICT`。
- Provenance 的“firstSeenAt 不回退”：用 `ON CONFLICT DO UPDATE SET last_seen_at = excluded.last_seen_at, fingerprint = COALESCE(excluded.fingerprint, provenance.fingerprint), parent_external_id = COALESCE(excluded.parent_external_id, provenance.parent_external_id)`，并且 `first_seen_at` 不更新。

### 3.2 首页与话题索引（读多、聚合、排序）
涉及主要代码：
- `HomeScreen._refreshFromDatabase`：读取 assistants + topics，然后构建树/时间线
- `TopicIndexService`：加载 assistants/topics 元数据，按需加载 rounds 与预览

意图拆解：
- “列出所有助手（用于分组显示）”
- “列出所有话题，按更新时间倒序”
- “按 assistantId 过滤话题”
- “拿到每个 topic 的 messageCount/roundCount”

SQLite/Drift 方案：
- assistants 表 + topics 表；topics 与 assistants 的关系建议**规范化**（见第 4 章）。
- `getAllTopics ORDER BY updated_at DESC` 走索引 `topics(updated_at DESC)`。

### 3.3 话题详情页（分页加载、按轮次加载、按 messageId 查 blocks）
涉及主要代码：
- `IsarMessageRepository`：`loadMessages/loadRounds/getRoundCount/loadBlocks/loadBlocksByTopic/...`
- `ConversationScreen`：大量“按需加载轮次/blocks/讨论数/高亮”等

意图拆解：
- “按 topicId + orderIndex 分页取消息”
- “按 topicId + roundIndex 范围取消息（轮次分页）”
- “按 messageId 取 blocks，并按 orderIndex 排序”
- “按 topicId 批量取 blocks（用于预览构建）”

SQLite/Drift 方案：
- messages：索引 `(topic_id, order_index)`、`(topic_id, round_index, order_index)`。
- message_blocks：索引 `(message_id, order_index)`；如果按 topicId 批量取 blocks，增加索引 `(topic_id, message_id)` 或只在 blocks 表冗余 topic_id（你现在已经有 topicId）。
- Drift 查询：`select(messages)..where((t) => t.topicId.equals(topicId))..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])..limit(limit, offset: offset)` 等。

### 3.4 搜索（文本检索 + 结果聚合 + snippet）
涉及主要代码：
- `SearchService.search`: topic name contains + main_text block contains

意图拆解：
- “按关键词搜 topic.name（大小写不敏感）”
- “按关键词搜 main_text blocks.content（大小写不敏感）”
- “把命中的 block 关联回 message/topic/assistant，并给出 snippet（含 matchStart/matchEnd）”

SQLite/Drift 方案（推荐使用 FTS5，而不是 LIKE）：
- 建一个虚拟表：`fts_topics(topic_id UNINDEXED, name)`，与 topics 同步。
- 建一个虚拟表：`fts_blocks(block_id UNINDEXED, message_id UNINDEXED, topic_id UNINDEXED, content)`，只喂 `main_text`。
- 通过 `snippet(fts_blocks, ...)` 或在 Dart 层用现有 `text_cleaner` 生成 snippet；命中位置可以通过 `offsets()`（FTS4）或自算（FTS5 不直接给 offsets，需要用 snippet 高亮标记或在 Dart 二次定位）。
- 结果聚合：用 JOIN 把 topic/assistant/message 拉齐，减少 N+1 查询。

阶段落地建议：
- Phase 1：先用 LIKE 实现功能对齐（可快速上线，但性能一般）。
- Phase 2：引入 FTS5 并替换 SearchService（性能与体验显著提升）。

### 3.5 标注/笔记（知识条目：CRUD + 按 messageId/topicId 查询 + watch）
涉及主要代码：
- `KnowledgeEntryService`：大量 CRUD + `watchByMessage/watchAll`
- `HighlightService`：watch by message 映射成 highlight 列表

意图拆解：
- “按 messageId 查询知识条目（高亮/标注）”
- “按 topicId 查询知识条目”
- “按 tag 聚合统计”
- “watch：当某条消息的知识条目变化，UI 自动更新”

SQLite/Drift 方案：
- knowledge_entries 主表（entryId 唯一）。
- tags：建议用规范化的 `knowledge_entry_tags(entry_id, tag)`，便于统计与过滤。
- selectionRanges：可 JSON 存储（实现简单）或拆表（便于精确查询/调试）。
- watch：Drift 直接 `watch()` 选择器；与当前 Isar `.watch(fireImmediately: true)` 等价。

### 3.6 讨论（thread + messages + watch）
涉及主要代码：
- `DiscussionService` 调用 `IsarDatabase` 的 CRUD + watch
- `IsarDatabase.watchDiscussionMessages`

意图拆解：
- “按 messageId 列出讨论线程”
- “按 discussionId 列出消息并按 createdAt 升序”
- “watch：discussionId 下的消息变化”
- “删除 discussion 时级联删除 messages”

SQLite/Drift 方案：
- discussions 表（discussion_id 主键）
- discussion_messages 表（message_id 主键，discussion_id 外键）
- 外键 `ON DELETE CASCADE` 或在事务里显式删两表
- watch：`select(discussionMessages)..where((t)=>t.discussionId.equals(id))..orderBy([...])..watch()`

### 3.7 AI 对话（UnifiedConversation/UnifiedMessage + watch）
涉及主要代码：
- `UnifiedConversationService` 与 `IsarDatabase.watchUnifiedMessages`

意图拆解：
- “按 contextType/contextId 拉取 conversation 列表”
- “按 conversationId 拉取 messages”
- “watch messages 变化用于 UI”
- “删除 conversation 时级联删除 messages”

SQLite/Drift 方案：
- unified_conversations + unified_messages 两表
- 外键级联删除
- 针对常用筛选建索引：`(context_type, is_archived, updated_at)`、`(context_id, updated_at)`、`(conversation_id, created_at)`

### 3.8 洞察（perspectives/insights + 扫描导入数据做统计）
涉及主要代码：
- `InsightService`：perspective CRUD、insight 保存、以及基于 topic/message/block 的统计扫描

意图拆解：
- “视角列表：按 sortOrder 排序，支持内置/自定义，支持启用开关”
- “洞察结果：按时间、按视角过滤，落库缓存”
- “统计扫描：跨表聚合（assistant/topic/message/block）”

SQLite/Drift 方案：
- perspectives 表 + insights 表
- 统计扫描建议尽可能用 SQL 聚合（COUNT/SUM/MAX），减少 Dart 循环；但如果涉及复杂文本提取（例如从 blocks 里抽 main_text），可以先按 topicId 批量读 blocks 再在 Dart 处理。

### 3.9 模板与偏好（小表、简单 CRUD）
涉及主要代码：
- `PromptTemplateService`

意图拆解：
- “active preference 只能有一个”
- “删除 active preference 时自动激活第一个”
- “内置模板缺失时补齐”

SQLite/Drift 方案：
- user_preferences 表：对 `is_active = 1` 建唯一约束（可用部分索引/触发器实现；或在事务里保证先全部置 0，再置 1）。
- task_templates 表：用 `is_builtin` 标记内置，启动时 upsert 内置模板即可。

### 3.10 导出（从数据库重建 Cherry Studio 兼容格式）
涉及主要代码：
- `CherryExportService.exportFromIsar`

意图拆解：
- “按 assistant → topics → messages → blocks 重建 JSON”
- “files 需要补上本地缓存路径/sha256/size 等”

SQLite/Drift 方案：
- 尽量减少 N+1：一次性取 topics，再一次性取 messages（按 topicId 分组），blocks 同理。
- Drift 可以用 `select` + `whereIn` 批量查询；数据量大时分批 in 查询（例如每 500 个 id 一批）。

---

## 4. Drift 数据模型（建议 schema）

下面给出“可落地、与现有代码语义对齐”的表设计建议。它不是唯一答案，但遵循：**查询模式优先**、**写入幂等优先**、**索引明确可解释**。

### 4.1 导入域表

#### assistants
- `assistant_id TEXT PRIMARY KEY`
- `name TEXT NOT NULL`
- `description TEXT NULL`
- `avatar TEXT NULL`
- `prompt TEXT NULL`
- `topic_count INTEGER NOT NULL DEFAULT 0`
- `created_at INTEGER NOT NULL`
- `updated_at INTEGER NOT NULL`

索引：
- `idx_assistants_updated_at(updated_at DESC)`

#### topics
- `topic_id TEXT PRIMARY KEY`
- `name TEXT NOT NULL`
- `message_count INTEGER NOT NULL`
- `round_count INTEGER NOT NULL`
- `created_at INTEGER NOT NULL`
- `updated_at INTEGER NOT NULL`

#### topic_assistants（替代 Isar 的 stringList membership 查询）
- `topic_id TEXT NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE`
- `assistant_id TEXT NOT NULL REFERENCES assistants(assistant_id) ON DELETE CASCADE`
- `PRIMARY KEY (topic_id, assistant_id)`

索引：
- `idx_topic_assistants_assistant(assistant_id, topic_id)`

#### messages
- `message_id TEXT PRIMARY KEY`
- `topic_id TEXT NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE`
- `order_index INTEGER NOT NULL`
- `round_index INTEGER NOT NULL`
- `role TEXT NOT NULL`  (user/assistant)
- `ask_id TEXT NULL`
- `useful INTEGER NOT NULL` (0/1)
- `model_id TEXT NULL`
- `model_name TEXT NULL`
- `usage_json TEXT NULL`
- `metrics_json TEXT NULL`
- `mentions_json TEXT NULL`
- `created_at INTEGER NOT NULL`
- `status TEXT NOT NULL`

索引：
- `idx_messages_topic_order(topic_id, order_index)`
- `idx_messages_topic_round_order(topic_id, round_index, order_index)`
- `idx_messages_role_created(role, created_at)`

#### message_blocks
- `block_id TEXT PRIMARY KEY`
- `topic_id TEXT NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE`
- `message_id TEXT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE`
- `order_index INTEGER NOT NULL`
- `type TEXT NOT NULL`
- `content TEXT NULL`
- `thinking_millsec INTEGER NULL`
- `url TEXT NULL`
- `file_json TEXT NULL`
- `tool_json TEXT NULL`
- `error_json TEXT NULL`
- `target_language TEXT NULL`
- `response_json TEXT NULL`
- `knowledge_json TEXT NULL`
- `created_at INTEGER NOT NULL`

索引：
- `idx_blocks_message_order(message_id, order_index)`
- `idx_blocks_topic_message(topic_id, message_id)`
- `idx_blocks_type(type)`

#### files
- `file_id TEXT PRIMARY KEY`
- `file_name TEXT NULL`
- `local_path TEXT NULL`
- `file_size INTEGER NULL`
- `mime_type TEXT NULL`
- `sha256 TEXT NULL`
- `reference_count INTEGER NOT NULL DEFAULT 0`
- `created_at INTEGER NOT NULL`
- `updated_at INTEGER NOT NULL`

#### import_artifacts / import_jobs / provenance_records
对应你新增的三张表，关键点：
- `provenance_records`：`UNIQUE(source_type, entity_type, external_id)`，且 `first_seen_at` 不更新。

### 4.2 用户域表

#### knowledge_entries
- `entry_id TEXT PRIMARY KEY`
- `type INTEGER NOT NULL`（枚举）
- `message_id TEXT NULL`（关联 imported messages）
- `topic_id TEXT NULL`
- `quoted_text TEXT NULL`
- `start INTEGER NULL`
- `end INTEGER NULL`
- `color INTEGER NULL`
- `style_type TEXT NULL`
- `comment TEXT NULL`
- `content TEXT NULL`（笔记 delta）
- `content_type TEXT NULL`
- `plain_text TEXT NULL`
- `prefix TEXT NULL`
- `suffix TEXT NULL`
- `selections_json TEXT NULL`（或拆表）
- `created_at INTEGER NOT NULL`
- `updated_at INTEGER NOT NULL`

索引：
- `idx_ke_message(message_id, created_at DESC)`
- `idx_ke_topic(topic_id, created_at DESC)`
- `idx_ke_type(type, created_at DESC)`

#### knowledge_entry_tags
- `entry_id TEXT NOT NULL REFERENCES knowledge_entries(entry_id) ON DELETE CASCADE`
- `tag TEXT NOT NULL`
- `PRIMARY KEY(entry_id, tag)`
- `idx_tag(tag)`

#### discussions / discussion_messages
按第 3.6。

#### unified_conversations / unified_messages
按第 3.7。

#### user_preferences / task_templates
按第 3.9。

#### perspectives / insights
按第 3.8。

---

## 5. Drift 实现策略（工程化落地）

### 5.1 选择 Drift 的原因（与现有需求对齐）
- 支持 schema migration + codegen（替代 Isar generator）
- 支持事务与批量写入
- 支持 `watch()` 流式查询（对齐当前 `.watch(fireImmediately: true)`）
- 支持 SQLite 特性（FTS5、触发器、部分索引）并且可逐步引入

### 5.2 新的数据访问分层（建议）

目标：让“业务意图”落在 repository/service，而不是散落在 SQL 里。

- `AppDatabase`（Drift Generated）：只关心表、DAO（可选）、迁移
- `Sqlite*Repository`：实现现有接口 `IAssistantRepository/ITopicRepository/IMessageRepository`
- `SqliteIsolatedServices`：把现在直接依赖 Isar 的 service 改成依赖 `AppDatabase`（例如 SearchService / KnowledgeEntryService / InsightService）

### 5.3 与现有代码并行演进（避免一次性大爆炸）
- Phase 0：引入 Drift，建立空库与基础表（不接业务）。
- Phase 1：先迁 `RepositoryProvider` 的三仓库（assistant/topic/message），因为 UI 层大量依赖这一层（TopicIndexService/HomeScreen）。
- Phase 2：迁 `KnowledgeEntryService` 与 `Discussion/UnifiedConversation`（响应式 watch 先跑通）。
- Phase 3：迁 `SearchService`（先 LIKE，后 FTS）。
- Phase 4：迁 `DataImportService` 写入路径，完成“全链路只用 SQLite”。
- Phase 5：删除 Isar 依赖与生成文件，清理老代码。

---

## 6. 数据迁移（Isar → SQLite）策略

### 6.1 迁移触发条件
- App 启动时：如果 SQLite 为空而 Isar 非空，则执行一次性迁移。
- 或提供“设置页按钮：从旧库导入”。

### 6.2 迁移原则
- 分表分页迁移，避免一次性加载导致内存峰值。
- 迁移过程可中断可重试：使用 `migration_state` 表记录进度（或用 SharedPreferences）。
- 迁移后做一致性校验：关键表 count 对比（topics/messages/blocks/knowledge_entries/unified_messages）。

### 6.3 迁移顺序（推荐）
1) imported facts：assistants → topics → topic_assistants → messages → blocks → files  
2) user facts：knowledge_entries(+tags) → discussions(+messages) → unified_conversations(+messages) → preferences/templates → perspectives/insights  
3) import meta：import_artifacts/jobs/provenance（如需保留历史）

---

## 7. 需要改动的关键文件清单（按优先级）

### 7.1 第一阶段（最小闭环：列表 + 详情分页）
- [repository_provider.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/repository_provider.dart)（注入切换）
- [isar_assistant_repository.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/repositories/isar/isar_assistant_repository.dart)（新增 sqlite 实现替代）
- [isar_topic_repository.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/repositories/isar/isar_topic_repository.dart)
- [isar_message_repository.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/repositories/isar/isar_message_repository.dart)
- [topic_index_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/topic_index_service.dart)（无需大改，但要确保接口语义一致）

### 7.2 第二阶段（用户数据 + watch）
- [knowledge_entry_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/knowledge_entry_service.dart)
- [discussion_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/discussion_service.dart) + `IsarDatabase` 对应方法
- [unified_conversation_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/unified_conversation_service.dart)
- [prompt_template_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/prompt_template_service.dart)

### 7.3 第三阶段（搜索与导入写入）
- [search_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/search_service.dart)（建议最终切 FTS）
- [data_import_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/data_import_service.dart)（批量 upsert + provenance/job）

### 7.4 第四阶段（导出与洞察）
- [cherry_export_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/cherry_export_service.dart)
- [insight_service.dart](file:///Users/kbaicai/Documents/mmdev/cherryviewer/flutter_viewer/lib/services/insight_service.dart)

### 7.5 清理阶段
- `pubspec.yaml` 移除 isar 相关依赖，加入 drift
- 删除 `lib/models/isar/*.g.dart`（最后做，避免中途破坏编译）

---

## 8. 验证与性能基线（必须先定义，再谈迁移完成）

建议定义迁移“完成”的客观标准：
- 功能对齐：导入→首页→详情→搜索→高亮→讨论→洞察→导出 的主路径可用。
- 一致性：同一份导入数据，在 Isar 与 SQLite 下：
  - topicCount/messageCount/blockCount 与关键业务统计一致
  - 搜索结果数量在可接受范围内一致（FTS 与 contains 的语义差异要明确）
- 性能：
  - 导入 1 万 messages：耗时、峰值内存
  - 搜索 keyword：响应时间
  - 打开超长话题：首屏时间、滚动帧率

---

## 9. 下一步建议（可立即落地的切入点）
- 先做 Drift 的 `AppDatabase + 三仓库`，让 `HomeScreen/TopicIndexService` 跑在 SQLite 上。
- 搜索先维持 LIKE 以完成闭环，随后上 FTS5（这是 SQLite 迁移真正带来体验提升的点之一）。
- 版本化导入先暂停（或明确删掉），等 SQLite 稳定后再设计“多 db 文件 + 切换”的版本管理。

