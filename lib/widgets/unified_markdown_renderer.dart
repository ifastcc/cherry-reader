import 'package:flutter/material.dart';
import 'package:gpt_markdown_custom/gpt_markdown.dart';
import '../services/markdown_syntax_highlighter.dart';

// 导出 HighlightRange 以便其他文件访问
export '../services/markdown_syntax_highlighter.dart' show HighlightRange;

/// 统一的 Markdown 渲染器
///
/// 整合了所有 Markdown 渲染需求：
/// - LaTeX 数学公式支持（$...$ 和 $$...$$）
/// - 多色高亮标注（通过自定义语法 <highlight color="#xxx" id="yyy">text</highlight>）
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

  /// 高亮范围列表（用于渲染已有高亮）
  final List<HighlightRange> highlights;

  /// 点击高亮区域的回调
  final Function(String id, TapDownDetails details)? onHighlightTap;

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
    this.highlights = const [],
    this.onHighlightTap,
    this.padding = EdgeInsets.zero,
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 创建自定义主题，优化标题间距
    final themeData = GptMarkdownThemeData(
      brightness: Theme.of(context).brightness,
      // 自定义标题样式 - 增加底部间距感（通过 height）
      h1: TextStyle(
        fontSize: largeFont ? 28 : 24,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A2E),
        height: 2.0, // 增加行高来创造标题后间距
      ),
      h2: TextStyle(
        fontSize: largeFont ? 24 : 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
        height: 1.8,
      ),
      h3: TextStyle(
        fontSize: largeFont ? 20 : 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
        height: 1.7,
      ),
      h4: TextStyle(
        fontSize: largeFont ? 18 : 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
        height: 1.6,
      ),
      h5: TextStyle(
        fontSize: largeFont ? 16 : 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
        height: 1.5,
      ),
      h6: TextStyle(
        fontSize: largeFont ? 15 : 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
        height: 1.5,
      ),
      linkColor: const Color(0xFF0F62FE),
      // 默认高亮颜色（用于 ==text== 语法）
      highlightColor: const Color(0xFFFBC02D),
    );

    // 默认的正文样式
    final defaultTextStyle =
        textStyle ??
        TextStyle(
          fontSize: largeFont ? 18 : 15,
          height: largeFont ? 2.0 : 1.85,
          color: const Color(0xFF2C3E50),
          letterSpacing: 0.2,
        );

    Widget markdownWidget = GptMarkdownTheme(
      gptThemeData: themeData,
      child: GptMarkdown(
        data,
        style: defaultTextStyle,
        textAlign: textAlign,
        // 启用 LaTeX 支持 - 支持 $...$ 和 $$...$$ 语法
        useDollarSignsForLatex: true,
        // 跟随链接颜色
        followLinkColor: true,
        // 传递渲染层高亮数据
        highlightRanges: highlights.map((h) => HighlightRangeData(
          id: h.id,
          start: h.start,
          end: h.end,
          color: h.color,
          styleType: h.styleType,
          text: h.text,
        )).toList(),
        // 高亮点击回调
        onHighlightRangeTap: onHighlightTap != null 
          ? (id, position) => onHighlightTap!(id, TapDownDetails(globalPosition: position))
          : null,
        // 自定义高亮渲染（用于 ==text== 语法的单色高亮）
        highlightBuilder: (context, text, style) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFBC02D).withAlpha(180),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(text, style: style),
          );
        },
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
