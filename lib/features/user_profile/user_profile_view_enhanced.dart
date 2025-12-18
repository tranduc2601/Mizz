import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../core/localization/app_localization.dart';
import '../music_carousel/music_service.dart';
import '../library/song_list_screen.dart';
import '../playlist/playlist_service.dart';

/// Enhanced User Profile Widget with Real Data
class UserProfileViewEnhanced extends StatelessWidget {
  final MusicService? musicService;

  const UserProfileViewEnhanced({
    super.key,
    this.musicService,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.colorsOf(context);
    final l10n = AppLocalizations.of(context);
    final playlistService = PlaylistServiceProvider.of(context);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.deepSpace, colors.nebulaPrimary, colors.cosmicAccent],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [colors.accentPink, colors.accentCyan],
                    ).createShader(bounds),
                    child: Text(
                      l10n.profile,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                border: Border.all(color: colors.accentCyan, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: colors.accentCyan.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF1a1a2e),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User Name
            const Text(
              'Music Lover',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // User Email
            Text(
              'Enjoy your music!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  context,
                  l10n.songs,
                  '${musicService?.totalSongs ?? 0}',
                  Icons.music_note,
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongListScreen.library(),
                      ),
                    );
                  },
                ),
                _buildStatCard(
                  context,
                  l10n.favorites,
                  '${musicService?.totalFavorites ?? 0}',
                  Icons.favorite,
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongListScreen.favorites(),
                      ),
                    );
                  },
                ),
                _buildStatCard(
                  context,
                  l10n.playlists,
                  '${playlistService.totalPlaylists}',
                  Icons.playlist_play,
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlaylistsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Menu Items - User specific only
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: l10n.notifications,
                    subtitle: l10n.manageNotifications,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.security,
                    title: l10n.privacy,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: l10n.helpAndSupport,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final colors = ThemeProvider.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.accentCyan, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final colors = ThemeProvider.colorsOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (iconColor ?? colors.accentCyan).withOpacity(0.2),
          ),
          child: Icon(icon, color: iconColor ?? colors.accentCyan, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
