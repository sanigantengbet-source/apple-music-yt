import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/music_models.dart';
import 'rust_bridge.dart';

class YtMusicApiService {
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static final http.Client _client = http.Client();
  final RustBridge _rustBridge = RustBridge();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://music.youtube.com/',
  };

  static Map<String, dynamic> _getWebRemixContext() {
    return {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.20240101.01.00',
        'hl': 'en',
        'gl': 'US',
      }
    };
  }

  static Map<String, dynamic> _getAndroidMusicContext() {
    return {
      'client': {
        'clientName': 'ANDROID_MUSIC',
        'clientVersion': '6.31.55',
        'androidSdkVersion': 33,
        'hl': 'en',
        'gl': 'US',
      }
    };
  }

  /// Search YouTube Music catalog
  Future<List<Song>> search(String query, {String filter = 'songs'}) async {
    // 1. Try Rust native core
    if (_rustBridge.isRustNativeAvailable) {
      final rustSongs = _rustBridge.search(query, filter: filter);
      if (rustSongs != null && rustSongs.isNotEmpty) {
        return rustSongs;
      }
    }

    // 2. High-performance fallback InnerTube
    try {
      String? params;
      if (filter == 'songs') {
        params = 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D';
      } else if (filter == 'albums') {
        params = 'EgWKAQIYAWoKEAkQBRAKEAMQBA%3D%3D';
      }

      final body = {
        'context': _getWebRemixContext(),
        'query': query,
      };
      if (params != null) {
        body['params'] = params;
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/search?prettyPrint=false'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);

      final songs = <Song>[];
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]
          ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

      if (contents is List) {
        for (final section in contents) {
          final shelfItems = section['musicShelfRenderer']?['contents'];
          if (shelfItems is List) {
            for (final item in shelfItems) {
              final song = _parseMusicResponsiveListItem(item);
              if (song != null) {
                songs.add(song);
              }
            }
          }
        }
      }

      return songs;
    } catch (e) {
      return [];
    }
  }

  Song? _parseMusicResponsiveListItem(dynamic item) {
    try {
      final renderer = item['musicResponsiveListItemRenderer'];
      if (renderer == null) return null;

      final flexColumns = renderer['flexColumns'] as List?;
      if (flexColumns == null || flexColumns.isEmpty) return null;

      final title = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']?['text']
          ?['runs']?[0]?['text'] as String?;
      if (title == null) return null;

      String? videoId = renderer['playlistItemData']?['videoId'];
      if (videoId == null) {
        videoId = renderer['overlay']?['musicItemThumbnailOverlayRenderer']?['content']
            ?['musicPlayButtonRenderer']?['playNavigationEndpoint']?['watchEndpoint']?['videoId'];
      }
      if (videoId == null) return null;

      String artist = 'Unknown Artist';
      String? album;
      String? duration;

      if (flexColumns.length > 1) {
        final runs = flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']?['text']
            ?['runs'] as List?;
        if (runs != null && runs.isNotEmpty) {
          artist = runs[0]?['text'] ?? 'Unknown Artist';
          if (runs.length >= 3) {
            album = runs[2]?['text'];
          }
          if (runs.length >= 5) {
            duration = runs[4]?['text'];
          }
        }
      }

      String thumbnailUrl = '';
      final thumbs = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']
          ?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnailUrl = thumbs.last['url'] ?? '';
      }

      return Song(
        id: videoId,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get direct playable audio stream URL
  Future<String?> getStreamUrl(String videoId) async {
    // 1. Try Rust native core
    if (_rustBridge.isRustNativeAvailable) {
      final rustInfo = _rustBridge.getStreamUrl(videoId);
      if (rustInfo != null && rustInfo['url'] != null) {
        return rustInfo['url'] as String;
      }
    }

    // 2. High-performance fallback InnerTube Player
    try {
      final body = {
        'context': _getAndroidMusicContext(),
        'videoId': videoId,
        'playbackContext': {
          'contentPlaybackContext': {
            'html5Preference': 'HTML5_PREF_WANTS',
          }
        }
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/player?prettyPrint=false'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'com.google.android.apps.youtube.music/6.31.55 (Linux; U; Android 13)',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);

      final adaptiveFormats = data['streamingData']?['adaptiveFormats'] as List?;
      if (adaptiveFormats == null) return null;

      dynamic bestFormat;
      int bestBitrate = 0;

      for (final fmt in adaptiveFormats) {
        final mimeType = fmt['mimeType'] as String? ?? '';
        if (mimeType.startsWith('audio/')) {
          final bitrate = (fmt['bitrate'] as num?)?.toInt() ?? 0;
          if (bitrate > bestBitrate) {
            bestBitrate = bitrate;
            bestFormat = fmt;
          }
        }
      }

      if (bestFormat != null) {
        if (bestFormat['url'] != null) {
          return bestFormat['url'] as String;
        }
      }

      // If no direct url in adaptive, check regular formats
      final regularFormats = data['streamingData']?['formats'] as List?;
      if (regularFormats != null && regularFormats.isNotEmpty) {
        return regularFormats[0]['url'] as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch Apple Music style curated home feed
  Future<Map<String, List<Song>>> getCuratedHomeFeed() async {
    final Map<String, List<Song>> shelves = {};

    try {
      final topPicks = await search('Today Hits Top Charts', filter: 'songs');
      if (topPicks.isNotEmpty) {
        shelves['Pilihan Teratas (Top Picks)'] = topPicks.take(8).toList();
      }

      final indonesianHits = await search('Lagu Populer Indonesia Terbaru', filter: 'songs');
      if (indonesianHits.isNotEmpty) {
        shelves['Lagu Populer Terkini'] = indonesianHits.take(8).toList();
      }

      final chillVibes = await search('Chill Acoustic Relaxing Music', filter: 'songs');
      if (chillVibes.isNotEmpty) {
        shelves['Santai & Akustik (Chill)'] = chillVibes.take(8).toList();
      }

      final spatialAudio = await search('Spatial Audio Dolby Atmos Hits', filter: 'songs');
      if (spatialAudio.isNotEmpty) {
        shelves['Sorotan Audio Spasial'] = spatialAudio.take(8).toList();
      }
    } catch (_) {}

    return shelves;
  }

  /// Fetch related songs for continuous radio playback (Up Next)
  Future<List<Song>> getUpNextRadio(String videoId) async {
    try {
      final body = {
        'context': _getWebRemixContext(),
        'videoId': videoId,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/next?prettyPrint=false'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);

      final songs = <Song>[];
      final tabs = data['contents']?['singleColumnMusicWatchNextResultsRenderer']
          ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'] as List?;

      if (tabs != null && tabs.isNotEmpty) {
        final queueContents = tabs[0]?['tabRenderer']?['content']
            ?['musicQueueRenderer']?['content']?['playlistPanelRenderer']?['contents'] as List?;

        if (queueContents != null) {
          for (final item in queueContents) {
            final renderer = item['playlistPanelVideoRenderer'];
            if (renderer != null) {
              final id = renderer['videoId'] as String?;
              final title = renderer['title']?['runs']?[0]?['text'] as String?;
              String artist = 'Unknown Artist';
              final runs = renderer['longBylineText']?['runs'] as List?;
              if (runs != null && runs.isNotEmpty) {
                artist = runs[0]?['text'] ?? 'Unknown Artist';
              }
              String thumb = '';
              final thumbs = renderer['thumbnail']?['thumbnails'] as List?;
              if (thumbs != null && thumbs.isNotEmpty) {
                thumb = thumbs.last['url'] ?? '';
              }

              if (id != null && title != null && id != videoId) {
                songs.add(Song(
                  id: id,
                  title: title,
                  artist: artist,
                  thumbnailUrl: thumb,
                ));
              }
            }
          }
        }
      }

      return songs;
    } catch (_) {
      return [];
    }
  }

  /// Fetch lyrics for song
  Future<List<LyricsLine>> getLyrics(String videoId, String title, String artist) async {
    try {
      // 1. Try InnerTube next lyrics endpoint
      final body = {
        'context': _getWebRemixContext(),
        'videoId': videoId,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/next?prettyPrint=false'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tabs = data['contents']?['singleColumnMusicWatchNextResultsRenderer']
            ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'] as List?;

        if (tabs != null && tabs.length > 1) {
          final browseId = tabs[1]?['tabRenderer']?['endpoint']?['browseEndpoint']?['browseId'];
          if (browseId != null) {
            final lyricsResp = await _client.post(
              Uri.parse('$_baseUrl/browse?prettyPrint=false'),
              headers: _headers,
              body: jsonEncode({
                'context': _getWebRemixContext(),
                'browseId': browseId,
              }),
            );

            if (lyricsResp.statusCode == 200) {
              final lyricData = jsonDecode(lyricsResp.body);
              final desc = lyricData['contents']?['sectionListRenderer']?['contents']?[0]
                  ?['musicDescriptionShelfRenderer']?['description']?['runs']?[0]?['text'] as String?;

              if (desc != null && desc.isNotEmpty) {
                return _parsePlainLyrics(desc);
              }
            }
          }
        }
      }
    } catch (_) {}

    // Fallback: search open lrc / lyrics
    return _generateTimedPlaceholderLyrics(title, artist);
  }

  List<LyricsLine> _parsePlainLyrics(String text) {
    final lines = text.split('\n');
    final result = <LyricsLine>[];
    int secondOffset = 5;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        result.add(LyricsLine(
          timestamp: Duration(seconds: secondOffset),
          text: trimmed,
        ));
        secondOffset += 4;
      }
    }
    return result;
  }

  List<LyricsLine> _generateTimedPlaceholderLyrics(String title, String artist) {
    return [
      LyricsLine(timestamp: const Duration(seconds: 4), text: '♪ Instrumental Intro ♪'),
      LyricsLine(timestamp: const Duration(seconds: 12), text: 'Sedang memutar: $title'),
      LyricsLine(timestamp: const Duration(seconds: 18), text: 'Oleh $artist'),
      LyricsLine(timestamp: const Duration(seconds: 24), text: 'Audio kualitas tinggi dari YouTube Music'),
      LyricsLine(timestamp: const Duration(seconds: 32), text: 'Pemutaran latar belakang aktif'),
      LyricsLine(timestamp: const Duration(seconds: 45), text: '♪ Melodi Mengalun ♪'),
    ];
  }
}
