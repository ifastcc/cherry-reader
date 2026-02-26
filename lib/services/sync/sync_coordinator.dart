import 'dart:async';
import 'dart:io';

import '../lan_http_sync/lan_http_sync_pull_prefs.dart';
import '../local_folder_sync_service.dart';
import '../webdav_service.dart';
import 'sync_candidate.dart';
import 'sync_preferences.dart';
import 'sync_source_type.dart';

class SyncDiscoveryResult {
  final List<SyncCandidate> candidates;
  final List<String> warnings;

  const SyncDiscoveryResult({required this.candidates, required this.warnings});
}

class SyncDecision {
  final SyncCandidate? selected;
  final bool shouldSync;
  final String? reason;

  const SyncDecision({
    required this.selected,
    required this.shouldSync,
    this.reason,
  });
}

class SyncCoordinator {
  static final SyncCoordinator _instance = SyncCoordinator._internal();
  factory SyncCoordinator() => _instance;
  static SyncCoordinator get instance => _instance;

  SyncCoordinator._internal();

  LocalFolderSyncService? _localWatcher;
  final _candidateController = StreamController<SyncCandidate>.broadcast();
  Stream<SyncCandidate> get candidateStream => _candidateController.stream;

  Future<void> init() async {
    await SyncPreferences.migrateFromLegacyIfNeeded();
  }

  Future<void> startWatchingLocalFolderIfEnabled() async {
    final sources = await SyncPreferences.getAutoSources();
    final enabled = sources[SyncSourceType.localFolder] ?? false;
    if (!enabled) {
      await stopWatchingLocalFolder();
      return;
    }

    final config = await LocalFolderSyncService.loadConfig();
    if (!config.isValid) {
      await stopWatchingLocalFolder();
      return;
    }

    _localWatcher?.dispose();
    final watcher = LocalFolderSyncService();
    watcher.onFileChanged = (backup) {
      _candidateController.add(
        SyncCandidate(
          sourceType: SyncSourceType.localFolder,
          name: backup.name,
          remoteId: backup.path,
          size: backup.size,
          modifiedAt: backup.modifiedTime,
          displayName: backup.displayName,
        ),
      );
    };
    await watcher.startWatching(config);
    _localWatcher = watcher;
  }

  Future<void> stopWatchingLocalFolder() async {
    _localWatcher?.dispose();
    _localWatcher = null;
  }

  Future<SyncDiscoveryResult> discoverLatestCandidates() async {
    final sources = await SyncPreferences.getAutoSources();
    final enabledTypes = <SyncSourceType>{};
    for (final entry in sources.entries) {
      if (entry.value == true) enabledTypes.add(entry.key);
    }
    return _discoverLatestCandidatesForTypes(enabledTypes);
  }

  Future<SyncDiscoveryResult> discoverLatestCandidatesForTypes(
    Set<SyncSourceType> enabledTypes,
  ) async {
    return _discoverLatestCandidatesForTypes(enabledTypes);
  }

  Future<SyncDiscoveryResult> _discoverLatestCandidatesForTypes(
    Set<SyncSourceType> enabledTypes,
  ) async {
    final warnings = <String>[];
    final out = <SyncCandidate>[];

    bool enabled(SyncSourceType type) => enabledTypes.contains(type);

    if (enabled(SyncSourceType.lanReceive)) {
      final inbox = await SyncPreferences.getInboxCandidate(
        SyncSourceType.lanReceive,
      );
      if (inbox != null && inbox.remoteId.isNotEmpty) {
        final f = File(inbox.remoteId);
        if (await f.exists()) {
          out.add(inbox);
        }
      }
    }

    if (enabled(SyncSourceType.webdav)) {
      final config = await WebDavService.loadConfig();
      if (!config.isValid) {
        warnings.add('WebDAV 配置不完整');
      } else {
        final latest = await WebDavService.findLatestBackup(config);
        if (latest != null) {
          out.add(
            SyncCandidate(
              sourceType: SyncSourceType.webdav,
              name: latest.name ?? '',
              remoteId: '${config.path}/${latest.name}',
              size: latest.size ?? 0,
              modifiedAt: latest.mTime ?? DateTime(1970),
            ),
          );
        }
      }
    }

    if (enabled(SyncSourceType.localFolder)) {
      final config = await LocalFolderSyncService.loadConfig();
      if (!config.isValid) {
        warnings.add('本地文件夹未配置');
      } else {
        final latest = await LocalFolderSyncService.findLatestBackup(config);
        if (latest != null) {
          out.add(
            SyncCandidate(
              sourceType: SyncSourceType.localFolder,
              name: latest.name,
              remoteId: latest.path,
              size: latest.size,
              modifiedAt: latest.modifiedTime,
              displayName: latest.displayName,
            ),
          );
        }
      }
    }

    if (enabled(SyncSourceType.httpPull)) {
      final inbox = await SyncPreferences.getInboxCandidate(
        SyncSourceType.httpPull,
      );
      if (inbox != null && inbox.remoteId.isNotEmpty) {
        final f = File(inbox.remoteId);
        if (await f.exists()) {
          out.add(inbox);
        }
      }

      final prefs = await LanHttpSyncPullPrefs.load();
      final info = await LanHttpSyncPullPrefs.fetchLatestInfo(
        baseUrl: prefs.baseUrl,
        token: prefs.token,
      );
      if (info == null) {
        warnings.add('HTTP 同步源不可用或未配置');
      } else {
        out.add(
          SyncCandidate(
            sourceType: SyncSourceType.httpPull,
            name: info.name,
            remoteId: LanHttpSyncPullPrefs.buildDownloadUrl(prefs.baseUrl),
            size: info.size,
            modifiedAt: info.modifiedAt,
          ),
        );
      }
    }

    return SyncDiscoveryResult(candidates: out, warnings: warnings);
  }

  SyncCandidate? chooseLatest(List<SyncCandidate> candidates) {
    if (candidates.isEmpty) return null;
    final sorted = [...candidates]
      ..sort((a, b) {
        final cmp = b.modifiedAt.compareTo(a.modifiedAt);
        if (cmp != 0) return cmp;
        final sizeCmp = b.size.compareTo(a.size);
        if (sizeCmp != 0) return sizeCmp;
        final aLocal = File(a.remoteId).existsSync();
        final bLocal = File(b.remoteId).existsSync();
        if (aLocal == bLocal) return 0;
        return bLocal ? 1 : -1;
      });
    return sorted.first;
  }

  Future<SyncDecision> decideWhetherToSync(SyncCandidate candidate) async {
    final lastFingerprint = await SyncPreferences.getLastImportedFingerprint();
    final lastSourceType = await SyncPreferences.getLastImportedSourceType();

    // 来源切换时不能仅用时间戳判定“已是最新”，否则可能误跳过同步。
    if (lastSourceType != null && lastSourceType != candidate.sourceType) {
      return SyncDecision(
        selected: candidate,
        shouldSync: true,
        reason: '同步来源已切换，执行更新',
      );
    }

    if (lastFingerprint == null) {
      return SyncDecision(selected: candidate, shouldSync: true);
    }
    if (lastFingerprint == candidate.fingerprint) {
      return SyncDecision(
        selected: candidate,
        shouldSync: false,
        reason: '已是最新版本',
      );
    }
    final lastModified = await SyncPreferences.getLastImportedModifiedAt();
    if (lastModified != null &&
        candidate.modifiedAt.toUtc().millisecondsSinceEpoch <=
            lastModified.toUtc().millisecondsSinceEpoch) {
      return SyncDecision(
        selected: candidate,
        shouldSync: false,
        reason: '已是最新版本',
      );
    }
    return SyncDecision(selected: candidate, shouldSync: true);
  }

  Future<String?> fetchToAppDataPath(
    SyncCandidate candidate, {
    void Function(int received, int total)? onWebDavProgress,
  }) async {
    switch (candidate.sourceType) {
      case SyncSourceType.webdav:
        final config = await WebDavService.loadConfig();
        if (!config.isValid) return null;
        final list = await WebDavService.listBackupFiles(config);
        BackupFileInfo? target;
        for (final item in list) {
          if (item.name == candidate.name) {
            target = item;
            break;
          }
        }
        if (target == null) return null;
        return WebDavService.downloadBackup(
          config,
          target.webdavFile,
          onProgress: onWebDavProgress,
        );
      case SyncSourceType.localFolder:
        return LocalFolderSyncService.loadBackup(
          LocalBackupInfo(
            name: candidate.name,
            path: candidate.remoteId,
            size: candidate.size,
            modifiedTime: candidate.modifiedAt,
          ),
        );
      case SyncSourceType.lanReceive:
        if (candidate.remoteId.isEmpty) return null;
        final f = File(candidate.remoteId);
        if (await f.exists()) return candidate.remoteId;
        return null;
      case SyncSourceType.httpPull:
        final asFile = File(candidate.remoteId);
        if (await asFile.exists()) {
          return candidate.remoteId;
        }
        final prefs = await LanHttpSyncPullPrefs.load();
        return LanHttpSyncPullPrefs.downloadLatestToAppData(
          baseUrl: prefs.baseUrl,
          token: prefs.token,
          onProgress: onWebDavProgress,
        );
      case SyncSourceType.serverSync:
        // serverSync 走独立的增量同步流程（ServerSyncService.incrementalSync）
        // 不需要下载 zip 文件
        return null;
      case SyncSourceType.manualImport:
        return null;
    }
  }
}
