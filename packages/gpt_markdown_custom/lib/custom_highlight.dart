import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'markdown_component.dart';
import 'custom_widgets/markdown_config.dart';
import 'theme.dart';

/// 自定义多色高亮组件
///
/// 支持语法：<highlight color="#FFEB3B" id="h1">高亮文本</highlight>
///
/// 功能：
/// - 多色高亮支持
/// - 点击事件回调
/// - 自定义样式（下划线、背景色等）
class CustomHighlightMd extends InlineMd {
  /// 高亮点击回调
  final Function(String id, Offset position)? onHighlightTap;

  CustomHighlightMd({this.onHighlightTap});

  @override
  RegExp get exp => RegExp(
    r'<highlight\s+color="([^"]+)"\s+id="([^"]+)"(?:\s+style="([^"]+)")?>(.+?)</highlight>',
    dotAll: false,
  );

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    if (match == null) {
      return TextSpan(text: text, style: config.style);
    }

    final colorStr = match.group(1) ?? '#FFEB3B'; // 默认黄色
    final id = match.group(2) ?? '';
    final styleType = match.group(3) ?? 'background'; // background | underline
    final highlightedText = match.group(4) ?? '';

    // 解析颜色
    Color color = _parseColor(colorStr);

    // 根据样式类型创建不同的文本样式
    TextStyle textStyle;
    if (styleType == 'underline') {
      textStyle = config.style?.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: color,
        decorationThickness: 2.0,
        decorationStyle: TextDecorationStyle.solid,
      ) ?? TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: color,
        decorationThickness: 2.0,
      );
    } else {
      // 默认背景高亮
      textStyle = config.style?.copyWith(
        background: Paint()
          ..color = color.withAlpha(180)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      ) ?? TextStyle(
        background: Paint()
          ..color = color.withAlpha(180)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 如果有点击回调，创建可点击的 TextSpan
    if (onHighlightTap != null) {
      return TextSpan(
        text: highlightedText,
        style: textStyle,
        recognizer: TapGestureRecognizer()
          ..onTapDown = (details) {
            onHighlightTap!(id, details.globalPosition);
          },
      );
    }

    return TextSpan(text: highlightedText, style: textStyle);
  }

  /// 解析颜色字符串（支持 #RRGGBB 和 #AARRGGBB 格式）
  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        final hexStr = colorStr.substring(1);
        if (hexStr.length == 6) {
          // #RRGGBB
          return Color(int.parse('FF$hexStr', radix: 16));
        } else if (hexStr.length == 8) {
          // #AARRGGBB
          return Color(int.parse(hexStr, radix: 16));
        }
      }
    } catch (e) {
      // 解析失败返回默认黄色
    }
    return const Color(0xFFFBC02D);
  }
}
