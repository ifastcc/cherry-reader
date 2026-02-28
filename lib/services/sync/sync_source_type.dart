enum SyncSourceType {
  webdav('webdav', 'WebDAV'),
  localFolder('localFolder', '本地文件夹'),
  serverSync('serverSync', '同步服务器'),
  manualImport('manualImport', '手动导入');

  final String id;
  final String label;
  const SyncSourceType(this.id, this.label);

  static SyncSourceType? fromId(String id) {
    for (final t in SyncSourceType.values) {
      if (t.id == id) return t;
    }
    return null;
  }
}
