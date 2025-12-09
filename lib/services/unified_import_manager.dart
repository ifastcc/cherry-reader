import '../models/isar/assistant_entity.dart';
import '../models/isar/topic_entity.dart';
import '../models/isar/message_entity.dart';
import '../models/isar/message_block_entity.dart';
import '../models/isar/file_entity.dart';
import 'cherry_extractor.dart';
import 'data_import_service.dart';
import 'isar_database.dart';

/// 数据导入管理器
///
/// 负责将 Cherry Studio 数据导入到 Isar 数据库
/// 存储架构：TopicEntity + MessageEntity + MessageBlockEntity
class DataImportManager {
  final IsarDatabase _db;

  DataImportManager(this._db);

  /// 导入数据
  ///
  /// [extractor] 已加载的 CherryExtractor
  /// [onProgress] 进度回调
  Future<ImportResult> importData(
    CherryExtractor extractor, {
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      onProgress?.call(0.05, '正在准备导入...');

      final importService = DataImportService(_db, extractor);

      final result = await importService.importFromExtractor(
        onProgress: (progress, message) {
          // 将进度映射到 5%-98%
          final mappedProgress = 0.05 + progress * 0.93;
          onProgress?.call(mappedProgress, message);
        },
      );

      onProgress?.call(1.0, '导入完成');

      return result;
    } catch (e) {
      print('❌ 导入失败: $e');
      return ImportResult()
        ..success = false
        ..error = e.toString();
    }
  }

  /// 清除所有数据（用于重新导入）
  Future<void> clearAll() async {
    final isar = await _db.instance;
    await isar.writeTxn(() async {
      await isar.assistantEntitys.clear();
      await isar.topicEntitys.clear();
      await isar.messageEntitys.clear();
      await isar.messageBlockEntitys.clear();
      await isar.fileEntitys.clear();
    });
    print('✅ 已清除所有数据');
  }
}
