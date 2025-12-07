import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/tts_play_session.dart';
import '../models/tts_segment.dart';
import '../utils/markdown_to_ssml_converter.dart';
import 'tts_segment_cache.dart';

/// TTS 段落下载器
///
/// 负责并发下载段落音频，支持优先级调度
class TtsSegmentDownloader {
  final List<String> apiKeys;
  int _currentKeyIndex;
  final String region;
  final Dio _dio = Dio();
  final TtsSegmentCache _cache = TtsSegmentCache();

  /// SSML 配置
  SsmlConfig ssmlConfig;

  /// 最大并发下载数
  final int maxConcurrent;

  /// 当前下载任务
  final Map<int, Future<void>> _downloadTasks = {};

  /// 是否已取消
  bool _isCancelled = false;

  /// 进度回调
  void Function(int segmentIndex, SegmentStatus status)? onSegmentStatusChanged;

  TtsSegmentDownloader({
    String? apiKey,
    List<String>? apiKeys,
    required this.region,
    int currentKeyIndex = 0,
    this.maxConcurrent = 3,
    this.ssmlConfig = const SsmlConfig(),
  })  : apiKeys = apiKeys ?? (apiKey != null ? [apiKey] : []),
        _currentKeyIndex = currentKeyIndex;

  String get _ttsUrl =>
      'https://$region.tts.speech.microsoft.com/cognitiveservices/v1';

  String? get _currentApiKey {
    if (apiKeys.isEmpty) return null;
    if (_currentKeyIndex < 0 || _currentKeyIndex >= apiKeys.length) {
      _currentKeyIndex = 0;
    }
    return apiKeys[_currentKeyIndex];
  }

  bool _switchToNextKey() {
    if (apiKeys.length <= 1) return false;
    _currentKeyIndex = (_currentKeyIndex + 1) % apiKeys.length;
    debugPrint('🔊 切换到下一个 API Key (index: $_currentKeyIndex)');
    return true;
  }

  /// 开始下载会话的所有段落
  ///
  /// [priorityIndex] 优先下载的段落索引（当前要播放的）
  Future<void> downloadSession({
    required TtsPlaySession session,
    required String voiceName,
    required double rate,
    String? style,
    int priorityIndex = 0,
  }) async {
    _isCancelled = false;
    debugPrint('🔊 开始下载会话: ${session.messageId}, ${session.segments.length} 段');

    final pendingSegments = <int>[];

    // 收集需要下载的段落
    for (var i = 0; i < session.segments.length; i++) {
      if (session.segments[i].status == SegmentStatus.pending) {
        pendingSegments.add(i);
      }
    }

    if (pendingSegments.isEmpty) {
      debugPrint('🔊 所有段落已就绪');
      return;
    }

    // 按优先级排序：priorityIndex 及其后的段落优先
    pendingSegments.sort((a, b) {
      final aPriority = a >= priorityIndex ? a - priorityIndex : 1000 + a;
      final bPriority = b >= priorityIndex ? b - priorityIndex : 1000 + b;
      return aPriority.compareTo(bPriority);
    });

    debugPrint('🔊 下载顺序: $pendingSegments');

    // 使用信号量控制并发
    final semaphore = _Semaphore(maxConcurrent);
    final futures = <Future<void>>[];

    for (final index in pendingSegments) {
      if (_isCancelled) break;

      final future = semaphore.acquire().then((_) async {
        if (_isCancelled) return;

        try {
          await _downloadSegment(
            session: session,
            segmentIndex: index,
            voiceName: voiceName,
            rate: rate,
            style: style,
          );
        } finally {
          semaphore.release();
        }
      });

      futures.add(future);
    }

    await Future.wait(futures);
    debugPrint('🔊 会话下载完成: ${session.messageId}');
  }

  /// 下载单个段落
  Future<void> downloadSingleSegment({
    required TtsPlaySession session,
    required int segmentIndex,
    required String voiceName,
    required double rate,
    String? style,
  }) async {
    await _downloadSegment(
      session: session,
      segmentIndex: segmentIndex,
      voiceName: voiceName,
      rate: rate,
      style: style,
    );
  }

  /// 内部下载方法
  Future<void> _downloadSegment({
    required TtsPlaySession session,
    required int segmentIndex,
    required String voiceName,
    required double rate,
    String? style,
  }) async {
    if (_isCancelled) return;

    final segment = session.segments[segmentIndex];

    // 检查是否已经在下载
    if (_downloadTasks.containsKey(segmentIndex)) {
      await _downloadTasks[segmentIndex];
      return;
    }

    // 更新状态为下载中
    session.updateSegment(
      segmentIndex,
      segment.copyWith(status: SegmentStatus.downloading),
    );
    onSegmentStatusChanged?.call(segmentIndex, SegmentStatus.downloading);

    debugPrint('🔊 开始下载段落 $segmentIndex: ${segment.text.length} 字符, hasSsml: ${segment.hasSsml}');

    try {
      final audioData = await _synthesizeSegment(
        segment: segment,
        voiceName: voiceName,
        rate: rate,
        style: style,
      );

      if (_isCancelled) return;

      // 保存到缓存
      final filePath = await _cache.saveSegmentAudio(
        messageId: session.messageId,
        segmentIndex: segmentIndex,
        audioData: audioData,
      );

      // 更新段落状态
      session.updateSegment(
        segmentIndex,
        segment.copyWith(
          status: SegmentStatus.ready,
          cachePath: filePath,
        ),
      );
      onSegmentStatusChanged?.call(segmentIndex, SegmentStatus.ready);

      // 保存会话元数据
      await _cache.saveSessionMeta(session);

      debugPrint('🔊 段落 $segmentIndex 下载完成');
    } catch (e) {
      debugPrint('🔊 段落 $segmentIndex 下载失败: $e');

      session.updateSegment(
        segmentIndex,
        segment.copyWith(
          status: SegmentStatus.error,
          errorMessage: e.toString(),
        ),
      );
      onSegmentStatusChanged?.call(segmentIndex, SegmentStatus.error);
    } finally {
      _downloadTasks.remove(segmentIndex);
    }
  }

  /// 合成单个段落的音频
  Future<List<int>> _synthesizeSegment({
    required TtsSegment segment,
    required String voiceName,
    required double rate,
    String? style,
    int retryCount = 0,
  }) async {
    final currentKey = _currentApiKey;
    if (currentKey == null || currentKey.isEmpty) {
      throw Exception('No API key configured');
    }

    // 构建 SSML
    final ratePct = ((rate - 1.0) * 100).toStringAsFixed(0);
    final rateStr = '${rate >= 1.0 ? '+' : ''}$ratePct%';

    // 优先使用 segment 自带的 SSML，否则回退到简单转义
    final ssml = segment.toFullSsml(
      voiceName: voiceName,
      rate: rateStr,
      style: style,
    );

    // DEBUG: 打印 SSML
    debugPrint('🔊 ════════════════════════════════════════════════════════');
    debugPrint('🔊 段落 ${segment.index} SSML:');
    debugPrint('🔊 hasSsml: ${segment.hasSsml}');
    for (int i = 0; i < ssml.length; i += 500) {
      final end = (i + 500 < ssml.length) ? i + 500 : ssml.length;
      debugPrint('[SSML $i-$end] ${ssml.substring(i, end)}');
    }
    debugPrint('🔊 ════════════════════════════════════════════════════════');

    try {
      final response = await _dio.post<List<int>>(
        _ttsUrl,
        data: ssml,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': currentKey,
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
            'User-Agent': 'CherryViewer',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('TTS API Failed: ${response.statusCode}');
      }

      return response.data!;
    } catch (e) {
      // 如果是配额错误，尝试切换 Key
      if (_switchToNextKey() && retryCount < apiKeys.length) {
        debugPrint('🔊 重试下载...');
        return _synthesizeSegment(
          segment: segment,
          voiceName: voiceName,
          rate: rate,
          style: style,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }

  /// 取消所有下载
  void cancel() {
    _isCancelled = true;
    debugPrint('🔊 取消所有下载任务');
  }

  /// 释放资源
  void dispose() {
    cancel();
    _dio.close();
  }
}

/// 简单的信号量实现
class _Semaphore {
  final int maxCount;
  int _currentCount = 0;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this.maxCount);

  Future<void> acquire() async {
    if (_currentCount < maxCount) {
      _currentCount++;
      return;
    }

    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
    _currentCount++;
  }

  void release() {
    _currentCount--;
    if (_waiters.isNotEmpty) {
      final waiter = _waiters.removeAt(0);
      waiter.complete();
    }
  }
}
