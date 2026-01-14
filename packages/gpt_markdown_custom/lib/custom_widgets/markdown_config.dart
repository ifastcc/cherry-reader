import 'package:flutter/material.dart';
import 'package:gpt_markdown_custom/gpt_markdown.dart';
import 'custom_table_row.dart';

/// A builder function for the ordered list.
typedef OrderedListBuilder =
    Widget Function(
      BuildContext context,
      String no,
      Widget child,
      GptMarkdownConfig config,
    );

/// A builder function for the unordered list.
typedef UnOrderedListBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      GptMarkdownConfig config,
    );

/// A builder function for the source tag.
typedef SourceTagBuilder =
    Widget Function(BuildContext context, String content, TextStyle textStyle);

/// A builder function for the code block.
typedef CodeBlockBuilder =
    Widget Function(
      BuildContext context,
      String name,
      String code,
      bool closed,
    );

/// A builder function for the LaTeX.
typedef LatexBuilder =
    Widget Function(
      BuildContext context,
      String tex,
      TextStyle textStyle,
      bool inline,
    );

/// A builder function for the link.
typedef LinkBuilder =
    Widget Function(
      BuildContext context,
      InlineSpan text,
      String url,
      TextStyle style,
    );

/// A builder function for the table.
typedef TableBuilder =
    Widget Function(
      BuildContext context,
      List<CustomTableRow> tableRows,
      TextStyle textStyle,
      GptMarkdownConfig config,
    );

/// A builder function for the highlight.
typedef HighlightBuilder =
    Widget Function(BuildContext context, String text, TextStyle style);

/// A builder function for the image.
typedef ImageBuilder = Widget Function(BuildContext context, String imageUrl);

/// Callback for highlight range tap events.
typedef HighlightRangeTapCallback = void Function(String id, Offset position);

/// Data class for highlight ranges (used for render-layer highlighting).
///
/// This is used to apply highlights directly during rendering,
/// avoiding Markdown syntax conflicts.
class HighlightRangeData {
  final String? id;
  final int start;
  final int end;
  final Color color;
  final String? styleType; // 'background' or 'underline'
  final String? text; // 【新增】用于在渲染时动态匹配的文本
  final String? prefix; // 【新增】上下文前缀 (用于语义定位)
  final String? suffix; // 【新增】上下文后缀 (用于语义定位)
  final int? blockIndex; // 【新增】Block ID，如有则 start/end 为局部偏移
  final String? blockContentHash; // 【新增】
  final int? blockInternalStart; // 【新增】
  final int? blockInternalEnd; // 【新增】
  final String? groupId; // 【新增】
  final bool isTarget; // 【精确定位】是否为目标高亮

  const HighlightRangeData({
    this.id,
    required this.start,
    required this.end,
    required this.color,
    this.styleType = 'background',
    this.text,
    this.prefix,
    this.suffix,
    this.blockIndex,
    this.blockContentHash,
    this.blockInternalStart,
    this.blockInternalEnd,
    this.groupId,
    this.isTarget = false,
  });
}

/// A configuration class for the GPT Markdown component.
///
/// The [GptMarkdownConfig] class is used to configure the GPT Markdown component.
/// It takes a [style] parameter to set the style of the text,
/// a [textDirection] parameter to set the direction of the text,
/// and an optional [onLinkTap] parameter to handle link clicks.
class GptMarkdownConfig {
  const GptMarkdownConfig({
    this.useDollarSignsForLatex = false,
    this.style,
    this.textDirection = TextDirection.ltr,
    this.onLinkTap,
    this.textAlign,
    this.textScaler,
    this.latexWorkaround,
    this.latexBuilder,
    this.followLinkColor = false,
    this.codeBuilder,
    this.sourceTagBuilder,
    this.highlightBuilder,
    this.orderedListBuilder,
    this.unOrderedListBuilder,
    this.linkBuilder,
    this.imageBuilder,
    this.maxLines,
    this.overflow,
    this.components,
    this.inlineComponents,
    this.tableBuilder,
    this.highlightRanges,
    this.onHighlightRangeTap,
    this.debugShowBlockIndex = false,
  });

  /// The direction of the text.
  final TextDirection textDirection;

  /// The style of the text.
  final TextStyle? style;

  /// The alignment of the text.
  final TextAlign? textAlign;

  /// The text scaler.
  final TextScaler? textScaler;

  /// The callback function to handle link clicks.
  final void Function(String url, String title)? onLinkTap;

  /// The LaTeX workaround.
  final String Function(String tex)? latexWorkaround;

  /// The LaTeX builder.
  final LatexBuilder? latexBuilder;

  /// The source tag builder.
  final SourceTagBuilder? sourceTagBuilder;

  /// Whether to use dollar signs for LaTeX (Ignored in V2 Config, handled wrapper)
  final bool useDollarSignsForLatex;

  /// Whether to follow the link color.
  final bool followLinkColor;

  /// The code builder.
  final CodeBlockBuilder? codeBuilder;

  /// The Ordered List builder.
  final OrderedListBuilder? orderedListBuilder;

  /// The Unordered List builder.
  final UnOrderedListBuilder? unOrderedListBuilder;

  /// The maximum number of lines.
  final int? maxLines;

  /// The overflow.
  final TextOverflow? overflow;

  /// The highlight builder.
  final HighlightBuilder? highlightBuilder;

  /// The link builder.
  final LinkBuilder? linkBuilder;

  /// The image builder.
  final ImageBuilder? imageBuilder;

  /// The list of components.
  final List<MarkdownComponent>? components;

  /// The list of inline components.
  final List<MarkdownComponent>? inlineComponents;

  /// The table builder.
  final TableBuilder? tableBuilder;

  /// Highlight ranges for render-layer highlighting.
  /// These are applied directly to TextSpans during rendering.
  final List<HighlightRangeData>? highlightRanges;

  /// Callback when a highlight range is tapped.
  final HighlightRangeTapCallback? onHighlightRangeTap;

  /// 【调试】是否在每个 Block 前显示索引号
  final bool debugShowBlockIndex;

  /// A copy of the configuration with the specified parameters.
  GptMarkdownConfig copyWith({
    TextStyle? style,
    TextDirection? textDirection,
    final void Function(String url, String title)? onLinkTap,
    final TextAlign? textAlign,
    final TextScaler? textScaler,
    final String Function(String tex)? latexWorkaround,
    final LatexBuilder? latexBuilder,
    final SourceTagBuilder? sourceTagBuilder,
    final bool? followLinkColor,
    final CodeBlockBuilder? codeBuilder,
    final int? maxLines,
    final TextOverflow? overflow,
    final HighlightBuilder? highlightBuilder,
    final LinkBuilder? linkBuilder,
    final ImageBuilder? imageBuilder,
    final OrderedListBuilder? orderedListBuilder,
    final UnOrderedListBuilder? unOrderedListBuilder,
    final List<MarkdownComponent>? components,
    final List<MarkdownComponent>? inlineComponents,
    final TableBuilder? tableBuilder,
    final List<HighlightRangeData>? highlightRanges,
    final HighlightRangeTapCallback? onHighlightRangeTap,
    final bool? useDollarSignsForLatex,
    final bool? debugShowBlockIndex,
  }) {
    return GptMarkdownConfig(
      useDollarSignsForLatex: useDollarSignsForLatex ?? this.useDollarSignsForLatex,
      style: style ?? this.style,
      textDirection: textDirection ?? this.textDirection,
      onLinkTap: onLinkTap ?? this.onLinkTap,
      textAlign: textAlign ?? this.textAlign,
      textScaler: textScaler ?? this.textScaler,
      latexWorkaround: latexWorkaround ?? this.latexWorkaround,
      latexBuilder: latexBuilder ?? this.latexBuilder,
      followLinkColor: followLinkColor ?? this.followLinkColor,
      codeBuilder: codeBuilder ?? this.codeBuilder,
      sourceTagBuilder: sourceTagBuilder ?? this.sourceTagBuilder,
      maxLines: maxLines ?? this.maxLines,
      overflow: overflow ?? this.overflow,
      highlightBuilder: highlightBuilder ?? this.highlightBuilder,
      linkBuilder: linkBuilder ?? this.linkBuilder,
      imageBuilder: imageBuilder ?? this.imageBuilder,
      orderedListBuilder: orderedListBuilder ?? this.orderedListBuilder,
      unOrderedListBuilder: unOrderedListBuilder ?? this.unOrderedListBuilder,
      components: components ?? this.components,
      inlineComponents: inlineComponents ?? this.inlineComponents,
      tableBuilder: tableBuilder ?? this.tableBuilder,
      highlightRanges: highlightRanges ?? this.highlightRanges,
      onHighlightRangeTap: onHighlightRangeTap ?? this.onHighlightRangeTap,
      debugShowBlockIndex: debugShowBlockIndex ?? this.debugShowBlockIndex,
    );
  }

  /// A method to get a rich text widget from an inline span.
  Text getRich(InlineSpan span) {
    return Text.rich(
      span,
      textDirection: textDirection,
      textScaler: textScaler,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// A method to check if the configuration is the same.
  bool isSame(GptMarkdownConfig other) {
    return style == other.style &&
        textAlign == other.textAlign &&
        textScaler == other.textScaler &&
        maxLines == other.maxLines &&
        overflow == other.overflow &&
        followLinkColor == other.followLinkColor &&
        // latexWorkaround == other.latexWorkaround &&
        // components == other.components &&
        // inlineComponents == other.inlineComponents &&
        // latexBuilder == other.latexBuilder &&
        // sourceTagBuilder == other.sourceTagBuilder &&
        // codeBuilder == other.codeBuilder &&
        // orderedListBuilder == other.orderedListBuilder &&
        // unOrderedListBuilder == other.unOrderedListBuilder &&
        // linkBuilder == other.linkBuilder &&
        // imageBuilder == other.imageBuilder &&
        // highlightBuilder == other.highlightBuilder &&
        // onLinkTap == other.onLinkTap &&
        textDirection == other.textDirection;
  }
}
