import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:bonsoir/bonsoir.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/data_persistence_manager.dart';
import '../services/lan_transfer_send_service.dart';
import '../services/local_folder_sync_service.dart';
import '../services/webdav_service.dart';

class LanTransferSendScreen extends StatefulWidget {
  const LanTransferSendScreen({super.key});

  @override
  State<LanTransferSendScreen> createState() => _LanTransferSendScreenState();
}

class _LanTransferSendScreenState extends State<LanTransferSendScreen> {
  static const String _serviceTypeFullName = '_cherrystudio._tcp';
  static const String _historyKey = 'lan_transfer_peer_history_v1';
  static const int _maxHistoryItems = 12;

  late final LanTransferSendService _sendService;
  BonsoirDiscovery? _discovery;

  final Map<String, ResolvedBonsoirService> _resolved = {};
  bool _isScanning = false;
  bool _isSending = false;
  String? _selectedPeerId;
  List<_SavedLanTransferPeer> _history = const [];

  @override
  void initState() {
    super.initState();
    _sendService = LanTransferSendService();
    unawaited(_loadHistory());
  }

  @override
  void dispose() {
    _stopScan();
    _sendService.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    _resolved.clear();
    _selectedPeerId = null;

    final discovery = BonsoirDiscovery(type: _serviceTypeFullName);
    _discovery = discovery;
    await discovery.ready;

    discovery.eventStream?.listen((event) {
      if (!mounted) return;
      final service = event.service;
      if (service == null) return;

      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        service.resolve(discovery.serviceResolver);
        return;
      }

      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        if (service is ResolvedBonsoirService) {
          final key = '${service.name}-${service.host ?? ''}-${service.port}';
          _upsertHistoryFromResolved(service);
          setState(() {
            _resolved[key] = service;
            _selectedPeerId ??= 'r:$key';
          });
        }
        return;
      }

      if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        final key = '${service.name}-${(service is ResolvedBonsoirService) ? service.host ?? '' : ''}-${service.port}';
        setState(() {
          _resolved.remove(key);
          if (_selectedPeerId == 'r:$key') {
            _selectedPeerId = null;
          }
        });
      }
    });

    setState(() => _isScanning = true);
    await discovery.start();
  }

  Future<void> _stopScan() async {
    if (!_isScanning) return;
    final d = _discovery;
    _discovery = null;
    setState(() => _isScanning = false);
    try {
      await d?.stop();
    } catch (_) {}
  }

  List<_PeerOption> _getPeerOptions() {
    final resolvedOptions = _resolved.entries
        .map((e) {
          final svc = e.value;
          final host = svc.host;
          if (host == null || host.isEmpty) return null;
          return _PeerOption(
            id: 'r:${e.key}',
            peer: LanTransferPeer(
              name: svc.name,
              host: host,
              port: svc.port,
              attributes: svc.attributes,
            ),
            label: '${svc.name}  ($host:${svc.port})',
            host: host,
            port: svc.port,
          );
        })
        .whereType<_PeerOption>()
        .toList();

    final seen = <String>{};
    for (final o in resolvedOptions) {
      seen.add('${o.host}:${o.port}');
    }

    final historyOptions = _history
        .where((h) => h.host.isNotEmpty && h.port > 0)
        .where((h) => !seen.contains('${h.host}:${h.port}'))
        .map((h) {
          return _PeerOption(
            id: 'h:${h.host}:${h.port}',
            peer: LanTransferPeer(
              name: h.name,
              host: h.host,
              port: h.port,
              attributes: h.attributes,
            ),
            label: '${h.name}  (${h.host}:${h.port})  · 历史',
            host: h.host,
            port: h.port,
          );
        })
        .toList();

    return [...resolvedOptions, ...historyOptions];
  }

  LanTransferPeer? _getSelectedPeer() {
    final id = _selectedPeerId;
    if (id == null) return null;
    final options = _getPeerOptions();
    for (final o in options) {
      if (o.id == id) return o.peer;
    }
    return null;
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? const <String>[];
    final parsed = <_SavedLanTransferPeer>[];
    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          parsed.add(_SavedLanTransferPeer.fromJson(decoded));
        }
      } catch (_) {}
    }
    parsed.sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));
    if (!mounted) return;
    setState(() {
      _history = parsed;
      final options = _getPeerOptions();
      _selectedPeerId ??= options.isNotEmpty ? options.first.id : null;
    });
  }

  Future<void> _persistHistory(List<_SavedLanTransferPeer> items) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = items.take(_maxHistoryItems).toList();
    await prefs.setStringList(
      _historyKey,
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> _upsertHistoryFromResolved(ResolvedBonsoirService svc) async {
    final host = svc.host;
    if (host == null || host.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = [..._history];
    final idx = next.indexWhere((e) => e.host == host && e.port == svc.port);
    final item = _SavedLanTransferPeer(
      name: svc.name,
      host: host,
      port: svc.port,
      attributes: svc.attributes,
      lastSeenMs: now,
    );
    if (idx >= 0) {
      next[idx] = item;
    } else {
      next.insert(0, item);
    }
    next.sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));
    if (mounted) {
      setState(() => _history = next.take(_maxHistoryItems).toList());
    }
    await _persistHistory(next);
  }

  Future<void> _markHistoryUsed(LanTransferPeer peer) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = [..._history];
    next.removeWhere((e) => e.host == peer.host && e.port == peer.port);
    next.insert(
      0,
      _SavedLanTransferPeer(
        name: peer.name,
        host: peer.host,
        port: peer.port,
        attributes: peer.attributes,
        lastSeenMs: now,
      ),
    );
    if (mounted) {
      setState(() => _history = next.take(_maxHistoryItems).toList());
    }
    await _persistHistory(next);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    if (!mounted) return;
    setState(() => _history = const []);
  }

  Future<String?> _prepareZipFromWebDav() async {
    final config = await WebDavService.loadConfig();
    if (!config.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先配置 WebDAV'), duration: Duration(seconds: 2)),
        );
      }
      return null;
    }

    final backups = await WebDavService.listBackupFiles(config);
    if (backups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WebDAV 未找到备份文件'), duration: Duration(seconds: 2)),
        );
      }
      return null;
    }

    final latest = backups.first;
    final tmp = await getTemporaryDirectory();
    final targetPath = p.join(tmp.path, latest.name.isNotEmpty ? latest.name : 'cherry-studio.backup.zip');
    final localPath = await WebDavService.downloadBackupToPath(
      config,
      latest.webdavFile,
      targetPath: targetPath,
    );
    if (localPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WebDAV 下载失败'), duration: Duration(seconds: 2)),
        );
      }
      return null;
    }
    return localPath;
  }

  Future<String?> _prepareZipFromAppData() async {
    final appPath = await DataPersistenceManager.getAppDataFilePath();
    final file = File(appPath);
    if (await file.exists()) return appPath;
    return null;
  }

  Future<String?> _prepareZipFromLocalFolder() async {
    final config = await LocalFolderSyncService.loadConfig();
    if (!config.isValid) return null;
    final backups = await LocalFolderSyncService.listBackupFiles(config);
    if (backups.isEmpty) return null;
    return backups.first.path;
  }

  Future<String?> _pickZipFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result == null || result.files.isEmpty) return null;
    return result.files.first.path;
  }

  Future<void> _send({required Future<String?> Function() prepareZip, required String actionName}) async {
    final peer = _getSelectedPeer();
    if (peer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未选择可用设备'), duration: Duration(seconds: 2)),
      );
      return;
    }
    if (_isSending) return;

    setState(() => _isSending = true);
    try {
      final zipPath = await prepareZip();
      if (zipPath == null) return;

      await _sendService.sendZipToPeer(peer: peer, zipPath: zipPath);
      final state = _sendService.notifier.value;
      if (state.status == LanTransferSendStatus.completed) {
        await _markHistoryUsed(peer);
      } else if (state.status == LanTransferSendStatus.error) {
        final selectedId = _selectedPeerId;
        final fromHistory = selectedId != null && selectedId.startsWith('h:');
        if (fromHistory && !_isScanning) {
          unawaited(_startScan());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('连接失败，已开始扫描附近设备'), duration: Duration(seconds: 2)),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _getPeerOptions();
    final selectedId = _selectedPeerId ?? (options.isNotEmpty ? options.first.id : null);
    if (_selectedPeerId == null && selectedId != null) {
      _selectedPeerId = selectedId;
    }
    _PeerOption? selectedOption;
    if (selectedId != null) {
      for (final o in options) {
        if (o.id == selectedId) {
          selectedOption = o;
          break;
        }
      }
    }
    final peer = selectedOption?.peer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网同步助手'),
        actions: [
          IconButton(
            onPressed: _isScanning ? _stopScan : _startScan,
            icon: Icon(_isScanning ? Icons.stop_circle_outlined : Icons.wifi_find),
            tooltip: _isScanning ? '停止扫描' : '开始扫描',
          ),
          if (_history.isNotEmpty)
            IconButton(
              onPressed: _isSending
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('清除历史设备'),
                            content: const Text('将移除已保存的历史设备地址。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('取消'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('清除'),
                              ),
                            ],
                          );
                        },
                      );
                      if (ok == true) {
                        await _clearHistory();
                      }
                    },
              icon: const Icon(Icons.delete_outline),
              tooltip: '清除历史',
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
                  const Text('使用说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    [
                      '1) 手机端：打开「设置 → 数据与同步 → 局域网传输（接收）」并保持页面常亮。',
                      '2) 桌面端：在本页扫描到手机后，选择一种“备份来源”并发送。',
                      '3) 发送完成后，手机端返回首页会自动解析导入。',
                    ].join('\n'),
                    style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('发现的设备', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        _isScanning ? '扫描中' : '已停止',
                        style: TextStyle(fontSize: 12, color: _isScanning ? Colors.green[700] : Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '不会在后台自动扫描；仅在你点「开始扫描」时发送局域网发现请求。',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  if (options.isEmpty)
                    Text(
                      _history.isEmpty
                          ? '暂无设备。请确保手机端已打开接收页且与本机同一局域网，然后点右上角开始扫描。'
                          : '暂无在线设备。可先尝试历史设备；不通时再点右上角开始扫描。',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: options
                          .map(
                            (o) => DropdownMenuItem(
                              value: o.id,
                              child: Text(o.label),
                            ),
                          )
                          .toList(),
                      onChanged: _isSending
                          ? null
                          : (v) {
                              setState(() => _selectedPeerId = v);
                            },
                    ),
                  const SizedBox(height: 12),
                  if (peer != null)
                    Text(
                      '目标：${peer.name}  ${peer.host}:${peer.port}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<LanTransferSendState>(
                valueListenable: _sendService.notifier,
                builder: (context, state, _) {
                  final isBusy = _isSending || state.status == LanTransferSendStatus.transferring || state.status == LanTransferSendStatus.handshaking;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('发送备份', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (state.progress != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: state.progress),
                        ),
                      if (state.progress != null) const SizedBox(height: 8),
                      Text(
                        state.error ?? state.message ?? '选择一个来源开始发送',
                        style: TextStyle(fontSize: 13, color: state.error != null ? Colors.red[700] : Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _send(prepareZip: _prepareZipFromWebDav, actionName: 'WebDAV 最新备份'),
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: const Text('发送 WebDAV 最新备份'),
                          ),
                          OutlinedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _send(prepareZip: _prepareZipFromLocalFolder, actionName: '本地备份目录最新'),
                            icon: const Icon(Icons.folder_copy_outlined),
                            label: const Text('发送本地目录最新'),
                          ),
                          OutlinedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _send(prepareZip: _prepareZipFromAppData, actionName: '应用内备份文件'),
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('发送应用内文件'),
                          ),
                          OutlinedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _send(prepareZip: _pickZipFile, actionName: '选择 ZIP'),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('选择 ZIP 发送'),
                          ),
                        ],
                      ),
                      if (_isSending) ...[
                        const SizedBox(height: 12),
                        const Text('发送中，请保持窗口打开。', style: TextStyle(fontSize: 12)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedLanTransferPeer {
  final String name;
  final String host;
  final int port;
  final Map<String, String> attributes;
  final int lastSeenMs;

  const _SavedLanTransferPeer({
    required this.name,
    required this.host,
    required this.port,
    required this.attributes,
    required this.lastSeenMs,
  });

  factory _SavedLanTransferPeer.fromJson(Map<String, dynamic> json) {
    final attrs = <String, String>{};
    final rawAttrs = json['attributes'];
    if (rawAttrs is Map) {
      for (final e in rawAttrs.entries) {
        if (e.key is String && e.value is String) {
          attrs[e.key as String] = e.value as String;
        }
      }
    }
    return _SavedLanTransferPeer(
      name: json['name']?.toString() ?? '未知设备',
      host: json['host']?.toString() ?? '',
      port: int.tryParse(json['port']?.toString() ?? '') ?? 0,
      attributes: attrs,
      lastSeenMs: int.tryParse(json['lastSeenMs']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'host': host,
        'port': port,
        'attributes': attributes,
        'lastSeenMs': lastSeenMs,
      };
}

class _PeerOption {
  final String id;
  final LanTransferPeer peer;
  final String label;
  final String host;
  final int port;

  const _PeerOption({
    required this.id,
    required this.peer,
    required this.label,
    required this.host,
    required this.port,
  });
}
