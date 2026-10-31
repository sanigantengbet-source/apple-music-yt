import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';
import 'full_screen_player.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final progress = (provider.duration.inMilliseconds > 0)
        ? (provider.position.inMilliseconds / provider.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, _, __) => const FullScreenPlayer(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        height: 64,
        decoration: BoxDecoration(
          color: AppleMusicColors.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      // Artwork
                      Hero(
                        tag: 'artwork_${song.id}',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppleMusicColors.surfaceElevated,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: song.thumbnailUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: song.highResThumbnail,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, _, __) => const Icon(
                                      CupertinoIcons.music_note,
                                      color: AppleMusicColors.textSecondary,
                                    ),
                                  )
                                : const Icon(
                                    CupertinoIcons.music_note,
                                    color: AppleMusicColors.textSecondary,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Artist
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppleMusicColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppleMusicColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      IconButton(
                        iconSize: 30,
                        splashRadius: 24,
                        icon: Icon(
                          provider.isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                          color: AppleMusicColors.textPrimary,
                        ),
                        onPressed: () => provider.togglePlayPause(),
                      ),
                      IconButton(
                        iconSize: 26,
                        splashRadius: 24,
                        icon: const Icon(
                          CupertinoIcons.forward_fill,
                          color: AppleMusicColors.textPrimary,
                        ),
                        onPressed: () => provider.skipToNext(),
                      ),
                    ],
                  ),
                ),

                // Tiny sleek bottom progress line
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppleMusicColors.textPrimary.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: AppleMusicColors.accent.withOpacity(0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
