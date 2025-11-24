import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/cherry_extractor.dart';
import '../services/data_persistence_manager.dart';
import '../services/isar_database.dart';
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

  // 【优化】使用轻量级索引，而非完整数据
  Map<String, List<Map<String, dynamic>>>? _topicIndex;
  Map<String, Map<String, dynamic>>? _assistantMap;

  @override
  void initState() {
    super.initState();
    _autoLoadDataFile();
  }

  /// 自动加载上次打开的文件（使用轻量级缓存）
  ///
  /// 【性能优化】只加载话题索引，不加载完整数据
  Future<void> _autoLoadDataFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final startTime = DateTime.now();

      // 智能加载: 优先使用轻量级索引
      final (topicIndex, isFromCache) =
          await DataPersistenceManager.smartLoad();

      if (topicIndex != null && topicIndex.isNotEmpty) {
        // 从缓存加载索引
        debugPrint('✅ 从缓存加载话题索引');

        // 加载 Assistant 信息
        final lastFile = await DataPersistenceManager.getLastFilePath();
        if (lastFile != null) {
          // 创建轻量级 extractor（只用于获取 assistant 信息）
          final extractor = _createLightweightExtractor(lastFile);
          await extractor.load();

          final assistants = extractor.getAssistants();
          final assistantMap = <String, Map<String, dynamic>>{};
          for (final a in assistants) {
            if (a is Map<String, dynamic>) {
              final id = a['id'] as String?;
              if (id != null) {
                assistantMap[id] = a;
              }
            }
          }

          setState(() {
            _extractor = extractor;
            _topicIndex = topicIndex;
            _assistantMap = assistantMap;
            _isLoading = false;
          });

          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          debugPrint('💡 从缓存加载完成，耗时 ${elapsed}ms');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ 已从缓存加载（轻量级索引）'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
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

  /// 创建轻量级 Extractor（只用于加载 Assistant 信息）
  CherryExtractor _createLightweightExtractor(String filePath) {
    final isZip = filePath.endsWith('.zip');
    return CherryExtractor(
      zipPath: isZip ? filePath : null,
      dataJsonPath: isZip ? null : filePath,
    );
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
        initialDirectory =
            Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
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
      final appFilePath = await DataPersistenceManager.copyFileToAppDirectory(
        filePath,
      );

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
  ///
  /// 【优化】加载完成后保存轻量级索引到 Isar
  Future<void> _loadFile(String filePath, {bool saveCache = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _extractor = null;
      _topicIndex = null;
      _assistantMap = null;
    });

    try {
      final startTime = DateTime.now();

      final isZip = filePath.endsWith('.zip');
      final extractor = CherryExtractor(
        zipPath: isZip ? filePath : null,
        dataJsonPath: isZip ? null : filePath,
      );

      await extractor.load();

      // 【优化】提取话题索引（轻量级）
      final grouped = extractor.getTopicsByAssistant();
      final topicIndex = <String, List<Map<String, dynamic>>>{};

      for (final entry in grouped.entries) {
        final assistantId = entry.key;
        final assistantData = entry.value;
        final topics = assistantData['topics'] as List<dynamic>;

        topicIndex[assistantId] = topics.map((t) {
          final topic = t as Map<String, dynamic>;
          return {
            'id': topic['id'],
            'name': topic['name'],
            'assistantId': assistantId,
            'messageCount': (topic['messages'] as List?)?.length ?? 0,
            'createdAt': topic['createdAt'],
            'updatedAt': topic['updatedAt'],
          };
        }).toList();
      }

      // 提取 Assistant 信息
      final assistants = extractor.getAssistants();
      final assistantMap = <String, Map<String, dynamic>>{};
      for (final a in assistants) {
        if (a is Map<String, dynamic>) {
          final id = a['id'] as String?;
          if (id != null) {
            assistantMap[id] = a;
          }
        }
      }

      setState(() {
        _extractor = extractor;
        _topicIndex = topicIndex;
        _assistantMap = assistantMap;
        _isLoading = false;
      });

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('💡 文件加载完成，耗时 ${elapsed}ms');

      // 保存轻量级索引到缓存
      if (saveCache) {
        try {
          // 【修复】构建完整话题数据（包含解析后的 blocks）
          final allTopics = <Map<String, dynamic>>[];
          for (final entry in grouped.entries) {
            final assistantData = entry.value;
            final topics = assistantData['topics'] as List<dynamic>;
            for (final t in topics) {
              final topic = t as Map<String, dynamic>;

              // 【关键修复】解析每个消息的 blocks
              final messages = topic['messages'] as List<dynamic>? ?? [];
              final processedMessages = <Map<String, dynamic>>[];

              for (final msg in messages) {
                if (msg is! Map<String, dynamic>) continue;

                // 提取 block IDs 并查找完整 block 数据
                final blockIds =
                    (msg['blocks'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final resolvedBlocks = extractor.getMessageBlocks(blockIds);

                // 创建包含完整 blocks 的消息副本
                final processedMsg = Map<String, dynamic>.from(msg);
                processedMsg['blocks'] = resolvedBlocks;
                processedMessages.add(processedMsg);
              }

              // 创建包含解析后消息的话题副本
              final processedTopic = Map<String, dynamic>.from(topic);
              processedTopic['messages'] = processedMessages;
              processedTopic['assistantId'] = entry.key;

              allTopics.add(processedTopic);
            }
          }

          await DataPersistenceManager.saveTopicIndexCache(allTopics);
          await DataPersistenceManager.markCacheAsValid();
          await DataPersistenceManager.saveFileTimestamp(filePath);
          debugPrint('✅ 已保存话题缓存');
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
          SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red),
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
          // 【修复】清除缓存按钮
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              // 显示确认对话框
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清除缓存'),
                  content: const Text('确定要清除所有缓存吗？\n\n清除后需要重新加载数据文件。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  // 清除所有缓存
                  await DataPersistenceManager.clearCache();
                  await IsarDatabase().clearAll();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 缓存已清除，请重新加载文件'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  setState(() {
                    _extractor = null;
                    _topicIndex = null;
                    _assistantMap = null;
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('清除缓存失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            tooltip: '清除缓存',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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

    if (_topicIndex == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[600]),
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
    if (_topicIndex == null || _topicIndex!.isEmpty) {
      return const Center(child: Text('没有找到话题'));
    }

    // 【优化】将 Map 转换为 List 用于 ListView.builder
    final assistantEntries = _topicIndex!.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assistantEntries.length,
      itemBuilder: (context, index) {
        final entry = assistantEntries[index];
        final assistantId = entry.key;
        final topics = entry.value;

        // 获取 Assistant 信息
        final assistantInfo =
            _assistantMap?[assistantId] ?? {'id': assistantId, 'name': '未命名助手'};

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
            // 【优化】ExpansionTile 的 children 仍使用 map，因为这只在展开时渲染
            children: topics.map((topic) {
              final topicName = topic['name'] as String? ?? '未命名话题';
              final topicId = topic['id'] as String;
              final messageCount = topic['messageCount'] as int? ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                title: Text(topicName),
                subtitle: Text('$messageCount 条消息'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // 【按需加载】点击时才加载完整话题数据
                  if (_extractor == null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('数据加载器未就绪')));
                    return;
                  }

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
      },
    );
  }
}
