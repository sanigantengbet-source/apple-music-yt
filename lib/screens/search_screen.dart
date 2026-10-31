import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';
import '../services/storage_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _categories = const [
    {
      'title': 'Pop',
      'colors': [Color(0xFFFF2D55), Color(0xFFFF5E7E)],
      'query': 'Top Pop Hits Music',
    },
    {
      'title': 'Hip-Hop',
      'colors': [Color(0xFF5856D6), Color(0xFF8B8AE8)],
      'query': 'Hip Hop Rap Hits',
    },
    {
      'title': 'R&B / Soul',
      'colors': [Color(0xFFFF9500), Color(0xFFFFB340)],
      'query': 'RnB Soul Music',
    },
    {
      'title': 'Rock',
      'colors': [Color(0xFF007AFF), Color(0xFF47A0FF)],
      'query': 'Rock Classics and Modern',
    },
    {
      'title': 'Tari & Elektronik',
      'colors': [Color(0xFF34C759), Color(0xFF63D982)],
      'query': 'EDM Dance Electronic',
    },
    {
      'title': 'Santai (Chill)',
      'colors': [Color(0xFF30B0C7), Color(0xFF5FD3E8)],
      'query': 'Chill Lo-Fi Acoustic',
    },
    {
      'title': 'Indie Indonesia',
      'colors': [Color(0xFFAF52DE), Color(0xFFC77DEB)],
      'query': 'Indie Populer Indonesia Hindia Pamungkas Nadin',
    },
    {
      'title': 'Olahraga (Workout)',
      'colors': [Color(0xFFFF3B30), Color(0xFFFF6961)],
      'query': 'Workout Gym High Energy Music',
    },
    {
      'title': 'Fokus & Belajar',
      'colors': [Color(0xFF5E5CE6), Color(0xFF8685ED)],
      'query': 'Deep Focus Study Instrumental',
    },
    {
      'title': 'Tangga Lagu Teratas',
      'colors': [Color(0xFFFFD60A), Color(0xFFFFE14D)],
      'query': 'Top 50 Trending Music Global',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCategoryTap(String query, MusicProvider provider) {
    _searchCtrl.text = query;
    provider.search(query);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final results = provider.searchResults;
    final isSearching = provider.isSearching;
    final searchHistory = StorageService.getSearchHistory();

    return Scaffold(
      backgroundColor: AppleMusicColors.background,
      body: CustomScrollView(
        slivers: [
          // Cupertino Large Title
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Cari',
              style: TextStyle(
                color: AppleMusicColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            backgroundColor: AppleMusicColors.background.withOpacity(0.8),
            border: null,
          ),

          // Apple Music Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoSearchTextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                placeholder: 'Artis, Lagu, Lirik, dan Lainnya',
                placeholderStyle: const TextStyle(
                  color: AppleMusicColors.textSecondary,
                  fontSize: 16,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                backgroundColor: AppleMusicColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                itemColor: AppleMusicColors.textSecondary,
                prefixInsets: const EdgeInsets.only(left: 10),
                onChanged: (val) {
                  if (val.isEmpty) {
                    provider.search('');
                  }
                },
                onSubmitted: (val) {
                  provider.search(val);
                },
              ),
            ),
          ),

          // Search Results View
          if (isSearching)
            const SliverFillRemaining(
              child: Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                  color: AppleMusicColors.accent,
                ),
              ),
            )
          else if (_searchCtrl.text.isNotEmpty && results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = results[index];
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 50,
                              height: 50,
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
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppleMusicColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${song.artist}${song.album != null ? ' • ${song.album}' : ''}',
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
                              IconButton(
                                icon: Icon(
                                  provider.isFavorite(song.id)
                                      ? CupertinoIcons.heart_fill
                                      : CupertinoIcons.heart,
                                  color: provider.isFavorite(song.id)
                                      ? AppleMusicColors.accent
                                      : AppleMusicColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => provider.toggleFavorite(song),
                              ),
                              const Icon(
                                CupertinoIcons.ellipsis,
                                color: AppleMusicColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                          onTap: () {
                            provider.playSong(song, queue: results, index: index);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 80),
                          child: Divider(color: AppleMusicColors.divider, height: 1),
                        ),
                      ],
                    );
                  },
                  childCount: results.length,
                ),
              ),
            )
          else ...[
            // Recent Searches Chips
            if (searchHistory.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Pencarian Terkini',
                    style: TextStyle(
                      color: AppleMusicColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: searchHistory.length,
                    itemBuilder: (context, index) {
                      final item = searchHistory[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ActionChip(
                          backgroundColor: AppleMusicColors.surfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide.none,
                          label: Text(
                            item,
                            style: const TextStyle(
                              color: AppleMusicColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () {
                            _searchCtrl.text = item;
                            provider.search(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Browse Categories Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text(
                  'Jelajahi Kategori',
                  style: TextStyle(
                    color: AppleMusicColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            // 2-Column Categories Gradient Tiles
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = _categories[index];
                    final colors = cat['colors'] as List<Color>;

                    return GestureDetector(
                      onTap: () => _onCategoryTap(cat['query'] as String, provider),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            cat['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _categories.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}
