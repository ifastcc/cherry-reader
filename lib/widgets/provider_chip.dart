import 'package:flutter/material.dart';
import '../models/ai_provider.dart';
import '../services/ai_provider_service.dart';

/// Provider/Model 选择 Chip
///
/// 显示在 AppBar，紧凑展示当前模型
/// 点击弹出选择器
class ProviderChip extends StatelessWidget {
  /// 点击回调（如果为 null，使用默认选择器）
  final VoidCallback? onTap;

  /// 选择完成后的回调
  final VoidCallback? onChanged;

  const ProviderChip({
    Key? key,
    this.onTap,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = AIProviderService.instance;
    final activeModel = service.activeModel;
    final activeProvider = service.activeProvider;

    // 未配置状态
    if (activeProvider == null || !activeProvider.isValid) {
      return _buildChip(
        context,
        icon: Icons.warning_amber_outlined,
        label: '未配置',
        color: Colors.orange,
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            _showProviderSelector(context);
          }
        },
      );
    }

    // 已配置状态
    return _buildChip(
      context,
      icon: Icons.smart_toy_outlined,
      label: activeModel?.displayName ?? activeProvider.name,
      color: Colors.green,
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          _showProviderSelector(context);
        }
      },
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  void _showProviderSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProviderSelectorSheet(
        onChanged: onChanged,
      ),
    );
  }
}

/// Provider/Model 选择器 Bottom Sheet
class ProviderSelectorSheet extends StatefulWidget {
  final VoidCallback? onChanged;

  const ProviderSelectorSheet({
    Key? key,
    this.onChanged,
  }) : super(key: key);

  @override
  State<ProviderSelectorSheet> createState() => _ProviderSelectorSheetState();
}

class _ProviderSelectorSheetState extends State<ProviderSelectorSheet> {
  final service = AIProviderService.instance;

  @override
  Widget build(BuildContext context) {
    final providers = service.validProviders;
    final activeProvider = service.activeProvider;
    final activeModelId = service.activeModelId;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // 拖动指示器
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_outlined),
                  const SizedBox(width: 8),
                  const Text(
                    '选择模型',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Provider 和 Model 列表
            Expanded(
              child: providers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        final isActiveProvider = provider.id == activeProvider?.id;

                        return _buildProviderSection(
                          provider,
                          isActiveProvider,
                          activeModelId,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '未配置 AI Provider',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请在设置中导入 Cherry Studio 配置\n或手动添加 Provider',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // 打开设置页面
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings),
            label: const Text('前往设置'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection(
    AIProvider provider,
    bool isActiveProvider,
    String? activeModelId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider 标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isActiveProvider ? Colors.blue.withOpacity(0.05) : Colors.grey[50],
          child: Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                size: 18,
                color: isActiveProvider ? Colors.blue : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActiveProvider ? Colors.blue : Colors.grey[800],
                  ),
                ),
              ),
              if (isActiveProvider)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '当前',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Model 列表
        ...provider.models.map((model) {
          final isActiveModel = isActiveProvider && model.id == activeModelId;

          return ListTile(
            dense: true,
            leading: Radio<String>(
              value: model.id,
              groupValue: isActiveProvider ? activeModelId : null,
              onChanged: (value) async {
                if (value != null) {
                  await service.setActiveProvider(provider.id);
                  await service.setActiveModel(value);
                  widget.onChanged?.call();
                  setState(() {});
                }
              },
            ),
            title: Text(
              model.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActiveModel ? FontWeight.w600 : FontWeight.normal,
                color: isActiveModel ? Colors.blue : Colors.grey[800],
              ),
            ),
            subtitle: Text(
              model.id,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            onTap: () async {
              await service.setActiveProvider(provider.id);
              await service.setActiveModel(model.id);
              widget.onChanged?.call();
              setState(() {});
            },
          );
        }),

        const Divider(height: 1),
      ],
    );
  }
}
