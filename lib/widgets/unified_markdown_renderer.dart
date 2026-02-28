import 'package:flutter/material.dart';
import 'package:gpt_markdown_custom/gpt_markdown.dart';
import '../utils/text_cleaner.dart';

/// 统一的 Markdown 渲染器
///
/// 整合了所有 Markdown 渲染需求：
/// - LaTeX 数学公式支持（$...$ 和 $$...$$）
/// - 优化的排版样式（标题间距、行高、字间距）
/// - 代码高亮
/// - 可选的文本选择功能
/// - 支持大字体模式（全屏阅读）
/// - 【新增】虚拟化渲染优化（长文本场景）
class UnifiedMarkdownRenderer extends StatelessWidget {
  /// Markdown 内容
  final String data;

  /// 基础文本样式
  final TextStyle? textStyle;

  /// 文本对齐方式
  final TextAlign? textAlign;

  /// 是否可选择文本
  final bool selectable;

  /// 是否使用大字体模式（全屏阅读时）
  final bool largeFont;

  /// 内边距
  final EdgeInsets padding;

  /// 是否支持独立滚动
  final bool scrollable;

  /// 【性能优化】虚拟化阈值（字符数）
  /// 超过此阈值时启用增量渲染优化
  final int virtualizeThreshold;

  /// 【性能优化】是否启用虚拟化
  /// 设为 true 时，长内容会分块渲染
  final bool enableVirtualization;

  const UnifiedMarkdownRenderer({
    super.key,
    required this.data,
    this.textStyle,
    this.textAlign,
    this.selectable = false,
    this.largeFont = false,
    this.padding = EdgeInsets.zero,
    this.scrollable = false,
    this.virtualizeThreshold = 10000,
    this.enableVirtualization = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFE8E8E8)
        : const Color(0xFF1A1A2E);
    final sanitizedData = data
        .replaceAll('<!-- -->', '')
        .replaceAll('<!---->', '');
    final normalizedData = fixMarkdownStrongAfterCjkPunctuation(sanitizedData);

    // 创建自定义主题 - Cherry Studio 风格
    final themeData = _buildThemeData(context, isDark, textColor);

    // 默认的正文样式 - Cherry Studio 风格
    final bodyColor = isDark
        ? const Color(0xFFD4D4D4)
        : const Color(0xFF374151);
    final defaultTextStyle =
        textStyle ??
        TextStyle(
          fontSize: largeFont ? 17 : 14,
          height: 1.6, // Cherry Studio 的 line-height: 1.6
          color: bodyColor,
          letterSpacing: 0.1,
        );

    // 【性能优化】长内容虚拟化渲染
    final shouldVirtualize =
        enableVirtualization && normalizedData.length > virtualizeThreshold;

    Widget markdownWidget;

    if (shouldVirtualize) {
      // 长内容：使用增量渲染
      markdownWidget = _buildVirtualizedContent(
        context,
        normalizedData,
        themeData,
        defaultTextStyle,
      );
    } else {
      // 短内容：直接渲染
      markdownWidget = _buildDirectContent(
        normalizedData,
        themeData,
        defaultTextStyle,
      );
    }

    // 根据 scrollable 和 padding 包装
    if (padding != EdgeInsets.zero) {
      markdownWidget = Padding(padding: padding, child: markdownWidget);
    }

    if (scrollable) {
      return SingleChildScrollView(child: markdownWidget);
    }

    return markdownWidget;
  }

  /// 构建主题数据
  GptMarkdownThemeData _buildThemeData(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    return GptMarkdownThemeData(
      brightness: Theme.of(context).brightness,
      // 标题样式 - 更紧凑的行高
      h1: TextStyle(
        fontSize: largeFont ? 28 : 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.4,
      ),
      h2: TextStyle(
        fontSize: largeFont ? 24 : 19,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h3: TextStyle(
        fontSize: largeFont ? 20 : 17,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h4: TextStyle(
        fontSize: largeFont ? 18 : 15,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h5: TextStyle(
        fontSize: largeFont ? 16 : 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h6: TextStyle(
        fontSize: largeFont ? 15 : 13,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      // 【关键】分割线更细更透明
      hrLineThickness: 0.5,
      hrLineColor: isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.08),
      linkColor: const Color(0xFF3B82F6),
      // 默认高亮颜色
      highlightColor: const Color(0xFFFBC02D),
    );
  }

  /// 直接渲染（短内容）
  Widget _buildDirectContent(
    String markdown,
    GptMarkdownThemeData themeData,
    TextStyle defaultTextStyle,
  ) {
    return GptMarkdownTheme(
      gptThemeData: themeData,
      child: GptMarkdownV2(
        data: markdown,
        config: GptMarkdownConfig(
          style: defaultTextStyle,
          textAlign: textAlign,
          useDollarSignsForLatex: true,
          followLinkColor: true,
        ),
      ),
    );
  }

  /// 【性能优化】虚拟化渲染（长内容）
  ///
  /// 策略：将长内容分成多个段落，使用 RepaintBoundary 隔离重绘
  Widget _buildVirtualizedContent(
    BuildContext context,
    String markdown,
    GptMarkdownThemeData themeData,
    TextStyle defaultTextStyle,
  ) {
    // 按段落分割（使用双换行作为分隔符）
    final chunks = _splitIntoChunks(markdown);

    return GptMarkdownTheme(
      gptThemeData: themeData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: chunks.map((chunk) {
          return RepaintBoundary(
            child: GptMarkdownV2(
              data: chunk,
              config: GptMarkdownConfig(
                style: defaultTextStyle,
                textAlign: textAlign,
                useDollarSignsForLatex: true,
                followLinkColor: true,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 将内容分割成块
  ///
  /// 按双换行或特定标记分割，保持语义完整性
  List<String> _splitIntoChunks(String content) {
    // 按双换行分割（Markdown 段落边界）
    final paragraphs = content.split(RegExp(r'\n\n+'));

    // 合并小段落，避免过多碎片
    final chunks = <String>[];
    final buffer = StringBuffer();
    const maxChunkSize = 2000; // 每块最大字符数

    for (final para in paragraphs) {
      if (buffer.length + para.length > maxChunkSize && buffer.isNotEmpty) {
        chunks.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.write(para);
      buffer.write('\n\n');
    }

    if (buffer.isNotEmpty) {
      chunks.add(buffer.toString().trim());
    }

    return chunks.isEmpty ? [content] : chunks;
  }
}
