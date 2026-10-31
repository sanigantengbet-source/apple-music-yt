import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/apple_music_colors.dart';
import '../providers/music_provider.dart';
import 'lyrics_view.dart';
import 'queue_view.dart';

enum PlayerSubView { artwork, lyrics, queue }

class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> with SingleTickerProviderStateMixin {
  PlayerSubView _subView = PlayerSubView.artwork;
  double? _dragSeekSeconds;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatRemaining(Duration pos, Duration total) {
    if (total <= pos) return '-0:00';
    final rem = total - pos;
    final minutes = rem.inMinutes;
    final seconds = rem.inSeconds % 60;
    return '-$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showActionMenu(BuildContext context, dynamic song, MusicProvider provider) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(song.title),
        message: Text(song.artist),
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  provider.isFavorite(song.id)
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  color: AppleMusicColors.accent,
                ),
                const SizedBox(width: 8),
                Text(provider.isFavorite(song.id)
                    ? 'Hapus dari Favorit'
                    : 'Tambah ke Lagu Favorit'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.toggleFavorite(song);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Bagikan Lagu...'),
            onPressed: () {
              Navigator.pop(ctx);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Buat Stasiun Radio dari Lagu ini'),
            onPressed: () {
              Navigator.pop(ctx);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Tutup'),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final totalSeconds = provider.duration.inSeconds.toDouble();
    final currentSeconds = _dragSeekSeconds ??
        provider.position.inSeconds.toDouble().clamp(0.0, totalSeconds > 0 ? totalSeconds : 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dynamic Blurred Ambient Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF141416),
              child: song.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: song.highResThumbnail,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                color: Colors.black.withOpacity(0.68),
              ),
            ),
          ),

          // Main Player UI
          SafeArea(
          child: Column(
            children: [
              // Pull-down handle indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Header bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.chevron_down, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'MEMUTAR DARI YOUTUBE MUSIC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.album ?? 'Sonora Music Engine',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.ellipsis,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _showActionMenu(context, song, provider),
                    ),
                  ],
                ),
              ),

              // Center Stage (Switches between Artwork, Lyrics, and Queue)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildCenterContent(song, provider),
                ),
              ),

              // Bottom Control Section
              _buildBottomControls(song, provider, currentSeconds, totalSeconds),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCenterContent(dynamic song, MusicProvider provider) {
    if (_subView == PlayerSubView.lyrics) {
      return const LyricsView(key: ValueKey('lyrics'));
    }

    if (_subView == PlayerSubView.queue) {
      return const QueueView(key: ValueKey('queue'));
    }

    // Default: Artwork with Apple Music Paused/Playing Scale Animation
    final isPlaying = provider.isPlaying;
    return Center(
      key: const ValueKey('artwork'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
        child: AnimatedScale(
          scale: isPlaying ? 1.0 : 0.84,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isPlaying ? 0.65 : 0.4),
                    blurRadius: isPlaying ? 35 : 18,
                    offset: Offset(0, isPlaying ? 16 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: song.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.highResThumbnail,
                        fit: BoxFit.cover,
                        errorWidget: (context, _, __) => const Icon(
                          CupertinoIcons.music_note,
                          size: 80,
                          color: Colors.white54,
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.music_note,
                        size: 80,
                        color: Colors.white54,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    dynamic song,
    MusicProvider provider,
    double currentSeconds,
    double totalSeconds,
  ) {
    final isFavorite = provider.isFavorite(song.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title & Artist & Favorite Star/Heart
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.65),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Apple Lossless Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LOSSLESS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                iconSize: 26,
                icon: Icon(
                  isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: isFavorite ? AppleMusicColors.accent : Colors.white60,
                ),
                onPressed: () => provider.toggleFavorite(song),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Scrubber / Progress Bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: currentSeconds.clamp(0.0, totalSeconds > 0 ? totalSeconds : 1.0),
              min: 0.0,
              max: totalSeconds > 0 ? totalSeconds : 1.0,
              onChanged: (val) {
                setState(() {
                  _dragSeekSeconds = val;
                });
              },
              onChangeEnd: (val) {
                provider.seekTo(Duration(seconds: val.toInt()));
                setState(() {
                  _dragSeekSeconds = null;
                });
              },
            ),
          ),

          // Elapsed and Remaining Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(Duration(seconds: currentSeconds.toInt())),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                Text(
                  _formatRemaining(
                    Duration(seconds: currentSeconds.toInt()),
                    provider.duration,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Playback Buttons (Previous, Massive Play/Pause, Next)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                iconSize: 42,
                splashRadius: 32,
                icon: const Icon(CupertinoIcons.backward_fill, color: Colors.white),
                onPressed: () => provider.skipToPrevious(),
              ),
              IconButton(
                iconSize: 64,
                splashRadius: 40,
                icon: Icon(
                  provider.isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: Colors.white,
                ),
                onPressed: () => provider.togglePlayPause(),
              ),
              IconButton(
                iconSize: 42,
                splashRadius: 32,
                icon: const Icon(CupertinoIcons.forward_fill, color: Colors.white),
                onPressed: () => provider.skipToNext(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Volume Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.volume_down,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: Colors.white.withOpacity(0.85),
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    ),
                    child: Slider(
                      value: provider.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) => provider.setVolume(val),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.volume_up,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Bottom Action Row (Lyrics, AirPlay, Queue)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Lyrics Toggle
              IconButton(
                icon: Icon(
                  CupertinoIcons.quote_bubble_fill,
                  size: 24,
                  color: _subView == PlayerSubView.lyrics
                      ? AppleMusicColors.accent
                      : Colors.white.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _subView = (_subView == PlayerSubView.lyrics)
                        ? PlayerSubView.artwork
                        : PlayerSubView.lyrics;
                  });
                },
              ),

              // AirPlay Icon
              IconButton(
                icon: Icon(
                  CupertinoIcons.airplayaudio,
                  size: 24,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: () {},
              ),

              // Queue / Up Next Toggle
              IconButton(
                icon: Icon(
                  CupertinoIcons.list_bullet,
                  size: 24,
                  color: _subView == PlayerSubView.queue
                      ? AppleMusicColors.accent
                      : Colors.white.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _subView = (_subView == PlayerSubView.queue)
                        ? PlayerSubView.artwork
                        : PlayerSubView.queue;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
