import 'package:drift/drift.dart';

import '../../models/domain/assistant_model.dart';
import '../../services/drift/app_database.dart';
import '../i_assistant_repository.dart';

class DriftAssistantRepository implements IAssistantRepository {
  final ImportDatabase _db;

  DriftAssistantRepository(this._db);

  AssistantModel _toModel(Assistant row) {
    return AssistantModel(
      assistantId: row.assistantId,
      name: row.name,
      description: row.description,
      avatar: row.avatar,
      prompt: row.prompt,
      topicCount: row.topicCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<List<AssistantModel>> getAllAssistants() async {
    final query = _db.select(_db.assistants)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
      ]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<AssistantModel?> getAssistant(String assistantId) async {
    final query = _db.select(_db.assistants)
      ..where((t) => t.assistantId.equals(assistantId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<int> getAssistantCount() async {
    final countExp = _db.assistants.assistantId.count();
    final row = await (_db.selectOnly(_db.assistants)..addColumns([countExp]))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<void> saveAssistant(AssistantModel assistant) async {
    await _db.into(_db.assistants).insertOnConflictUpdate(
          AssistantsCompanion(
            assistantId: Value(assistant.assistantId),
            name: Value(assistant.name),
            description: Value(assistant.description),
            avatar: Value(assistant.avatar),
            prompt: Value(assistant.prompt),
            topicCount: Value(assistant.topicCount),
            createdAt: Value(assistant.createdAt),
            updatedAt: Value(assistant.updatedAt),
          ),
        );
  }

  @override
  Future<void> saveAssistants(List<AssistantModel> assistants) async {
    if (assistants.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(
        _db.assistants,
        assistants
            .map(
              (a) => AssistantsCompanion(
                assistantId: Value(a.assistantId),
                name: Value(a.name),
                description: Value(a.description),
                avatar: Value(a.avatar),
                prompt: Value(a.prompt),
                topicCount: Value(a.topicCount),
                createdAt: Value(a.createdAt),
                updatedAt: Value(a.updatedAt),
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  @override
  Future<void> deleteAssistant(String assistantId) async {
    await (_db.delete(_db.assistants)
          ..where((t) => t.assistantId.equals(assistantId)))
        .go();
  }

  @override
  Future<void> clearAllAssistants() async {
    await _db.delete(_db.assistants).go();
  }

  @override
  Future<void> updateTopicCount(String assistantId, int topicCount) async {
    await (_db.update(_db.assistants)
          ..where((t) => t.assistantId.equals(assistantId)))
        .write(
      AssistantsCompanion(
        topicCount: Value(topicCount),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
