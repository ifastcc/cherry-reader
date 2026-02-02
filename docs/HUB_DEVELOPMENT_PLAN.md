# Hub 开发计划（草案 v0.1）

本计划按你提出的阶段拆解，并把“无损导入/导出、更多来源接入、增量与唯一性”作为主线。目标是每个阶段都能交付可用成果，而不是等终局形态才可用。

## 0. 设计原则（贯穿全程）

- 权威数据面在 Hub：客户端可以缓存/投影，但 Hub 是最终归档与查询入口。
- 幂等优先：任何导入/写入都必须可重复执行不产生重复。
- 分组与身份解耦：分组（collection）可编辑但不参与话题唯一性判断，避免移动分组导致重复话题。
- 离线优先：客户端写入先落本地并进入 outbox，网络可用时幂等写回 Hub。
- 保留原始工件：导入文件（artifact）应可重放，便于未来修复解析器后重建数据。
- 先“可用闭环”，再“完美无损”：先覆盖 main_text/askId/主线、多回复、附件；特殊 block 类型逐步补齐。
- 索引可重建：全文/向量索引都是投影，坏了能重建，不影响权威数据正确性。
  - 第一期只保证“可检索/可回放”，不追求跨来源 UI 完全一致。

## 1. 阶段 1：数据结构 + Cherry Studio 无损导入（MVP，2–4 周）

### 1.1 输出物（可验收）

- Hub 服务（HTTP API）能：
  - 上传 Cherry Studio ZIP/JSON
  - 导入到 Hub 数据库（thread/turn/reply/message/block/asset/provenance）
  - 查询 threads 列表与详情
  - 下载 Hub Bundle（thread→turn→replies）
- Cherry Reader 能：
  - 作为 Hub 的只读客户端：拉取 Bundle 并导入本地（版本库或缓存库）

### 1.2 任务拆解

#### 1.2.1 设计并落地 Hub 数据模型（主存储）

- 定义：artifact / import_job（导入可追溯与可重放）
- 定义：collection / thread_collection（分组与归属）
- 定义：thread / turn / reply / message / message_block / asset / provenance_record
- 定义：source_type 枚举（cherry_studio_backup / cherry_reader / telegram / poe / gemini / manual_import）
- 定义：幂等 key（source_type + external_id）与 fingerprint
- 定义：最小鉴权（workspace token，read/import/write/admin scopes）

#### 1.2.2 Cherry Studio → Hub 导入适配器

- 输入：ZIP（内含 data.json）/ 单独 data.json
- 解析：
  - localStorage.persist:cherry-studio.assistants（用于 topic 归属与标题元数据）
  - indexedDB.topics/messages/message_blocks/files
- 映射：
  - topicId → thread_external_id
  - message.askId → turn_external_id（缺失时生成）
  - message.useful → reply.is_mainline（若 role=assistant）
  - blocks[] → message_block（按 blockId 寻址 blockMap）
  - files[] → asset（按 fileId/sha256 去重）
- 幂等：
  - 同一 topicId 再导入：upsert thread
  - turn/reply/message/block 按外部 id upsert
  - fingerprint 不变则跳过更新
  - 分组只更新 source collection，不覆盖 user collection

#### 1.2.3 Hub 查询 API（最小集合）

- GET /threads（分页、时间范围）
- GET /threads/{id}（包含 turns/replies，或提供展开参数）
- GET /threads/{id}/bundle
- GET /assets/{id}（下载/签名下载）
- POST /tokens（生成/轮换 token）

#### 1.2.4 Cherry Reader 对接 Hub（只读）

- 新增同步源：Hub（baseUrl + token）
- 拉取策略：
  - 先用“时间范围 + 游标分页”拉 threads 元数据
  - 点开/需要时再拉详情 bundle（节省带宽）
- 本地落库策略（二选一）：
  - A：导入到现有版本化 Isar（把 Hub bundle 映射为 Topic/Message/Block）
  - B：新增 Hub-only 的只读缓存库（更干净，但改动多）

### 1.3 验收清单

- 同一个 Cherry Studio 备份导入 3 次，Hub 数据不重复
- 把某个 thread 从 `poe` 分组移动到 `work` 后，再导入 Poe 数据不生成新 thread
- 导入后能正确看到：
  - thread 列表、turn 轮次、单轮多回复、主线标记
  - 至少 main_text 完整
  - 附件可下载（图片/文件）
- Cherry Reader 能拉取并展示 Hub 数据
- Hub 导入任务可追踪（import_job 状态、统计、错误）
- Hub token 不出现在日志输出

## 2. 阶段 2：Cherry Studio 无损导出 + Hub 索引（4–8 周）

### 2.1 输出物

- Hub → Cherry Studio：导出 ZIP（data.json + Data/Files）
- Hub 支持关键词检索 + 向量检索（最小可用）

### 2.2 任务拆解

#### 2.2.1 Hub → Cherry Studio 导出适配器

- 关键点：重建 Cherry Studio 需要的结构：
  - localStorage.persist:cherry-studio.assistants（可由 tags/collection 映射生成；或用单 assistant）
  - indexedDB.topics/messages/message_blocks/files
  - Data/Files 附件路径与 fileId 映射
- 无损目标：
  - askId/useful/model/usage/mentions 等尽量保留
  - block 的 payload 尽量保持原始字段集合

#### 2.2.2 索引管线（可重建投影）

- FTS（关键词）：
  - message_block.main_text 拼接成 message_text
  - 生成 tsvector（GIN 索引）
  - 模糊匹配可引入 pg_trgm
- 向量（语义）：
  - 优先对 user 提问、mainline reply 建 embedding
  - pgvector HNSW 索引
- 后台任务：
  - 导入后异步构建索引
  - 支持“重建索引”命令（admin endpoint）

### 2.3 验收清单

- 从 Hub 导出 ZIP，能在 Cherry Studio restore 后可正常浏览（至少主文本、轮次、多回复）
- 关键词搜索能返回合理结果；语义搜索能命中相关 threads/messages

## 3. 阶段 3：更多来源（Poe/Gemini/Telegram）+ 增量策略（持续迭代）

### 3.1 输出物

- Hub 支持新增 source_type 的导入适配器
- 增量导入可用：新增 turn、旧对话追加一轮、单轮新增回复都能正确合并

### 3.2 “增量与唯一性”设计（重点）

#### 3.2.1 幂等键体系

对每个实体写 provenance_record，统一用：

- (workspace_id, source_type, entity_type, external_id) 唯一

external_id 规则：

- 有官方 id：直接用（如 Cherry Studio topicId/messageId/blockId；Telegram update id）
- 无官方 id：用 deterministic hash 生成（内容 + 时间 + 父级 external_id）
- 如后续找到更可靠的外部 id：写 provenance 别名绑定到既有 thread（修正匹配）

#### 3.2.2 旧对话追加一轮（最常见）

导入某个来源的一个“对话对象”时：

- 先定位 thread（按 thread_external_id upsert）
- 再遍历 turn：
  - turn_external_id 存在则 upsert，缺失则生成（建议用 user message 外部 id 生成）
- reply 同理
- turn_index 可按 asked_at 排序后重排（保持 UI 一致）

#### 3.2.3 单轮新增回复（多模型/补答）

同一个 turn_external_id 下新增 reply_external_id：

- 直接插入 reply；必要时重新计算 is_mainline（保持唯一）

### 3.3 接入 Poe/Gemini/Telegram 的策略

#### 3.3.1 先文件导入，后 connector

- Poe/Gemini：优先做“导出文件 → 上传 Hub → 适配器解析”
- Telegram：用 bot/webhook 直接写 Hub（turn/reply 追加）

#### 3.3.2 适配器输出统一映射到 Hub 模型

无论来源如何，适配器的产出统一是：

- thread（标题/标签/来源）
- turns（每轮的 user message）
- replies（每轮的一个或多个回复）
- assets（可选）
- provenance（每个节点外部 id）

### 3.4 验收清单

- 同一来源数据重复导入不会重复
- 已存在 thread 能追加 turn/reply
- 时间线、轮次、主线在多次增量后仍稳定
- 来源分组变化不会影响 thread 匹配（只影响 source collection 归属）

## 4. 阶段 4（可选）：更实时的 Cherry Studio 写入与多端双写

这阶段只有当“非 Cherry Studio 写入占比明显提升”才值得投入。

- 低侵入版本：Cherry Studio 定期上传备份到 Hub（自动化脚本/插件）
- 高侵入版本：Cherry Studio 变成 Hub 客户端（细粒度增量写入、冲突处理、鉴权）

## 5. Cherry Reader 后续演进清单（对齐 Hub）

- Hub 同步源（阶段 1）：只读聚合
- 写回 Hub（阶段 2/3）：
  - 移动端问答（turn/reply）
  - 标注/洞察/讨论（扩展实体，和 message/thread 关联）
- 搜索策略：
  - 离线：本地 Isar 索引
  - 在线：Hub 搜索（关键词/向量）
- 冲突策略：
  - 以 Hub 为权威；本地仅缓存与离线队列
  - outbox 写回必须幂等，失败可重试，不依赖“最后一次状态”
