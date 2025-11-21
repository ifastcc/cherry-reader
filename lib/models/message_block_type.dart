/// Cherry Studio 消息块类型枚举
enum MessageBlockType {
  mainText('main_text'),
  thinking('thinking'),
  image('image'),
  file('file'),
  tool('tool'),
  citation('citation'),
  error('error'),
  translation('translation'),
  code('code'),
  video('video'),
  unknown('unknown');

  final String value;
  const MessageBlockType(this.value);

  static MessageBlockType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'main_text':
        return MessageBlockType.mainText;
      case 'thinking':
        return MessageBlockType.thinking;
      case 'image':
        return MessageBlockType.image;
      case 'file':
        return MessageBlockType.file;
      case 'tool':
        return MessageBlockType.tool;
      case 'citation':
        return MessageBlockType.citation;
      case 'error':
        return MessageBlockType.error;
      case 'translation':
        return MessageBlockType.translation;
      case 'code':
        return MessageBlockType.code;
      case 'video':
        return MessageBlockType.video;
      default:
        return MessageBlockType.unknown;
    }
  }
}
