import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme.dart';
import '../theme_provider.dart';
import '../localization/app_localization.dart';

/// Settings Screen - Allows users to configure app preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locController = LocalizationProvider.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.settings,
          style: const TextStyle(
            color: GalaxyTheme.moonGlow,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GalaxyTheme.moonGlow),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: GalaxyTheme.galaxyGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Language Section
              _buildSectionHeader(context, l10n.language),
              _buildLanguageCard(context, l10n, locController),

              const SizedBox(height: 24),

              // Theme Section
              _buildSectionHeader(context, l10n.theme),
              _buildThemeSelector(context, l10n),

              const SizedBox(height: 24),

              // Notifications Section
              _buildSectionHeader(context, l10n.notifications),
              _buildSettingCard(
                context,
                icon: Icons.notifications,
                title: l10n.notifications,
                subtitle: 'Manage notification preferences',
                onTap: () {
                  // TODO: Implement notifications settings
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
                },
              ),

              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader(context, l10n.about),
              _buildSettingCard(
                context,
                icon: Icons.info_outline,
                title: l10n.about,
                subtitle: 'Mizz v1.0.0',
                onTap: () {
                  _showAboutDialog(context, l10n);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: GalaxyTheme.auroraGreen,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    AppLocalizations l10n,
    LocalizationController controller,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: GalaxyTheme.nebulaPurple.withOpacity(0.3),
            border: Border.all(
              color: GalaxyTheme.moonGlow.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              for (final locale in AppLocale.values)
                _buildLanguageOption(
                  context,
                  locale: locale,
                  isSelected: controller.locale == locale,
                  onTap: () {
                    controller.setLocale(locale);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required AppLocale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: locale != AppLocale.values.last
                ? BorderSide(
                    color: GalaxyTheme.moonGlow.withOpacity(0.1),
                    width: 1,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Flag icon
            Text(
              locale == AppLocale.vietnamese ? '🇻🇳' : '🇺🇸',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            // Language name
            Expanded(
              child: Text(
                locale.displayName,
                style: TextStyle(
                  color: GalaxyTheme.moonGlow,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // Checkmark
            if (isSelected)
              Icon(Icons.check_circle, color: GalaxyTheme.auroraGreen, size: 24)
            else
              Icon(
                Icons.circle_outlined,
                color: GalaxyTheme.moonGlow.withOpacity(0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: GalaxyTheme.nebulaPurple.withOpacity(0.3),
                border: Border.all(
                  color: GalaxyTheme.moonGlow.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GalaxyTheme.cosmicViolet.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: GalaxyTheme.moonGlow, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: GalaxyTheme.moonGlow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: GalaxyTheme.moonGlow.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: GalaxyTheme.moonGlow.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: GalaxyTheme.nebulaPurple.withOpacity(0.3),
            border: Border.all(
              color: GalaxyTheme.moonGlow.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: AppThemeType.values.map((theme) {
              return _buildThemeOption(
                context,
                theme: theme,
                l10n: l10n,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required AppThemeType theme,
    required AppLocalizations l10n,
  }) {
    // Get the current selected theme
    final themeController = ThemeProvider.of(context);
    final isSelected = themeController.themeType == theme;
    final themeColors = AppThemeColors.fromType(theme);

    return InkWell(
      onTap: () {
        themeController.setTheme(theme);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: theme != AppThemeType.values.last
                ? BorderSide(
                    color: GalaxyTheme.moonGlow.withOpacity(0.1),
                    width: 1,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Color preview
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    themeColors.nebulaPrimary,
                    themeColors.cosmicAccent,
                  ],
                ),
                border: Border.all(
                  color: isSelected 
                      ? themeColors.accentCyan 
                      : GalaxyTheme.moonGlow.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Theme name
            Expanded(
              child: Text(
                l10n.locale == AppLocale.vietnamese
                    ? theme.nameVi
                    : theme.nameEn,
                style: TextStyle(
                  color: GalaxyTheme.moonGlow,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // Checkmark
            if (isSelected)
              Icon(Icons.check_circle, color: GalaxyTheme.auroraGreen, size: 24)
            else
              Icon(
                Icons.circle_outlined,
                color: GalaxyTheme.moonGlow.withOpacity(0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/Mizz.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mizz',
                    style: TextStyle(
                      color: GalaxyTheme.moonGlow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: GalaxyTheme.moonGlow.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.yourMusicYourWay,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GalaxyTheme.stardustPink,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.close,
                      style: const TextStyle(color: GalaxyTheme.auroraGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
