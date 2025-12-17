import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../core/localization/app_localization.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../music_carousel/music_service.dart';
import 'profile_edit_screen.dart';

/// Enhanced User Profile Widget with Real Data
class UserProfileViewEnhanced extends StatelessWidget {
  final AuthService authService;
  final MusicService? musicService;

  const UserProfileViewEnhanced({
    super.key,
    required this.authService,
    this.musicService,
  });

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final colors = ThemeProvider.colorsOf(context);
    final l10n = AppLocalizations.of(context);

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
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileEditScreen(authService: authService),
                  ),
                );
              },
              child: Stack(
                children: [
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
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: colors.cosmicAccent,
                      backgroundImage: _getAvatarImage(user?.avatarUrl),
                      child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [colors.accentPink, colors.accentCyan],
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // User Name
            Text(
              user?.name ?? 'Music Lover',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // User Email
            Text(
              user?.email ?? 'user@galaxy.com',
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
                ),
                _buildStatCard(
                  context,
                  l10n.favorites,
                  '${musicService?.totalFavorites ?? 0}',
                  Icons.favorite,
                ),
                _buildStatCard(
                  context,
                  l10n.playlists,
                  '0',
                  Icons.playlist_play,
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
                    icon: Icons.person,
                    title: l10n.editProfile,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileEditScreen(authService: authService),
                        ),
                      );
                    },
                  ),
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
                  const Divider(color: Colors.white24, height: 30),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: l10n.logout,
                    iconColor: Colors.red,
                    onTap: () async {
                      await authService.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) =>
                                LoginScreen(authService: authService),
                          ),
                          (route) => false,
                        );
                      }
                    },
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
    IconData icon,
  ) {
    final colors = ThemeProvider.colorsOf(context);
    return Container(
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
    );
  }

  /// Helper to get avatar image from path (handles both local files and URLs)
  ImageProvider? _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    // Check if it's a network URL
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return NetworkImage(avatarUrl);
    }

    // It's a local file path
    final file = File(avatarUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return null;
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
