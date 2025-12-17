import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme.dart';
import '../theme_provider.dart';
import '../localization/app_localization.dart';
import '../update/github_update_manager.dart';

/// Settings Screen - Allows users to configure app preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GithubUpdateManager _updateManager = GithubUpdateManager();

  @override
  void initState() {
    super.initState();
    // Check for updates in background when screen loads
    _updateManager.addListener(_onUpdateStateChanged);
    _checkForUpdates();
  }

  @override
  void dispose() {
    _updateManager.removeListener(_onUpdateStateChanged);
    super.dispose();
  }

  void _onUpdateStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkForUpdates() async {
    await _updateManager.checkForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locController = LocalizationProvider.of(context);
    final colors = ThemeProvider.colorsOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.settings,
          style: TextStyle(color: colors.moonGlow, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.moonGlow),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
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

              // Updates Section
              _buildSectionHeader(context, l10n.updates),
              _buildUpdateCard(context, l10n),

              const SizedBox(height: 24),

              // Notifications Section
              _buildSectionHeader(context, l10n.notifications),
              _buildSettingCard(
                context,
                icon: Icons.notifications,
                title: l10n.notifications,
                subtitle: l10n.manageNotifications,
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
                },
              ),

              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader(context, l10n.about),
              _buildSettingCard(
                context,
                icon: Icons.info_outline,
                title: l10n.about,
                subtitle: '${l10n.appName} v${_updateManager.currentVersion.isEmpty ? "1.0.0" : _updateManager.currentVersion}',
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
    final colors = ThemeProvider.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.auroraGreen,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, AppLocalizations l10n) {
    final colors = ThemeProvider.colorsOf(context);
    final isUpdateAvailable = _updateManager.isUpdateAvailable;
    final isChecking = _updateManager.isCheckingUpdate;

    String subtitle;
    if (isChecking) {
      subtitle = l10n.checkingForUpdates;
    } else if (isUpdateAvailable) {
      subtitle = '${l10n.newVersionAvailable}: v${_updateManager.latestVersion}';
    } else {
      subtitle = '${l10n.currentVersion}: v${_updateManager.currentVersion.isEmpty ? "1.0.0" : _updateManager.currentVersion}';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleUpdateTap(context, l10n),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colors.nebulaPrimary.withOpacity(0.3),
                border: Border.all(
                  color: isUpdateAvailable
                      ? colors.stardustPink.withOpacity(0.5)
                      : colors.moonGlow.withOpacity(0.2),
                  width: isUpdateAvailable ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon with red dot badge
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.cosmicAccent.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isChecking
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.moonGlow,
                                ),
                              )
                            : Icon(Icons.system_update, color: colors.moonGlow, size: 24),
                      ),
                      // Red dot badge
                      if (isUpdateAvailable)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.deepSpace, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.checkForUpdates,
                              style: TextStyle(
                                color: colors.moonGlow,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isUpdateAvailable) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.stardustPink,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  l10n.newLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isUpdateAvailable
                                ? colors.stardustPink
                                : colors.moonGlow.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: isUpdateAvailable ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colors.moonGlow.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleUpdateTap(BuildContext context, AppLocalizations l10n) {
    final colors = ThemeProvider.colorsOf(context);

    if (_updateManager.isCheckingUpdate) {
      return; // Don't do anything while checking
    }

    if (_updateManager.isUpdateAvailable && _updateManager.latestRelease != null) {
      // Show update dialog with changelog
      _showUpdateDialog(context, l10n);
    } else {
      // Check again and show snackbar
      _updateManager.checkForUpdate().then((_) {
        if (mounted) {
          if (_updateManager.isUpdateAvailable) {
            _showUpdateDialog(context, l10n);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(l10n.youAreUpToDate),
                  ],
                ),
                backgroundColor: colors.auroraGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      });
    }
  }

  void _showUpdateDialog(BuildContext context, AppLocalizations l10n) {
    final colors = ThemeProvider.colorsOf(context);
    final release = _updateManager.latestRelease!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
              padding: const EdgeInsets.all(24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.auroraGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.system_update, color: colors.auroraGreen, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.updateAvailable,
                              style: TextStyle(
                                color: colors.moonGlow,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'v${release.version}',
                              style: TextStyle(
                                color: colors.auroraGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Changelog
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.deepSpace.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.whatsNew,
                            style: TextStyle(
                              color: colors.moonGlow,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            release.body,
                            style: TextStyle(
                              color: colors.moonGlow.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.later,
                            style: TextStyle(color: colors.moonGlow.withOpacity(0.7)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _startDownload(context, l10n);
                          },
                          icon: const Icon(Icons.download),
                          label: Text(l10n.updateNow),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.auroraGreen,
                            foregroundColor: colors.deepSpace,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startDownload(BuildContext context, AppLocalizations l10n) {
    final colors = ThemeProvider.colorsOf(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DownloadProgressDialog(
        updateManager: _updateManager,
        l10n: l10n,
        colors: colors,
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    AppLocalizations l10n,
    LocalizationController controller,
  ) {
    final colors = ThemeProvider.colorsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colors.nebulaPrimary.withOpacity(0.3),
            border: Border.all(
              color: colors.moonGlow.withOpacity(0.2),
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
    final colors = ThemeProvider.colorsOf(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: locale != AppLocale.values.last
                ? BorderSide(color: colors.moonGlow.withOpacity(0.1), width: 1)
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
                  color: colors.moonGlow,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // Checkmark
            if (isSelected)
              Icon(Icons.check_circle, color: colors.auroraGreen, size: 24)
            else
              Icon(
                Icons.circle_outlined,
                color: colors.moonGlow.withOpacity(0.3),
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
    final colors = ThemeProvider.colorsOf(context);
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
                color: colors.nebulaPrimary.withOpacity(0.3),
                border: Border.all(
                  color: colors.moonGlow.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.cosmicAccent.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: colors.moonGlow, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colors.moonGlow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: colors.moonGlow.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colors.moonGlow.withOpacity(0.5),
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
    final colors = ThemeProvider.colorsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colors.nebulaPrimary.withOpacity(0.3),
            border: Border.all(
              color: colors.moonGlow.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: AppThemeType.values.map((theme) {
              return _buildThemeOption(context, theme: theme, l10n: l10n);
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
    final colors = themeController.colors;
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
                ? BorderSide(color: colors.moonGlow.withOpacity(0.1), width: 1)
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
                  colors: [themeColors.nebulaPrimary, themeColors.cosmicAccent],
                ),
                border: Border.all(
                  color: isSelected
                      ? themeColors.accentCyan
                      : colors.moonGlow.withOpacity(0.2),
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
                  color: colors.moonGlow,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // Checkmark
            if (isSelected)
              Icon(Icons.check_circle, color: colors.auroraGreen, size: 24)
            else
              Icon(
                Icons.circle_outlined,
                color: colors.moonGlow.withOpacity(0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    final colors = ThemeProvider.colorsOf(context);
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
                    colors.nebulaPrimary.withOpacity(0.9),
                    colors.cosmicAccent.withOpacity(0.9),
                  ],
                ),
                border: Border.all(
                  color: colors.moonGlow.withOpacity(0.3),
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
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.music_note,
                      size: 80,
                      color: colors.moonGlow,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appName,
                    style: TextStyle(
                      color: colors.moonGlow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.version} ${_updateManager.currentVersion.isEmpty ? "1.0.0" : _updateManager.currentVersion}',
                    style: TextStyle(
                      color: colors.moonGlow.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.yourMusicYourWay,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.stardustPink,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.close,
                      style: TextStyle(color: colors.auroraGreen),
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

/// Download progress dialog
class _DownloadProgressDialog extends StatefulWidget {
  final GithubUpdateManager updateManager;
  final AppLocalizations l10n;
  final AppThemeColors colors;

  const _DownloadProgressDialog({
    required this.updateManager,
    required this.l10n,
    required this.colors,
  });

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;
  DownloadStatus _status = DownloadStatus.idle;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() {
    setState(() {
      _status = DownloadStatus.downloading;
      _progress = 0;
    });

    widget.updateManager.downloadAndInstallApk(
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }
      },
      onCompleted: () {
        if (mounted) {
          setState(() {
            _status = DownloadStatus.completed;
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _status = DownloadStatus.failed;
            _errorMessage = error;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                  widget.colors.nebulaPrimary.withOpacity(0.95),
                  widget.colors.cosmicAccent.withOpacity(0.95),
                ],
              ),
              border: Border.all(
                color: widget.colors.moonGlow.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                if (_status == DownloadStatus.downloading)
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 4,
                      backgroundColor: widget.colors.deepSpace.withOpacity(0.3),
                      color: widget.colors.accentCyan,
                    ),
                  )
                else if (_status == DownloadStatus.completed)
                  Icon(Icons.check_circle, color: widget.colors.auroraGreen, size: 60)
                else if (_status == DownloadStatus.failed)
                  const Icon(Icons.error, color: Colors.red, size: 60),

                const SizedBox(height: 20),

                // Title
                Text(
                  _getTitle(),
                  style: TextStyle(
                    color: widget.colors.moonGlow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Progress or message
                if (_status == DownloadStatus.downloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: widget.colors.deepSpace.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.colors.accentCyan),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: widget.colors.accentCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else if (_status == DownloadStatus.completed) ...[
                  Text(
                    widget.l10n.openingInstaller,
                    style: TextStyle(color: widget.colors.moonGlow.withOpacity(0.7)),
                  ),
                ] else if (_status == DownloadStatus.failed) ...[
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(widget.l10n.close),
                      ),
                      ElevatedButton(
                        onPressed: _startDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.colors.accentCyan,
                        ),
                        child: Text(widget.l10n.retry),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_status) {
      case DownloadStatus.downloading:
        return widget.l10n.downloading;
      case DownloadStatus.completed:
        return widget.l10n.downloadComplete;
      case DownloadStatus.failed:
        return widget.l10n.downloadFailed;
      default:
        return widget.l10n.downloading;
    }
  }
}
