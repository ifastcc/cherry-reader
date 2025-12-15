import 'package:isar_community/isar.dart';

part 'prompt_template_entity.g.dart';

/// 模板适用类型
///
/// 区分模板是用于多模型对比还是单回复分析
enum TemplateTargetType {
  /// 多模型对比（如元分析、视角）
  multiModel,

  /// 单回复分析
  singleReply,

  /// 通用（如总结、翻译）
  any,
}

/// 用户偏好实体（System Prompt）
///
/// 存储用户的全局偏好设置，作为所有对话的 System Prompt
/// 例如：语言偏好、思考方式、回复风格等
@collection
class UserPreferenceEntity {
  Id id = Isar.autoIncrement;

  /// 偏好唯一 ID（UUID）
  @Index(unique: true)
  late String preferenceId;

  /// 偏好名称（如"默认偏好"、"简洁模式"等）
  late String name;

  /// System Prompt 内容
  late String systemPrompt;

  /// 是否为当前激活的偏好
  @Index()
  late bool isActive;

  /// 默认模板 ID（用于新对话自动选择模板）
  String? defaultTemplateId;

  /// 创建时间戳（毫秒）
  late int createdAt;

  /// 更新时间戳（毫秒）
  late int updatedAt;

  /// 创建实体
  static UserPreferenceEntity create({
    required String preferenceId,
    required String name,
    required String systemPrompt,
    bool isActive = false,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return UserPreferenceEntity()
      ..preferenceId = preferenceId
      ..name = name
      ..systemPrompt = systemPrompt
      ..isActive = isActive
      ..createdAt = now
      ..updatedAt = now;
  }

  /// 默认偏好
  static UserPreferenceEntity createDefault(String preferenceId) {
    return create(
      preferenceId: preferenceId,
      name: '默认偏好',
      systemPrompt: '''- 总是使用简体中文回答问题
- 从第一性原理出发进行思考，找到问题的本质和关键因素
- 回复要简洁，避免冗余的客套话''',
      isActive: true,
    );
  }
}

/// 任务模版实体
///
/// 存储可复用的任务模版（本质上是预设的用户问题模式）
/// 例如：元分析模版、翻译模版、总结模版等
@collection
class TaskTemplateEntity {
  Id id = Isar.autoIncrement;

  /// 模版唯一 ID（UUID）
  @Index(unique: true)
  late String templateId;

  /// 模版名称
  late String name;

  /// 模版描述（可选）
  String? description;

  /// 模版内容（Markdown 格式）
  late String content;

  /// 是否为系统预设模版（不可删除）
  late bool isBuiltIn;

  /// 使用次数（用于排序）
  late int usageCount;

  /// 模板适用类型（多模型对比/单回复/通用）
  @Enumerated(EnumType.ordinal)
  late TemplateTargetType targetType;

  /// 创建时间戳（毫秒）
  late int createdAt;

  /// 更新时间戳（毫秒）
  @Index()
  late int updatedAt;

  /// 创建实体
  static TaskTemplateEntity create({
    required String templateId,
    required String name,
    required String content,
    String? description,
    bool isBuiltIn = false,
    TemplateTargetType targetType = TemplateTargetType.any,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TaskTemplateEntity()
      ..templateId = templateId
      ..name = name
      ..description = description
      ..content = content
      ..isBuiltIn = isBuiltIn
      ..usageCount = 0
      ..targetType = targetType
      ..createdAt = now
      ..updatedAt = now;
  }

  /// 内置的视角模版（多模型对比）
  static TaskTemplateEntity createPerspective(String templateId) {
    return create(
      templateId: templateId,
      name: '视角',
      description: '梳理每轮对话的脉络和核心亮点，提炼有价值的视角和透镜',
      content: '''这里有好多轮对话，而且每一轮对话可能有多个模型的回复，因为这个对话太长了，信息量太多了，所以我希望你能够用直观而不失本质理解的语言去梳理和讲解每一轮对话，我的关注的点，每一轮对话的每个回复的核心/亮点/本质/局限等等？

然后也要讲清楚每一轮对话的脉络发展，最后尝试抓住我想要精准提问的点是什么？

最重要的是提炼出一些你认为有意思，可能对与我的问题有帮助的视角/透镜？
''',
      isBuiltIn: true,
      targetType: TemplateTargetType.multiModel,
    );
  }

  /// 内置的元分析模版（多模型对比）
  static TaskTemplateEntity createMetaAnalysis(String templateId) {
    return create(
      templateId: templateId,
      name: '元分析',
      description: '对比多个模型回复，逆向工程思维路径，提炼底层规律',
      content: '''请对以下多个模型的回复进行元分析（Meta-Analysis）。不需要简单的"内容摘要"，而是通过对比，逆向工程出每个模型背后的思维路径，达到降维和建模的效果。语言精炼简洁，直观而不失本质。

## 第一部分：信噪比蒸馏

对每个模型回复，去除修饰性文本，仅保留绝对干货。

**格式**：`[模型名] 核心论点`（用最精炼的语言总结其独特价值主张，犀利、直观）

## 第二部分：思维拓扑学分析

跳出具体文字，在更高维度审视回复差异：

1. **光谱分布**：这些回复在什么光谱上分布？（如：理论↔实践、解构↔建构、抽象↔具体）
2. **盲区检测**：它们共同忽略了什么？存在什么固有局限？
3. **认知升维**：综合这些回复，能抽象出什么通用模型或底层规律来彻底解释用户问题？
''',
      isBuiltIn: true,
      targetType: TemplateTargetType.multiModel,
    );
  }

  /// 内置的总结模版
  static TaskTemplateEntity createSummary(String templateId) {
    return create(
      templateId: templateId,
      name: '内容总结',
      description: '对内容进行简洁的总结提炼',
      content: '''请对以下内容进行总结：

1. **核心观点**：提取最重要的 3-5 个观点
2. **关键信息**：列出必须记住的关键事实或数据
3. **行动建议**：如果有的话，提取可执行的建议

要求：简洁、准确、不遗漏重要信息

---

**原始内容：**
''',
      isBuiltIn: true,
    );
  }

  /// 内置的翻译模版
  static TaskTemplateEntity createTranslation(String templateId) {
    return create(
      templateId: templateId,
      name: '翻译',
      description: '将内容翻译成目标语言',
      content: '''请将以下内容翻译成简体中文：

要求：
1. 保持原文的语气和风格
2. 专业术语需准确翻译
3. 如有文化差异，适当本地化

---

**原文：**
''',
      isBuiltIn: true,
    );
  }
}
