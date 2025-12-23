import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/tts_play_session.dart';
import '../models/tts_segment.dart';
import '../utils/audio_cache_key.dart';
import '../utils/markdown_to_ssml_converter.dart';
import 'tts_audio_cache.dart';
import 'tts_session_storage.dart';

/// 下载重试配置
class DownloadRetryConfig {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);
  static const double backoffMultiplier = 2.0;

  /// 计算重试延迟（指数退避）
  static Duration getDelay(int retryCount) {
    return initialDelay * pow(backoffMultiplier, retryCount).toInt();
  }

  /// 判断是否可重试的错误
  static bool isRetryable(dynamic error) {
    if (error is DioException) {
      // 网络超时、连接错误可重试
      if ([
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      ].contains(error.type)) {
        return true;
      }
      // 5xx 服务器错误可重试
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return true;
      }
    }
    return false;
  }
}

/// TTS 段落下载器
///
/// 负责并发下载段落音频，支持：
/// - 全局缓存池（跨场景复用）
/// - 自动重试（3 次，指数退避）
/// - 优先级调度
class TtsSegmentDownloader {
  final List<String> apiKeys;
  int _currentKeyIndex;
  final String region;
  final Dio _dio = Dio();

  // 使用新的全局缓存
  final TtsAudioCache _audioCache = TtsAudioCache();
  final TtsSessionStorage _sessionStorage = TtsSessionStorage();

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
          await _downloadSegmentWithRetry(
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

  /// 下载单个段落（公开 API，用于手动重试）
  Future<void> downloadSingleSegment({
    required TtsPlaySession session,
    required int segmentIndex,
    required String voiceName,
    required double rate,
    String? style,
  }) async {
    await _downloadSegmentWithRetry(
      session: session,
      segmentIndex: segmentIndex,
      voiceName: voiceName,
      rate: rate,
      style: style,
    );
  }

  /// 内部下载方法（带自动重试）
  Future<void> _downloadSegmentWithRetry({
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

    // 构建 SSML 和缓存 Key
    final ratePct = ((rate - 1.0) * 100).toStringAsFixed(0);
    final rateStr = '${rate >= 1.0 ? '+' : ''}$ratePct%';
    final ssml = segment.toFullSsml(
      voiceName: voiceName,
      rate: rateStr,
      style: style,
    );

    // 生成全局缓存 Key
    final cacheKey = AudioCacheKey.generate(
      ssml: ssml,
      voice: voiceName,
      rate: rate,
      style: style,
    );

    // 1. 先检查全局缓存
    final cachedPath = await _audioCache.getCachedPath(cacheKey);
    if (cachedPath != null) {
      // 缓存命中！
      session.updateSegment(
        segmentIndex,
        segment.copyWith(
          status: SegmentStatus.ready,
          cachePath: cachedPath,
          audioCacheKey: cacheKey,
          retryCount: 0,
          errorMessage: null,
        ),
      );
      onSegmentStatusChanged?.call(segmentIndex, SegmentStatus.ready);
      await _sessionStorage.saveSession(session);
      debugPrint('🔊 段落 $segmentIndex 缓存命中');
      return;
    }

    // 2. 开始下载（带重试）
    int retryCount = 0;

    while (retryCount <= DownloadRetryConfig.maxRetries) {
      if (_isCancelled) return;

      try {
        // 更新状态为下载中
        session.updateSegment(
          segmentIndex,
          segment.copyWith(
            status: SegmentStatus.downloading,
            retryCount: retryCount,
          ),
        );
        onSegmentStatusChanged?.call(segmentIndex, SegmentStatus.downloading);

        debugPrint('🔊 开始下载段落 $segmentIndex: ${segment.text.length} 字符${retryCount > 0 ? ' (重试 $retryCount/${DownloadRetryConfig.maxRetries})' : ''}');

        // 下载音频
        final audioData = await _synthesizeSegment(
          ssml: ssml,
          voiceName: voiceName,
        );

        if (_isCancelled) return;

        // 保存到全局缓存
        final filePath = await _audioCache.saveAudio(cacheKey, audioData);

        // 更新段落状态
        session.updateSegment(
          segmentIndex,
          segment.copyWith(
            status: SegmentStatus.ready,
            cachePath: filePath,
            audioCacheKey: cacheKey,
            retryCount: 0,
            errorMessage: null,
          ),
        );
        onSegmentStatusChanged?.call(segmentIndex, SegmentStatus.ready);

        // 保存会话状态
        await _sessionStorage.saveSession(session);

        debugPrint('🔊 段落 $segmentIndex 下载完成');
        return;

      } catch (e) {
        debugPrint('🔊 段落 $segmentIndex 下载失败: $e');

        // 判断是否可重试
        if (DownloadRetryConfig.isRetryable(e) &&
            retryCount < DownloadRetryConfig.maxRetries) {
          retryCount++;
          final delay = DownloadRetryConfig.getDelay(retryCount);
          debugPrint('🔊 ${delay.inSeconds}秒后重试...');
          await Future.delayed(delay);
          continue;
        }

        // 不可重试或已达最大重试次数
        session.updateSegment(
          segmentIndex,
          segment.copyWith(
            status: SegmentStatus.error,
            errorMessage: e.toString(),
            retryCount: retryCount,
            lastErrorTime: DateTime.now(),
          ),
        );
        onSegmentStatusChanged?.call(segmentIndex, SegmentStatus.error);
        await _sessionStorage.saveSession(session);
        return;
      }
    }
  }

  /// 合成单个段落的音频
  Future<List<int>> _synthesizeSegment({
    required String ssml,
    required String voiceName,
    int apiKeyRetryCount = 0,
  }) async {
    final currentKey = _currentApiKey;
    if (currentKey == null || currentKey.isEmpty) {
      throw Exception('No API key configured');
    }

    // DEBUG: 打印 SSML（详细调试模式）
    debugPrint('🔊 ════════════════════════════════════════════════════════');
    debugPrint('🔊 TTS 请求详情:');
    debugPrint('🔊   Voice: $voiceName');
    debugPrint('🔊   SSML 长度: ${ssml.length} 字符');

    // 检查是否包含可能导致 400 错误的内容
    final hasUnescapedAngleBracket = RegExp(r'<(?!/?(?:speak|voice|prosody|break|emphasis|lang|mstts:|s|p|sub|phoneme)[>\s/])').hasMatch(ssml);
    final hasControlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]').hasMatch(ssml);

    if (hasUnescapedAngleBracket) {
      debugPrint('🔊 ⚠️ 警告: SSML 中可能包含未转义的 HTML/XML 标签!');
    }
    if (hasControlChars) {
      debugPrint('🔊 ⚠️ 警告: SSML 中包含控制字符!');
    }

    // 打印 SSML 内容（分段显示）
    debugPrint('🔊 SSML 内容:');
    for (int i = 0; i < ssml.length; i += 500) {
      final end = (i + 500 < ssml.length) ? i + 500 : ssml.length;
      debugPrint('[SSML $i-$end] ${ssml.substring(i, end)}');
    }
    debugPrint('🔊 ═════════════���══════════════════════════════════════════');

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
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('TTS API Failed: ${response.statusCode}');
      }

      return response.data!;
    } on DioException catch (e) {
      // 如果是 401/403，可能是 API Key 问题，尝试切换
      final statusCode = e.response?.statusCode;
      if ((statusCode == 401 || statusCode == 403 || statusCode == 429) &&
          _switchToNextKey() &&
          apiKeyRetryCount < apiKeys.length) {
        debugPrint('🔊 API Key 问题，切换后重试...');
        return _synthesizeSegment(
          ssml: ssml,
          voiceName: voiceName,
          apiKeyRetryCount: apiKeyRetryCount + 1,
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
