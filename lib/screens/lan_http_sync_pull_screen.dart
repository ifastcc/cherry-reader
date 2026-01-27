import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/data_persistence_manager.dart';
import '../services/lan_http_sync/lan_http_sync_pull_prefs.dart';
import '../services/sync/sync_candidate.dart';
import '../services/sync/sync_preferences.dart';
import '../services/sync/sync_source_type.dart';

class LanHttpSyncPullScreen extends StatefulWidget {
  const LanHttpSyncPullScreen({super.key});

  @override
  State<LanHttpSyncPullScreen> createState() => _LanHttpSyncPullScreenState();
}

class _LanHttpSyncPullScreenState extends State<LanHttpSyncPullScreen> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _tokenController;

  bool _isDownloading = false;
  double? _progress;
  String? _message;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
    _tokenController = TextEditingController();
    unawaited(_loadPrefs());
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _baseUrlController.text =
          prefs.getString(LanHttpSyncPullPrefs.keyBaseUrl) ?? 'http://';
      _tokenController.text = prefs.getString(LanHttpSyncPullPrefs.keyToken) ?? '';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LanHttpSyncPullPrefs.keyBaseUrl, _baseUrlController.text.trim());
    await prefs.setString(LanHttpSyncPullPrefs.keyToken, _tokenController.text.trim());
  }

  String _buildDownloadUrl(String base) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('/lan-sync/latest.zip')) return trimmed;
    final normalized = trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    return '$normalized/lan-sync/latest.zip';
  }

  Future<void> _download() async {
    if (_isDownloading) return;
    final base = _baseUrlController.text.trim();
    final token = _tokenController.text.trim();
    final url = _buildDownloadUrl(base);
    if (url.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _message = '连接中...';
    });

    await _savePrefs();

    final targetPath = await DataPersistenceManager.getAppDataFilePath();
    final tmpPath = '$targetPath.tmp';

    final remoteInfo = await LanHttpSyncPullPrefs.fetchLatestInfo(
      baseUrl: base,
      token: token,
    );

    final dio = Dio();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    try {
      if (await File(tmpPath).exists()) {
        await File(tmpPath).delete();
      }

      await dio.download(
        url,
        tmpPath,
        cancelToken: cancelToken,
        options: Options(
          headers: token.isEmpty ? null : {'x-cherry-sync-token': token},
          responseType: ResponseType.stream,
        ),
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          if (total <= 0) {
            setState(() {
              _progress = null;
              _message = '下载中...';
            });
            return;
          }
          final p = received / total;
          setState(() {
            _progress = p.clamp(0.0, 1.0);
            _message = '下载中 ${(p * 100).toStringAsFixed(1)}%';
          });
        },
      );

      final tmpFile = File(tmpPath);
      if (!await tmpFile.exists()) {
        throw Exception('下载失败：文件不存在');
      }

      final finalFile = File(targetPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tmpFile.rename(targetPath);

      await DataPersistenceManager.clearCache();
      try {
        if (remoteInfo != null) {
          await File(targetPath).setLastModified(remoteInfo.modifiedAt.toLocal());
        }
        final stat = await File(targetPath).stat();
        await SyncPreferences.setInboxCandidate(
          SyncCandidate(
            sourceType: SyncSourceType.httpPull,
            name: remoteInfo?.name ?? targetPath.split(Platform.pathSeparator).last,
            remoteId: targetPath,
            size: remoteInfo?.size ?? stat.size,
            modifiedAt: remoteInfo?.modifiedAt ?? stat.modified.toUtc(),
          ),
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _progress = 1.0;
        _message = '下载完成，返回首页会自动解析导入';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 已下载到应用内')),
        );
        final goBack = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('已下载完成'),
              content: const Text('返回首页后会自动解析并导入。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('稍后'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('返回首页'),
                ),
              ],
            );
          },
        );
        if (goBack == true && mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _message = e.type == DioExceptionType.cancel
            ? '已取消'
            : '下载失败：${e.response?.statusCode ?? ''} ${e.message ?? e.toString()}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _message = '下载失败：$e';
      });
    } finally {
      _cancelToken = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('从桌面同步源下载'),
        actions: [
          if (_isDownloading)
            IconButton(
              onPressed: () {
                _cancelToken?.cancel();
              },
              icon: const Icon(Icons.close),
              tooltip: '取消',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('连接信息',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _baseUrlController,
                    enabled: !_isDownloading,
                    decoration: const InputDecoration(
                      labelText: '桌面端地址（或完整下载地址）',
                      hintText: 'http://192.168.1.10:9531',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    enabled: !_isDownloading,
                    decoration: const InputDecoration(
                      labelText: '访问令牌（x-cherry-sync-token）',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (progress != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: progress),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _message ?? '输入地址与令牌后点击下载',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isDownloading ? null : _download,
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('下载'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                [
                  '说明：',
                  '1) 桌面端在「设置 → 高级设置 → 局域网同步源（HTTP）」开启后，会显示下载地址与令牌。',
                  '2) 下载完成后返回首页，应用会自动解析并导入。',
                ].join('\n'),
                style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
