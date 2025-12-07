import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'tts_segment.dart';

/// TTS 播放会话
///
/// 管理一个消息的所有分段和播放状态
class TtsPlaySession {
  final String messageId;
  final String fullText;
  final String contentHash;     // 原文内容 hash
  final TtsSessionSettings settings;
  final List<TtsSegment> segments;
  final DateTime createdAt;

  int currentIndex;             // 当前播放的段落索引
  int lastPlayedIndex;          // 上次播放到的位置（用于断点续播）
  Duration? totalDuration;      // 总时长（所有段落播放后计算）

  TtsPlaySession({
    required this.messageId,
    required this.fullText,
    required this.contentHash,
    required this.settings,
    required this.segments,
    DateTime? createdAt,
    this.currentIndex = 0,
    this.lastPlayedIndex = 0,
    this.totalDuration,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 生成内容 hash
  static String generateContentHash(String text) {
    return md5.convert(utf8.encode(text)).toString().substring(0, 8);
  }

  /// 从 JSON 创建
  factory TtsPlaySession.fromJson(Map<String, dynamic> json) {
    return TtsPlaySession(
      messageId: json['messageId'] as String,
      fullText: json['fullText'] as String,
      contentHash: json['contentHash'] as String,
      settings: TtsSessionSettings.fromJson(json['settings'] as Map<String, dynamic>),
      segments: (json['segments'] as List<dynamic>)
          .map((e) => TtsSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      currentIndex: json['currentIndex'] as int? ?? 0,
      lastPlayedIndex: json['lastPlayedIndex'] as int? ?? 0,
      totalDuration: json['totalDuration'] != null
          ? Duration(milliseconds: json['totalDuration'] as int)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'fullText': fullText,
      'contentHash': contentHash,
      'settings': settings.toJson(),
      'segments': segments.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'currentIndex': currentIndex,
      'lastPlayedIndex': lastPlayedIndex,
      'totalDuration': totalDuration?.inMilliseconds,
    };
  }

  /// 获取当前段落
  TtsSegment? get currentSegment =>
      currentIndex >= 0 && currentIndex < segments.length
          ? segments[currentIndex]
          : null;

  /// 获取下一个段落
  TtsSegment? get nextSegment =>
      currentIndex + 1 < segments.length
          ? segments[currentIndex + 1]
          : null;

  /// 是否有下一个段落
  bool get hasNext => currentIndex < segments.length - 1;

  /// 是否有上一个段落
  bool get hasPrevious => currentIndex > 0;

  /// 获取已就绪的段落数量
  int get readyCount => segments.where((s) => s.status == SegmentStatus.ready).length;

  /// 获取下载进度 (0.0 - 1.0)
  double get downloadProgress => segments.isEmpty ? 0 : readyCount / segments.length;

  /// 是否全部下载完成
  bool get isFullyDownloaded => readyCount == segments.length;

  /// 计算总时长（从已有 duration 的段落）
  Duration calculateTotalDuration() {
    int totalMs = 0;
    for (final seg in segments) {
      if (seg.duration != null) {
        totalMs += seg.duration!.inMilliseconds;
      }
    }
    return Duration(milliseconds: totalMs);
  }

  /// 更新段落
  void updateSegment(int index, TtsSegment updated) {
    if (index >= 0 && index < segments.length) {
      segments[index] = updated;
    }
  }

  /// 验证设置是否匹配
  bool settingsMatch(TtsSessionSettings other) {
    return settings.voice == other.voice &&
        settings.rate == other.rate &&
        settings.style == other.style;
  }

  @override
  String toString() => 'TtsPlaySession(messageId: $messageId, segments: ${segments.length}, progress: ${(downloadProgress * 100).toStringAsFixed(0)}%)';
}

/// TTS 会话设置
class TtsSessionSettings {
  final String voice;
  final double rate;
  final String style;

  const TtsSessionSettings({
    required this.voice,
    this.rate = 1.0,
    this.style = 'general',
  });

  factory TtsSessionSettings.fromJson(Map<String, dynamic> json) {
    return TtsSessionSettings(
      voice: json['voice'] as String,
      rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
      style: json['style'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice': voice,
      'rate': rate,
      'style': style,
    };
  }

  /// 生成设置 hash
  String get hash => md5.convert(utf8.encode('$voice|$rate|$style')).toString().substring(0, 8);
}
