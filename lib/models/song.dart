class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? duration;
  final int durationSeconds;
  final String thumbnailUrl;
  String? streamUrl;
  bool isLiked;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.durationSeconds = 0,
    required this.thumbnailUrl,
    this.streamUrl,
    this.isLiked = false,
  });

  // High-res thumbnail helper (replaces low-res w60/w120 with w600 or maxresdefault)
  String get highResThumbnail {
    if (thumbnailUrl.isEmpty) return '';
    if (thumbnailUrl.contains('googleusercontent.com') || thumbnailUrl.contains('ggpht.com')) {
      return thumbnailUrl.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w800-h800-l90-rj');
    }
    if (thumbnailUrl.contains('ytimg.com/vi/')) {
      return thumbnailUrl.replaceAll(RegExp(r'/(default|hqdefault|mqdefault|sddefault)\.jpg'), '/maxresdefault.jpg');
    }
    return thumbnailUrl;
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    int durationSec = 0;
    if (json['duration_seconds'] != null) {
      durationSec = (json['duration_seconds'] as num).toInt();
    } else if (json['duration'] != null && json['duration'] is String) {
      final parts = (json['duration'] as String).split(':');
      if (parts.length == 2) {
        durationSec = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      } else if (parts.length == 3) {
        durationSec = (int.tryParse(parts[0]) ?? 0) * 3600 +
            (int.tryParse(parts[1]) ?? 0) * 60 +
            (int.tryParse(parts[2]) ?? 0);
      }
    }

    return Song(
      id: json['id'] ?? json['videoId'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? (json['artists'] != null && json['artists'] is List && (json['artists'] as List).isNotEmpty ? json['artists'][0]['name'] : 'Unknown Artist'),
      album: json['album'] is Map ? json['album']['name'] : json['album'],
      duration: json['duration'],
      durationSeconds: durationSec,
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnail'] ?? '',
      streamUrl: json['stream_url'],
      isLiked: json['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'duration_seconds': durationSeconds,
      'thumbnail_url': thumbnailUrl,
      'stream_url': streamUrl,
      'isLiked': isLiked,
    };
  }
}
