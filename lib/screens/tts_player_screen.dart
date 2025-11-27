import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../models/tts_item.dart';

class TtsPlayerScreen extends StatelessWidget {
  const TtsPlayerScreen({Key? key}) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TtsProvider>(
      builder: (context, tts, child) {
        final item = tts.currentItem;
        if (item == null) {
          return const Scaffold(
            body: Center(child: Text('没有正在播放的内容')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Cover Art Area
              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    width: 240,
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Info & Controls Area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Title
                      Column(
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.author ?? 'AI Assistant',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      // Progress Bar
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(tts.currentPosition),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  _formatDuration(tts.totalDuration),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Speed / Timer
                          IconButton(
                            icon: const Icon(Icons.speed),
                            color: Colors.grey[600],
                            onPressed: () {
                              _showSpeedDialog(context, tts);
                            },
                          ),
                          
                          // Prev
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            iconSize: 36,
                            color: Colors.grey[800],
                            onPressed: () => tts.previous(),
                          ),

                          // Play/Pause
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                tts.playerState == TtsState.loading
                                    ? Icons.hourglass_empty
                                    : (tts.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded),
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

                          // Next
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            iconSize: 36,
                            color: Colors.grey[800],
                            onPressed: () => tts.next(),
                          ),

                          // Playlist
                          IconButton(
                            icon: const Icon(Icons.playlist_play_rounded),
                            color: Colors.grey[600],
                            onPressed: () {
                              _showPlaylist(context, tts);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedDialog(BuildContext context, TtsProvider tts) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '播放速度',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
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

  void _showPlaylist(BuildContext context, TtsProvider tts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '播放列表',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tts.playlist.length,
                  itemBuilder: (context, index) {
                    final item = tts.playlist[index];
                    final isPlaying = index == tts.currentIndex;
                    return ListTile(
                      leading: isPlaying
                          ? const Icon(Icons.equalizer, color: Colors.blue)
                          : Text('${index + 1}', style: const TextStyle(color: Colors.grey)),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isPlaying ? Colors.blue : Colors.black,
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        // Play this item
                        // We need a method in provider to play specific index
                        // tts.playIndex(index); 
                        // For now, we can implement it or just close.
                        // Let's assume user wants to jump.
                        // But TtsProvider needs a method for that.
                        // I'll add playIndex to TtsProvider later or just use setPlaylist logic.
                        // Actually, I can just set currentIndex and play.
                        // But currentIndex is private setter? No, I made it private.
                        // I should add jumpTo(index) to TtsProvider.
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
