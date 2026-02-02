import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_reader/utils/text_cleaner.dart';

void main() {
  group('fixMarkdownStrongAfterCjkPunctuation', () {
    test('inserts html comment before opener when preceded by CJK', () {
      const input = '中文**：加粗**后面';
      final output = fixMarkdownStrongAfterCjkPunctuation(input);
      expect(output, '中文<!-- -->**：加粗**后面');
    });

    test('inserts html comment after closer when followed by CJK', () {
      const input = '一种**“阳亢阴竭”**的极端病态';
      final output = fixMarkdownStrongAfterCjkPunctuation(input);
      expect(output, '一种<!-- -->**“阳亢阴竭”**<!-- -->的极端病态');
    });

    test('does not change when opener is at start', () {
      const input = '**：加粗**';
      final output = fixMarkdownStrongAfterCjkPunctuation(input);
      expect(output, input);
    });

    test('does not change inside fenced code block', () {
      const input = '```\n中文**：加粗**\n```';
      final output = fixMarkdownStrongAfterCjkPunctuation(input);
      expect(output, input);
    });

    test('does not change inside inline code', () {
      const input = '`中文**：加粗**`';
      final output = fixMarkdownStrongAfterCjkPunctuation(input);
      expect(output, input);
    });
  });
}
