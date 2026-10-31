import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import 'ytmusic_api_service.dart';

/// Background Audio Handler using audio_service and just_audio
class AppleMusicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final YtMusicApiService _apiService = YtMusicApiService();

  List<Song> _currentQueue = [];
  int _currentIndex = -1;

  AppleMusicAudioHandler() {
    _initAudioPlayerListeners();
  }

  void _initAudioPlayerListeners() {
    // Broadcast playback state changes to Android notification & iOS LockScreen
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ));
    });

    // Automatically handle song completion & play next
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  AudioPlayer get player => _player;
  List<Song> get songQueue => _currentQueue;
  int get currentIndex => _currentIndex;
  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _currentQueue.length)
      ? _currentQueue[_currentIndex]
      : null;

  /// Play a song directly or start a new queue
  Future<void> playSong(Song song, {List<Song>? queue, int initialIndex = 0}) async {
    if (queue != null && queue.isNotEmpty) {
      _currentQueue = List.from(queue);
      _currentIndex = initialIndex;
    } else {
      _currentQueue = [song];
      _currentIndex = 0;
    }

    await _playCurrentIndex();
  }

  Future<void> _playCurrentIndex() async {
    if (_currentIndex < 0 || _currentIndex >= _currentQueue.length) return;
    final song = _currentQueue[_currentIndex];

    // Update MediaItem for Android Notification & iOS Lockscreen
    final item = MediaItem(
      id: song.id,
      album: song.album ?? 'YouTube Music',
      title: song.title,
      artist: song.artist,
      duration: song.durationSeconds > 0 ? Duration(seconds: song.durationSeconds) : null,
      artUri: song.thumbnailUrl.isNotEmpty ? Uri.tryParse(song.thumbnailUrl) : null,
    );
    mediaItem.add(item);

    // Update queue in AudioService
    this.queue.add(_currentQueue.map((s) => MediaItem(
      id: s.id,
      album: s.album ?? 'YouTube Music',
      title: s.title,
      artist: s.artist,
      artUri: s.thumbnailUrl.isNotEmpty ? Uri.tryParse(s.thumbnailUrl) : null,
    )).toList());

    try {
      // Resolve audio stream URL if not cached
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await _apiService.getStreamUrl(song.id);
        song.streamUrl = streamUrl;
      }

      if (streamUrl != null && streamUrl.isNotEmpty) {
        await _player.setUrl(streamUrl);
        await _player.play();
      } else {
        // Fallback or retry next
        if (_currentQueue.length > 1) {
          skipToNext();
        }
      }
    } catch (e) {
      // Stream error handling
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_currentQueue.isEmpty) return;
    if (_currentIndex + 1 < _currentQueue.length) {
      _currentIndex++;
      await _playCurrentIndex();
    } else {
      // Fetch radio recommendations automatically to keep playing seamlessly
      if (_currentQueue.isNotEmpty) {
        final lastSong = _currentQueue.last;
        final recommendations = await _apiService.getUpNextRadio(lastSong.id);
        if (recommendations.isNotEmpty) {
          _currentQueue.addAll(recommendations);
          _currentIndex++;
          await _playCurrentIndex();
        }
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      // If played for more than 3 seconds, seek to start (like Apple Music)
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await _playCurrentIndex();
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _currentQueue.length) {
      _currentIndex = index;
      await _playCurrentIndex();
    }
  }

  Future<void> addToQueue(Song song) async {
    _currentQueue.add(song);
    this.queue.add(_currentQueue.map((s) => MediaItem(
      id: s.id,
      title: s.title,
      artist: s.artist,
      artUri: Uri.tryParse(s.thumbnailUrl),
    )).toList());
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _currentQueue.length ||
        newIndex < 0 || newIndex >= _currentQueue.length) return;

    final song = _currentQueue.removeAt(oldIndex);
    _currentQueue.insert(newIndex, song);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
  }
}
