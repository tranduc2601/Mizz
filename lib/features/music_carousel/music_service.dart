import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'music_model.dart';

/// Music Service - Manages the music library with persistence
class MusicService extends ChangeNotifier {
  List<MusicItem> _musicItems = [];
  List<MusicItem> _recentlyPlayed = [];
  static const String _storageKey = 'mizz_music_library';
  static const String _recentlyPlayedKey = 'mizz_recently_played';

  MusicService() {
    _loadFromStorage();
  }

  List<MusicItem> get musicItems => List.unmodifiable(_musicItems);
  List<MusicItem> get favoriteItems => _musicItems.where((s) => s.isFavorite).toList();
  List<MusicItem> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  int get totalSongs => _musicItems.length;
  int get totalFavorites => favoriteItems.length;

  /// Load songs from storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _musicItems = jsonList.map((j) => _musicItemFromJson(j)).toList();
        debugPrint('📂 Loaded ${_musicItems.length} songs from storage');
      }
      
      // Load recently played
      final recentJson = prefs.getString(_recentlyPlayedKey);
      if (recentJson != null) {
        final List<dynamic> recentList = json.decode(recentJson);
        _recentlyPlayed = recentList.map((j) => _musicItemFromJson(j)).toList();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading songs: $e');
    }
  }

  /// Save songs to storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _musicItems.map((s) => _musicItemToJson(s)).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
      
      // Save recently played (max 50)
      final recentList = _recentlyPlayed.take(50).map((s) => _musicItemToJson(s)).toList();
      await prefs.setString(_recentlyPlayedKey, json.encode(recentList));
      
      debugPrint('💾 Saved ${_musicItems.length} songs to storage');
    } catch (e) {
      debugPrint('❌ Error saving songs: $e');
    }
  }

  Map<String, dynamic> _musicItemToJson(MusicItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'artist': item.artist,
      'albumArt': item.albumArt,
      'musicSource': item.musicSource,
      'duration': item.duration,
      'isFavorite': item.isFavorite,
    };
  }

  MusicItem _musicItemFromJson(Map<String, dynamic> json) {
    return MusicItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      albumArt: json['albumArt'] ?? '',
      musicSource: json['musicSource'] ?? '',
      duration: json['duration'] ?? '0:00',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  /// Add a new song to the library
  void addSong({
    required String title,
    required String artist,
    required String musicSource,
    String? albumArt,
  }) {
    final newSong = MusicItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      artist: artist,
      albumArt: albumArt ?? '',
      musicSource: musicSource,
      duration: '0:00',
      isFavorite: false,
    );

    _musicItems.add(newSong);
    _saveToStorage();
    notifyListeners();
  }

  /// Remove a song from the library
  void removeSong(String id) {
    _musicItems.removeWhere((song) => song.id == id);
    _saveToStorage();
    notifyListeners();
  }

  /// Toggle favorite status
  void toggleFavorite(String id) {
    final index = _musicItems.indexWhere((song) => song.id == id);
    if (index != -1) {
      _musicItems[index] = _musicItems[index].copyWith(
        isFavorite: !_musicItems[index].isFavorite,
      );
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Add to recently played
  void addToRecentlyPlayed(String id) {
    final song = getSongById(id);
    if (song != null) {
      // Remove if already exists
      _recentlyPlayed.removeWhere((s) => s.id == id);
      // Add to beginning
      _recentlyPlayed.insert(0, song);
      // Keep max 50
      if (_recentlyPlayed.length > 50) {
        _recentlyPlayed = _recentlyPlayed.take(50).toList();
      }
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Update song details
  void updateSong(
    String id, {
    String? title,
    String? artist,
    String? albumArt,
    String? duration,
  }) {
    final index = _musicItems.indexWhere((song) => song.id == id);
    if (index != -1) {
      _musicItems[index] = _musicItems[index].copyWith(
        title: title,
        artist: artist,
        albumArt: albumArt,
        duration: duration,
      );
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Get song by ID
  MusicItem? getSongById(String id) {
    try {
      return _musicItems.firstWhere((song) => song.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear recently played history
  void clearRecentlyPlayed() {
    _recentlyPlayed.clear();
    _saveToStorage();
    notifyListeners();
  }
}

/// Music Service Provider - Provides music service to the widget tree
class MusicServiceProvider extends InheritedWidget {
  final MusicService musicService;

  const MusicServiceProvider({
    super.key,
    required this.musicService,
    required super.child,
  });

  static MusicService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<MusicServiceProvider>();
    assert(provider != null, 'No MusicServiceProvider found in context');
    return provider!.musicService;
  }

  @override
  bool updateShouldNotify(MusicServiceProvider oldWidget) {
    return musicService != oldWidget.musicService;
  }
}
