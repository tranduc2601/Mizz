import 'package:flutter/material.dart';
import '../core/smart_audio_handler.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../core/localization/app_localization.dart';

/// Demo UI for SmartAudioHandler
/// Shows how to use the universal audio player with buttons and loading indicator
class SmartAudioDemo extends StatefulWidget {
  const SmartAudioDemo({super.key});

  @override
  State<SmartAudioDemo> createState() => _SmartAudioDemoState();
}

class _SmartAudioDemoState extends State<SmartAudioDemo> {
  late SmartAudioHandler _audioHandler;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioHandler = SmartAudioHandler();

    // Listen to loading state changes
    _audioHandler.isLoading.addListener(_onLoadingChanged);
    _audioHandler.errorMessage.addListener(_onErrorChanged);
  }

  void _onLoadingChanged() {
    if (mounted) setState(() {});
  }

  void _onErrorChanged() {
    final error = _audioHandler.errorMessage.value;
    if (error != null && mounted) {
      final colors = ThemeProvider.colorsOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: colors.accentPink,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioHandler.isLoading.removeListener(_onLoadingChanged);
    _audioHandler.errorMessage.removeListener(_onErrorChanged);
    _audioHandler.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _playYouTubeLink() async {
    final url = _urlController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pasteYouTubeUrl)));
      return;
    }

    try {
      await _audioHandler.playInput(url);
    } catch (e) {
      // Error already handled by SmartAudioHandler
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.colorsOf(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smartAudioDemo),
        backgroundColor: colors.deepSpace,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.deepSpace, colors.cosmicAccent.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Loading Indicator
                ValueListenableBuilder<bool>(
                  valueListenable: _audioHandler.isLoading,
                  builder: (context, isLoading, _) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: isLoading ? 60 : 0,
                      child: isLoading
                          ? Card(
                              color: colors.accentCyan.withOpacity(0.2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.accentCyan,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    l10n.loadingAudio,
                                    style: TextStyle(
                                      color: colors.moonGlow,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Current Track Info
                ValueListenableBuilder(
                  valueListenable: _audioHandler.playerState,
                  builder: (context, state, _) {
                    final title =
                        _audioHandler.currentTitle ?? l10n.noTrackLoaded;
                    return Card(
                      color: colors.deepSpace.withOpacity(0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              state == PlayerState.playing
                                  ? Icons.music_note
                                  : Icons.music_off,
                              size: 48,
                              color: colors.accentPink,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: TextStyle(
                                color: colors.moonGlow,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state == PlayerState.playing
                                  ? l10n.playing
                                  : state == PlayerState.paused
                                  ? l10n.paused
                                  : l10n.stopped,
                              style: TextStyle(
                                color: colors.moonGlow.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Progress Bar
                ValueListenableBuilder(
                  valueListenable: _audioHandler.position,
                  builder: (context, position, _) {
                    return ValueListenableBuilder(
                      valueListenable: _audioHandler.duration,
                      builder: (context, duration, _) {
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: colors.accentCyan,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: colors.accentPink,
                              ),
                              child: Slider(
                                value: progress.clamp(0.0, 1.0),
                                onChanged: (value) {
                                  final newPosition = Duration(
                                    milliseconds:
                                        (value * duration.inMilliseconds)
                                            .toInt(),
                                  );
                                  _audioHandler.seek(newPosition);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: TextStyle(
                                      color: colors.moonGlow,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(
                                      color: colors.moonGlow,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Playback Controls
                ValueListenableBuilder(
                  valueListenable: _audioHandler.playerState,
                  builder: (context, state, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _audioHandler.stop(),
                          icon: const Icon(Icons.stop),
                          color: colors.moonGlow,
                          iconSize: 32,
                        ),
                        const SizedBox(width: 20),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [colors.accentPink, colors.accentCyan],
                            ),
                          ),
                          child: IconButton(
                            onPressed: state == PlayerState.playing
                                ? () => _audioHandler.pause()
                                : () => _audioHandler.resume(),
                            icon: Icon(
                              state == PlayerState.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            color: Colors.white,
                            iconSize: 40,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),
                Divider(color: colors.moonGlow.withOpacity(0.2)),
                const SizedBox(height: 20),

                // YouTube URL Input
                Text(
                  l10n.playYouTubeLink,
                  style: TextStyle(
                    color: colors.moonGlow.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  style: TextStyle(color: colors.moonGlow),
                  decoration: InputDecoration(
                    hintText: l10n.pasteYouTubeUrl,
                    hintStyle: TextStyle(
                      color: colors.moonGlow.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(Icons.link, color: colors.auroraGreen),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Play YouTube Button
                ElevatedButton.icon(
                  onPressed: _audioHandler.isLoading.value
                      ? null
                      : _playYouTubeLink,
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(l10n.playYouTubeLink),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.auroraGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Pick File Button
                ElevatedButton.icon(
                  onPressed: _audioHandler.isLoading.value
                      ? null
                      : () => _audioHandler.pickAndPlayLocalFile(),
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.pickLocalFile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
