import 'dart:convert';
import 'package:crypto/crypto.dart';

/// TTS 音频缓存 Key 计算工具
///
/// 基于内容+配置的哈希缓存，实现跨场景复用
class AudioCacheKey {
  /// 生成音频缓存 Key
  ///
  /// 输入：
  /// - [ssml]: SSML 内容（实际发送给 TTS API 的内容，包含停顿、语调等）
  /// - [voice]: 语音名称
  /// - [rate]: 语速（影响合成结果）
  /// - [style]: 风格（可选）
  ///
  /// 输出：32 位十六进制字符串（MD5 完整值）
  ///
  /// 示例：
  /// ```
  /// 段落 "Hello World" + voice=xiaoxiao:
  ///   rate=1.0 → cacheKey: abc123...（缓存文件 1）
  ///   rate=1.5 → cacheKey: def456...（缓存文件 2）
  /// ```
  static String generate({
    required String ssml,
    required String voice,
    required double rate,
    String? style,
  }) {
    // 关键因素：SSML 内容 + 语音 + 语速 + 风格
    // SSML 包含了所有停顿、语调信息，是 TTS 合成的实际输入
    final input = '$ssml|$voice|$rate|${style ?? ''}';
    return md5.convert(utf8.encode(input)).toString(); // 完整 32 位
  }

  /// 获取缓存文件路径
  ///
  /// 使用两级目录分片（前两位），避免单目录文件过多
  /// 例如：audio/ab/abcd1234567890ef.mp3
  static String getFilePath(String basePath, String cacheKey) {
    final prefix = cacheKey.substring(0, 2); // 前两位做目录分片
    return '$basePath/audio/$prefix/$cacheKey.mp3';
  }

  /// 生成内容哈希（16 位，仅用于快速判断内容是否变化）
  ///
  /// 用于会话级别的快速比对，不用于音频缓存
  static String generateContentHash(String text) {
    return md5.convert(utf8.encode(text)).toString().substring(0, 16);
  }
}
