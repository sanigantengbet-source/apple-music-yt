import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';
import '../widgets/apple_shelf.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final shelves = provider.homeShelves;

    return Scaffold(
      backgroundColor: AppleMusicColors.background,
      body: CustomScrollView(
        slivers: [
          // Cupertino Large Title
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Telusuri',
              style: TextStyle(
                color: AppleMusicColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            backgroundColor: AppleMusicColors.background.withOpacity(0.8),
            border: null,
          ),

          // Horizontal Hero Banners
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: PageView(
                controller: PageController(viewportFraction: 0.9),
                children: [
                  _buildBrowseHeroCard(
                    category: 'EKSKLUSIF',
                    title: 'New Music Daily',
                    subtitle: 'Lagu baru terbaik hari ini dari musisi dunia & Indonesia.',
                    gradient: const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    icon: CupertinoIcons.sparkles,
                  ),
                  _buildBrowseHeroCard(
                    category: 'TANGGA LAGU',
                    title: "Today's Hits",
                    subtitle: 'Kompilasi lagu hits teratas paling viral di YouTube Music.',
                    gradient: const [Color(0xFFE52D27), Color(0xFFB31217)],
                    icon: CupertinoIcons.flame_fill,
                  ),
                  _buildBrowseHeroCard(
                    category: 'AUDIO SPASIAL',
                    title: 'Dolby Atmos Showcase',
                    subtitle: 'Dengarkan dimensi suara baru dengan kedalaman memukau.',
                    gradient: const [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
                    icon: CupertinoIcons.waveform_path,
                  ),
                ],
              ),
            ),
          ),

          // Shelves
          ...shelves.entries.map((entry) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: AppleShelf(
                  subtitle: 'Sorotan Editor',
                  title: entry.key,
                  songs: entry.value,
                  onSongTap: (song) => provider.playSong(song, queue: entry.value),
                ),
              ),
            );
          }),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseHeroCard({
    required String category,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 16,
            child: Icon(
              icon,
              size: 110,
              color: Colors.white.withOpacity(0.12),
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
                      category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    height: 1.3,
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
