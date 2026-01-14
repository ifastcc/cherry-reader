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
          // 启用 LaTeX 支持 - 支持 $...$ 和 $$...$$ 语法
          useDollarSignsForLatex: true, // Config usually handles this internally or via regex replacement in V2 wrapper? 
          // Note: GptMarkdownV2 wrapper in v2/widget.dart doesn't have useDollarSignsForLatex param logic in build?
          // Let's check GptMarkdownV2 source again. It calls GptMarkdownVisitor.
          // And GptMarkdown wrapper (V1) did regex replacement BEFORE MdWidget.
          // GptMarkdownV2 wrapper in v2/widget.dart does NOT do regex replacement as seen in previous view?
          // Wait, I viewed v2/widget.dart. It has:
          // final document = md.Document(extensionSet: GptExtensionSet.all);
          // And NO regex replacement.
          // So I might need to handle $ -> \( replacement manually or update V2 to support it?
          // LatexInlineSyntax in V2 handles $.
          // So V2 is native. No need for regex replacement. GOOD.
          
          // 【调试】显示 Block 索引号 (临时开启)
          debugShowBlockIndex: true,
          
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
            prefix: h.prefix,
            suffix: h.suffix,
            blockIndex: h.blockIndex,
            blockContentHash: h.blockContentHash,
            blockInternalStart: h.blockInternalStart,
            blockInternalEnd: h.blockInternalEnd,
            groupId: h.groupId,
            isTarget: h.isTarget,  // 【精确定位】传递目标标记
          )).toList(),
          
          // 高亮点击回调
          onHighlightRangeTap: onHighlightTap != null 
            ? (id, position) => onHighlightTap!(id, TapDownDetails(globalPosition: position))
            : null,
            
          // 自定义高亮渲染
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
