import 'package:flutter_test/flutter_test.dart';
import 'package:apple_music_yt/constants/apple_music_colors.dart';
import 'package:apple_music_yt/models/song.dart';
import 'package:apple_music_yt/models/music_models.dart';
import 'package:apple_music_yt/services/rust_bridge.dart';

void main() {
  group('AppleMusic App Core Tests', () {
    test('Song model serialization and highResThumbnail', () {
      final json = {
        'id': 'test_video_123',
        'title': 'Blinding Lights',
        'artist': 'The Weeknd',
        'album': 'After Hours',
        'duration': '3:20',
        'thumbnail_url': 'https://lh3.googleusercontent.com/abc=w120-h120',
        'isLiked': true,
      };

      final song = Song.fromJson(json);
      expect(song.id, 'test_video_123');
      expect(song.title, 'Blinding Lights');
      expect(song.artist, 'The Weeknd');
      expect(song.album, 'After Hours');
      expect(song.durationSeconds, 200);
      expect(song.isLiked, true);
      expect(song.highResThumbnail, contains('=w800-h800-l90-rj'));

      final serialized = song.toJson();
      expect(serialized['id'], 'test_video_123');
      expect(serialized['title'], 'Blinding Lights');
      expect(serialized['isLiked'], true);
    });

    test('Album model parsing', () {
      final json = {
        'browseId': 'MPREb_album1',
        'title': 'Starboy',
        'artist': 'The Weeknd',
        'year': '2016',
        'thumbnail': 'https://lh3.googleusercontent.com/starboy',
        'tracks': [
          {
            'id': 'track_1',
            'title': 'Starboy',
            'artist': 'The Weeknd',
            'duration': '3:50',
            'thumbnail_url': 'https://lh3.googleusercontent.com/starboy',
          }
        ],
      };

      final album = Album.fromJson(json);
      expect(album.id, 'MPREb_album1');
      expect(album.title, 'Starboy');
      expect(album.tracks.length, 1);
      expect(album.tracks.first.title, 'Starboy');
    });

    test('AppleMusicColors tokens consistency', () {
      expect(AppleMusicColors.accent.value, 0xFFFA243C);
      expect(AppleMusicColors.background.value, 0xFF000000);
      expect(AppleMusicColors.categoryGradients.isNotEmpty, true);
    });

    test('RustBridge singleton initialization and fallback behavior', () {
      final bridge1 = RustBridge();
      final bridge2 = RustBridge();
      expect(identical(bridge1, bridge2), true);
      // Even if native .so is not present in local test environment,
      // search returns null and doesn't throw or crash
      final result = bridge1.search('test');
      if (!bridge1.isRustNativeAvailable) {
        expect(result, isNull);
      }
    });
  });
}
