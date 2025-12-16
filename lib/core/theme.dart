import 'package:flutter/material.dart';

/// Galaxy Mystical Theme for the Music Player App
/// Features deep purple/violet gradients with glassmorphism effects
class GalaxyTheme {
  // Primary Galaxy Colors
  static const Color deepSpace = Color(0xFF0A0E27);
  static const Color nebulaPurple = Color(0xFF2D1B69);
  static const Color cosmicViolet = Color(0xFF6B2D9E);
  static const Color stardustPink = Color(0xFFB968C7);
  static const Color galaxyBlue = Color(0xFF4A5F8F);

  // Accent Colors
  static const Color starWhite = Color(0xFFFFFFFF);
  static const Color moonGlow = Color(0xFFF0E5FF);
  static const Color auroraGreen = Color(0xFF66FFC2);

  // Cyberpunk Colors
  static const Color cyberpunkPink = Color(0xFFFF006E);
  static const Color cyberpunkCyan = Color(0xFF00F0FF);
  static const Color cyberpunkPurple = Color(0xFF9D4EDD);
  static const Color neonGreen = Color(0xFF39FF14);

  // Gradient Definitions
  static const LinearGradient galaxyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepSpace, nebulaPurple, cosmicViolet],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40FFFFFF), Color(0x20FFFFFF)],
  );

  // Glass Effect Shadow
  static List<BoxShadow> glassmorpismShadow = [
    BoxShadow(
      color: cosmicViolet.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 5,
    ),
    BoxShadow(
      color: stardustPink.withOpacity(0.2),
      blurRadius: 40,
      spreadRadius: 10,
    ),
  ];

  // Theme Data
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepSpace,

      colorScheme: const ColorScheme.dark(
        primary: cosmicViolet,
        secondary: stardustPink,
        surface: nebulaPurple,
        error: Colors.redAccent,
        onPrimary: starWhite,
        onSecondary: starWhite,
        onSurface: moonGlow,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: moonGlow),
        titleTextStyle: TextStyle(
          color: moonGlow,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: starWhite,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: moonGlow,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: moonGlow),
        bodyMedium: TextStyle(fontSize: 14, color: moonGlow),
      ),

      iconTheme: const IconThemeData(color: moonGlow, size: 24),
    );
  }

  // Glassmorphism Container Decoration
  static BoxDecoration glassContainer({
    double borderRadius = 20,
    Color? customColor,
  }) {
    return BoxDecoration(
      gradient: customColor != null
          ? LinearGradient(
              colors: [
                customColor.withOpacity(0.3),
                customColor.withOpacity(0.1),
              ],
            )
          : cardGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: moonGlow.withOpacity(0.2), width: 1.5),
      boxShadow: glassmorpismShadow,
    );
  }

  // Star Background Pattern (Optional decoration)
  static Widget starBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(gradient: galaxyGradient),
      child: Stack(
        children: [
          // Nebula effect overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [stardustPink.withOpacity(0.4), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}
