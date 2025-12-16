import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// User Profile Widget
///
/// Displays user information and favorite songs in the EndDrawer
class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(gradient: GalaxyTheme.galaxyGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // User Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: GalaxyTheme.moonGlow.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: GalaxyTheme.glassmorpismShadow,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: GalaxyTheme.cosmicViolet,
                child: Text('🎵', style: TextStyle(fontSize: 40)),
              ),
            ),

            const SizedBox(height: 16),

            // User Name
            Text(
              'Music Lover',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // User Email
            Text(
              'user@galaxy.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GalaxyTheme.moonGlow.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 30),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Songs', '156', Icons.music_note),
                _buildStatCard('Favorites', '42', Icons.favorite),
                _buildStatCard('Playlists', '8', Icons.playlist_play),
              ],
            ),

            const SizedBox(height: 30),

            // Favorite Songs Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.star, color: GalaxyTheme.auroraGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Favorite Songs',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Favorite Songs List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFavoriteSongTile(
                    'Cosmic Journey',
                    'Stellar Sounds',
                    '🌌',
                  ),
                  _buildFavoriteSongTile(
                    'Stardust Symphony',
                    'Cosmic Collective',
                    '⭐',
                  ),
                  _buildFavoriteSongTile(
                    'Meteor Shower',
                    'Space Voyagers',
                    '☄️',
                  ),
                  _buildFavoriteSongTile(
                    'Aurora Dreams',
                    'Northern Lights',
                    '🌈',
                  ),
                  _buildFavoriteSongTile(
                    'Galaxy Waltz',
                    'Celestial Harmony',
                    '🪐',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: GalaxyTheme.glassContainer(borderRadius: 16),
      child: Column(
        children: [
          Icon(icon, color: GalaxyTheme.stardustPink, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: GalaxyTheme.starWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: GalaxyTheme.moonGlow.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteSongTile(String title, String artist, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: GalaxyTheme.glassContainer(borderRadius: 12),
      child: Row(
        children: [
          // Emoji Album Art
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  GalaxyTheme.cosmicViolet.withOpacity(0.3),
                  GalaxyTheme.galaxyBlue.withOpacity(0.3),
                ],
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),

          const SizedBox(width: 12),

          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: GalaxyTheme.starWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artist,
                  style: TextStyle(
                    fontSize: 12,
                    color: GalaxyTheme.moonGlow.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Favorite Icon
          const Icon(Icons.favorite, color: GalaxyTheme.stardustPink, size: 20),
        ],
      ),
    );
  }
}
