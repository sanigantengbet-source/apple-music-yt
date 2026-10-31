import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../models/music_models.dart';
import '../services/audio_player_service.dart';
import '../services/ytmusic_api_service.dart';
import '../services/storage_service.dart';

class MusicProvider extends ChangeNotifier {
  final AppleMusicAudioHandler audioHandler;
  final YtMusicApiService _apiService = YtMusicApiService();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  bool _isPlaying = false;
  double _volume = 1.0;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;

  Map<String, List<Song>> _homeShelves = {};
  bool _isLoadingHome = false;

  List<Song> _searchResults = [];
  bool _isSearching = false;
  String _currentSearchQuery = '';

  List<LyricsLine> _lyrics = [];
  int _currentLyricIndex = 0;
  bool _isLoadingLyrics = false;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playbackStateSub;
  StreamSubscription? _mediaItemSub;

  MusicProvider({required this.audioHandler}) {
    _initListeners();
    loadHomeFeed();
  }

  // Getters
  Song? get currentSong => audioHandler.currentSong;
  List<Song> get queue => audioHandler.songQueue;
  int get currentIndex => audioHandler.currentIndex;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  Map<String, List<Song>> get homeShelves => _homeShelves;
  bool get isLoadingHome => _isLoadingHome;
  List<Song> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get currentSearchQuery => _currentSearchQuery;
  List<LyricsLine> get lyrics => _lyrics;
  int get currentLyricIndex => _currentLyricIndex;
  bool get isLoadingLyrics => _isLoadingLyrics;

  void _initListeners() {
    _playbackStateSub = audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _position = state.position;
      _bufferedPosition = state.bufferedPosition;
      _updateLyricIndex();
      notifyListeners();
    });

    _posSub = audioHandler.player.positionStream.listen((pos) {
      _position = pos;
      _updateLyricIndex();
      notifyListeners();
    });

    _durSub = audioHandler.player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _mediaItemSub = audioHandler.mediaItem.listen((item) {
      if (item != null && currentSong != null) {
        StorageService.addToHistory(currentSong!);
        loadLyricsForCurrentSong();
      }
      notifyListeners();
    });

    _volume = audioHandler.player.volume;
  }

  void _updateLyricIndex() {
    if (_lyrics.isEmpty) return;
    int index = 0;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_position >= _lyrics[i].timestamp) {
        index = i;
      } else {
        break;
      }
    }
    if (_currentLyricIndex != index) {
      _currentLyricIndex = index;
      notifyListeners();
    }
  }

  // Audio Playback Controls
  Future<void> playSong(Song song, {List<Song>? queue, int index = 0}) async {
    await audioHandler.playSong(song, queue: queue, initialIndex: index);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
    notifyListeners();
  }

  Future<void> skipToNext() async {
    await audioHandler.skipToNext();
    notifyListeners();
  }

  Future<void> skipToPrevious() async {
    await audioHandler.skipToPrevious();
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await audioHandler.seek(position);
    _position = position;
    _updateLyricIndex();
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await audioHandler.player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    await audioHandler.player.setShuffleModeEnabled(_isShuffle);
    notifyListeners();
  }

  Future<void> toggleRepeat() async {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
    await audioHandler.player.setLoopMode(_loopMode);
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    await StorageService.toggleFavorite(song);
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return StorageService.isFavorite(songId);
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    await audioHandler.reorderQueue(oldIndex, newIndex);
    notifyListeners();
  }

  Future<void> addToQueue(Song song) async {
    await audioHandler.addToQueue(song);
    notifyListeners();
  }

  // Home Feed
  Future<void> loadHomeFeed() async {
    if (_isLoadingHome) return;
    _isLoadingHome = true;
    notifyListeners();

    try {
      _homeShelves = await _apiService.getCuratedHomeFeed();
    } catch (_) {}

    _isLoadingHome = false;
    notifyListeners();
  }

  // Search
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _currentSearchQuery = '';
      notifyListeners();
      return;
    }

    _currentSearchQuery = query;
    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _apiService.search(query);
      StorageService.addSearchQuery(query);
    } catch (_) {
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  // Lyrics
  Future<void> loadLyricsForCurrentSong() async {
    final song = currentSong;
    if (song == null) return;

    _isLoadingLyrics = true;
    _lyrics = [];
    notifyListeners();

    try {
      _lyrics = await _apiService.getLyrics(song.id, song.title, song.artist);
    } catch (_) {
      _lyrics = [];
    }

    _isLoadingLyrics = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playbackStateSub?.cancel();
    _mediaItemSub?.cancel();
    super.dispose();
  }
}
