import 'markdown_component.dart';

/// 从 Markdown 源文本提取渲染后的纯文本
///
/// 这个工具类复用 MarkdownComponent 的解析逻辑，
/// 但只提取最终显示给用户的纯文本，用于高亮匹配等场景。
class PlainTextExtractor {
  /// 从 Markdown 源文本提取渲染后的纯文本
  ///
  /// 处理逻辑：
  /// 1. 使用与渲染相同的正则表达式解析 Markdown
  /// 2. 移除语法标记（如 >, **, ` 等）
  /// 3. 保留最终显示的文本内容
  ///
  /// [source] 原始 Markdown 文本
  /// [useDollarSignsForLatex] 是否使用 $ 符号表示 LaTeX
  static String extractPlainText(String source, {bool useDollarSignsForLatex = false}) {
    String text = source.trim();
    
    // 与 GptMarkdown.build 相同的 LaTeX 处理
    if (useDollarSignsForLatex) {
      text = text.replaceAllMapped(
        RegExp(r"(?<!\\)\$\$(.*?)(?<!\\)\$\$", dotAll: true),
        (match) => "\\[${match[1] ?? ""}\\]",
      );
      if (!text.contains(r"\(")) {
        text = text.replaceAllMapped(
          RegExp(r"(?<!\\)\$(.*?)(?<!\\)\$"),
          (match) => "\\(${match[1] ?? ""}\\)",
        );
        text = text.splitMapJoin(
          RegExp(r"\[.*?\]|\(.*?\)"),
          onNonMatch: (p0) {
            return p0.replaceAll("\\\$", "\$");
          },
        );
      }
    }
    
    final buffer = StringBuffer();
    _extractFromText(text, buffer, includeGlobalComponents: true);
    return buffer.toString();
  }
  
  /// 递归提取纯文本
  static void _extractFromText(
    String text,
    StringBuffer buffer, {
    required bool includeGlobalComponents,
  }) {
    if (text.isEmpty) return;
    
    final components = includeGlobalComponents
        ? MarkdownComponent.globalComponents
        : MarkdownComponent.inlineComponents;
    
    Iterable<String> regexes = components.map<String>((e) => e.exp.pattern);
    final combinedRegex = RegExp(
      regexes.join("|"),
      multiLine: true,
      dotAll: true,
    );
    
    text.splitMapJoin(
      combinedRegex,
      onMatch: (p0) {
        String element = p0[0] ?? "";
        for (var each in components) {
          var p = each.exp.pattern;
          var exp = RegExp(
            '^$p\$',
            multiLine: each.exp.isMultiLine,
            dotAll: each.exp.isDotAll,
          );
          if (exp.hasMatch(element)) {
            _extractFromComponent(each, element, buffer);
            return "";
          }
        }
        return "";
      },
      onNonMatch: (p0) {
        if (p0.isEmpty) return "";
        
        if (includeGlobalComponents) {
          // 递归处理内联组件
          _extractFromText(p0, buffer, includeGlobalComponents: false);
        } else {
          // 纯文本直接添加
          buffer.write(p0);
        }
        return "";
      },
    );
  }
  
  /// 从特定组件提取纯文本
  static void _extractFromComponent(
    MarkdownComponent component,
    String text,
    StringBuffer buffer,
  ) {
    // 根据组件类型提取内容
    if (component is BlockQuote) {
      // 引用块：移除 > 符号
      _extractBlockQuote(text, buffer);
    } else if (component is HTag) {
      // 标题：移除 # 符号
      _extractHeading(text, buffer);
    } else if (component is BoldMd) {
      // 粗体：移除 ** 符号
      _extractBold(text, buffer);
    } else if (component is ItalicMd) {
      // 斜体：移除 * 符号
      _extractItalic(text, buffer);
    } else if (component is StrikeMd) {
      // 删除线：移除 ~~ 符号
      _extractStrike(text, buffer);
    } else if (component is UnderLineMd) {
      // 下划线
      _extractUnderline(text, buffer);
    } else if (component is HighlightedText) {
      // 高亮/行内代码：移除 ` 符号
      _extractHighlight(text, buffer);
    } else if (component is UnOrderedList) {
      // 无序列表：移除 - 或 * 符号
      _extractUnorderedList(text, buffer);
    } else if (component is OrderedList) {
      // 有序列表：保留数字和内容
      _extractOrderedList(text, buffer);
    } else if (component is NewLines) {
      // 换行
      buffer.write("\n\n");
    } else if (component is LatexMath) {
      // 行内 LaTeX：提取公式内容
      _extractInlineLatex(text, buffer);
    } else if (component is LatexMathMultiLine) {
      // 块级 LaTeX：提取公式内容
      _extractBlockLatex(text, buffer);
    } else if (component is ATagMd) {
      // 链接：提取链接文本
      _extractLink(text, buffer);
    } else if (component is CodeBlockMd) {
      // 代码块：提取代码内容
      _extractCodeBlock(text, buffer);
    } else if (component is HrLine) {
      // 水平线：忽略
    } else if (component is CheckBoxMd) {
      // 复选框
      _extractCheckbox(text, buffer);
    } else if (component is RadioButtonMd) {
      // 单选框
      _extractRadioButton(text, buffer);
    } else if (component is IndentMd) {
      // 缩进
      _extractIndent(text, buffer);
    } else if (component is SourceTag) {
      // 来源标签：提取数字
      _extractSourceTag(text, buffer);
    } else if (component is TableMd) {
      // 表格
      _extractTable(text, buffer);
    } else if (component is ImageMd) {
      // 图片：提取 alt 文本
      _extractImage(text, buffer);
    } else {
      // 未知组件：尝试保留原文
      buffer.write(text);
    }
  }
  
  // ========== 各组件的纯文本提取逻辑 ==========
  
  static void _extractBlockQuote(String text, StringBuffer buffer) {
    final exp = RegExp(
      r"(?:(?:^)\ *>[^\n]+)(?:(?:\n)\ *>[^\n]+)*",
      dotAll: true,
      multiLine: true,
    );
    var match = exp.firstMatch(text);
    if (match == null) return;
    
    var m = match[0] ?? '';
    for (var each in m.split('\n')) {
      if (each.startsWith(RegExp(r'\ *>'))) {
        var subString = each.trimLeft().substring(1);
        if (subString.startsWith(' ')) {
          subString = subString.substring(1);
        }
        // 递归处理引用块内容
        _extractFromText(subString, buffer, includeGlobalComponents: true);
        buffer.write('\n');
      } else {
        _extractFromText(each, buffer, includeGlobalComponents: true);
        buffer.write('\n');
      }
    }
  }
  
  static void _extractHeading(String text, StringBuffer buffer) {
    final exp = RegExp(r"^\ *(?<hash>#{1,6})\ (?<data>[^\n]+?)$", multiLine: true);
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      var data = match.namedGroup('data') ?? '';
      _extractFromText(data, buffer, includeGlobalComponents: false);
      buffer.write('\n');
    }
  }
  
  static void _extractBold(String text, StringBuffer buffer) {
    final exp = RegExp(r"(?<!\*)\*\*(?<!\s)(.+?)(?<!\s)\*\*(?!\*)");
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      _extractFromText(match[1] ?? '', buffer, includeGlobalComponents: false);
    }
  }
  
  static void _extractItalic(String text, StringBuffer buffer) {
    final exp = RegExp(r"(?:(?<!\*)\*(?<!\s)(.+?)(?<!\s)\*(?!\*))", dotAll: true);
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      _extractFromText(match[1] ?? match[2] ?? '', buffer, includeGlobalComponents: false);
    }
  }
  
  static void _extractStrike(String text, StringBuffer buffer) {
    final exp = RegExp(r"(?<!\*)~~(?<!\s)(.+?)(?<!\s)~~(?!\*)");
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      _extractFromText(match[1] ?? '', buffer, includeGlobalComponents: false);
    }
  }
  
  static void _extractUnderline(String text, StringBuffer buffer) {
    final exp = RegExp(r"<u>(.*?)(?:</u>|$)", multiLine: true, dotAll: true);
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      _extractFromText(match[1] ?? '', buffer, includeGlobalComponents: false);
    }
  }
  
  static void _extractHighlight(String text, StringBuffer buffer) {
    final exp = RegExp(r"`(?!`)(.+?)(?<!`)`(?!`)");
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      buffer.write(match[1] ?? '');
    }
  }
  
  static void _extractUnorderedList(String text, StringBuffer buffer) {
    final exp = RegExp(r"^\ *(?:\-|\*)\ ([^\n]+)$", multiLine: true);
    var match = exp.firstMatch(text);
    if (match != null) {
      _extractFromText(match[1]?.trim() ?? '', buffer, includeGlobalComponents: true);
      buffer.write('\n');
    }
  }
  
  static void _extractOrderedList(String text, StringBuffer buffer) {
    final exp = RegExp(r"^\ *([0-9]+)\.\ ([^\n]+)$", multiLine: true);
    var match = exp.firstMatch(text);
    if (match != null) {
      buffer.write('${match[1]}. ');
      _extractFromText(match[2]?.trim() ?? '', buffer, includeGlobalComponents: true);
      buffer.write('\n');
    }
  }
  
  static void _extractInlineLatex(String text, StringBuffer buffer) {
    final exp = RegExp(r"\\\\?\((.+?)\\\\?\)", dotAll: true);
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      // LaTeX 公式作为整体保留
      buffer.write(match[1] ?? '');
    }
  }
  
  static void _extractBlockLatex(String text, StringBuffer buffer) {
    final exp = RegExp(r"\ *\\?\[((?:.)*?)\\?\]|(\ *\\begin.*?\\end{.*?})", dotAll: true);
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      buffer.write(match[1] ?? match[2] ?? '');
      buffer.write('\n');
    }
  }
  
  static void _extractLink(String text, StringBuffer buffer) {
    // [text](url) 或 [text](url "title")
    final exp = RegExp(r'\[([^\]]+)\]\([^\)]+\)');
    var match = exp.firstMatch(text);
    if (match != null) {
      _extractFromText(match[1] ?? '', buffer, includeGlobalComponents: false);
    }
  }
  
  static void _extractCodeBlock(String text, StringBuffer buffer) {
    // ```lang\ncode\n``` 
    final exp = RegExp(r"```(?:\w*)\n?([\s\S]*?)```", dotAll: true);
    var match = exp.firstMatch(text);
    if (match != null) {
      buffer.write(match[1] ?? '');
      buffer.write('\n');
    }
  }
  
  static void _extractCheckbox(String text, StringBuffer buffer) {
    final exp = RegExp(r"^\[(?:\x|\ )\]\ (\S[^\n]*?)$", multiLine: true);
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      _extractFromText(match[1] ?? '', buffer, includeGlobalComponents: true);
      buffer.write('\n');
    }
  }
  
  static void _extractRadioButton(String text, StringBuffer buffer) {
    final exp = RegExp(r"^\((?:\x|\ )\)\ (\S[^\n]*)$", multiLine: true);
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      _extractFromText(match[1] ?? '', buffer, includeGlobalComponents: true);
      buffer.write('\n');
    }
  }
  
  static void _extractIndent(String text, StringBuffer buffer) {
    final exp = RegExp(r"^(\ \ +)([^\n]+)$", multiLine: true);
    var match = exp.firstMatch(text);
    if (match != null) {
      _extractFromText(match[2]?.trim() ?? '', buffer, includeGlobalComponents: false);
    }
  }
  
  static void _extractSourceTag(String text, StringBuffer buffer) {
    final exp = RegExp(r"(?:【.*?)?\[(\d+?)\]");
    var match = exp.firstMatch(text.trim());
    if (match != null) {
      buffer.write('[${match[1]}]');
    }
  }
  
  static void _extractTable(String text, StringBuffer buffer) {
    // 表格较复杂，简单提取每个单元格
    final lines = text.split('\n');
    for (var line in lines) {
      // 跳过分隔行
      if (RegExp(r'^[\|\-\:\s]+$').hasMatch(line)) continue;
      
      // 提取单元格内容
      final cells = line.split('|').where((c) => c.trim().isNotEmpty);
      for (var cell in cells) {
        _extractFromText(cell.trim(), buffer, includeGlobalComponents: false);
        buffer.write('\t');
      }
      buffer.write('\n');
    }
  }
  
  static void _extractImage(String text, StringBuffer buffer) {
    // ![alt](url)
    final exp = RegExp(r'!\[([^\]]*)\]\([^\)]+\)');
    var match = exp.firstMatch(text);
    if (match != null) {
      var alt = match[1] ?? '';
      if (alt.isNotEmpty) {
        buffer.write(alt);
      }
    }
  }
}
