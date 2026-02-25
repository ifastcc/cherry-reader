import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class TtsCacheManager {
  static final TtsCacheManager _instance = TtsCacheManager._internal();
  static const int defaultMaxSizeMB = 500;

  factory TtsCacheManager() {
    return _instance;
  }

  TtsCacheManager._internal();

  Future<String> get _cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final ttsDir = Directory(path.join(appDir.path, 'tts_cache'));
    if (!await ttsDir.exists()) {
      await ttsDir.create(recursive: true);
    }
    return ttsDir.path;
  }

  String _generateFileName({
    required String text,
    required String voiceName,
    required String style,
    required double rate,
    required double pitch,
    String? messageId,
  }) {
    if (messageId != null && messageId.isNotEmpty) {
      // 如果提供了 messageId，直接使用它作为文件名（加前缀防止冲突）
      // 这样即使文本内容变化，只要 ID 不变，仍然可以关联（或者反过来，如果内容变了，ID不变，会读旧的？
      // 用户需求是：即使数据更新也有个id可以关联起来。
      // 通常意味着：ID 对应唯一的音频。如果内容变了，ID 应该变？或者 ID 是持久的？
      // 如果内容变了但 ID 没变，使用旧音频可能不匹配。
      // 但用户特别提到“做好缓存---看能不能与消息的id关联起来”，可能是为了避免重复生成。
      // 让我们混合一下：使用 ID + 内容哈希？或者只用 ID？
      // 用户说 "就像是标注那样即使数据更新也有个id可以关联起来"，这暗示 ID 是稳定的 key。
      // 为了安全起见，我们还是应该包含内容的 hash，或者至少检查内容是否一致？
      // 但为了响应用户 "与消息的id关联" 的请求，我们将优先使用 ID。
      // 为了避免内容变更导致读错，我们可以把 content hash 作为文件名的一部分，或者只用 ID。
      // 考虑到 TTS 生成成本，如果 ID 相同但内容不同，应该重新生成。
      // 所以文件名应该是: msg_<id>_<content_hash>.mp3
      // 这样既利用了 ID 方便查找（如果我们需要按 ID 查找），又能处理内容变更。
      // 但 `getFile` 时我们通常知道 ID 和 Content。
      // 简化起见，用户可能只是希望文件名可读性好一点，或者缓存结构清晰一点。
      // 让我们使用: msg_{id}_{content_hash}.mp3
      final contentHash = md5.convert(utf8.encode('$text|$voiceName|$style|$rate|$pitch')).toString().substring(0, 8);
      // 处理 ID 中的非法字符
      final safeId = messageId.replaceAll(RegExp(r'[^\w-]'), '_');
      return 'msg_${safeId}_$contentHash.mp3';
    }
    
    final content = '$text|$voiceName|$style|$rate|$pitch';
    final digest = md5.convert(utf8.encode(content));
    return '$digest.mp3';
  }

  Future<File?> getFile({
    required String text,
    required String voiceName,
    String style = 'general',
    double rate = 1.0,
    double pitch = 1.0,
    String? messageId,
  }) async {
    final dir = await _cacheDir;
    final fileName = _generateFileName(
      text: text,
      voiceName: voiceName,
      style: style,
      rate: rate,
      pitch: pitch,
      messageId: messageId,
    );
    final file = File(path.join(dir, fileName));
    
    if (await file.exists()) {
      try {
        await file.setLastModified(DateTime.now());
      } catch (_) {}
      return file;
    }
    return null;
  }

  Future<File> saveFile({
    required List<int> data,
    required String text,
    required String voiceName,
    String style = 'general',
    double rate = 1.0,
    double pitch = 1.0,
    String? messageId,
  }) async {
    final dir = await _cacheDir;
    final fileName = _generateFileName(
      text: text,
      voiceName: voiceName,
      style: style,
      rate: rate,
      pitch: pitch,
      messageId: messageId,
    );
    final file = File(path.join(dir, fileName));
    final saved = await file.writeAsBytes(data);
    await cleanup(maxSizeMB: defaultMaxSizeMB);
    return saved;
  }

  Future<void> cleanup({int maxSizeMB = defaultMaxSizeMB}) async {
    final dir = await _cacheDir;
    final directory = Directory(dir);
    if (!await directory.exists()) return;

    final entries = <({File file, int size, DateTime modified})>[];
    int totalSize = 0;

    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        final stat = await entity.stat();
        totalSize += stat.size;
        entries.add((file: entity, size: stat.size, modified: stat.modified));
      } catch (_) {}
    }

    final maxBytes = maxSizeMB * 1024 * 1024;
    if (totalSize <= maxBytes) return;

    entries.sort((a, b) => a.modified.compareTo(b.modified));
    final targetBytes = (maxBytes * 0.8).toInt();

    for (final entry in entries) {
      if (totalSize <= targetBytes) break;
      try {
        await entry.file.delete();
        totalSize -= entry.size;
      } catch (_) {}
    }
  }

  Future<void> clearCache() async {
    final dir = await _cacheDir;
    final directory = Directory(dir);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<int> getCacheSize() async {
    final dir = await _cacheDir;
    final directory = Directory(dir);
    if (!await directory.exists()) return 0;
    
    int totalSize = 0;
    try {
      await for (final file in directory.list(recursive: true, followLinks: false)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    } catch (e) {
      print('Error calculating cache size: $e');
    }
    return totalSize;
  }
}
