import 'cherry_extractor.dart';
import 'data_import/i_data_import_service.dart';
import '../models/domain/import_result.dart';

/// 数据导入管理器
///
/// 负责将 Cherry Studio 数据导入到 SQLite（Drift）数据库
class DataImportManager {
  final IDataImportService _service;

  DataImportManager(this._service);

  /// 导入数据
  ///
  /// [extractor] 已加载的 CherryExtractor
  /// [onProgress] 进度回调
  Future<ImportResult> importData(
    CherryExtractor extractor, {
    void Function(double progress, String message)? onProgress,
  }) async {
    return _service.importData(extractor, onProgress: onProgress);
  }

  /// 清除所有数据（用于重新导入）
  Future<void> clearAll() async {
    await _service.clearAll();
  }
}
