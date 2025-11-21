/// Cherry Studio 消息块状态枚举
enum MessageBlockStatus {
  success('success'),
  streaming('streaming'),
  error('error'),
  paused('paused'),
  pending('pending'),
  processing('processing');

  final String value;
  const MessageBlockStatus(this.value);

  static MessageBlockStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return MessageBlockStatus.success;
      case 'streaming':
        return MessageBlockStatus.streaming;
      case 'error':
        return MessageBlockStatus.error;
      case 'paused':
        return MessageBlockStatus.paused;
      case 'pending':
        return MessageBlockStatus.pending;
      case 'processing':
        return MessageBlockStatus.processing;
      default:
        return MessageBlockStatus.success;
    }
  }
}
