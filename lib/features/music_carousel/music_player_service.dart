import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../core/media_notification_handler.dart';

/// Loop mode enum
enum MusicLoopMode { none, one, all }

/// Current song metadata for notification
class CurrentSongMetadata {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;

  const CurrentSongMetadata({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
  });
}

/// Music Player Service - Handles audio playback
/// Uses just_audio for all audio playback (local, URL, and YouTube)
/// Integrates with MizzAudioHandler for Android 13+ media notifications
class MusicPlayerService extends ChangeNotifier {
  // Fallback player when audio handler is not initialized
  AudioPlayer? _fallbackPlayer;

  // Use the audio handler's player for unified playback + notification
  // Falls back to own player if handler not initialized
  AudioPlayer get _audioPlayer {
    if (isMizzAudioHandlerInitialized) {
      return mizzAudioHandler.player;
    }
    _fallbackPlayer ??= AudioPlayer();
    return _fallbackPlayer!;
  }

  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  String? _currentSongId;
  bool _isPlaying = false;
  bool _isLoading = false;
  MusicLoopMode _loopMode = MusicLoopMode.none;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _autoNext = true; // Auto-play next song when current ends
  bool _audioSessionInitialized = false;
  bool _streamListenersInitialized = false;

  // Current song metadata for notification
  CurrentSongMetadata? _currentMetadata;

  MusicPlayerService() {
    _initAudioSession();
    // Defer stream listener setup to ensure mizzAudioHandler is ready
    Future.microtask(() => _initStreamListeners());
  }

  /// Initialize stream listeners from the audio handler's player
  void _initStreamListeners() {
    if (_streamListenersInitialized) return;
    _streamListenersInitialized = true;

    final player = _audioPlayer;

    // Position stream
    player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Duration stream
    player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Player state stream
    player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();

      // Handle song completion
      if (state.processingState == ProcessingState.completed) {
        _handleSongComplete();
      }
    });
  }

  /// Initialize audio session for background playback
  Future<void> _initAudioSession() async {
    if (_audioSessionInitialized) return;
    _audioSessionInitialized = true;

    try {
      final session = await AudioSession.instance;

      // Configure for music playback with background support
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );

      // Activate the audio session to ensure we have audio focus
      await session.setActive(true);

      // Handle audio interruptions (phone calls, etc.)
      // Only pause for phone calls, not for app backgrounding
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Lower volume instead of pausing
              _audioPlayer.setVolume(_volume * 0.3);
              break;
            case AudioInterruptionType.pause:
              // Only pause for important interruptions like phone calls
              _audioPlayer.pause();
              break;
            case AudioInterruptionType.unknown:
              // Don't pause for unknown interruptions (includes app backgrounding)
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Restore volume
              _audioPlayer.setVolume(_volume);
              break;
            case AudioInterruptionType.pause:
              // Resume after phone call ends
              if (_currentSongId != null) {
                _audioPlayer.play();
              }
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      // Handle headphone disconnection - pause when headphones are unplugged
      session.becomingNoisyEventStream.listen((_) {
        _audioPlayer.pause();
      });

      debugPrint('✅ Audio session configured for background playback');
    } catch (e) {
      debugPrint('⚠️ Failed to configure audio session: $e');
    }
  }

  String? get currentSongId => _currentSongId;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  MusicLoopMode get loopMode => _loopMode;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  bool get autoNext => _autoNext;
  double get progress {
    if (_duration.inMilliseconds <= 0) return 0.0;
    // Clamp progress between 0.0 and 1.0 to avoid slider overflow error
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  /// Toggle loop mode: none -> one -> all -> none
  void toggleLoopMode() {
    switch (_loopMode) {
      case MusicLoopMode.none:
        _loopMode = MusicLoopMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case MusicLoopMode.one:
        _loopMode = MusicLoopMode.all;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case MusicLoopMode.all:
        _loopMode = MusicLoopMode.none;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  void _handleSongComplete() {
    // LoopMode.one is handled by the player itself
    // For other modes, notify the UI to handle auto-next
    if (_loopMode != MusicLoopMode.one && _autoNext) {
      onSongComplete?.call(_currentSongId ?? '');
    }
  }

  // Callback for when song completes (for auto-next and loop all mode)
  Function(String songId)? onSongComplete;

  /// Toggle auto-next mode
  void toggleAutoNext() {
    _autoNext = !_autoNext;
    notifyListeners();
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (isMizzAudioHandlerInitialized) {
      await mizzAudioHandler.setVolume(_volume);
    } else {
      await _audioPlayer.setVolume(_volume);
    }
    notifyListeners();
  }

  /// Set playback speed (0.25 to 2.0)
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.25, 2.0);
    if (isMizzAudioHandlerInitialized) {
      await mizzAudioHandler.setSpeed(_playbackSpeed);
    } else {
      await _audioPlayer.setSpeed(_playbackSpeed);
    }
    notifyListeners();
  }

  /// Play a song with full metadata for Android 13+ media notification
  ///
  /// [songId] - Unique identifier for the song
  /// [musicSource] - Audio source (file path, URL, or YouTube URL)
  /// [title] - Song title (displayed in notification)
  /// [artist] - Artist name (displayed in notification)
  /// [artworkUrl] - Album art URL (displayed in notification)
  /// [localFilePath] - Cached local file path for faster playback
  Future<void> playSong(
    String songId,
    String musicSource, {
    String? localFilePath,
    String? title,
    String? artist,
    String? artworkUrl,
  }) async {
    try {
      _currentSongId = songId;
      _isLoading = true;
      notifyListeners();

      // Store metadata for notification
      _currentMetadata = CurrentSongMetadata(
        id: songId,
        title: title ?? 'Unknown Title',
        artist: artist ?? 'Unknown Artist',
        artworkUrl: artworkUrl,
      );

      // Stop any playing audio first
      await _audioPlayer.stop();

      // If local file path is available, use it (fastest)
      if (localFilePath != null && localFilePath.isNotEmpty) {
        final localFile = File(localFilePath);
        if (await localFile.exists()) {
          debugPrint('✅ Playing from local cache (instant): $localFilePath');
          await _playSource(localFilePath, isFile: true);
          _isLoading = false;
          notifyListeners();
          return;
        } else {
          debugPrint('⚠️ Local file not found, falling back to source');
        }
      }

      // Check if it's a YouTube URL
      if (musicSource.contains('youtube.com') ||
          musicSource.contains('youtu.be')) {
        await _playYouTube(musicSource);
      } else if (musicSource.startsWith('http')) {
        // Direct URL
        await _playSource(musicSource, isFile: false);
      } else {
        // Local file
        debugPrint('📁 Playing local file: $musicSource');
        await _playSource(musicSource, isFile: true);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('❌ Error playing song: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Play from source with optional notification update
  Future<void> _playSource(String source, {required bool isFile}) async {
    if (isMizzAudioHandlerInitialized && _currentMetadata != null) {
      // Use audio handler for playback with notification
      await mizzAudioHandler.playFromSource(
        id: _currentMetadata!.id,
        source: source,
        title: _currentMetadata!.title,
        artist: _currentMetadata!.artist,
        artworkUrl: _currentMetadata!.artworkUrl,
      );
      await mizzAudioHandler.setVolume(_volume);
      await mizzAudioHandler.setSpeed(_playbackSpeed);
    } else {
      // Fallback: use player directly without notification
      if (isFile) {
        await _audioPlayer.setFilePath(source);
      } else {
        await _audioPlayer.setUrl(source);
      }
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.play();
    }
  }

  Future<void> _playYouTube(String url) async {
    debugPrint('🎵 Loading YouTube video: $url');

    final video = await _youtubeExplode.videos.get(url);
    debugPrint('📹 Video: ${video.title}');

    final manifest = await _youtubeExplode.videos.streamsClient.getManifest(
      video.id,
    );

    // Try different stream types in order of preference
    File? downloadedFile;

    // Strategy 1: Try muxed MP4 streams (most compatible)
    final muxedMp4 = manifest.muxed
        .where((s) => s.container.name.toLowerCase() == 'mp4')
        .toList();

    if (muxedMp4.isNotEmpty) {
      muxedMp4.sort((a, b) => a.size.totalBytes.compareTo(b.size.totalBytes));
      final stream = muxedMp4.first;
      debugPrint(
        '📦 Trying muxed MP4: ${(stream.size.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
      );
      downloadedFile = await _downloadStream(video.id.value, stream, 'mp4');
    }

    // Strategy 2: Try audio-only MP4/M4A
    if (downloadedFile == null) {
      final audioMp4 = manifest.audioOnly
          .where(
            (s) =>
                s.container.name.toLowerCase() == 'mp4' ||
                s.container.name.toLowerCase() == 'm4a',
          )
          .toList();

      if (audioMp4.isNotEmpty) {
        audioMp4.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        final stream = audioMp4.first;
        debugPrint(
          '📦 Trying audio MP4/M4A: ${stream.bitrate.kiloBitsPerSecond} kbps',
        );
        downloadedFile = await _downloadStream(video.id.value, stream, 'm4a');
      }
    }

    // Strategy 3: Try WebM/Opus
    if (downloadedFile == null) {
      final webm = manifest.audioOnly
          .where((s) => s.container.name.toLowerCase() == 'webm')
          .toList();

      if (webm.isNotEmpty) {
        webm.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        final stream = webm.first;
        debugPrint(
          '📦 Trying WebM audio: ${stream.bitrate.kiloBitsPerSecond} kbps',
        );
        downloadedFile = await _downloadStream(video.id.value, stream, 'webm');
      }
    }

    if (downloadedFile == null) {
      throw Exception('No suitable audio stream found');
    }

    // Use video thumbnail as artwork if no custom artwork was provided
    final thumbnailUrl =
        _currentMetadata?.artworkUrl ??
        'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg';

    // Update metadata with YouTube info if needed
    _currentMetadata ??= CurrentSongMetadata(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      artworkUrl: thumbnailUrl,
    );

    // Play using shared method
    debugPrint('▶️ Playing YouTube with media notification...');
    await _playSource(downloadedFile.path, isFile: true);
    debugPrint('✅ YouTube playing with notification');
  }

  Future<File?> _downloadStream(
    String videoId,
    StreamInfo stream,
    String ext,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/yt_$videoId.$ext');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      debugPrint('📥 Downloading ${stream.size.totalBytes} bytes...');

      final dataStream = _youtubeExplode.videos.streamsClient.get(stream);
      final List<int> allBytes = [];
      final totalBytes = stream.size.totalBytes;

      int lastProgress = 0;
      await for (final chunk in dataStream) {
        allBytes.addAll(chunk);
        final progress = (allBytes.length / totalBytes * 100).toInt();
        if (progress >= lastProgress + 20) {
          debugPrint('📥 Progress: $progress%');
          lastProgress = progress;
        }
      }

      debugPrint('📥 Downloaded ${allBytes.length} bytes');

      if (allBytes.length < 10000) {
        debugPrint('⚠️ Download too small, skipping');
        return null;
      }

      await tempFile.writeAsBytes(Uint8List.fromList(allBytes), flush: true);

      final savedSize = await tempFile.length();
      debugPrint('💾 Saved: $savedSize bytes at ${tempFile.path}');

      if (savedSize < allBytes.length * 0.9) {
        debugPrint('⚠️ File save incomplete');
        return null;
      }

      return tempFile;
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      return null;
    }
  }

  /// Download YouTube audio to permanent storage
  /// Returns the permanent file path if successful, null otherwise
  Future<String?> downloadYouTubeAudio(
    String musicSource, {
    String? songTitle,
    Function(double)? onProgress,
  }) async {
    if (!musicSource.contains('youtube.com') &&
        !musicSource.contains('youtu.be')) {
      debugPrint('⚠️ Not a YouTube URL');
      return null;
    }

    try {
      debugPrint('📥 Starting permanent download: $musicSource');

      final video = await _youtubeExplode.videos.get(musicSource);
      debugPrint('📹 Video: ${video.title}');

      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(
        video.id,
      );

      // Get the best audio stream
      StreamInfo? bestStream;
      String ext = 'm4a';

      // Try audio-only MP4/M4A first (best for mobile)
      final audioMp4 = manifest.audioOnly
          .where(
            (s) =>
                s.container.name.toLowerCase() == 'mp4' ||
                s.container.name.toLowerCase() == 'm4a',
          )
          .toList();

      if (audioMp4.isNotEmpty) {
        audioMp4.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        bestStream = audioMp4.first;
        ext = 'm4a';
      } else {
        // Fallback to muxed MP4
        final muxedMp4 = manifest.muxed
            .where((s) => s.container.name.toLowerCase() == 'mp4')
            .toList();
        if (muxedMp4.isNotEmpty) {
          muxedMp4.sort(
            (a, b) => a.size.totalBytes.compareTo(b.size.totalBytes),
          );
          bestStream = muxedMp4.first;
          ext = 'mp4';
        }
      }

      if (bestStream == null) {
        debugPrint('❌ No suitable audio stream found');
        return null;
      }

      // Get permanent storage directory
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${appDir.path}/MizzMusic');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      // Create safe filename
      final safeTitle = (songTitle ?? video.title)
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName = '${video.id.value}_$safeTitle.$ext';
      final permanentFile = File('${musicDir.path}/$fileName');

      // Check if already downloaded
      if (await permanentFile.exists()) {
        debugPrint('✅ File already exists: ${permanentFile.path}');
        return permanentFile.path;
      }

      debugPrint('📥 Downloading to: ${permanentFile.path}');

      final dataStream = _youtubeExplode.videos.streamsClient.get(bestStream);
      final List<int> allBytes = [];
      final totalBytes = bestStream.size.totalBytes;

      int lastProgressPercent = 0;
      await for (final chunk in dataStream) {
        allBytes.addAll(chunk);
        final progress = allBytes.length / totalBytes;
        final progressPercent = (progress * 100).toInt();

        // Update progress callback more frequently (every 2%)
        if (progressPercent >= lastProgressPercent + 2 ||
            progressPercent == 100) {
          debugPrint('📥 Download progress: $progressPercent%');
          lastProgressPercent = progressPercent;
          onProgress?.call(progress);
        }
      }

      // Ensure final progress is reported
      onProgress?.call(1.0);

      if (allBytes.length < 10000) {
        debugPrint('⚠️ Download too small');
        return null;
      }

      await permanentFile.writeAsBytes(
        Uint8List.fromList(allBytes),
        flush: true,
      );

      final savedSize = await permanentFile.length();
      debugPrint(
        '✅ Downloaded: ${(savedSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      debugPrint('✅ Saved to: ${permanentFile.path}');

      return permanentFile.path;
    } catch (e) {
      debugPrint('❌ Download error: $e');
      return null;
    }
  }

  Future<void> pause() async {
    if (isMizzAudioHandlerInitialized) {
      await mizzAudioHandler.pause();
    } else {
      await _audioPlayer.pause();
    }
  }

  Future<void> resume() async {
    if (isMizzAudioHandlerInitialized) {
      await mizzAudioHandler.play();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> stop() async {
    if (isMizzAudioHandlerInitialized) {
      await mizzAudioHandler.stop();
    } else {
      await _audioPlayer.stop();
    }
    _currentSongId = null;
    _currentMetadata = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    if (isMizzAudioHandlerInitialized) {
      await mizzAudioHandler.seek(position);
    } else {
      await _audioPlayer.seek(position);
    }
  }

  /// Set up callbacks for notification transport controls
  /// Call this after initializing the service to handle skip next/previous from notification
  void setupNotificationCallbacks({
    VoidCallback? onSkipToNext,
    VoidCallback? onSkipToPrevious,
  }) {
    if (isMizzAudioHandlerInitialized) {
      mizzAudioHandler.onSkipToNext = onSkipToNext;
      mizzAudioHandler.onSkipToPrevious = onSkipToPrevious;
    }
  }

  /// Get current metadata
  CurrentSongMetadata? get currentMetadata => _currentMetadata;

  @override
  void dispose() {
    _youtubeExplode.close();
    super.dispose();
  }
}

/// Music Player Service Provider - Provides player service to widget tree
class MusicPlayerServiceProvider extends InheritedWidget {
  final MusicPlayerService playerService;

  const MusicPlayerServiceProvider({
    super.key,
    required this.playerService,
    required super.child,
  });

  static MusicPlayerService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<MusicPlayerServiceProvider>();
    assert(provider != null, 'No MusicPlayerServiceProvider found in context');
    return provider!.playerService;
  }

  @override
  bool updateShouldNotify(MusicPlayerServiceProvider oldWidget) {
    return playerService != oldWidget.playerService;
  }
}
