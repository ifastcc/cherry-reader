import '../cherry_extractor.dart';
import '../../models/domain/import_result.dart';

abstract class IDataImportService {
  Future<ImportResult> importData(
    CherryExtractor extractor, {
    void Function(double progress, String message)? onProgress,
  });

  Future<void> clearAll();
}
