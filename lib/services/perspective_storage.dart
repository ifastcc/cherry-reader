import '../models/isar/perspective_entity.dart';

/// 内置视角定义
///
/// 包含所有预定义的分析视角及其 Prompt 模板
class BuiltinPerspectives {
  // ============ 分类常量 ============

  static const String categorySelf = 'self_awareness';
  static const String categorySolve = 'problem_solving';
  static const String categoryAction = 'action_oriented';
  static const String categoryGrow = 'growth_mindset';

  /// 分类名称映射
  static const Map<String, String> categoryNames = {
    categorySelf: '自我认识',
    categorySolve: '问题解决',
    categoryAction: '行动导向',
    categoryGrow: '成长思维',
  };

  /// 分类图标映射
  static const Map<String, String> categoryIcons = {
    categorySelf: '🪞',
    categorySolve: '🔧',
    categoryAction: '🎯',
    categoryGrow: '🌱',
  };

  // ============ 内置视角 ============

  /// 获取所有内置视角
  static List<PerspectiveEntity> getAll() {
    return [
      _createThinkingMode(),
      _createValueClarity(),
      _createFriendPerspective(),
      _createSeneca(),
      _createEnergyAudit(),
      _createNextAction(),
      _createEvolution(),
    ];
  }

  /// 🧠 思维模式
  static PerspectiveEntity _createThinkingMode() {
    return PerspectiveEntity.create(
      perspectiveId: 'builtin_thinking_mode',
      name: '思维模式',
      icon: '🧠',
      description: '分析思维模式和认知偏差',
      category: categorySelf,
      isBuiltin: true,
      isEnabled: true,
      sortOrder: 10,
      promptTemplate: '''你是一位认知心理学专家。请分析以下用户提问，识别其中的思维模式。

用户提问列表：
{queries}

请从以下角度分析：

## 一、思维模式识别
识别用户在这些提问中展现的主要思维模式，例如：
- 分析型思维 vs 直觉型思维
- 线性思维 vs 系统思维
- 确定性寻求 vs 不确定性接受

## 二、认知偏差检测
指出可能存在的认知偏差，如：
- 确认偏误
- 可得性启发
- 锚定效应
- 沉没成本谬误

## 三、思维盲区
指出用户可能忽视的视角或问题维度。

## 四、优化建议
给出具体的思维方式优化建议。

用第二人称"你"来表述，语气温和但有洞察力。''',
    );
  }

  /// 💎 价值澄清
  static PerspectiveEntity _createValueClarity() {
    return PerspectiveEntity.create(
      perspectiveId: 'builtin_value_clarity',
      name: '价值澄清',
      icon: '💎',
      description: '识别核心价值观和优先级',
      category: categorySelf,
      isBuiltin: true,
      isEnabled: true,
      sortOrder: 20,
      promptTemplate: '''你是一位价值观教练。请分析以下用户提问，帮助识别其核心价值观。

用户提问列表：
{queries}

请从以下角度分析：

## 一、价值观识别
从这些提问中识别用户最关注的价值维度：
- 成长与学习
- 关系与连接
- 成就与认可
- 自由与独立
- 安全与稳定
- 意义与贡献

## 二、价值冲突
指出可能存在的价值观冲突或张力。

## 三、优先级洞察
基于提问频率和深度，推断用户的价值优先级。

## 四、价值对齐建议
给出让行动与价值观更一致的具体建议。

用第二人称"你"来表述，温暖而有洞察力。''',
    );
  }

  /// 👥 朋友视角
  static PerspectiveEntity _createFriendPerspective() {
    return PerspectiveEntity.create(
      perspectiveId: 'builtin_friend_perspective',
      name: '朋友视角',
      icon: '👥',
      description: '像朋友一样给出真诚建议',
      category: categorySolve,
      isBuiltin: true,
      isEnabled: true,
      sortOrder: 30,
      promptTemplate: '''你是用户的一位智慧、真诚的老朋友。请以朋友的视角回应以下提问。

用户提问列表：
{queries}

作为朋友，请：

## 一、真诚回应
像老朋友一样，真诚地说出你看到的情况，包括：
- 你观察到的模式
- 你感受到的情绪
- 你欣赏的地方

## 二、坦诚反馈
作为朋友，给出可能不太中听但重要的反馈。

## 三、支持与鼓励
提供情感支持，同时给出实际的鼓励。

## 四、建议
如果你是这位朋友，你会给出什么建议？

用"我"和"你"来表述，像真实的朋友对话一样自然。''',
    );
  }

  /// 🏛 塞涅卡
  static PerspectiveEntity _createSeneca() {
    return PerspectiveEntity.create(
      perspectiveId: 'builtin_seneca',
      name: '塞涅卡',
      icon: '🏛',
      description: '斯多葛哲学视角的智慧',
      category: categoryGrow,
      isBuiltin: true,
      isEnabled: true,
      sortOrder: 40,
      promptTemplate: '''你是古罗马斯多葛哲学家塞涅卡。请以你的智慧回应以下问题。

用户提问列表：
{queries}

请以塞涅卡的视角分析：

## 一、关于控制的边界
区分这些问题中，哪些在用户的控制范围内，哪些不在。

## 二、关于时间
这些问题如何与时间的有限性相关？什么是真正重要的？

## 三、关于逆境
如何将这些挑战转化为成长的机会？

## 四、实践智慧
给出具体的斯多葛式建议：
- 每日反思
- 负面想象
- 专注当下

用塞涅卡的口吻，引用适当的斯多葛格言。''',
    );
  }

  /// ⚡ 能量审计
  static PerspectiveEntity _createEnergyAudit() {
    return PerspectiveEntity.create(
      perspectiveId: 'builtin_energy_audit',
      name: '能量审计',
      icon: '⚡',
      description: '分析精力消耗和能量管理',
      category: categoryAction,
      isBuiltin: true,
      isEnabled: true,
      sortOrder: 50,
      promptTemplate: '''你是一位能量管理专家。请分析以下提问中反映的能量消耗模式。

用户提问列表：
{queries}

请从能量角度分析：

## 一、能量消耗识别
这些提问涉及的事项中：
- 哪些是能量消耗者？
- 哪些是能量给予者？
- 哪些是能量中性的？

## 二、能量泄漏点
识别可能导致能量持续流失的模式：
- 过度思考
- 决策疲劳
- 情绪内耗
- 无效忙碌

## 三、能量投资回报
评估这些问题的能量投入产出比。

## 四、能量优化建议
给出具体的能量管理策略：
- 何时做什么
- 如何恢复
- 什么值得投入

用第二人称"你"来表述，务实而有指导性。''',
    );
  }

  /// ✅ 下一步行动
  static PerspectiveEntity _createNextAction() {
    return PerspectiveEntity.create(
      perspectiveId: 'builtin_next_action',
      name: '下一步行动',
      icon: '✅',
      description: '提取可执行的下一步行动',
      category: categoryAction,
      isBuiltin: true,
      isEnabled: true,
      sortOrder: 60,
      promptTemplate: '''你是一位 GTD（Getting Things Done）专家。请从以下提问中提取可执行的行动。

用户提问列表：
{queries}

请提取行动项：

## 一、即时行动（2分钟内可完成）
列出可以立即执行的小任务。

## 二、项目行动（需要多步骤）
识别需要分解的较大项目，并给出第一步。

## 三、等待行动
需要等待他人或外部条件的事项。

## 四、日程行动
需要安排到特定时间的事项。

## 五、参考/思考
不需要行动，但值得记录的想法或信息。

## 六、优先级建议
如果只能做三件事，应该是哪三件？为什么？

格式要求：每个行动项应该是具体的、可执行的动词短语。''',
    );
  }

  /// 📈 关注演变
  static PerspectiveEntity _createEvolution() {
    return PerspectiveEntity.create(
      perspectiveId: 'builtin_evolution',
      name: '关注演变',
      icon: '📈',
      description: '追踪思维和关注点的变化',
      category: categoryGrow,
      isBuiltin: true,
      isEnabled: true,
      sortOrder: 70,
      promptTemplate: '''你是一位个人成长分析师。请分析以下提问中反映的关注点演变。

用户提问列表：
{queries}

请分析演变趋势：

## 一、主题演变
这些提问的主题如何随时间变化？
- 从什么转向什么？
- 有什么持续关注的主题？
- 有什么新出现的主题？

## 二、深度演变
思考的深度如何变化？
- 从表面到深入？
- 从具体到抽象？
- 从问题到解决方案？

## 三、情绪基调演变
情绪基调有什么变化？
- 焦虑 vs 平静
- 困惑 vs 清晰
- 被动 vs 主动

## 四、成长信号
识别积极的成长信号和可能的停滞点。

## 五、发展建议
基于演变趋势，建议下一阶段的关注方向。

用第二人称"你"来表述，观察性强且有启发性。''',
    );
  }
}
