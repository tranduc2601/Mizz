import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'theme_provider.dart';

/// Animated Galaxy Cyberpunk Background
/// Features moving stars, nebula clouds, and cyberpunk grid lines
/// Uses dynamic colors from ThemeProvider
class AnimatedGalaxyBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGalaxyBackground({super.key, required this.child});

  @override
  State<AnimatedGalaxyBackground> createState() =>
      _AnimatedGalaxyBackgroundState();
}

class _AnimatedGalaxyBackgroundState extends State<AnimatedGalaxyBackground>
    with TickerProviderStateMixin {
  late AnimationController _starsController;
  late AnimationController _nebulaController;
  final List<Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Generate stars
    for (int i = 0; i < 100; i++) {
      _stars.add(
        Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2 + 1,
          speed: _random.nextDouble() * 0.5 + 0.2,
          opacity: _random.nextDouble() * 0.5 + 0.3,
        ),
      );
    }

    // Stars animation
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Nebula animation
    _nebulaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _starsController.dispose();
    _nebulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get dynamic colors from theme provider
    final colors = ThemeProvider.colorsOf(context);

    return Stack(
      children: [
        // Base gradient background - uses dynamic theme colors
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.deepSpace,
                colors.nebulaPrimary,
                colors.cosmicAccent.withOpacity(0.6),
              ],
            ),
          ),
        ),

        // Animated nebula clouds
        AnimatedBuilder(
          animation: _nebulaController,
          builder: (context, child) {
            return CustomPaint(
              painter: NebulaPainter(_nebulaController.value, colors),
              size: Size.infinite,
            );
          },
        ),

        // Animated stars
        AnimatedBuilder(
          animation: _starsController,
          builder: (context, child) {
            return CustomPaint(
              painter: StarsPainter(_stars, _starsController.value, colors),
              size: Size.infinite,
            );
          },
        ),

        // Cyberpunk glow accents - uses dynamic theme colors
        Positioned(
          top: 100,
          left: 0,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colors.accentPink.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 100,
          right: 0,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colors.accentCyan.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class Star {
  final double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class StarsPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;
  final AppThemeColors colors;

  StarsPainter(this.stars, this.animationValue, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var star in stars) {
      // Update star position
      star.y = (star.y + star.speed * 0.001) % 1.0;

      final dx = star.x * size.width;
      final dy = star.y * size.height;

      paint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(Offset(dx, dy), star.size, paint);

      // Add twinkle effect - uses dynamic accent color
      if ((animationValue * 100 + star.x * 100).toInt() % 100 < 2) {
        paint.color = colors.accentCyan.withOpacity(0.8);
        canvas.drawCircle(Offset(dx, dy), star.size * 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) => true;
}

class NebulaPainter extends CustomPainter {
  final double animationValue;
  final AppThemeColors colors;

  NebulaPainter(this.animationValue, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    // Nebula cloud 1 - uses dynamic theme colors
    final offset1 = Offset(
      size.width * 0.3 + sin(animationValue * 2 * pi) * 50,
      size.height * 0.3 + cos(animationValue * 2 * pi) * 30,
    );
    paint.shader = RadialGradient(
      colors: [
        colors.nebulaPrimary.withOpacity(0.3),
        colors.cosmicAccent.withOpacity(0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: offset1, radius: 200));
    canvas.drawCircle(offset1, 200, paint);

    // Nebula cloud 2 - uses dynamic theme colors
    final offset2 = Offset(
      size.width * 0.7 + cos(animationValue * 2 * pi) * 60,
      size.height * 0.6 + sin(animationValue * 2 * pi) * 40,
    );
    paint.shader = RadialGradient(
      colors: [
        colors.stardustPink.withOpacity(0.2),
        colors.accentPink.withOpacity(0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: offset2, radius: 250));
    canvas.drawCircle(offset2, 250, paint);

    // Cyberpunk accent cloud - uses dynamic accent color
    final offset3 = Offset(
      size.width * 0.5 + sin(animationValue * 3 * pi) * 40,
      size.height * 0.8 + cos(animationValue * 3 * pi) * 20,
    );
    paint.shader = RadialGradient(
      colors: [colors.accentCyan.withOpacity(0.2), Colors.transparent],
    ).createShader(Rect.fromCircle(center: offset3, radius: 150));
    canvas.drawCircle(offset3, 150, paint);
  }

  @override
  bool shouldRepaint(NebulaPainter oldDelegate) => true;
}
