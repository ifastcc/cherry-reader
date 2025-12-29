import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/isar/note_entity.dart';
import '../services/note_service.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

/// 笔记列表页面
///
/// 功能：
/// - 按时间倒序显示所有笔记
/// - 按日期分组
/// - 搜索和标签筛选
/// - 新建笔记入口
/// - 每日回顾入口
class NotesScreen extends StatefulWidget {
  /// 跳转到对话的回调
  final void Function(String topicId, String? messageId)? onNavigateToConversation;

  const NotesScreen({
    super.key,
    this.onNavigateToConversation,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  final TextEditingController _searchController = TextEditingController();

  List<NoteEntity> _notes = [];
  List<NoteEntity> _filteredNotes = [];
  Map<String, int> _tagStats = {};
  String? _selectedTag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final notes = await _noteService.getAllNotes();
      final tagStats = await _noteService.getTagStatistics();

      setState(() {
        _notes = notes;
        _filteredNotes = notes;
        _tagStats = tagStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        // 标签筛选
        if (_selectedTag != null && !note.tags.contains(_selectedTag)) {
          return false;
        }
        // 搜索筛选
        if (query.isNotEmpty && !note.plainText.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  void _onTagSelected(String? tag) {
    setState(() {
      _selectedTag = _selectedTag == tag ? null : tag;
    });
    _filterNotes();
  }

  Future<void> _createNote() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteEditorScreen(),
      ),
    );

    if (result == true || result == null) {
      _loadNotes(); // 刷新列表
    }
  }

  Future<void> _editNote(NoteEntity note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(existingNote: note),
      ),
    );

    if (result == true || result == null) {
      _loadNotes(); // 刷新列表
    }
  }

  Future<void> _deleteNote(NoteEntity note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: const Text('确定要删除这条笔记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _noteService.deleteNote(note.noteId);
      _loadNotes();
    }
  }

  void _navigateToSource(NoteEntity note) {
    if (note.topicId != null && widget.onNavigateToConversation != null) {
      widget.onNavigateToConversation!(note.topicId!, note.messageId);
    }
  }

  void _showDailyReview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyReviewSheet(
        notes: _notes,
        onNoteTap: _editNote,
        onSourceTap: _navigateToSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('笔记'),
        actions: [
          if (_notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _showDailyReview,
              tooltip: '每日回顾',
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索笔记...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterNotes();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (_) => _filterNotes(),
            ),
          ),

          // 标签筛选
          if (_tagStats.isNotEmpty) _buildTagFilter(),

          // 笔记列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTagFilter() {
    final sortedTags = _tagStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: sortedTags.length,
        itemBuilder: (context, index) {
          final entry = sortedTags[index];
          final isSelected = _selectedTag == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('#${entry.key} (${entry.value})'),
              selected: isSelected,
              onSelected: (_) => _onTagSelected(entry.key),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty || _selectedTag != null
                ? '没有找到匹配的笔记'
                : '还没有笔记',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isEmpty && _selectedTag == null)
            Text(
              '点击右下角按钮创建第一条笔记',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    // 按日期分组
    final grouped = _groupNotesByDate(_filteredNotes);

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final group = grouped[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateGroupHeader(dateText: group.dateText),
              ...group.notes.map((note) => NoteCard(
                    note: note,
                    onTap: () => _editNote(note),
                    onSourceTap: note.hasSource ? () => _navigateToSource(note) : null,
                    onDelete: () => _deleteNote(note),
                  )),
            ],
          );
        },
      ),
    );
  }

  List<_DateGroup> _groupNotesByDate(List<NoteEntity> notes) {
    final groups = <String, List<NoteEntity>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final note in notes) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(note.createdAt);
      final noteDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      String key;
      if (noteDate == today) {
        key = '今天';
      } else if (noteDate == yesterday) {
        key = '昨天';
      } else if (now.year == dateTime.year) {
        key = DateFormat('MM月dd日').format(dateTime);
      } else {
        key = DateFormat('yyyy年MM月dd日').format(dateTime);
      }

      groups.putIfAbsent(key, () => []).add(note);
    }

    return groups.entries
        .map((e) => _DateGroup(dateText: e.key, notes: e.value))
        .toList();
  }
}

class _DateGroup {
  final String dateText;
  final List<NoteEntity> notes;

  _DateGroup({required this.dateText, required this.notes});
}

/// 每日回顾底部弹窗
class DailyReviewSheet extends StatefulWidget {
  final List<NoteEntity> notes;
  final void Function(NoteEntity note)? onNoteTap;
  final void Function(NoteEntity note)? onSourceTap;

  const DailyReviewSheet({
    super.key,
    required this.notes,
    this.onNoteTap,
    this.onSourceTap,
  });

  @override
  State<DailyReviewSheet> createState() => _DailyReviewSheetState();
}

class _DailyReviewSheetState extends State<DailyReviewSheet> {
  late PageController _pageController;
  late List<NoteEntity> _reviewNotes;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 随机打乱并取最多 10 条
    _reviewNotes = List.from(widget.notes)..shuffle();
    if (_reviewNotes.length > 10) {
      _reviewNotes = _reviewNotes.take(10).toList();
    }
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_reviewNotes.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: Text('还没有笔记可以回顾'),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                const Text(
                  '每日回顾',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 卡片区域
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _reviewNotes.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final note = _reviewNotes[index];
                return _buildReviewCard(context, note);
              },
            ),
          ),

          // 底部指示器
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentIndex > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
                Text(
                  '${_currentIndex + 1}/${_reviewNotes.length} 条笔记',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentIndex < _reviewNotes.length - 1
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, NoteEntity note) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onNoteTap?.call(note);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间戳
              Text(
                _formatDateTime(note.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              // 内容
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    note.plainText,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              // 标签
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: note.tags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],

              // 来源
              if (note.hasSource) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSourceTap?.call(note);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '查看原对话',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}
