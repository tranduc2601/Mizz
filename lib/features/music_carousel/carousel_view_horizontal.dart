import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/theme.dart';
import 'music_model.dart';
import 'music_service.dart';
import 'music_player_service.dart' show MusicPlayerService, MusicLoopMode;
import 'widgets/carousel_3d.dart';

/// Music Carousel View with 3D Circular Carousel
class MusicCarouselView extends StatefulWidget {
  const MusicCarouselView({super.key});

  @override
  State<MusicCarouselView> createState() => _MusicCarouselViewState();
}

class _MusicCarouselViewState extends State<MusicCarouselView> {
  int _currentIndex = 0;
  late MusicPlayerService _playerService;
  final Map<String, Color> _dominantColors = {};

  @override
  void initState() {
    super.initState();
    _playerService = MusicPlayerService();
    _playerService.addListener(() {
      if (mounted) setState(() {});
    });

    // Set up auto-next callback
    _playerService.onSongComplete = (songId) {
      _playNextSong();
    };
  }

  /// Play the next song automatically
  void _playNextSong() {
    final musicService = MusicServiceProvider.of(context);
    final musicItems = musicService.musicItems;

    if (musicItems.isEmpty) return;

    int nextIndex;
    if (_playerService.loopMode == MusicLoopMode.all) {
      nextIndex = (_currentIndex + 1) % musicItems.length;
    } else {
      nextIndex = _currentIndex + 1;
      if (nextIndex >= musicItems.length) return;
    }

    setState(() {
      _currentIndex = nextIndex;
    });

    final nextSong = musicItems[nextIndex];
    _playerService.playSong(
      nextSong.id,
      nextSong.musicSource,
      localFilePath: nextSong.localFilePath,
    );
  }

  /// Play the previous song
  void _playPreviousSong() {
    final musicService = MusicServiceProvider.of(context);
    final musicItems = musicService.musicItems;

    if (musicItems.isEmpty) return;

    int prevIndex;
    if (_playerService.loopMode == MusicLoopMode.all) {
      prevIndex = (_currentIndex - 1 + musicItems.length) % musicItems.length;
    } else {
      prevIndex = _currentIndex - 1;
      if (prevIndex < 0) return;
    }

    setState(() {
      _currentIndex = prevIndex;
    });

    final prevSong = musicItems[prevIndex];
    _playerService.playSong(
      prevSong.id,
      prevSong.musicSource,
      localFilePath: prevSong.localFilePath,
    );
  }

  Future<void> _extractDominantColor(MusicItem item) async {
    if (_dominantColors.containsKey(item.id)) return;
    if (item.albumArt.isEmpty) {
      _dominantColors[item.id] = GalaxyTheme.cyberpunkCyan;
      return;
    }

    try {
      ImageProvider imageProvider;
      if (item.albumArt.startsWith('http')) {
        imageProvider = NetworkImage(item.albumArt);
      } else {
        imageProvider = FileImage(File(item.albumArt));
      }

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100),
        maximumColorCount: 5,
      );

      if (mounted) {
        setState(() {
          _dominantColors[item.id] =
              paletteGenerator.dominantColor?.color ??
              paletteGenerator.vibrantColor?.color ??
              GalaxyTheme.cyberpunkCyan;
        });
      }
    } catch (e) {
      _dominantColors[item.id] = GalaxyTheme.cyberpunkCyan;
    }
  }

  @override
  void dispose() {
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
          return _buildEmptyState(context);
        }

        // Extract colors for all items
        for (final item in musicItems) {
          _extractDominantColor(item);
        }

        // Ensure current index is valid
        if (_currentIndex >= musicItems.length) {
          _currentIndex = musicItems.length - 1;
        }

        final currentSong = musicItems[_currentIndex];
        final isPlaying =
            _playerService.isPlaying &&
            _playerService.currentSongId == currentSong.id;
        final currentColor =
            _dominantColors[currentSong.id] ?? GalaxyTheme.cyberpunkCyan;

        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // 3D Circular Carousel
              Carousel3D(
                items: musicItems,
                currentIndex: _currentIndex,
                onIndexChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                cardBuilder: (item, isFront, shadowColor) {
                  return MusicCard3D(
                    item: item,
                    isFront: isFront,
                    shadowColor: shadowColor,
                    onMenuTap: isFront
                        ? () => _showCardMenu(context, musicService, item)
                        : null,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      currentSong.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
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

              const SizedBox(height: 16),

              // Speed Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildSpeedButton()],
                ),
              ),

              const SizedBox(height: 8),

              // Progress Bar
              _buildProgressBar(context, currentColor),

              const SizedBox(height: 24),

              // Control Buttons
              _buildControlButtons(
                context,
                musicItems,
                currentSong,
                isPlaying,
                currentColor,
              ),

              const SizedBox(height: 16),

              // Volume Slider
              _buildVolumeSlider(currentColor),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildProgressBar(BuildContext context, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: accentColor,
              thumbColor: accentColor,
            ),
            child: Slider(
              value: _playerService.progress,
              onChanged: (value) {
                final position = _playerService.duration * value;
                _playerService.seek(position);
              },
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GalaxyTheme.moonGlow.withOpacity(0.6),
                  ),
                ),
                Text(
                  _formatDuration(_playerService.duration),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GalaxyTheme.moonGlow.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    List<MusicItem> musicItems,
    MusicItem currentSong,
    bool isPlaying,
    Color accentColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Auto-Next Button
        _buildAutoNextButton(),

        const SizedBox(width: 12),

        // Previous Button
        _buildControlButton(
          icon: Icons.skip_previous,
          onPressed: () => _playPreviousSong(),
        ),

        const SizedBox(width: 20),

        // Play/Pause Button
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.6)],
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.5),
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
                  await _playerService.playSong(
                    currentSong.id,
                    currentSong.musicSource,
                    localFilePath: currentSong.localFilePath,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: GalaxyTheme.stardustPink,
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
          onPressed: () => _playNextSong(),
        ),

        const SizedBox(width: 12),

        // Loop Button
        _buildLoopButton(),
      ],
    );
  }

  Widget _buildAutoNextButton() {
    final isActive = _playerService.autoNext;

    return GestureDetector(
      onTap: () {
        _playerService.toggleAutoNext();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _playerService.autoNext
                  ? 'Auto-play next: ON'
                  : 'Auto-play next: OFF',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: _playerService.autoNext
                ? GalaxyTheme.auroraGreen
                : GalaxyTheme.moonGlow.withOpacity(0.7),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? GalaxyTheme.auroraGreen
                : GalaxyTheme.moonGlow.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.playlist_play,
          color: isActive
              ? GalaxyTheme.auroraGreen
              : GalaxyTheme.moonGlow.withOpacity(0.5),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Icon(
            _playerService.volume == 0
                ? Icons.volume_off
                : _playerService.volume < 0.5
                ? Icons.volume_down
                : Icons.volume_up,
            color: GalaxyTheme.moonGlow.withOpacity(0.7),
            size: 20,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: accentColor,
                thumbColor: accentColor,
              ),
              child: Slider(
                value: _playerService.volume,
                onChanged: (value) {
                  _playerService.setVolume(value);
                },
                inactiveColor: GalaxyTheme.moonGlow.withOpacity(0.2),
              ),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              '${(_playerService.volume * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: GalaxyTheme.moonGlow.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    return PopupMenuButton<double>(
      onSelected: (speed) {
        _playerService.setPlaybackSpeed(speed);
      },
      color: GalaxyTheme.deepSpace.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: GalaxyTheme.moonGlow.withOpacity(0.3)),
      ),
      itemBuilder: (context) => speeds.map((speed) {
        final isSelected = _playerService.playbackSpeed == speed;
        return PopupMenuItem<double>(
          value: speed,
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.check, color: GalaxyTheme.cyberpunkCyan, size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(
                '${speed}x',
                style: TextStyle(
                  color: isSelected
                      ? GalaxyTheme.cyberpunkCyan
                      : GalaxyTheme.moonGlow,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: GalaxyTheme.moonGlow.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              color: GalaxyTheme.moonGlow.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${_playerService.playbackSpeed}x',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: GalaxyTheme.moonGlow.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoopButton() {
    IconData icon;
    Color color;

    switch (_playerService.loopMode) {
      case MusicLoopMode.none:
        icon = Icons.repeat;
        color = GalaxyTheme.moonGlow.withOpacity(0.5);
        break;
      case MusicLoopMode.one:
        icon = Icons.repeat_one;
        color = GalaxyTheme.cyberpunkCyan;
        break;
      case MusicLoopMode.all:
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
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
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

  void _showCardMenu(
    BuildContext context,
    MusicService musicService,
    MusicItem item,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GalaxyTheme.deepSpace.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GalaxyTheme.moonGlow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.playlist_add, color: GalaxyTheme.moonGlow),
                title: Text(
                  'Add to Playlist',
                  style: TextStyle(color: GalaxyTheme.moonGlow),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
                },
              ),
              ListTile(
                leading: Icon(
                  item.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: item.isFavorite
                      ? GalaxyTheme.cyberpunkPink
                      : GalaxyTheme.moonGlow,
                ),
                title: Text(
                  item.isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  style: TextStyle(color: GalaxyTheme.moonGlow),
                ),
                onTap: () {
                  musicService.toggleFavorite(item.id);
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: Icon(Icons.edit, color: GalaxyTheme.auroraGreen),
                title: Text(
                  'Edit Song',
                  style: TextStyle(color: GalaxyTheme.moonGlow),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, musicService, item);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: GalaxyTheme.stardustPink),
                title: Text(
                  'Delete',
                  style: TextStyle(color: GalaxyTheme.stardustPink),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, musicService, item);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
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
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    // Album Art Preview
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() {
                            newImagePath = image.path;
                          });
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: GalaxyTheme.cyberpunkCyan.withOpacity(0.5),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (newImagePath != null &&
                                  newImagePath!.isNotEmpty)
                                newImagePath!.startsWith('http')
                                    ? Image.network(
                                        newImagePath!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(newImagePath!),
                                        fit: BoxFit.cover,
                                      )
                              else
                                Container(
                                  color: GalaxyTheme.deepSpace,
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                  ),
                                ),
                              Container(
                                color: Colors.black38,
                                child: const Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      titleController,
                      'Song Name',
                      Icons.music_note,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(artistController, 'Artist', Icons.person),
                  ],
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
                    musicService.updateSong(
                      item.id,
                      title: titleController.text.trim(),
                      artist: artistController.text.trim(),
                      albumArt: newImagePath,
                    );
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GalaxyTheme.cyberpunkCyan,
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

  void _showDeleteDialog(
    BuildContext context,
    MusicService musicService,
    MusicItem item,
  ) {
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
            'Are you sure you want to delete "${item.title}"?',
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
                musicService.removeSong(item.id);
                Navigator.pop(dialogContext);
                if (_currentIndex >= musicService.musicItems.length) {
                  _currentIndex = musicService.musicItems.length - 1;
                  if (_currentIndex < 0) _currentIndex = 0;
                }
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
