import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/feature_registry.dart';
import 'core/animated_background.dart';
import 'core/auth_provider.dart';
import 'core/settings/settings_screen.dart';
import 'core/localization/app_localization.dart';
import 'core/youtube_download_service.dart';
import 'features/user_profile/user_profile_view_enhanced.dart';
import 'features/music_carousel/music_service.dart';
import 'features/listening_history/listening_history_screen.dart';
import 'features/library/song_list_screen.dart';

/// Main Screen - The layout skeleton
///
/// This scaffold connects all the UI components:
/// - AppBar with hamburger menu and user avatar
/// - Body with the 3D carousel
/// - Left Drawer (menu)
/// - Right Drawer (user profile)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,

      // Galaxy Background with Animation
      body: AnimatedGalaxyBackground(
        child: Column(
          children: [
            // Custom AppBar with Glass Effect
            _buildGlassAppBar(context, scaffoldKey),

            // Main Content - 3D Carousel
            Expanded(
              child: Center(
                child: FeatureWidget(
                  featureId: 'music_carousel',
                  fallback: _buildFallbackMessage(
                    'Music Carousel not available',
                  ),
                ),
              ),
            ),

            // Bottom Space
            const SizedBox(height: 20),
          ],
        ),
      ),

      // Left Drawer - Menu
      drawer: _buildMenuDrawer(context),

      // Right Drawer - User Profile
      endDrawer: Drawer(
        child: UserProfileViewEnhanced(
          authService: AuthProvider.of(context),
          musicService: MusicServiceProvider.of(context),
        ),
      ),
    );
  }

  /// Glass AppBar with Hamburger Menu and User Avatar
  Widget _buildGlassAppBar(
    BuildContext context,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) {
    // Get dynamic colors from theme provider
    final colors = ThemeProvider.colorsOf(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              colors.nebulaPrimary.withOpacity(0.3),
              colors.cosmicAccent.withOpacity(0.2),
            ],
          ),
          border: Border.all(color: colors.moonGlow.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: colors.cosmicAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hamburger Menu
                IconButton(
                  icon: Icon(Icons.menu, color: colors.moonGlow),
                  onPressed: () {
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),

                // App Logo - Use Mizz.png with transparent background handling
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Image.asset(
                    'assets/Mizz.png',
                    height: 40,
                    fit: BoxFit.contain,
                    // Ensure transparent background is handled properly
                    filterQuality: FilterQuality.high,
                  ),
                ),

                // User Avatar
                GestureDetector(
                  onTap: () {
                    scaffoldKey.currentState?.openEndDrawer();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.stardustPink.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.stardustPink.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: colors.cosmicAccent,
                      child: const Text('🎵', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Left Drawer - Menu
  Widget _buildMenuDrawer(BuildContext context) {
    // Get dynamic colors and localization
    final colors = ThemeProvider.colorsOf(context);
    final l10n = AppLocalizations.of(context);

    return Drawer(
      child: Container(
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
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.music_note, size: 50, color: colors.auroraGreen),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appName,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.yourMusicYourWay,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.moonGlow.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: colors.moonGlow, thickness: 0.5),

              // Menu Items
              _buildMenuItem(
                context,
                icon: Icons.home,
                title: l10n.home,
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.add_circle_outline,
                title: l10n.addNewSong,
                onTap: () {
                  Navigator.pop(context);
                  _showAddSongDialog(context);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.library_music,
                title: l10n.myLibrary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SongListScreen.library()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.playlist_play,
                title: l10n.playlists,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.favorite,
                title: l10n.favorites,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SongListScreen.favorites(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.history,
                title: l10n.recentlyPlayed,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ListeningHistoryScreen(),
                    ),
                  );
                },
              ),

              Divider(color: colors.moonGlow, thickness: 0.5),

              _buildMenuItem(
                context,
                icon: Icons.settings,
                title: l10n.settings,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: l10n.about,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show Add Song Dialog
  void _showAddSongDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController artistController = TextEditingController();
    final TextEditingController linkController = TextEditingController();
    String? imagePath;
    String? musicFilePath;
    String sourceType = 'link'; // 'link' or 'file'

    // Get dynamic colors and localization
    final colors = ThemeProvider.colorsOf(context);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.nebulaPrimary.withOpacity(0.9),
                      colors.cosmicAccent.withOpacity(0.9),
                    ],
                  ),
                  border: Border.all(
                    color: colors.moonGlow.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          l10n.addNewSong,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Image picker (optional)
                        Text(
                          '${l10n.coverImage} (${l10n.cancel})',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: colors.deepSpace.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.moonGlow.withOpacity(0.2),
                            ),
                          ),
                          child: imagePath == null
                              ? InkWell(
                                  onTap: () async {
                                    // Implement image picker
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (image != null) {
                                      setState(() {
                                        imagePath = image.path;
                                      });
                                    }
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 48,
                                        color: colors.moonGlow.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.tapToAddImage,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: colors.moonGlow
                                                  .withOpacity(0.5),
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(imagePath!),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.close),
                                        color: colors.moonGlow,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            imagePath = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Song name
                        Text(
                          '${l10n.songName} *',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          style: TextStyle(color: colors.moonGlow),
                          decoration: InputDecoration(
                            hintText: l10n.enterSongName,
                            hintStyle: TextStyle(
                              color: colors.moonGlow.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: colors.deepSpace.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.moonGlow.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.moonGlow.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.auroraGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Artist name
                        Text(
                          l10n.artist,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: artistController,
                          style: TextStyle(color: colors.moonGlow),
                          decoration: InputDecoration(
                            hintText: l10n.enterArtist,
                            hintStyle: TextStyle(
                              color: colors.moonGlow.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: colors.deepSpace.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.moonGlow.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.moonGlow.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.auroraGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Music Source Type Selector
                        Text(
                          '${l10n.musicSource} *',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),

                        // Source type tabs
                        Container(
                          decoration: BoxDecoration(
                            color: colors.deepSpace.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.moonGlow.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      sourceType = 'link';
                                      musicFilePath = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sourceType == 'link'
                                          ? colors.auroraGreen.withOpacity(0.3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.link,
                                          color: sourceType == 'link'
                                              ? colors.auroraGreen
                                              : colors.moonGlow.withOpacity(
                                                  0.5,
                                                ),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.link,
                                          style: TextStyle(
                                            color: sourceType == 'link'
                                                ? colors.auroraGreen
                                                : colors.moonGlow.withOpacity(
                                                    0.5,
                                                  ),
                                            fontWeight: sourceType == 'link'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      sourceType = 'file';
                                      linkController.clear();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sourceType == 'file'
                                          ? colors.accentCyan.withOpacity(0.3)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.upload_file,
                                          color: sourceType == 'file'
                                              ? colors.accentCyan
                                              : colors.moonGlow.withOpacity(
                                                  0.5,
                                                ),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.uploadFile,
                                          style: TextStyle(
                                            color: sourceType == 'file'
                                                ? colors.accentCyan
                                                : colors.moonGlow.withOpacity(
                                                    0.5,
                                                  ),
                                            fontWeight: sourceType == 'file'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Link input or file upload
                        if (sourceType == 'link')
                          TextField(
                            controller: linkController,
                            style: TextStyle(color: colors.moonGlow),
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: l10n.enterMusicUrl,
                              hintStyle: TextStyle(
                                color: colors.moonGlow.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: colors.deepSpace.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colors.moonGlow.withOpacity(0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colors.moonGlow.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colors.auroraGreen,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.link,
                                color: colors.auroraGreen,
                              ),
                            ),
                          )
                        else
                          InkWell(
                            onTap: () async {
                              // Request storage permission for Android 13+
                              if (Platform.isAndroid) {
                                final status = await Permission.audio.request();
                                if (!status.isGranted) {
                                  // Try storage permission as fallback
                                  final storageStatus = await Permission.storage
                                      .request();
                                  if (!storageStatus.isGranted) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.storagePermissionRequired,
                                          ),
                                          backgroundColor: colors.stardustPink,
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                }
                              }

                              // Use custom extensions instead of FileType.audio
                              // FileType.audio can fail on some Android devices
                              FilePickerResult? result = await FilePicker
                                  .platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'mp3',
                                      'wav',
                                      'aac',
                                      'm4a',
                                      'ogg',
                                      'flac',
                                      'wma',
                                      'opus',
                                      'webm',
                                    ],
                                    allowMultiple: false,
                                  );

                              if (result != null &&
                                  result.files.single.path != null) {
                                setState(() {
                                  musicFilePath = result.files.single.path;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.deepSpace.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: musicFilePath != null
                                      ? colors.accentCyan
                                      : colors.moonGlow.withOpacity(0.2),
                                  width: musicFilePath != null ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    musicFilePath != null
                                        ? Icons.audiotrack
                                        : Icons.upload_file,
                                    color: musicFilePath != null
                                        ? colors.accentCyan
                                        : colors.moonGlow.withOpacity(0.5),
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          musicFilePath != null
                                              ? l10n.fileSelected
                                              : l10n.tapToUploadFile,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: musicFilePath != null
                                                    ? colors.accentCyan
                                                    : colors.moonGlow
                                                          .withOpacity(0.7),
                                              ),
                                        ),
                                        if (musicFilePath != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            musicFilePath!.split('/').last,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: colors.moonGlow
                                                      .withOpacity(0.5),
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (musicFilePath != null)
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      color: colors.moonGlow,
                                      onPressed: () {
                                        setState(() {
                                          musicFilePath = null;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Cancel button
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              child: Text(
                                l10n.cancel,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: colors.moonGlow.withOpacity(0.7),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Add button
                            ElevatedButton(
                              onPressed: () {
                                // Validate based on source type
                                if (nameController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.pleaseEnterSongName),
                                      backgroundColor: colors.stardustPink,
                                    ),
                                  );
                                  return;
                                }

                                if (sourceType == 'link' &&
                                    linkController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.pleaseEnterMusicLink),
                                      backgroundColor: colors.stardustPink,
                                    ),
                                  );
                                  return;
                                }

                                if (sourceType == 'file' &&
                                    musicFilePath == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.pleaseSelectMusicFile),
                                      backgroundColor: colors.stardustPink,
                                    ),
                                  );
                                  return;
                                }

                                // Add song to music service
                                final musicService = MusicServiceProvider.of(
                                  context,
                                );
                                final songSource = sourceType == 'link'
                                    ? linkController.text.trim()
                                    : musicFilePath!;
                                final songTitle = nameController.text.trim();
                                final songArtist =
                                    artistController.text.trim().isEmpty
                                    ? l10n.unknownArtist
                                    : artistController.text.trim();

                                final songId = musicService.addSong(
                                  title: songTitle,
                                  artist: songArtist,
                                  musicSource: songSource,
                                  albumArt: imagePath,
                                );

                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${l10n.songAddedSuccess} "$songTitle"',
                                    ),
                                    backgroundColor: colors.auroraGreen,
                                  ),
                                );

                                // Check if it's a YouTube link and offer to download
                                if (sourceType == 'link' &&
                                    YouTubeDownloadService().isYouTubeUrl(
                                      songSource,
                                    )) {
                                  // Show download dialog after a short delay
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () {
                                      if (context.mounted) {
                                        _showYouTubeDownloadDialog(
                                          context,
                                          songId: songId,
                                          songTitle: songTitle,
                                          youtubeUrl: songSource,
                                        );
                                      }
                                    },
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.auroraGreen,
                                foregroundColor: colors.deepSpace,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(l10n.addSong),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show dialog asking user if they want to download YouTube audio for faster playback
  void _showYouTubeDownloadDialog(
    BuildContext context, {
    required String songId,
    required String songTitle,
    required String youtubeUrl,
  }) {
    final colors = ThemeProvider.colorsOf(context);
    final l10n = AppLocalizations.of(context);

    double downloadProgress = 0.0;
    String statusMessage = '';
    bool isDownloading = false;
    bool downloadComplete = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.nebulaPrimary.withOpacity(0.95),
                      colors.cosmicAccent.withOpacity(0.95),
                    ],
                  ),
                  border: Border.all(
                    color: colors.moonGlow.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Icon(
                        isDownloading
                            ? Icons.downloading
                            : downloadComplete
                            ? Icons.check_circle
                            : Icons.download_for_offline,
                        size: 48,
                        color: downloadComplete
                            ? colors.auroraGreen
                            : colors.accentCyan,
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        downloadComplete
                            ? l10n.downloadComplete
                            : isDownloading
                            ? l10n.downloadingAudio
                            : l10n.downloadForFasterPlayback,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Description or progress
                      if (!isDownloading && !downloadComplete)
                        Text(
                          l10n.youtubeDownloadDescription,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.moonGlow.withOpacity(0.8),
                              ),
                          textAlign: TextAlign.center,
                        )
                      else if (isDownloading) ...[
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: downloadProgress,
                            backgroundColor: colors.deepSpace.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.accentCyan,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(downloadProgress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.accentCyan,
                              ),
                        ),
                        if (statusMessage.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            statusMessage,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.moonGlow.withOpacity(0.6),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ] else if (downloadComplete)
                        Text(
                          l10n.downloadCompleteDescription,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.auroraGreen),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 24),

                      // Buttons
                      if (!isDownloading && !downloadComplete)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Skip button
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(
                                l10n.skipForNow,
                                style: TextStyle(
                                  color: colors.moonGlow.withOpacity(0.7),
                                ),
                              ),
                            ),
                            // Download button
                            ElevatedButton.icon(
                              onPressed: () async {
                                setState(() {
                                  isDownloading = true;
                                  downloadProgress = 0;
                                  statusMessage = '';
                                });

                                final downloadService =
                                    YouTubeDownloadService();
                                final localPath = await downloadService
                                    .downloadYouTubeAudio(
                                      youtubeUrl,
                                      songTitle: songTitle,
                                      onProgress: (progress) {
                                        setState(() {
                                          downloadProgress = progress;
                                        });
                                      },
                                      onStatus: (status) {
                                        setState(() {
                                          statusMessage = status;
                                        });
                                      },
                                    );

                                if (localPath != null && context.mounted) {
                                  // Update song with local file path
                                  final musicService = MusicServiceProvider.of(
                                    context,
                                  );
                                  musicService.updateLocalFilePath(
                                    songId,
                                    localPath,
                                  );

                                  setState(() {
                                    downloadComplete = true;
                                    isDownloading = false;
                                  });
                                } else {
                                  // Download failed
                                  setState(() {
                                    isDownloading = false;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.downloadFailed),
                                        backgroundColor: colors.stardustPink,
                                      ),
                                    );
                                  }
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                              icon: const Icon(Icons.download),
                              label: Text(l10n.downloadNow),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.accentCyan,
                                foregroundColor: colors.deepSpace,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (downloadComplete)
                        ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.auroraGreen,
                            foregroundColor: colors.deepSpace,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l10n.done),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colors = ThemeProvider.colorsOf(context);
    return ListTile(
      leading: Icon(icon, color: colors.moonGlow),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      onTap: onTap,
      hoverColor: colors.cosmicAccent.withOpacity(0.3),
    );
  }

  Widget _buildFallbackMessage(String message) {
    return Builder(
      builder: (context) {
        final colors = ThemeProvider.colorsOf(context);
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  colors.nebulaPrimary.withOpacity(0.3),
                  colors.cosmicAccent.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: colors.moonGlow.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 50, color: colors.stardustPink),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(color: colors.moonGlow, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
