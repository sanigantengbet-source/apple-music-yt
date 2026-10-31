import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/apple_music_colors.dart';
import '../models/song.dart';

class AppleShelf extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Song> songs;
  final Function(Song song) onSongTap;

  const AppleShelf({
    super.key,
    required this.title,
    this.subtitle,
    required this.songs,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null)
                Text(
                  subtitle!.toUpperCase(),
                  style: const TextStyle(
                    color: AppleMusicColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppleMusicColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: AppleMusicColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal Card Carousel
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Container(
                width: 156,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => onSongTap(song),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artwork Card
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppleMusicColors.surfaceElevated,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
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
                      const SizedBox(height: 8),

                      // Song Title
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppleMusicColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Artist
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppleMusicColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
