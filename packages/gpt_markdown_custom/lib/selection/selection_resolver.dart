import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Represents a selection within the Block-Based Markdown architecture.
class BlockSelection {
  final int startBlockIndex;
  final int startOffset; // Local offset within the start block
  final int endBlockIndex;
  final int endOffset; // Local offset within the end block
  final String? text; // Selected text (for verification)

  const BlockSelection({
    required this.startBlockIndex,
    required this.startOffset,
    required this.endBlockIndex,
    required this.endOffset,
    this.text,
  });
  
  @override
  String toString() {
    return 'BlockSelection(start: $startBlockIndex@$startOffset, end: $endBlockIndex@$endOffset, text: "$text")';
  }
}

/// Helper to resolve UI selections back to BlockSelection data.
class SelectionResolver {
  
  // Removed unused resolve method

  
  // Revised Strategy: HitTest based resolution
 
  // We can't easily implement "Get User Selection" without private API access or a custom SelectionContainerDelegate.
  // HOWEVER, the user asked to "Implement a SelectionRegistrar OR use SelectionArea callback... to reverse calculate".
  
  // Let's define the Resolver to simply accept `Offset start, Offset end`?
  // And we assume the caller provides them (e.g. from a custom `SelectionArea` fork or a PointerUp event).
  // If we can Resolve `Offset -> Block` via HitTest, that is useful.
  // e.g. `Resolver.hitTest(root, offset)`.
  
  static ({int blockIndex, int localOffset})? hitTest(RenderBox root, Offset globalPosition) {
     final result = BoxHitTestResult();
     // Transform global to local root
     final localPoint = root.globalToLocal(globalPosition);
     if (root.hitTest(result, position: localPoint)) {
         for (final entry in result.path) {
             final target = entry.target;
             if (target is RenderMetaData) {
                 final data = target.metaData;
                 if (data is Map && data.containsKey('blockIndex')) {
                     // Found Block!
                     // Continue to find RenderParagraph to resolve offset
                     // But HitTest path contains "RenderMetaData" then children?
                     // No, "Path" is from LEAF to ROOT.
                     // So we find Paragraph FIRST, then MetaData LATER.
                     
                     // We need to iterate path, look for RenderParagraph.
                     // Then keep looking up for RenderMetaData.
                 }
             }
         }
         
         RenderParagraph? paragraph;
         int? blockIndex;
         
         for (final entry in result.path) {
             final target = entry.target;
             if (target is RenderParagraph) {
                 paragraph = target;
             }
             if (target is RenderMetaData) {
                 if (target.metaData is Map && target.metaData.containsKey('blockIndex')) {
                    blockIndex = target.metaData['blockIndex'] as int;
                    // We found the enclosing block.
                    // If we also have the paragraph, we are good.
                    break; 
                 }
             }
         }
         
         if (blockIndex != null && paragraph != null) {
              // Resolve offset in paragraph
              // We need the local coordinate relative to paragraph.
              // The `entry` in hit test path has `transform`.
              // `entry.transform` helps convert coordinate?
              // Actually `BoxHitTestEntry` has `localPosition`.
              
              // Find the entry for the paragraph
              final pEntry = result.path.firstWhere((e) => e.target == paragraph);
              if (pEntry is BoxHitTestEntry) {
                   final offset = paragraph.getPositionForOffset(pEntry.localPosition);
                   return (blockIndex: blockIndex, localOffset: offset.offset);
              }
         }
     }
     return null;
  }
}
