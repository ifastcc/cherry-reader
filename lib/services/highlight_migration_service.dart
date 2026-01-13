
import 'package:isar_community/isar.dart';
import '../models/isar/knowledge_entry.dart';
import '../models/isar/markdown_block_entity.dart';
import '../services/isar_database.dart';
import '../services/markdown_block_service.dart';
import '../widgets/unified_markdown_renderer.dart';
import 'package:gpt_markdown_custom/gpt_markdown.dart';
import 'package:flutter/widgets.dart';

class HighlightMigrationService {
  final IsarDatabase _db = IsarDatabase();
  final MarkdownBlockService _blockService;

  HighlightMigrationService(this._blockService);

  /// Migrates all KnowledgeEntries with missing blockId to use Block-Based Local Offsets.
  Future<void> migrateAll() async {
    final isar = await _db.instance;
    
    // 1. Find all highlights needing migration
    final entriesToMigrate = await isar.knowledgeEntrys
        .filter()
        .blockIdIsNull()
        .and()
        .quotedTextIsNotEmpty()
        .findAll();
        
    print("Found ${entriesToMigrate.length} entries to migrate.");
    if (entriesToMigrate.isEmpty) return;

    // Group by Message ID
    final Map<String, List<KnowledgeEntry>> byMessage = {};
    for (final e in entriesToMigrate) {
       if (e.messageId != null) {
         byMessage.putIfAbsent(e.messageId!, () => []).add(e);
       }
    }
    
    // Process each message
    for (final messageId in byMessage.keys) {
       await _migrateMessage(isar, messageId, byMessage[messageId]!);
    }
  }

  Future<void> _migrateMessage(Isar isar, String messageId, List<KnowledgeEntry> entries) async {
      // 1. Fetch Blocks for this message
      // Note: We need a way to get blocks sorted.
      final blocks = await isar.markdownBlockEntitys
         .filter()
         .rootMessageIdEqualTo(messageId)
         .sortByOrderIndex()
         .findAll();
         
      if (blocks.isEmpty) {
         print("Skipping migration for message $messageId: No blocks found.");
         return;
      }
      
      // Calculate Block Global Offsets
      // We assume blocks are joined by '\n'
      final List<int> blockOffsets = [];
      int currentOffset = 0;
      for (final b in blocks) {
        blockOffsets.add(currentOffset);
        currentOffset += b.content.length + 1; // +1 for newline gap
      }
      
      // Map Entries
      final updates = <KnowledgeEntry>[];
      
      for (final entry in entries) {
         if (entry.start == null || entry.end == null) continue;
         
         final globalStart = entry.start!;
         
         // Find Block
         // Find largest blockOffset <= globalStart
         int blockIndex = -1;
         for (int i = 0; i < blockOffsets.length; i++) {
           if (blockOffsets[i] <= globalStart) {
             blockIndex = i;
           } else {
             break;
           }
         }
         
         if (blockIndex != -1) {
            final block = blocks[blockIndex];
            final startOffset = blockOffsets[blockIndex];
            final localStart = globalStart - startOffset;
            final localEnd = entry.end! - startOffset;
            
            // Verify bounds (relaxed)
            // If localStart > block length, something is wrong with global alignment.
            // But we migrate best-effort.
            
            entry.blockId = block.id.toString(); // assuming block.id is int? 
            // Wait, block.id is Isar Id (int). KnowledgeEntry.blockId is String?
            // Schema defines it as String?
            // Let's use string.
            
            entry.localStart = localStart;
            // Clamp end if needed? Or allow overflow? 
            // Local model strictness: end should be relative to block start.
            entry.localEnd = localEnd; 
            
            updates.add(entry);
            print("Migrated Entry ${entry.id} -> Block ${block.id} ($localStart - $localEnd)");
         } else {
            print("Failed to map Entry ${entry.id} (Start: $globalStart) to any block.");
         }
      }
      
      if (updates.isNotEmpty) {
        await isar.writeTxn(() async {
           await isar.knowledgeEntrys.putAll(updates);
        });
      }
  }
}
