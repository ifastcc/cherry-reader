import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/cherry_extractor.dart';
import '../services/data_persistence_manager.dart';
import 'conversation_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CherryExtractor? _extractor;
  bool _isLoading = false;
  String? _error;
  Map<String, Map<String, dynamic>>? _groupedTopics;

  @override
  void initState() {
    super.initState();
    _autoLoadDataFile();
  }

  /// 自动加载上次打开的文件(使用缓存)
  Future<void> _autoLoadDataFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 智能加载: 优先使用缓存
      final (cachedData, isFromCache) = await DataPersistenceManager.smartLoad();

      if (cachedData != null) {
        // 从缓存加载数据
        debugPrint('✅ 从缓存加载数据');
        await _loadFromCachedData(cachedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 已从缓存加载上次的数据'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 没有缓存,尝试重新解析文件
        final lastFile = await DataPersistenceManager.getLastFilePath();
        if (lastFile != null) {
          final file = File(lastFile);
          if (await file.exists()) {
            debugPrint('📂 重新解析文件: $lastFile');
            await _loadFile(lastFile, saveCache: true);
          } else {
            debugPrint('⚠️  上次打开的文件不存在: $lastFile');
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          debugPrint('ℹ️  没有上次打开的文件记录');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // 自动加载失败不显示错误，让用户手动选择
      debugPrint('⚠️  自动加载失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 从缓存数据加载
  Future<void> _loadFromCachedData(Map<String, dynamic> data) async {
    try {
      final extractor = CherryExtractor.fromCachedData(data);
      final grouped = extractor.getTopicsByAssistant();

      setState(() {
        _extractor = extractor;
        _groupedTopics = grouped;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 从缓存加载失败: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 选择并加载文件
  Future<void> _pickAndLoadFile() async {
    // 获取上次打开的目录
    String? initialDirectory;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDir = prefs.getString('last_opened_directory');

      if (lastDir != null && await Directory(lastDir).exists()) {
        initialDirectory = lastDir;
      } else {
        // 如果没有上次目录,尝试使用用户主目录
        initialDirectory = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      }
    } catch (e) {
      initialDirectory = null;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
      initialDirectory: initialDirectory,
      dialogTitle: '选择 Cherry Studio 导出文件',
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    // 拷贝文件到App目录
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('📂 用户选择的文件: $filePath');

      // 拷贝文件到App内部目录
      final appFilePath = await DataPersistenceManager.copyFileToAppDirectory(filePath);

      // 保存上次打开的目录(用于下次打开文件选择器)
      try {
        var fileDir = File(filePath).parent.path;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_opened_directory', fileDir);
        debugPrint('✅ 已保存目录: $fileDir');
      } catch (e) {
        debugPrint('保存目录失败: $e');
      }

      // 加载拷贝后的文件
      await _loadFile(appFilePath, saveCache: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 文件已导入到App目录'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = '文件拷贝失败: $e';
        _isLoading = false;
      });
      debugPrint('文件拷贝失败: $e');
    }
  }

  /// 加载指定文件
  Future<void> _loadFile(String filePath, {bool saveCache = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _extractor = null;
      _groupedTopics = null;
    });

    try {
      final isZip = filePath.endsWith('.zip');
      final extractor = CherryExtractor(
        zipPath: isZip ? filePath : null,
        dataJsonPath: isZip ? null : filePath,
      );

      await extractor.load();

      final grouped = extractor.getTopicsByAssistant();

      setState(() {
        _extractor = extractor;
        _groupedTopics = grouped;
        _isLoading = false;
      });

      // 保存缓存
      if (saveCache) {
        try {
          final cacheData = extractor.exportToMap();
          await DataPersistenceManager.saveCachedData(filePath, cacheData);
          debugPrint('✅ 已保存数据缓存');
        } catch (e) {
          debugPrint('⚠️  保存缓存失败: $e');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cherry Studio Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: '设置',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickAndLoadFile,
        icon: const Icon(Icons.folder_open),
        label: const Text('加载数据'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载数据...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('加载失败', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_groupedTopics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            const Text(
              '请选择 Cherry Studio 导出文件',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '支持 .zip 或 .json 格式',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return _buildTopicList();
  }

  Widget _buildTopicList() {
    if (_groupedTopics == null || _groupedTopics!.isEmpty) {
      return const Center(child: Text('没有找到话题'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _groupedTopics!.entries.map((entry) {
        final assistantInfo = entry.value['assistant'] as Map<String, dynamic>;
        final topics = entry.value['topics'] as List<dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              child: Text(
                (assistantInfo['name'] as String?)?.substring(0, 1) ?? '?',
              ),
            ),
            title: Text(
              assistantInfo['name'] as String? ?? '未命名助手',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${topics.length} 个话题'),
            children: topics.map((topic) {
              final topicData = topic as Map<String, dynamic>;
              final topicName = topicData['name'] as String? ?? '未命名话题';
              final topicId = topicData['id'] as String;
              final messages = topicData['messages'] as List<dynamic>? ?? [];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                title: Text(topicName),
                subtitle: Text('${messages.length} 条消息'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConversationScreen(
                        extractor: _extractor!,
                        topicId: topicId,
                        topicName: topicName,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
