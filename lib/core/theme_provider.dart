import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App theme enum
enum AppThemeType {
  purple('purple', 'Tím Galaxy', 'Purple Galaxy'),
  blue('blue', 'Xanh Dương', 'Ocean Blue'),
  black('black', 'Đen', 'Dark Black'),
  white('white', 'Trắng', 'Light White'),
  red('red', 'Đỏ Tươi', 'Vibrant Red');

  final String code;
  final String nameVi;
  final String nameEn;
  const AppThemeType(this.code, this.nameVi, this.nameEn);

  static AppThemeType fromCode(String code) {
    return AppThemeType.values.firstWhere(
      (t) => t.code == code,
      orElse: () => AppThemeType.purple,
    );
  }
}

/// Theme colors for each theme type
class AppThemeColors {
  final Color deepSpace;
  final Color nebulaPrimary;
  final Color cosmicAccent;
  final Color stardustPink;
  final Color galaxyBlue;
  final Color moonGlow;
  final Color auroraGreen;
  final Color accentPink;
  final Color accentCyan;
  final Color accentPurple;
  final Color neonGreen;
  final bool isDark;

  const AppThemeColors({
    required this.deepSpace,
    required this.nebulaPrimary,
    required this.cosmicAccent,
    required this.stardustPink,
    required this.galaxyBlue,
    required this.moonGlow,
    required this.auroraGreen,
    required this.accentPink,
    required this.accentCyan,
    required this.accentPurple,
    required this.neonGreen,
    this.isDark = true,
  });

  // Purple Galaxy Theme (Original)
  static const purple = AppThemeColors(
    deepSpace: Color(0xFF0A0E27),
    nebulaPrimary: Color(0xFF2D1B69),
    cosmicAccent: Color(0xFF6B2D9E),
    stardustPink: Color(0xFFB968C7),
    galaxyBlue: Color(0xFF4A5F8F),
    moonGlow: Color(0xFFF0E5FF),
    auroraGreen: Color(0xFF66FFC2),
    accentPink: Color(0xFFFF006E),
    accentCyan: Color(0xFF00F0FF),
    accentPurple: Color(0xFF9D4EDD),
    neonGreen: Color(0xFF39FF14),
    isDark: true,
  );

  // Ocean Blue Theme
  static const blue = AppThemeColors(
    deepSpace: Color(0xFF0A1628),
    nebulaPrimary: Color(0xFF1B3A69),
    cosmicAccent: Color(0xFF2D6B9E),
    stardustPink: Color(0xFF68A8C7),
    galaxyBlue: Color(0xFF4A7F8F),
    moonGlow: Color(0xFFE5F0FF),
    auroraGreen: Color(0xFF66FFC2),
    accentPink: Color(0xFF00A3FF),
    accentCyan: Color(0xFF00F0FF),
    accentPurple: Color(0xFF4E7DDD),
    neonGreen: Color(0xFF39FF14),
    isDark: true,
  );

  // Dark Black Theme
  static const black = AppThemeColors(
    deepSpace: Color(0xFF000000),
    nebulaPrimary: Color(0xFF1A1A1A),
    cosmicAccent: Color(0xFF333333),
    stardustPink: Color(0xFF666666),
    galaxyBlue: Color(0xFF4A4A4A),
    moonGlow: Color(0xFFE0E0E0),
    auroraGreen: Color(0xFF00FF88),
    accentPink: Color(0xFFFF4081),
    accentCyan: Color(0xFF00BCD4),
    accentPurple: Color(0xFF7C4DFF),
    neonGreen: Color(0xFF00FF00),
    isDark: true,
  );

  // Light White Theme
  static const white = AppThemeColors(
    deepSpace: Color(0xFFFFFFFF),
    nebulaPrimary: Color(0xFFF5F5F5),
    cosmicAccent: Color(0xFFE0E0E0),
    stardustPink: Color(0xFF9E9E9E),
    galaxyBlue: Color(0xFF90A4AE),
    moonGlow: Color(0xFF212121),
    auroraGreen: Color(0xFF00C853),
    accentPink: Color(0xFFE91E63),
    accentCyan: Color(0xFF00ACC1),
    accentPurple: Color(0xFF7C4DFF),
    neonGreen: Color(0xFF00E676),
    isDark: false,
  );

  // Vibrant Red Theme
  static const red = AppThemeColors(
    deepSpace: Color(0xFF1A0A0A),
    nebulaPrimary: Color(0xFF3D1515),
    cosmicAccent: Color(0xFF6B2D2D),
    stardustPink: Color(0xFFFF6B6B),
    galaxyBlue: Color(0xFF8F4A4A),
    moonGlow: Color(0xFFFFE5E5),
    auroraGreen: Color(0xFFFFD700),
    accentPink: Color(0xFFFF0040),
    accentCyan: Color(0xFFFF6B9D),
    accentPurple: Color(0xFFDD4E4E),
    neonGreen: Color(0xFFFFAA00),
    isDark: true,
  );

  static AppThemeColors fromType(AppThemeType type) {
    switch (type) {
      case AppThemeType.purple:
        return purple;
      case AppThemeType.blue:
        return blue;
      case AppThemeType.black:
        return black;
      case AppThemeType.white:
        return white;
      case AppThemeType.red:
        return red;
    }
  }
}

/// Theme Controller - Manages app theme state
class ThemeController extends ChangeNotifier {
  AppThemeType _themeType;
  late AppThemeColors _colors;
  static const String _storageKey = 'mizz_theme';

  ThemeController({AppThemeType themeType = AppThemeType.purple})
      : _themeType = themeType {
    _colors = AppThemeColors.fromType(_themeType);
    _loadFromStorage();
  }

  AppThemeType get themeType => _themeType;
  AppThemeColors get colors => _colors;

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_storageKey);
      if (code != null) {
        _themeType = AppThemeType.fromCode(code);
        _colors = AppThemeColors.fromType(_themeType);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(AppThemeType type) async {
    if (_themeType != type) {
      _themeType = type;
      _colors = AppThemeColors.fromType(type);
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, type.code);
      } catch (e) {
        debugPrint('Error saving theme: $e');
      }
    }
  }

  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: _colors.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: _colors.deepSpace,
      colorScheme: ColorScheme(
        brightness: _colors.isDark ? Brightness.dark : Brightness.light,
        primary: _colors.cosmicAccent,
        secondary: _colors.stardustPink,
        surface: _colors.nebulaPrimary,
        error: Colors.redAccent,
        onPrimary: _colors.moonGlow,
        onSecondary: _colors.moonGlow,
        onSurface: _colors.moonGlow,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _colors.moonGlow),
        titleTextStyle: TextStyle(
          color: _colors.moonGlow,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _colors.moonGlow,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _colors.moonGlow,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: _colors.moonGlow),
        bodyMedium: TextStyle(fontSize: 14, color: _colors.moonGlow),
      ),
      iconTheme: IconThemeData(color: _colors.moonGlow, size: 24),
    );
  }
}

/// Theme Provider - Provides theme to widget tree
class ThemeProvider extends InheritedNotifier<ThemeController> {
  const ThemeProvider({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    return provider!.notifier!;
  }

  static AppThemeColors colorsOf(BuildContext context) {
    return of(context).colors;
  }
}
