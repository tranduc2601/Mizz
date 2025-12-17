import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

/// Background Audio Handler with YouTube Caching
/// Uses just_audio + audio_session for background playback
class BackgroundAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  // State management
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  String? _currentSource;
  String? _currentTitle;
  String? _currentArtist;

  bool _initialized = false;

  // YouTube cache management
  static const String _cacheKey = 'youtube_audio_cache_v2';
  Map<String, String> _youtubeCache = {};

  BackgroundAudioHandler() {
    _loadCache();
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson != null) {
        _youtubeCache = Map<String, String>.from(jsonDecode(cacheJson));
        debugPrint('📂 Loaded ${_youtubeCache.length} cached YouTube songs');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load cache: $e');
    }
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_youtubeCache));
    } catch (e) {
      debugPrint('⚠️ Failed to save cache: $e');
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Configure audio session for music playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Handle audio interruptions (phone calls, etc.)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _player.pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _player.play();
            break;
        }
      }
    });

    // Handle headphone disconnection
    session.becomingNoisyEventStream.listen((_) {
      _player.pause();
    });
  }

  // Getters
  bool get isPlaying => _player.playing;
  String? get currentSource => _currentSource;
  String? get currentTitle => _currentTitle;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;

  /// Combined stream for UI updates
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  /// Extract video ID from YouTube URL
  String? _extractVideoId(String url) {
    final patterns = [
      RegExp(r'v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'embed/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Universal play function - automatically detects input type
  Future<void> playInput(String input, {String? title, String? artist}) async {
    try {
      await init();
      isLoading.value = true;
      errorMessage.value = null;
      _currentTitle = title;
      _currentArtist = artist;
      _currentSource = input;

      // Case A: YouTube URL
      if (input.contains('youtube.com') || input.contains('youtu.be')) {
        await _playYouTubeAudio(input);
      }
      // Case B: Direct HTTP/HTTPS URL
      else if (input.startsWith('http://') || input.startsWith('https://')) {
        await _playDirectUrl(input, title: title);
      }
      // Case C: Local file path
      else {
        await _playLocalFile(input, title: title);
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Playback error: ${e.toString()}';
      debugPrint('❌ BackgroundAudioHandler Error: $e');
      rethrow;
    }
  }

  /// Case A: Extract and play YouTube audio stream with CACHING
  Future<void> _playYouTubeAudio(String youtubeUrl) async {
    try {
      debugPrint('🎵 Extracting YouTube audio from: $youtubeUrl');

      final videoId = _extractVideoId(youtubeUrl);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL');
      }

      // Check cache first - FAST PATH
      if (_youtubeCache.containsKey(videoId)) {
        final cachedPath = _youtubeCache[videoId]!;
        final cachedFile = File(cachedPath);
        if (await cachedFile.exists()) {
          debugPrint('✅ Playing from cache (instant): $cachedPath');
          await _player.setFilePath(cachedPath);
          await _player.play();
          return;
        } else {
          _youtubeCache.remove(videoId);
          await _saveCache();
        }
      }

      // Get video metadata
      final video = await _youtubeExplode.videos.get(youtubeUrl);
      _currentTitle ??= video.title;
      _currentArtist ??= video.author;

      // Get audio-only stream manifest
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(
        video.id,
      );

      // Prefer MP4/M4A streams to avoid codec issues
      AudioOnlyStreamInfo? audioStream;
      try {
        audioStream = manifest.audioOnly.firstWhere(
          (stream) =>
              stream.container.name.toLowerCase() == 'mp4' ||
              stream.container.name.toLowerCase() == 'm4a',
        );
        debugPrint('✅ Found MP4/M4A audio stream');
      } catch (e) {
        debugPrint('⚠️ No MP4/M4A stream, using highest bitrate');
        audioStream = manifest.audioOnly.withHighestBitrate();
      }

      // Download to PERMANENT cache directory
      debugPrint('📥 Downloading and caching audio...');
      final cacheDir = await _getCacheDirectory();
      final extension = audioStream.container.name.toLowerCase();
      final fileName = '$videoId.$extension';
      final cacheFile = File('${cacheDir.path}/$fileName');

      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }

      final stream = _youtubeExplode.videos.streamsClient.get(audioStream);
      final fileStream = cacheFile.openWrite();
      await for (final chunk in stream) {
        fileStream.add(chunk);
      }
      await fileStream.flush();
      await fileStream.close();

      // Save to cache
      _youtubeCache[videoId] = cacheFile.path;
      await _saveCache();

      debugPrint('✅ Cached: ${cacheFile.path}');

      // Play
      await _player.setFilePath(cacheFile.path);
      await _player.play();
    } catch (e) {
      errorMessage.value = 'Failed to extract YouTube audio: $e';
      debugPrint('❌ YouTube extraction failed: $e');
      rethrow;
    }
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/youtube_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Case B: Play direct MP3/stream URL
  Future<void> _playDirectUrl(String url, {String? title}) async {
    try {
      debugPrint('🌐 Playing direct URL: $url');
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      errorMessage.value = 'Failed to play URL: $e';
      debugPrint('❌ URL playback failed: $e');
      rethrow;
    }
  }

  /// Case C: Play local device file
  Future<void> _playLocalFile(String filePath, {String? title}) async {
    try {
      debugPrint('📁 Playing local file: $filePath');
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final fileName = filePath.split(Platform.pathSeparator).last;
      _currentTitle = title ?? fileName;

      await _player.setFilePath(filePath);
      await _player.play();
    } catch (e) {
      errorMessage.value = 'Failed to play local file: $e';
      debugPrint('❌ Local file playback failed: $e');
      rethrow;
    }
  }

  /// Pick and play local audio file
  Future<bool> pickAndPlayLocalFile() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        errorMessage.value = 'Storage permission denied';
        isLoading.value = false;
        return false;
      }

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

      final fileName = filePath.split(Platform.pathSeparator).last;
      await playInput(filePath, title: fileName);
      return true;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'File picking error: $e';
      debugPrint('❌ File picker error: $e');
      return false;
    }
  }

  /// Check and request storage permissions
  Future<bool> _checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final androidVersion = Platform.operatingSystemVersion;
    debugPrint('📱 Android version: $androidVersion');

    Permission permission;
    if (androidVersion.contains('13') ||
        androidVersion.contains('14') ||
        androidVersion.contains('15')) {
      permission = Permission.audio;
    } else {
      permission = Permission.storage;
    }

    final status = await permission.status;
    if (status.isGranted) return true;

    final result = await permission.request();
    return result.isGranted;
  }

  /// Clear YouTube cache
  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      _youtubeCache.clear();
      await _saveCache();
      debugPrint('🗑️ Cache cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear cache: $e');
    }
  }

  /// Get cache size in MB
  Future<double> getCacheSizeMB() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize / (1024 * 1024);
    } catch (e) {
      return 0;
    }
  }

  // Playback controls
  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSource = null;
    _currentTitle = null;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  void dispose() {
    _player.dispose();
    _youtubeExplode.close();
    isLoading.dispose();
    errorMessage.dispose();
  }
}

/// Helper class for position data
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

/// Global audio handler instance
late BackgroundAudioHandler audioHandler;

/// Initialize audio handler - call this in main()
Future<void> initAudioService() async {
  audioHandler = BackgroundAudioHandler();
  await audioHandler.init();
}
