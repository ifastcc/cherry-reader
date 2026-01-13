import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import '../custom_widgets/markdown_config.dart';
import 'parser.dart';
import 'visitor.dart';
import '../markdown_parse_result.dart';

class GptMarkdownV2 extends StatelessWidget {
  final String data;
  final GptMarkdownConfig config;
  final ScrollController? controller;

  const GptMarkdownV2({
    super.key,
    required this.data,
    this.config = const GptMarkdownConfig(),
    this.controller,
  });

  /// 【Single Source of Truth】提取纯文本
  /// 使用 GptMarkdownVisitor 轻量模式
  static String extractPlainText(BuildContext context, String data) {
    final document = md.Document(
      extensionSet: GptExtensionSet.all,
    );
    final nodes = document.parseLines(data.split(RegExp(r'\r?\n')));
    
    // 使用轻量配置，不需要高亮渲染
    final visitor = GptMarkdownVisitor(context, const GptMarkdownConfig());
    for (final node in nodes) {
      node.accept(visitor);
    }
    
    return visitor.plainText;
  }

  /// 【Single Source of Truth】生成解析结果
  /// 使用单一 GptMarkdownVisitor 同时生成 Widget、PlainText 和 BlockRegistry
  static MarkdownParseResult generateParseResult(
    BuildContext context,
    String data,
    GptMarkdownConfig config,
  ) {
    // 1. Parse
    final document = md.Document(
      extensionSet: GptExtensionSet.all,
    );
    final nodes = document.parseLines(data.split(RegExp(r'\r?\n')));

    // 2. 【Single Source of Truth】单一 Visitor 生成所有输出
    final visitor = GptMarkdownVisitor(context, config);
    for (final node in nodes) {
      node.accept(visitor);
    }

    return MarkdownParseResult(
      spans: [], // Spans are no longer aggregated centrally
      plainText: visitor.plainText, // 【Single Source of Truth】
      mappings: [], 
      blocks: visitor.blockRegistry,
      blockWidgets: visitor.blocks,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Parse
    final document = md.Document(
      extensionSet: GptExtensionSet.all,
    );
    
    final nodes = document.parseLines(data.split(RegExp(r'\r?\n')));

    // 2. Visit / Render
    final visitor = GptMarkdownVisitor(context, config);
    for (final node in nodes) {
      node.accept(visitor);
    }

    // 3. Build ListView/Column
    // 3. Build ListView/Column
    // Note: We removed the internal SelectionArea to allow parent widgets (like HighlightableCard) 
    // to manage selection validation and toolbars.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: visitor.blocks,
    );
  }
}
