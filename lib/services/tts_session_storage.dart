import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/tts_play_session.dart';
import '../models/tts_segment.dart';
import '../utils/audio_cache_key.dart';
import 'tts_audio_cache.dart';

/// TTS 会话状态存储
///
/// 职责：
/// 1. 存储和恢复播放会话状态（播放进度、段落映射）
/// 2. 验证会话有效性（内容是否变化、设置是否匹配）
/// 3. 与 TtsAudioCache 配合，恢复段落的缓存路径
///
/// 存储结构：
/// ```
/// tts_cache/
/// └── sessions/
///     └── msg_{id}.json
/// ```
class TtsSessionStorage {
  static final TtsSessionStorage _instance = TtsSessionStorage._internal();

  factory TtsSessionStorage() => _instance;

  TtsSessionStorage._internal();

  String? _basePath;
  final TtsAudioCache _audioCache = TtsAudioCache();

  /// 获取会话存储目录
  Future<String> get basePath async {
    if (_basePath != null) return _basePath!;

    final appDir = await getApplicationDocumentsDirectory();
    final sessionDir = Directory(path.join(appDir.path, 'tts_cache', 'sessions'));
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
    }
    _basePath = sessionDir.path;
    return _basePath!;
  }

  /// 获取会话文件路径
  Future<String> _getSessionPath(String sessionId) async {
    final base = await basePath;
    final safeId = sessionId.replaceAll(RegExp(r'[^\w-]'), '_');
    return path.join(base, 'msg_$safeId.json');
  }

  /// 获取有效的会话
  ///
  /// 验证：
  /// 1. 会话文件存在
  /// 2. 内容哈希匹配
  /// 3. 设置匹配
  /// 4. 恢复段落的缓存路径
  Future<TtsPlaySession?> getValidSession({
    required String sessionId,
    required String contentHash,
    required TtsSessionSettings settings,
  }) async {
    try {
      final sessionPath = await _getSessionPath(sessionId);
      final sessionFile = File(sessionPath);

      if (!await sessionFile.exists()) {
        debugPrint('🔊 会话不存在: $sessionId');
        return null;
      }

      final jsonStr = await sessionFile.readAsString();
      final session = TtsPlaySession.fromJson(jsonDecode(jsonStr));

      // 验证内容哈希
      if (session.contentHash != contentHash) {
        debugPrint('🔊 内容已变化，清除旧会话: $sessionId');
        await deleteSession(sessionId);
        return null;
      }

      // 验证设置
      if (!session.settingsMatch(settings)) {
        debugPrint('🔊 设置已变化，清除旧会话: $sessionId');
        await deleteSession(sessionId);
        return null;
      }

      // 恢复段落的缓存路径（从全局缓存池查找）
      await _restoreSegmentCachePaths(session, settings);

      debugPrint('🔊 会话有效: $sessionId, ${session.readyCount}/${session.segments.length} 段就绪');
      return session;
    } catch (e) {
      debugPrint('🔊 读取会话失败: $e');
      return null;
    }
  }

  /// 恢复段落的缓存路径
  ///
  /// 对于每个段落：
  /// 1. 如果有 audioCacheKey 且缓存存在 → ready
  /// 2. 否则（包括 error 状态）→ pending，允许重试
  Future<void> _restoreSegmentCachePaths(
    TtsPlaySession session,
    TtsSessionSettings settings,
  ) async {
    int restoredCount = 0;
    int resetCount = 0;

    for (var i = 0; i < session.segments.length; i++) {
      final segment = session.segments[i];

      // 如果段落有 audioCacheKey，从全局缓存查找
      if (segment.audioCacheKey != null) {
        final cachedPath = await _audioCache.getCachedPath(segment.audioCacheKey!);
        if (cachedPath != null) {
          session.updateSegment(
            i,
            segment.copyWith(
              status: SegmentStatus.ready,
              cachePath: cachedPath,
              errorMessage: null, // 清除旧的错误信息
            ),
          );
          restoredCount++;
          continue;
        }
      }

      // 没有缓存 Key、缓存文件丢失、或之前是 error 状态 → 重置为 pending
      // 这样可以重新下载
      if (segment.status != SegmentStatus.pending) {
        session.updateSegment(
          i,
          segment.copyWith(
            status: SegmentStatus.pending,
            cachePath: null,
            errorMessage: null,
          ),
        );
        resetCount++;
      }
    }

    debugPrint('🔊 恢复段落状态: $restoredCount 个从缓存恢复, $resetCount 个重置为待下载');
  }

  /// 保存会话
  Future<void> saveSession(TtsPlaySession session) async {
    try {
      final sessionPath = await _getSessionPath(session.messageId);
      final sessionFile = File(sessionPath);
      await sessionFile.writeAsString(jsonEncode(session.toJson()));
      debugPrint('🔊 会话已保存: ${session.messageId}');
    } catch (e) {
      debugPrint('🔊 保存会话失败: $e');
    }
  }

  /// 删除会话
  Future<void> deleteSession(String sessionId) async {
    try {
      final sessionPath = await _getSessionPath(sessionId);
      final sessionFile = File(sessionPath);
      if (await sessionFile.exists()) {
        await sessionFile.delete();
        debugPrint('🔊 会话已删除: $sessionId');
      }
    } catch (e) {
      debugPrint('🔊 删除会话失败: $e');
    }
  }

  /// 清除所有会话
  Future<void> clearAllSessions() async {
    try {
      final base = await basePath;
      final dir = Directory(base);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
        debugPrint('🔊 已清除所有会话');
      }
    } catch (e) {
      debugPrint('🔊 清除会话失败: $e');
    }
  }

  /// 获取所有会话 ID
  Future<List<String>> getAllSessionIds() async {
    try {
      final base = await basePath;
      final dir = Directory(base);
      if (!await dir.exists()) return [];

      final ids = <String>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final name = path.basenameWithoutExtension(entity.path);
          if (name.startsWith('msg_')) {
            ids.add(name.substring(4)); // 移除 'msg_' 前缀
          }
        }
      }
      return ids;
    } catch (e) {
      debugPrint('🔊 获取会话列表失败: $e');
      return [];
    }
  }
}
