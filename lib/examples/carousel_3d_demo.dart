import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D Rotating Card Carousel Demo
/// Converted from HTML/CSS 3D card carousel
class Carousel3DDemo extends StatefulWidget {
  const Carousel3DDemo({super.key});

  @override
  State<Carousel3DDemo> createState() => _Carousel3DDemoState();
}

class _Carousel3DDemoState extends State<Carousel3DDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Card colors (RGB values from the original CSS)
  final List<Color> cardColors = [
    const Color.fromRGBO(142, 249, 252, 1), // Cyan
    const Color.fromRGBO(142, 252, 204, 1), // Mint
    const Color.fromRGBO(142, 252, 157, 1), // Light Green
    const Color.fromRGBO(215, 252, 142, 1), // Lime
    const Color.fromRGBO(252, 252, 142, 1), // Yellow
    const Color.fromRGBO(252, 208, 142, 1), // Orange
    const Color.fromRGBO(252, 142, 142, 1), // Red
    const Color.fromRGBO(252, 142, 239, 1), // Pink
    const Color.fromRGBO(204, 142, 252, 1), // Purple
    const Color.fromRGBO(142, 202, 252, 1), // Blue
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // Same as CSS animation
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        title: const Text('3D Card Carousel'),
        backgroundColor: const Color(0xFF1a1a2e),
      ),
      body: Center(
        child: Carousel3D(
          controller: _controller,
          cardColors: cardColors,
          cardWidth: 100,
          cardHeight: 150,
          rotateX: -15, // degrees, same as CSS --rotateX
        ),
      ),
    );
  }
}

/// 3D Carousel Widget
class Carousel3D extends StatelessWidget {
  final AnimationController controller;
  final List<Color> cardColors;
  final double cardWidth;
  final double cardHeight;
  final double rotateX;

  const Carousel3D({
    super.key,
    required this.controller,
    required this.cardColors,
    this.cardWidth = 100,
    this.cardHeight = 150,
    this.rotateX = -15,
  });

  @override
  Widget build(BuildContext context) {
    final int quantity = cardColors.length;
    // translateZ = (width + height) from CSS
    final double translateZ = cardWidth + cardHeight;

    return SizedBox(
      width: 300,
      height: 400,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(quantity, (index) {
              // Calculate rotation angle for each card
              final double cardAngle = (360 / quantity) * index;
              // Current rotation from animation (0 to 360 degrees)
              final double currentRotation = controller.value * 360;

              return _buildCard(
                index: index,
                cardAngle: cardAngle,
                currentRotation: currentRotation,
                translateZ: translateZ,
                color: cardColors[index],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required int index,
    required double cardAngle,
    required double currentRotation,
    required double translateZ,
    required Color color,
  }) {
    // Total Y rotation = card's base angle + current animation rotation
    final double totalYRotation = cardAngle + currentRotation;
    final double yRotationRad = totalYRotation * (math.pi / 180);
    final double xRotationRad = rotateX * (math.pi / 180);

    // Calculate 3D position
    final double x = translateZ * math.sin(yRotationRad);
    final double z = translateZ * math.cos(yRotationRad);

    // Calculate scale based on Z position (perspective effect)
    final double perspective = 1000;
    final double scale = perspective / (perspective + z);

    // Calculate opacity based on Z position (cards in back are more transparent)
    final double opacity = ((z + translateZ) / (2 * translateZ)).clamp(
      0.3,
      1.0,
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..translate(x * scale, 0.0, 0.0)
        ..rotateX(xRotationRad)
        ..rotateY(yRotationRad)
        ..scale(scale),
      child: Opacity(
        opacity: opacity,
        child: _Card3D(width: cardWidth, height: cardHeight, color: color),
      ),
    );
  }
}

/// Individual 3D Card
class _Card3D extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _Card3D({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.6),
            color.withOpacity(0.9),
          ],
          stops: const [0.0, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

/// Enhanced version with images
class Carousel3DWithImages extends StatefulWidget {
  final List<String> imageUrls;
  final List<Color>? cardColors;

  const Carousel3DWithImages({
    super.key,
    required this.imageUrls,
    this.cardColors,
  });

  @override
  State<Carousel3DWithImages> createState() => _Carousel3DWithImagesState();
}

class _Carousel3DWithImagesState extends State<Carousel3DWithImages>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Color> _defaultColors = [
    const Color.fromRGBO(142, 249, 252, 1),
    const Color.fromRGBO(142, 252, 204, 1),
    const Color.fromRGBO(142, 252, 157, 1),
    const Color.fromRGBO(215, 252, 142, 1),
    const Color.fromRGBO(252, 252, 142, 1),
    const Color.fromRGBO(252, 208, 142, 1),
    const Color.fromRGBO(252, 142, 142, 1),
    const Color.fromRGBO(252, 142, 239, 1),
    const Color.fromRGBO(204, 142, 252, 1),
    const Color.fromRGBO(142, 202, 252, 1),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.cardColors ?? _defaultColors;
    final int quantity = widget.imageUrls.length;
    final double cardWidth = 100;
    final double cardHeight = 150;
    final double translateZ = cardWidth + cardHeight;

    return SizedBox(
      width: 300,
      height: 400,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(quantity, (index) {
              final double cardAngle = (360 / quantity) * index;
              final double currentRotation = _controller.value * 360;
              final double totalYRotation = cardAngle + currentRotation;
              final double yRotationRad = totalYRotation * (math.pi / 180);
              final double xRotationRad = -15 * (math.pi / 180);

              final double x = translateZ * math.sin(yRotationRad);
              final double z = translateZ * math.cos(yRotationRad);
              final double perspective = 1000;
              final double scale = perspective / (perspective + z);
              final double opacity = ((z + translateZ) / (2 * translateZ))
                  .clamp(0.3, 1.0);

              final color = colors[index % colors.length];

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translate(x * scale, 0.0, 0.0)
                  ..rotateX(xRotationRad)
                  ..rotateY(yRotationRad)
                  ..scale(scale),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.6),
                                  color.withOpacity(0.9),
                                ],
                                stops: const [0.0, 0.8, 1.0],
                              ),
                            ),
                            child: Icon(Icons.image, color: color, size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
