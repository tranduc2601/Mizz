import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';
import 'dart:io';
import '../../core/media_notification_handler.dart';

enum MusicLoopMode { none, one, all }

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

class MusicPlayerService extends ChangeNotifier {
  AudioPlayer? _fallbackPlayer;

  AudioPlayer get _audioPlayer {
    if (isMizzAudioHandlerInitialized) {
      return mizzAudioHandler.player;
    }
    _fallbackPlayer ??= AudioPlayer();
    return _fallbackPlayer!;
  }

  String? _currentSongId;
  bool _isPlaying = false;
  bool _isLoading = false;
  MusicLoopMode _loopMode = MusicLoopMode.none;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _autoNext = true;
  bool _audioSessionInitialized = false;
  bool _streamListenersInitialized = false;
  bool _isDisposed = false;
  final List<StreamSubscription> _subscriptions = [];
  CurrentSongMetadata? _currentMetadata;

  MusicPlayerService() {
    _initAudioSession();
    Future.microtask(() => _initStreamListeners());
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _initStreamListeners() {
    if (_streamListenersInitialized || _isDisposed) return;
    _streamListenersInitialized = true;

    final player = _audioPlayer;

    _subscriptions.add(
      player.positionStream.listen((position) {
        if (_isDisposed) return;
      }),
    );

    _subscriptions.add(
      player.durationStream.listen((duration) {
        if (_isDisposed) return;
        _duration = duration ?? Duration.zero;
        _safeNotifyListeners();
      }),
    );

    _subscriptions.add(
      player.playerStateStream.listen((state) {
        if (_isDisposed) return;
        _isPlaying = state.playing;
        _safeNotifyListeners();

        if (state.processingState == ProcessingState.completed) {
          _handleSongComplete();
        }
      }),
    );
  }

  Future<void> _initAudioSession() async {
    if (_audioSessionInitialized) return;
    _audioSessionInitialized = true;

    try {
      final session = await AudioSession.instance;

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

      _currentMetadata = CurrentSongMetadata(
        id: songId,
        title: title ?? 'Unknown Title',
        artist: artist ?? 'Unknown Artist',
        artworkUrl: artworkUrl,
      );

      await _audioPlayer.stop();

      if (localFilePath != null && localFilePath.isNotEmpty) {
        final localFile = File(localFilePath);
        if (await localFile.exists()) {
          debugPrint('✅ Playing from local cache: $localFilePath');
          await _playSource(localFilePath, isFile: true);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (musicSource.startsWith('http')) {
        await _playSource(musicSource, isFile: false);
      } else {
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

  Future<void> _playSource(String source, {required bool isFile}) async {
    if (isMizzAudioHandlerInitialized && _currentMetadata != null) {
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

  void setupNotificationCallbacks({
    VoidCallback? onSkipToNext,
    VoidCallback? onSkipToPrevious,
  }) {
    if (isMizzAudioHandlerInitialized) {
      mizzAudioHandler.onSkipToNext = onSkipToNext;
      mizzAudioHandler.onSkipToPrevious = onSkipToPrevious;
    }
  }

  CurrentSongMetadata? get currentMetadata => _currentMetadata;

  @override
  void dispose() {
    _isDisposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _fallbackPlayer?.dispose();
    super.dispose();
  }
}

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
