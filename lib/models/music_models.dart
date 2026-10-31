import 'song.dart';

class Album {
  final String id;
  final String title;
  final String artist;
  final String? year;
  final String thumbnailUrl;
  final List<Song> tracks;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    this.year,
    required this.thumbnailUrl,
    this.tracks = const [],
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['browseId'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      year: json['year'],
      thumbnailUrl: json['thumbnail'] ?? json['thumbnail_url'] ?? '',
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((t) => Song.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Artist {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String? subscribers;
  final List<Song> topSongs;
  final List<Album> albums;

  Artist({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.subscribers,
    this.topSongs = const [],
    this.albums = const [],
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['browseId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      thumbnailUrl: json['thumbnail'] ?? json['thumbnail_url'] ?? '',
      subscribers: json['subscribers'],
    );
  }
}

class Playlist {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String? description;
  final int trackCount;
  final List<Song> tracks;

  Playlist({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    this.description,
    this.trackCount = 0,
    this.tracks = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['browseId'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? json['channel'] ?? 'YouTube Music',
      thumbnailUrl: json['thumbnail'] ?? json['thumbnail_url'] ?? '',
      description: json['description'],
      trackCount: json['trackCount'] ?? 0,
    );
  }
}

class LyricsLine {
  final Duration timestamp;
  final String text;

  LyricsLine({
    required this.timestamp,
    required this.text,
  });
}
