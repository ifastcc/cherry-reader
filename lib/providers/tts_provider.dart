import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_item.dart';
import '../models/tts_settings.dart';
import '../models/tts_segment.dart';
import '../models/tts_play_session.dart';
import '../services/ast_tts_converter.dart';
import '../services/tts_segment_cache.dart';
import '../services/tts_segment_downloader.dart';

enum TtsState { stopped, playing, paused, loading }

class TtsProvider extends ChangeNotifier {
  // 旧的播放列表（保持向后兼容）
  List<TtsItem> _playlist = [];
  int _currentItemIndex = -1;

  // 新的分段播放系统
  TtsPlaySession? _currentSession;
  AstBasedTtsConverter? _astConverter;
  final TtsSegmentCache _cache = TtsSegmentCache();
  TtsSegmentDownloader? _downloader;

  // 播放器
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 状态
  TtsState _playerState = TtsState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;

  // Settings
  TtsSettings _settings = TtsSettings();

  // 操作锁
  bool _isOperating = false;

  TtsProvider() {
    _init();
  }

  // Getters
  List<TtsItem> get playlist => _playlist;
  int get currentIndex => _currentItemIndex;
  TtsItem? get currentItem =>
      _currentItemIndex >= 0 && _currentItemIndex < _playlist.length
          ? _playlist[_currentItemIndex]
          : null;

  TtsPlaySession? get currentSession => _currentSession;
  TtsSegment? get currentSegment => _currentSession?.currentSegment;
  int get currentSegmentIndex => _currentSession?.currentIndex ?? -1;
  int get totalSegments => _currentSession?.segments.length ?? 0;
  double get downloadProgress => _currentSession?.downloadProgress ?? 0;
  bool get isFullyDownloaded => _currentSession?.isFullyDownloaded ?? false;

  TtsState get playerState => _playerState;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  bool get isPlaying => _playerState == TtsState.playing;
  bool get hasValidConfig =>
      _settings.azureApiKeys.isNotEmpty && _settings.azureRegion.isNotEmpty;
  double get rhythmScale => _settings.rhythmScale;
  String get ssmlConfigType => _settings.ssmlConfigType;

  Future<void> _init() async {
    // 加载设置
    final prefs = await SharedPreferences.getInstance();
    final ttsJson = prefs.getString(TtsSettings.prefKey);
    if (ttsJson != null) {
      _settings = TtsSettings.fromJson(jsonDecode(ttsJson));
      _playbackSpeed = _settings.defaultRate;
    }

    // 监听播放器状态
    _audioPlayer.playerStateStream.listen(_handlePlayerState);
    _audioPlayer.durationStream.listen((d) {
      if (d != null) {
        _totalDuration = d;
        // 更新当前段落的时长
        if (_currentSession != null && _currentSession!.currentSegment != null) {
          final seg = _currentSession!.currentSegment!;
          if (seg.duration == null) {
            _currentSession!.updateSegment(
              seg.index,
              seg.copyWith(duration: d),
            );
            _cache.saveSessionMeta(_currentSession!);
          }
        }
        notifyListeners();
      }
    });
    _audioPlayer.positionStream.listen((p) {
      _currentPosition = p;
      notifyListeners();
    });
  }

  void _handlePlayerState(PlayerState state) {
    switch (state.processingState) {
      case ProcessingState.idle:
        if (_playerState != TtsState.stopped) {
          _playerState = TtsState.stopped;
          notifyListeners();
        }
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        if (_playerState != TtsState.paused && _playerState != TtsState.loading) {
          _playerState = TtsState.loading;
          notifyListeners();
        }
        break;
      case ProcessingState.ready:
        if (state.playing) {
          _playerState = TtsState.playing;
        } else if (_playerState == TtsState.playing || _playerState == TtsState.loading) {
          _playerState = TtsState.paused;
        }
        notifyListeners();
        break;
      case ProcessingState.completed:
        _playerState = TtsState.stopped;
        _onSegmentFinished();
        notifyListeners();
        break;
    }
  }

  /// 当前段落播放完成
  Future<void> _onSegmentFinished() async {
    if (_currentSession == null) return;

    // 检查是否有下一段
    if (_currentSession!.hasNext) {
      _currentSession!.currentIndex++;
      _currentSession!.lastPlayedIndex = _currentSession!.currentIndex;
      await _cache.saveSessionMeta(_currentSession!);
      notifyListeners();
      await _playCurrentSegment();
    } else {
      // 全部播放完成
      debugPrint('🎵 全部段落播放完成');
      _currentSession!.currentIndex = 0;
      _currentSession!.lastPlayedIndex = 0;
      await _cache.saveSessionMeta(_currentSession!);
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TtsSettings.prefKey, jsonEncode(_settings.toJson()));
  }

  Future<void> reloadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final ttsJson = prefs.getString(TtsSettings.prefKey);
    if (ttsJson != null) {
      _settings = TtsSettings.fromJson(jsonDecode(ttsJson));
      _playbackSpeed = _settings.defaultRate;
      // 重新创建下载器和转换器
      _downloader = null;
      _astConverter = null;
      notifyListeners();
    }
  }

  /// 创建下载器
  TtsSegmentDownloader _getDownloader() {
    _downloader ??= TtsSegmentDownloader(
      apiKeys: _settings.azureApiKeys,
      region: _settings.azureRegion,
      currentKeyIndex: _settings.currentKeyIndex,
      maxConcurrent: 3,
    );
    _downloader!.onSegmentStatusChanged = (index, status) {
      notifyListeners();
    };
    return _downloader!;
  }

  /// 创建 AST 转换器（基于设置）
  AstBasedTtsConverter _getConverter() {
    if (_astConverter == null) {
      // 根据 ssmlConfigType 选择基础配置
      TtsSsmlConfig baseConfig;
      switch (_settings.ssmlConfigType) {
        case 'fast':
          baseConfig = TtsSsmlConfig.fastConfig;
          break;
        case 'audiobook':
          baseConfig = TtsSsmlConfig.audiobookConfig;
          break;
        case 'relaxed':
          baseConfig = TtsSsmlConfig.relaxedConfig;
          break;
        case 'default':
        case 'natural':
        default:
          baseConfig = TtsSsmlConfig.defaultConfig;
      }

      // 应用用户的节奏倍率
      final config = baseConfig.withRhythmScale(_settings.rhythmScale);

      _astConverter = AstBasedTtsConverter(config: config);
      debugPrint('🎯 创建 AST 转换器: configType=${_settings.ssmlConfigType}, rhythmScale=${_settings.rhythmScale}');
    }
    return _astConverter!;
  }

  // ============ 新的分段播放 API ============

  /// 开始朗读消息
  ///
  /// [messageId] 消息 ID（用于缓存关联）
  /// [text] 要朗读的文本
  /// [title] 标题（用于显示）
  /// [author] 作者（用于显示）
  Future<void> startReading({
    required String messageId,
    required String text,
    String title = 'Untitled',
    String? author,
  }) async {
    if (_isOperating) return;
    _isOperating = true;

    try {
      debugPrint('🎵 开始朗读: $messageId');

      // 刷新设置
      await reloadSettings();

      if (!hasValidConfig) {
        debugPrint('🎵 TTS 未配置');
        return;
      }

      // 停止当前播放
      await _audioPlayer.stop();
      _playerState = TtsState.loading;
      notifyListeners();

      // 生成内容 hash
      final contentHash = TtsPlaySession.generateContentHash(text);
      final settings = TtsSessionSettings(
        voice: _settings.defaultVoiceName,
        rate: _playbackSpeed,
        style: 'general',
      );

      // 检查缓存
      var session = await _cache.getValidSession(
        messageId: messageId,
        contentHash: contentHash,
        settings: settings,
      );

      if (session == null) {
        // 创建新会话（使用 AST 转换器分段并生成 SSML）
        debugPrint('🎵 创建新的播放会话（AST 模式）');
        final segmentsWithSsml = _getConverter().convert(text);

        if (segmentsWithSsml.isEmpty) {
          debugPrint('🎵 文本分段为空');
          _playerState = TtsState.stopped;
          notifyListeners();
          return;
        }

        // 转换为 TtsSegment（带 SSML）
        final segments = segmentsWithSsml.map((s) => TtsSegment(
          index: s.index,
          text: s.plainText,
          ssml: s.ssmlContent,
          startOffset: s.startOffset,
          endOffset: s.endOffset,
        )).toList();

        debugPrint('🎵 AST 分段完成: ${segments.length} 个段落');
        for (var i = 0; i < segments.length; i++) {
          debugPrint('  段落 $i: ${segments[i].text.length} 字符, hasSsml: ${segments[i].hasSsml}');
        }

        session = TtsPlaySession(
          messageId: messageId,
          fullText: text,
          contentHash: contentHash,
          settings: settings,
          segments: segments,
        );

        await _cache.createSession(session);
      } else {
        // 恢复上次播放位置
        session.currentIndex = session.lastPlayedIndex;
        debugPrint('🎵 恢复播放会话，从段落 ${session.currentIndex} 开始');
      }

      _currentSession = session;

      // 更新旧的 playlist（保持 UI 兼容）
      _playlist = [
        TtsItem(
          id: messageId,
          text: text,
          title: title,
          author: author,
        )
      ];
      _currentItemIndex = 0;

      notifyListeners();

      // 开始下载所有段落（后台）
      _startDownloadingAllSegments();

      // 等待当前段落就绪并播放
      await _waitAndPlayCurrentSegment();

    } catch (e) {
      debugPrint('🎵 朗读失败: $e');
      _playerState = TtsState.stopped;
      notifyListeners();
    } finally {
      _isOperating = false;
    }
  }

  /// 开始下载所有段落
  void _startDownloadingAllSegments() {
    if (_currentSession == null) return;

    final downloader = _getDownloader();
    downloader.downloadSession(
      session: _currentSession!,
      voiceName: _settings.defaultVoiceName,
      rate: _playbackSpeed,
      style: 'general',
      priorityIndex: _currentSession!.currentIndex,
    );
  }

  /// 等待当前段落就绪并播放
  Future<void> _waitAndPlayCurrentSegment() async {
    if (_currentSession == null) return;

    final segment = _currentSession!.currentSegment;
    if (segment == null) return;

    // 如果段落已就绪，直接播放
    if (segment.status == SegmentStatus.ready && segment.cachePath != null) {
      await _playCurrentSegment();
      return;
    }

    // 等待段落下载完成
    debugPrint('🎵 等待段落 ${segment.index} 下载...');
    _playerState = TtsState.loading;
    notifyListeners();

    // 轮询等待
    while (_currentSession != null) {
      final currentSeg = _currentSession!.currentSegment;
      if (currentSeg == null) break;

      if (currentSeg.status == SegmentStatus.ready && currentSeg.cachePath != null) {
        await _playCurrentSegment();
        return;
      }

      if (currentSeg.status == SegmentStatus.error) {
        debugPrint('🎵 段落下载失败: ${currentSeg.errorMessage}');
        // 尝试下一段
        if (_currentSession!.hasNext) {
          _currentSession!.currentIndex++;
          notifyListeners();
          continue;
        } else {
          _playerState = TtsState.stopped;
          notifyListeners();
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// 播放当前段落
  Future<void> _playCurrentSegment() async {
    if (_currentSession == null) return;

    final segment = _currentSession!.currentSegment;
    if (segment == null || segment.cachePath == null) {
      debugPrint('🎵 段落不可播放');
      return;
    }

    debugPrint('🎵 播放段落 ${segment.index}: ${segment.cachePath}');

    try {
      await _audioPlayer.setFilePath(segment.cachePath!);
      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('🎵 播放失败: $e');
      // 可能是缓存文件损坏，删除并重试
      try {
        await _cache.clearMessageCache(_currentSession!.messageId);
      } catch (_) {}
      _playerState = TtsState.stopped;
      notifyListeners();
    }
  }

  // ============ 播放控制 ============

  /// 播放/恢复
  Future<void> play() async {
    if (_isOperating) return;

    if (_playerState == TtsState.paused) {
      await _audioPlayer.play();
    } else if (_currentSession != null) {
      await _waitAndPlayCurrentSegment();
    }
  }

  /// 暂停
  Future<void> pause() async {
    await _audioPlayer.pause();
    _playerState = TtsState.paused;
    notifyListeners();
  }

  /// 停止
  Future<void> stop() async {
    _downloader?.cancel();
    await _audioPlayer.stop();
    _currentPosition = Duration.zero;
    _playerState = TtsState.stopped;
    notifyListeners();
  }

  /// 下一段
  Future<void> nextSegment() async {
    if (_currentSession == null || !_currentSession!.hasNext) return;

    await _audioPlayer.stop();
    _currentSession!.currentIndex++;
    _currentSession!.lastPlayedIndex = _currentSession!.currentIndex;
    await _cache.saveSessionMeta(_currentSession!);
    notifyListeners();
    await _waitAndPlayCurrentSegment();
  }

  /// 上一段
  Future<void> previousSegment() async {
    if (_currentSession == null || !_currentSession!.hasPrevious) return;

    await _audioPlayer.stop();
    _currentSession!.currentIndex--;
    _currentSession!.lastPlayedIndex = _currentSession!.currentIndex;
    await _cache.saveSessionMeta(_currentSession!);
    notifyListeners();
    await _waitAndPlayCurrentSegment();
  }

  /// 跳转到指定段落
  Future<void> jumpToSegment(int index) async {
    if (_currentSession == null) return;
    if (index < 0 || index >= _currentSession!.segments.length) return;

    await _audioPlayer.stop();
    _currentSession!.currentIndex = index;
    _currentSession!.lastPlayedIndex = index;
    await _cache.saveSessionMeta(_currentSession!);

    // 如果点击的段落还没下载，优先下载它
    final segment = _currentSession!.segments[index];
    if (segment.status != SegmentStatus.ready) {
      final downloader = _getDownloader();
      await downloader.downloadSingleSegment(
        session: _currentSession!,
        segmentIndex: index,
        voiceName: _settings.defaultVoiceName,
        rate: _playbackSpeed,
      );
    }

    notifyListeners();
    await _waitAndPlayCurrentSegment();
  }

  /// Seek 在当前段落内
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// 设置播放速度
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  // ============ 旧 API 兼容 ============

  /// 设置播放列表（兼容旧 API）
  void setPlaylist(List<TtsItem> items, {int initialIndex = 0}) {
    if (items.isEmpty) return;

    // 使用第一个 item 开始朗读
    final item = items[initialIndex];
    startReading(
      messageId: item.id,
      text: item.text,
      title: item.title,
      author: item.author,
    );
  }

  /// 添加到播放列表（兼容旧 API）
  void addToPlaylist(TtsItem item) {
    // 暂不支持多消息队列，直接播放新的
    startReading(
      messageId: item.id,
      text: item.text,
      title: item.title,
      author: item.author,
    );
  }

  /// 清除播放列表
  void clearPlaylist() {
    stop();
    _playlist.clear();
    _currentItemIndex = -1;
    _currentSession = null;
    notifyListeners();
  }

  /// 下一曲（兼容旧 API）
  Future<void> next() async {
    await nextSegment();
  }

  /// 上一曲（兼容旧 API）
  Future<void> previous() async {
    await previousSegment();
  }

  /// 设置语音
  Future<void> setVoice(String voiceName) async {
    if (_settings.defaultVoiceName == voiceName) return;
    _settings.defaultVoiceName = voiceName;
    await _saveSettings();
    notifyListeners();
  }

  /// 设置节奏倍率 (0.5 ~ 2.0, 1.0 为正常)
  Future<void> setRhythmScale(double scale) async {
    final clampedScale = scale.clamp(0.5, 2.0);
    if (_settings.rhythmScale == clampedScale) return;
    _settings.rhythmScale = clampedScale;
    _astConverter = null; // 重新创建转换器
    await _saveSettings();
    notifyListeners();
  }

  /// 设置 SSML 配置类型
  Future<void> setSsmlConfigType(String configType) async {
    if (_settings.ssmlConfigType == configType) return;
    _settings.ssmlConfigType = configType;
    _astConverter = null; // 重新创建转换器
    await _saveSettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _downloader?.dispose();
    super.dispose();
  }
}
