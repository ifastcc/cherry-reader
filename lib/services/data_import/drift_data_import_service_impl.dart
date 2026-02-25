import '../app_db.dart';
import '../cherry_extractor.dart';
import '../drift/drift_data_import_service.dart';
import '../../models/domain/import_result.dart';
import 'i_data_import_service.dart';

class DriftDataImportServiceImpl implements IDataImportService {
  final AppDb _db;

  DriftDataImportServiceImpl(this._db);

  @override
  Future<ImportResult> importData(
    CherryExtractor extractor, {
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      await _db.init();

      onProgress?.call(0.05, '正在准备导入...');
      final importService = DriftDataImportService(_db.importDb, extractor);

      final result = await importService.importFromExtractor(
        onProgress: (progress, message) {
          final mappedProgress = 0.05 + progress * 0.93;
          onProgress?.call(mappedProgress, message);
        },
      );

      onProgress?.call(1.0, '导入完成');
      return result;
    } catch (e) {
      return ImportResult()
        ..success = false
        ..error = e.toString();
    }
  }

  @override
  Future<void> clearAll() async {
    await _db.init();
    await _db.clearImportedData();
  }
}
