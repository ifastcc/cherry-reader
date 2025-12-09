import 'dart:async';
import '../repositories/i_assistant_repository.dart';
import '../repositories/i_topic_repository.dart';
import '../repositories/i_message_repository.dart';
import '../repositories/isar/isar_assistant_repository.dart';
import '../repositories/isar/isar_topic_repository.dart';
import '../repositories/isar/isar_message_repository.dart';
import 'isar_database.dart';

/// Repository 提供者（依赖注入）
///
/// 单例模式，提供全局访问的 Repository 实例
/// 便于测试时替换为 Mock 实现
class RepositoryProvider {
  static RepositoryProvider? _instance;
  static Completer<RepositoryProvider>? _initCompleter;

  late final IAssistantRepository assistantRepository;
  late final ITopicRepository topicRepository;
  late final IMessageRepository messageRepository;

  final IsarDatabase _db;

  RepositoryProvider._(this._db) {
    assistantRepository = IsarAssistantRepository(_db);
    topicRepository = IsarTopicRepository(_db);
    messageRepository = IsarMessageRepository(_db);
  }

  /// 初始化 Repository 提供者
  ///
  /// 必须在应用启动时调用
  /// 使用 Completer 防止并发初始化导致的竞态条件
  static Future<RepositoryProvider> init() async {
    // 已初始化，直接返回
    if (_instance != null) return _instance!;

    // 正在初始化，等待完成
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // 开始初始化
    _initCompleter = Completer<RepositoryProvider>();

    try {
      final db = IsarDatabase();
      await db.init();

      _instance = RepositoryProvider._(db);
      _initCompleter!.complete(_instance!);
      print('✅ RepositoryProvider 初始化完成');
      return _instance!;
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  /// 获取实例
  ///
  /// 必须在 init() 调用后使用
  static RepositoryProvider get instance {
    if (_instance == null) {
      throw StateError('RepositoryProvider not initialized. Call init() first.');
    }
    return _instance!;
  }

  /// 检查是否已初始化
  static bool get isInitialized => _instance != null;

  /// 重置实例（仅用于测试）
  static void reset() {
    _instance = null;
  }

  /// 获取数据库实例（用于直接操作或迁移）
  IsarDatabase get database => _db;
}
