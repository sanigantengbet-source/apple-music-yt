import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  final List<Map<String, dynamic>> _stations = const [
    {
      'title': 'Apple Music 1',
      'subtitle': 'The new music that matters',
      'host': 'Zane Lowe & Tim Sweeney',
      'gradient': [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
      'query': 'Apple Music 1 Live Today Hits',
    },
    {
      'title': 'Apple Music Hits',
      'subtitle': 'Lagu-lagu favorit terbaik sepanjang masa',
      'host': 'Estelle & Jayde Donovan',
      'gradient': [Color(0xFF2C3E50), Color(0xFFFD746C)],
      'query': 'Apple Music Hits 80s 90s 2000s Pop',
    },
    {
      'title': 'Apple Music Chill',
      'subtitle': 'Irama santai untuk relaksasi dan fokus',
      'host': 'Sounwave & Friends',
      'gradient': [Color(0xFF00B4DB), Color(0xFF0083B0)],
      'query': 'Lo-Fi Chill Beats Relaxing Music',
    },
    {
      'title': 'Indonesian Hits Radio',
      'subtitle': 'Musik pop dan indie lokal Indonesia terkini',
      'host': 'Sonora Regional',
      'gradient': [Color(0xFF11998E), Color(0xFF38EF7D)],
      'query': 'Lagu Populer Indonesia Pop Hits',
    },
    {
      'title': 'Acoustic Morning',
      'subtitle': 'Ketenangan petikan gitar mengawali hari',
      'host': 'Editorial Radio',
      'gradient': [Color(0xFFFF8008), Color(0xFFFFC837)],
      'query': 'Acoustic Guitar Morning Coffee',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return Scaffold(
      backgroundColor: AppleMusicColors.background,
      body: CustomScrollView(
        slivers: [
          // Large Cupertino Title
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Radio',
              style: TextStyle(
                color: AppleMusicColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            backgroundColor: AppleMusicColors.background.withOpacity(0.8),
            border: null,
          ),

          // Live Broadcast Hero Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF654EA3), Color(0xFFEAAFC8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.circle_fill, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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
                              'SIARAN LANGSUNG',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Apple Music 1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'The Zane Lowe Show • Episode Terbaru',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final songs = await provider.search('Zane Lowe Show Apple Music 1');
                            if (provider.searchResults.isNotEmpty) {
                              provider.playSong(provider.searchResults.first, queue: provider.searchResults);
                            }
                          },
                          icon: const Icon(CupertinoIcons.play_fill, size: 16),
                          label: const Text('Dengarkan Siaran'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stations List Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Stasiun Menurut Genre & Suasana Hati',
                style: TextStyle(
                  color: AppleMusicColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          // Stations Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final station = _stations[index];
                  final gradient = station['gradient'] as List<Color>;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      title: Text(
                        station['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        station['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onTap: () async {
                        final q = station['query'] as String;
                        await provider.search(q);
                        if (provider.searchResults.isNotEmpty) {
                          provider.playSong(provider.searchResults.first, queue: provider.searchResults);
                        }
                      },
                    ),
                  );
                },
                childCount: _stations.length,
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
