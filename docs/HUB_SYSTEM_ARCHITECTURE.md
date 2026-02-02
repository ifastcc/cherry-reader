# Hub 系统架构（草案 v0.1）

本文件面向你描述的目标形态：一个 Hub 作为权威数据面，接受多来源写入与导入，提供统一查询/下载，并被 Cherry Reader（移动端）聚合读取与写回；Cherry Studio（桌面端）可先通过备份导入接入，后续再演进为更实时的写入。

## 1. 目标与非目标

### 1.1 目标

- 一个可长期演进的权威数据面（Source of Truth）：对话、轮次、多回复、主线选择、附件、来源谱系。
- 多来源接入：Cherry Studio（zip/json 备份）、Cherry Reader（本地问答/标注/洞察/讨论）、Telegram、Poe/Gemini 导出等。
- 对外统一能力：
  - 查询：时间范围、标签、来源、关键词检索、向量检索（语义）。
  - 下载：导出 Hub Bundle；可选导出 Cherry Studio 兼容包。
- 幂等与增量：同一份数据反复导入不重复；已存在对话可追加新轮次/新回复；支持“旧对话新增一轮”的追加。

### 1.2 非目标（第一阶段明确不做）

- 不追求和 Cherry Studio 的“实时双向强一致同步”。
- 不追求一次性支持所有复杂消息类型映射（先覆盖 main_text / image / file / tool / error / thinking）。
- 不追求把所有外部来源完全无损映射为同一 UI 呈现（先做到语义可用、可检索、可回放）。

### 1.3 关键决策（为什么这样设计）

- 抽象层选择：采用 Thread → Turn → Reply，是因为你的核心交互形态稳定且与 Cherry Studio 的 askId/useful 语义同构。
- 不追求“零抽象”：导入/导出可以只是传输规范，但内部仍必须有最小信封（身份、来源、时间、幂等键），否则无法做到稳定增量与跨来源合并。
- Schema-on-read 的边界：可以存原始工件（artifact）以便未来重放/重新解析，但查询体验仍需要结构化权威数据与可重建索引投影。

## 2. 核心抽象（推荐采用 Thread → Turn → Reply）

你想要的交互形态相对固定：分组（话题）→ 多轮次（用户一次提问）→ 单轮多回复（多个模型/多版本）。

建议 Hub 的核心抽象是：

- Thread：一个话题/对话分组（等价于 Cherry Studio 的 topic 的“阅读视角”）
- Turn：一次用户提问（ask），对应一个 askId
- Reply：对某次提问的一个或多个模型回复（可多条、可标主线）
- Block：回复/提问的内容片段，承载富文本/图片/工具调用等
- Asset：附件对象（图片、文件、音频等），从 Block 引用
- Provenance：来源与谱系，记录这段数据从哪里来、怎么来的、外部 ID 是什么

> 兼容性提示：Cherry Studio/Cherry Reader 已有 askId/useful（主线）这类语义，映射成本最低。

## 3. 数据模型设计（权威数据 + 可投影索引）

### 3.1 主表（权威数据）

#### 3.1.1 workspace

- workspace_id
- owner_id / members（可后置）

#### 3.1.2 artifact（原始导入工件，强烈建议）

为保证“可重放、可追溯、可修正解析器”的能力，建议保留原始导入文件或其引用（ZIP/JSON/MD/目录包等）。权威结构化数据来自解析结果，但 artifact 允许未来修复 bug 后重建数据或补齐字段。

- artifact_id
- workspace_id
- source_type
- storage_key（对象存储路径或本地路径引用）
- sha256
- mime
- size
- created_at

#### 3.1.3 import_job（导入任务）

- import_id
- workspace_id
- artifact_id（可空：直接上传内容时也可先落 artifact）
- status（pending/running/succeeded/failed）
- stats_json（话题数、消息数、附件数、更新数等）
- error（可空）
- created_at / finished_at

#### 3.1.4 collection（分组/集合）

分组需要作为可编辑的“一等公民”存储，但它不参与话题身份判断。否则当用户把某个话题从 `poe` 分组移动到 `work` 分组时，下次导入 Poe 数据就会重复创建话题。

建议将“来源分组”和“用户分组”分离：

- source collection：来源平台自带的归属（例如 Poe 的 folder/space），用于谱系追溯
- user collection：用户在 Hub/Cherry Reader 中维护的归属，是组织结构的权威

字段建议：

- collection_id
- workspace_id
- type（source/user）
- source_type（当 type=source 时必填：poe/gemini/cherry_studio_backup/...）
- external_id（当 type=source 时：来源分组 id；当 type=user 时可空）
- name
- created_at / updated_at

#### 3.1.5 thread_collection（话题归属）

- workspace_id
- thread_id
- collection_id
- pinned（可选）
- created_at

约束建议：

- 同一 thread 可属于多个 collection（允许“来源分组 + 用户分组”并存）
- 导入时只追加/更新 source collection 归属，不覆盖 user collection 归属

#### 3.1.6 thread

- thread_id（Hub 内部 ID，UUID 或 ULID）
- workspace_id
- title
- tags（string[]）
- created_at / updated_at
- source_summary（可选：最新来源信息）

#### 3.1.7 turn

- turn_id（UUID/ULID）
- thread_id
- ask_id（稳定标识，见 4.1）
- turn_index（从 0 开始，便于展示；可由时间/导入顺序计算）
- asked_at
- user_message_id（指向 message）
- created_at / updated_at

#### 3.1.8 reply

- reply_id（UUID/ULID）
- thread_id
- turn_id
- message_id（指向 message）
- provider_id / model_id / model_name（可空）
- is_mainline（单 turn 内最多一个 true）
- status（pending/streaming/completed/error）
- created_at / updated_at

#### 3.1.9 message

用于“可寻址 + 可追加 + 可索引”。一个 turn 的 user 消息是一个 message；每个 reply 也是一个 message。

- message_id
- thread_id
- role（user/assistant/system/tool）
- created_at
- status
- source_message_key（见 4.1）
- blocks（不建议 JSON 内嵌，建议 message_block 表）

#### 3.1.10 message_block

- block_id
- message_id
- order_index
- type（main_text / image / file / tool / error / thinking / citation ...）
- content_text（可空）
- payload_json（可空：tool args、error、citation 等）
- asset_id（可空：图片/文件引用）
- created_at

#### 3.1.11 asset

- asset_id
- workspace_id
- sha256（去重）
- mime
- size
- storage_key（对象存储路径）
- origin_name（可空）
- created_at

#### 3.1.12 provenance_record（来源谱系）

把“幂等与增量”的关键字段独立出来，避免污染主表结构。

- provenance_id
- workspace_id
- source_type（cherry_studio_backup / cherry_reader / telegram / poe / gemini / manual_import ...）
- external_id（外部唯一标识：例如 topicId、telegram message id、文件路径等）
- entity_type（thread/turn/reply/message/asset）
- entity_id（Hub 内部 ID）
- external_parent_id（可空：用于表达层级，例如 turn 属于哪个外部 topic）
- first_seen_at / last_seen_at
- fingerprint（内容指纹，可用于内容变化检测）

### 3.2 索引/投影（可重建数据）

以下表不作为权威数据，属于加速查询的“投影”：

- message_fts：全文检索向量（tsvector），字段包含 main_text 拼接、标题、标签等
- message_embedding：embedding 向量（pgvector），建议按“userQuery + main_text”构建，支持多粒度（message级/turn级/thread级）
- thread_stats：轮次、消息数、最近活跃等统计冗余

## 4. 幂等、增量与唯一性策略

### 4.1 分组与身份解耦（必须）

原则：分组（collection）是可编辑的归属，不是身份。身份只由来源标识与内容结构决定。

因此：

- 话题（thread）的外部唯一键永远不包含 “collection name / collection id”
- 导入时 source collection 的归属可变，但 thread 的匹配必须稳定
- 用户把 thread 从 `poe` 移到 `work` 后，下次导入 Poe 的同一对话，必须命中同一个 thread，并只更新 source collection 谱系信息

### 4.2 ID 与 Key 的设计原则

核心要求：同一来源的数据重复导入，不产生重复实体；同一 thread 可以在未来追加 turn/reply；旧对话新增一轮也能正确落在同一 thread。

建议采用“双层标识”：

- Hub 内部 ID：thread_id/turn_id/message_id 等（UUID/ULID）
- 来源 Key：source_type + external_id（写入 provenance_record），用于幂等 upsert

具体到不同实体的 external_id 建议：

- Thread：
  - Cherry Studio：topicId（indexedDB.topics.id）
  - Telegram：chatId + threadTag（或你自定义的话题归属规则）
  - Poe/Gemini：导出文件中的 conversationId（若无则用“来源对话文件的稳定字段”生成 deterministic key）
- Turn：
  - 优先使用来源提供的 askId（Cherry Studio 有 askId）
  - 若来源无 askId：用 stable hash 生成，例如 sha1(thread_external_id + "#turn:" + user_message_external_id)
- Reply：
  - 优先使用来源 messageId（Cherry Studio message.id）
  - 若无：sha1(turn_external_id + "#reply:" + model + createdAt + contentHash)
- Message/Block：
  - 同上，能用外部 id 就用；不能就用 deterministic hash

### 4.3 话题标识的分层策略（强标识优先，弱标识兜底）

不同来源对“对话 ID”的支持程度不同，建议按优先级设计 thread_external_id 的生成策略：

- Level 1（强标识）：来源提供稳定的 conversationId/topicId，直接用 (source_type, external_id) 作为幂等键
- Level 2（稳定弱标识）：来源无 conversationId 但导出能提供稳定字段，生成 deterministic key，例如：
  - sha256(source_type + normalized(first_user_text) + created_at_day + participant_hint)
- Level 3（兜底匹配）：当导出格式变化导致 deterministic key 不稳定时，用相似度匹配定位旧 thread，匹配成功后将新的 external_id 作为别名写入 provenance_record，形成一对多映射

provenance_record 需要允许同一个 entity_id 绑定多个 (source_type, external_id)，用于“修正匹配后绑定别名”。

### 4.4 “旧对话新增一轮”的处理

当导入同一个 thread_external_id：

- Hub 根据 provenance_record 找到 thread_id（upsert thread）
- 遍历导入数据里的 turn：
  - 以 turn 的 external_id/upsert turn
  - 以 message external_id/upsert message
  - 以 reply external_id/upsert reply
- 对于新增 turn：自然插入即可；turn_index 可用 asked_at 排序后重算，或按导入顺序 + asked_at 共同决定

### 4.5 消息级幂等与增量（检测“是否新增/是否变更”）

对“话题是否新增东西”的判断，应下沉到 message/reply/turn 级别，而不是依赖标题或分组。

建议为 message 设计 source_message_key：

- 优先使用来源 messageId（如 Cherry Studio message.id）
- 若来源无 messageId：用 deterministic key 生成，例如：
  - sha256(role + created_at + normalized_text + attachment_hashes)

导入时：

- source_message_key 不存在：插入新 message/message_block（新增内容）
- source_message_key 存在但 fingerprint 变化：更新 message_block，并触发索引重建（内容变更）

可以额外在 thread 或 provenance_record 上维护水位线字段以加速“快速判断是否需要解析”：

- latest_source_message_created_at
- latest_source_message_key
- thread_fingerprint（例如把该 thread 下所有 source_message_key 排序后做一次 hash）

### 4.6 内容变更检测（是否需要更新）

对每个 entity（thread/turn/message/reply）存 fingerprint（例如 sha256(normalized content)）：

- fingerprint 未变：跳过更新（提升导入性能）
- fingerprint 变化：更新对应 message_block，并触发索引重建（fts/embedding）

## 5. 导入/导出协议（作为传输规范）

### 5.1 Hub Bundle（推荐对外输出/内部交换规范）

输出建议采用你偏好的“Thread → Turns → Replies”的结构，作为对外 API 的主要 payload 与下载格式。

- bundle 顶层包含：
  - schema/version
  - workspaceId
  - exportedAt
  - threads[]

每个 thread：

- threadId（Hub 内部）或 externalRef（来源信息）
- title/tags/createdAt/updatedAt
- turns[]：每个 turn 包含 askId、user message、replies[]
- assets[]（可选：也可通过 separate endpoint 下载）

### 5.2 适配器边界（不同来源如何对齐）

- Hub 内部只认 Thread/Turn/Reply/Message/Block/Asset；不同来源通过适配器映射进入这些结构。
- 当来源缺失关键字段（conversationId/messageId/askId 等）：
  - 先生成 deterministic key 保证幂等
  - 如后续发现更可靠的外部 id，可通过 provenance_record 追加别名完成“纠错绑定”

### 5.3 Cherry Studio 无损导入/导出（适配器策略）

- 导入：以 Cherry Studio 的 data.json 为输入，做字段级映射到 Hub 模型，并写 provenance_record 记录 topicId/messageId/blockId/fileId
- 导出：从 Hub 生成 Cherry Studio 兼容 data.json + ZIP（需要重建 localStorage assistants 目录信息；若 Hub 未维护 assistant 概念，可用 tags/collection 映射为 assistant，或使用单一 assistant）

> 注意：真正“无损”取决于 Cherry Studio 的字段集合。以你现有 Cherry Reader 导入字段看，message/model/usage/metrics/mentions/askId/useful/block payload 已经覆盖大部分核心语义。

## 6. API（最小集合，便于阶段 1 落地）

### 6.1 Ingest

- POST /v1/imports
  - 上传文件（zip/json/md/自定义 bundle）
  - 返回 import_id
- GET /v1/imports/{import_id}
  - 查看导入进度、统计、错误

### 6.2 Query

- GET /v1/threads?from=&to=&q=&tag=&source=&limit=&cursor=
- GET /v1/threads/{thread_id}
- GET /v1/threads/{thread_id}/bundle（导出单个 thread 的 bundle）
- POST /v1/search
  - keyword：FTS
  - vector：pgvector

### 6.3 Assets

- GET /v1/assets/{asset_id}（签名下载或代理下载）

### 6.4 Write（阶段 2）

- POST /v1/threads/{thread_id}/turns
- POST /v1/turns/{turn_id}/replies
- POST /v1/annotations（标注/洞察/讨论等，作为扩展实体）

### 6.5 Auth（最小可用）

第一阶段可先用 workspace token：

- POST /v1/tokens（生成/轮换 token，需管理员权限）
- 使用：Authorization: Bearer <token>

建议为 token 增加：

- scopes（read/import/write/admin）
- expiry（可选）

## 7. 客户端策略（Cherry Reader / Cherry Studio）

### 7.1 Cherry Reader：离线优先 + Hub 聚合

- 读取：
  - 在线：按时间窗口/分页拉取 threads 列表；按需拉 thread bundle
  - 离线：本地缓存（可沿用现有版本化 Isar 思路）
- 写入：
  - 本地先落库并写入 outbox（离线队列）
  - 网络可用时批量 flush 到 Hub（幂等提交，失败可重试）

### 7.2 Cherry Studio：低侵入接入优先

- 阶段 1：仍以备份 ZIP/JSON 作为导入输入（可通过 WebDAV/脚本定期上传到 Hub）
- 阶段 4：如确有必要再做更细粒度的实时 connector

## 8. 技术选型建议（实现层面）

- 主库：PostgreSQL
  - 全文：tsvector + GIN；模糊：pg_trgm
  - 向量：pgvector + HNSW
- 附件：S3/MinIO（或磁盘 + storage_key 抽象）
- 后台任务：导入解析、索引构建（fts/embedding）建议异步化

## 9. 安全与隐私（最低要求）

- Hub token 属于敏感信息：日志中禁止打印；客户端需安全存储（Keychain/Keystore）。
- 附件下载建议走签名 URL 或带鉴权的代理下载，避免直接暴露存储桶。
- 若未来涉及多人或公网访问：必须补齐用户体系、审计日志、速率限制与备份策略。
