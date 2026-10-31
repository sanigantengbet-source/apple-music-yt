import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class StorageService {
  static const String _keyFavorites = 'apple_music_favorites';
  static const String _keyHistory = 'apple_music_history';
  static const String _keySearchHistory = 'apple_music_search_history';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favorites
  static List<Song> getFavorites() {
    final list = _prefs?.getStringList(_keyFavorites) ?? [];
    return list.map((jsonStr) => Song.fromJson(jsonDecode(jsonStr))).toList();
  }

  static Future<void> toggleFavorite(Song song) async {
    final favorites = getFavorites();
    final index = favorites.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      favorites.removeAt(index);
      song.isLiked = false;
    } else {
      song.isLiked = true;
      favorites.insert(0, song);
    }
    final encoded = favorites.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs?.setStringList(_keyFavorites, encoded);
  }

  static bool isFavorite(String songId) {
    final favorites = getFavorites();
    return favorites.any((s) => s.id == songId);
  }

  // Recently Played History
  static List<Song> getHistory() {
    final list = _prefs?.getStringList(_keyHistory) ?? [];
    return list.map((jsonStr) => Song.fromJson(jsonDecode(jsonStr))).toList();
  }

  static Future<void> addToHistory(Song song) async {
    final history = getHistory();
    history.removeWhere((s) => s.id == song.id);
    history.insert(0, song);
    if (history.length > 50) history.removeLast();

    final encoded = history.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs?.setStringList(_keyHistory, encoded);
  }

  // Search History
  static List<String> getSearchHistory() {
    return _prefs?.getStringList(_keySearchHistory) ?? [
      'Taylor Swift',
      'The Weeknd',
      'Billie Eilish',
      'Kendrick Lamar',
      'Coldplay',
    ];
  }

  static Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final list = getSearchHistory();
    list.removeWhere((q) => q.toLowerCase() == query.toLowerCase());
    list.insert(0, query.trim());
    if (list.length > 20) list.removeLast();
    await _prefs?.setStringList(_keySearchHistory, list);
  }
}
