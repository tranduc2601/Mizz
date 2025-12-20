/// Music Item Model
class MusicItem {
  final String id;
  final String title;
  final String artist;
  final String albumArt;
  final String musicSource; // File path or URL (YouTube or direct)
  final String?
  localFilePath; // Cached local MP3 file path (for faster playback)
  final String duration;
  final bool isFavorite;

  const MusicItem({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt = '',
    required this.musicSource,
    this.localFilePath,
    required this.duration,
    this.isFavorite = false,
  });

  /// Check if this is a YouTube source
  bool get isYouTubeSource =>
      musicSource.contains('youtube.com') || musicSource.contains('youtu.be');

  /// Get the best source to play (prefer local file if available)
  String get playableSource => localFilePath ?? musicSource;

  /// Check if local cache exists
  bool get hasLocalCache => localFilePath != null && localFilePath!.isNotEmpty;

  /// Creates a copy with updated fields
  /// Use [clearLocalFilePath] = true to explicitly set localFilePath to null
  MusicItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArt,
    String? musicSource,
    String? localFilePath,
    bool clearLocalFilePath = false,
    String? duration,
    bool? isFavorite,
  }) {
    return MusicItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      musicSource: musicSource ?? this.musicSource,
      localFilePath: clearLocalFilePath
          ? null
          : (localFilePath ?? this.localFilePath),
      duration: duration ?? this.duration,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Sample Music Data
class MusicData {
  static List<MusicItem> getSampleMusic() {
    return [];
  }
}
