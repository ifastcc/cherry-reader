import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/highlight_data.dart';

class HighlightListSheet extends StatelessWidget {
  final List<HighlightData> highlights;
  final Function(HighlightData) onDelete;
  final Function(HighlightData) onTap;

  const HighlightListSheet({
    Key? key,
    required this.highlights,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group highlights by date
    final grouped = _groupHighlights(highlights);
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort by date descending

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '高亮列表',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${highlights.length} 条标注',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (highlights.isEmpty)
            const Expanded(
              child: Center(
                child: Text('暂无高亮标注', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final date = sortedKeys[index];
                  final dayHighlights = grouped[date]!;

                  // Sort highlights within the day by time descending
                  dayHighlights.sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _formatDate(date),
                          style: const TextStyle(
                            color: Color(0xFF5B9BD5),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ...dayHighlights.map(
                        (h) => _buildHighlightItem(context, h),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(BuildContext context, HighlightData highlight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252530),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3a3a4a)),
      ),
      child: ListTile(
        onTap: () => onTap(highlight),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(highlight.color),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          highlight.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE8E8E8),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        subtitle: Text(
          DateFormat('HH:mm').format(highlight.createdAt),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => onDelete(highlight),
        ),
      ),
    );
  }

  Map<DateTime, List<HighlightData>> _groupHighlights(
    List<HighlightData> list,
  ) {
    final map = <DateTime, List<HighlightData>>{};
    for (final h in list) {
      final date = DateTime(
        h.createdAt.year,
        h.createdAt.month,
        h.createdAt.day,
      );
      if (!map.containsKey(date)) {
        map[date] = [];
      }
      map[date]!.add(h);
    }
    return map;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return '今天';
    if (date == yesterday) return '昨天';
    return DateFormat('yyyy年MM月dd日').format(date);
  }
}
