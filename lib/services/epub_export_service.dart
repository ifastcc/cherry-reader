import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:archive/archive.dart' show Deflate;

/// A minimal, EPUB-compliant ZIP encoder.
/// 
/// The standard `archive` package sets the "Data Descriptor" flag (bit 3)
/// which violates EPUB/OCF specification and causes Apple Books/WeRead to reject files.
/// 
/// This encoder manually constructs ZIP bytes to ensure:
/// 1. mimetype is first and uncompressed (STORE method)
/// 2. No Data Descriptor (bit 3 = 0)
/// 3. No extra field data for mimetype
class EpubZipEncoder {
  final List<_ZipEntry> _entries = [];
  
  /// Add a file to the archive.
  /// [compress] - whether to use DEFLATE compression (false for mimetype)
  void addFile(String name, List<int> data, {bool compress = true}) {
    _entries.add(_ZipEntry(name, Uint8List.fromList(data), compress: compress));
  }
  
  /// Add a UTF-8 text file to the archive.
  void addTextFile(String name, String content, {bool compress = true}) {
    addFile(name, utf8.encode(content), compress: compress);
  }
  
  /// Encode all files into a valid EPUB ZIP.
  Uint8List encode() {
    final output = BytesBuilder();
    final centralDirectory = BytesBuilder();
    final offsets = <int>[];
    
    // Write local file headers and data
    for (final entry in _entries) {
      offsets.add(output.length);
      output.add(entry.toLocalFileHeader());
    }
    
    // Write central directory
    final centralDirOffset = output.length;
    for (var i = 0; i < _entries.length; i++) {
      centralDirectory.add(_entries[i].toCentralDirectoryHeader(offsets[i]));
    }
    output.add(centralDirectory.toBytes());
    
    // Write end of central directory
    output.add(_buildEndOfCentralDirectory(
      centralDirOffset,
      centralDirectory.length,
      _entries.length,
    ));
    
    return output.toBytes();
  }
  
  Uint8List _buildEndOfCentralDirectory(int centralDirOffset, int centralDirSize, int entryCount) {
    final buffer = ByteData(22);
    buffer.setUint32(0, 0x06054b50, Endian.little); // End of central directory signature
    buffer.setUint16(4, 0, Endian.little); // Number of this disk
    buffer.setUint16(6, 0, Endian.little); // Disk where central directory starts
    buffer.setUint16(8, entryCount, Endian.little); // Number of central directory records on this disk
    buffer.setUint16(10, entryCount, Endian.little); // Total number of central directory records
    buffer.setUint32(12, centralDirSize, Endian.little); // Size of central directory
    buffer.setUint32(16, centralDirOffset, Endian.little); // Offset of start of central directory
    buffer.setUint16(20, 0, Endian.little); // Comment length
    return buffer.buffer.asUint8List();
  }
}

class _ZipEntry {
  final String name;
  final Uint8List uncompressedData;
  final bool compress;
  
  late final Uint8List compressedData;
  late final int crc32;
  late final int compressionMethod;
  
  _ZipEntry(this.name, this.uncompressedData, {this.compress = true}) {
    crc32 = _calculateCrc32(uncompressedData);
    
    if (compress && uncompressedData.length > 100) {
      // Use DEFLATE compression
      compressedData = Uint8List.fromList(Deflate(uncompressedData).getBytes());
      // Only use compression if it actually saves space
      if (compressedData.length < uncompressedData.length) {
        compressionMethod = 8; // DEFLATE
      } else {
        compressedData = uncompressedData;
        compressionMethod = 0; // STORE
      }
    } else {
      compressedData = uncompressedData;
      compressionMethod = 0; // STORE
    }
  }
  
  Uint8List toLocalFileHeader() {
    final nameBytes = utf8.encode(name);
    final headerSize = 30 + nameBytes.length;
    final totalSize = headerSize + compressedData.length;
    
    final buffer = ByteData(totalSize);
    var offset = 0;
    
    // Local file header signature
    buffer.setUint32(offset, 0x04034b50, Endian.little); offset += 4;
    // Version needed to extract (2.0)
    buffer.setUint16(offset, 20, Endian.little); offset += 2;
    // General purpose bit flag (NO Data Descriptor! Bit 3 = 0)
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    // Compression method
    buffer.setUint16(offset, compressionMethod, Endian.little); offset += 2;
    // Last mod file time (use fixed value for reproducibility)
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    // Last mod file date
    buffer.setUint16(offset, 0x5921, Endian.little); offset += 2; // 2025-01-01
    // CRC-32
    buffer.setUint32(offset, crc32, Endian.little); offset += 4;
    // Compressed size
    buffer.setUint32(offset, compressedData.length, Endian.little); offset += 4;
    // Uncompressed size
    buffer.setUint32(offset, uncompressedData.length, Endian.little); offset += 4;
    // File name length
    buffer.setUint16(offset, nameBytes.length, Endian.little); offset += 2;
    // Extra field length (0 for EPUB compliance)
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    
    // Copy to result
    final result = buffer.buffer.asUint8List();
    
    // Add filename
    final output = BytesBuilder();
    output.add(result.sublist(0, 30));
    output.add(nameBytes);
    output.add(compressedData);
    
    return output.toBytes();
  }
  
  Uint8List toCentralDirectoryHeader(int localHeaderOffset) {
    final nameBytes = utf8.encode(name);
    final headerSize = 46 + nameBytes.length;
    
    final buffer = ByteData(headerSize);
    var offset = 0;
    
    // Central directory file header signature
    buffer.setUint32(offset, 0x02014b50, Endian.little); offset += 4;
    // Version made by (2.0, Unix)
    buffer.setUint16(offset, 0x0314, Endian.little); offset += 2;
    // Version needed to extract
    buffer.setUint16(offset, 20, Endian.little); offset += 2;
    // General purpose bit flag
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    // Compression method
    buffer.setUint16(offset, compressionMethod, Endian.little); offset += 2;
    // Last mod file time
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    // Last mod file date
    buffer.setUint16(offset, 0x5921, Endian.little); offset += 2;
    // CRC-32
    buffer.setUint32(offset, crc32, Endian.little); offset += 4;
    // Compressed size
    buffer.setUint32(offset, compressedData.length, Endian.little); offset += 4;
    // Uncompressed size
    buffer.setUint32(offset, uncompressedData.length, Endian.little); offset += 4;
    // File name length
    buffer.setUint16(offset, nameBytes.length, Endian.little); offset += 2;
    // Extra field length
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    // File comment length
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    // Disk number start
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    // Internal file attributes
    buffer.setUint16(offset, 0, Endian.little); offset += 2;
    // External file attributes
    buffer.setUint32(offset, 0, Endian.little); offset += 4;
    // Relative offset of local header
    buffer.setUint32(offset, localHeaderOffset, Endian.little); offset += 4;
    
    // Copy to result
    final result = buffer.buffer.asUint8List();
    
    // Add filename
    final output = BytesBuilder();
    output.add(result.sublist(0, 46));
    output.add(nameBytes);
    
    return output.toBytes();
  }
  
  /// CRC-32 calculation (IEEE 802.3 polynomial)
  static int _calculateCrc32(Uint8List data) {
    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}

class EpubExportService {
  /// Export the entire conversation (all rounds) to EPUB
  /// Creates a valid EPUB 3.0 file with multiple chapters.
  ///
  /// Each round becomes a separate chapter in the book.
  /// [groups] should be the result of _getConversationGroups() from ConversationScreen.
  Future<void> exportFullConversation({
    required String topicName,
    required List<Map<String, dynamic>> groups,
    required Map<int, List<String>> allAnalyses,
  }) async {
    // Generate a consistent UUID for the book
    final uuid = 'urn:uuid:${DateTime.now().millisecondsSinceEpoch}';

    // Create EPUB-compliant ZIP
    final zip = EpubZipEncoder();

    // 1. mimetype MUST be first and uncompressed
    zip.addTextFile('mimetype', 'application/epub+zip', compress: false);

    // 2. META-INF/container.xml
    final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    zip.addTextFile('META-INF/container.xml', containerXml);

    // 3. OEBPS/styles.css
    zip.addTextFile('OEBPS/styles.css', _generateCss());

    // 4. Generate chapter files for each round
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final userMsg = group['user_message'] as Map<String, dynamic>;
      final assistantReplies = group['assistant_replies'] as List<dynamic>;
      final analyses = allAnalyses[i];

      final chapterHtml = _generateChapterHtml(
        i + 1,
        userMsg,
        assistantReplies,
        analyses,
      );
      zip.addTextFile('OEBPS/chapter${i + 1}.html', chapterHtml);
    }

    // 5. OEBPS/content.opf
    zip.addTextFile('OEBPS/content.opf', _generateFullConversationOpf(topicName, uuid, groups.length));

    // 6. OEBPS/toc.ncx
    zip.addTextFile('OEBPS/toc.ncx', _generateFullConversationToc(topicName, uuid, groups));

    // 7. OEBPS/nav.xhtml
    zip.addTextFile('OEBPS/nav.xhtml', _generateFullConversationNav(topicName, groups));

    // Encode to bytes
    final epubData = zip.encode();

    // Ask user where to save
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Full Conversation EPUB',
      fileName: '${_sanitizeFilename(topicName)}_完整对话.epub',
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (outputFile == null) return;

    // Ensure extension
    if (!outputFile.toLowerCase().endsWith('.epub')) {
      outputFile += '.epub';
    }

    // Write to file
    final file = File(outputFile);
    await file.writeAsBytes(epubData);
  }

  /// Export a single conversation round (group) to EPUB
  /// Creates a valid EPUB 3.0 file compatible with WeRead (微信读书) and other readers.
  ///
  /// Uses a custom ZIP encoder to ensure full EPUB/OCF compliance.
  /// Works on all platforms (macOS, Windows, Linux, Web, iOS, Android).
  Future<void> exportGroup({
    required String topicName,
    required Map<String, dynamic> userMessage,
    required List<dynamic> assistantReplies,
    List<String>? aiAnalyses,
  }) async {
    // Generate a consistent UUID for the book
    final uuid = 'urn:uuid:${DateTime.now().millisecondsSinceEpoch}';
    
    // Create EPUB-compliant ZIP
    final zip = EpubZipEncoder();
    
    // 1. mimetype MUST be first and uncompressed
    zip.addTextFile('mimetype', 'application/epub+zip', compress: false);
    
    // 2. META-INF/container.xml
    final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    zip.addTextFile('META-INF/container.xml', containerXml);
    
    // 3. OEBPS/styles.css
    zip.addTextFile('OEBPS/styles.css', _generateCss());
    
    // 4. OEBPS/chapter.html
    final contentHtml = _generateHtml(topicName, userMessage, assistantReplies, aiAnalyses);
    zip.addTextFile('OEBPS/chapter.html', contentHtml);
    
    // 判断是否有 AI 分析
    final hasAiAnalyses = aiAnalyses != null && aiAnalyses.isNotEmpty;
    
    // 5. OEBPS/content.opf
    zip.addTextFile('OEBPS/content.opf', _generateOpf(topicName, uuid));
    
    // 6. OEBPS/toc.ncx（带详细目录）
    zip.addTextFile('OEBPS/toc.ncx', _generateToc(topicName, uuid, assistantReplies, hasAiAnalyses));
    
    // 7. OEBPS/nav.xhtml（带详细目录）
    zip.addTextFile('OEBPS/nav.xhtml', _generateNav(topicName, assistantReplies, hasAiAnalyses));
    
    // Encode to bytes
    final epubData = zip.encode();
    
    // Ask user where to save
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save EPUB',
      fileName: '${_sanitizeFilename(topicName)}.epub',
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    
    if (outputFile == null) return;
    
    // Ensure extension
    if (!outputFile.toLowerCase().endsWith('.epub')) {
      outputFile += '.epub';
    }
    
    // Write to file
    final file = File(outputFile);
    await file.writeAsBytes(epubData);
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5\-]'), '_');
  }

  String _generateHtml(
    String topicName,
    Map<String, dynamic> userMessage,
    List<dynamic> assistantReplies,
    List<String>? aiAnalyses,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">');
    buffer.writeln('<head>');
    buffer.writeln('<title>$topicName</title>');
    buffer.writeln('<link rel="stylesheet" type="text/css" href="styles.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // User Question
    buffer.writeln('<section class="user-message" id="question">');
    buffer.writeln('<h2>用户提问</h2>');
    buffer.writeln(_markdownToHtml(_extractText(userMessage)));
    buffer.writeln('</section>');

    // AI Analysis
    if (aiAnalyses != null && aiAnalyses.isNotEmpty) {
      buffer.writeln('<section class="ai-analysis" id="ai-insights">');
      buffer.writeln('<h2>AI 洞察</h2>');
      for (final analysis in aiAnalyses) {
         buffer.writeln('<div class="analysis-block">');
         buffer.writeln(_markdownToHtml(analysis));
         buffer.writeln('</div>');
      }
      buffer.writeln('</section>');
    }

    // Model Responses - 使用带id的HTML生成
    buffer.writeln('<section class="model-responses" id="responses">');
    buffer.writeln('<h2>模型回复</h2>');
    for (var i = 0; i < assistantReplies.length; i++) {
       final replyMap = assistantReplies[i] as Map<String, dynamic>;
       final modelName = replyMap['model']?['name'] as String? ?? 'Unknown Model';
       final content = _extractText(replyMap);
       final modelId = _sanitizeId(modelName, i);

       buffer.writeln('<article class="response-block" id="$modelId">');
       buffer.writeln('<h3 class="model-name">$modelName</h3>');
       buffer.writeln('<div class="model-content">');
       // 【改进】使用带id的HTML生成，为Markdown标题添加锚点
       buffer.writeln(_markdownToHtmlWithIds(content, modelId));
       buffer.writeln('</div>');
       buffer.writeln('<hr/>');
       buffer.writeln('</article>');
    }
    buffer.writeln('</section>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
  
  /// 生成安全的 HTML id（只保留字母数字和连字符）
  String _sanitizeId(String name, int index) {
    final sanitized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'model-${index + 1}-$sanitized';
  }
  
  String _markdownToHtml(String markdown) {
    // Use the markdown package to convert
    String html = md.markdownToHtml(
      markdown, 
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    
    // Basic XHTML fix for void elements
    // 1. Fix <br> -> <br/>
    html = html.replaceAll('<br>', '<br/>');
    // 2. Fix <hr> -> <hr/>
    html = html.replaceAll('<hr>', '<hr/>');
    
    // 3. Fix <img> tags (Close them properly)
    html = html.replaceAllMapped(RegExp(r'<img[^>]+>'), (match) {
      var imgTag = match.group(0)!;
      // Ensure it ends with />
      if (!imgTag.trimRight().endsWith('/>')) {
         // Remove the last > and add />
         imgTag = imgTag.substring(0, imgTag.lastIndexOf('>')) + '/>';
      }
      return imgTag;
    });
    
    // 4. CRITICAL: Fix HTML Entities
    // XML only supports 5 predefined entities: &amp; &lt; &gt; &quot; &apos;
    // All others (like &nbsp;) must be numeric.
    html = html.replaceAll('&nbsp;', '&#160;');
    html = html.replaceAll('&copy;', '&#169;');
    html = html.replaceAll('&mdash;', '&#8212;');
    html = html.replaceAll('&ldquo;', '&#8220;');
    html = html.replaceAll('&rdquo;', '&#8221;');
    
    return html;
  }

  String _extractText(Map<String, dynamic> message) {
    final blocks = message['blocks'] as List<dynamic>? ?? [];
    var content = '';
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'main_text') {
        content += block['content'] as String? ?? '';
      }
    }
    return content;
  }

  /// 从Markdown内容中提取标题列表
  /// 返回: [{level: 1, title: "标题", id: "heading-1"}]
  List<Map<String, dynamic>> _extractHeadings(String markdown, String idPrefix) {
    final headings = <Map<String, dynamic>>[];
    final lines = markdown.split('\n');
    var headingIndex = 0;

    for (final line in lines) {
      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line.trim());
      if (match != null) {
        final level = match.group(1)!.length;
        final title = match.group(2)!.trim();
        final id = '$idPrefix-h${headingIndex++}';
        headings.add({
          'level': level,
          'title': title,
          'id': id,
        });
      }
    }
    return headings;
  }

  /// 将Markdown转换为HTML，并为标题添加id锚点
  String _markdownToHtmlWithIds(String markdown, String idPrefix) {
    var headingIndex = 0;

    // 先替换标题，添加id
    final processedMarkdown = markdown.replaceAllMapped(
      RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true),
      (match) {
        final hashes = match.group(1)!;
        final title = match.group(2)!;
        final id = '$idPrefix-h${headingIndex++}';
        // 使用特殊标记，后面转换后再处理
        return '$hashes $title {#$id}';
      },
    );

    // 转换为HTML
    String html = md.markdownToHtml(
      processedMarkdown,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    // 处理标题id：将 <h1>title {#id}</h1> 转换为 <h1 id="id">title</h1>
    html = html.replaceAllMapped(
      RegExp(r'<(h[1-6])>(.+?)\s*\{#([^}]+)\}</(h[1-6])>'),
      (match) => '<${match.group(1)} id="${match.group(3)}">${match.group(2)}</${match.group(4)}>',
    );

    // 基本XHTML修复
    html = html.replaceAll('<br>', '<br/>');
    html = html.replaceAll('<hr>', '<hr/>');

    html = html.replaceAllMapped(RegExp(r'<img[^>]+>'), (match) {
      var imgTag = match.group(0)!;
      if (!imgTag.trimRight().endsWith('/>')) {
        imgTag = imgTag.substring(0, imgTag.lastIndexOf('>')) + '/>';
      }
      return imgTag;
    });

    // 修复HTML实体
    html = html.replaceAll('&nbsp;', '&#160;');
    html = html.replaceAll('&copy;', '&#169;');
    html = html.replaceAll('&mdash;', '&#8212;');
    html = html.replaceAll('&ldquo;', '&#8220;');
    html = html.replaceAll('&rdquo;', '&#8221;');

    return html;
  }

  String _generateCss() {
    return '''
body {
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  line-height: 1.6;
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
  background-color: #ffffff;
  color: #333;
}

h2 {
  font-size: 1.4em; 
  color: #455a64; 
  border-bottom: 2px solid #eceff1; 
  padding-bottom: 0.3em; 
  margin-top: 2em; 
  margin-bottom: 1em;
}

h3.model-name { 
  font-size: 1.1em; 
  color: #1565c0; 
  background-color: #e3f2fd;
  display: inline-block;
  padding: 4px 12px;
  border-radius: 16px;
  margin-top: 1.5em;
  margin-bottom: 1em;
}

.user-message {
  font-size: 1.1em;
}

/* AI Analysis - Special Styling */
.ai-analysis .analysis-block {
  background-color: #f3e5f5; /* Purple 50 */
  border-left: 4px solid #ab47bc; /* Purple 400 */
  padding: 12px 16px;
  margin-bottom: 16px;
  border-radius: 4px;
  color: #4a148c;
}

/* Code Blocks - Horizontal Scroll, Monospace */
pre {
  background-color: #f5f7f9;
  padding: 12px;
  border-radius: 6px;
  overflow-x: auto; /* Allow horizontal scroll */
  white-space: pre; /* Maintain formatting */
  border: 1px solid #e1e4e8;
  margin: 1em 0;
}

code {
  font-family: "JetBrains Mono", "Fira Code", "Roboto Mono", "SFMono-Regular", Consolas, monospace;
  font-size: 0.9em;
}

/* Inline Code */
p code, li code {
  background-color: rgba(175, 184, 193, 0.2);
  padding: 0.2em 0.4em;
  border-radius: 4px;
}

blockquote {
  color: #546e7a;
  border-left: 4px solid #cfd8dc;
  margin: 1em 0;
  padding-left: 1em;
  background-color: #fafafa;
}

hr {
  border: 0;
  border-top: 1px solid #e0e0e0;
  margin: 30px 0;
}

img {
  max-width: 100%;
  height: auto;
  border-radius: 4px;
}

table {
  border-collapse: collapse;
  width: 100%;
  margin: 1em 0;
}
th, td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: left;
}
th {
  background-color: #f2f2f2;
}
''';
  }

  String _generateOpf(String title, String uuid) {
    final modifiedDate = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'\.\d+Z$'), 'Z');
    
    return '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:language>zh-CN</dc:language>
    <dc:identifier id="BookId">$uuid</dc:identifier>
    <meta property="dcterms:modified">$modifiedDate</meta>
  </metadata>
  <manifest>
    <item id="styles" href="styles.css" media-type="text/css"/>
    <item id="chapter" href="chapter.html" media-type="application/xhtml+xml"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter"/>
  </spine>
</package>''';
  }
  
  String _generateNav(String title, List<dynamic> assistantReplies, bool hasAiAnalyses) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="zh-CN">');
    buffer.writeln('<head>');
    buffer.writeln('<title>$title</title>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<nav epub:type="toc" id="toc">');
    buffer.writeln('  <h1>目录</h1>');
    buffer.writeln('  <ol>');

    // 用户提问
    buffer.writeln('    <li><a href="chapter.html#question">用户提问</a></li>');

    // AI 洞察（如果有）
    if (hasAiAnalyses) {
      buffer.writeln('    <li><a href="chapter.html#ai-insights">AI 洞察</a></li>');
    }

    // 模型回复（作为子目录，包含Markdown标题）
    buffer.writeln('    <li>');
    buffer.writeln('      <a href="chapter.html#responses">模型回复</a>');
    if (assistantReplies.isNotEmpty) {
      buffer.writeln('      <ol>');
      for (var i = 0; i < assistantReplies.length; i++) {
        final replyMap = assistantReplies[i] as Map<String, dynamic>;
        final modelName = replyMap['model']?['name'] as String? ?? 'Unknown Model';
        final modelId = _sanitizeId(modelName, i);
        final content = _extractText(replyMap);
        final headings = _extractHeadings(content, modelId);

        buffer.writeln('        <li>');
        buffer.writeln('          <a href="chapter.html#$modelId">$modelName</a>');

        // 【改进】添加Markdown标题作为子章节
        if (headings.isNotEmpty) {
          buffer.writeln('          <ol>');
          for (final heading in headings) {
            final hTitle = _escapeXml(heading['title'] as String);
            final hId = heading['id'] as String;
            buffer.writeln('            <li><a href="chapter.html#$hId">$hTitle</a></li>');
          }
          buffer.writeln('          </ol>');
        }
        buffer.writeln('        </li>');
      }
      buffer.writeln('      </ol>');
    }
    buffer.writeln('    </li>');

    buffer.writeln('  </ol>');
    buffer.writeln('</nav>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// 转义XML特殊字符
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
  
  String _generateToc(String title, String uuid, List<dynamic> assistantReplies, bool hasAiAnalyses) {
     // The ncx format is used for EPUB 2 backward compatibility
     // but modern readers (Apple Books, WeRead) often rely on it for navigation.
     final buffer = StringBuffer();
     buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
     buffer.writeln('<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">');
     buffer.writeln('  <head>');
     buffer.writeln('    <meta name="dtb:uid" content="$uuid"/>');
     buffer.writeln('    <meta name="dtb:depth" content="3"/>');
     buffer.writeln('    <meta name="dtb:totalPageCount" content="0"/>');
     buffer.writeln('    <meta name="dtb:maxPageNumber" content="0"/>');
     buffer.writeln('  </head>');
     buffer.writeln('  <docTitle>');
     buffer.writeln('    <text>$title</text>');
     buffer.writeln('  </docTitle>');
     buffer.writeln('  <navMap>');

     var playOrder = 1;

     // 用户提问
     buffer.writeln('    <navPoint id="navPoint-$playOrder" playOrder="$playOrder">');
     buffer.writeln('      <navLabel><text>用户提问</text></navLabel>');
     buffer.writeln('      <content src="chapter.html#question"/>');
     buffer.writeln('    </navPoint>');
     playOrder++;

     // AI 洞察（如果有）
     if (hasAiAnalyses) {
       buffer.writeln('    <navPoint id="navPoint-$playOrder" playOrder="$playOrder">');
       buffer.writeln('      <navLabel><text>AI 洞察</text></navLabel>');
       buffer.writeln('      <content src="chapter.html#ai-insights"/>');
       buffer.writeln('    </navPoint>');
       playOrder++;
     }

     // 模型回复（带子项和Markdown标题）
     buffer.writeln('    <navPoint id="navPoint-$playOrder" playOrder="$playOrder">');
     buffer.writeln('      <navLabel><text>模型回复</text></navLabel>');
     buffer.writeln('      <content src="chapter.html#responses"/>');
     playOrder++;

     // 每个模型作为子导航点
     for (var i = 0; i < assistantReplies.length; i++) {
       final replyMap = assistantReplies[i] as Map<String, dynamic>;
       final modelName = replyMap['model']?['name'] as String? ?? 'Unknown Model';
       final modelId = _sanitizeId(modelName, i);
       final content = _extractText(replyMap);
       final headings = _extractHeadings(content, modelId);

       buffer.writeln('      <navPoint id="navPoint-$playOrder" playOrder="$playOrder">');
       buffer.writeln('        <navLabel><text>$modelName</text></navLabel>');
       buffer.writeln('        <content src="chapter.html#$modelId"/>');
       playOrder++;

       // 【改进】添加Markdown标题作为子导航点
       for (final heading in headings) {
         final hTitle = _escapeXml(heading['title'] as String);
         final hId = heading['id'] as String;
         buffer.writeln('        <navPoint id="navPoint-$playOrder" playOrder="$playOrder">');
         buffer.writeln('          <navLabel><text>$hTitle</text></navLabel>');
         buffer.writeln('          <content src="chapter.html#$hId"/>');
         buffer.writeln('        </navPoint>');
         playOrder++;
       }

       buffer.writeln('      </navPoint>');
     }

     buffer.writeln('    </navPoint>');
     buffer.writeln('  </navMap>');
     buffer.writeln('</ncx>');

     return buffer.toString();
  }

  /// Generate HTML for a single chapter (round)
  String _generateChapterHtml(
    int chapterNumber,
    Map<String, dynamic> userMessage,
    List<dynamic> assistantReplies,
    List<String>? aiAnalyses,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">');
    buffer.writeln('<head>');
    buffer.writeln('<title>第 $chapterNumber 轮对话</title>');
    buffer.writeln('<link rel="stylesheet" type="text/css" href="styles.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Chapter title
    buffer.writeln('<h1 id="round-$chapterNumber">第 $chapterNumber 轮对话</h1>');

    // User Question
    buffer.writeln('<section class="user-message" id="question-$chapterNumber">');
    buffer.writeln('<h2>用户提问</h2>');
    buffer.writeln(_markdownToHtml(_extractText(userMessage)));
    buffer.writeln('</section>');

    // AI Analysis
    if (aiAnalyses != null && aiAnalyses.isNotEmpty) {
      buffer.writeln('<section class="ai-analysis" id="ai-insights-$chapterNumber">');
      buffer.writeln('<h2>AI 洞察</h2>');
      for (final analysis in aiAnalyses) {
         buffer.writeln('<div class="analysis-block">');
         buffer.writeln(_markdownToHtml(analysis));
         buffer.writeln('</div>');
      }
      buffer.writeln('</section>');
    }

    // Model Responses - 使用带id的HTML生成
    buffer.writeln('<section class="model-responses" id="responses-$chapterNumber">');
    buffer.writeln('<h2>模型回复</h2>');
    for (var i = 0; i < assistantReplies.length; i++) {
       final replyMap = assistantReplies[i] as Map<String, dynamic>;
       final modelName = replyMap['model']?['name'] as String? ?? 'Unknown Model';
       final content = _extractText(replyMap);
       final modelId = 'ch$chapterNumber-${_sanitizeId(modelName, i)}';

       buffer.writeln('<article class="response-block" id="$modelId">');
       buffer.writeln('<h3 class="model-name">$modelName</h3>');
       buffer.writeln('<div class="model-content">');
       // 【改进】使用带id的HTML生成，为Markdown标题添加锚点
       buffer.writeln(_markdownToHtmlWithIds(content, modelId));
       buffer.writeln('</div>');
       buffer.writeln('<hr/>');
       buffer.writeln('</article>');
    }
    buffer.writeln('</section>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// Generate OPF for full conversation (multiple chapters)
  String _generateFullConversationOpf(String title, String uuid, int chapterCount) {
    final modifiedDate = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'\.\d+Z$'), 'Z');

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="3.0">');
    buffer.writeln('  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">');
    buffer.writeln('    <dc:title>$title - 完整对话</dc:title>');
    buffer.writeln('    <dc:language>zh-CN</dc:language>');
    buffer.writeln('    <dc:identifier id="BookId">$uuid</dc:identifier>');
    buffer.writeln('    <meta property="dcterms:modified">$modifiedDate</meta>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <manifest>');
    buffer.writeln('    <item id="styles" href="styles.css" media-type="text/css"/>');

    // Add all chapter files
    for (var i = 1; i <= chapterCount; i++) {
      buffer.writeln('    <item id="chapter$i" href="chapter$i.html" media-type="application/xhtml+xml"/>');
    }

    buffer.writeln('    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    buffer.writeln('    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    buffer.writeln('  </manifest>');
    buffer.writeln('  <spine toc="ncx">');

    // Add all chapters to spine
    for (var i = 1; i <= chapterCount; i++) {
      buffer.writeln('    <itemref idref="chapter$i"/>');
    }

    buffer.writeln('  </spine>');
    buffer.writeln('</package>');

    return buffer.toString();
  }

  /// Generate TOC for full conversation
  /// 【改进】包含模型回复和Markdown标题作为子章节
  String _generateFullConversationToc(String title, String uuid, List<Map<String, dynamic>> groups) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">');
    buffer.writeln('  <head>');
    buffer.writeln('    <meta name="dtb:uid" content="$uuid"/>');
    buffer.writeln('    <meta name="dtb:depth" content="4"/>');
    buffer.writeln('    <meta name="dtb:totalPageCount" content="0"/>');
    buffer.writeln('    <meta name="dtb:maxPageNumber" content="0"/>');
    buffer.writeln('  </head>');
    buffer.writeln('  <docTitle>');
    buffer.writeln('    <text>$title - 完整对话</text>');
    buffer.writeln('  </docTitle>');
    buffer.writeln('  <navMap>');

    var playOrder = 1;

    // Add each chapter with nested navigation
    for (var i = 0; i < groups.length; i++) {
      final chapterNum = i + 1;
      final group = groups[i];
      final assistantReplies = group['assistant_replies'] as List<dynamic>;

      buffer.writeln('    <navPoint id="navPoint-$playOrder" playOrder="$playOrder">');
      buffer.writeln('      <navLabel><text>第 $chapterNum 轮对话</text></navLabel>');
      buffer.writeln('      <content src="chapter$chapterNum.html"/>');
      playOrder++;

      // 【改进】添加模型回复作为子导航点
      for (var j = 0; j < assistantReplies.length; j++) {
        final replyMap = assistantReplies[j] as Map<String, dynamic>;
        final modelName = replyMap['model']?['name'] as String? ?? 'Unknown Model';
        final modelId = 'ch$chapterNum-${_sanitizeId(modelName, j)}';
        final content = _extractText(replyMap);
        final headings = _extractHeadings(content, modelId);

        buffer.writeln('      <navPoint id="navPoint-$playOrder" playOrder="$playOrder">');
        buffer.writeln('        <navLabel><text>$modelName</text></navLabel>');
        buffer.writeln('        <content src="chapter$chapterNum.html#$modelId"/>');
        playOrder++;

        // 【改进】添加Markdown标题作为更深层子导航点
        for (final heading in headings) {
          final hTitle = _escapeXml(heading['title'] as String);
          final hId = heading['id'] as String;
          buffer.writeln('        <navPoint id="navPoint-$playOrder" playOrder="$playOrder">');
          buffer.writeln('          <navLabel><text>$hTitle</text></navLabel>');
          buffer.writeln('          <content src="chapter$chapterNum.html#$hId"/>');
          buffer.writeln('        </navPoint>');
          playOrder++;
        }

        buffer.writeln('      </navPoint>');
      }

      buffer.writeln('    </navPoint>');
    }

    buffer.writeln('  </navMap>');
    buffer.writeln('</ncx>');

    return buffer.toString();
  }

  /// Generate navigation for full conversation
  /// 【改进】包含模型回复和Markdown标题作为子章节
  String _generateFullConversationNav(String title, List<Map<String, dynamic>> groups) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="zh-CN">');
    buffer.writeln('<head>');
    buffer.writeln('<title>$title - 完整对话</title>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<nav epub:type="toc" id="toc">');
    buffer.writeln('  <h1>目录</h1>');
    buffer.writeln('  <ol>');

    // Add each chapter with sub-navigation
    for (var i = 0; i < groups.length; i++) {
      final chapterNum = i + 1;
      final group = groups[i];
      final assistantReplies = group['assistant_replies'] as List<dynamic>;

      buffer.writeln('    <li>');
      buffer.writeln('      <a href="chapter$chapterNum.html">第 $chapterNum 轮对话</a>');

      // 【改进】添加模型回复作为子章节
      if (assistantReplies.isNotEmpty) {
        buffer.writeln('      <ol>');
        for (var j = 0; j < assistantReplies.length; j++) {
          final replyMap = assistantReplies[j] as Map<String, dynamic>;
          final modelName = replyMap['model']?['name'] as String? ?? 'Unknown Model';
          final modelId = 'ch$chapterNum-${_sanitizeId(modelName, j)}';
          final content = _extractText(replyMap);
          final headings = _extractHeadings(content, modelId);

          buffer.writeln('        <li>');
          buffer.writeln('          <a href="chapter$chapterNum.html#$modelId">$modelName</a>');

          // 【改进】添加Markdown标题作为更深层子章节
          if (headings.isNotEmpty) {
            buffer.writeln('          <ol>');
            for (final heading in headings) {
              final hTitle = _escapeXml(heading['title'] as String);
              final hId = heading['id'] as String;
              buffer.writeln('            <li><a href="chapter$chapterNum.html#$hId">$hTitle</a></li>');
            }
            buffer.writeln('          </ol>');
          }
          buffer.writeln('        </li>');
        }
        buffer.writeln('      </ol>');
      }
      buffer.writeln('    </li>');
    }

    buffer.writeln('  </ol>');
    buffer.writeln('</nav>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
}
