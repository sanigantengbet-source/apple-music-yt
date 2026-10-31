import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';
import '../services/storage_service.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final favorites = StorageService.getFavorites();
    final history = StorageService.getHistory();
    final recentlyAdded = [...favorites, ...history].toSet().toList();

    final menuItems = [
      {'title': 'Daftar Putar', 'icon': CupertinoIcons.music_albums},
      {'title': 'Artis', 'icon': CupertinoIcons.person_2},
      {'title': 'Album', 'icon': CupertinoIcons.square_stack_3d_down_right},
      {'title': 'Lagu', 'icon': CupertinoIcons.music_note},
      {'title': 'Lagu Favorit', 'icon': CupertinoIcons.heart_fill},
      {'title': 'Diunduh', 'icon': CupertinoIcons.arrow_down_circle},
    ];

    return Scaffold(
      backgroundColor: AppleMusicColors.background,
      body: CustomScrollView(
        slivers: [
          // Cupertino Large Title
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Perpustakaan',
              style: TextStyle(
                color: AppleMusicColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            backgroundColor: AppleMusicColors.background.withOpacity(0.8),
            border: null,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: AppleMusicColors.accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {},
            ),
          ),

          // Menu list items (Apple Music Library List Style)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = menuItems[index];
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      leading: Icon(
                        item['icon'] as IconData,
                        color: AppleMusicColors.accent,
                        size: 24,
                      ),
                      title: Text(
                        item['title'] as String,
                        style: const TextStyle(
                          color: AppleMusicColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        color: AppleMusicColors.textSecondary,
                        size: 16,
                      ),
                      onTap: () {
                        if (item['title'] == 'Lagu Favorit' && favorites.isNotEmpty) {
                          provider.playSong(favorites.first, queue: favorites);
                        }
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 60),
                      child: Divider(color: AppleMusicColors.divider, height: 1),
                    ),
                  ],
                );
              },
              childCount: menuItems.length,
            ),
          ),

          // Recently Added Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Baru Ditambahkan',
                style: TextStyle(
                  color: AppleMusicColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),

          // 2-Column Recently Added Grid
          if (recentlyAdded.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.music_albums,
                        size: 64,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum Ada Lagu Tersimpan',
                        style: TextStyle(
                          color: AppleMusicColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cari lagu dan tekan bintang favorit untuk menambahkannya ke koleksi Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.76,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = recentlyAdded[index];
                    return GestureDetector(
                      onTap: () => provider.playSong(song, queue: recentlyAdded, index: index),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppleMusicColors.surfaceElevated,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
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
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppleMusicColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppleMusicColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: recentlyAdded.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}
