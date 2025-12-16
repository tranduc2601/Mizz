import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme.dart';
import 'core/feature_registry.dart';
import 'core/animated_background.dart';
import 'core/auth_provider.dart';
import 'core/settings/settings_screen.dart';
import 'features/user_profile/user_profile_view_enhanced.dart';
import 'features/music_carousel/music_service.dart';
import 'features/listening_history/listening_history_screen.dart';

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
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              GalaxyTheme.nebulaPurple.withOpacity(0.3),
              GalaxyTheme.cosmicViolet.withOpacity(0.2),
            ],
          ),
          border: Border.all(
            color: GalaxyTheme.moonGlow.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: GalaxyTheme.cosmicViolet.withOpacity(0.3),
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
                  icon: const Icon(Icons.menu, color: GalaxyTheme.moonGlow),
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
                        color: GalaxyTheme.stardustPink.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GalaxyTheme.stardustPink.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: GalaxyTheme.cosmicViolet,
                      child: Text('🎵', style: TextStyle(fontSize: 20)),
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
    return Drawer(
      child: Container(
        decoration: BoxDecoration(gradient: GalaxyTheme.galaxyGradient),
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
                    const Icon(
                      Icons.music_note,
                      size: 50,
                      color: GalaxyTheme.auroraGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mizz',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Music, Your Way',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GalaxyTheme.moonGlow.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: GalaxyTheme.moonGlow, thickness: 0.5),

              // Menu Items
              _buildMenuItem(
                context,
                icon: Icons.home,
                title: 'Home',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.add_circle_outline,
                title: 'Add New Song',
                onTap: () {
                  Navigator.pop(context);
                  _showAddSongDialog(context);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.library_music,
                title: 'My Library',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.playlist_play,
                title: 'Playlists',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.favorite,
                title: 'Favorites',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.history,
                title: 'Recently Played',
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

              const Divider(color: GalaxyTheme.moonGlow, thickness: 0.5),

              _buildMenuItem(
                context,
                icon: Icons.settings,
                title: 'Settings',
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
                title: 'About',
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
                      GalaxyTheme.nebulaPurple.withOpacity(0.9),
                      GalaxyTheme.cosmicViolet.withOpacity(0.9),
                    ],
                  ),
                  border: Border.all(
                    color: GalaxyTheme.moonGlow.withOpacity(0.3),
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
                          'Add New Song',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Image picker (optional)
                        Text(
                          'Cover Image (Optional)',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: GalaxyTheme.deepSpace.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: GalaxyTheme.moonGlow.withOpacity(0.2),
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
                                        color: GalaxyTheme.moonGlow.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add image',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: GalaxyTheme.moonGlow
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
                                        color: GalaxyTheme.moonGlow,
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
                          'Song Name *',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: GalaxyTheme.moonGlow),
                          decoration: InputDecoration(
                            hintText: 'Enter song name',
                            hintStyle: TextStyle(
                              color: GalaxyTheme.moonGlow.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: GalaxyTheme.deepSpace.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: GalaxyTheme.moonGlow.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: GalaxyTheme.moonGlow.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: GalaxyTheme.auroraGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Artist name
                        Text(
                          'Artist Name',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: artistController,
                          style: const TextStyle(color: GalaxyTheme.moonGlow),
                          decoration: InputDecoration(
                            hintText: 'Enter artist name',
                            hintStyle: TextStyle(
                              color: GalaxyTheme.moonGlow.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: GalaxyTheme.deepSpace.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: GalaxyTheme.moonGlow.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: GalaxyTheme.moonGlow.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: GalaxyTheme.auroraGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Music Source Type Selector
                        Text(
                          'Music Source *',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),

                        // Source type tabs
                        Container(
                          decoration: BoxDecoration(
                            color: GalaxyTheme.deepSpace.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: GalaxyTheme.moonGlow.withOpacity(0.2),
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
                                          ? GalaxyTheme.auroraGreen.withOpacity(
                                              0.3,
                                            )
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
                                              ? GalaxyTheme.auroraGreen
                                              : GalaxyTheme.moonGlow
                                                    .withOpacity(0.5),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Link',
                                          style: TextStyle(
                                            color: sourceType == 'link'
                                                ? GalaxyTheme.auroraGreen
                                                : GalaxyTheme.moonGlow
                                                      .withOpacity(0.5),
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
                                          ? GalaxyTheme.cyberpunkCyan
                                                .withOpacity(0.3)
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
                                              ? GalaxyTheme.cyberpunkCyan
                                              : GalaxyTheme.moonGlow
                                                    .withOpacity(0.5),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Upload File',
                                          style: TextStyle(
                                            color: sourceType == 'file'
                                                ? GalaxyTheme.cyberpunkCyan
                                                : GalaxyTheme.moonGlow
                                                      .withOpacity(0.5),
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
                            style: const TextStyle(color: GalaxyTheme.moonGlow),
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'Paste YouTube, TikTok, or other music link',
                              hintStyle: TextStyle(
                                color: GalaxyTheme.moonGlow.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: GalaxyTheme.deepSpace.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: GalaxyTheme.moonGlow.withOpacity(0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: GalaxyTheme.moonGlow.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: GalaxyTheme.auroraGreen,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.link,
                                color: GalaxyTheme.auroraGreen,
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
                                        const SnackBar(
                                          content: Text(
                                            'Storage permission is required to upload music files',
                                          ),
                                          backgroundColor:
                                              GalaxyTheme.stardustPink,
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
                                color: GalaxyTheme.deepSpace.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: musicFilePath != null
                                      ? GalaxyTheme.cyberpunkCyan
                                      : GalaxyTheme.moonGlow.withOpacity(0.2),
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
                                        ? GalaxyTheme.cyberpunkCyan
                                        : GalaxyTheme.moonGlow.withOpacity(0.5),
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
                                              ? 'File selected'
                                              : 'Tap to upload MP3/MP4 file',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: musicFilePath != null
                                                    ? GalaxyTheme.cyberpunkCyan
                                                    : GalaxyTheme.moonGlow
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
                                                  color: GalaxyTheme.moonGlow
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
                                      color: GalaxyTheme.moonGlow,
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
                                'Cancel',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: GalaxyTheme.moonGlow.withOpacity(
                                        0.7,
                                      ),
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
                                    const SnackBar(
                                      content: Text('Please enter song name'),
                                      backgroundColor: GalaxyTheme.stardustPink,
                                    ),
                                  );
                                  return;
                                }

                                if (sourceType == 'link' &&
                                    linkController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a music link',
                                      ),
                                      backgroundColor: GalaxyTheme.stardustPink,
                                    ),
                                  );
                                  return;
                                }

                                if (sourceType == 'file' &&
                                    musicFilePath == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a music file',
                                      ),
                                      backgroundColor: GalaxyTheme.stardustPink,
                                    ),
                                  );
                                  return;
                                }

                                // Add song to music service
                                final musicService = MusicServiceProvider.of(
                                  context,
                                );
                                musicService.addSong(
                                  title: nameController.text.trim(),
                                  artist: artistController.text.trim().isEmpty
                                      ? 'Unknown Artist'
                                      : artistController.text.trim(),
                                  musicSource: sourceType == 'link'
                                      ? linkController.text.trim()
                                      : musicFilePath!,
                                  albumArt: imagePath,
                                );

                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Song "${nameController.text}" added!',
                                    ),
                                    backgroundColor: GalaxyTheme.auroraGreen,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GalaxyTheme.auroraGreen,
                                foregroundColor: GalaxyTheme.deepSpace,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Add Song'),
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

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: GalaxyTheme.moonGlow),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      onTap: onTap,
      hoverColor: GalaxyTheme.cosmicViolet.withOpacity(0.3),
    );
  }

  Widget _buildFallbackMessage(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: GalaxyTheme.glassContainer(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: GalaxyTheme.stardustPink,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: GalaxyTheme.moonGlow, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
