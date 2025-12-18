import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../music_carousel/music_model.dart';
import '../music_carousel/music_service.dart';
import '../music_carousel/music_player_service.dart';
import '../playlist/playlist_service.dart';
import '../playlist/playlist_model.dart';
import '../../core/theme.dart';

/// Song List Screen - Shows songs in bar format
/// Used for My Library, Playlists, Favorites
class SongListScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<MusicItem> Function(MusicService) songsSelector;
  final bool showFavoritesOnly;

  const SongListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.songsSelector,
    this.showFavoritesOnly = false,
  });

  /// Factory for My Library
  factory SongListScreen.library() {
    return SongListScreen(
      title: 'My Library',
      icon: Icons.library_music,
      songsSelector: (service) => service.musicItems,
    );
  }

  /// Factory for Favorites
  factory SongListScreen.favorites() {
    return SongListScreen(
      title: 'Favorites',
      icon: Icons.favorite,
      songsSelector: (service) =>
          service.musicItems.where((s) => s.isFavorite).toList(),
      showFavoritesOnly: true,
    );
  }

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  @override
  Widget build(BuildContext context) {
    final musicService = MusicServiceProvider.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(widget.icon, color: GalaxyTheme.cyberpunkPink),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: const TextStyle(
                color: GalaxyTheme.moonGlow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GalaxyTheme.moonGlow),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: GalaxyTheme.galaxyGradient),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: musicService,
            builder: (context, _) {
              final songs = widget.songsSelector(musicService);

              if (songs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  return SongBarItem(
                    song: songs[index],
                    musicService: musicService,
                    onTap: () => _playSong(songs[index]),
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
            widget.showFavoritesOnly ? Icons.favorite_border : Icons.music_off,
            size: 80,
            color: GalaxyTheme.moonGlow.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            widget.showFavoritesOnly
                ? 'No favorites yet'
                : 'No songs in library',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: GalaxyTheme.moonGlow.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.showFavoritesOnly
                ? 'Heart a song to add it here'
                : 'Add songs from the main screen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GalaxyTheme.moonGlow.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _playSong(MusicItem song) {
    final playerService = MusicPlayerServiceProvider.of(context);
    playerService.playSong(
      song.id,
      song.musicSource,
      localFilePath: song.localFilePath,
    );
  }
}

/// A single song bar item
class SongBarItem extends StatefulWidget {
  final MusicItem song;
  final MusicService musicService;
  final VoidCallback onTap;

  const SongBarItem({
    super.key,
    required this.song,
    required this.musicService,
    required this.onTap,
  });

  @override
  State<SongBarItem> createState() => _SongBarItemState();
}

class _SongBarItemState extends State<SongBarItem> {
  Color _dominantColor = GalaxyTheme.cyberpunkCyan;

  @override
  void initState() {
    super.initState();
    _extractColor();
  }

  Future<void> _extractColor() async {
    if (widget.song.albumArt.isEmpty) return;

    try {
      ImageProvider imageProvider;
      if (widget.song.albumArt.startsWith('http')) {
        imageProvider = NetworkImage(widget.song.albumArt);
      } else {
        imageProvider = FileImage(File(widget.song.albumArt));
      }

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(50, 50),
        maximumColorCount: 3,
      );

      if (mounted) {
        setState(() {
          _dominantColor =
              paletteGenerator.dominantColor?.color ??
              paletteGenerator.vibrantColor?.color ??
              GalaxyTheme.cyberpunkCyan;
        });
      }
    } catch (e) {
      // Keep default color
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = MusicPlayerServiceProvider.of(context);
    final isPlaying =
        playerService.isPlaying &&
        playerService.currentSongId == widget.song.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            GalaxyTheme.deepSpace.withOpacity(0.8),
            _dominantColor.withOpacity(0.15),
          ],
        ),
        border: Border.all(
          color: isPlaying
              ? _dominantColor.withOpacity(0.8)
              : GalaxyTheme.moonGlow.withOpacity(0.2),
          width: isPlaying ? 2 : 1,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: _dominantColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildAlbumArt(),
        title: Text(
          widget.song.title,
          style: TextStyle(
            color: GalaxyTheme.moonGlow,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          widget.song.artist,
          style: TextStyle(
            color: GalaxyTheme.moonGlow.withOpacity(0.6),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/Pause button
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: _dominantColor,
                size: 40,
              ),
              onPressed: () {
                if (isPlaying) {
                  playerService.pause();
                } else {
                  widget.onTap();
                }
              },
            ),
            // Menu button
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: GalaxyTheme.moonGlow.withOpacity(0.7),
              ),
              color: GalaxyTheme.deepSpace.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
              ),
              onSelected: (value) => _handleMenuAction(value, context),
              itemBuilder: (context) => [
                _buildMenuItem(
                  'edit',
                  Icons.edit,
                  'Edit Song',
                  GalaxyTheme.auroraGreen,
                ),
                _buildMenuItem(
                  'favorite',
                  widget.song.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  widget.song.isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  GalaxyTheme.cyberpunkPink,
                ),
                const PopupMenuDivider(),
                _buildMenuItem(
                  'delete',
                  Icons.delete,
                  'Delete',
                  GalaxyTheme.stardustPink,
                ),
              ],
            ),
          ],
        ),
        onTap: widget.onTap,
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _dominantColor.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.song.albumArt.isEmpty
            ? _buildPlaceholder()
            : (widget.song.albumArt.startsWith('http')
                  ? Image.network(
                      widget.song.albumArt,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : Image.file(
                      File(widget.song.albumArt),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_dominantColor.withOpacity(0.8), GalaxyTheme.deepSpace],
        ),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 28),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: GalaxyTheme.moonGlow)),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'favorite':
        widget.musicService.toggleFavorite(widget.song.id);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: widget.song.title);
    final artistController = TextEditingController(text: widget.song.artist);
    final durationController = TextEditingController(
      text: widget.song.duration,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
          ),
          title: const Text(
            'Edit Song',
            style: TextStyle(color: GalaxyTheme.moonGlow),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'Song Name', Icons.music_note),
                const SizedBox(height: 12),
                _buildTextField(artistController, 'Artist', Icons.person),
                const SizedBox(height: 12),
                _buildTextField(
                  durationController,
                  'Duration (mm:ss)',
                  Icons.timer,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.musicService.updateSong(
                  widget.song.id,
                  title: titleController.text.trim(),
                  artist: artistController.text.trim(),
                );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GalaxyTheme.cyberpunkCyan,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: GalaxyTheme.moonGlow.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GalaxyTheme.cyberpunkCyan),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
          ),
          title: const Text(
            'Delete Song',
            style: TextStyle(color: GalaxyTheme.moonGlow),
          ),
          content: Text(
            'Are you sure you want to delete "${widget.song.title}"?',
            style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.musicService.removeSong(widget.song.id);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GalaxyTheme.stardustPink,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

/// Playlists screen with playlist management
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  @override
  Widget build(BuildContext context) {
    final playlistService = PlaylistServiceProvider.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.playlist_play, color: GalaxyTheme.auroraGreen),
            SizedBox(width: 12),
            Text(
              'Playlists',
              style: TextStyle(
                color: GalaxyTheme.moonGlow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GalaxyTheme.moonGlow),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: GalaxyTheme.auroraGreen),
            onPressed: () =>
                _showCreatePlaylistDialog(context, playlistService),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: GalaxyTheme.galaxyGradient),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: playlistService,
            builder: (context, _) {
              final playlists = playlistService.playlists;

              if (playlists.isEmpty) {
                return _buildEmptyState(context, playlistService);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  return _PlaylistTile(
                    playlist: playlists[index],
                    playlistService: playlistService,
                    onTap: () => _openPlaylist(context, playlists[index]),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    PlaylistService playlistService,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: 80,
            color: GalaxyTheme.moonGlow.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No playlists yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: GalaxyTheme.moonGlow.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a playlist to organize your music',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GalaxyTheme.moonGlow.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                _showCreatePlaylistDialog(context, playlistService),
            icon: const Icon(Icons.add),
            label: const Text('Create Playlist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GalaxyTheme.auroraGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    final musicService = MusicServiceProvider.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongListScreen(
          title: playlist.name,
          icon: Icons.playlist_play,
          songsSelector: (service) => service.musicItems
              .where((song) => playlist.songIds.contains(song.id))
              .toList(),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistService playlistService,
  ) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
          ),
          title: const Text(
            'Create Playlist',
            style: TextStyle(color: GalaxyTheme.moonGlow),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Playlist Name',
              labelStyle: TextStyle(
                color: GalaxyTheme.moonGlow.withOpacity(0.7),
              ),
              prefixIcon: Icon(
                Icons.playlist_add,
                color: GalaxyTheme.moonGlow.withOpacity(0.7),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: GalaxyTheme.moonGlow.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GalaxyTheme.auroraGreen),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  playlistService.createPlaylist(
                    name: nameController.text.trim(),
                  );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Playlist "${nameController.text}" created!',
                      ),
                      backgroundColor: GalaxyTheme.auroraGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GalaxyTheme.auroraGreen,
              ),
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Single playlist tile widget
class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final PlaylistService playlistService;
  final VoidCallback onTap;

  const _PlaylistTile({
    required this.playlist,
    required this.playlistService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            GalaxyTheme.deepSpace.withOpacity(0.8),
            GalaxyTheme.cosmicViolet.withOpacity(0.15),
          ],
        ),
        border: Border.all(
          color: GalaxyTheme.moonGlow.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                GalaxyTheme.cosmicViolet.withOpacity(0.5),
                GalaxyTheme.galaxyBlue.withOpacity(0.5),
              ],
            ),
          ),
          child: const Icon(
            Icons.playlist_play,
            color: GalaxyTheme.moonGlow,
            size: 28,
          ),
        ),
        title: Text(
          playlist.name,
          style: const TextStyle(
            color: GalaxyTheme.moonGlow,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${playlist.songCount} songs',
          style: TextStyle(
            color: GalaxyTheme.moonGlow.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: GalaxyTheme.moonGlow.withOpacity(0.7),
          ),
          color: GalaxyTheme.deepSpace.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
          ),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'add_songs',
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: GalaxyTheme.cyberpunkCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Songs',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, color: GalaxyTheme.auroraGreen, size: 20),
                  const SizedBox(width: 12),
                  const Text('Rename', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: GalaxyTheme.stardustPink, size: 20),
                  const SizedBox(width: 12),
                  const Text('Delete', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'add_songs':
        _showAddSongsDialog(context);
        break;
      case 'rename':
        _showRenameDialog(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showAddSongsDialog(BuildContext context) {
    final musicService = MusicServiceProvider.of(context);
    final allSongs = musicService.musicItems;
    final selectedSongIds = <String>{...playlist.songIds};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
              ),
              title: Row(
                children: [
                  Icon(Icons.playlist_add, color: GalaxyTheme.cyberpunkCyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Songs to ${playlist.name}',
                      style: const TextStyle(color: GalaxyTheme.moonGlow),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: allSongs.isEmpty
                    ? Center(
                        child: Text(
                          'No songs available',
                          style: TextStyle(
                            color: GalaxyTheme.moonGlow.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allSongs.length,
                        itemBuilder: (context, index) {
                          final song = allSongs[index];
                          final isSelected = selectedSongIds.contains(song.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedSongIds.add(song.id);
                                } else {
                                  selectedSongIds.remove(song.id);
                                }
                              });
                            },
                            title: Text(
                              song.title,
                              style: const TextStyle(
                                color: GalaxyTheme.moonGlow,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              style: TextStyle(
                                color: GalaxyTheme.moonGlow.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            activeColor: GalaxyTheme.auroraGreen,
                            checkColor: Colors.black,
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: GalaxyTheme.moonGlow.withOpacity(0.7),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add new songs that weren't in the playlist
                    for (final songId in selectedSongIds) {
                      if (!playlist.songIds.contains(songId)) {
                        playlistService.addSongToPlaylist(playlist.id, songId);
                      }
                    }
                    // Remove songs that were unchecked
                    for (final songId in playlist.songIds) {
                      if (!selectedSongIds.contains(songId)) {
                        playlistService.removeSongFromPlaylist(
                          playlist.id,
                          songId,
                        );
                      }
                    }
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playlist "${playlist.name}" updated'),
                        backgroundColor: GalaxyTheme.auroraGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GalaxyTheme.auroraGreen,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context) {
    final nameController = TextEditingController(text: playlist.name);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
          ),
          title: const Text(
            'Rename Playlist',
            style: TextStyle(color: GalaxyTheme.moonGlow),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Playlist Name',
              labelStyle: TextStyle(
                color: GalaxyTheme.moonGlow.withOpacity(0.7),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: GalaxyTheme.moonGlow.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GalaxyTheme.auroraGreen),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  playlistService.renamePlaylist(
                    playlist.id,
                    nameController.text.trim(),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GalaxyTheme.auroraGreen,
              ),
              child: const Text(
                'Rename',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
          ),
          title: const Text(
            'Delete Playlist',
            style: TextStyle(color: GalaxyTheme.moonGlow),
          ),
          content: Text(
            'Are you sure you want to delete "${playlist.name}"?',
            style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                playlistService.deletePlaylist(playlist.id);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "${playlist.name}" deleted'),
                    backgroundColor: GalaxyTheme.stardustPink,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GalaxyTheme.stardustPink,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
