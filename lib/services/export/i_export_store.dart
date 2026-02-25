import '../../models/domain/export_snapshot.dart';

abstract class IExportStore {
  Future<ExportSnapshot> loadSnapshot();
}
