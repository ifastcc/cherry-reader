import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/computed_timeline.dart';

/// 时间线计算服务
///
/// 提供在 Isolate 中执行 CPU 密集型计算的能力，
/// 包括话题排序、分组、预览提取等。
class TimelineComputeService {
  /// 在 Isolate 中计算完整时间线
  static Future<ComputedTimeline> computeTimeline(
    TimelineComputeParams params,
  ) async {
    return compute(_computeTimelineInIsolate, params);
  }
}

/// 在 Isolate 中执行的计算函数（顶级函数）
ComputedTimeline _computeTimelineInIsolate(TimelineComputeParams params) {
  final rawData = params.rawData;
  final assistantMap = params.assistantMap;
  final now = params.now;

  // 1. 构建 block 索引
  final blockMap = _buildBlockMap(rawData);

  // 2. 提取所有话题并计算预览
  final allTopics = <TopicItem>[];
  final topicsMap = <String, TopicItem>{};

  final indexedDB = rawData['indexedDB'] as Map<String, dynamic>? ?? {};
  final localStorage = rawData['localStorage'] as Map<String, dynamic>? ?? {};

  // 从 localStorage 获取 assistant -> topics 映射
  final assistantTopicsMap = _extractAssistantTopics(localStorage);

  // 获取所有 topic 的完整数据
  final topicsData = indexedDB['topics'] as List<dynamic>? ?? [];
  final topicFullMap = <String, Map<String, dynamic>>{};
  for (final topic in topicsData) {
    if (topic is Map<String, dynamic>) {
      final id = topic['id'] as String?;
      if (id != null) {
        topicFullMap[id] = topic;
      }
    }
  }

  // 遍历 assistant -> topics 映射
  for (final entry in assistantTopicsMap.entries) {
    final assistantId = entry.key;
    final assistantInfo = assistantMap[assistantId];
    final assistantName =
        assistantInfo?['name'] as String? ?? '未命名助手';

    for (final topicMeta in entry.value) {
      final topicId = topicMeta['id'] as String?;
      if (topicId == null) continue;

      final fullTopic = topicFullMap[topicId];
      if (fullTopic == null) continue;

      // 计算 roundCount 和提取预览
      final messages = fullTopic['messages'] as List<dynamic>? ?? [];
      int roundCount = 0;
      String? userPreview;
      String? aiPreview;

      for (final msg in messages) {
        if (msg is Map<String, dynamic>) {
          final role = msg['role'] as String?;
          if (role == 'user') {
            roundCount++;
            // 提取最后一个用户问题
            final preview = _extractMessagePreview(msg, blockMap);
            if (preview != null) {
              userPreview = preview;
            }
          } else if (role == 'assistant' && aiPreview == null) {
            // 提取第一个 AI 回答
            aiPreview = _extractMessagePreview(msg, blockMap);
          }
        }
      }

      // 解析时间
      final updatedAt = _parseDateTime(topicMeta['updatedAt']) ?? now;
      final timeDisplay = _formatTimeDisplay(updatedAt, now);

      final item = TopicItem(
        topicId: topicId,
        name: topicMeta['name'] as String? ?? '未命名话题',
        assistantId: assistantId,
        assistantName: assistantName,
        roundCount: roundCount,
        messageCount: messages.length,
        updatedAt: updatedAt,
        timeDisplay: timeDisplay,
        userPreview: userPreview,
        aiPreview: aiPreview,
      );

      allTopics.add(item);
      topicsMap[topicId] = item;
    }
  }

  // 3. 按更新时间排序
  allTopics.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  // 4. 分组
  final groups = _groupByTime(allTopics, now);

  return ComputedTimeline(
    version: params.version,
    groups: groups,
    topicsMap: topicsMap,
    computedAt: now,
  );
}

/// 构建 block_id -> block 的映射
Map<String, Map<String, dynamic>> _buildBlockMap(Map<String, dynamic> rawData) {
  final blockMap = <String, Map<String, dynamic>>{};
  final indexedDB = rawData['indexedDB'] as Map<String, dynamic>? ?? {};
  final messageBlocks = indexedDB['message_blocks'] as List<dynamic>? ?? [];

  for (final block in messageBlocks) {
    if (block is Map<String, dynamic>) {
      final id = block['id'] as String?;
      if (id != null) {
        blockMap[id] = block;
      }
    }
  }

  return blockMap;
}

/// 从 localStorage 提取 assistant -> topics 映射
Map<String, List<Map<String, dynamic>>> _extractAssistantTopics(
  Map<String, dynamic> localStorage,
) {
  final result = <String, List<Map<String, dynamic>>>{};

  try {
    final persistDataStr = localStorage['persist:cherry-studio'];
    if (persistDataStr == null) return result;

    Map<String, dynamic> persistData;
    if (persistDataStr is String) {
      persistData = json.decode(persistDataStr) as Map<String, dynamic>? ?? {};
    } else {
      persistData = persistDataStr as Map<String, dynamic>? ?? {};
    }

    final assistantsStr = persistData['assistants'];
    Map<String, dynamic> assistantsData;
    if (assistantsStr is String) {
      assistantsData = json.decode(assistantsStr) as Map<String, dynamic>? ?? {};
    } else {
      assistantsData = assistantsStr as Map<String, dynamic>? ?? {};
    }

    final assistants = assistantsData['assistants'] as List<dynamic>? ?? [];
    for (final asst in assistants) {
      if (asst is Map<String, dynamic>) {
        final id = asst['id'] as String?;
        if (id != null) {
          final topics = asst['topics'] as List<dynamic>? ?? [];
          result[id] = topics
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
    }
  } catch (_) {}

  return result;
}

/// 提取消息预览
String? _extractMessagePreview(
  Map<String, dynamic> msg,
  Map<String, Map<String, dynamic>> blockMap,
) {
  final blockIds = msg['blocks'] as List<dynamic>? ?? [];

  for (final blockId in blockIds) {
    final block = blockMap[blockId.toString()];
    if (block == null) continue;

    if (block['type'] == 'main_text') {
      final content = block['content'] as String?;
      if (content != null && content.isNotEmpty) {
        // 清理和截断
        final cleaned = content
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
            .replaceAll(RegExp(r'\*\*'), '')
            .trim();
        return cleaned.length > 80 ? '${cleaned.substring(0, 80)}...' : cleaned;
      }
    }
  }

  return null;
}

/// 解析时间
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  try {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    }
  } catch (_) {}
  return null;
}

/// 格式化时间显示
String _formatTimeDisplay(DateTime dt, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final date = DateTime(dt.year, dt.month, dt.day);
  final timeStr = DateFormat('HH:mm').format(dt);

  if (date == today) {
    return timeStr;
  } else if (date == yesterday) {
    return timeStr;
  } else if (date.isAfter(today.subtract(Duration(days: today.weekday)))) {
    const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${weekdays[dt.weekday]} $timeStr';
  } else if (dt.year == now.year) {
    return '${DateFormat('MM-dd').format(dt)} $timeStr';
  } else {
    return '${DateFormat('yyyy-MM-dd').format(dt)} $timeStr';
  }
}

/// 按时间分组
List<TimelineGroup> _groupByTime(List<TopicItem> topics, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekStart = today.subtract(Duration(days: today.weekday - 1));

  final grouped = <TimeGroup, List<TopicItem>>{
    TimeGroup.today: [],
    TimeGroup.yesterday: [],
    TimeGroup.thisWeek: [],
    TimeGroup.earlier: [],
  };

  for (final topic in topics) {
    final date = DateTime(
      topic.updatedAt.year,
      topic.updatedAt.month,
      topic.updatedAt.day,
    );

    if (date == today) {
      grouped[TimeGroup.today]!.add(topic);
    } else if (date == yesterday) {
      grouped[TimeGroup.yesterday]!.add(topic);
    } else if (date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
      grouped[TimeGroup.thisWeek]!.add(topic);
    } else {
      grouped[TimeGroup.earlier]!.add(topic);
    }
  }

  return [
    TimelineGroup(type: TimeGroup.today, topics: grouped[TimeGroup.today]!),
    TimelineGroup(type: TimeGroup.yesterday, topics: grouped[TimeGroup.yesterday]!),
    TimelineGroup(type: TimeGroup.thisWeek, topics: grouped[TimeGroup.thisWeek]!),
    TimelineGroup(type: TimeGroup.earlier, topics: grouped[TimeGroup.earlier]!),
  ].where((g) => g.topics.isNotEmpty).toList();
}
