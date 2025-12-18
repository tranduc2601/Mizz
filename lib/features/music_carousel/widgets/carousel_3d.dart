import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import '../music_model.dart';
import '../../../core/theme.dart';

/// 3D Circular Carousel with 5 visible cards
/// Cards rotate in a circle: behind - left - front - right - behind
class Carousel3D extends StatefulWidget {
  final List<MusicItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget Function(MusicItem item, bool isFront, Color shadowColor)
  cardBuilder;

  const Carousel3D({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.cardBuilder,
  });

  @override
  State<Carousel3D> createState() => _Carousel3DState();
}

class _Carousel3DState extends State<Carousel3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _currentAngle = 0;
  double _targetAngle = 0;
  double _dragStartAngle = 0;
  final Map<String, Color> _dominantColors = {};

  // Number of visible cards (max 5)
  int get visibleCount => math.min(5, widget.items.length);

  // Angle between each card in the circle
  double get angleStep =>
      widget.items.isEmpty ? 0 : (2 * math.pi) / widget.items.length;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animation.addListener(() {
      setState(() {
        _currentAngle =
            _targetAngle -
            (_targetAngle - _currentAngle) * (1 - _animation.value);
      });
    });

    _extractDominantColors();
  }

  @override
  void didUpdateWidget(Carousel3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateToIndex(widget.currentIndex);
    }
    if (oldWidget.items != widget.items) {
      _extractDominantColors();
    }
  }

  Future<void> _extractDominantColors() async {
    for (final item in widget.items) {
      if (_dominantColors.containsKey(item.id)) continue;
      if (item.albumArt.isEmpty) {
        _dominantColors[item.id] = GalaxyTheme.cyberpunkCyan;
        continue;
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
  }

  void _animateToIndex(int index) {
    if (widget.items.isEmpty) return;

    final targetAngle = -index * angleStep;
    final diff = targetAngle - _currentAngle;

    // Normalize to shortest path
    double normalizedDiff = diff;
    if (diff > math.pi) {
      normalizedDiff = diff - 2 * math.pi;
    } else if (diff < -math.pi) {
      normalizedDiff = diff + 2 * math.pi;
    }

    _targetAngle = _currentAngle + normalizedDiff;
    _animationController.forward(from: 0);
  }

  void _handleDragStart(DragStartDetails details) {
    _animationController.stop();
    _dragStartAngle = _currentAngle;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.items.isEmpty) return;

    // Convert horizontal drag to angle change
    // Positive because dragging right should rotate right (show previous)
    // Dragging left should rotate left (show next)
    final delta = details.delta.dx / 150.0;
    setState(() {
      _currentAngle += delta;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.items.isEmpty) return;

    // Snap to nearest card
    final nearestIndex =
        (-_currentAngle / angleStep).round() % widget.items.length;
    final normalizedIndex = nearestIndex < 0
        ? nearestIndex + widget.items.length
        : nearestIndex;

    // Animate to snap position
    _targetAngle = -normalizedIndex * angleStep;

    // Normalize to prevent large angle jumps
    while ((_targetAngle - _currentAngle).abs() > math.pi) {
      if (_targetAngle > _currentAngle) {
        _targetAngle -= 2 * math.pi;
      } else {
        _targetAngle += 2 * math.pi;
      }
    }

    _animationController.forward(from: 0);

    if (normalizedIndex != widget.currentIndex) {
      widget.onIndexChanged(normalizedIndex);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: SizedBox(
        height:
            280, // Increased height for new card geometry (center card Y: -14 to 0)
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centerX = constraints.maxWidth / 2;
            // Position cards in negative Y space - center card bottom at Y=0 (bottom of container)
            final centerY = 240.0; // Cards positioned lower
            final radius = constraints.maxWidth * 0.35;

            return Stack(
              clipBehavior: Clip.none,
              children: _buildCards(centerX, centerY, radius),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildCards(double centerX, double centerY, double radius) {
    final cards = <_CardData>[];

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final cardAngle = _currentAngle + i * angleStep;

      // Normalize angle to 0-2π
      final normalizedAngle = cardAngle % (2 * math.pi);
      final adjustedAngle = normalizedAngle < 0
          ? normalizedAngle + 2 * math.pi
          : normalizedAngle;

      // X position: sin for left-right movement
      final xOffset = math.sin(cardAngle) * radius;

      // Z depth: cos for front-back (1 = front, -1 = back)
      final zDepth = math.cos(cardAngle);

      // NEW GEOMETRY:
      // All cards positioned in "negative Y space" (visually lower)
      // Center card: Y from -14 to 0 (height = 14 units, positioned at bottom)
      // Side cards: Y from -12 to -2 (height = 10 units, 2-unit gap from center)
      //
      // Height ratio: side = 10/14 = 0.714 of center
      // Y offset: side cards are shifted UP by 2 units relative to center

      // Scale determines card height
      // Front card (zDepth > 0.9): scale = 1.0 (14 units)
      // Side cards (zDepth ~ 0): scale = 0.714 (10 units)
      final double scale;
      final double yOffset;

      if (zDepth > 0.9) {
        // CENTER CARD: Full size, positioned lower (bottom at Y=0)
        scale = 1.0;
        yOffset = 0.0; // No offset - this is the reference
      } else if (zDepth > 0.3) {
        // Transition from front to side
        final t = (zDepth - 0.3) / 0.6; // 0 to 1
        scale = 0.714 + t * 0.286;
        // Y offset transitions from -20 (side) to 0 (front)
        yOffset = -20.0 * (1 - t);
      } else if (zDepth > -0.3) {
        // SIDE CARDS: Smaller and shifted UP (higher position = more negative Y offset)
        // 2-unit gap from center at top and bottom
        scale = 0.714;
        yOffset =
            -20.0; // Side cards positioned higher (2 unit gap * 10 pixels/unit)
      } else {
        // Back cards fade smaller and stay higher
        final t = (zDepth + 0.7) / 0.4; // 0 to 1
        scale = 0.4 + t * 0.314;
        yOffset = -25.0 + t * 5.0;
      }

      // Opacity: back cards are more transparent
      final opacity = 0.4 + (zDepth + 1) * 0.3; // 0.4 to 1.0

      // Only show if within visible range
      if (zDepth > -0.7) {
        cards.add(
          _CardData(
            index: i,
            item: item,
            xOffset: xOffset,
            yOffset: yOffset,
            zDepth: zDepth,
            scale: scale,
            opacity: opacity,
            isFront: zDepth > 0.9,
          ),
        );
      }
    }

    // Sort by zDepth so front cards are on top
    cards.sort((a, b) => a.zDepth.compareTo(b.zDepth));

    return cards.map((data) {
      final shadowColor =
          _dominantColors[data.item.id] ?? GalaxyTheme.cyberpunkCyan;

      // Landscape card dimensions: 280x158 (16:9)
      const cardWidth = MusicCard3D.cardWidth;
      const cardHeight = MusicCard3D.cardHeight;

      return Positioned(
        left: centerX + data.xOffset - (cardWidth / 2) * data.scale,
        top: centerY + data.yOffset - (cardHeight / 2) * data.scale,
        child: GestureDetector(
          onTap: () {
            if (data.index != widget.currentIndex) {
              widget.onIndexChanged(data.index);
            }
          },
          child: Transform.scale(
            scale: data.scale,
            child: Opacity(
              opacity: data.opacity.clamp(0.0, 1.0),
              child: widget.cardBuilder(data.item, data.isFront, shadowColor),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _CardData {
  final int index;
  final MusicItem item;
  final double xOffset;
  final double yOffset;
  final double zDepth;
  final double scale;
  final double opacity;
  final bool isFront;

  _CardData({
    required this.index,
    required this.item,
    required this.xOffset,
    required this.yOffset,
    required this.zDepth,
    required this.scale,
    required this.opacity,
    required this.isFront,
  });
}

/// A single 3D card with dynamic shadow color from image
/// Enhanced with CSS-style 3D effects: colored border + radial gradient overlay
/// Card shape: Landscape rectangle with 16:9 aspect ratio (280x158)
class MusicCard3D extends StatelessWidget {
  final MusicItem item;
  final bool isFront;
  final Color shadowColor;
  final VoidCallback? onMenuTap;

  // Card dimensions: 16:9 landscape ratio (increased 30%)
  static const double cardWidth = 364;
  static const double cardHeight = 205; // 364 / (16/9) ≈ 205

  const MusicCard3D({
    super.key,
    required this.item,
    required this.isFront,
    required this.shadowColor,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Colored border like CSS: border: 2px solid rgba(var(--color-card))
        border: Border.all(
          color: shadowColor.withOpacity(isFront ? 0.9 : 0.5),
          width: isFront ? 2.5 : 1.5,
        ),
        boxShadow: [
          // Glow effect from the card color
          BoxShadow(
            color: shadowColor.withOpacity(isFront ? 0.5 : 0.2),
            blurRadius: isFront ? 25 : 12,
            spreadRadius: isFront ? 4 : 1,
          ),
          // Inner shadow for depth
          if (isFront)
            BoxShadow(
              color: shadowColor.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Album Art with proper fit
            _buildAlbumArt(),

            // CSS-style radial gradient overlay
            // background: radial-gradient(circle, rgba(color, 0.2) 0%, rgba(color, 0.6) 80%, rgba(color, 0.9) 100%)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        shadowColor.withOpacity(0.05),
                        shadowColor.withOpacity(isFront ? 0.15 : 0.25),
                        shadowColor.withOpacity(isFront ? 0.3 : 0.45),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom gradient for text visibility
            if (isFront)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

            // Song info overlay (only on front card)
            if (isFront)
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // Menu button (only on front card)
            if (isFront && onMenuTap != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 22,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 8),
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                  onPressed: onMenuTap,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    if (item.albumArt.isEmpty) {
      return _buildPlaceholder();
    }

    if (item.albumArt.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          item.albumArt,
          width: cardWidth,
          height: cardHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(item.albumArt),
        width: cardWidth,
        height: cardHeight,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final hash = item.title.hashCode.abs();
    final colors = [
      [GalaxyTheme.cosmicViolet, GalaxyTheme.galaxyBlue],
      [GalaxyTheme.nebulaPurple, GalaxyTheme.stardustPink],
      [GalaxyTheme.cyberpunkPink, GalaxyTheme.cyberpunkCyan],
      [GalaxyTheme.auroraGreen, GalaxyTheme.galaxyBlue],
    ];
    final selectedColors = colors[hash % colors.length];

    final words = item.title.trim().split(' ');
    String displayText;
    if (words.length >= 2) {
      displayText = words[0][0].toUpperCase() + words[1][0].toUpperCase();
    } else if (item.title.length >= 2) {
      displayText = item.title.substring(0, 2).toUpperCase();
    } else {
      displayText = item.title.toUpperCase();
    }

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
            fontSize: 48,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(3, 3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
