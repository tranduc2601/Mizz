import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Smart Audio Handler - Universal audio player for YouTube, URLs, and local files
class SmartAudioHandler extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  // State management
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<PlayerState> playerState = ValueNotifier<PlayerState>(
    PlayerState.stopped,
  );
  final ValueNotifier<Duration> position = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<Duration> duration = ValueNotifier<Duration>(
    Duration.zero,
  );

  String? _currentSource;
  String? _currentTitle;

  SmartAudioHandler() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      playerState.value = state;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      position.value = pos;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      duration.value = dur;
      notifyListeners();
    });
  }

  // Getters
  bool get isPlaying => playerState.value == PlayerState.playing;
  String? get currentSource => _currentSource;
  String? get currentTitle => _currentTitle;

  /// Universal play function - automatically detects input type
  Future<void> playInput(String input, {String? title}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      _currentTitle = title;
      _currentSource = input;

      // Case A: YouTube URL
      if (input.contains('youtube.com') || input.contains('youtu.be')) {
        await _playYouTubeAudio(input);
      }
      // Case B: Direct HTTP/HTTPS URL
      else if (input.startsWith('http://') || input.startsWith('https://')) {
        await _playDirectUrl(input);
      }
      // Case C: Local file path
      else {
        await _playLocalFile(input);
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Playback error: ${e.toString()}';
      debugPrint('❌ SmartAudioHandler Error: $e');
      rethrow;
    }
  }

  /// Case A: Extract and play YouTube audio stream
  /// Downloads audio to temp file to avoid 403 errors from YouTube
  Future<void> _playYouTubeAudio(String youtubeUrl) async {
    try {
      debugPrint('🎵 Extracting YouTube audio from: $youtubeUrl');

      // Get video metadata
      final video = await _youtubeExplode.videos.get(youtubeUrl);
      _currentTitle ??= video.title;

      // Get audio-only stream manifest
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(
        video.id,
      );

      // CRITICAL FIX: Prefer MP4/M4A streams to avoid 403 errors and codec issues
      // WebM/Opus streams often fail with 403 or playback errors on Android
      AudioOnlyStreamInfo? audioStream;

      try {
        // First, try to find MP4 or M4A audio stream (tag 140 usually)
        audioStream = manifest.audioOnly.firstWhere(
          (stream) =>
              stream.container.name.toLowerCase() == 'mp4' ||
              stream.container.name.toLowerCase() == 'm4a',
        );

        debugPrint(
          '✅ Found MP4/M4A audio stream (Container: ${audioStream.container.name})',
        );
      } catch (e) {
        // Fallback: Use highest bitrate if no MP4 found
        debugPrint(
          '⚠️ No MP4/M4A stream available, falling back to highest bitrate',
        );
        debugPrint(
          '⚠️ Warning: WebM streams may cause 403 errors or playback issues',
        );
        audioStream = manifest.audioOnly.withHighestBitrate();
      }

      debugPrint('📦 Container: ${audioStream.container.name}');
      debugPrint('🎼 Codec: ${audioStream.audioCodec}');
      debugPrint('📊 Bitrate: ${audioStream.bitrate}');
      debugPrint('🏷️ Tag: ${audioStream.tag}');

      // Download to temp file to avoid 403 errors
      debugPrint('📥 Downloading audio stream to temp file...');

      final tempDir = await getTemporaryDirectory();
      final extension = audioStream.container.name.toLowerCase();
      final fileName = '${video.id.value}.$extension';
      final tempFile = File('${tempDir.path}/$fileName');

      // Delete old file if exists
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Get the stream and download
      final stream = _youtubeExplode.videos.streamsClient.get(audioStream);
      final fileStream = tempFile.openWrite();

      await for (final chunk in stream) {
        fileStream.add(chunk);
      }

      await fileStream.flush();
      await fileStream.close();

      debugPrint('✅ Download complete: ${tempFile.path}');

      // Play from local file (100% reliable)
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      errorMessage.value = 'Failed to extract YouTube audio: $e';
      debugPrint('❌ YouTube extraction failed: $e');
      rethrow;
    }
  }

  /// Case B: Play direct MP3/stream URL
  Future<void> _playDirectUrl(String url) async {
    try {
      debugPrint('🌐 Playing direct URL: $url');
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      errorMessage.value = 'Failed to play URL: $e';
      debugPrint('❌ URL playback failed: $e');
      rethrow;
    }
  }

  /// Case C: Play local device file
  Future<void> _playLocalFile(String filePath) async {
    try {
      debugPrint('📁 Playing local file: $filePath');
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      errorMessage.value = 'Failed to play local file: $e';
      debugPrint('❌ Local file playback failed: $e');
      rethrow;
    }
  }

  /// Pick and play local audio file (with permission handling)
  Future<bool> pickAndPlayLocalFile() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      // Check and request permissions
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        errorMessage.value = 'Storage permission denied';
        isLoading.value = false;
        return false;
      }

      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('⚠️ No file selected');
        isLoading.value = false;
        return false;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        errorMessage.value = 'Invalid file path';
        isLoading.value = false;
        return false;
      }

      // Extract filename for title
      final fileName = filePath.split('/').last;
      _currentTitle = fileName;

      // Play the selected file
      await playInput(filePath, title: fileName);
      return true;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'File picking error: $e';
      debugPrint('❌ File picker error: $e');
      return false;
    }
  }

  /// Check and request storage permissions (Android 13+ aware)
  Future<bool> _checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ uses different permission model
    final androidVersion = Platform.operatingSystemVersion;
    debugPrint('📱 Android version: $androidVersion');

    Permission permission;
    if (androidVersion.contains('13') ||
        androidVersion.contains('14') ||
        androidVersion.contains('15')) {
      // Android 13+ (API 33+)
      permission = Permission.audio;
    } else {
      // Older Android versions
      permission = Permission.storage;
    }

    final status = await permission.status;
    debugPrint('🔐 Permission status: $status');

    if (status.isGranted) {
      return true;
    }

    // Request permission
    final result = await permission.request();
    debugPrint('🔐 Permission request result: $result');

    return result.isGranted;
  }

  // Playback controls
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSource = null;
    _currentTitle = null;
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Volume control (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _youtubeExplode.close();
    isLoading.dispose();
    errorMessage.dispose();
    playerState.dispose();
    position.dispose();
    duration.dispose();
    super.dispose();
  }
}
