import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../music_carousel/music_service.dart';
import '../music_carousel/music_model.dart';
import '../music_carousel/music_player_service.dart';

/// Listening History Screen - Shows recently played songs as horizontal bars
class ListeningHistoryScreen extends StatelessWidget {
  const ListeningHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicService = MusicServiceProvider.of(context);
    final playerService = MusicPlayerServiceProvider.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: GalaxyTheme.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [GalaxyTheme.cyberpunkPink, GalaxyTheme.cyberpunkCyan],
          ).createShader(bounds),
          child: const Text(
            'Listening History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (musicService.recentlyPlayed.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              tooltip: 'Clear History',
              onPressed: () => _showClearConfirmDialog(context, musicService),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: GalaxyTheme.galaxyGradient),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: musicService,
            builder: (context, _) {
              final recentlyPlayed = musicService.recentlyPlayed;

              if (recentlyPlayed.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recentlyPlayed.length,
                itemBuilder: (context, index) {
                  final song = recentlyPlayed[index];
                  return _buildHistoryItem(
                    context,
                    song,
                    musicService,
                    playerService,
                    index,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: GalaxyTheme.moonGlow.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No listening history yet',
            style: TextStyle(
              fontSize: 18,
              color: GalaxyTheme.moonGlow.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start playing songs to build your history',
            style: TextStyle(
              fontSize: 14,
              color: GalaxyTheme.moonGlow.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    MusicItem song,
    MusicService musicService,
    MusicPlayerService playerService,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            GalaxyTheme.nebulaPurple.withOpacity(0.6),
            GalaxyTheme.cosmicViolet.withOpacity(0.4),
          ],
        ),
        border: Border.all(
          color: GalaxyTheme.moonGlow.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GalaxyTheme.cosmicViolet.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: playerService,
        builder: (context, _) {
          final isPlaying = playerService.currentSongId == song.id && 
                           playerService.isPlaying;
          final isCurrentSong = playerService.currentSongId == song.id;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildThumbnail(song, isCurrentSong),
            title: Text(
              song.title,
              style: TextStyle(
                color: isCurrentSong 
                    ? GalaxyTheme.cyberpunkCyan 
                    : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Favorite Button
                IconButton(
                  icon: Icon(
                    song.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: song.isFavorite
                        ? GalaxyTheme.cyberpunkPink
                        : Colors.white70,
                  ),
                  onPressed: () => musicService.toggleFavorite(song.id),
                ),
                // Play/Pause Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isPlaying
                          ? [GalaxyTheme.cyberpunkPink, GalaxyTheme.cyberpunkCyan]
                          : [GalaxyTheme.cyberpunkCyan, GalaxyTheme.auroraGreen],
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        playerService.pause();
                      } else if (isCurrentSong) {
                        playerService.resume();
                      } else {
                        // Play this song
                        playerService.playSong(song.id, song.musicSource);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(MusicItem song, bool isCurrentSong) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentSong
              ? GalaxyTheme.cyberpunkCyan
              : GalaxyTheme.moonGlow.withOpacity(0.3),
          width: isCurrentSong ? 2 : 1,
        ),
        boxShadow: isCurrentSong
            ? [
                BoxShadow(
                  color: GalaxyTheme.cyberpunkCyan.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _getImageWidget(song),
      ),
    );
  }

  Widget _getImageWidget(MusicItem song) {
    if (song.albumArt.isNotEmpty) {
      if (song.albumArt.startsWith('http')) {
        return Image.network(
          song.albumArt,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } else {
        final file = File(song.albumArt);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: GalaxyTheme.cosmicViolet,
      child: const Icon(
        Icons.music_note,
        color: Colors.white54,
        size: 28,
      ),
    );
  }

  void _showClearConfirmDialog(
    BuildContext context,
    MusicService musicService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GalaxyTheme.deepSpace,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear History',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear your listening history?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GalaxyTheme.cyberpunkPink,
            ),
            onPressed: () {
              musicService.clearRecentlyPlayed();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
