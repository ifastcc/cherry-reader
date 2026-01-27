import 'package:isar_community/isar.dart';
import '../models/isar/knowledge_entry.dart';
import '../services/isar_database.dart';

class HighlightMigrationService {
  final IsarDatabase _db = IsarDatabase();

  Future<int> migrateAll() async {
    final isar = await _db.instance;

    final entriesToMigrate = await isar.knowledgeEntrys
        .filter()
        .selectionsIsNull()
        .and()
        .blockIndexIsNotNull()
        .and()
        .blockInternalStartIsNotNull()
        .and()
        .blockInternalEndIsNotNull()
        .findAll();

    if (entriesToMigrate.isEmpty) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final e in entriesToMigrate) {
      e.selectionRanges = [
        SelectionRange(
          blockIndex: e.blockIndex!,
          start: e.blockInternalStart!,
          end: e.blockInternalEnd!,
          text: e.quotedText ?? '',
        )
      ];
      e.updatedAt = now;
    }

    await isar.writeTxn(() async {
      await isar.knowledgeEntrys.putAll(entriesToMigrate);
    });

    return entriesToMigrate.length;
  }
}
