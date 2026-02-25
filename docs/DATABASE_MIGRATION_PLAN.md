# 数据库架构迁移计划：从 JSON Blob 到消息级存储

> 文档版本：1.3
> 创建日期：2024-12
> 最后更新：2025-12
> 状态：规划中

---

## 0. 相关文档（SQLite / Drift）

如果你要把当前项目从 Isar 迁移到 SQLite（Drift），并且希望从“业务意图/第一性原理”出发做重构，而不是做语法替换，请看：

- [DRIFT_REFACTOR_PLAN.md](./DRIFT_REFACTOR_PLAN.md)

## 一、背景与问题

### 1.1 当前架构概述

Cherry Reader 是一个用于查看和分析 Cherry Studio 聊天记录的 Flutter 应用。当前使用 Isar 数据库存储数据，核心数据模型如下：

```
数据层级：
Assistant (助手)
  └── Topic (话题)
        └── Round (轮次/对话)
              └── Reply (AI回复，可能有多个模型的回复)
```

**当前存储方式**：

```dart
@collection
class TopicCacheEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String topicId;

  late String name;
  late String assistantId;
  late int messageCount;
  late int roundCount;

  late String dataJson;  // ⚠️ 核心问题：整个话题的 JSON 序列化

  late int createdAt;
  late int updatedAt;
}
```

### 1.2 发现的问题

#### 问题 1：打开长话题时加载慢

**现象**：打开一个有很多轮对话的话题时，需要等待 2-5 秒才能显示内容。

**根因分析**：

```
当前加载流程：
1. loadTopicData(topicId)
2. 从 Isar 读取 TopicCacheEntity
3. json.decode(entity.dataJson)  ← 一次性反序列化整个话题
4. 得到 100+ 条消息的完整数据
5. 在内存中分组处理
6. 渲染（虽然 UI 是虚拟化的，但数据已经全部加载）
```

**问题本质**：

- `dataJson` 存储了整个话题的 JSON（可能 500KB+）
- 无法分页加载消息
- 无法只加载可见区域的消息
- JSON 反序列化是 CPU 密集型操作

#### 问题 2：Block 内容已写入缓存，但仍是大 JSON Blob，附件未落库

**现象**：
- 当前在 `HomeScreen` 导入阶段已将 block 内容展开后写入 `dataJson`（`saveTopicIndexCache` 传入的 `processedTopic` 包含完整 blocks），因此不再只存 ID。
- 但 block、消息、附件依然打包在单个 JSON Blob 中，无法分页/增量加载，且 image/file 块依赖 ZIP 内的 `files[]` 原始附件，一旦用户删除源文件会断链。

**根因分析**：
- `dataJson` 仍保存完整话题 JSON（含 blocks），未拆分为消息级表。
- `CherryExtractor.files` 只在内存中，未持久化到 Isar 或应用沙箱路径，图片/附件 URL 仍指向导出文件。

**影响**：
- 仍需一次性反序列化大 JSON，CPU/内存开销高，无法按需加载。
- 删除原 ZIP/JSON 后，图片/附件无法显示。

### 1.3 数据流转分析

```
┌─────────────────────────────────────────────────────────────────┐
│                        数据导入流程                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  用户选择 ZIP/JSON 文件                                          │
│         ↓                                                       │
│  CherryExtractor.load()                                         │
│    ├─ 解压/读取文件                                              │
│    ├─ 提取 indexedDB.topics[]                                   │
│    ├─ 提取 indexedDB.message_blocks[]                           │
│    └─ 构建 blockMap (block_id → block)  ← ⚠️ 仅内存中，未持久化   │
│         ↓                                                       │
│  DataPersistenceManager.saveTopicIndexCache()                   │
│    ├─ 遍历每个 topic                                             │
│    ├─ json.encode(topic) → dataJson   ← ⚠️ 不包含 block 内容     │
│    └─ 批量保存到 Isar (TopicCacheEntity)                         │
│         ↓                                                       │
│  用户打开话题                                                    │
│         ↓                                                       │
│  DataPersistenceManager.loadTopicData(topicId)                  │
│    ├─ Isar 查询 TopicCacheEntity                                │
│    └─ json.decode(dataJson) ← ⚠️ 只有 block IDs，无内容          │
│         ↓                                                       │
│  ConversationScreen 渲染                                        │
│    ├─ 需要 extractor.blockMap 获取实际内容                       │
│    ├─ _getConversationGroups() 在内存中分组                      │
│    └─ ScrollablePositionedList 虚拟化渲染                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4 当前 Isar 实体一览

| 实体                        | 用途           | 存储内容                           |
| --------------------------- | -------------- | ---------------------------------- |
| `TopicCacheEntity`          | 话题缓存       | 元数据 + **dataJson（不含 block 内容）**  |
| `HighlightEntity`           | 文本标注       | messageId, text, start, end, color |
| `AIAnalysisEntity`          | AI 分析缓存    | topicId, groupIndex, content       |
| `DiscussionEntity`          | 讨论线程（旧） | messageId, title                   |
| `DiscussionMessageEntity`   | 讨论消息（旧） | discussionId, role, content        |
| `UnifiedConversationEntity` | 统一对话（新） | contextType, contextId, title      |
| `UnifiedMessageEntity`      | 统一消息（新） | conversationId, role, content      |
| `TaskTemplateEntity`        | 任务模板       | name, content, targetType          |
| `UserPreferenceEntity`      | 用户偏好       | systemPrompt                       |

### 1.5 新实体与 UnifiedConversationEntity 的关系

项目中已存在 `UnifiedConversationEntity` 和 `UnifiedMessageEntity`，用于 AI 对话功能。新的 `MessageEntity` 与它们的关系如下：

| 实体 | 用途 | 数据来源 |
|------|------|----------|
| `MessageEntity` | 存储 Cherry Studio 导入的历史消息 | 用户导入的 ZIP/JSON |
| `UnifiedMessageEntity` | 存储应用内 AI 对话消息 | 用户与 AI 的实时对话 |

**设计决策**：保持两套实体独立，因为：

1. **数据来源不同**：`MessageEntity` 是只读的导入数据，`UnifiedMessageEntity` 是可编辑的对话数据
2. **字段差异**：`MessageEntity` 需要 `askId`、`useful`、`blocks` 等 Cherry Studio 特有字段
3. **生命周期不同**：导入数据随文件更新而重置，对话数据需要持久保留

**未来统一方案**：如果需要统一，可以在 `UnifiedConversationEntity` 中添加 `sourceType` 字段区分数据来源。

---

## 二、解决方案：方案 B - 消息级存储

### 2.1 核心思路

将 `TopicCacheEntity.dataJson` 拆分为四个独立的 Isar 集合：

```
当前：TopicCacheEntity.dataJson (一个大 JSON，不含 block 内容)
     ↓ 拆分为
新架构：
     AssistantEntity (助手元数据) ← 新增
         ↓ 1:N
     TopicEntity (轻量级元数据)
         ↓ 1:N
     MessageEntity (消息级存储)
         ↓ 1:N
     MessageBlockEntity (消息块存储，包含实际内容)
```

### 2.2 新数据模型设计

#### AssistantEntity（助手元数据）

```dart
@collection
class AssistantEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String assistantId;

  late String name;
  String? description;
  String? avatar;       // 头像 URL 或 Base64
  String? prompt;       // 系统提示词

  late int topicCount;  // 话题数量（冗余字段，提升查询性能）

  @Index()
  late int createdAt;
  late int updatedAt;
}
```

**存储内容**：助手的元数据，用于首页分组展示。
**预估大小**：每个助手约 1KB。

#### TopicEntity（话题元数据）

```dart
@collection
class TopicEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String topicId;

  late String name;

  @Index(composite: [CompositeIndex('createdAt')])  // 复合索引
  late String assistantId;

  late int messageCount;
  late int roundCount;

  @Index()
  late int createdAt;
  late int updatedAt;
}
```

**存储内容**：只存储话题的元数据，不存储消息内容。
**预估大小**：每个话题约 200 字节。

#### MessageEntity（消息）

```dart
@collection
class MessageEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String messageId;

  @Index(composite: [CompositeIndex('orderIndex')])  // 复合索引：topicId + orderIndex
  late String topicId;

  late int orderIndex;  // 在话题中的顺序（0, 1, 2, 3...）

  @Index()
  late int roundIndex;  // 所属轮次索引（用于按轮次分页）

  late String role;     // user / assistant

  @Index()
  String? askId;        // 同一问题的回复分组 ID

  late bool useful;     // 是否为主线回复

  String? modelId;
  String? modelName;

  String? usageJson;    // Token 统计 (JSON)
  String? metricsJson;  // 性能指标 (JSON)
  String? mentionsJson; // @mention 列表 (JSON)

  @Index()
  late int createdAt;
  late String status;
}
```

**存储内容**：消息的元数据和关联信息，不存储实际文本内容。
**预估大小**：每条消息约 500 字节。

**`orderIndex` 索引策略**：

| 场景 | 索引方式 | 说明 |
|------|---------|------|
| 导入的历史消息 | 简单顺序（0, 1, 2...） | 只读数据，无需插入 |
| 用户 AI 对话 | 稀疏索引（1000, 2000, 3000...） | 可能需要中间插入 |
| 统一消息系统（未来） | 稀疏索引 + 重排 | 两套系统合并时使用 |

**设计考量**：
- 当前 `MessageEntity` 用于**只读的导入数据**，简单顺序索引足够
- 项目中还有 `UnifiedMessageEntity`（用户自己的 AI 对话），支持多模型回复、重试等
- 如果将来**统一两套消息系统**，需要支持在中间插入消息
- 建议：导入时使用简单顺序，但保留**稀疏索引的能力**以备扩展

```dart
// 当前：导入数据使用简单顺序
orderIndex: i,  // 0, 1, 2, 3...

// 未来：如果需要支持插入，改为稀疏索引
orderIndex: i * 1000,  // 0, 1000, 2000, 3000...
// 插入时：在 1000 和 2000 之间插入 1500
```

#### MessageBlockEntity（消息块）

```dart
@collection
class MessageBlockEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String blockId;

  @Index(composite: [CompositeIndex('orderIndex')])  // 复合索引
  late String messageId;

  late int orderIndex;  // 在消息中的顺序

  late String type;     // main_text, thinking, image, file, tool, citation, error, translation, code, video

  String? content;      // 主要文本内容（长文本）

  // 特定类型字段
  double? thinkingMillsec;  // thinking 块
  String? url;              // image 块
  String? fileJson;         // file 块
  String? toolJson;         // tool 块
  String? errorJson;        // error 块

  late int createdAt;
}
```

**存储内容**：实际的消息内容，包括文本、思考过程、图片等。
**预估大小**：每个块 1KB - 50KB 不等（取决于内容长度）。

#### 附件存储（补充）

图片/文件 Block 需要同时落库或落盘，避免依赖原始 ZIP：

```dart
@collection
class FileEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String fileId;     // 对应 Cherry 导出的文件 id

  String? fileName;
  String? mimeType;
  String? sha256;
  String? localPath;      // 拷贝到应用沙箱后的路径
  String? url;            // 远端/原始 URL 备份

  @Index()
  late int createdAt;
}
```

导入时将 `files[]` 复制到应用可访问目录并记录 hash，Block 中只保留 `fileId`/`url` 的引用，读取时通过 `FileEntity` 解析为可用路径。

**存储策略**：
- 目录：`{app_documents}/cherry_files/{year}/{month}/{hash_prefix}/{full_sha256}.{ext}`，按月+hash 前缀分桶。
- 去重：导入时计算 sha256（大文件可只取首尾 1MB 组合），若已存在同 hash 的 FileEntity 则复用 `localPath`，不重复拷贝；维护引用计数，删除 MessageBlockEntity 时同步扣减。
- 大文件：>50MB 默认不复制，仅保留 url 引用并提示用户“保留原始链接”，阈值可配置。
- 清理：定期任务/设置页“清理孤立文件”扫描引用计数为 0 的文件并删除，同时清理 FileEntity 记录。

### 2.3 架构对比

| 维度     | 当前架构              | 新架构（方案 B） |
| -------- | --------------------- | ---------------- |
| 存储方式 | JSON Blob（不含 block 内容） | 分表存储（完整数据） |
| 加载方式 | 整体加载              | 分页加载         |
| 查询粒度 | 话题级                | 消息级 / 块级    |
| 内存占用 | 高（完整话题）        | 低（按需加载）   |
| 首屏速度 | 慢（需要全部解析）    | 快（只加载首页） |
| 数据完整性 | 依赖原始文件          | 自包含           |

### 2.4 查询接口设计

为了更好的代码组织和测试性，采用 **Repository 抽象层** 设计：

```dart
/// ========== 抽象接口层 ==========

/// 消息数据模型（与数据库实现无关）
class MessageModel {
  final String messageId;
  final String topicId;
  final int orderIndex;
  final int roundIndex;
  final String role;
  final String? askId;
  final bool useful;
  final String? modelId;
  final String? modelName;
  final int createdAt;
  final String status;

  MessageModel({
    required this.messageId,
    required this.topicId,
    required this.orderIndex,
    required this.roundIndex,
    required this.role,
    this.askId,
    required this.useful,
    this.modelId,
    this.modelName,
    required this.createdAt,
    required this.status,
  });
}

/// 消息块数据模型
class BlockModel {
  final String blockId;
  final String messageId;
  final int orderIndex;
  final String type;
  final String? content;
  final double? thinkingMillsec;
  final String? url;
  final int createdAt;

  BlockModel({
    required this.blockId,
    required this.messageId,
    required this.orderIndex,
    required this.type,
    this.content,
    this.thinkingMillsec,
    this.url,
    required this.createdAt,
  });
}

/// 消息仓库抽象接口
abstract class IMessageRepository {
  /// 获取话题的消息数量
  Future<int> getMessageCount(String topicId);

  /// 分页加载消息
  Future<List<MessageModel>> loadMessages(
    String topicId, {
    int offset = 0,
    int limit = 20,
  });

  /// 加载消息的所有 Block
  Future<List<BlockModel>> loadBlocks(String messageId);

  /// 批量加载多条消息的 Block（避免 N+1 问题）
  Future<Map<String, List<BlockModel>>> batchLoadBlocks(List<String> messageIds);

  /// 按轮次分页加载
  Future<List<MessageModel>> loadRounds(
    String topicId, {
    int startRound = 0,
    int roundCount = 5,
  });

  /// 获取话题的轮次总数
  Future<int> getRoundCount(String topicId);

  /// 监听消息变化
  Stream<List<MessageModel>> watchMessages(String topicId);
}

/// 话题仓库抽象接口
abstract class ITopicRepository {
  Future<List<TopicModel>> getTopicsByAssistant(String assistantId);
  Future<TopicModel?> getTopic(String topicId);
  Future<int> getTopicCount();
}

/// 助手仓库抽象接口
abstract class IAssistantRepository {
  Future<List<AssistantModel>> getAllAssistants();
  Future<AssistantModel?> getAssistant(String assistantId);
}

/// ========== Isar 实现层 ==========

class IsarMessageRepository implements IMessageRepository {
  final IsarDatabase _db;

  IsarMessageRepository(this._db);

  /// 获取话题的消息数量
  Future<int> getMessageCount(String topicId) async {
    try {
      final isar = await _db.instance;
      return isar.messageEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .count();
    } on IsarError catch (e) {
      print('❌ 获取消息数量失败: $e');
      return 0;
    }
  }

  /// 分页加载消息
  @override
  Future<List<MessageModel>> loadMessages(
    String topicId, {
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final isar = await _db.instance;
      final entities = await isar.messageEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .sortByOrderIndex()
          .offset(offset)
          .limit(limit)
          .findAll();
      return entities.map(_toMessageModel).toList();
    } on IsarError catch (e) {
      print('❌ 加载消息失败: $e');
      return [];
    }
  }

  /// 加载消息的所有 Block
  @override
  Future<List<BlockModel>> loadBlocks(String messageId) async {
    try {
      final isar = await _db.instance;
      final entities = await isar.messageBlockEntitys
          .filter()
          .messageIdEqualTo(messageId)
          .sortByOrderIndex()
          .findAll();
      return entities.map(_toBlockModel).toList();
    } on IsarError catch (e) {
      print('❌ 加载 Block 失败: $e');
      return [];
    }
  }

  /// 批量加载多条消息的 Block（避免 N+1 问题）
  @override
  Future<Map<String, List<BlockModel>>> batchLoadBlocks(
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return {};

    try {
      final isar = await _db.instance;
      final entities = await isar.messageBlockEntitys
          .filter()
          .anyOf(messageIds, (q, id) => q.messageIdEqualTo(id))
          .findAll();

      final grouped = <String, List<BlockModel>>{};
      for (final entity in entities) {
        grouped.putIfAbsent(entity.messageId, () => []).add(_toBlockModel(entity));
      }

      // 按 orderIndex 排序
      for (final list in grouped.values) {
        list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      }

      return grouped;
    } on IsarError catch (e) {
      print('❌ 批量加载 Block 失败: $e');
      return {};
    }
  }

  /// 按轮次分页加载（推荐：与 UI 展示逻辑一致）
  ///
  /// 一个轮次 = 一个用户问题 + 所有 AI 回复
  /// 这样分页不会截断多模型回复
  @override
  Future<List<MessageModel>> loadRounds(
    String topicId, {
    int startRound = 0,
    int roundCount = 5,
  }) async {
    try {
      final isar = await _db.instance;
      final entities = await isar.messageEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .roundIndexBetween(startRound, startRound + roundCount - 1)
          .sortByOrderIndex()
          .findAll();
      return entities.map(_toMessageModel).toList();
    } on IsarError catch (e) {
      print('❌ 按轮次加载失败: $e');
      return [];
    }
  }

  /// 获取话题的轮次总数
  @override
  Future<int> getRoundCount(String topicId) async {
    try {
      final isar = await _db.instance;
      final topic = await isar.topicEntitys
          .filter()
          .topicIdEqualTo(topicId)
          .findFirst();
      return topic?.roundCount ?? 0;
    } on IsarError catch (e) {
      print('❌ 获取轮次数量失败: $e');
      return 0;
    }
  }

  /// 监听消息变化
  @override
  Stream<List<MessageModel>> watchMessages(String topicId) {
    return _db.instanceSync.messageEntitys
        .filter()
        .topicIdEqualTo(topicId)
        .sortByOrderIndex()
        .watch(fireImmediately: true)
        .map((entities) => entities.map(_toMessageModel).toList());
  }

  // ========== 私有转换方法 ==========

  MessageModel _toMessageModel(MessageEntity e) => MessageModel(
    messageId: e.messageId,
    topicId: e.topicId,
    orderIndex: e.orderIndex,
    roundIndex: e.roundIndex,
    role: e.role,
    askId: e.askId,
    useful: e.useful,
    modelId: e.modelId,
    modelName: e.modelName,
    createdAt: e.createdAt,
    status: e.status,
  );

  BlockModel _toBlockModel(MessageBlockEntity e) => BlockModel(
    blockId: e.blockId,
    messageId: e.messageId,
    orderIndex: e.orderIndex,
    type: e.type,
    content: e.content,
    thinkingMillsec: e.thinkingMillsec,
    url: e.url,
    createdAt: e.createdAt,
  );
}
```

### 2.5 首屏加载策略

为了达到 <200ms 的首屏加载目标，采用以下策略：

```
首屏加载策略：

1. 初始加载
   ├─ 加载前 5 个轮次的消息
   ├─ 批量加载这些消息的 Block（batchLoadBlocks）
   └─ 批量预加载标注（HighlightService.batchPreload）

2. Block 懒加载（按类型区分）
   ├─ main_text: 立即加载（核心内容）
   ├─ thinking: 仅加载元数据，展开时加载 content
   ├─ image: 显示占位图，进入可见区域时加载
   └─ file/tool/citation: 按需加载

3. 预加载缓冲
   ├─ 当前可见位置 + 2 个轮次（向下预加载）
   └─ 滚动到 80% 位置时触发加载更多

4. 内存管理
   ├─ 最多保留 20 个轮次的 Block 在内存中
   └─ 滚动超出范围时释放旧数据
```

### 2.6 UI 层按轮次分页加载

```dart
class _ConversationScreenState extends State<ConversationScreen> {
  final _repository = MessageRepository();

  /// 按轮次组织的数据结构（与当前 UI 一致）
  List<RoundData> _rounds = [];
  Map<String, List<MessageBlockEntity>> _blockMap = {};

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentRoundPage = 0;
  int _totalRounds = 0;
  static const _roundsPerPage = 5;  // 每次加载 5 个轮次
  static const _preloadThreshold = 2;  // 预加载阈值

  @override
  void initState() {
    super.initState();
    _loadInitialRounds();
  }

  Future<void> _loadInitialRounds() async {
    setState(() => _isLoading = true);

    // 1. 获取轮次总数
    _totalRounds = await _repository.getRoundCount(widget.topicId);

    // 2. 加载首批轮次的消息
    final messages = await _repository.loadRounds(
      widget.topicId,
      startRound: 0,
      roundCount: _roundsPerPage,
    );

    // 3. 批量加载 Block（避免 N+1）
    final blockMap = await _repository.batchLoadBlocks(
      messages.map((m) => m.messageId).toList(),
    );

    // 4. 批量预加载标注
    await HighlightService().batchPreload(
      messages.map((m) => m.messageId).toList(),
    );

    // 5. 按轮次分组
    final rounds = _groupMessagesByRound(messages);

    setState(() {
      _rounds = rounds;
      _blockMap = blockMap;
      _isLoading = false;
      _hasMore = _currentRoundPage * _roundsPerPage < _totalRounds;
      _currentRoundPage = 1;
    });
  }

  Future<void> _loadMoreRounds() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    final startRound = _currentRoundPage * _roundsPerPage;
    final newMessages = await _repository.loadRounds(
      widget.topicId,
      startRound: startRound,
      roundCount: _roundsPerPage,
    );

    final newBlocks = await _repository.batchLoadBlocks(
      newMessages.map((m) => m.messageId).toList(),
    );

    await HighlightService().batchPreload(
      newMessages.map((m) => m.messageId).toList(),
    );

    final newRounds = _groupMessagesByRound(newMessages);

    setState(() {
      _rounds.addAll(newRounds);
      _blockMap.addAll(newBlocks);
      _isLoading = false;
      _currentRoundPage++;
      _hasMore = _currentRoundPage * _roundsPerPage < _totalRounds;
    });
  }

  /// 将消息按轮次分组（与当前 _getConversationGroups 逻辑一致）
  List<RoundData> _groupMessagesByRound(List<MessageEntity> messages) {
    final grouped = <int, RoundData>{};

    for (final msg in messages) {
      grouped.putIfAbsent(msg.roundIndex, () => RoundData(roundIndex: msg.roundIndex));

      if (msg.role == 'user') {
        grouped[msg.roundIndex]!.userMessage = msg;
      } else {
        grouped[msg.roundIndex]!.assistantReplies.add(msg);
      }
    }

    return grouped.values.toList()..sort((a, b) => a.roundIndex.compareTo(b.roundIndex));
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            _loadMoreRounds();
          }
        }
        return false;
      },
      child: ScrollablePositionedList.builder(
        itemCount: _rounds.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _rounds.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final round = _rounds[index];
          return RoundCard(
            round: round,
            blockMap: _blockMap,
          );
        },
      ),
    );
  }
}

/// 轮次数据结构
class RoundData {
  final int roundIndex;
  MessageEntity? userMessage;
  List<MessageEntity> assistantReplies = [];

  RoundData({required this.roundIndex});
}
```

### 2.7 内存管理详细设计

```dart
/// Block 内存缓存管理器（按轮次）
class BlockCacheManager {
  static const int maxRoundsInMemory = 20;
  final _cache = LinkedHashMap<String, List<MessageBlockEntity>>();

  void put(String roundKey, List<MessageBlockEntity> blocks) {
    while (_cache.length >= maxRoundsInMemory) {
      _cache.remove(_cache.keys.first); // 移除最老
    }
    _cache[roundKey] = blocks;
  }

  List<MessageBlockEntity>? get(String roundKey) {
    final blocks = _cache.remove(roundKey);
    if (blocks != null) {
      _cache[roundKey] = blocks; // 触发 LRU
    }
    return blocks;
  }
}
```

滚动策略：
- 滚动速度 > 2000px/s 时暂停预加载，避免抢占渲染。
- 滚动停止后 100ms 启动预加载当前位置 ±2 轮次。
- 保持内存只存最近 20 轮，超出范围的 Blocks 释放。

---

## 三、数据导入重构

### 3.1 Block 数据来源与迁移路径

**关键问题**：Cherry Studio 导出格式中，`message_blocks` 是独立存储的：

```json
{
  "indexedDB": {
    "topics": [...],           // 话题列表（messages 只有 block IDs）
    "message_blocks": [...],   // 所有消息块（实际内容在这里）
    "files": [...],
    "assistants": [...]
  }
}
```

**当前问题**：`dataJson` 存储的是原始 topic，只包含 block IDs，不包含 block 内容。Block 内容只存在于 `CherryExtractor.blockMap` 中，未持久化。

**迁移路径选择**：

| 路径 | 方式 | 优点 | 缺点 |
|------|------|------|------|
| **路径 A（推荐）** | 提示用户重新导入 | 代码简单，数据完整 | 用户需要重新导入 |
| 路径 B | 先发版本扩展缓存 | 可自动迁移 | 需要两次发版，复杂 |

**推荐路径 A**：由于这是只读查看器，用户重新导入数据是可接受的。迁移时检测旧数据，提示用户重新导入即可。

### 3.2 新的导入服务

```dart
class DataImportService {
  final IsarDatabase _db;
  final CherryExtractor _extractor;

  /// 断点续传：记录已导入的话题索引
  static const String _importProgressKey = 'import_progress';

  DataImportService(this._db, this._extractor);

  /// 从 Cherry Studio 导出文件导入数据
  ///
  /// 特性：
  /// - 分批事务（每 50 个话题一个事务），避免长事务锁定
  /// - 支持断点续传（记录进度，失败后可继续）
  /// - Block 数据从 CherryExtractor.blockMap 获取
  Future<void> importFromFile(
    String filePath, {
    void Function(double progress, String message)? onProgress,
  }) async {
    // 1. 解析文件（CherryExtractor 会构建 blockMap）
    onProgress?.call(0.05, '正在解析文件...');
    await _extractor.load();

    // 2. 导入 Assistants
    onProgress?.call(0.08, '正在导入助手信息...');
    await _importAssistants();

    // 3. 获取所有话题
    final groupedTopics = _extractor.getTopicsByAssistant();
    final allTopics = <Map<String, dynamic>>[];

    for (final entry in groupedTopics.entries) {
      final topics = entry.value['topics'] as List<dynamic>? ?? [];
      for (final topic in topics) {
        allTopics.add({
          'assistantId': entry.key,
          'topic': topic,
        });
      }
    }

    // 4. 检查断点续传
    final prefs = await SharedPreferences.getInstance();
    int startIndex = prefs.getInt(_importProgressKey) ?? 0;

    if (startIndex == 0) {
      // 首次导入：清除旧数据
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.topicEntitys.clear();
        await isar.messageEntitys.clear();
        await isar.messageBlockEntitys.clear();
      });
    }

    onProgress?.call(0.1, '开始导入 ${allTopics.length} 个话题...');

    // 5. 分批导入（每批 50 个话题）
    const batchSize = 50;
    final isar = await _db.instance;

    for (var i = startIndex; i < allTopics.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, allTopics.length);
      final batch = allTopics.sublist(i, end);

      // 每批一个事务
      await isar.writeTxn(() async {
        for (final item in batch) {
          await _importTopic(
            isar,
            item['assistantId'] as String,
            item['topic'] as Map<String, dynamic>,
          );
        }
      });

      // 保存进度（断点续传）
      await prefs.setInt(_importProgressKey, end);

      onProgress?.call(
        0.1 + 0.9 * end / allTopics.length,
        '已导入 $end/${allTopics.length} 个话题...',
      );
    }

    // 6. 更新 Assistant 的 topicCount
    await _updateAssistantTopicCounts();

    // 7. 清除进度记录
    await prefs.remove(_importProgressKey);
    onProgress?.call(1.0, '导入完成');
  }

  /// 导入 Assistants
  Future<void> _importAssistants() async {
    final isar = await _db.instance;
    final assistants = _extractor.getAssistants();

    await isar.writeTxn(() async {
      await isar.assistantEntitys.clear();

      for (final asst in assistants) {
        if (asst is! Map<String, dynamic>) continue;

        final entity = AssistantEntity()
          ..assistantId = asst['id'] as String? ?? ''
          ..name = asst['name'] as String? ?? '未命名助手'
          ..description = asst['description'] as String?
          ..avatar = asst['avatar'] as String?
          ..prompt = asst['prompt'] as String?
          ..topicCount = 0  // 后面更新
          ..createdAt = DateTime.now().millisecondsSinceEpoch
          ..updatedAt = DateTime.now().millisecondsSinceEpoch;

        await isar.assistantEntitys.put(entity);
      }
    });
  }

  /// 更新 Assistant 的 topicCount
  Future<void> _updateAssistantTopicCounts() async {
    final isar = await _db.instance;
    final assistants = await isar.assistantEntitys.where().findAll();

    await isar.writeTxn(() async {
      for (final asst in assistants) {
        final count = await isar.topicEntitys
            .filter()
            .assistantIdEqualTo(asst.assistantId)
            .count();
        asst.topicCount = count;
        await isar.assistantEntitys.put(asst);
      }
    });
  }

  Future<void> _importTopic(
    Isar isar,
    String assistantId,
    Map<String, dynamic> topicData,
  ) async {
    final topicId = topicData['id'] as String;
    final messages = topicData['messages'] as List<dynamic>? ?? [];
    final missingBlocks = <String>[];  // 导入后生成报告

    // 计算统计信息 + 构建轮次映射（按 askId 分组）
    int roundCount = 0;
    int currentRound = -1;
    String? currentAskId;
    final roundMap = <int, int>{};  // messageIndex -> roundIndex

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i] as Map<String, dynamic>;
      final askId = msg['askId'] as String?;
      final role = msg['role'] as String?;

      if (askId != null && askId != currentAskId) {
        currentRound++;
        roundCount++;
        currentAskId = askId;
      } else if (role == 'user' && askId == null) {
        // 没有 askId 的用户消息也开启新轮次
        currentRound++;
        roundCount++;
      }

      roundMap[i] = currentRound >= 0 ? currentRound : 0;
    }

    // 保存 Topic
    final topicEntity = TopicEntity()
      ..topicId = topicId
      ..name = topicData['name'] as String? ?? '未命名话题'
      ..assistantId = assistantId
      ..messageCount = messages.length
      ..roundCount = roundCount
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;

    await isar.topicEntitys.put(topicEntity);

    // 保存 Messages 和 Blocks
    for (var i = 0; i < messages.length; i++) {
      final msgData = messages[i] as Map<String, dynamic>;
      await _importMessage(
        isar,
        topicId,
        msgData,
        orderIndex: i,           // 简单顺序索引
        roundIndex: roundMap[i]!, // 轮次索引
        missingBlocks: missingBlocks,
      );
    }

    if (missingBlocks.isNotEmpty) {
      print('⚠️ 导入完成但有 ${missingBlocks.length} 个 Block 缺失');
    }
  }

  Future<void> _importMessage(
    Isar isar,
    String topicId,
    Map<String, dynamic> msgData, {
    required int orderIndex,
    required int roundIndex,
    required List<String> missingBlocks,
  }) async {
    final messageId = msgData['id'] as String;
    final blockIds = (msgData['blocks'] as List<dynamic>?)?.cast<String>() ?? [];

    // 保存 Message
    final messageEntity = MessageEntity()
      ..messageId = messageId
      ..topicId = topicId
      ..orderIndex = orderIndex
      ..roundIndex = roundIndex
      ..role = msgData['role'] as String? ?? 'user'
      ..askId = msgData['askId'] as String?
      ..useful = msgData['useful'] as bool? ?? true
      ..modelId = (msgData['model'] as Map<String, dynamic>?)?['id'] as String?
      ..modelName = (msgData['model'] as Map<String, dynamic>?)?['name'] as String?
      ..usageJson = msgData['usage'] != null ? jsonEncode(msgData['usage']) : null
      ..metricsJson = msgData['metrics'] != null ? jsonEncode(msgData['metrics']) : null
      ..mentionsJson = msgData['mentions'] != null ? jsonEncode(msgData['mentions']) : null
      ..createdAt = _parseTimestamp(msgData['createdAt'])
      ..status = msgData['status'] as String? ?? 'completed';

    await isar.messageEntitys.put(messageEntity);

    // 保存 Blocks（从 CherryExtractor.blockMap 获取实际内容）
    for (var j = 0; j < blockIds.length; j++) {
      final blockId = blockIds[j];
      // ⚠️ 关键：通过 blockMap 获取 block 内容
      final blockData = _extractor.blockMap[blockId];

      if (blockData != null && blockData is Map<String, dynamic>) {
        final blockEntity = MessageBlockEntity()
          ..blockId = blockId
          ..messageId = messageId
          ..orderIndex = j
          ..type = blockData['type'] as String? ?? 'main_text'
          ..content = blockData['content'] as String?
          ..thinkingMillsec = (blockData['thinking_millsec'] as num?)?.toDouble()
          ..url = blockData['url'] as String?
          ..fileJson = blockData['file'] != null ? jsonEncode(blockData['file']) : null
          ..toolJson = blockData['tool'] != null ? jsonEncode(blockData['tool']) : null
          ..errorJson = blockData['error'] != null ? jsonEncode(blockData['error']) : null
          ..createdAt = _parseTimestamp(blockData['createdAt']);

        await isar.messageBlockEntitys.put(blockEntity);
      } else {
        // Block 数据丢失时创建占位符并记录
        missingBlocks.add('$blockId (message: $messageId)');
        final placeholder = MessageBlockEntity()
          ..blockId = blockId
          ..messageId = messageId
          ..orderIndex = j
          ..type = 'error'
          ..content = '[Block 数据丢失]'
          ..createdAt = DateTime.now().millisecondsSinceEpoch;
        await isar.messageBlockEntitys.put(placeholder);
      }
    }
  }

  int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ??
             DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}
```

### 3.3 增量导入策略

用户可能需要：
- 重新导入更新后的 ZIP 文件
- 导入不同的 ZIP 文件

```dart
enum ImportMode {
  replace,  // 替换：清空后导入
  merge,    // 合并：按 topicId 去重
}

class DataImportService {
  // ... 上面的代码 ...

  /// 检测导入模式
  Future<ImportMode?> detectImportMode(String filePath) async {
    final isar = await _db.instance;
    final existingCount = await isar.topicEntitys.count();

    if (existingCount == 0) {
      return ImportMode.replace;  // 首次导入，直接替换
    }

    // 有旧数据，需要用户选择
    return null;  // 返回 null 表示需要询问用户
  }

  /// 带模式的导入
  Future<void> importWithMode(
    String filePath,
    ImportMode mode, {
    void Function(double progress, String message)? onProgress,
  }) async {
    if (mode == ImportMode.replace) {
      // 替换模式：清空所有数据后导入
      final isar = await _db.instance;
      await isar.writeTxn(() async {
        await isar.assistantEntitys.clear();
        await isar.topicEntitys.clear();
        await isar.messageEntitys.clear();
        await isar.messageBlockEntitys.clear();
      });
    }

    await importFromFile(filePath, onProgress: onProgress);
  }
}
```

**Merge 语义补充**：
- 以 `topicId` 为主键：如果新导入中存在同名 topic，采用“先删后写”或基于 `updatedAt/version` 的覆盖策略，避免旧数据混入。
- `messageId`/`blockId` 冲突时必须重写或删除旧记录，保持唯一索引一致；不允许直接跳过写入（否则会出现半旧半新）。
- 导入完成后生成报告，列出覆盖/新增/跳过的数量，方便用户核对。

### 3.4 并发控制与崩溃恢复

**导入期间的读写隔离**：
1. 导入开始时设置全局标志 `_isImporting = true`，UI 显示「正在导入，部分数据可能不完整」。
2. 读取可用独立 Isar 实例（多读单写），但 UI 层应避免展示未完成导入的数据。
3. 导入完成后广播刷新事件，UI 自动重载列表。

**崩溃恢复/断点续传**：
- 每批事务成功后持久化进度（SharedPreferences），记录已完成的话题数/offset。
- 启动时检测未完成导入，可选择继续或清空重来。
- 合并模式下记录已覆盖的 topicId 列表，避免重复覆盖。

### 3.5 导入日志与监控

```dart
class ImportLogger {
  final List<ImportLogEntry> _entries = [];
  void info(String msg) => _entries.add(ImportLogEntry.info(msg));
  void warn(String msg) => _entries.add(ImportLogEntry.warn(msg));
  void error(String msg, [Object? err]) =>
      _entries.add(ImportLogEntry.error(msg, err));

  String report() {
    final buf = StringBuffer('=== 导入报告 ===\n');
    buf.writeln('警告数: ${_entries.where((e) => e.level == "warn").length}');
    buf.writeln('错误数: ${_entries.where((e) => e.level == "error").length}');
    return buf.toString();
  }
}
```

导入结束后输出报告，UI 可展示“覆盖/新增/缺失 Block 数”等摘要。

---

## 四、迁移计划

### 4.1 阶段概览

```
阶段 1: 新建表结构 + 抽象层
    ├─ 创建 Repository 抽象接口（IMessageRepository 等）
    ├─ 创建数据模型（MessageModel, BlockModel 等）
    ├─ 创建新实体文件
    ├─ 创建 Repository 实现
    ├─ 创建导入服务
    └─ 单元测试

阶段 2: 并行运行
    ├─ 新数据同时写入新旧两套表
    ├─ ConversationScreen 通过抽象接口读取
    ├─ 添加 Feature Flag 切换
    └─ 集成测试

阶段 3: 数据迁移
    ├─ 检测旧数据，提示用户重新导入
    ├─ 显示迁移/导入进度
    └─ 保留旧数据作为回滚选项

阶段 4: 稳定后清理
    ├─ 确认新架构稳定（至少一个版本周期）
    ├─ 删除 TopicCacheEntity.dataJson
    ├─ 删除旧的加载逻辑
    └─ 更新文档
```

### 4.2 阶段 1：新建表结构 + 抽象层

**目标**：创建 Repository 抽象层和 Isar 实现，提升代码可测试性和可维护性。

**任务列表**：

**抽象层（与数据库无关）**：
- [ ] 创建 `lib/models/message_model.dart`（数据模型）
- [ ] 创建 `lib/models/block_model.dart`（数据模型）
- [ ] 创建 `lib/models/topic_model.dart`（数据模型）
- [ ] 创建 `lib/models/assistant_model.dart`（数据模型）
- [ ] 创建 `lib/repositories/i_message_repository.dart`（抽象接口）
- [ ] 创建 `lib/repositories/i_topic_repository.dart`（抽象接口）
- [ ] 创建 `lib/repositories/i_assistant_repository.dart`（抽象接口）

**Isar 实现层**：
- [ ] 创建 `lib/models/isar/assistant_entity.dart`
- [ ] 创建 `lib/models/isar/topic_entity.dart`
- [ ] 创建 `lib/models/isar/message_entity.dart`
- [ ] 创建 `lib/models/isar/message_block_entity.dart`
- [ ] 创建 `lib/models/isar/file_entity.dart` 并在导入时复制/索引附件
- [ ] 运行 `dart run build_runner build` 生成代码
- [ ] 创建 `lib/repositories/isar/isar_message_repository.dart`
- [ ] 创建 `lib/repositories/isar/isar_topic_repository.dart`
- [ ] 创建 `lib/repositories/isar/isar_assistant_repository.dart`
- [ ] 更新 `IsarDatabase.init()` 添加新 Schema

**服务层**：
- [ ] 创建 `lib/services/data_import_service.dart`
- [ ] 创建 `lib/services/repository_provider.dart`（依赖注入）

**测试**：
- [ ] 编写 Repository 抽象接口的单元测试
- [ ] 编写 Isar 实现的集成测试

**文件变更**：

```
lib/models/
├── message_model.dart        # 新增：数据模型（与数据库无关）
├── block_model.dart          # 新增
├── topic_model.dart          # 新增
├── assistant_model.dart      # 新增
└── isar/
    ├── assistant_entity.dart     # 新增：Isar 实体
    ├── assistant_entity.g.dart   # 生成
    ├── topic_entity.dart         # 新增
    ├── topic_entity.g.dart       # 生成
    ├── message_entity.dart       # 新增
    ├── message_entity.g.dart     # 生成
    ├── message_block_entity.dart # 新增
    ├── message_block_entity.g.dart # 生成
    └── file_entity.dart          # 新增

lib/repositories/
├── i_message_repository.dart     # 新增：抽象接口
├── i_topic_repository.dart       # 新增
├── i_assistant_repository.dart   # 新增
└── isar/
    ├── isar_message_repository.dart  # 新增：Isar 实现
    ├── isar_topic_repository.dart    # 新增
    └── isar_assistant_repository.dart # 新增

lib/services/
├── data_import_service.dart  # 新增
├── repository_provider.dart  # 新增：依赖注入
├── isar_database.dart        # 修改：添加新 Schema
└── ...

test/
├── repositories/
│   ├── message_repository_test.dart  # 新增
│   └── ...
└── services/
    └── data_import_service_test.dart # 新增
```

**依赖注入设计**：

```dart
/// lib/services/repository_provider.dart
class RepositoryProvider {
  static RepositoryProvider? _instance;

  late final IMessageRepository messageRepository;
  late final ITopicRepository topicRepository;
  late final IAssistantRepository assistantRepository;

  RepositoryProvider._();

  static Future<RepositoryProvider> init() async {
    if (_instance != null) return _instance!;

    _instance = RepositoryProvider._();

    final db = IsarDatabase();
    await db.init();
    _instance!.messageRepository = IsarMessageRepository(db);
    _instance!.topicRepository = IsarTopicRepository(db);
    _instance!.assistantRepository = IsarAssistantRepository(db);

    return _instance!;
  }

  static RepositoryProvider get instance {
    if (_instance == null) {
      throw StateError('RepositoryProvider not initialized');
    }
    return _instance!;
  }
}
```

### 4.3 阶段 2：并行运行

**目标**：新旧两套存储并行运行，可以通过 Feature Flag 切换。

**任务列表**：

- [ ] 修改 `DataPersistenceManager.saveTopicIndexCache()` 同时写入新表
- [ ] 创建 `lib/services/topic_service.dart` 封装读取逻辑
- [ ] 添加 Feature Flag：`use_new_storage`
- [ ] 修改 `ConversationScreen` 支持从新表读取
- [ ] 修改 `HomeScreen` 支持从新表读取话题列表
- [ ] 为 EPUB/TTS/AI 分析等模块提供兼容层（批量拉取消息+Block 聚合）
- [ ] 集成测试：对比新旧两套存储的数据一致性

**Feature Flag 实现**：

```dart
class FeatureFlags {
  static const String _keyUseNewStorage = 'feature_use_new_storage';

  static Future<bool> get useNewStorage async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseNewStorage) ?? false;
  }

  static Future<void> setUseNewStorage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseNewStorage, value);
  }
}
```

### 4.4 阶段 3：数据迁移

**目标**：检测旧数据，提示用户重新导入。

**迁移策略**：由于旧的 `dataJson` 不包含 block 内容，无法直接迁移。采用**提示重新导入**策略：

```dart
class DataMigrationService {
  final IsarDatabase _db;

  static const String _migrationStatusKey = 'migration_status';

  DataMigrationService(this._db);

  /// 迁移状态
  enum MigrationStatus { notStarted, needsReimport, completed }

  Future<MigrationStatus> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_migrationStatusKey);
    return MigrationStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => MigrationStatus.notStarted,
    );
  }

  /// 检查是否需要迁移
  Future<bool> needsMigration() async {
    final isar = await _db.instance;

    // 检查是否有旧数据
    final oldCount = await isar.topicCacheEntitys.count();
    if (oldCount == 0) return false;

    // 检查是否有新数据
    final newCount = await isar.topicEntitys.count();
    if (newCount > 0) return false;  // 已有新数据，不需要迁移

    return true;
  }

  /// 标记需要重新导入
  Future<void> markNeedsReimport() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_migrationStatusKey, MigrationStatus.needsReimport.name);
  }

  /// 标记迁移完成
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_migrationStatusKey, MigrationStatus.completed.name);
  }

  /// 清理旧数据（迁移完成后调用）
  Future<void> cleanupOldData() async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.topicCacheEntitys.clear();
    });
    print('✅ 已清理旧数据');
  }

  /// 回滚到旧架构（删除新表数据）
  Future<void> rollback() async {
    final isar = await _db.instance;
    final prefs = await SharedPreferences.getInstance();

    await isar.writeTxn(() async {
      await isar.assistantEntitys.clear();
      await isar.topicEntitys.clear();
      await isar.messageEntitys.clear();
      await isar.messageBlockEntitys.clear();
    });

    await prefs.setString(_migrationStatusKey, MigrationStatus.notStarted.name);
    print('✅ 已回滚到旧架构');
  }
}
```

**启动时检测**：

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = IsarDatabase();
  await db.init();

  // 检查是否需要迁移
  final migrationService = DataMigrationService(db);
  if (await migrationService.needsMigration()) {
    await migrationService.markNeedsReimport();
    runApp(ReimportPromptApp());  // 显示重新导入提示
  } else {
    runApp(const MyApp());
  }
}
```

**用户生成数据兼容性**：
- 旧版的高亮（HighlightEntity）、AI 分析（AIAnalysisEntity）、统一对话（UnifiedConversationEntity/Message）均依赖 `topicId`/`messageId`。重新导入后需保证 ID 稳定，否则会导致用户数据失联。
- 若无法保证稳定 ID，需要在重新导入前提醒用户导出高亮/分析；或提供映射方案（根据旧 topicId -> 新 topicId 重写引用）。
- 迁移后再清理旧表时，应确认这些用户数据已成功关联到新表或明确提示会被清空。

### 4.5 阶段 4：清理

**目标**：删除旧的存储逻辑和数据。

**任务列表**：

- [ ] 从 `IsarDatabase.init()` 移除 `TopicCacheEntitySchema`
- [ ] 删除 `TopicCacheEntity` 文件
- [ ] 删除 `DataPersistenceManager` 中的旧方法
- [ ] 更新所有调用点使用新的 Repository
- [ ] 删除 Feature Flag
- [ ] 更新文档

### 4.6 现有功能兼容层

现有功能依赖 `dataJson` 整体结构，需提供聚合接口：

| 功能 | 位置 | 兼容方案 |
|------|------|----------|
| EPUB 导出 | `lib/services/epub_export_service.dart` | 通过 TopicExportService 拉全量消息+Blocks 组装为旧格式 |
| TTS 朗读 | `lib/providers/tts_provider.dart` | 按消息流式读取 `MessageBlockEntity.content`，按需预加载下一条 |
| AI 分析 | `lib/services/analysis_cache_manager.dart` | 使用 MessageRepository 聚合消息，保持 groupIndex 分组 |
| 批量导出/复制 | （若有） | 复用 TopicExportService 的组装结果 |

示例适配：
```dart
class TopicExportService {
  final MessageRepository _repo;

  Future<Map<String, dynamic>> getFullTopicData(String topicId) async {
    final messages = await _repo.loadAllMessages(topicId);
    final blockMap = await _repo.batchLoadBlocks(
      messages.map((m) => m.messageId).toList(),
    );

    return {
      'id': topicId,
      'messages': messages.map((m) {
        final blocks = blockMap[m.messageId] ?? [];
        return _assembleMessage(m, blocks);
      }).toList(),
    };
  }
}
```

### 4.7 数据库 Schema 版本管理

在 `IsarDatabase.init()` 中维护 Schema 版本：

```dart
class IsarDatabase {
  static const int schemaVersion = 2; // v1: 旧架构, v2: 新架构

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('db_schema_version') ?? 1;

    if (stored < schemaVersion) {
      await _migrate(stored, schemaVersion); // 执行迁移/清理
      await prefs.setInt('db_schema_version', schemaVersion);
    }
  }
}
```

迁移逻辑应与 `DataMigrationService` 对齐，确保版本变更时提示重新导入或执行清理。

---

## 五、预期效果

### 5.1 性能目标

| 指标                    | 当前（估算） | 目标         | 预期提升 |
| ----------------------- | ------------ | ------------ | -------- |
| 打开话题（100 条消息）  | ~2 秒        | <200ms       | **10x**  |
| 打开话题（1000 条消息） | ~5 秒        | <200ms（首屏）| **25x** |
| 内存占用（大话题）      | ~50MB        | ~5MB         | **90%↓** |
| 滚动加载更多            | 不支持       | 支持         | ✅       |

### 5.2 性能验证计划

**加载性能测试**：

| 场景 | 数据规模 | 验收标准 |
|------|----------|----------|
| 小话题 | 10 轮对话 | 首屏 <100ms |
| 中话题 | 50 轮对话 | 首屏 <150ms |
| 大话题 | 200 轮对话 | 首屏 <200ms |
| 超大话题 | 500 轮对话 | 首屏 <300ms，滚动流畅 |

**导入性能测试**：

| 数据规模 | 当前导入时间 | 新架构目标 |
|---------|------------|-----------|
| 100 话题 | ~5s | <8s |
| 500 话题 | ~15s | <25s |
| 1000 话题 | ~30s | <50s |

**测试设备**：
- 低端：iPhone SE 2 / Pixel 4a
- 高端：iPhone 14 Pro / Pixel 7

**测试方法**：
```dart
// 使用 Stopwatch 测量首屏加载时间
final stopwatch = Stopwatch()..start();

await _loadInitialRounds();

stopwatch.stop();
print('首屏加载耗时: ${stopwatch.elapsedMilliseconds}ms');

// 使用 Flutter DevTools 监控内存占用
```

**验收标准**：
- 低端设备首屏加载 < 300ms
- 滚动时无明显卡顿（FPS > 50）
- 内存峰值 < 100MB

### 5.3 测试矩阵

| 测试类型 | 覆盖范围 | 优先级 |
|---------|---------|-------|
| 单元测试 | MessageRepository.loadMessages（正常/空/边界） | P0 |
| 单元测试 | DataImportService.importFromFile（正常/中断/异常数据） | P0 |
| 单元测试 | DataIntegrityChecker.check（一致性校验） | P0 |
| 集成测试 | 完整导入流程（ZIP/JSON 各种大小） | P0 |
| 集成测试 | 分页加载 + 滚动（首屏/加载更多/快速滚动） | P0 |
| 集成测试 | 新旧存储对比（数据一致性） | P0 |
| 回归测试 | EPUB 导出（内容完整性） | P1 |
| 回归测试 | TTS 朗读（播放流畅性） | P1 |
| 回归测试 | 标注功能（保存/加载/迁移） | P1 |
| 回归测试 | AI 分析（缓存命中/未命中） | P1 |
| 平台测试 | Android 低端机（Pixel 4a，50 话题） | P1 |
| 平台测试 | iOS（iPhone SE 2，100 话题） | P1 |
| 平台测试 | macOS（M1 Mac，500 话题） | P2 |

**测试数据准备**：
- 小：10 话题，每话题 5 轮
- 中：100 话题，每话题 20 轮
- 大：500 话题，每话题 50 轮
- 压力：1000 话题，每话题 100 轮

### 5.4 数据一致性校验

迁移/导入完成后执行一致性检查：

```dart
class DataIntegrityChecker {
  final IsarDatabase _db;
  final CherryExtractor _extractor;

  DataIntegrityChecker(this._db, this._extractor);

  /// 执行完整性校验
  Future<IntegrityReport> check() async {
    final isar = await _db.instance;
    final report = IntegrityReport();

    // 1. 数量校验
    final topicCount = await isar.topicEntitys.count();
    final expectedTopics = _extractor.topics.length;
    report.topicCountMatch = topicCount == expectedTopics;
    report.topicCount = topicCount;
    report.expectedTopicCount = expectedTopics;

    // 2. 消息数量校验
    final messageCount = await isar.messageEntitys.count();
    int expectedMessages = 0;
    for (final topic in _extractor.topics) {
      if (topic is Map<String, dynamic>) {
        expectedMessages += (topic['messages'] as List?)?.length ?? 0;
      }
    }
    report.messageCountMatch = messageCount == expectedMessages;
    report.messageCount = messageCount;
    report.expectedMessageCount = expectedMessages;

    // 3. Block 数量校验
    final blockCount = await isar.messageBlockEntitys.count();
    report.blockCount = blockCount;
    report.expectedBlockCount = _extractor.blockMap.length;
    report.blockCountMatch = blockCount <= report.expectedBlockCount;  // 可能有孤立 block

    // 4. 抽样校验（随机选 5 个话题）
    final topics = await isar.topicEntitys.where().limit(5).findAll();
    for (final topic in topics) {
      final messages = await isar.messageEntitys
          .filter()
          .topicIdEqualTo(topic.topicId)
          .findAll();
      report.sampledTopics.add(SampledTopic(
        topicId: topic.topicId,
        messageCount: messages.length,
        expectedMessageCount: topic.messageCount,
        match: messages.length == topic.messageCount,
      ));
    }

    return report;
  }
}

class IntegrityReport {
  bool topicCountMatch = false;
  int topicCount = 0;
  int expectedTopicCount = 0;

  bool messageCountMatch = false;
  int messageCount = 0;
  int expectedMessageCount = 0;

  bool blockCountMatch = false;
  int blockCount = 0;
  int expectedBlockCount = 0;

  List<SampledTopic> sampledTopics = [];

  bool get isValid => topicCountMatch && messageCountMatch;
}

class SampledTopic {
  final String topicId;
  final int messageCount;
  final int expectedMessageCount;
  final bool match;

  SampledTopic({
    required this.topicId,
    required this.messageCount,
    required this.expectedMessageCount,
    required this.match,
  });
}
```

### 5.4 用户体验改善

- **秒开话题**：无论话题有多少消息，首屏都能在 200ms 内显示
- **流畅滚动**：滚动到底部时自动加载更多，无卡顿
- **低内存占用**：只加载可见区域的消息，适合低端设备
- **数据自包含**：不再依赖原始 ZIP 文件

### 5.5 技术债务清理

- **消除 dataJson Blob**：不再存储完整的 JSON 字符串
- **消除数据不完整**：Block 内容完整持久化
- **统一数据模型**：消息的存储格式与 `UnifiedMessageEntity` 对齐

---

## 六、风险与应对

### 6.1 向后兼容

**风险**：旧版本用户升级后，旧数据无法读取。

**应对**：

- 检测旧数据存在时，提示用户重新导入
- 提供「重新导入」按钮，引导用户操作
- 保留旧数据直到用户确认新数据正常

### 6.2 回滚方案

**风险**：新架构上线后发现严重问题，需要回退。

**应对策略**：

```
阶段 3 完成后的数据状态：
├─ 旧表 (TopicCacheEntity) ← 保留，不删除
├─ 新表 (TopicEntity, MessageEntity, MessageBlockEntity) ← 新数据
└─ Feature Flag: use_new_storage ← 控制读取来源
```

**回滚步骤**：
1. 将 `use_new_storage` 设为 `false`
2. 调用 `DataMigrationService.rollback()` 清空新表
3. 用户无感知地回退到旧架构（但需要重新导入）

**阶段 4 清理前提条件**：
- 新架构稳定运行至少一个版本周期
- 无用户反馈严重问题
- 性能验证通过

### 6.3 导入性能

**风险**：分解写入可能比一次性写入慢。

**应对**：

- 使用事务批量写入（每批 50 个话题），批间让出事件循环
- 将解析+写入放入 Isolate/compute，避免 UI 卡顿；桌面端也应异步写
- 显示导入进度/剩余时间，支持取消
- 导入完成后压缩/compact 前先 close 再 open，避免长事务锁

### 6.4 Isar 不支持 JOIN

**风险**：需要查询三个表关联数据。

**应对**：

- 使用批量查询替代循环查询（`batchLoadBlocks`）
- 在内存中关联数据（按 messageId 分组）
- 使用复合索引优化查询性能

### 6.5 Block 数据来源

**风险**：旧的 `dataJson` 不包含 block 内容，无法直接迁移。

**应对**：

- 采用「提示重新导入」策略
- 检测旧数据时，显示友好的提示信息
- 提供清晰的操作指引

### 6.6 用户生成数据（高亮/AI 分析/统一对话）丢失

**风险**：重新导入或切换新表后，旧数据的 `topicId`/`messageId` 变化导致用户标注、AI 分析、统一对话消息失联或被清空。

**应对**：

- 保证导入后的 `topicId`/`messageId` 与旧版一致；如生成策略有变，提供映射表并批量重写引用。
- 在迁移 UI 中明确提示「标注/分析数据可能丢失」，提供导出备份或跳过迁移的选项。
- 清理旧表前，验证用户数据已成功关联（抽样检查/完整性校验）。

### 6.7 实体命名一致性

**风险**：新增 `TopicEntity`/`MessageEntity` 与旧的 `TopicCacheEntity` 命名接近，易混淆。

**应对**：
- 在阶段 4 清理后再保留简化命名；并行阶段可以临时命名为 `ImportedTopicEntity`/`ImportedMessageEntity` 或在文档/代码注释中明确“Imported”语义。
- 对外暴露的 Repository/Service 层使用“Imported”命名，避免调用方误用旧实体。

---

## 七、未来扩展

### 7.1 两套消息系统的统一

当前项目存在两套消息系统：

| 系统 | 实体 | 用途 | 特点 |
|------|------|------|------|
| 导入数据 | `MessageEntity` + `MessageBlockEntity` | Cherry Studio 历史消息 | 只读、分块存储 |
| AI 对话 | `UnifiedMessageEntity` | 用户自己的对话 | 可编辑、流式更新、多模型回复 |

**`UnifiedMessageEntity` 的关键特性**：
- `askId`：关联用户问题，支持同一问题的多个 AI 回复
- `isMainline`：主线回复选择（类似 Cherry Studio 的 `useful` 字段）
- `regenerateAssistantMessage()`：重试/重新生成
- 按 `createdAt` 排序（无 `orderIndex`）

**统一方案（未来）**：

```dart
// 方案 A：扩展 MessageEntity 支持可编辑场景
@collection
class MessageEntity {
  // ... 现有字段 ...

  // 新增：标记数据来源
  @Index()
  late String sourceType;  // 'imported' | 'ai_chat'

  // 新增：支持流式更新
  String? status;  // pending | streaming | completed | error

  // 改为稀疏索引，支持插入
  late int orderIndex;  // 1000, 2000, 3000...
}

// 方案 B：保持独立，通过接口层统一
abstract class IMessage {
  String get messageId;
  String get role;
  String get content;
  int get createdAt;
}

class MessageEntity implements IMessage { ... }
class UnifiedMessageEntity implements IMessage { ... }
```

**建议**：
- 短期：保持两套系统独立，各司其职
- 中期：在 Repository 层统一查询接口
- 长期：根据实际需求决定是否合并实体

### 7.2 全文搜索

新架构便于添加全文搜索功能：

```dart
// 添加全文搜索索引
@collection
class MessageBlockEntity {
  // ...

  @Index(type: IndexType.value)
  String? content;  // 可以被搜索
}

// 搜索接口
Future<List<MessageBlockEntity>> search(String keyword) async {
  return isar.messageBlockEntitys
      .filter()
      .contentContains(keyword, caseSensitive: false)
      .findAll();
}
```

---

## 八、相关文件

### 需要修改的文件

| 文件                                         | 修改内容                    |
| -------------------------------------------- | --------------------------- |
| `lib/services/isar_database.dart`            | 添加新 Schema，新增查询方法 |
| `lib/services/data_persistence_manager.dart` | 添加新表写入逻辑            |
| `lib/screens/conversation_screen.dart`       | 改用分页加载                |
| `lib/screens/home_screen.dart`               | 改用新的话题列表查询        |
| `lib/services/data_import_service.dart`      | 导入时复制并索引附件        |
| `pubspec.yaml`                               | 确保 Isar 版本兼容          |

### 需要新增的文件

| 文件                                        | 用途         |
| ------------------------------------------- | ------------ |
| `lib/models/isar/assistant_entity.dart`     | 新助手实体   |
| `lib/models/isar/topic_entity.dart`         | 新话题实体   |
| `lib/models/isar/message_entity.dart`       | 新消息实体   |
| `lib/models/isar/message_block_entity.dart` | 新消息块实体 |
| `lib/models/isar/file_entity.dart`          | 附件索引实体 |
| `lib/services/message_repository.dart`      | 消息查询服务 |
| `lib/services/data_import_service.dart`     | 数据导入服务 |
| `lib/services/data_migration_service.dart`  | 数据迁移服务 |
| `lib/services/data_integrity_checker.dart`  | 数据完整性校验 |

### 需要删除的文件（阶段 4）

| 文件                                        | 原因         |
| ------------------------------------------- | ------------ |
| `lib/models/isar/topic_cache_entity.dart`   | 被新实体替代 |
| `lib/models/isar/topic_cache_entity.g.dart` | 生成文件     |

---

## 九、参考资料

- [Isar 官方文档](https://isar.dev/)
- [Flutter 官方 SQL 架构指南](https://docs.flutter.dev/app-architecture/design-patterns/sql)
- [Flutter 分页最佳实践](https://codewithandrea.com/articles/flutter-riverpod-pagination/)

---

## 十、修订历史

| 版本 | 日期    | 作者   | 变更内容 |
| ---- | ------- | ------ | -------- |
| 1.0  | 2024-12 | Claude | 初始版本 |
| 1.1  | 2024-12 | Claude | Review 修订：添加 Block 数据来源说明、按轮次分页、分批事务、回滚方案、性能验证计划、实体关系说明 |
| 1.2  | 2024-12 | Claude | 全面修订：修复 Block 数据迁移缺陷、添加 AssistantEntity、补充首屏加载策略、添加数据一致性校验、添加增量导入策略、添加导入性能指标、添加 Repository 错误处理、添加两套消息系统统一方案、完善 orderIndex 索引策略说明 |
| 1.3  | 2025-12 | Claude | 架构优化：添加 Repository 抽象层设计、完善依赖注入设计 |
| 1.4  | 2025-12 | Claude | 文档精简：移除数据库迁移相关内容，聚焦消息级存储架构 |
