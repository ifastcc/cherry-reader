# Cherry Reader 自定义数据源导入协议（Markdown / 目录）

本协议用于在 Cherry Reader 中从 **Markdown 文件**或**目录结构**导入聊天数据，并在内部转换为 Cherry Studio `data.json` 同构结构以复用现有导入/导出能力。

协议版本：0.1（与当前实现对齐）

---

## 1. 支持范围

- 支持导入：
  - 单个 `.md` 文件
  - 一个目录（批量导入）
- 支持解析：
  - YAML Front Matter（仅支持 `key: value` 的简单键值对）
  - `## User` / `## Assistant` 作为消息分段
  - Markdown 图片引用 `![alt](path)`（会生成 `image` block，并写入 `indexedDB.files[]` 元数据）
- 不支持/未实现（当前版本）：
  - 复杂 YAML（嵌套、数组、多行字符串等）
  - 角色别名（例如 `## Human`、`## System`）
  - 复杂附件类型（非图片）到 block 的细分映射

---

## 2. 导入方式（应用内）

- 首页右上角“同步”
  - 选择 `ZIP/JSON/MD` 导入：选择 `.zip/.json/.md`
  - 选择目录导入：选择一个目录作为根目录导入

---

## 3. 目录导入结构（推荐）

根目录示例：

```text
ImportSource/
├── assistants/
│   └── <assistant_slug>/
│       ├── _meta.yaml            # 可选：助手元数据
│       ├── <topic_slug>.md       # 话题文件（每个 md 一个 topic）
│       └── ...
├── chats/                        # 可选：无归属话题（统一归到内置 chats assistant）
│   └── <topic_slug>.md
└── files/                        # 可选：附件池（当前只用于“相对路径更稳”）
    └── any.png
```

约定：

- `assistants/<assistant_slug>/`：一个 assistant 的目录；目录名即 assistant 的 slug。
- `assistants/<assistant_slug>/*.md`：每个 md 表示一个 topic。
- `chats/*.md`：没有明确 assistant 归属的话题，导入时会归到一个名为 `chats` 的 assistant。

---

## 4. Assistant 元数据（\_meta.yaml，可选）

文件路径：

```text
assistants/<assistant_slug>/_meta.yaml
```

支持字段（简单键值对）：

```yaml
id: "optional-id"
name: "编程助手"
description: "专注 TypeScript 开发"
systemPrompt: "You are a helpful assistant."
prompt: "兼容字段：若 systemPrompt 不存在则使用 prompt"
avatar: "avatar.png"
```

说明：

- 若无 `_meta.yaml`：默认 `name = assistant_slug`。
- `id`：可选；不提供则使用确定性哈希生成（见第 7 节）。
- `systemPrompt/prompt/avatar/description`：会映射进导出的 Cherry assistant 结构。

---

## 5. Topic Markdown 格式

### 5.1 Front Matter（可选）

```markdown
---
id: "optional-id"
name: "关于 React 组件的讨论"
created_at: 2024-01-15T10:00:00Z
updated_at: 2024-01-15T12:00:00Z
---
```

支持字段：

- `id`：可选；不提供则使用确定性哈希生成（见第 7 节）
- `name`：可选；不提供则使用文件名（不含扩展名）
- `created_at/updated_at`（或 `createdAt/updatedAt`）：可选；不提供则使用当前时间

### 5.2 消息分段

使用二级标题分段：

```markdown
## User

用户消息内容

## Assistant

AI 回复内容
```

规则：

- `## User` 开始一条 `role=user` 的消息
- `## Assistant` 开始一条 `role=assistant` 的消息
- 标题之间的所有内容都属于该消息的正文

---

## 6. 图片/附件引用

### 6.1 Markdown 图片语法

在任意消息正文中写：

```markdown
![架构图](../files/diagram.png)
```

当前行为：

- 会在该消息生成一个 `image` block
- 会为 `diagram.png` 生成一条 `indexedDB.files[]` 元数据记录（包含 `id/path/size/type/ext` 等）
- 在导入到本地数据库时，会尝试把附件拷贝到应用沙箱 `attachments/` 目录，并写入 `FileEntity.localPath`

### 6.2 路径解析规则（当前实现）

对 `![...](path)` 的 `path`：

1. 先按“相对当前 md 文件所在目录”解析；
2. 若找不到文件，会尝试向上查找导入根目录（满足同时存在 `assistants/` 与 `files/`），并基于根目录做一次兜底解析（用于兼容 `../files/...` 写法）。

---

## 7. ID 策略（确定性哈希）

为保证幂等导入（同一份数据多次导入不重复），当前实现采用 SHA1 生成确定性 ID：

- `assistantId = sha1("assistant:" + assistant_slug)`（除非 `_meta.yaml` 显式提供 `id`）
- `topicId = sha1("topic:" + relative_path)`（除非 Front Matter 显式提供 `id`）
- `messageId = sha1(topicId + "#msg:" + message_index)`
- `blockId = sha1(messageId + "#blk:" + block_index)`
- `askId`：每遇到一个 `User` 消息生成一个 askId，后续连续的 `Assistant` 消息共享同一个 askId：
  - `askId = sha1(topicId + "#ask:" + ask_index)`
- `fileId`：
  - 先对文件内容算 `contentHash = sha1(fileBytes)`
  - `fileId = sha1("file:" + contentHash)`

---

## 8. 生成的 IR（内部结构概念）

导入时会生成与 Cherry Studio `data.json` 同构的结构（简化示意）：

```json
{
  "time": 1730000000000,
  "version": 5,
  "localStorage": {
    "persist:cherry-studio": "{\"assistants\":\"{\\\"assistants\\\":[...]}\"}"
  },
  "indexedDB": {
    "topics": [{ "id": "...", "messages": [...] }],
    "message_blocks": [{ "id": "...", "messageId": "...", "type": "main_text|image", ... }],
    "files": [{ "id": "...", "path": "Data/Files/<hash>.<ext>", ... }]
  }
}
```

注意：

- `persist:cherry-studio` 是“字符串套字符串”的兼容格式（与 Cherry Studio 备份一致）。

---

## 9. 已知限制与下一步建议

如果目标是“最终导出 ZIP 能在 Cherry Studio restore 后完整可用（含附件）”，当前版本已经做了基础闭环：

- 导入阶段会尝试拷贝附件到应用沙箱（`attachments/`）并记录 `FileEntity.localPath`
- 导出阶段会把 `FileEntity.localPath` 对应文件写入 ZIP 的 `Data/Files/`

仍建议后续补齐：

- 更严格的格式校验与错误提示（例如缺少 `## User/Assistant`、Front Matter 时间格式错误等）
- 支持更多语义块类型（file / audio / video）与渲染策略
