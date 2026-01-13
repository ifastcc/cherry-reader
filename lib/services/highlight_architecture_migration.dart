import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/isar/knowledge_entry.dart';
import 'knowledge_entry_service.dart';
import 'isar_database.dart';

/// 高亮架构迁移服务
/// 
/// 将旧架构（一次选择 = 多条 groupId 关联记录）迁移到
/// 新架构（一次选择 = 一条记录 + selections 数组）
class HighlightArchitectureMigration {
  static final HighlightArchitectureMigration _instance = 
      HighlightArchitectureMigration._internal();
  factory HighlightArchitectureMigration() => _instance;
  HighlightArchitectureMigration._internal();

  final KnowledgeEntryService _entryService = KnowledgeEntryService();
  final IsarDatabase _db = IsarDatabase();

  /// 执行迁移
  /// 
  /// 将所有 groupId 关联的多条记录合并为单条记录（包含 selections）
  /// 返回迁移的记录数量
  Future<int> migrate() async {
    final isar = await _db.instance;
    
    // 1. 获取所有有 groupId 的高亮记录
    final allEntries = await isar.knowledgeEntrys
        .filter()
        .groupIdIsNotNull()
        .groupIdIsNotEmpty()
        .findAll();
    
    if (allEntries.isEmpty) {
      debugPrint('[Migration] 无需迁移：没有 groupId 关联的记录');
      return 0;
    }
    
    // 2. 按 groupId 分组
    final Map<String, List<KnowledgeEntry>> grouped = {};
    for (final entry in allEntries) {
      grouped.putIfAbsent(entry.groupId!, () => []).add(entry);
    }
    
    int migratedCount = 0;
    
    // 3. 处理每个 group
    for (final groupId in grouped.keys) {
      final group = grouped[groupId]!;
      
      // 只有多条记录的 group 需要合并
      if (group.length <= 1) continue;
      
      debugPrint('[Migration] 合并 groupId: $groupId (${group.length} 条记录)');
      
      // 按 start 排序
      group.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));
      
      // 4. 构建 selections 数组
      final selections = <SelectionRange>[];
      final textParts = <String>[];
      
      for (final entry in group) {
        selections.add(SelectionRange(
          blockIndex: entry.blockIndex ?? 0,
          internalStart: entry.blockInternalStart ?? 0,
          internalEnd: entry.blockInternalEnd ?? (entry.end ?? 0) - (entry.start ?? 0),
          text: entry.quotedText ?? '',
          blockContentHash: entry.blockContentHash,
          globalStart: entry.start ?? 0,
          globalEnd: entry.end ?? 0,
          prefix: entry.prefix,
          suffix: entry.suffix,
        ));
        textParts.add(entry.quotedText ?? '');
      }
      
      // 5. 更新第一条记录为合并后的记录
      final merged = group.first;
      merged.quotedText = textParts.join('\n\n');  // 保留段落换行
      merged.end = group.last.end;
      merged.selectionRanges = selections;
      merged.groupId = null;  // 清除 groupId
      merged.updatedAt = DateTime.now().millisecondsSinceEpoch;
      
      // 6. 保存合并后的记录
      await isar.writeTxn(() async {
        await isar.knowledgeEntrys.put(merged);
      });
      
      // 7. 删除其他记录
      for (int i = 1; i < group.length; i++) {
        await _entryService.deleteEntry(group[i].entryId);
      }
      
      migratedCount++;
    }
    
    debugPrint('[Migration] 迁移完成：合并了 $migratedCount 组记录');
    return migratedCount;
  }

  /// 检查是否需要迁移
  Future<bool> needsMigration() async {
    final isar = await _db.instance;
    
    // 检查是否有多条 groupId 相同的记录
    final entriesWithGroup = await isar.knowledgeEntrys
        .filter()
        .groupIdIsNotNull()
        .groupIdIsNotEmpty()
        .findAll();
    
    final groupCounts = <String, int>{};
    for (final entry in entriesWithGroup) {
      groupCounts[entry.groupId!] = (groupCounts[entry.groupId!] ?? 0) + 1;
    }
    
    // 如果任何 groupId 有多条记录，则需要迁移
    return groupCounts.values.any((count) => count > 1);
  }
}
