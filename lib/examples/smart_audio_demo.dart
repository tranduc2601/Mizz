import 'package:flutter/material.dart';
import '../core/smart_audio_handler.dart';
import '../core/theme.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
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
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a YouTube URL')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Audio Handler Demo'),
        backgroundColor: GalaxyTheme.deepSpace,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GalaxyTheme.deepSpace,
              GalaxyTheme.cosmicPurple.withOpacity(0.3),
            ],
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
                              color: GalaxyTheme.cyberpunkCyan.withOpacity(0.2),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: GalaxyTheme.cyberpunkCyan,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Loading audio...',
                                    style: TextStyle(
                                      color: GalaxyTheme.moonGlow,
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
                        _audioHandler.currentTitle ?? 'No track loaded';
                    return Card(
                      color: GalaxyTheme.deepSpace.withOpacity(0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              state == PlayerState.playing
                                  ? Icons.music_note
                                  : Icons.music_off,
                              size: 48,
                              color: GalaxyTheme.cyberpunkPink,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                color: GalaxyTheme.moonGlow,
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
                                  ? 'Playing'
                                  : state == PlayerState.paused
                                  ? 'Paused'
                                  : 'Stopped',
                              style: TextStyle(
                                color: GalaxyTheme.moonGlow.withOpacity(0.7),
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
                                activeTrackColor: GalaxyTheme.cyberpunkCyan,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: GalaxyTheme.cyberpunkPink,
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
                                    style: const TextStyle(
                                      color: GalaxyTheme.moonGlow,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: GalaxyTheme.moonGlow,
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
                          color: GalaxyTheme.moonGlow,
                          iconSize: 32,
                        ),
                        const SizedBox(width: 20),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                GalaxyTheme.cyberpunkPink,
                                GalaxyTheme.cyberpunkCyan,
                              ],
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
                const Divider(color: Colors.white24),
                const SizedBox(height: 20),

                // YouTube URL Input
                Text(
                  'Play YouTube Link',
                  style: TextStyle(
                    color: GalaxyTheme.moonGlow.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: GalaxyTheme.moonGlow),
                  decoration: InputDecoration(
                    hintText: 'Paste YouTube URL here',
                    hintStyle: TextStyle(
                      color: GalaxyTheme.moonGlow.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.link,
                      color: GalaxyTheme.auroraGreen,
                    ),
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
                  label: const Text('Play YouTube Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GalaxyTheme.auroraGreen,
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
                  label: const Text('Pick Local Audio File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GalaxyTheme.cyberpunkCyan,
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
