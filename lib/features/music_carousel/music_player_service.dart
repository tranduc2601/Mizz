import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Loop mode enum
enum MusicLoopMode { none, one, all }

/// Music Player Service - Handles audio playback
/// Uses just_audio for all audio playback (local, URL, and YouTube)
class MusicPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
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

  MusicPlayerService() {
    _initAudioSession();

    // Position stream
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Duration stream
    _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Player state stream
    _audioPlayer.playerStateStream.listen((state) {
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
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
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
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  /// Set playback speed (0.25 to 2.0)
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.25, 2.0);
    await _audioPlayer.setSpeed(_playbackSpeed);
    notifyListeners();
  }

  Future<void> playSong(
    String songId,
    String musicSource, {
    String? localFilePath,
  }) async {
    try {
      _currentSongId = songId;
      _isLoading = true;
      notifyListeners();

      // Stop any playing audio first
      await _audioPlayer.stop();

      // If local file path is available, use it (fastest)
      if (localFilePath != null && localFilePath.isNotEmpty) {
        final localFile = File(localFilePath);
        if (await localFile.exists()) {
          debugPrint('✅ Playing from local cache (instant): $localFilePath');
          await _audioPlayer.setFilePath(localFilePath);
          await _audioPlayer.setVolume(_volume);
          await _audioPlayer.setSpeed(_playbackSpeed);
          await _audioPlayer.play();
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
        // Other URL
        await _audioPlayer.setUrl(musicSource);
        await _audioPlayer.setVolume(_volume);
        await _audioPlayer.setSpeed(_playbackSpeed);
        await _audioPlayer.play();
      } else {
        // Local file
        debugPrint('📁 Playing local file: $musicSource');
        await _audioPlayer.setFilePath(musicSource);
        await _audioPlayer.setVolume(_volume);
        await _audioPlayer.setSpeed(_playbackSpeed);
        await _audioPlayer.play();
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

    // Play with just_audio
    debugPrint('▶️ Playing with just_audio...');
    await _audioPlayer.setFilePath(downloadedFile.path);
    await _audioPlayer.setVolume(_volume);
    await _audioPlayer.setSpeed(_playbackSpeed);
    await _audioPlayer.play();
    debugPrint('✅ Playing with just_audio');
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

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSongId = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
