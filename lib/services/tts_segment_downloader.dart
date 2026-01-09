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

/// 预加载配置
class PrefetchConfig {
  /// 目标缓冲字符数（达到此目标后停止预加载）
  /// 按 200字/分钟 计算，1500字 ≈ 7.5 分钟缓冲
  final int targetBufferChars;

  /// 触发阈值字符数（缓冲低于此值时开始补充下载）
  /// 500字 ≈ 2.5 分钟
  final int refillThresholdChars;

  /// 冷启动预加载字符数（首次播放时快速准备）
  /// 800字 ≈ 4 分钟
  final int coldStartChars;

  /// 最大并发下载数
  final int maxConcurrent;

  const PrefetchConfig({
    this.targetBufferChars = 1500,
    this.refillThresholdChars = 500,
    this.coldStartChars = 800,
    this.maxConcurrent = 3,
  });

  /// 默认配置
  static const PrefetchConfig defaultConfig = PrefetchConfig();

  /// 激进预加载（更多缓冲，适合网络不稳定）
  static const PrefetchConfig aggressiveConfig = PrefetchConfig(
    targetBufferChars: 3000,
    refillThresholdChars: 1000,
    coldStartChars: 1500,
    maxConcurrent: 4,
  );

  /// 保守预加载（更少缓冲，节省流量）
  static const PrefetchConfig conservativeConfig = PrefetchConfig(
    targetBufferChars: 800,
    refillThresholdChars: 300,
    coldStartChars: 500,
    maxConcurrent: 2,
  );
}

/// TTS 段落下载器（滑动窗口预加载版）
///
/// 核心设计：
/// 1. **按需下载**：不再一次性下载所有段落
/// 2. **字符计数**：用缓冲字符数（而非段落数）控制预加载量
/// 3. **滑动窗口**：播放位置变化时动态调整下载目标
/// 4. **智能取消**：用户停止播放时取消后续下载
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

  /// 预加载配置
  PrefetchConfig prefetchConfig;

  /// 当前会话
  TtsPlaySession? _currentSession;

  /// 当前播放位置
  int _currentPlayIndex = 0;

  /// 是否已取消
  bool _isCancelled = false;

  /// 是否正在预加载
  bool _isPrefetching = false;

  /// 下载信号量
  late _Semaphore _semaphore;

  /// 进度回调
  void Function(int segmentIndex, SegmentStatus status)? onSegmentStatusChanged;

  /// 缓冲状态变化回调
  void Function(int bufferedChars, int targetChars)? onBufferStatusChanged;

  TtsSegmentDownloader({
    String? apiKey,
    List<String>? apiKeys,
    required this.region,
    int currentKeyIndex = 0,
    this.ssmlConfig = const SsmlConfig(),
    this.prefetchConfig = const PrefetchConfig(),
  })  : apiKeys = apiKeys ?? (apiKey != null ? [apiKey] : []),
        _currentKeyIndex = currentKeyIndex {
    _semaphore = _Semaphore(prefetchConfig.maxConcurrent);
  }

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

  // ========== 公开 API ==========

  /// 开始预加载会话
  ///
  /// 只下载冷启动所需的段落，后续通过 [updatePlayPosition] 触发更多下载
  Future<void> startPrefetch({
    required TtsPlaySession session,
    required String voiceName,
    required double rate,
    String? style,
    int startIndex = 0,
  }) async {
    _currentSession = session;
    _currentPlayIndex = startIndex;
    _isCancelled = false;

    debugPrint('🔊 开始预加载会话: ${session.messageId}, 共 ${session.segments.length} 段');
    debugPrint('🔊 预加载配置: 目标缓冲 ${prefetchConfig.targetBufferChars} 字符, '
        '触发阈值 ${prefetchConfig.refillThresholdChars} 字符');

    // 计算冷启动需要下载的段落
    final segmentsToDownload = _calculateSegmentsToDownload(
      fromIndex: startIndex,
      targetChars: prefetchConfig.coldStartChars,
    );

    debugPrint('🔊 冷启动下载: ${segmentsToDownload.length} 段');

    await _downloadSegments(
      indices: segmentsToDownload,
      voiceName: voiceName,
      rate: rate,
      style: style,
    );

    // 冷启动完成后，检查是否需要继续预加载
    _checkAndContinuePrefetch(voiceName: voiceName, rate: rate, style: style);
  }

  /// 更新播放位置
  ///
  /// 当播放进度变化时调用，触发滑动窗口预加载
  void updatePlayPosition({
    required int currentIndex,
    required String voiceName,
    required double rate,
    String? style,
  }) {
    if (_currentSession == null) return;

    _currentPlayIndex = currentIndex;
    
    // 如果之前被取消了，恢复预加载（用户可能暂停后恢复播放）
    if (_isCancelled) {
      _isCancelled = false;
      debugPrint('🔊 检测到播放位置更新，重新启用预加载');
    }

    // 计算当前缓冲量
    final bufferedChars = _calculateBufferedChars(fromIndex: currentIndex);
    final targetChars = prefetchConfig.targetBufferChars;

    debugPrint('🔊 播放位置更新: $currentIndex, 缓冲: $bufferedChars / $targetChars 字符');

    onBufferStatusChanged?.call(bufferedChars, targetChars);

    // 如果缓冲低于阈值，触发补充下载
    if (bufferedChars < prefetchConfig.refillThresholdChars) {
      debugPrint('🔊 缓冲不足，开始补充下载');
      _checkAndContinuePrefetch(voiceName: voiceName, rate: rate, style: style);
    }
  }

  /// 取消队列中的下载（优雅停止）
  ///
  /// 让正在进行中的下载完成，只取消队列中还没开始的
  void cancelPending() {
    _isCancelled = true;
    debugPrint('🔊 取消队列中的下载任务（进行中的会完成）');
  }

  /// 取消所有下载（硬停止）
  ///
  /// 设置取消标志，所有任务在下一个检查点退出
  void cancelAll() {
    _isCancelled = true;
    _isPrefetching = false;
    debugPrint('🔊 取消所有下载任务');
  }

  /// 恢复预加载（暂停后恢复播放时调用）
  void resume({
    required String voiceName,
    required double rate,
    String? style,
  }) {
    if (_currentSession == null) return;
    
    // 重置取消标志
    _isCancelled = false;
    
    debugPrint('🔊 恢复预加载');
    
    // 检查缓冲并触发预加载
    _checkAndContinuePrefetch(voiceName: voiceName, rate: rate, style: style);
  }

  /// 下载单个段落（公开 API，用于手动重试）
  Future<void> downloadSingleSegment({
    required TtsPlaySession session,
    required int segmentIndex,
    required String voiceName,
    required double rate,
    String? style,
  }) async {
    _currentSession = session;
    await _downloadSegmentWithRetry(
      segmentIndex: segmentIndex,
      voiceName: voiceName,
      rate: rate,
      style: style,
    );
  }

  /// 释放资源
  void dispose() {
    cancelAll();
    _dio.close();
  }

  // ========== 兼容旧 API ==========

  /// 开始下载会话的所有段落（兼容旧代码，内部转为增量预加载）
  @Deprecated('Use startPrefetch instead for better performance')
  Future<void> downloadSession({
    required TtsPlaySession session,
    required String voiceName,
    required double rate,
    String? style,
    int priorityIndex = 0,
  }) async {
    await startPrefetch(
      session: session,
      voiceName: voiceName,
      rate: rate,
      style: style,
      startIndex: priorityIndex,
    );
  }

  // ========== 内部方法 ==========

  /// 计算需要下载的段落索引列表
  ///
  /// 从 [fromIndex] 开始，累计字符数直到达到 [targetChars]
  List<int> _calculateSegmentsToDownload({
    required int fromIndex,
    required int targetChars,
  }) {
    if (_currentSession == null) return [];

    final segments = _currentSession!.segments;
    final result = <int>[];
    int accumulatedChars = 0;

    for (int i = fromIndex; i < segments.length; i++) {
      final segment = segments[i];

      // 跳过已下载的段落（但仍计入缓冲）
      if (segment.status == SegmentStatus.ready) {
        accumulatedChars += segment.text.length;
        continue;
      }

      // 跳过正在下载的段落
      if (segment.status == SegmentStatus.downloading) {
        accumulatedChars += segment.text.length;
        continue;
      }

      // 需要下载的段落
      if (segment.status == SegmentStatus.pending ||
          segment.status == SegmentStatus.error) {
        result.add(i);
        accumulatedChars += segment.text.length;
      }

      // 达到目标字符数，停止
      if (accumulatedChars >= targetChars) {
        break;
      }
    }

    return result;
  }

  /// 计算从指定位置开始已缓冲的字符数
  int _calculateBufferedChars({required int fromIndex}) {
    if (_currentSession == null) return 0;

    final segments = _currentSession!.segments;
    int bufferedChars = 0;

    for (int i = fromIndex; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.status == SegmentStatus.ready) {
        bufferedChars += segment.text.length;
      } else {
        // 遇到未就绪的段落，停止计算
        // （只计算连续已缓冲的部分）
        break;
      }
    }

    return bufferedChars;
  }

  /// 检查并继续预加载
  void _checkAndContinuePrefetch({
    required String voiceName,
    required double rate,
    String? style,
  }) {
    if (_currentSession == null) return;
    if (_isCancelled) return;
    if (_isPrefetching) return;

    final bufferedChars = _calculateBufferedChars(fromIndex: _currentPlayIndex);

    // 如果缓冲已达标，不需要继续下载
    if (bufferedChars >= prefetchConfig.targetBufferChars) {
      debugPrint('🔊 缓冲已达标: $bufferedChars / ${prefetchConfig.targetBufferChars} 字符');
      return;
    }

    // 计算需要补充的字符数
    final neededChars = prefetchConfig.targetBufferChars - bufferedChars;
    final segmentsToDownload = _calculateSegmentsToDownload(
      fromIndex: _currentPlayIndex,
      targetChars: neededChars + bufferedChars, // 总目标
    );

    if (segmentsToDownload.isEmpty) {
      debugPrint('🔊 没有需要下载的段落');
      return;
    }

    debugPrint('🔊 补充下载: ${segmentsToDownload.length} 段');

    _downloadSegments(
      indices: segmentsToDownload,
      voiceName: voiceName,
      rate: rate,
      style: style,
    );
  }

  /// 批量下载段落
  Future<void> _downloadSegments({
    required List<int> indices,
    required String voiceName,
    required double rate,
    String? style,
  }) async {
    if (indices.isEmpty) return;
    if (_isCancelled) return;

    _isPrefetching = true;

    final futures = <Future<void>>[];

    for (final index in indices) {
      if (_isCancelled) break;

      final future = _semaphore.acquire().then((_) async {
        if (_isCancelled) {
          _semaphore.release();
          return;
        }

        try {
          await _downloadSegmentWithRetry(
            segmentIndex: index,
            voiceName: voiceName,
            rate: rate,
            style: style,
          );
        } finally {
          _semaphore.release();
        }
      });

      futures.add(future);
    }

    await Future.wait(futures);

    _isPrefetching = false;

    // 下载完成后，检查是否需要继续预加载
    if (!_isCancelled) {
      _checkAndContinuePrefetch(voiceName: voiceName, rate: rate, style: style);
    }
  }

  /// 内部下载方法（带自动重试）
  Future<void> _downloadSegmentWithRetry({
    required int segmentIndex,
    required String voiceName,
    required double rate,
    String? style,
  }) async {
    if (_currentSession == null) return;
    if (_isCancelled) return;

    final session = _currentSession!;
    if (segmentIndex < 0 || segmentIndex >= session.segments.length) return;

    final segment = session.segments[segmentIndex];

    // 已经就绪，跳过
    if (segment.status == SegmentStatus.ready) return;

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
        debugPrint('🔊 ❌ 失败 SSML内容 [Length: ${ssml.length}]:');
        debugPrint(ssml);

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

    // 检查是否包含可能导致 400 错误的内容
    final hasUnescapedAngleBracket = RegExp(r'<(?!/?(?:speak|voice|prosody|break|emphasis|lang|mstts:|s|p|sub|phoneme)[>\s/])').hasMatch(ssml);
    final hasControlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]').hasMatch(ssml);

    if (hasUnescapedAngleBracket) {
      debugPrint('🔊 ⚠️ 警告: SSML 中可能包含未转义的 HTML/XML 标签!');
    }
    if (hasControlChars) {
      debugPrint('🔊 ⚠️ 警告: SSML 中包含控制字符!');
    }

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
