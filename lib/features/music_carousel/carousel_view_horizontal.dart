import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import 'music_model.dart';
import 'music_service.dart';
import 'music_player_service.dart' show MusicPlayerService, LoopMode;
import 'dart:io';

/// New Horizontal Music Carousel with External Controls
class MusicCarouselView extends StatefulWidget {
  const MusicCarouselView({super.key});

  @override
  State<MusicCarouselView> createState() => _MusicCarouselViewState();
}

class _MusicCarouselViewState extends State<MusicCarouselView> {
  late PageController _pageController;
  int _currentIndex = 0;
  late MusicPlayerService _playerService;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _playerService = MusicPlayerService();
    _playerService.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicService = MusicServiceProvider.of(context);

    return ListenableBuilder(
      listenable: musicService,
      builder: (context, child) {
        final musicItems = musicService.musicItems;

        if (musicItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 100,
                  color: GalaxyTheme.moonGlow.withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                Text(
                  'No songs yet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first song from the menu',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GalaxyTheme.moonGlow.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        // Ensure current index is valid
        if (_currentIndex >= musicItems.length) {
          _currentIndex = musicItems.length - 1;
        }

        final currentSong = musicItems[_currentIndex];
        final isPlaying =
            _playerService.isPlaying &&
            _playerService.currentSongId == currentSong.id;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Horizontal Card Carousel
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: musicItems.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 0.0;
                      if (_pageController.position.haveDimensions) {
                        value = (_pageController.page ?? 0.0) - index;
                      }

                      final bool isCenter = index == _currentIndex;
                      final double scale =
                          1.0 - (value.abs() * 0.3).clamp(0.0, 0.3);
                      final double opacity =
                          1.0 - (value.abs() * 0.5).clamp(0.0, 0.5);

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: _buildHorizontalCard(
                            context,
                            musicItems[index],
                            isCenter,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Song Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    currentSong.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSong.artist,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: GalaxyTheme.moonGlow.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: _playerService.progress,
                      onChanged: (value) {
                        final position = _playerService.duration * value;
                        _playerService.seek(position);
                      },
                      activeColor: GalaxyTheme.cyberpunkCyan,
                      inactiveColor: GalaxyTheme.moonGlow.withOpacity(0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_playerService.position),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: GalaxyTheme.moonGlow.withOpacity(0.6),
                              ),
                        ),
                        Text(
                          _formatDuration(_playerService.duration),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: GalaxyTheme.moonGlow.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous Button
                _buildControlButton(
                  icon: Icons.skip_previous,
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),

                const SizedBox(width: 20),

                // Play/Pause Button
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        GalaxyTheme.cyberpunkPink,
                        GalaxyTheme.cyberpunkCyan,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GalaxyTheme.cyberpunkPink.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        if (isPlaying) {
                          await _playerService.pause();
                        } else {
                          // Play the current song
                          await _playerService.playSong(
                            currentSong.id,
                            currentSong.musicSource,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error playing song: ${e.toString()}',
                              ),
                              backgroundColor: GalaxyTheme.stardustPink,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),

                const SizedBox(width: 20),

                // Next Button
                _buildControlButton(
                  icon: Icons.skip_next,
                  onPressed: _currentIndex < musicItems.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),

                const SizedBox(width: 12),

                // Loop Button
                _buildLoopButton(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoopButton() {
    IconData icon;
    Color color;
    
    switch (_playerService.loopMode) {
      case LoopMode.none:
        icon = Icons.repeat;
        color = GalaxyTheme.moonGlow.withOpacity(0.5);
        break;
      case LoopMode.one:
        icon = Icons.repeat_one;
        color = GalaxyTheme.cyberpunkCyan;
        break;
      case LoopMode.all:
        icon = Icons.repeat;
        color = GalaxyTheme.cyberpunkPink;
        break;
    }
    
    return GestureDetector(
      onTap: () {
        _playerService.toggleLoopMode();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    MusicItem item,
    bool isCenter,
  ) {
    final musicService = MusicServiceProvider.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: GalaxyTheme.cyberpunkCyan.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: isCenter ? 5 : 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Album Art or Placeholder
            item.albumArt.isEmpty
                ? _buildPlaceholderImage(item.title)
                : (item.albumArt.startsWith('http')
                      ? Image.network(
                          item.albumArt,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(item.title);
                          },
                        )
                      : Image.file(
                          File(item.albumArt),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(item.title);
                          },
                        )),

            // Three-dot menu button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: GalaxyTheme.deepSpace.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: GalaxyTheme.moonGlow.withOpacity(0.3),
                    ),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'playlist':
                        // TODO: Add to playlist
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add to playlist - Coming soon!'),
                          ),
                        );
                        break;
                      case 'favorite':
                        musicService.toggleFavorite(item.id);
                        break;
                      case 'edit':
                        _showEditDialog(context, musicService, item);
                        break;
                      case 'delete':
                        _showDeleteDialog(context, musicService, item);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'playlist',
                      child: Row(
                        children: [
                          Icon(Icons.playlist_add, color: GalaxyTheme.moonGlow),
                          const SizedBox(width: 12),
                          Text(
                            'Add to Playlist',
                            style: TextStyle(color: GalaxyTheme.moonGlow),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            item.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: item.isFavorite
                                ? GalaxyTheme.cyberpunkPink
                                : GalaxyTheme.moonGlow,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.isFavorite
                                ? 'Remove from Favorites'
                                : 'Add to Favorites',
                            style: TextStyle(color: GalaxyTheme.moonGlow),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: GalaxyTheme.auroraGreen),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Song',
                            style: TextStyle(color: GalaxyTheme.moonGlow),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: GalaxyTheme.stardustPink),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: GalaxyTheme.stardustPink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    MusicService musicService,
    MusicItem item,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
          ),
          title: Text(
            'Delete Song',
            style: TextStyle(color: GalaxyTheme.moonGlow),
          ),
          content: Text(
            'Are you sure you want to delete "${item.title}"?',
            style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: GalaxyTheme.moonGlow),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                musicService.removeSong(item.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${item.title}"'),
                    backgroundColor: GalaxyTheme.stardustPink,
                  ),
                );
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

  void _showEditDialog(
    BuildContext context,
    MusicService musicService,
    MusicItem item,
  ) {
    final titleController = TextEditingController(text: item.title);
    final artistController = TextEditingController(text: item.artist);
    String? newImagePath = item.albumArt;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
              ),
              title: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [GalaxyTheme.cyberpunkPink, GalaxyTheme.cyberpunkCyan],
                ).createShader(bounds),
                child: const Text(
                  'Edit Song',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Album Art Preview
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            newImagePath = image.path;
                          });
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: GalaxyTheme.cyberpunkCyan.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (newImagePath != null && newImagePath!.isNotEmpty)
                                newImagePath!.startsWith('http')
                                    ? Image.network(
                                        newImagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(item.title),
                                      )
                                    : Image.file(
                                        File(newImagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(item.title),
                                      )
                              else
                                _buildPlaceholderImage(item.title),
                              Container(
                                color: Colors.black38,
                                child: const Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change image',
                      style: TextStyle(
                        color: GalaxyTheme.moonGlow.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title Field
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Song Name',
                        labelStyle: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: GalaxyTheme.cyberpunkCyan),
                        ),
                        prefixIcon: Icon(Icons.music_note, color: GalaxyTheme.moonGlow.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Artist Field
                    TextField(
                      controller: artistController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Artist',
                        labelStyle: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: GalaxyTheme.cyberpunkCyan),
                        ),
                        prefixIcon: Icon(Icons.person, color: GalaxyTheme.moonGlow.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: GalaxyTheme.moonGlow.withOpacity(0.7)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Song name cannot be empty'),
                          backgroundColor: GalaxyTheme.stardustPink,
                        ),
                      );
                      return;
                    }
                    
                    musicService.updateSong(
                      item.id,
                      title: titleController.text.trim(),
                      artist: artistController.text.trim().isEmpty
                          ? 'Unknown Artist'
                          : artistController.text.trim(),
                      albumArt: newImagePath,
                    );
                    
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated "${titleController.text}"'),
                        backgroundColor: GalaxyTheme.auroraGreen,
                      ),
                    );
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
      },
    );
  }

  Widget _buildPlaceholderImage(String title) {
    final hash = title.hashCode.abs();
    final colors = [
      [GalaxyTheme.cosmicViolet, GalaxyTheme.galaxyBlue],
      [GalaxyTheme.nebulaPurple, GalaxyTheme.stardustPink],
      [GalaxyTheme.cyberpunkPink, GalaxyTheme.cyberpunkCyan],
      [GalaxyTheme.auroraGreen, GalaxyTheme.galaxyBlue],
    ];
    final selectedColors = colors[hash % colors.length];

    final words = title.trim().split(' ');
    String displayText;
    if (words.length >= 2) {
      displayText = words[0][0].toUpperCase() + words[1][0].toUpperCase();
    } else if (title.length >= 2) {
      displayText = title.substring(0, 2).toUpperCase();
    } else {
      displayText = title.toUpperCase();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selectedColors,
        ),
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 80,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(4, 4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GalaxyTheme.deepSpace.withOpacity(0.5),
        border: Border.all(
          color: color ?? GalaxyTheme.moonGlow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? GalaxyTheme.moonGlow, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
