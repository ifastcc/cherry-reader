import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// 性能监控工具
///
/// 使用方式：
/// 1. 在 main.dart 中启用: PerformanceMonitor.enable();
/// 2. 在代码中使用: PerformanceMonitor.trace('操作名称', () { ... });
/// 3. 监控帧率: PerformanceMonitor.startFrameMonitoring();
class PerformanceMonitor {
  static bool _enabled = false;
  static final Map<String, List<int>> _traces = {};
  static int _frameCount = 0;
  static int _jankCount = 0;
  static DateTime? _frameMonitorStart;

  /// 启用性能监控
  static void enable() {
    _enabled = true;
    debugPrint('🔧 [PerformanceMonitor] 性能监控已启用');
  }

  /// 禁用性能监控
  static void disable() {
    _enabled = false;
    debugPrint('🔧 [PerformanceMonitor] 性能监控已禁用');
  }

  /// 追踪同步操作耗时
  static T trace<T>(String name, T Function() operation) {
    if (!_enabled) return operation();

    final sw = Stopwatch()..start();
    final result = operation();
    sw.stop();

    _recordTrace(name, sw.elapsedMicroseconds);
    return result;
  }

  /// 追踪异步操作耗时
  static Future<T> traceAsync<T>(String name, Future<T> Function() operation) async {
    if (!_enabled) return operation();

    final sw = Stopwatch()..start();
    final result = await operation();
    sw.stop();

    _recordTrace(name, sw.elapsedMicroseconds);
    return result;
  }

  /// 记录追踪数据
  static void _recordTrace(String name, int microseconds) {
    _traces.putIfAbsent(name, () => []);
    _traces[name]!.add(microseconds);

    // 如果耗时超过 16ms（一帧的时间），打印警告
    if (microseconds > 16000) {
      debugPrint('⚠️ [Perf] $name 耗时 ${(microseconds / 1000).toStringAsFixed(2)}ms (超过一帧)');
    } else {
      debugPrint('📊 [Perf] $name 耗时 ${(microseconds / 1000).toStringAsFixed(2)}ms');
    }
  }

  /// 开始帧率监控
  static void startFrameMonitoring() {
    if (!_enabled) {
      debugPrint('⚠️ [PerformanceMonitor] 请先调用 enable() 启用监控');
      return;
    }

    _frameCount = 0;
    _jankCount = 0;
    _frameMonitorStart = DateTime.now();

    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    debugPrint('🎬 [PerformanceMonitor] 帧率监控已开始');
  }

  /// 停止帧率监控并输出报告
  static void stopFrameMonitoring() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);

    if (_frameMonitorStart == null) return;

    final duration = DateTime.now().difference(_frameMonitorStart!);
    final fps = _frameCount / duration.inSeconds.clamp(1, double.infinity);
    final jankRate = _frameCount > 0 ? (_jankCount / _frameCount * 100) : 0;

    debugPrint('''
╔════════════════════════════════════════════════════╗
║           📊 帧率监控报告                          ║
╠════════════════════════════════════════════════════╣
║ 监控时长: ${duration.inSeconds} 秒
║ 总帧数: $_frameCount
║ 平均帧率: ${fps.toStringAsFixed(1)} FPS
║ 卡顿帧数: $_jankCount
║ 卡顿率: ${jankRate.toStringAsFixed(1)}%
╚════════════════════════════════════════════════════╝
''');

    _frameMonitorStart = null;
  }

  /// 帧回调处理
  static void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameCount++;

      // 计算帧耗时 (build + rasterize)
      final buildDuration = timing.buildDuration.inMicroseconds;
      final rasterDuration = timing.rasterDuration.inMicroseconds;
      final totalDuration = buildDuration + rasterDuration;

      // 超过 16.67ms 算卡顿
      if (totalDuration > 16670) {
        _jankCount++;
        if (kDebugMode) {
          debugPrint('🐌 [Jank] Frame ${_frameCount}: build=${(buildDuration/1000).toStringAsFixed(1)}ms, '
              'raster=${(rasterDuration/1000).toStringAsFixed(1)}ms, '
              'total=${(totalDuration/1000).toStringAsFixed(1)}ms');
        }
      }
    }
  }

  /// 输出追踪统计报告
  static void printReport() {
    if (_traces.isEmpty) {
      debugPrint('📊 [PerformanceMonitor] 暂无追踪数据');
      return;
    }

    debugPrint('\n╔════════════════════════════════════════════════════╗');
    debugPrint('║           📊 性能追踪报告                          ║');
    debugPrint('╠════════════════════════════════════════════════════╣');

    for (final entry in _traces.entries) {
      final name = entry.key;
      final times = entry.value;
      if (times.isEmpty) continue;

      final avg = times.reduce((a, b) => a + b) / times.length;
      final max = times.reduce((a, b) => a > b ? a : b);
      final min = times.reduce((a, b) => a < b ? a : b);

      debugPrint('║ $name');
      debugPrint('║   调用次数: ${times.length}');
      debugPrint('║   平均耗时: ${(avg/1000).toStringAsFixed(2)}ms');
      debugPrint('║   最大耗时: ${(max/1000).toStringAsFixed(2)}ms');
      debugPrint('║   最小耗时: ${(min/1000).toStringAsFixed(2)}ms');
      debugPrint('╠────────────────────────────────────────────────────╣');
    }

    debugPrint('╚════════════════════════════════════════════════════╝\n');
  }

  /// 清除追踪数据
  static void clearTraces() {
    _traces.clear();
    debugPrint('🧹 [PerformanceMonitor] 追踪数据已清除');
  }

  /// 标记重建
  /// 在 Widget 的 build 方法中调用，用于追踪不必要的重建
  static void markRebuild(String widgetName) {
    if (!_enabled) return;
    debugPrint('🔄 [Rebuild] $widgetName');
  }
}

/// 性能追踪的便捷扩展
extension StopwatchPerf on Stopwatch {
  /// 打印耗时并返回
  void printElapsed(String label) {
    debugPrint('⏱️ [$label] ${elapsedMilliseconds}ms');
  }
}
