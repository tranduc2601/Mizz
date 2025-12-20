import 'package:flutter/material.dart';
import '../core/optimized_background.dart';
import '../features/music_carousel/optimized_carousel.dart';
import '../core/theme.dart';

/// Example: How to integrate optimized widgets into main_screen.dart
///
/// This demonstrates the complete integration of:
/// 1. OptimizedGalaxyBackground (replaces AnimatedGalaxyBackground)
/// 2. OptimizedMusicCarousel (replaces Matrix4 carousel)

class OptimizedMainScreenExample extends StatelessWidget {
  const OptimizedMainScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedGalaxyBackground(
      enableBreathing: true, // Set to false for even better performance
      child: Scaffold(
        backgroundColor: Colors.transparent,

        // Left drawer
        drawer: _buildLeftDrawer(),

        // Right drawer
        endDrawer: _buildRightDrawer(),

        // App bar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Galaxy Music',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/user_avatar.png'),
                ),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Main content
        body: Column(
          children: [
            const SizedBox(height: 20),

            // Header
            Text(
              'Now Playing',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Optimized Carousel (60fps guaranteed!)
            const Expanded(child: OptimizedMusicCarousel()),

            // Player controls
            _buildPlayerControls(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a0033), // Deep Purple
              Color(0xFF000000), // Black
              Color(0xFF001a4d), // Dark Blue
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [GalaxyTheme.cosmicViolet, GalaxyTheme.galaxyBlue],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.music_note, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Galaxy Music',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.library_music, 'Library', () {}),
            _buildDrawerItem(Icons.playlist_play, 'Playlists', () {}),
            _buildDrawerItem(Icons.album, 'Albums', () {}),
            _buildDrawerItem(Icons.person, 'Artists', () {}),
            const Divider(color: Colors.white24),
            _buildDrawerItem(Icons.settings, 'Settings', () {}),
            _buildDrawerItem(Icons.info_outline, 'About', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildRightDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1a0033), Color(0xFF000000), Color(0xFF001a4d)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    GalaxyTheme.cyberpunkPink,
                    GalaxyTheme.cyberpunkCyan,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage('assets/user_avatar.png'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Music Lover',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.favorite, 'Favorites', () {}),
            _buildDrawerItem(Icons.history, 'Recently Played', () {}),
            _buildDrawerItem(Icons.file_download, 'Downloads', () {}),
            const Divider(color: Colors.white24),
            _buildDrawerItem(Icons.account_circle, 'Profile', () {}),
            _buildDrawerItem(Icons.logout, 'Logout', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: GalaxyTheme.cyberpunkPink,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
            ),
            child: Slider(value: 0.5, onChanged: (value) {}),
          ),

          const SizedBox(height: 10),

          // Time labels
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('2:30', style: TextStyle(color: Colors.white70)),
                Text('5:00', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.shuffle),
                color: Colors.white70,
                iconSize: 28,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                color: Colors.white,
                iconSize: 40,
                onPressed: () {},
              ),

              // Play/Pause button
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      GalaxyTheme.cyberpunkPink,
                      GalaxyTheme.cyberpunkCyan,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GalaxyTheme.cyberpunkPink.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: () {},
                ),
              ),

              IconButton(
                icon: const Icon(Icons.skip_next),
                color: Colors.white,
                iconSize: 40,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.repeat),
                color: Colors.white70,
                iconSize: 28,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HOW TO INTEGRATE INTO YOUR EXISTING APP
// ============================================================================

/*
STEP 1: Open your main_screen.dart file

STEP 2: Replace the old widgets:

// BEFORE:
import 'core/animated_background.dart';
import 'features/music_carousel/carousel_view_enhanced.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedGalaxyBackground(  // OLD
      child: Scaffold(
        body: MusicCarouselView(),  // OLD
      ),
    );
  }
}

// AFTER:
import 'core/optimized_background.dart';
import 'features/music_carousel/optimized_carousel.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return OptimizedGalaxyBackground(  // NEW
      enableBreathing: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: const OptimizedMusicCarousel(),  // NEW
      ),
    );
  }
}

STEP 3: Test the app

flutter run --profile

STEP 4: Check performance (press 'P' in terminal)

Expected result: Green bars at 60fps, no red spikes!
*/
