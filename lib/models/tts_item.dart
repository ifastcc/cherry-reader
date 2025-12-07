class TtsItem {
  final String id;
  final String text;
  final String title; // e.g., "Chapter 1" or "Assistant Reply"
  final String? author; // e.g., "GPT-4"
  final String? voiceName; // Optional override
  final String? style; // Optional override
  final bool isMarkdown; // 是否为 Markdown 格式，需要转换为 SSML

  TtsItem({
    required this.id,
    required this.text,
    this.title = 'Untitled',
    this.author,
    this.voiceName,
    this.style,
    this.isMarkdown = true, // 默认为 true，因为大多数内容都是 Markdown
  });
}
