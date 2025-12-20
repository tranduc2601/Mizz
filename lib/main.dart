import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/feature_registry.dart';
import 'core/localization/app_localization.dart';
import 'core/media_notification_handler.dart';
import 'core/download_manager.dart';
import 'core/newpipe_downloader.dart';
import 'features/music_carousel/music_carousel_feature.dart';
import 'features/music_carousel/music_service.dart';
import 'features/music_carousel/music_player_service.dart';
import 'features/playlist/playlist_service.dart';
import 'features/user_profile/user_profile_feature.dart';
import 'main_screen.dart';

Future<void> main() async {
  // Initialize the app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize NewPipe Downloader
  try {
    NewPipeDownloader.initialize();
    debugPrint('✅ NewPipe Downloader initialized');
  } catch (e) {
    debugPrint('⚠️ NewPipe initialization failed: $e');
  }

  try {
    await initMizzAudioService();
  } catch (e) {
    debugPrint('⚠️ Failed to initialize media notification: $e');
  }

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
  late final MusicService musicService;
  late final MusicPlayerService playerService;
  late final PlaylistService playlistService;
  late final DownloadManager downloadManager;
  late final LocalizationController localizationController;
  late final ThemeController themeController;

  @override
  void initState() {
    super.initState();
    musicService = MusicService();
    playerService = MusicPlayerService();
    playlistService = PlaylistService();
    downloadManager = DownloadManager();
    localizationController = LocalizationController(locale: AppLocale.english);
    themeController = ThemeController();

    // Initialize playlist service
    playlistService.init();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      controller: themeController,
      child: LocalizationProvider(
        controller: localizationController,
        child: MusicServiceProvider(
          musicService: musicService,
          child: MusicPlayerServiceProvider(
            playerService: playerService,
            child: PlaylistServiceProvider(
              service: playlistService,
              child: DownloadManagerProvider(
                manager: downloadManager,
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    localizationController,
                    themeController,
                  ]),
                  builder: (context, child) {
                    return MaterialApp(
                      title: 'Mizz',
                      debugShowCheckedModeBanner: false,
                      theme: themeController.themeData,
                      home: const MainScreen(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
