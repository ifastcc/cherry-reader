import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../services/cherry_extractor.dart';
import '../services/analysis_cache_manager.dart';
import '../services/openai_service.dart';
import '../services/highlight_service.dart';
import '../services/data_persistence_manager.dart';
import '../widgets/horizontal_scroll_view.dart';
import '../widgets/streaming_analysis_card.dart';
import '../widgets/highlightable_card.dart';
import '../widgets/user_message_card.dart';
import '../services/epub_export_service.dart';
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
  // _cacheData 已移除，Isar 自动管理持久化
  Map<int, List<String>> _aiAnalyses = {};

  // 流式生成状态
  bool _isGenerating = false;
  int? _generatingGroupIndex;
  String _currentStreamContent = '';

  // 卡片显示配置
  late int _columnsPerView;

  // 【性能优化】缓存对话分组结果
  List<Map<String, dynamic>>? _cachedGroups;

  final _epubExportService = EpubExportService();

  // API 配置
  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';
  String _model = 'gpt-4-turbo-preview';

  @override
  void initState() {
    super.initState();

    _cacheManager = AnalysisCacheManager();
    _initApiConfig();
    _loadData();
  }

  /// 初始化 API 配置（从 SharedPreferences 读取）
  Future<void> _initApiConfig() async {
    final config = await getApiConfig();
    final columnsPerView = await getColumnsPerView();
    setState(() {
      _apiKey = config['apiKey'] ?? '';
      _baseUrl = config['apiUrl'] ?? 'https://api.openai.com/v1';
      _model = config['model'] ?? 'gpt-4-turbo-preview';
      _openaiService = OpenAIService(apiKey: _apiKey, baseUrl: _baseUrl);
      _columnsPerView = columnsPerView;
    });
  }

  Future<void> _loadData() async {
    final startTime = DateTime.now();

    // 【优化】优先从 Isar 加载话题数据（按需加载）
    var conv = await DataPersistenceManager.loadTopicData(widget.topicId);

    // 如果缓存中没有数据，使用 extractor（fallback）
    if (conv == null) {
      conv = widget.extractor.extractTopicConversation(widget.topicId);
    }

    // 【优化】从 Isar 加载分析缓存
    final analyses = await _cacheManager.getTopicAnalyses(widget.topicId);

    // 【性能优化】批量预加载所有消息的标注
    if (conv != null) {
      final messages = conv['messages'] as List<dynamic>? ?? [];
      final messageIds = messages
          .where((m) => m is Map<String, dynamic>)
          .map((m) => m['id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      if (messageIds.isNotEmpty) {
        final highlightService = HighlightService();
        await highlightService.batchPreload(messageIds);
      }
    }

    setState(() {
      _conversation = conv;
      _aiAnalyses = analyses;
      _cachedGroups = null; // 清除缓存，触发重新计算
    });
  }

  /// 获取对话分组（按 askId 和 useful 字段分组）
  ///
  /// 【性能优化】使用缓存避免重复计算
  List<Map<String, dynamic>> _getConversationGroups() {
    // 检查缓存
    if (_cachedGroups != null) {
      return _cachedGroups!;
    }

    if (_conversation == null) {
      return [];
    }

    final messages = _conversation!['messages'] as List<dynamic>;

    final groups = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentGroup;

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
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

    // 缓存结果
    _cachedGroups = groups;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('该问题没有助手回复')));
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

      // 【优化】保存到 Isar（自动持久化）
      await _cacheManager.saveAnalysis(
        widget.topicId,
        groupIndex,
        _currentStreamContent,
      );

      final updatedAnalyses = await _cacheManager.getTopicAnalyses(
        widget.topicId,
      );

      setState(() {
        _aiAnalyses = updatedAnalyses;
        _isGenerating = false;
        _generatingGroupIndex = null;
        _currentStreamContent = '';
        _cachedGroups = null; // AI 分析可能改变显示，清除缓存
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ 分析已保存')));
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generatingGroupIndex = null;
        _currentStreamContent = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportToEpub(int groupIndex) async {
    final groups = _getConversationGroups();
    if (groupIndex >= groups.length) return;

    final group = groups[groupIndex];
    final userMsg = group['user_message'] as Map<String, dynamic>;
    final assistantReplies = group['assistant_replies'] as List<dynamic>;
    final analyses = _aiAnalyses[groupIndex] ?? [];

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成电子书...')),
      );

      await _epubExportService.exportGroup(
        topicName: widget.topicName,
        userMessage: userMsg,
        assistantReplies: assistantReplies,
        aiAnalyses: analyses,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ EPUB 3.0 导出成功 (v2)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('电子书导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 导出完整对话（所有轮次）
  Future<void> _exportFullConversation() async {
    final groups = _getConversationGroups();

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有对话内容可以导出')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正在生成完整对话电子书 (${groups.length} 轮)...')),
      );

      await _epubExportService.exportFullConversation(
        topicName: widget.topicName,
        groups: groups,
        allAnalyses: _aiAnalyses,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 完整对话导出成功 (${groups.length} 轮)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('完整对话导出失败: $e'),
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
          // 导出完整对话按钮
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出完整对话',
            onPressed: _conversation == null ? null : _exportFullConversation,
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
      // 【性能优化】减小缓存范围，提升滚动性能
      cacheExtent: 300, // 只预渲染必要的内容
      addAutomaticKeepAlives: true, // 保持已构建的组件
      itemBuilder: (context, index) {
        // 【性能优化】使用 RepaintBoundary 隔离重绘
        return RepaintBoundary(
          key: ValueKey('group_$index'),
          child: _buildConversationGroup(groups[index], index),
        );
      },
    );
  }

  Widget _buildConversationGroup(Map<String, dynamic> group, int groupIndex) {
    final userMsg = group['user_message'] as Map<String, dynamic>;
    final assistantReplies = group['assistant_replies'] as List<dynamic>;

    // 计算总卡片数（流式卡片 + AI分析 + 助手回复）
    final hasStreamingCard =
        _isGenerating && _generatingGroupIndex == groupIndex;
    final aiAnalysisCount = _aiAnalyses[groupIndex]?.length ?? 0;
    final totalCards =
        (hasStreamingCard ? 1 : 0) + aiAnalysisCount + assistantReplies.length;

    // 判断是否为单卡片模式（只有一个助手回复，无AI分析，无流式生成）
    final isSingleCard =
        totalCards == 1 && !hasStreamingCard && aiAnalysisCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 用户消息
        UserMessageCard(key: ValueKey(userMsg['id']), data: userMsg),

        const SizedBox(height: 12),

        // 整合的回复区域（工具栏 + 卡片）
        if (assistantReplies.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]?.withOpacity(0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 顶部工具栏
                _buildIntegratedToolbar(groupIndex),
                // 分隔线
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                ),
                // 卡片区域
                isSingleCard
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          height: 580,
                          child: HighlightableCard.assistant(
                            key: ValueKey(
                              (assistantReplies.first
                                  as Map<String, dynamic>)['id'],
                            ),
                            data:
                                assistantReplies.first as Map<String, dynamic>,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          bottom: 12,
                          top: 8,
                        ),
                        child: HorizontalScrollView(
                          columnsPerView: _columnsPerView,
                          cards: [
                            if (hasStreamingCard)
                              StreamingAnalysisCard(
                                content: _currentStreamContent,
                                analysisIndex: aiAnalysisCount + 1,
                              ),
                            ...(_aiAnalyses[groupIndex] ?? [])
                                .asMap()
                                .entries
                                .map((entry) {
                              return HighlightableCard.aiAnalysis(
                                key: ValueKey('ai_${groupIndex}_${entry.key}'),
                                content: entry.value,
                              );
                            }),
                            ...assistantReplies.map((reply) {
                              final replyMap = reply as Map<String, dynamic>;
                              return HighlightableCard.assistant(
                                key: ValueKey(replyMap['id']),
                                data: replyMap,
                              );
                            }),
                          ],
                        ),
                      ),
              ],
            ),
          ),
      ],
    );
  }

  /// 构建整合式工具栏（作为卡片区域的标题栏）
  Widget _buildIntegratedToolbar(int groupIndex) {
    const primaryColor = Color(0xFF8B5CF6); // AI Purple
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isCurrentGenerating =
        _isGenerating && _generatingGroupIndex == groupIndex;
    final analysisCount = _aiAnalyses[groupIndex]?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 左侧：本轮对话标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '本轮对话',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // 分析计数徽章
          if (analysisCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$analysisCount 条分析',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],

          const Spacer(),

          // 右侧：操作按钮
          _buildCompactButton(
            onPressed:
                _isGenerating ? null : () => _showAnalysisDialog(groupIndex),
            icon: isCurrentGenerating
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : Icon(Icons.auto_awesome_rounded, size: 15, color: primaryColor),
            label: isCurrentGenerating ? '分析中' : 'AI 分析',
            backgroundColor: primaryColor.withOpacity(0.1),
            textColor: primaryColor,
          ),
          const SizedBox(width: 8),
          _buildCompactButton(
            onPressed: () => _exportToEpub(groupIndex),
            icon: Icon(
              Icons.menu_book_rounded,
              size: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            label: '导出',
            backgroundColor: isDark
                ? Colors.grey[800]!.withOpacity(0.5)
                : Colors.grey[100]!,
            textColor: isDark ? Colors.grey[300]! : Colors.grey[700]!,
          ),
        ],
      ),
    );
  }

  /// 构建紧凑型按钮
  Widget _buildCompactButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onPressed == null
                      ? textColor.withOpacity(0.5)
                      : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
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
