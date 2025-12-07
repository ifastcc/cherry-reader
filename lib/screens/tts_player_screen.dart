import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../models/tts_segment.dart';

class TtsPlayerScreen extends StatefulWidget {
  const TtsPlayerScreen({Key? key}) : super(key: key);

  @override
  State<TtsPlayerScreen> createState() => _TtsPlayerScreenState();
}

class _TtsPlayerScreenState extends State<TtsPlayerScreen> {
  final ScrollController _scrollController = ScrollController();
  int _lastHighlightedIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _scrollToCurrentSegment(int index, int totalSegments) {
    if (_scrollController.hasClients && index != _lastHighlightedIndex) {
      _lastHighlightedIndex = index;
      // 计算滚动位置，让当前段落在中间偏上
      final itemHeight = 80.0; // 估算每个段落的高度
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetOffset = (index * itemHeight) - (viewportHeight / 3);

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TtsProvider>(
      builder: (context, tts, child) {
        final item = tts.currentItem;
        final session = tts.currentSession;

        if (item == null) {
          return const Scaffold(
            body: Center(child: Text('没有正在播放的内容')),
          );
        }

        // 自动滚动到当前段落
        if (session != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCurrentSegment(session.currentIndex, session.segments.length);
          });
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (session != null)
                  Text(
                    '${session.currentIndex + 1}/${session.segments.length} 段',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            centerTitle: true,
            actions: [
              // 下载进度指示器
              if (session != null && !session.isFullyDownloaded)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: session.downloadProgress,
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onPressed: () => _showOptionsMenu(context, tts),
              ),
            ],
          ),
          body: Column(
            children: [
              // 歌词式段落显示区域
              Expanded(
                child: session != null
                    ? _buildSegmentList(context, tts, session)
                    : const Center(child: CircularProgressIndicator()),
              ),

              // 播放控制区域
              _buildControlArea(context, tts, session),
            ],
          ),
        );
      },
    );
  }

  /// 构建段落列表（歌词式）
  Widget _buildSegmentList(BuildContext context, TtsProvider tts, session) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: session.segments.length,
      itemBuilder: (context, index) {
        final segment = session.segments[index];
        final isCurrent = index == session.currentIndex;
        final isPast = index < session.currentIndex;
        final status = segment.status;

        return GestureDetector(
          onTap: () => tts.jumpToSegment(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.blue.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent ? Colors.blue : Colors.transparent,
                width: 2,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 段落序号和状态
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status, isCurrent, isPast),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _buildStatusIcon(status, index, isCurrent),
                  ),
                ),
                const SizedBox(width: 12),
                // 段落文本
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        segment.text,
                        style: TextStyle(
                          fontSize: isCurrent ? 16 : 14,
                          fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
                          color: isPast
                              ? Colors.grey[400]
                              : isCurrent
                                  ? Colors.blue[800]
                                  : Colors.grey[700],
                          height: 1.5,
                        ),
                        maxLines: isCurrent ? null : 3,
                        overflow: isCurrent ? null : TextOverflow.ellipsis,
                      ),
                      if (segment.duration != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatDuration(segment.duration!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(SegmentStatus status, bool isCurrent, bool isPast) {
    if (isCurrent) return Colors.blue;
    if (isPast) return Colors.grey[300]!;

    switch (status) {
      case SegmentStatus.ready:
        return Colors.green[100]!;
      case SegmentStatus.downloading:
        return Colors.orange[100]!;
      case SegmentStatus.error:
        return Colors.red[100]!;
      case SegmentStatus.pending:
        return Colors.grey[200]!;
    }
  }

  Widget _buildStatusIcon(SegmentStatus status, int index, bool isCurrent) {
    if (isCurrent) {
      return const Icon(Icons.play_arrow, color: Colors.white, size: 18);
    }

    switch (status) {
      case SegmentStatus.ready:
        return Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        );
      case SegmentStatus.downloading:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange[700],
          ),
        );
      case SegmentStatus.error:
        return Icon(Icons.error_outline, color: Colors.red[700], size: 16);
      case SegmentStatus.pending:
        return Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        );
    }
  }

  /// 构建控制区域
  Widget _buildControlArea(BuildContext context, TtsProvider tts, session) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 当前段落进度条
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: Colors.blue,
                  ),
                  child: Slider(
                    value: tts.currentPosition.inSeconds.toDouble(),
                    max: tts.totalDuration.inSeconds.toDouble() > 0
                        ? tts.totalDuration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (value) {
                      tts.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(tts.currentPosition),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        _formatDuration(tts.totalDuration),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 播放速度
                IconButton(
                  icon: Text(
                    '${tts.playbackSpeed}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  onPressed: () => _showSpeedDialog(context, tts),
                ),

                // 上一段
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 36,
                  color: session?.hasPrevious == true ? Colors.grey[800] : Colors.grey[300],
                  onPressed: session?.hasPrevious == true ? () => tts.previousSegment() : null,
                ),

                // 播放/暂停
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      tts.playerState == TtsState.loading
                          ? Icons.hourglass_empty
                          : (tts.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                    iconSize: 32,
                    color: Colors.white,
                    onPressed: () {
                      if (tts.isPlaying) {
                        tts.pause();
                      } else {
                        tts.play();
                      }
                    },
                  ),
                ),

                // 下一段
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 36,
                  color: session?.hasNext == true ? Colors.grey[800] : Colors.grey[300],
                  onPressed: session?.hasNext == true ? () => tts.nextSegment() : null,
                ),

                // 段落列表
                IconButton(
                  icon: const Icon(Icons.list_rounded),
                  color: Colors.grey[600],
                  onPressed: () => _showSegmentList(context, tts),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, TtsProvider tts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '播放速度',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                  final isSelected = tts.playbackSpeed == speed;
                  return InkWell(
                    onTap: () {
                      tts.setPlaybackSpeed(speed);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSegmentList(BuildContext context, TtsProvider tts) {
    final session = tts.currentSession;
    if (session == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // 拖动指示器
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '全部段落',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${session.readyCount}/${session.segments.length} 已下载',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: session.segments.length,
                    itemBuilder: (context, index) {
                      final segment = session.segments[index];
                      final isCurrent = index == session.currentIndex;

                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.blue : _getStatusColor(
                              segment.status,
                              isCurrent,
                              index < session.currentIndex,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _buildStatusIcon(segment.status, index, isCurrent),
                          ),
                        ),
                        title: Text(
                          segment.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.blue : Colors.black,
                          ),
                        ),
                        subtitle: segment.duration != null
                            ? Text(_formatDuration(segment.duration!))
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          tts.jumpToSegment(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOptionsMenu(BuildContext context, TtsProvider tts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('重新下载'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 实现重新下载
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('清除缓存'),
                onTap: () {
                  Navigator.pop(context);
                  tts.clearPlaylist();
                  Navigator.pop(context); // 关闭播放页
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
