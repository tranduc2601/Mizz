import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/feature_registry.dart';
import 'core/auth_provider.dart';
import 'core/localization/app_localization.dart';
import 'features/music_carousel/music_carousel_feature.dart';
import 'features/music_carousel/music_service.dart';
import 'features/music_carousel/music_player_service.dart';
import 'features/user_profile/user_profile_feature.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'main_screen.dart';

void main() {
  // Initialize the app
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: GalaxyTheme.deepSpace,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Register features using the plug-and-play architecture
  _registerFeatures();

  runApp(const GalaxyMusicApp());
}

/// Register all features in the Feature Registry
///
/// TO "UNINSTALL" A FEATURE: Simply comment out or remove the line below
/// Example: Remove music_carousel feature by commenting:
/// // registry.register(MusicCarouselFeature());
void _registerFeatures() {
  final registry = FeatureRegistry();

  // Register Music Carousel Feature
  registry.register(MusicCarouselFeature());

  // Register User Profile Feature
  registry.register(UserProfileFeature());

  // Future features can be added here:
  // registry.register(VolumeControlFeature());
  // registry.register(EqualizerFeature());
  // etc.
}

class GalaxyMusicApp extends StatefulWidget {
  const GalaxyMusicApp({super.key});

  @override
  State<GalaxyMusicApp> createState() => _GalaxyMusicAppState();
}

class _GalaxyMusicAppState extends State<GalaxyMusicApp> {
  late final AuthService authService;
  late final MusicService musicService;
  late final MusicPlayerService playerService;
  late final LocalizationController localizationController;
  late final ThemeController themeController;

  @override
  void initState() {
    super.initState();
    authService = AuthService();
    musicService = MusicService();
    playerService = MusicPlayerService();
    localizationController = LocalizationController(locale: AppLocale.english);
    themeController = ThemeController();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      controller: themeController,
      child: LocalizationProvider(
        controller: localizationController,
        child: AuthProvider(
          authService: authService,
          child: MusicServiceProvider(
            musicService: musicService,
            child: MusicPlayerServiceProvider(
              playerService: playerService,
              child: ListenableBuilder(
                listenable: Listenable.merge([localizationController, themeController]),
                builder: (context, child) {
                  return MaterialApp(
                    title: 'Mizz',
                    debugShowCheckedModeBanner: false,
                    theme: themeController.themeData,
                    home: ListenableBuilder(
                      listenable: authService,
                      builder: (context, child) {
                        if (authService.isAuthenticated) {
                          return const MainScreen();
                        }
                        return LoginScreen(authService: authService);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
