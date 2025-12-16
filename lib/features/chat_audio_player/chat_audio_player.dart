import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// ChatAudioPlayer - Local audio file picker and player widget
/// Similar to how Gemini/ChatGPT handles file attachments
///
/// Usage:
/// ```dart
/// ChatAudioPlayer(
///   onFileSelected: (String? path, String? name) {
///     print('Selected: $name at $path');
///   },
/// )
/// ```
class ChatAudioPlayer extends StatefulWidget {
  /// Callback when a file is selected (path, fileName)
  final void Function(String? path, String? fileName)? onFileSelected;

  /// Initial file path (if already have a file)
  final String? initialFilePath;

  /// Primary color for the player
  final Color primaryColor;

  /// Background color for the container
  final Color backgroundColor;

  const ChatAudioPlayer({
    super.key,
    this.onFileSelected,
    this.initialFilePath,
    this.primaryColor = Colors.teal,
    this.backgroundColor = const Color(0xFF1E1E2E),
  });

  @override
  State<ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<ChatAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State
  String? _filePath;
  String? _fileName;
  bool _isLoading = false;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Initialize with existing file if provided
    if (widget.initialFilePath != null) {
      _filePath = widget.initialFilePath;
      _fileName = widget.initialFilePath!.split('/').last;
    }

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
    });

    // Listen for completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Request necessary permissions for Android 13+
  Future<bool> _requestPermissions() async {
    // Android 13+ (API 33+) uses READ_MEDIA_AUDIO
    // Older versions use READ_EXTERNAL_STORAGE

    if (Platform.isAndroid) {
      // Try audio permission first (Android 13+)
      if (await Permission.audio.request().isGranted) {
        return true;
      }

      // Fallback to storage permission (older Android)
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      // Check if permanently denied
      if (await Permission.audio.isPermanentlyDenied ||
          await Permission.storage.isPermanentlyDenied) {
        _showPermissionDialog();
        return false;
      }

      return false;
    }

    return true; // iOS and other platforms
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.backgroundColor,
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Audio file access permission is required to select music files. '
          'Please enable it in Settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: widget.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Pick audio file from local storage
  Future<void> _pickAudioFile() async {
    setState(() => _isLoading = true);

    try {
      // Request permissions first
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      // Open file picker with custom extensions (more reliable than FileType.audio)
      // FileType.audio can fail on some Android devices with "invalid_format_type"
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'wav',
          'aac',
          'm4a',
          'ogg',
          'flac',
          'wma',
          'opus',
          'webm',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // CRITICAL: On Android, use the cached path for reliable playback
        // file.path contains the cached copy path that audioplayers can access
        String? filePath = file.path;

        if (filePath != null) {
          // Stop any current playback
          await _audioPlayer.stop();

          setState(() {
            _filePath = filePath;
            _fileName = file.name;
            _position = Duration.zero;
            _duration = Duration.zero;
          });

          // Notify parent
          widget.onFileSelected?.call(filePath, file.name);

          debugPrint('📁 Selected file: $_fileName');
          debugPrint('📂 Path: $_filePath');
        }
      }
    } catch (e) {
      debugPrint('❌ File picker error: $e');
      _showError('Failed to pick file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Play/Pause toggle
  Future<void> _togglePlayPause() async {
    if (_filePath == null) {
      _showError('No file selected');
      return;
    }

    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        // Use DeviceFileSource for local files
        await _audioPlayer.play(DeviceFileSource(_filePath!));
      }
    } catch (e) {
      debugPrint('❌ Playback error: $e');
      _showError('Playback failed: $e');
    }
  }

  /// Stop playback
  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
    });
  }

  /// Seek to position
  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final hasFile = _filePath != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: File info + Pick button
          Row(
            children: [
              // File icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasFile ? Icons.audio_file : Icons.music_note,
                  color: widget.primaryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // File name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasFile ? _fileName! : 'No file selected',
                      style: TextStyle(
                        color: hasFile ? Colors.white : Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasFile && _duration.inSeconds > 0)
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Pick file button
              _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.primaryColor,
                      ),
                    )
                  : IconButton(
                      onPressed: _pickAudioFile,
                      icon: Icon(
                        hasFile ? Icons.folder_open : Icons.add_circle_outline,
                        color: widget.primaryColor,
                      ),
                      tooltip: 'Select audio file',
                    ),
            ],
          ),

          // Player controls (only show if file is selected)
          if (hasFile) ...[
            const SizedBox(height: 16),

            // Progress slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: widget.primaryColor,
                inactiveTrackColor: widget.primaryColor.withOpacity(0.2),
                thumbColor: widget.primaryColor,
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds.toDouble().clamp(
                        0,
                        _duration.inMilliseconds.toDouble(),
                      )
                    : 0,
                max: _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1,
                onChanged: (value) {
                  _seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),

            // Time labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stop button
                IconButton(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_rounded),
                  color: Colors.white70,
                  iconSize: 32,
                ),

                const SizedBox(width: 16),

                // Play/Pause button (main)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.primaryColor,
                        widget.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    color: Colors.white,
                    iconSize: 40,
                    padding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(width: 16),

                // Replay button (seek to start)
                IconButton(
                  onPressed: () => _seek(Duration.zero),
                  icon: const Icon(Icons.replay_rounded),
                  color: Colors.white70,
                  iconSize: 32,
                ),
              ],
            ),
          ],

          // Prompt to select file (only show if no file)
          if (!hasFile) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAudioFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Audio File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
