import 'dart:io';

import '../cherry_extractor.dart';
import 'folder_scanner.dart';
import 'ir_builder.dart';

class SourceAdapter {
  final IrBuilder _irBuilder;
  final FolderScanner _folderScanner;

  SourceAdapter({IrBuilder? irBuilder, FolderScanner? folderScanner})
      : _irBuilder = irBuilder ?? IrBuilder(),
        _folderScanner = folderScanner ?? FolderScanner();

  Future<CherryExtractor> loadExtractor(String path) async {
    final entityType = await FileSystemEntity.type(path, followLinks: false);
    if (entityType == FileSystemEntityType.directory) {
      final scan = await _folderScanner.scan(path);
      final result = await _irBuilder.buildFromFolderScan(scan);
      return CherryExtractor.fromCachedData(result.rawData);
    }

    final lower = path.toLowerCase();
    if (lower.endsWith('.md')) {
      final result = await _irBuilder.buildFromMarkdownFile(path);
      return CherryExtractor.fromCachedData(result.rawData);
    }

    final isZip = lower.endsWith('.zip');
    final extractor = CherryExtractor(
      zipPath: isZip ? path : null,
      dataJsonPath: isZip ? null : path,
    );
    await extractor.load();
    return extractor;
  }
}

