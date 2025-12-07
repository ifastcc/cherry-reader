import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider.dart';
import '../utils/api_host_utils.dart';

/// AI Provider 管理服务
///
/// 功能：
/// 1. 管理多个 AI Provider
/// 2. 从 Cherry Studio 备份导入 Provider
/// 3. 持久化存储 Provider 配置
class AIProviderService {
  static const String _prefKey = 'ai_providers';
  static const String _activeProviderKey = 'active_provider_id';
  static const String _activeModelKey = 'active_model_id';

  static AIProviderService? _instance;
  static AIProviderService get instance {
    _instance ??= AIProviderService._();
    return _instance!;
  }

  AIProviderService._();

  List<AIProvider> _providers = [];
  String? _activeProviderId;
  String? _activeModelId;

  /// 获取所有 Provider
  List<AIProvider> get providers => List.unmodifiable(_providers);

  /// 获取有效的 Provider（有 API Key 的）
  List<AIProvider> get validProviders =>
      _providers.where((p) => p.isValid && p.enabled).toList();

  /// 获取当前激活的 Provider
  AIProvider? get activeProvider {
    if (_activeProviderId == null) return null;
    try {
      return _providers.firstWhere((p) => p.id == _activeProviderId);
    } catch (_) {
      return _providers.isNotEmpty ? _providers.first : null;
    }
  }

  /// 获取当前激活的 Model ID
  String? get activeModelId => _activeModelId;

  /// 获取当前激活的 Model
  AIModel? get activeModel {
    final provider = activeProvider;
    if (provider == null || _activeModelId == null) return null;
    try {
      return provider.models.firstWhere((m) => m.id == _activeModelId);
    } catch (_) {
      return provider.models.isNotEmpty ? provider.models.first : null;
    }
  }

  /// 初始化，从持久化存储加载
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载 providers
    final json = prefs.getString(_prefKey);
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        _providers = list
            .map((e) => AIProvider.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('⚠️ 加载 AI Providers 失败: $e');
        _providers = [];
      }
    }

    // 加载激活的 provider 和 model
    _activeProviderId = prefs.getString(_activeProviderKey);
    _activeModelId = prefs.getString(_activeModelKey);

    // 如果没有激活的，设置第一个有效的
    if (_activeProviderId == null && validProviders.isNotEmpty) {
      _activeProviderId = validProviders.first.id;
      if (validProviders.first.models.isNotEmpty) {
        _activeModelId = validProviders.first.models.first.id;
      }
    }
  }

  /// 保存到持久化存储
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(_providers.map((p) => p.toJson()).toList()),
    );
    if (_activeProviderId != null) {
      await prefs.setString(_activeProviderKey, _activeProviderId!);
    }
    if (_activeModelId != null) {
      await prefs.setString(_activeModelKey, _activeModelId!);
    }
  }

  /// 设置激活的 Provider
  Future<void> setActiveProvider(String providerId) async {
    _activeProviderId = providerId;
    // 重置 model 为该 provider 的第一个
    final provider = activeProvider;
    if (provider != null && provider.models.isNotEmpty) {
      _activeModelId = provider.models.first.id;
    } else {
      _activeModelId = null;
    }
    await _save();
  }

  /// 设置激活的 Model
  Future<void> setActiveModel(String modelId) async {
    _activeModelId = modelId;
    await _save();
  }

  /// 添加 Provider
  Future<void> addProvider(AIProvider provider) async {
    // 检查是否已存在
    final existingIndex = _providers.indexWhere((p) => p.id == provider.id);
    if (existingIndex >= 0) {
      _providers[existingIndex] = provider;
    } else {
      _providers.add(provider);
    }
    await _save();
  }

  /// 更新 Provider
  Future<void> updateProvider(AIProvider provider) async {
    final index = _providers.indexWhere((p) => p.id == provider.id);
    if (index >= 0) {
      _providers[index] = provider;
      await _save();
    }
  }

  /// 删除 Provider
  Future<void> removeProvider(String providerId) async {
    _providers.removeWhere((p) => p.id == providerId);
    if (_activeProviderId == providerId) {
      _activeProviderId = validProviders.isNotEmpty ? validProviders.first.id : null;
    }
    await _save();
  }

  /// 清空所有 Provider
  Future<void> clearAll() async {
    _providers.clear();
    _activeProviderId = null;
    _activeModelId = null;
    await _save();
  }

  /// 从 Cherry Studio 备份 ZIP 文件导入 Provider
  ///
  /// 返回导入的 Provider 数量
  Future<int> importFromCherryStudioZip(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $zipPath');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 查找 data.json
    ArchiveFile? dataFile;
    for (final f in archive) {
      if (f.name.endsWith('data.json')) {
        dataFile = f;
        break;
      }
    }

    if (dataFile == null) {
      throw Exception('ZIP 文件中未找到 data.json');
    }

    final jsonString = utf8.decode(dataFile.content as List<int>);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    return _parseAndImportProviders(data);
  }

  /// 从 Cherry Studio 备份 JSON 字符串导入 Provider
  Future<int> importFromCherryStudioJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return _parseAndImportProviders(data);
  }

  /// 从已解析的数据中导入 Provider（被动导入，用于数据加载时自动导入）
  ///
  /// 这是一个被动的导入方式，在加载 Cherry Studio 数据时自动调用
  /// 不需要重新解包 ZIP 文件
  Future<int> importFromParsedData(Map<String, dynamic> data) async {
    return _parseAndImportProviders(data);
  }

  /// 解析并导入 Provider
  int _parseAndImportProviders(Map<String, dynamic> data) {
    // localStorage 中的 persist:cherry-studio 包含 llm.providers
    final localStorage = data['localStorage'] as Map<String, dynamic>?;
    if (localStorage == null) {
      throw Exception('导出数据中未找到 localStorage');
    }

    // persist:cherry-studio 是一个 JSON 字符串
    final persistStr = localStorage['persist:cherry-studio'] as String?;
    if (persistStr == null) {
      throw Exception('导出数据中未找到 persist:cherry-studio');
    }

    final persistData = jsonDecode(persistStr) as Map<String, dynamic>;

    // llm 字段也是一个 JSON 字符串
    final llmStr = persistData['llm'] as String?;
    if (llmStr == null) {
      throw Exception('导出数据中未找到 llm 配置');
    }

    final llmData = jsonDecode(llmStr) as Map<String, dynamic>;

    // providers 是一个数组
    final providersJson = llmData['providers'] as List<dynamic>?;
    if (providersJson == null || providersJson.isEmpty) {
      throw Exception('导出数据中未找到 providers');
    }

    int importedCount = 0;
    for (final pJson in providersJson) {
      try {
        final provider =
            AIProvider.fromCherryStudio(pJson as Map<String, dynamic>);

        // 只导入有效的 provider
        if (provider.isValid) {
          // 检查是否已存在
          final existingIndex =
              _providers.indexWhere((p) => p.id == provider.id);
          if (existingIndex >= 0) {
            // 如果已存在且是用户手动添加的，则跳过（保护用户配置）
            final existing = _providers[existingIndex];
            if (existing.source == ProviderSource.manual) {
              print('ℹ️ 跳过导入 "${provider.name}"：已存在手动添加的配置');
              continue;
            }
            // 如果是从 Cherry Studio 导入的，则更新
            _providers[existingIndex] = provider;
          } else {
            _providers.add(provider);
          }
          importedCount++;
        }
      } catch (e) {
        print('⚠️ 解析 Provider 失败: $e');
      }
    }

    // 保存
    _save();

    // 如果没有激活的 provider，设置第一个
    if (_activeProviderId == null && validProviders.isNotEmpty) {
      _activeProviderId = validProviders.first.id;
      if (validProviders.first.models.isNotEmpty) {
        _activeModelId = validProviders.first.models.first.id;
      }
    }

    return importedCount;
  }

  /// 获取用于 API 调用的配置
  ///
  /// 返回 (apiKey, baseUrl, modelId) 或 null
  ({String apiKey, String baseUrl, String modelId})? getActiveConfig() {
    final provider = activeProvider;
    final model = activeModel;

    if (provider == null || !provider.isValid) return null;

    // 对 Cherry Studio 导出的 apiHost 做一次规范化处理，
    // 自动补全缺失的 /v1，保证与 Cherry Studio 中的调用行为一致。
    final normalizedBaseUrl = formatOpenAIApiHost(provider.apiHost);

    return (
      apiKey: provider.apiKey,
      baseUrl: normalizedBaseUrl,
      modelId: model?.id ?? (provider.models.isNotEmpty ? provider.models.first.id : 'gpt-4'),
    );
  }
}
