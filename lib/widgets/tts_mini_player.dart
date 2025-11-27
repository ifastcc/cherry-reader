import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../screens/tts_player_screen.dart';

class TtsMiniPlayer extends StatelessWidget {
  const TtsMiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TtsProvider>(
      builder: (context, tts, child) {
        if (tts.playerState == TtsState.stopped && tts.playlist.isEmpty) {
          return const SizedBox.shrink();
        }

        final item = tts.currentItem;
        if (item == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const TtsPlayerScreen(),
              ),
            );
          },
          child: Container(
            height: 64,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Cover / Icon
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.blue),
                ),

                // Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.author ?? 'AI Assistant',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Controls
                IconButton(
                  icon: Icon(
                    tts.playerState == TtsState.loading
                        ? Icons.hourglass_empty
                        : (tts.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  onPressed: () {
                    if (tts.isPlaying) {
                      tts.pause();
                    } else {
                      tts.play();
                    }
                  },
                ),
                
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: Colors.grey,
                  onPressed: () {
                    tts.stop();
                    tts.clearPlaylist();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
