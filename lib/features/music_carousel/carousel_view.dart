import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'music_model.dart';

/// 3D Column Carousel Widget
///
/// Creates a vertical 3D carousel that rotates around an invisible central column
/// Features:
/// - Center card: Full opacity, scale 1.0
/// - Side cards: Reduced opacity (0.6), scale 0.8, rotated inwards
/// - Swipe to rotate
/// - Click side card to bring to center
/// - Click center card to activate play mode
class MusicCarouselView extends StatefulWidget {
  const MusicCarouselView({super.key});

  @override
  State<MusicCarouselView> createState() => _MusicCarouselViewState();
}

class _MusicCarouselViewState extends State<MusicCarouselView> {
  late PageController _pageController;
  late List<MusicItem> _musicItems;
  int _currentIndex = 0;
  String? _playingId;

  // 3D effect parameters
  static const double _viewportFraction = 0.8;

  @override
  void initState() {
    super.initState();
    _musicItems = MusicData.getSampleMusic();
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: _viewportFraction,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCardTap(int index) {
    if (index == _currentIndex) {
      // Center card tapped - toggle play mode
      setState(() {
        if (_playingId == _musicItems[index].id) {
          _playingId = null; // Stop playing
        } else {
          _playingId = _musicItems[index].id; // Start playing
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
    return SizedBox(
      height: 500,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: _musicItems.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 0.0;

              if (_pageController.position.haveDimensions) {
                value = (_pageController.page ?? 0.0) - index;
              }

              return _build3DCard(context, _musicItems[index], index, value);
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
    // Calculate 3D transformation values
    final bool isCenter = index == _currentIndex && pageOffset.abs() < 0.1;
    final double rotation = pageOffset * 0.5; // Rotation angle
    final double scale = isCenter ? 1.0 : 0.8 - (pageOffset.abs() * 0.1);
    final double opacity = isCenter ? 1.0 : 0.6 - (pageOffset.abs() * 0.2);
    final bool isPlaying = _playingId == item.id;

    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateY(rotation) // Rotate around Y-axis (column effect)
          ..scale(scale.clamp(0.6, 1.0)),
        child: Opacity(
          opacity: opacity.clamp(0.4, 1.0),
          child: GestureDetector(
            onTap: () => _onCardTap(index),
            child: _buildCard(context, item, isCenter, isPlaying),
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
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
      width: 280,
      decoration: GalaxyTheme.glassContainer(borderRadius: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GalaxyTheme.cosmicViolet.withOpacity(0.3),
                      GalaxyTheme.nebulaPurple.withOpacity(0.2),
                      GalaxyTheme.galaxyBlue.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),

            // Album Art Section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      GalaxyTheme.stardustPink.withOpacity(0.3),
                      GalaxyTheme.cosmicViolet.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Album Art Emoji
                    Text(item.albumArt, style: const TextStyle(fontSize: 120)),

                    // Play Button Overlay (when playing)
                    if (isPlaying)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: const Icon(
                          Icons.pause_circle_filled,
                          size: 60,
                          color: GalaxyTheme.auroraGreen,
                        ),
                      )
                    else if (isCenter)
                      // Hint: Show play icon on hover (center card)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Icon(
                          Icons.play_circle_filled,
                          size: 60,
                          color: GalaxyTheme.moonGlow.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Song Info Section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      GalaxyTheme.deepSpace.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Artist and Duration Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.artist,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: GalaxyTheme.moonGlow.withOpacity(0.7),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GalaxyTheme.cosmicViolet.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.duration,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: GalaxyTheme.moonGlow,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
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
                        _buildActionButton(
                          icon: item.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item.isFavorite
                              ? GalaxyTheme.stardustPink
                              : null,
                          onTap: () {
                            // Toggle favorite
                            setState(() {
                              final index = _musicItems.indexOf(item);
                              _musicItems[index] = item.copyWith(
                                isFavorite: !item.isFavorite,
                              );
                            });
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.skip_next,
                          onTap: () {
                            if (_currentIndex < _musicItems.length - 1) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color ?? GalaxyTheme.moonGlow, size: 28),
      ),
    );
  }
}
