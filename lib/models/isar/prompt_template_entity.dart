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
      description: '梳理对话脉络，提炼有价值的视角和透镜',
      content: '''请梳理这段对话，用直观而不失本质的语言讲解：

1. **每轮对话的核心**：各个回复的亮点、本质、局限
2. **脉络发展**：对话是如何演进的，我真正想问的是什么
3. **视角提炼**：提炼出可能对问题有帮助的视角或透镜
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

  /// 内置的深度分析模版（多模型对比）
  static TaskTemplateEntity createDeepAnalysis(String templateId) {
    return create(
      templateId: templateId,
      name: '深度分析',
      description: '全面分析各模型回复的优劣，给出基于第一性原理的独立见解',
      content: '''请你详细分析上述内容，并给出你的深度思考和见解。要求：

1. 仔细阅读所有模型回复，全面分析它们各自的优劣点（包括但不限于：洞察深度、逻辑严密性、知识广度、实用价值、表达清晰度等）

2. 基于第一性原理，综合所有回复，给出你自己的深度分析和洞见，不要只是总结或复述已有内容

3. 如果所有回复都存在共同的遗漏点或盲区，请明确指出

4. 采用清晰的结构化表达，但避免空洞的话语
''',
      isBuiltIn: true,
      targetType: TemplateTargetType.multiModel,
    );
  }
}
