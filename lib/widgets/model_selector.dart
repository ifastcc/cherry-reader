import 'package:flutter/material.dart';
import '../services/multi_model_service.dart';
import '../services/ai_provider_service.dart';

/// 模型选择弹窗
///
/// 在输入 @ 时显示，支持：
/// 1. 搜索过滤
/// 2. 按 Provider 分组
/// 3. 多选模式
class ModelSelectorPopup extends StatefulWidget {
  /// 初始搜索词
  final String initialQuery;

  /// 选择回调
  final Function(Map<String, dynamic> model) onSelect;

  /// 取消回调
  final VoidCallback onCancel;

  /// 位置（相对于 Overlay）
  final Offset? position;

  /// 最大高度
  final double maxHeight;

  const ModelSelectorPopup({
    super.key,
    this.initialQuery = '',
    required this.onSelect,
    required this.onCancel,
    this.position,
    this.maxHeight = 300,
  });

  @override
  State<ModelSelectorPopup> createState() => _ModelSelectorPopupState();
}

class _ModelSelectorPopupState extends State<ModelSelectorPopup> {
  final MultiModelService _multiModelService = MultiModelService.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _filteredModels = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _filterModels(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterModels(String query) {
    setState(() {
      _filteredModels = _multiModelService.searchModels(query);
      _selectedIndex = 0;
    });
  }

  void _selectModel(Map<String, dynamic> model) {
    widget.onSelect(model);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: widget.maxHeight,
          maxWidth: 320,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索模型...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: _filterModels,
              ),
            ),
            const Divider(height: 1),
            // 模型列表
            Flexible(
              child: _filteredModels.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredModels.length,
                      itemBuilder: (context, index) {
                        final model = _filteredModels[index];
                        return _buildModelItem(model, index, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            '没有找到匹配的模型',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '请先在设置中配置 AI Provider',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelItem(Map<String, dynamic> model, int index, bool isDark) {
    final isSelected = index == _selectedIndex;
    final modelName = model['modelName'] as String;
    final providerName = model['providerName'] as String;
    final modelColor = _getModelColor(modelName);

    return InkWell(
      onTap: () => _selectModel(model),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected
            ? (isDark ? Colors.grey[800] : Colors.grey[100])
            : Colors.transparent,
        child: Row(
          children: [
            // 模型图标
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: modelColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: modelColor,
              ),
            ),
            const SizedBox(width: 10),
            // 模型信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    providerName,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // 选中指示
            if (isSelected)
              Icon(
                Icons.keyboard_return,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Color _getModelColor(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (name.contains('gpt') || name.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (name.contains('gemini') || name.contains('google')) {
      return const Color(0xFF4285F4);
    } else if (name.contains('qwen') || name.contains('通义')) {
      return const Color(0xFF6366F1);
    } else if (name.contains('deepseek')) {
      return const Color(0xFF06B6D4);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }
}

/// 多模型选择器（用于一次选择多个模型）
class MultiModelSelector extends StatefulWidget {
  /// 已选中的模型
  final List<Map<String, dynamic>> selectedModels;

  /// 选择变化回调
  final Function(List<Map<String, dynamic>> models) onChanged;

  const MultiModelSelector({
    super.key,
    required this.selectedModels,
    required this.onChanged,
  });

  @override
  State<MultiModelSelector> createState() => _MultiModelSelectorState();
}

class _MultiModelSelectorState extends State<MultiModelSelector> {
  final AIProviderService _providerService = AIProviderService.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.smart_toy_outlined, size: 18),
              const SizedBox(width: 8),
              const Text(
                '选择模型',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '已选 ${widget.selectedModels.length} 个',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Provider 列表
        Expanded(
          child: ListView.builder(
            itemCount: _providerService.validProviders.length,
            itemBuilder: (context, index) {
              final provider = _providerService.validProviders[index];
              return _buildProviderSection(provider, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSection(dynamic provider, bool isDark) {
    return ExpansionTile(
      title: Text(
        provider.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${provider.models.length} 个模型',
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
      leading: Icon(
        Icons.cloud_outlined,
        color: _getProviderColor(provider.name),
      ),
      children: provider.models.map<Widget>((model) {
        final isSelected = widget.selectedModels.any(
          (m) => m['providerId'] == provider.id && m['modelId'] == model.id,
        );

        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            final modelInfo = {
              'providerId': provider.id,
              'providerName': provider.name,
              'modelId': model.id,
              'modelName': model.displayName,
            };

            final newList = List<Map<String, dynamic>>.from(widget.selectedModels);
            if (value == true) {
              newList.add(modelInfo);
            } else {
              newList.removeWhere(
                (m) => m['providerId'] == provider.id && m['modelId'] == model.id,
              );
            }
            widget.onChanged(newList);
          },
          title: Text(
            model.displayName,
            style: const TextStyle(fontSize: 13),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        );
      }).toList(),
    );
  }

  Color _getProviderColor(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (lowerName.contains('anthropic') || lowerName.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (lowerName.contains('google') || lowerName.contains('gemini')) {
      return const Color(0xFF4285F4);
    } else if (lowerName.contains('azure')) {
      return const Color(0xFF0078D4);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }
}

/// 已选模型标签展示
class SelectedModelsChips extends StatelessWidget {
  final List<Map<String, dynamic>> models;
  final Function(Map<String, dynamic> model)? onRemove;

  const SelectedModelsChips({
    super.key,
    required this.models,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: models.map((model) {
        final modelName = model['modelName'] as String;
        final modelColor = _getModelColor(modelName);

        return Chip(
          label: Text(
            modelName,
            style: TextStyle(fontSize: 11, color: modelColor),
          ),
          backgroundColor: modelColor.withValues(alpha: 0.1),
          side: BorderSide(color: modelColor.withValues(alpha: 0.3)),
          deleteIcon: Icon(Icons.close, size: 14, color: modelColor),
          onDeleted: onRemove != null ? () => onRemove!(model) : null,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }

  Color _getModelColor(String modelName) {
    final name = modelName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD4A574);
    } else if (name.contains('gpt') || name.contains('openai')) {
      return const Color(0xFF10A37F);
    } else if (name.contains('gemini') || name.contains('google')) {
      return const Color(0xFF4285F4);
    } else if (name.contains('qwen') || name.contains('通义')) {
      return const Color(0xFF6366F1);
    } else if (name.contains('deepseek')) {
      return const Color(0xFF06B6D4);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }
}
