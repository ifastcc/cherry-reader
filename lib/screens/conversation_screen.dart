import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../services/cherry_extractor.dart';
import '../services/analysis_cache_manager.dart';
import '../services/openai_service.dart';
import '../widgets/horizontal_scroll_view.dart';
import '../widgets/streaming_analysis_card.dart';
import '../widgets/highlightable_card.dart';
import '../widgets/user_message_card.dart';
import 'settings_screen.dart';

class ConversationScreen extends StatefulWidget {
  final CherryExtractor extractor;
  final String topicId;
  final String topicName;

  const ConversationScreen({
    Key? key,
    required this.extractor,
    required this.topicId,
    required this.topicName,
  }) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final AnalysisCacheManager _cacheManager;
  OpenAIService? _openaiService;

  Map<String, dynamic>? _conversation;
  Map<String, dynamic> _cacheData = {};
  Map<int, List<String>> _aiAnalyses = {};

  // 流式生成状态
  bool _isGenerating = false;
  int? _generatingGroupIndex;
  String _currentStreamContent = '';

  // 卡片显示配置
  late int _columnsPerView;

  // API 配置
  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';
  String _model = 'gpt-4-turbo-preview';

  @override
  void initState() {
    super.initState();

    // 根据平台设置默认列数
    _columnsPerView = _getDefaultColumnsPerView();

    _cacheManager = AnalysisCacheManager();
    _initApiConfig();
    _loadData();
  }

  /// 初始化 API 配置（从 SharedPreferences 读取）
  Future<void> _initApiConfig() async {
    final config = await getApiConfig();
    setState(() {
      _apiKey = config['apiKey'] ?? '';
      _baseUrl = config['apiUrl'] ?? 'https://api.openai.com/v1';
      _model = config['model'] ?? 'gpt-4-turbo-preview';
      _openaiService = OpenAIService(
        apiKey: _apiKey,
        baseUrl: _baseUrl,
      );
    });
  }

  /// 根据平台返回默认列数
  int _getDefaultColumnsPerView() {
    // 移动端（iOS/Android）默认 1 列
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          return 1;
        }
      } catch (e) {
        // 如果平台检测失败，继续检查其他条件
      }
    }

    // 桌面端（macOS/Windows/Linux/Web）默认 2 列
    return 2;
  }

  Future<void> _loadData() async {
    // 加载对话数据
    final conv = widget.extractor.extractTopicConversation(widget.topicId);

    // 加载缓存
    final cacheData = await _cacheManager.loadCache();
    final analyses = _cacheManager.getTopicAnalyses(cacheData, widget.topicId);

    setState(() {
      _conversation = conv;
      _cacheData = cacheData;
      _aiAnalyses = analyses;
    });
  }

  /// 获取对话分组（按 askId 和 useful 字段分组）
  List<Map<String, dynamic>> _getConversationGroups() {
    if (_conversation == null) return [];

    final messages = _conversation!['messages'] as List<dynamic>;
    final groups = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentGroup;

    for (final msg in messages) {
      if (msg is! Map<String, dynamic>) continue;

      final role = msg['role'] as String?;

      if (role == 'user') {
        // 新的用户消息 -> 新分组
        if (currentGroup != null) {
          groups.add(currentGroup);
        }
        currentGroup = {
          'user_message': msg,
          'assistant_replies': <Map<String, dynamic>>[],
        };
      } else if (role == 'assistant' && currentGroup != null) {
        // 助手回复 -> 添加到当前分组
        (currentGroup['assistant_replies'] as List).add(msg);
      }
    }

    if (currentGroup != null) {
      groups.add(currentGroup);
    }

    return groups;
  }

  /// 生成 AI 分析
  Future<void> _generateAnalysis(int groupIndex) async {
    // 检查 API 配置
    if (_openaiService == null || _apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先在设置中配置 API Key'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final groups = _getConversationGroups();
    if (groupIndex >= groups.length) return;

    final group = groups[groupIndex];
    final userMsg = group['user_message'] as Map<String, dynamic>;
    final assistantReplies = group['assistant_replies'] as List<dynamic>;

    if (assistantReplies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该问题没有助手回复')),
      );
      return;
    }

    // 构建 prompt
    final prompt = _buildAnalysisPrompt(userMsg, assistantReplies);

    setState(() {
      _isGenerating = true;
      _generatingGroupIndex = groupIndex;
      _currentStreamContent = '';
    });

    try {
      // 流式生成
      final stream = _openaiService!.streamChatCompletion(
        model: _model,
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      );

      await for (final chunk in stream) {
        setState(() {
          _currentStreamContent += chunk;
        });
      }

      // 保存到缓存
      final updatedCache = await _cacheManager.saveAnalysis(
        _cacheData,
        widget.topicId,
        groupIndex,
        _currentStreamContent,
      );

      final updatedAnalyses = _cacheManager.getTopicAnalyses(
        updatedCache,
        widget.topicId,
      );

      setState(() {
        _cacheData = updatedCache;
        _aiAnalyses = updatedAnalyses;
        _isGenerating = false;
        _generatingGroupIndex = null;
        _currentStreamContent = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 分析已保存')),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generatingGroupIndex = null;
        _currentStreamContent = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 构建 AI 分析 prompt（使用元分析模板）
  String _buildAnalysisPrompt(
    Map<String, dynamic> userMsg,
    List<dynamic> assistantReplies,
  ) {
    // 提取用户问题
    final userBlocks = userMsg['blocks'] as List<dynamic>? ?? [];
    var userQuery = '';
    for (final block in userBlocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        userQuery += block['content'] as String? ?? '';
      }
    }

    // 提取各模型回复
    var modelResponses = '';
    for (var i = 0; i < assistantReplies.length; i++) {
      final reply = assistantReplies[i] as Map<String, dynamic>;
      final model = reply['model'] as Map<String, dynamic>?;
      final modelName = model?['name'] as String? ?? 'Unknown';

      final blocks = reply['blocks'] as List<dynamic>? ?? [];
      var content = '';
      for (final block in blocks) {
        if (block is Map<String, dynamic> && block['type'] == 'main_text') {
          content += block['content'] as String? ?? '';
        }
      }

      modelResponses += '\n\n### 模型 ${i + 1}: $modelName\n$content';
    }

    // 元分析模板
    return '''请对以下多个模型的回复进行元分析（Meta-Analysis）。不需要简单的"内容摘要"，而是通过对比，逆向工程出每个模型背后的思维路径，达到降维和建模的效果。语言精炼简洁，直观而不失本质。

## 第一部分：信噪比蒸馏

对每个模型回复，去除修饰性文本，仅保留绝对干货。

**格式**：`[模型名] 核心论点`（用最精炼的语言总结其独特价值主张，犀利、直观）

## 第二部分：思维拓扑学分析

跳出具体文字，在更高维度审视回复差异：

1. **光谱分布**：这些回复在什么光谱上分布？（如：理论↔实践、解构↔建构、抽象↔具体）
2. **盲区检测**：它们共同忽略了什么？存在什么固有局限？
3. **认知升维**：综合这些回复，能抽象出什么通用模型或底层规律来彻底解释用户问题？

---

**用户问题：**

$userQuery

**模型回复对比（${assistantReplies.length} 个）：**

$modelResponses''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName),
        actions: [
          // 卡片列数选择器
          PopupMenuButton<int>(
            icon: const Icon(Icons.view_column),
            tooltip: '设置每屏显示卡片数',
            initialValue: _columnsPerView,
            onSelected: (value) {
              setState(() {
                _columnsPerView = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('1 列 (全屏)')),
              const PopupMenuItem(value: 2, child: Text('2 列 (默认)')),
              const PopupMenuItem(value: 3, child: Text('3 列 (紧凑)')),
              const PopupMenuItem(value: 4, child: Text('4 列 (超紧凑)')),
            ],
          ),
        ],
      ),
      body: _conversation == null
          ? const Center(child: CircularProgressIndicator())
          : _buildConversation(),
    );
  }

  Widget _buildConversation() {
    final groups = _getConversationGroups();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return _buildConversationGroup(groups[index], index);
      },
    );
  }

  Widget _buildConversationGroup(Map<String, dynamic> group, int groupIndex) {
    final userMsg = group['user_message'] as Map<String, dynamic>;
    final assistantReplies = group['assistant_replies'] as List<dynamic>;

    // 计算总卡片数（流式卡片 + AI分析 + 助手回复）
    final hasStreamingCard = _isGenerating && _generatingGroupIndex == groupIndex;
    final aiAnalysisCount = _aiAnalyses[groupIndex]?.length ?? 0;
    final totalCards = (hasStreamingCard ? 1 : 0) + aiAnalysisCount + assistantReplies.length;

    // 判断是否为单卡片模式（只有一个助手回复，无AI分析，无流式生成）
    final isSingleCard = totalCards == 1 && !hasStreamingCard && aiAnalysisCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 用户消息
        UserMessageCard(data: userMsg),

        const SizedBox(height: 16),

        // 助手回复（横向滚动）+ AI 分析
        if (assistantReplies.isNotEmpty)
          isSingleCard
              ? // 单个助手回复：居中占满宽度
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 600,
                  child: Column(
                    children: [
                      Expanded(
                        child: HighlightableCard.assistant(
                          data: assistantReplies.first as Map<String, dynamic>,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 生成分析按钮
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        tooltip: '生成 AI 分析',
                        onPressed: _isGenerating
                            ? null
                            : () => _showAnalysisDialog(groupIndex),
                      ),
                    ],
                  ),
                ),
              )
              : // 多卡片：使用横向滚动视图
              HorizontalScrollView(
                columnsPerView: _columnsPerView,
                cards: [
                  // 正在生成的流式卡片（最前面）
                  if (hasStreamingCard)
                    StreamingAnalysisCard(
                      content: _currentStreamContent,
                      analysisIndex: aiAnalysisCount + 1,
                    ),

                  // 已保存的 AI 分析卡片（也在助手回复之前）
                  ...(_aiAnalyses[groupIndex] ?? []).map((analysis) {
                    return HighlightableCard.aiAnalysis(content: analysis);
                  }),

                  // 助手回复卡片（放在最后）
                  ...assistantReplies.map((reply) {
                    return HighlightableCard.assistant(
                      data: reply as Map<String, dynamic>,
                    );
                  }),
                ],
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                  tooltip: '生成 AI 分析',
                  onPressed: _isGenerating
                      ? null
                      : () => _showAnalysisDialog(groupIndex),
                ),
              ),
      ],
    );
  }

  /// 显示生成分析对话框
  void _showAnalysisDialog(int groupIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成 AI 分析'),
        content: const Text('使用元分析模板对多个模型的回复进行对比分析？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAnalysis(groupIndex);
            },
            child: const Text('生成'),
          ),
        ],
      ),
    );
  }
}
