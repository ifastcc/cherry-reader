import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart' as md;

/// Isolate 预解析结果
/// 
/// 只包含可序列化数据，不包含 Widget（Widget 需要在主线程构建）
class MarkdownPreParseData {
  /// 纯文本内容
  final String plainText;
  
  /// Block 预解析信息列表
  final List<BlockPreParseData> blocks;
  
  /// 预估总高度（用于骨架屏）
  final double estimatedHeight;
  
  /// 原始 Markdown 内容的 hashCode（用于缓存验证）
  final int contentHash;

  const MarkdownPreParseData({
    required this.plainText,
    required this.blocks,
    required this.estimatedHeight,
    required this.contentHash,
  });
  
  /// 空结果
  static const empty = MarkdownPreParseData(
    plainText: '',
    blocks: [],
    estimatedHeight: 0,
    contentHash: 0,
  );
}

/// Block 预解析信息
class BlockPreParseData {
  /// Block 类型 (h1, h2, p, code, ul, ol, blockquote, etc.)
  final String type;
  
  /// Block 的纯文本内容
  final String text;
  
  /// 预估高度（像素）
  final double estimatedHeight;
  
  /// 在纯文本中的起始偏移
  final int globalStart;
  
  /// 在纯文本中的结束偏移
  final int globalEnd;

  const BlockPreParseData({
    required this.type,
    required this.text,
    required this.estimatedHeight,
    required this.globalStart,
    required this.globalEnd,
  });
}

/// Markdown Isolate 解析器
/// 
/// 将耗时的 Markdown 解析工作移到后台 Isolate，
/// 避免阻塞主线程，提升页面响应速度。
/// 
/// 注意：Widget 构建仍在主线程进行（需要 BuildContext），
/// 但基于预解析数据可以快速完成。
class MarkdownIsolateParser {
  static final instance = MarkdownIsolateParser._();
  MarkdownIsolateParser._();
  
  /// 缓存：避免重复解析相同内容
  final Map<int, MarkdownPreParseData> _cache = {};
  static const int _maxCacheSize = 100;
  
  /// 在后台 Isolate 解析 Markdown
  /// 
  /// 返回预解析数据，可用于：
  /// - 估算内容高度（骨架屏）
  /// - 快速获取纯文本（搜索）
  /// - 加速主线程 Widget 构建
  Future<MarkdownPreParseData> parseInBackground(String markdown) async {
    if (markdown.isEmpty) {
      return MarkdownPreParseData.empty;
    }
    
    final hash = markdown.hashCode;
    
    // 检查缓存
    if (_cache.containsKey(hash)) {
      return _cache[hash]!;
    }
    
    // 使用 compute() 在后台线程解析
    final result = await compute(_parseMarkdownIsolate, markdown);
    
    // 存入缓存
    _putCache(hash, result);
    
    return result;
  }
  
  /// 批量预解析（用于页面加载后预热）
  /// 
  /// [contents] 是 messageId -> markdown 的映射
  Future<Map<String, MarkdownPreParseData>> batchPreParse(
    Map<String, String> contents,
  ) async {
    final results = <String, MarkdownPreParseData>{};
    
    // 分批处理，每批最多 5 个，避免内存峰值
    final entries = contents.entries.toList();
    const batchSize = 5;
    
    for (var i = 0; i < entries.length; i += batchSize) {
      final batch = entries.skip(i).take(batchSize);
      
      // 并行解析当前批次
      final futures = batch.map((e) async {
        final data = await parseInBackground(e.value);
        return MapEntry(e.key, data);
      });
      
      final batchResults = await Future.wait(futures);
      results.addEntries(batchResults);
    }
    
    return results;
  }
  
  /// 清除缓存
  void clearCache() {
    _cache.clear();
  }
  
  /// 缓存管理
  void _putCache(int hash, MarkdownPreParseData data) {
    // LRU 淘汰
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[hash] = data;
  }
}

/// Isolate 入口函数（必须是顶层函数或静态方法）
MarkdownPreParseData _parseMarkdownIsolate(String markdown) {
  final blocks = <BlockPreParseData>[];
  final plainTextBuffer = StringBuffer();
  var currentOffset = 0;
  double totalHeight = 0;
  
  // 解析 Markdown AST
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  
  final lines = markdown.split(RegExp(r'\r?\n'));
  final nodes = document.parseLines(lines);
  
  // 遍历节点，提取 Block 信息
  for (final node in nodes) {
    final blockData = _extractBlockData(node, currentOffset);
    if (blockData != null) {
      blocks.add(blockData);
      plainTextBuffer.write(blockData.text);
      if (blockData.text.isNotEmpty && !blockData.text.endsWith('\n')) {
        plainTextBuffer.write('\n');
      }
      currentOffset = plainTextBuffer.length;
      totalHeight += blockData.estimatedHeight;
    }
  }
  
  return MarkdownPreParseData(
    plainText: plainTextBuffer.toString(),
    blocks: blocks,
    estimatedHeight: totalHeight,
    contentHash: markdown.hashCode,
  );
}

/// 提取单个节点的 Block 信息
BlockPreParseData? _extractBlockData(md.Node node, int currentOffset) {
  if (node is md.Element) {
    final type = node.tag;
    final text = _extractNodeText(node);
    final height = _estimateBlockHeight(type, text);
    
    return BlockPreParseData(
      type: type,
      text: text,
      estimatedHeight: height,
      globalStart: currentOffset,
      globalEnd: currentOffset + text.length,
    );
  } else if (node is md.Text) {
    final text = node.textContent;
    if (text.trim().isEmpty) return null;
    
    return BlockPreParseData(
      type: 'p',
      text: text,
      estimatedHeight: _estimateBlockHeight('p', text),
      globalStart: currentOffset,
      globalEnd: currentOffset + text.length,
    );
  }
  return null;
}

/// 递归提取节点纯文本
String _extractNodeText(md.Node node) {
  if (node is md.Text) {
    return node.textContent;
  } else if (node is md.Element) {
    final buffer = StringBuffer();
    for (final child in node.children ?? <md.Node>[]) {
      buffer.write(_extractNodeText(child));
    }
    // 某些块级元素需要换行
    if (['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'br'].contains(node.tag)) {
      buffer.write('\n');
    }
    return buffer.toString();
  }
  return '';
}

/// 估算 Block 高度
/// 
/// 基于内容类型和长度进行启发式估算
double _estimateBlockHeight(String type, String text) {
  const lineHeight = 24.0;  // 基础行高
  const padding = 16.0;     // 块间距
  
  // 计算文本行数（假设每行约 40 个字符）
  final charCount = text.length;
  final estimatedLines = (charCount / 40).ceil().clamp(1, 100);
  
  switch (type) {
    case 'h1':
      return 40.0 + padding;
    case 'h2':
      return 34.0 + padding;
    case 'h3':
      return 28.0 + padding;
    case 'h4':
    case 'h5':
    case 'h6':
      return 24.0 + padding;
    case 'pre':
    case 'code':
      // 代码块：固定行高 + 内边距
      return estimatedLines * 20.0 + 32.0;
    case 'blockquote':
      return estimatedLines * lineHeight + 24.0;
    case 'ul':
    case 'ol':
      // 列表：每项一行
      final itemCount = '\n'.allMatches(text).length + 1;
      return itemCount * lineHeight + padding;
    case 'table':
      // 表格：估算行数
      final rowCount = '\n'.allMatches(text).length + 1;
      return rowCount * 32.0 + 16.0;
    case 'hr':
      return 24.0;
    default:
      // 段落
      return estimatedLines * lineHeight + padding / 2;
  }
}
