import 'package:flutter/material.dart';
import 'package:gpt_markdown_custom/gpt_markdown.dart';

/// 统一的 Markdown 渲染器
///
/// 整合了所有 Markdown 渲染需求：
/// - LaTeX 数学公式支持（$...$ 和 $$...$$）
/// - 优化的排版样式（标题间距、行高、字间距）
/// - 代码高亮
/// - 可选的文本选择功能
/// - 支持大字体模式（全屏阅读）
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

  const UnifiedMarkdownRenderer({
    Key? key,
    required this.data,
    this.textStyle,
    this.textAlign,
    this.selectable = false,
    this.largeFont = false,
    this.padding = EdgeInsets.zero,
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A2E);
    
    // 创建自定义主题 - Cherry Studio 风格
    final themeData = GptMarkdownThemeData(
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

    // 默认的正文样式 - Cherry Studio 风格
    final bodyColor = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF374151);
    final defaultTextStyle =
        textStyle ??
        TextStyle(
          fontSize: largeFont ? 17 : 14,
          height: 1.6, // Cherry Studio 的 line-height: 1.6
          color: bodyColor,
          letterSpacing: 0.1,
        );

    Widget markdownWidget = GptMarkdownTheme(
      gptThemeData: themeData,
      child: GptMarkdownV2(
        data: data,
        config: GptMarkdownConfig(
          style: defaultTextStyle,
          textAlign: textAlign,
          useDollarSignsForLatex: true,
          // 跟随链接颜色
          followLinkColor: true,
        ),
      ),
    );

    // 根据 scrollable 和 padding 包装
    if (padding != EdgeInsets.zero) {
      markdownWidget = Padding(padding: padding, child: markdownWidget);
    }

    if (scrollable) {
      return SingleChildScrollView(child: markdownWidget);
    }

    return markdownWidget;
  }
}

