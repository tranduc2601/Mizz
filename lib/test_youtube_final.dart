import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const YouTubeFinalTestApp());
}

class YouTubeFinalTestApp extends StatelessWidget {
  const YouTubeFinalTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Final Test - Mizz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const YouTubeFinalTestScreen(),
    );
  }
}

/// Robust YouTube URL Handler with MP4/M4A priority
class YoutubeUrlHandler {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Extract playable audio stream info and download to temp file
  /// This method downloads the audio to avoid 403 errors from YouTube
  Future<String> downloadAndGetAudioPath(
    String originalUrl, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔍 EXTRACTING YOUTUBE AUDIO');
      debugPrint('📎 Input URL: $originalUrl');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Get video info
      final video = await _yt.videos.get(originalUrl);
      debugPrint('📹 Video Title: ${video.title}');
      debugPrint('⏱️ Duration: ${video.duration}');

      // Get stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final audioStreams = manifest.audioOnly.toList();

      debugPrint('📊 Total audio streams: ${audioStreams.length}');

      // Print all available streams
      debugPrint('\n🎵 AVAILABLE STREAMS:');
      for (var i = 0; i < audioStreams.length; i++) {
        final stream = audioStreams[i];
        debugPrint(
          '  [$i] ${stream.container.name.toUpperCase()} | '
          '${stream.bitrate} | Tag: ${stream.tag}',
        );
      }

      // PRIORITY 1: Find MP4/M4A stream (best compatibility)
      AudioOnlyStreamInfo? selectedStream;

      try {
        selectedStream = audioStreams.firstWhere((stream) {
          final containerName = stream.container.name.toLowerCase();
          return containerName == 'mp4' || containerName == 'm4a';
        });

        debugPrint('\n✅ FOUND MP4/M4A STREAM (PRIORITY 1)');
        debugPrint(
          '📦 Container: ${selectedStream.container.name.toUpperCase()}',
        );
        debugPrint('📊 Bitrate: ${selectedStream.bitrate}');
        debugPrint('🏷️ Tag: ${selectedStream.tag}');
      } catch (e) {
        // PRIORITY 2: Fallback to highest bitrate
        debugPrint('\n⚠️ NO MP4/M4A FOUND - USING FALLBACK');
        selectedStream = manifest.audioOnly.withHighestBitrate();
        debugPrint(
          '📦 Fallback: ${selectedStream.container.name.toUpperCase()}',
        );
      }

      // Download the audio stream to temp file to avoid 403 errors
      debugPrint('📥 Downloading audio stream...');

      final tempDir = await getTemporaryDirectory();
      final extension = selectedStream.container.name.toLowerCase();
      final fileName = '${video.id.value}.$extension';
      final tempFile = File('${tempDir.path}/$fileName');

      // Delete old file if exists
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Get the stream and download
      final stream = _yt.videos.streamsClient.get(selectedStream);
      final fileStream = tempFile.openWrite();

      final totalBytes = selectedStream.size.totalBytes;
      var downloadedBytes = 0;

      await for (final chunk in stream) {
        fileStream.add(chunk);
        downloadedBytes += chunk.length;

        if (onProgress != null && totalBytes > 0) {
          final progress = downloadedBytes / totalBytes;
          onProgress(progress);
        }
      }

      await fileStream.flush();
      await fileStream.close();

      debugPrint('✅ Download complete: ${tempFile.path}');
      debugPrint(
        '📁 File size: ${(downloadedBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return tempFile.path;
    } catch (e) {
      debugPrint('❌ EXTRACTION/DOWNLOAD FAILED: $e');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      rethrow;
    }
  }

  void dispose() {
    _yt.close();
  }
}

/// Final Test Screen UI
class YouTubeFinalTestScreen extends StatefulWidget {
  const YouTubeFinalTestScreen({super.key});

  @override
  State<YouTubeFinalTestScreen> createState() => _YouTubeFinalTestScreenState();
}

class _YouTubeFinalTestScreenState extends State<YouTubeFinalTestScreen> {
  final TextEditingController _urlController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeUrlHandler _ytHandler = YoutubeUrlHandler();
  final List<String> _logs = [];

  String _status = 'Ready to test';
  bool _isLoading = false;
  double _downloadProgress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Pre-fill test URL
    _urlController.text = 'https://youtu.be/dQw4w9WgXcQ';

    // Listen to player state
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          if (state.playing) {
            _status = '✅ PLAYING SUCCESSFULLY!';
            _addLog('✅ Playback started');
          } else if (state.processingState == ProcessingState.completed) {
            _status = '✅ Playback completed';
            _addLog('✅ Playback completed');
          } else if (state.processingState == ProcessingState.buffering) {
            _status = '⏳ Buffering...';
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
      if (mounted && dur != null) {
        setState(() => _duration = dur);
      }
    });
  }

  void _addLog(String message) {
    if (mounted) {
      setState(() {
        _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
        // Keep only last 20 logs
        if (_logs.length > 20) {
          _logs.removeAt(0);
        }
      });
    }
  }

  Future<void> _testPlay() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      _showStatus('❌ Enter a YouTube URL');
      return;
    }

    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      _showStatus('❌ Invalid YouTube URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '🔄 Extracting stream...';
      _downloadProgress = 0.0;
      _logs.clear();
    });

    _addLog('🔍 Starting extraction...');

    try {
      // Step 1: Download audio to temp file (avoids 403 errors)
      _addLog('📡 Fetching video metadata...');

      final audioPath = await _ytHandler.downloadAndGetAudioPath(
        url,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
            _status = '📥 Downloading: ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      _addLog('✅ Download complete');
      _addLog('📁 Local path: $audioPath');

      setState(() => _status = '🎵 Initializing player...');

      // Step 2: Play from local file (100% reliable)
      await _audioPlayer.setFilePath(audioPath);

      _addLog('✅ Audio source set');
      _addLog('▶️ Starting playback...');

      await _audioPlayer.play();

      setState(() {
        _isLoading = false;
        _status = '✅ PLAYING!';
      });

      _addLog('🎉 SUCCESS - Audio is playing!');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Error: ${e.toString()}';
      });

      _addLog('❌ ERROR: $e');
      debugPrint('❌ Playback Error: $e');
    }
  }

  void _showStatus(String message) {
    setState(() => _status = message);
    _addLog(message);
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
    final isPlaying = _audioPlayer.playerState.playing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 YouTube Final Test'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Card(
                  color: Colors.white.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoading) ...[
                          if (_downloadProgress > 0)
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                    value: _downloadProgress,
                                    color: Colors.cyanAccent,
                                    strokeWidth: 4,
                                  ),
                                ),
                                Text(
                                  '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            const CircularProgressIndicator(
                              color: Colors.cyanAccent,
                            ),
                        ] else
                          Icon(
                            isPlaying
                                ? Icons.play_circle_filled
                                : Icons.stop_circle,
                            size: 48,
                            color: isPlaying
                                ? Colors.greenAccent
                                : Colors.white54,
                          ),

                        const SizedBox(height: 12),

                        Text(
                          _status,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (isPlaying) ...[
                          const SizedBox(height: 8),
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

                const SizedBox(height: 16),

                // URL Input
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'YouTube URL',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.link,
                      color: Colors.tealAccent,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Test Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testPlay,
                  icon: const Icon(Icons.play_arrow, size: 24),
                  label: const Text(
                    'TEST PLAY',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Playback Controls
                if (isPlaying ||
                    _audioPlayer.playerState.processingState !=
                        ProcessingState.idle)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _audioPlayer.stop(),
                        icon: const Icon(Icons.stop),
                        color: Colors.white,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          if (isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                        ),
                        color: Colors.tealAccent,
                        iconSize: 56,
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Logs Section (FIXED OVERFLOW)
                const Text(
                  'Logs:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: _logs.isEmpty
                        ? const Center(
                            child: Text(
                              'No logs yet',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  _logs[index],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            },
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
