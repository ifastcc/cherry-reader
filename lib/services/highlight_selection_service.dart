import '../models/isar/message_block_entity.dart';
import '../models/highlight_data.dart';

class HighlightSelectionService {
  /// Calculates highlight data for a selection that might span multiple blocks.
  /// Returns a list of HighlightData, one per affected block.
  static List<HighlightData> calculateHighlights({
    required List<MessageBlockEntity> blocks,
    required int startBlockIndex,
    required int startOffset,
    required int endBlockIndex,
    required int endOffset,
    int color = 0xFFFBC02D,
  }) {
    // Normalize order
    int firstIndex = startBlockIndex < endBlockIndex ? startBlockIndex : endBlockIndex;
    int lastIndex = startBlockIndex < endBlockIndex ? endBlockIndex : startBlockIndex;
    
    // If standard direction (Start < End), offsets are correct.
    // If reversed (Start > End), we swapped indices, so we must swap offsets too?
    // WARNING: 'startOffset' belongs to 'startBlockIndex'.
    // If we swap indices, we must use the offset belonging to that index.
    
    int internalStartOffset = startBlockIndex <= endBlockIndex ? startOffset : endOffset;
    int internalEndOffset = startBlockIndex <= endBlockIndex ? endOffset : startOffset;
    
    // Also need to handle case where same block but backwards selection (Start > End offsets)
    if (firstIndex == lastIndex) {
      if (internalStartOffset > internalEndOffset) {
        final temp = internalStartOffset;
        internalStartOffset = internalEndOffset;
        internalEndOffset = temp;
      }
    }

    final results = <HighlightData>[];

    for (int i = firstIndex; i <= lastIndex; i++) {
        if (i < 0 || i >= blocks.length) continue;
        
        final block = blocks[i];
        // final blockIdStr = block.blockId; // MessageBlockEntity uses blockId
        final contentLen = block.content?.length ?? 0;
        
        int localS = 0;
        int localE = contentLen;
        
        if (i == firstIndex) {
           localS = internalStartOffset;
        }
        
        if (i == lastIndex) {
           localE = internalEndOffset;
        }
        
        // Clamp
        if (localS < 0) localS = 0;
        if (localE > contentLen) localE = contentLen;
        
        if (localS < localE) {
            final text = block.content?.substring(localS, localE) ?? '';
            
            results.add(HighlightData(
               // blockId: blockIdStr, // Not supported in HighlightData yet
               // localStart: localS,
               // localEnd: localE,
               text: text,
               start: localS, // Storing local offset in global field for now (Temporary)
               end: localE,   
               color: color,
            ));
        }
    }
    
    return results;
  }
}
