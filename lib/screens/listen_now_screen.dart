import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';
import '../services/storage_service.dart';
import '../widgets/apple_shelf.dart';

class ListenNowScreen extends StatelessWidget {
  const ListenNowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final shelves = provider.homeShelves;
    final history = StorageService.getHistory();

    return Scaffold(
      backgroundColor: AppleMusicColors.background,
      body: CustomScrollView(
        slivers: [
          // Cupertino Large Title App Bar
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Dengarkan Sekarang',
              style: TextStyle(
                color: AppleMusicColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            backgroundColor: AppleMusicColors.background.withOpacity(0.8),
            border: null,
            trailing: GestureDetector(
              onTap: () {},
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFA243C), Color(0xFFFF5E7E)],
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Pull to refresh
          CupertinoSliverRefreshControl(
            onRefresh: () => provider.loadHomeFeed(),
          ),

          // Loading state
          if (provider.isLoadingHome && shelves.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                  color: AppleMusicColors.accent,
                ),
              ),
            )
          else ...[
            // Top Picks Featured Hero Card
            SliverToBoxAdapter(
              child: _buildFeaturedHero(context, provider),
            ),

            // Recently Played Shelf
            if (history.isNotEmpty)
              SliverToBoxAdapter(
                child: AppleShelf(
                  subtitle: 'Baru Saja Diputar',
                  title: 'Putar Ulang',
                  songs: history,
                  onSongTap: (song) => provider.playSong(song, queue: history),
                ),
              ),

            // Dynamic Shelves from YouTube Music
            ...shelves.entries.map((entry) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppleShelf(
                    subtitle: 'Disesuaikan Untuk Anda',
                    title: entry.key,
                    songs: entry.value,
                    onSongTap: (song) => provider.playSong(song, queue: entry.value),
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120), // Padding for docked MiniPlayer
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturedHero(BuildContext context, MusicProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF8A002A), Color(0xFF1E0510)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              CupertinoIcons.music_albums,
              size: 200,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PILIHAN UTAMA HARI INI',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Audio Spasial Dolby Atmos & Kualitas Lossless',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Play curated top picks
                    final firstShelf = provider.homeShelves.values.isNotEmpty
                        ? provider.homeShelves.values.first
                        : null;
                    if (firstShelf != null && firstShelf.isNotEmpty) {
                      provider.playSong(firstShelf.first, queue: firstShelf);
                    }
                  },
                  icon: const Icon(CupertinoIcons.play_fill, size: 16),
                  label: const Text(
                    'Putar Sekarang',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
