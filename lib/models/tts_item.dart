class TtsItem {
  final String id;
  final String text;
  final String title; // e.g., "Chapter 1" or "Assistant Reply"
  final String? author; // e.g., "GPT-4"
  final String? voiceName; // Optional override
  final String? style; // Optional override

  TtsItem({
    required this.id,
    required this.text,
    this.title = 'Untitled',
    this.author,
    this.voiceName,
    this.style,
  });
}
