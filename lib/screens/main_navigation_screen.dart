import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/apple_music_colors.dart';
import '../widgets/mini_player.dart';
import 'listen_now_screen.dart';
import 'browse_screen.dart';
import 'radio_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ListenNowScreen(),
    BrowseScreen(),
    RadioScreen(),
    LibraryScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleMusicColors.background,
      body: Stack(
        children: [
          // Current Tab View
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Docked MiniPlayer directly above the bottom tab bar
          const Positioned(
            left: 0,
            right: 0,
            bottom: 60, // Sits above the 50-60px tab bar
            child: MiniPlayer(),
          ),
        ],
      ),

      // Apple Music Exact 5-Tab Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppleMusicColors.surface.withOpacity(0.85),
          border: const Border(
            top: BorderSide(
              color: AppleMusicColors.divider,
              width: 0.5,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: CupertinoTabBar(
              currentIndex: _currentIndex,
              backgroundColor: Colors.transparent,
              activeColor: AppleMusicColors.accent,
              inactiveColor: AppleMusicColors.textSecondary,
              iconSize: 24,
              height: 52,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.play_circle_fill),
                  label: 'Dengarkan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.square_grid_2x2_fill),
                  label: 'Telusuri',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.dot_radiowaves_left_right),
                  label: 'Radio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.music_albums_fill),
                  label: 'Perpustakaan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.search),
                  label: 'Cari',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
