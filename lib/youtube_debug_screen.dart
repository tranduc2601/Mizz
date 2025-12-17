import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const YouTubeDebugApp());
}

class YouTubeDebugApp extends StatelessWidget {
  const YouTubeDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Audio Debug - Mizz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const YouTubeDebugScreen(),
    );
  }
}

/// Robust YouTube URL Handler - Downloads and plays audio
class YoutubeUrlHandler {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Download and return local file path for playback
  Future<String> downloadAudio(String originalUrl) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔍 EXTRACTING YOUTUBE AUDIO');
      debugPrint('📎 Input URL: $originalUrl');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Step 1: Get video info
      final video = await _yt.videos.get(originalUrl);
      debugPrint('📹 Video Title: ${video.title}');
      debugPrint('⏱️ Duration: ${video.duration}');

      // Step 2: Get stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final audioStreams = manifest.audioOnly.toList();

      debugPrint('📊 Total audio streams available: ${audioStreams.length}');

      // Debug: Print all available streams
      debugPrint('\n🎵 AVAILABLE AUDIO STREAMS:');
      for (var i = 0; i < audioStreams.length; i++) {
        final stream = audioStreams[i];
        debugPrint(
          '  [$i] Container: ${stream.container.name.toUpperCase()} | '
          'Bitrate: ${stream.bitrate} | '
          'Tag: ${stream.tag}',
        );
      }

      // Step 3: PRIORITY 1 - Find MP4/M4A stream
      AudioOnlyStreamInfo? selectedStream;

      try {
        selectedStream = audioStreams.firstWhere((stream) {
          final containerName = stream.container.name.toLowerCase();
          return containerName == 'mp4' || containerName == 'm4a';
        });

        debugPrint('\n✅ SUCCESS: Found MP4/M4A stream (PRIORITY 1)');
        debugPrint(
          '📦 Container: ${selectedStream.container.name.toUpperCase()}',
        );
        debugPrint('📊 Bitrate: ${selectedStream.bitrate}');
      } catch (e) {
        // Step 4: PRIORITY 2 - Fallback to highest bitrate
        debugPrint('\n⚠️ WARNING: No MP4/M4A stream found!');
        debugPrint('⚠️ Falling back to highest bitrate stream');

        selectedStream = manifest.audioOnly.withHighestBitrate();
        debugPrint(
          '📦 Fallback Container: ${selectedStream.container.name.toUpperCase()}',
        );
      }

      // Download to temp file
      final tempDir = await getTemporaryDirectory();
      final ext = selectedStream.container.name.toLowerCase();
      final tempFile = File('${tempDir.path}/yt_debug_${video.id.value}.$ext');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      debugPrint('📥 Downloading audio stream...');
      final stream = _yt.videos.streamsClient.get(selectedStream);
      final fileStream = tempFile.openWrite();

      await for (final chunk in stream) {
        fileStream.add(chunk);
      }

      await fileStream.flush();
      await fileStream.close();

      debugPrint('✅ Download complete: ${tempFile.path}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return tempFile.path;
    } catch (e) {
      debugPrint('❌ EXTRACTION FAILED: $e');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      rethrow;
    }
  }

  void dispose() {
    _yt.close();
  }
}

/// Debug Screen UI
class YouTubeDebugScreen extends StatefulWidget {
  const YouTubeDebugScreen({super.key});

  @override
  State<YouTubeDebugScreen> createState() => _YouTubeDebugScreenState();
}

class _YouTubeDebugScreenState extends State<YouTubeDebugScreen> {
  final TextEditingController _urlController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeUrlHandler _ytHandler = YoutubeUrlHandler();

  String _status = 'Ready to test';
  bool _isLoading = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Paste a test URL for quick testing
    _urlController.text = 'https://youtu.be/dQw4w9WgXcQ'; // Example

    // Listen to player state
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.playing) {
            _status = '✅ Playing successfully!';
          } else if (state.processingState == ProcessingState.completed) {
            _status = '✅ Playback completed';
            _isPlaying = false;
          }
        });
      }
    });

    // Listen to position
    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    // Listen to duration
    _audioPlayer.durationStream.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur ?? Duration.zero);
      }
    });
  }

  Future<void> _debugPlay() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      _showStatus('❌ Please enter a YouTube URL');
      return;
    }

    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      _showStatus('❌ Invalid YouTube URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '🔄 Downloading audio stream...';
    });

    try {
      // Step 1: Download audio
      final localPath = await _ytHandler.downloadAudio(url);

      setState(() => _status = '🎵 Playing from local file...');

      // Step 2: Play from local file
      await _audioPlayer.setFilePath(localPath);
      await _audioPlayer.play();

      setState(() {
        _isLoading = false;
        _status = '✅ Playing!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Error: ${e.toString()}';
      });

      debugPrint('❌ Playback Error: $e');
    }
  }

  void _showStatus(String message) {
    setState(() => _status = message);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _ytHandler.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 YouTube Audio Debug'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'MIZZ - YouTube Playback Debug',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Status Card
                Card(
                  color: Colors.white.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_isLoading)
                          const CircularProgressIndicator(
                            color: Colors.cyanAccent,
                          )
                        else
                          Icon(
                            _isPlaying
                                ? Icons.play_circle_filled
                                : Icons.stop_circle,
                            size: 48,
                            color: _isPlaying
                                ? Colors.greenAccent
                                : Colors.white54,
                          ),

                        const SizedBox(height: 12),

                        Text(
                          _status,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (_isPlaying) ...[
                          const SizedBox(height: 16),
                          Text(
                            '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // URL Input
                const Text(
                  'YouTube URL:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Paste YouTube link here',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.link,
                      color: Colors.cyanAccent,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Debug Play Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _debugPlay,
                  icon: const Icon(Icons.bug_report, size: 24),
                  label: const Text(
                    'DEBUG PLAY',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Playback Controls
                if (_isPlaying || _position > Duration.zero) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _audioPlayer.stop(),
                        icon: const Icon(Icons.stop),
                        color: Colors.white,
                        iconSize: 36,
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () {
                          if (_isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                        ),
                        color: Colors.cyanAccent,
                        iconSize: 64,
                      ),
                    ],
                  ),
                ],

                const Spacer(),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Debug Instructions:',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Paste a YouTube URL\n'
                        '2. Click "DEBUG PLAY"\n'
                        '3. Check the console logs\n'
                        '4. Using just_audio with local file download',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
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
