import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

/// Android 13+ Media Notification Handler
///
/// This handler wraps just_audio with audio_service to provide:
/// - Full media notification with album art, title, artist
/// - Draggable seek bar (requires duration to be published in MediaItem)
/// - Transport controls: Previous, Play/Pause, Next
/// - Background playback support
/// - Lock screen controls
/// - Material You color extraction from album art (automatic on Android 13+)
///
/// CRITICAL for seek bar:
/// - Duration MUST be set in MediaItem metadata
/// - Position MUST be synced to playbackState in real-time
/// - MediaAction.seek MUST be declared in systemActions
///
/// CRITICAL for transport controls:
/// - MediaAction.skipToNext/skipToPrevious MUST be declared
/// - MediaControl buttons MUST be added to controls list
class MizzAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Callbacks for playlist navigation from notification
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;

  MizzAudioHandler() {
    _initializeStreams();
  }

  /// Initialize stream listeners to sync player state with notification
  void _initializeStreams() {
    // Sync playback events (position, duration, buffered position)
    _player.playbackEventStream.listen((_) => _syncState());

    // Sync playing state changes
    _player.playingStream.listen((_) => _syncState());

    // CRITICAL: Update duration in MediaItem when it becomes available
    // This enables the seek bar
    _player.durationStream.listen((duration) {
      if (duration != null && duration.inMilliseconds > 0) {
        _updateDuration(duration);
      }
    });
  }

  /// Sync current player state to the system notification
  void _syncState() {
    playbackState.add(
      PlaybackState(
        // Transport controls shown in notification compact view
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        // CRITICAL: Declare supported actions for seek bar and buttons
        systemActions: const {
          MediaAction.seek, // Required for draggable seek bar
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext, // Required for Next button
          MediaAction.skipToPrevious, // Required for Previous button
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        // Current state
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        processingState: _mapProcessingState(_player.processingState),
      ),
    );
  }

  /// Update duration in current MediaItem (CRITICAL for seek bar)
  void _updateDuration(Duration duration) {
    final current = mediaItem.value;
    if (current != null && current.duration != duration) {
      mediaItem.add(current.copyWith(duration: duration));
    }
  }

  /// Map just_audio processing state to audio_service
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // ============================================================
  // Playback Methods
  // ============================================================

  /// Play audio from a source with metadata for notification
  ///
  /// CRITICAL: Pass duration if known for immediate seek bar display
  Future<void> playFromSource({
    required String id,
    required String source,
    required String title,
    String artist = 'Unknown Artist',
    String? artworkUrl,
    Duration? duration,
  }) async {
    // Set media item first (for notification metadata)
    mediaItem.add(
      MediaItem(
        id: id,
        title: title,
        artist: artist,
        artUri: artworkUrl != null ? await _resolveArtUri(artworkUrl) : null,
        duration: duration, // Will be updated when audio loads if null
        playable: true,
      ),
    );

    // Set audio source
    if (source.startsWith('http://') || source.startsWith('https://')) {
      await _player.setUrl(source);
    } else {
      await _player.setFilePath(source);
    }

    // Start playback
    await _player.play();
  }

  /// Resolve artwork URI from various formats
  Future<Uri?> _resolveArtUri(String url) async {
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Uri.parse(url);
      } else if (url.startsWith('file://')) {
        return Uri.parse(url);
      } else if (await File(url).exists()) {
        return Uri.file(url);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to resolve artwork: $e');
    }
    return null;
  }

  /// Update notification metadata without restarting playback
  Future<void> updateNotificationMetadata({
    String? title,
    String? artist,
    String? artworkUrl,
  }) async {
    final current = mediaItem.value;
    if (current == null) return;

    mediaItem.add(
      current.copyWith(
        title: title ?? current.title,
        artist: artist ?? current.artist,
        artUri: artworkUrl != null
            ? await _resolveArtUri(artworkUrl)
            : current.artUri,
      ),
    );
  }

  // ============================================================
  // Transport Control Implementations
  // Called when user interacts with notification
  // ============================================================

  @override
  Future<void> play() async => await _player.play();

  @override
  Future<void> pause() async => await _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle, playing: false),
    );
  }

  @override
  Future<void> seek(Duration position) async => await _player.seek(position);

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> setSpeed(double speed) async => await _player.setSpeed(speed);

  // ============================================================
  // Player Access (for MusicPlayerService integration)
  // ============================================================

  /// The underlying audio player
  AudioPlayer get player => _player;

  // State getters
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  Duration get bufferedPosition => _player.bufferedPosition;

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  /// Dispose resources
  Future<void> disposePlayer() async {
    await _player.dispose();
  }
}

/// Global audio handler instance (nullable for graceful fallback)
MizzAudioHandler? _mizzAudioHandler;

/// Get the audio handler (throws if not initialized)
MizzAudioHandler get mizzAudioHandler {
  if (_mizzAudioHandler == null) {
    throw StateError(
      'MizzAudioHandler not initialized. Call initMizzAudioService() first.',
    );
  }
  return _mizzAudioHandler!;
}

/// Check if audio handler is initialized
bool get isMizzAudioHandlerInitialized => _mizzAudioHandler != null;

/// Initialize the audio service with notification support
/// Call this in main() before runApp()
Future<void> initMizzAudioService() async {
  _mizzAudioHandler = await AudioService.init(
    builder: () => MizzAudioHandler(),
    config: AudioServiceConfig(
      // Notification channel
      androidNotificationChannelId: 'com.mizz.audio',
      androidNotificationChannelName: 'Mizz Music',
      androidNotificationChannelDescription: 'Music playback controls',

      // Notification icon (small icon in status bar)
      // This should match a drawable resource name in android/app/src/main/res/drawable
      androidNotificationIcon: 'drawable/ic_mizz_notification',

      // Notification behavior:
      // androidStopForegroundOnPause: false - keeps foreground service during pause for stable background playback
      // Note: when androidStopForegroundOnPause is false, androidNotificationOngoing has no effect
      androidStopForegroundOnPause: false,
      androidNotificationOngoing: false,

      // Album art settings (enables Material You color extraction)
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      preloadArtwork: true,

      // Seek button intervals
      fastForwardInterval: const Duration(seconds: 10),
      rewindInterval: const Duration(seconds: 10),
    ),
  );

  debugPrint('✅ Media notification service initialized');
}
