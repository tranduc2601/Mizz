/// Music Item Model
class MusicItem {
  final String id;
  final String title;
  final String artist;
  final String albumArt;
  final String musicSource; // File path or URL
  final String duration;
  final bool isFavorite;

  const MusicItem({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt = '',
    required this.musicSource,
    required this.duration,
    this.isFavorite = false,
  });

  MusicItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArt,
    String? musicSource,
    String? duration,
    bool? isFavorite,
  }) {
    return MusicItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      musicSource: musicSource ?? this.musicSource,
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
