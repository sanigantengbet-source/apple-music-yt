import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';

class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final queue = provider.queue;
    final currentIndex = provider.currentIndex;

    return Column(
      children: [
        // Top Toolbar inside Queue
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Berikutnya (Playing Next)',
                style: TextStyle(
                  color: AppleMusicColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  // Shuffle button
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.shuffle,
                      color: provider.isShuffle
                          ? AppleMusicColors.accent
                          : AppleMusicColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => provider.toggleShuffle(),
                  ),
                  // Repeat button
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.repeat,
                      color: provider.loopMode != LoopMode.off
                          ? AppleMusicColors.accent
                          : AppleMusicColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => provider.toggleRepeat(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(color: AppleMusicColors.divider, height: 1),

        // Reorderable Queue List
        Expanded(
          child: queue.isEmpty
              ? const Center(
                  child: Text(
                    'Antrean kosong',
                    style: TextStyle(
                      color: AppleMusicColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    provider.reorderQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isCurrent = index == currentIndex;

                    return Container(
                      key: ValueKey('queue_${song.id}_$index'),
                      color: isCurrent
                          ? Colors.white.withOpacity(0.08)
                          : Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: AppleMusicColors.surfaceElevated,
                                child: song.thumbnailUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: song.highResThumbnail,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        CupertinoIcons.music_note,
                                        color: AppleMusicColors.textSecondary,
                                      ),
                              ),
                            ),
                            if (isCurrent && provider.isPlaying)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  CupertinoIcons.waveform,
                                  color: AppleMusicColors.accent,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent
                                ? AppleMusicColors.accent
                                : AppleMusicColors.textPrimary,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppleMusicColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCurrent)
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  CupertinoIcons.speaker_2_fill,
                                  color: AppleMusicColors.accent,
                                  size: 18,
                                ),
                              ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(
                                CupertinoIcons.bars,
                                color: AppleMusicColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          provider.playSong(song, queue: queue, index: index);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
