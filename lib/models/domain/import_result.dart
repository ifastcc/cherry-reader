class ImportResult {
  bool success = false;
  String? error;
  int totalTopics = 0;
  int importedTopics = 0;
  int importedMessages = 0;
  int importedFiles = 0;

  @override
  String toString() {
    if (success) {
      return '导入成功: $importedTopics 个话题, $importedMessages 条消息, $importedFiles 个文件';
    } else {
      return '导入失败: $error (已导入 $importedTopics/$totalTopics 个话题)';
    }
  }
}
