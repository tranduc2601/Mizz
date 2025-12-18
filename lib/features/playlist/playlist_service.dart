import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'playlist_model.dart';

/// Playlist Service - Manages user playlists
class PlaylistService extends ChangeNotifier {
  static const String _storageKey = 'user_playlists';

  final List<Playlist> _playlists = [];

  /// Get all playlists
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  /// Get total playlist count
  int get totalPlaylists => _playlists.length;

  /// Initialize service and load playlists from storage
  Future<void> init() async {
    await _loadFromStorage();
  }

  /// Load playlists from SharedPreferences
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString(_storageKey);

      if (playlistsJson != null) {
        final List<dynamic> decoded = json.decode(playlistsJson);
        _playlists.clear();
        _playlists.addAll(decoded.map((e) => Playlist.fromJson(e)).toList());
        notifyListeners();
        debugPrint('📂 Loaded ${_playlists.length} playlists from storage');
      }
    } catch (e) {
      debugPrint('❌ Error loading playlists: $e');
    }
  }

  /// Save playlists to SharedPreferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = json.encode(
        _playlists.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_storageKey, playlistsJson);
      debugPrint('💾 Saved ${_playlists.length} playlists to storage');
    } catch (e) {
      debugPrint('❌ Error saving playlists: $e');
    }
  }

  /// Create a new playlist
  Playlist createPlaylist({required String name, String? coverImage}) {
    final now = DateTime.now();
    final playlist = Playlist(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      coverImage: coverImage,
      songIds: [],
      createdAt: now,
      updatedAt: now,
    );

    _playlists.add(playlist);
    _saveToStorage();
    notifyListeners();
    return playlist;
  }

  /// Delete a playlist
  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    _saveToStorage();
    notifyListeners();
  }

  /// Rename a playlist
  void renamePlaylist(String id, String newName) {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Add a song to a playlist
  void addSongToPlaylist(String playlistId, String songId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      if (!playlist.songIds.contains(songId)) {
        _playlists[index] = playlist.copyWith(
          songIds: [...playlist.songIds, songId],
          updatedAt: DateTime.now(),
        );
        _saveToStorage();
        notifyListeners();
      }
    }
  }

  /// Remove a song from a playlist
  void removeSongFromPlaylist(String playlistId, String songId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      _playlists[index] = playlist.copyWith(
        songIds: playlist.songIds.where((id) => id != songId).toList(),
        updatedAt: DateTime.now(),
      );
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Get a playlist by ID
  Playlist? getPlaylist(String id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update playlist cover image
  void updateCoverImage(String playlistId, String? coverImage) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(
        coverImage: coverImage,
        updatedAt: DateTime.now(),
      );
      _saveToStorage();
      notifyListeners();
    }
  }
}

/// Provider widget for PlaylistService
class PlaylistServiceProvider extends InheritedNotifier<PlaylistService> {
  const PlaylistServiceProvider({
    super.key,
    required PlaylistService service,
    required super.child,
  }) : super(notifier: service);

  static PlaylistService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<PlaylistServiceProvider>();
    return provider!.notifier!;
  }
}
