import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'music_model.dart';
import 'music_service.dart';

/// Enhanced 3D Column Carousel with Full Image Cards
///
/// Features:
/// - Album art fills entire card
/// - Play button appears on hover
/// - Progress bar shows when playing
/// - Smooth animations and transitions
class MusicCarouselView extends StatefulWidget {
  const MusicCarouselView({super.key});

  @override
  State<MusicCarouselView> createState() => _MusicCarouselViewState();
}

class _MusicCarouselViewState extends State<MusicCarouselView> {
  late PageController _pageController;
  int _currentIndex = 0;
  String? _playingId;
  final Map<String, double> _playProgress = {}; // Track progress for each song
  int? _hoveredIndex;

  static const double _viewportFraction = 0.8;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: _viewportFraction,
    );

    // Simulate progress update
    Future.delayed(const Duration(seconds: 1), _updateProgress);
  }

  void _updateProgress() {
    if (!mounted) return;
    setState(() {
      if (_playingId != null) {
        _playProgress[_playingId!] = ((_playProgress[_playingId] ?? 0.0) + 0.01)
            .clamp(0.0, 1.0);
      }
    });
    Future.delayed(const Duration(milliseconds: 100), _updateProgress);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCardTap(int index, BuildContext context) {
    final musicService = MusicServiceProvider.of(context);
    final musicItems = musicService.musicItems;

    if (index == _currentIndex) {
      // Center card tapped - toggle play mode
      setState(() {
        final item = musicItems[index];
        if (_playingId == item.id) {
          _playingId = null;
        } else {
          _playingId = item.id;
          _playProgress[item.id] = _playProgress[item.id] ?? 0.0;
        }
      });
    } else {
      // Side card tapped - scroll to center
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicService = MusicServiceProvider.of(context);
    final musicItems = musicService.musicItems;

    return SizedBox(
      height: 550,
      child: musicItems.isEmpty
          ? Center(
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
            )
          : PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _hoveredIndex = null;
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

                    return _build3DCard(
                      context,
                      musicItems[index],
                      index,
                      value,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _build3DCard(
    BuildContext context,
    MusicItem item,
    int index,
    double pageOffset,
  ) {
    final bool isCenter = index == _currentIndex && pageOffset.abs() < 0.1;
    final double rotation = pageOffset * 0.5;
    final double scale = isCenter ? 1.0 : 0.8 - (pageOffset.abs() * 0.1);
    final double opacity = isCenter ? 1.0 : 0.6 - (pageOffset.abs() * 0.2);
    final bool isPlaying = _playingId == item.id;
    final double progress = _playProgress[item.id] ?? 0.0;

    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(rotation)
          ..scale(scale.clamp(0.6, 1.0)),
        child: Opacity(
          opacity: opacity.clamp(0.4, 1.0),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: GestureDetector(
              onTap: () => _onCardTap(index, context),
              child: _buildCard(
                context,
                item,
                isCenter,
                isPlaying,
                progress,
                _hoveredIndex == index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    MusicItem item,
    bool isCenter,
    bool isPlaying,
    double progress,
    bool isHovered,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
      width: 300,
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: GalaxyTheme.cyberpunkPink.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: isPlaying ? 10 : 5,
          ),
          BoxShadow(
            color: GalaxyTheme.cyberpunkCyan.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: isPlaying ? 8 : 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Album Art - Full card background
            item.albumArt.isEmpty
                ? _buildPlaceholderImage(item.title)
                : Image.network(
                    item.albumArt,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage(item.title);
                    },
                  ),

            // Dark overlay when playing
            if (isPlaying)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

            // Gradient overlay for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.95),
                    ],
                  ),
                ),
              ),
            ),

            // Play Button - Show on hover or when playing
            if ((isHovered && isCenter) || isPlaying)
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Song Info & Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Bar (when playing)
                    if (isPlaying) ...[
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  GalaxyTheme.cyberpunkPink,
                                  GalaxyTheme.cyberpunkCyan,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: GalaxyTheme.cyberpunkCyan.withOpacity(
                                    0.8,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(progress),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            item.duration,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Artist
                    Text(
                      item.artist,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: Icons.skip_previous,
                          onTap: () {
                            if (_currentIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                        _buildControlButton(
                          icon: item.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item.isFavorite
                              ? GalaxyTheme.cyberpunkPink
                              : null,
                          onTap: () {
                            final musicService = MusicServiceProvider.of(
                              context,
                            );
                            musicService.toggleFavorite(item.id);
                          },
                        ),
                        _buildControlButton(
                          icon: Icons.skip_next,
                          onTap: () {
                            final musicService = MusicServiceProvider.of(
                              context,
                            );
                            if (_currentIndex <
                                musicService.musicItems.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Cyberpunk border glow
            if (isCenter)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isPlaying
                          ? GalaxyTheme.cyberpunkPink
                          : GalaxyTheme.cyberpunkCyan.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 28),
      ),
    );
  }

  String _formatTime(double progress) {
    // Convert progress to time (assuming max duration)
    final seconds = (progress * 300).toInt(); // Assuming 5 min max
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Build placeholder image with song title text
  Widget _buildPlaceholderImage(String title) {
    // Generate a gradient based on title hash
    final hash = title.hashCode.abs();
    final colors = [
      [GalaxyTheme.cosmicViolet, GalaxyTheme.galaxyBlue],
      [GalaxyTheme.nebulaPurple, GalaxyTheme.stardustPink],
      [GalaxyTheme.cyberpunkPink, GalaxyTheme.cyberpunkCyan],
      [GalaxyTheme.auroraGreen, GalaxyTheme.galaxyBlue],
    ];
    final selectedColors = colors[hash % colors.length];

    // Get initials or first characters from title
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
            fontSize: 120,
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
}
