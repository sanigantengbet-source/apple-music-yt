import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  int _lastScrolledIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<MusicProvider>();
    final currentIndex = provider.currentLyricIndex;

    if (currentIndex != _lastScrolledIndex && _scrollController.hasClients) {
      _lastScrolledIndex = currentIndex;
      _scrollToIndex(currentIndex);
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    const itemHeight = 70.0;
    final targetOffset = (index * itemHeight) - 150;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final lyrics = provider.lyrics;
    final currentIndex = provider.currentLyricIndex;

    if (provider.isLoadingLyrics) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 14,
          color: AppleMusicColors.textSecondary,
        ),
      );
    }

    if (lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.quote_bubble,
              size: 56,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Lirik Tidak Tersedia',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lirik belum tersedia untuk lagu ini di YouTube Music',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final line = lyrics[index];
        final isCurrent = index == currentIndex;

        return GestureDetector(
          onTap: () {
            provider.seekTo(line.timestamp);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: isCurrent ? 30 : 26,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent
                    ? Colors.white
                    : Colors.white.withOpacity(0.35),
                letterSpacing: -0.5,
                height: 1.25,
                shadows: isCurrent
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              child: Text(line.text),
            ),
          ),
        );
      },
    );
  }
}
