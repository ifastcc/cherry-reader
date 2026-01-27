import 'dart:io';

import 'package:flutter/material.dart';

import '../services/lan_transfer_receive_service.dart';

class LanTransferReceiveScreen extends StatefulWidget {
  const LanTransferReceiveScreen({super.key});

  @override
  State<LanTransferReceiveScreen> createState() => _LanTransferReceiveScreenState();
}

class _LanTransferReceiveScreenState extends State<LanTransferReceiveScreen> {
  late final LanTransferReceiveService _service;
  bool _didPromptAfterComplete = false;

  @override
  void initState() {
    super.initState();
    _service = LanTransferReceiveService();
    _service.start();
    _service.notifier.addListener(_maybePromptAfterComplete);
  }

  @override
  void dispose() {
    _service.notifier.removeListener(_maybePromptAfterComplete);
    _service.dispose();
    super.dispose();
  }

  void _maybePromptAfterComplete() {
    if (!mounted) return;
    final state = _service.notifier.value;
    if (_didPromptAfterComplete) return;
    if (state.status != LanTransferReceiveStatus.completed || state.completedFilePath == null) return;
    _didPromptAfterComplete = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('已接收备份文件'),
          content: Text(
            '文件已保存到应用内。\n返回首页后会自动解析并导入。',
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('稍后'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pop(true);
              },
              child: const Text('返回首页'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网传输'),
      ),
      body: ValueListenableBuilder<LanTransferReceiveState>(
        valueListenable: _service.notifier,
        builder: (context, state, _) {
          final isRunning = _service.isRunning;
          final port = state.port;
          final progress = state.progress;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.deviceName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        port != null ? '端口：$port' : '端口：-',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.connectedClientName != null ? '已连接：${state.connectedClientName}' : '未连接',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      if (progress != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: progress),
                        ),
                      if (progress != null) const SizedBox(height: 8),
                      Text(
                        state.error ?? state.message ?? _defaultHintText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: state.error != null ? Colors.red[700] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: isRunning ? null : _service.start,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('启动'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isRunning ? _service.stop : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止'),
                          ),
                        ],
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
                      const Text('使用说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        _instructionText(),
                        style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _defaultHintText() {
    return '保持此页面打开，等待 Cherry Studio 桌面端发现并发送备份。';
  }

  String _instructionText() {
    final platform = Platform.isIOS
        ? 'iOS'
        : Platform.isAndroid
            ? 'Android'
            : Platform.operatingSystem;
    return [
      '1) 手机端：打开本页面，确保在同一 Wi‑Fi / 局域网内（当前：$platform）。',
      '2) 电脑端：打开 Cherry Studio → 数据设置 → 局域网传输。',
      '3) 在电脑端选择你的手机设备，发送备份 ZIP。',
      '4) 接收完成后返回首页，应用会自动解析并导入。',
    ].join('\n');
  }
}
