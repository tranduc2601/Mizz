import 'package:flutter/material.dart';
import '../core/background_audio_handler.dart';
import '../core/theme.dart';

/// Demo UI for BackgroundAudioHandler
/// Shows how to use the audio player with notification controls
class BackgroundAudioDemo extends StatefulWidget {
  const BackgroundAudioDemo({super.key});

  @override
  State<BackgroundAudioDemo> createState() => _BackgroundAudioDemoState();
}

class _BackgroundAudioDemoState extends State<BackgroundAudioDemo> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Listen to loading state changes
    audioHandler.isLoading.addListener(_onLoadingChanged);
    audioHandler.errorMessage.addListener(_onErrorChanged);
  }

  void _onLoadingChanged() {
    if (mounted) setState(() {});
  }

  void _onErrorChanged() {
    final error = audioHandler.errorMessage.value;
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
    audioHandler.isLoading.removeListener(_onLoadingChanged);
    audioHandler.errorMessage.removeListener(_onErrorChanged);
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
      await audioHandler.playInput(url);
    } catch (e) {
      // Error already handled by audioHandler
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
        title: const Text('Background Audio Demo'),
        backgroundColor: GalaxyTheme.deepSpace,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GalaxyTheme.deepSpace,
              GalaxyTheme.cosmicPurple.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Feature badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        GalaxyTheme.cyberpunkPink,
                        GalaxyTheme.cyberpunkCyan,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Background Playback + Notification Controls',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Loading Indicator
                ValueListenableBuilder<bool>(
                  valueListenable: audioHandler.isLoading,
                  builder: (context, isLoading, _) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: isLoading ? 60 : 0,
                      child: isLoading
                          ? Card(
                              color: GalaxyTheme.cyberpunkCyan.withValues(
                                alpha: 0.2,
                              ),
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
                StreamBuilder<bool>(
                  stream: audioHandler.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    final title =
                        audioHandler.currentTitle ?? 'No track loaded';
                    return Card(
                      color: GalaxyTheme.deepSpace.withValues(alpha: 0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              isPlaying ? Icons.music_note : Icons.music_off,
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
                              isPlaying ? '▶ Playing' : '⏸ Paused',
                              style: TextStyle(
                                color: GalaxyTheme.moonGlow.withValues(
                                  alpha: 0.7,
                                ),
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
                StreamBuilder<PositionData>(
                  stream: audioHandler.positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;
                    final position = positionData?.position ?? Duration.zero;
                    final duration = positionData?.duration ?? Duration.zero;
                    final buffered =
                        positionData?.bufferedPosition ?? Duration.zero;

                    final progress = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;
                    final bufferedProgress = duration.inMilliseconds > 0
                        ? buffered.inMilliseconds / duration.inMilliseconds
                        : 0.0;

                    return Column(
                      children: [
                        Stack(
                          children: [
                            // Buffered progress
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white24,
                                inactiveTrackColor: Colors.white12,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 0,
                                ),
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                value: bufferedProgress.clamp(0.0, 1.0),
                                onChanged: null,
                              ),
                            ),
                            // Playback progress
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: GalaxyTheme.cyberpunkCyan,
                                inactiveTrackColor: Colors.transparent,
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
                                  audioHandler.seek(newPosition);
                                },
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ),

                const SizedBox(height: 20),

                // Playback Controls
                StreamBuilder<bool>(
                  stream: audioHandler.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Previous (placeholder)
                        IconButton(
                          onPressed: () => audioHandler.skipToPrevious(),
                          icon: const Icon(Icons.skip_previous),
                          color: GalaxyTheme.moonGlow.withValues(alpha: 0.5),
                          iconSize: 32,
                        ),
                        const SizedBox(width: 12),

                        // Stop
                        IconButton(
                          onPressed: () => audioHandler.stop(),
                          icon: const Icon(Icons.stop),
                          color: GalaxyTheme.moonGlow,
                          iconSize: 32,
                        ),
                        const SizedBox(width: 12),

                        // Play/Pause
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                GalaxyTheme.cyberpunkPink,
                                GalaxyTheme.cyberpunkCyan,
                              ],
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => audioHandler.togglePlayPause(),
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            color: Colors.white,
                            iconSize: 40,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Next (placeholder)
                        IconButton(
                          onPressed: () => audioHandler.skipToNext(),
                          icon: const Icon(Icons.skip_next),
                          color: GalaxyTheme.moonGlow.withValues(alpha: 0.5),
                          iconSize: 32,
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
                    color: GalaxyTheme.moonGlow.withValues(alpha: 0.8),
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
                      color: GalaxyTheme.moonGlow.withValues(alpha: 0.5),
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
                  onPressed: audioHandler.isLoading.value
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

                const SizedBox(height: 16),

                // Pick File Button
                ElevatedButton.icon(
                  onPressed: audioHandler.isLoading.value
                      ? null
                      : () => audioHandler.pickAndPlayLocalFile(),
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
