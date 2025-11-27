import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_item.dart';
import '../models/tts_settings.dart';
import '../services/azure_tts_service.dart';

enum TtsState { stopped, playing, paused, loading }

class TtsProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<TtsItem> _playlist = [];
  int _currentIndex = -1;
  TtsState _playerState = TtsState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  
  // Settings cache
  TtsSettings _settings = TtsSettings();

  TtsProvider() {
    _init();
  }

  List<TtsItem> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  TtsItem? get currentItem => _currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;
  TtsState get playerState => _playerState;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  bool get isPlaying => _playerState == TtsState.playing;
  bool get hasValidConfig => _settings.azureApiKeys.isNotEmpty && _settings.azureRegion.isNotEmpty;

  // Operation lock to prevent race conditions
  bool _isOperating = false;

  Future<void> _init() async {
    // Load settings
    final prefs = await SharedPreferences.getInstance();
    final ttsJson = prefs.getString(TtsSettings.prefKey);
    if (ttsJson != null) {
      _settings = TtsSettings.fromJson(jsonDecode(ttsJson));
      _playbackSpeed = _settings.defaultRate;
    }

    // Listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _playerState = TtsState.playing;
          break;
        case PlayerState.paused:
          _playerState = TtsState.paused;
          break;
        case PlayerState.stopped:
        case PlayerState.completed:
          _playerState = TtsState.stopped;
          if (state == PlayerState.completed) {
            _onTrackFinished();
          }
          break;
        default:
          break;
      }
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((d) {
      _totalDuration = d;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((p) {
      _currentPosition = p;
      notifyListeners();
    });
  }

  /// 保存 TTS 设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TtsSettings.prefKey, jsonEncode(_settings.toJson()));
  }

  Future<void> _onTrackFinished() async {
    if (_currentIndex < _playlist.length - 1) {
      await next();
    } else {
      // End of playlist
      _currentIndex = -1;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      notifyListeners();
    }
  }

  // Playlist Management

  void addToPlaylist(TtsItem item) {
    _playlist.add(item);
    notifyListeners();
    // If nothing is playing, start playing this? Maybe not automatically unless requested.
  }

  void clearPlaylist() {
    _playlist.clear();
    stop();
    _currentIndex = -1;
    notifyListeners();
  }
  
  void setPlaylist(List<TtsItem> items, {int initialIndex = 0}) {
    _playlist = items;
    _currentIndex = initialIndex;
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      play();
    } else {
      stop();
    }
    notifyListeners();
  }

  // Playback Control

  Future<void> play() async {
    if (_isOperating) return;
    _isOperating = true;

    try {
      if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
        if (_playlist.isNotEmpty) {
          _currentIndex = 0;
        } else {
          return;
        }
      }

      final item = _playlist[_currentIndex];
      
      // Check if we are just resuming
      if (_playerState == TtsState.paused) {
        await _audioPlayer.resume();
        return;
      }

      _playerState = TtsState.loading;
      notifyListeners();

      // Refresh settings in case they changed
      final prefs = await SharedPreferences.getInstance();
      final ttsJson = prefs.getString(TtsSettings.prefKey);
      if (ttsJson != null) {
        _settings = TtsSettings.fromJson(jsonDecode(ttsJson));
      }

      if (_settings.azureApiKeys.isEmpty || _settings.azureRegion.isEmpty) {
        _playerState = TtsState.stopped;
        notifyListeners();
        // Should notify UI about missing config?
        // For now, we just stop.
        return;
      }

      final service = AzureTtsService(
        apiKeys: _settings.azureApiKeys,
        currentKeyIndex: _settings.currentKeyIndex,
        region: _settings.azureRegion,
      );

      final audioPath = await service.synthesize(
        text: item.text,
        voiceName: item.voiceName ?? _settings.defaultVoiceName,
        style: item.style ?? 'general',
        rate: _playbackSpeed,
        messageId: item.id, // Pass message ID for caching
      );

      // 如果服务切换了Key，保存新的索引
      if (service.currentKeyIndex != _settings.currentKeyIndex) {
        _settings.currentKeyIndex = service.currentKeyIndex;
        await _saveSettings();
      }

      await _audioPlayer.stop(); // Ensure stopped before setting new source
      await _audioPlayer.setSourceDeviceFile(audioPath);
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      await _audioPlayer.resume(); // resume() acts as play() for source
      
    } catch (e) {
      debugPrint('Error playing TTS: $e');
      _playerState = TtsState.stopped;
      notifyListeners();
    } finally {
      _isOperating = false;
    }
  }

  Future<void> pause() async {
    if (_isOperating) return;
    _isOperating = true;
    try {
      await _audioPlayer.pause();
    } finally {
      _isOperating = false;
    }
  }

  Future<void> stop() async {
    if (_isOperating) return;
    _isOperating = true;
    try {
      await _audioPlayer.stop();
      _currentPosition = Duration.zero;
      notifyListeners();
    } finally {
      _isOperating = false;
    }
  }

  Future<void> next() async {
    if (_isOperating) return;
    // Don't set _isOperating here because we call stop() and play() which handle it.
    // But we should prevent re-entry to next() itself?
    // Actually, if we just await, it should be fine.
    // But play() checks _isOperating. So if we set it here, play() will fail.
    // So we need to be careful.
    
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      // We can't use public stop() and play() if we lock here.
      // But if we don't lock here, user can spam next().
      
      // Let's just rely on the UI disabling buttons or the fact that play/stop are locked.
      // If user spams next, the first one will run. The second one might find _isOperating=true inside stop/play and return.
      // That's acceptable.
      
      await _audioPlayer.stop(); // Use internal player directly? No, use public to update state.
      // Actually, let's just call the methods.
      // If play() returns early because of lock, that's fine.
      
      // Better approach:
      // If we are already operating, ignore the request.
      
      // But wait, if I call stop() then play(), stop() will lock, finish, unlock. Then play() locks, finishes, unlocks.
      // So it works sequentially.
      // The issue is if next() is called TWICE rapidly.
      // 1. next() -> stop() (locks)
      // 2. next() -> stop() (sees lock, returns) -> play() (sees lock, returns)
      // So the second next() effectively does nothing. That is CORRECT behavior for spam protection.
      
      await stop(); 
      await play(); 
    }
  }

  Future<void> previous() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await stop();
      await play();
    }
  }
  
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setPlaybackRate(speed);
    notifyListeners();
  }

  /// 设置默认语音并保存
  Future<void> setVoice(String voiceName) async {
    if (_settings.defaultVoiceName == voiceName) return;
    
    _settings.defaultVoiceName = voiceName;
    await _saveSettings();
    notifyListeners();
  }
}
