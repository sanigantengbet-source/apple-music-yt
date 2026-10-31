import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'constants/apple_music_colors.dart';
import 'services/audio_player_service.dart';
import 'services/storage_service.dart';
import 'providers/music_provider.dart';
import 'screens/main_navigation_screen.dart';

late AppleMusicAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation & status bar matching iOS
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppleMusicColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Local Storage
  await StorageService.init();

  // Initialize Audio Service for Background Playback
  _audioHandler = await AudioService.init(
    builder: () => AppleMusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.applemusic.ytmusic.audio',
      androidNotificationChannelName: 'Apple Music YT Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  runApp(const AppleMusicApp());
}

class AppleMusicApp extends StatelessWidget {
  const AppleMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MusicProvider(audioHandler: _audioHandler),
        ),
      ],
      child: MaterialApp(
        title: 'Apple Music',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppleMusicColors.background,
          primaryColor: AppleMusicColors.accent,
          colorScheme: const ColorScheme.dark(
            primary: AppleMusicColors.accent,
            surface: AppleMusicColors.surface,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.white.withOpacity(0.08),
          fontFamily: '.SF Pro Display', // Defaults to iOS San Francisco font on Apple devices
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
