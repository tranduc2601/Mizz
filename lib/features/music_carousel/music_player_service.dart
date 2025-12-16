import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio/just_audio.dart' show AudioPlayer, ProcessingState;
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Loop mode enum
enum LoopMode { none, one, all }

/// Music Player Service - Handles audio playback
/// Uses just_audio for local files and audioplayers as fallback for YouTube
class MusicPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ap.AudioPlayer _fallbackPlayer = ap.AudioPlayer();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  String? _currentSongId;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _usingFallback = false;
  LoopMode _loopMode = LoopMode.none;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  MusicPlayerService() {
    // just_audio listeners
    _audioPlayer.positionStream.listen((position) {
      if (!_usingFallback) {
        _position = position;
        notifyListeners();
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (!_usingFallback) {
        _duration = duration ?? Duration.zero;
        notifyListeners();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (!_usingFallback) {
        _isPlaying = state.playing;
        notifyListeners();
      }
    });

    // audioplayers listeners
    _fallbackPlayer.onPositionChanged.listen((position) {
      if (_usingFallback) {
        _position = position;
        notifyListeners();
      }
    });

    _fallbackPlayer.onDurationChanged.listen((duration) {
      if (_usingFallback) {
        _duration = duration;
        notifyListeners();
      }
    });

    _fallbackPlayer.onPlayerStateChanged.listen((state) {
      if (_usingFallback) {
        _isPlaying = state == ap.PlayerState.playing;
        notifyListeners();
      }
    });
    
    // Handle song completion for loop
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongComplete();
      }
    });
    
    _fallbackPlayer.onPlayerComplete.listen((_) {
      _handleSongComplete();
    });
  }

  String? get currentSongId => _currentSongId;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  LoopMode get loopMode => _loopMode;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;
  
  /// Toggle loop mode: none -> one -> all -> none
  void toggleLoopMode() {
    switch (_loopMode) {
      case LoopMode.none:
        _loopMode = LoopMode.one;
        _audioPlayer.setLoopMode(just_audio.LoopMode.one);
        _fallbackPlayer.setReleaseMode(ap.ReleaseMode.loop);
        break;
      case LoopMode.one:
        _loopMode = LoopMode.all;
        _audioPlayer.setLoopMode(just_audio.LoopMode.off);
        _fallbackPlayer.setReleaseMode(ap.ReleaseMode.release);
        break;
      case LoopMode.all:
        _loopMode = LoopMode.none;
        _audioPlayer.setLoopMode(just_audio.LoopMode.off);
        _fallbackPlayer.setReleaseMode(ap.ReleaseMode.release);
        break;
    }
    notifyListeners();
  }
  
  void _handleSongComplete() {
    // LoopMode.one is handled by the player itself
    // LoopMode.all will be handled by the UI (play next song)
  }

  // Callback for when song completes (for loop all mode)
  Function(String songId)? onSongComplete;

  Future<void> playSong(String songId, String musicSource) async {
    try {
      _currentSongId = songId;
      _isLoading = true;
      _usingFallback = false;
      notifyListeners();

      // Stop any playing audio first
      await _audioPlayer.stop();
      await _fallbackPlayer.stop();

      // Check if it's a YouTube URL
      if (musicSource.contains('youtube.com') ||
          musicSource.contains('youtu.be')) {
        await _playYouTube(musicSource);
      } else if (musicSource.startsWith('http')) {
        // Other URL
        await _audioPlayer.setUrl(musicSource);
        await _audioPlayer.play();
      } else {
        // Local file
        debugPrint('📁 Playing local file: $musicSource');
        await _audioPlayer.setFilePath(musicSource);
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

    // Strategy 3: Try WebM/Opus (may work with audioplayers)
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

    // Try playing with just_audio first
    try {
      debugPrint('▶️ Trying just_audio...');
      await _audioPlayer.setFilePath(downloadedFile.path);
      await _audioPlayer.play();
      debugPrint('✅ Playing with just_audio');
    } catch (e) {
      debugPrint('⚠️ just_audio failed: $e');
      debugPrint('▶️ Trying audioplayers...');

      // Fallback to audioplayers
      _usingFallback = true;
      await _fallbackPlayer.play(ap.DeviceFileSource(downloadedFile.path));
      debugPrint('✅ Playing with audioplayers');
    }
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
    if (_usingFallback) {
      await _fallbackPlayer.pause();
    } else {
      await _audioPlayer.pause();
    }
  }

  Future<void> resume() async {
    if (_usingFallback) {
      await _fallbackPlayer.resume();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> stop() async {
    if (_usingFallback) {
      await _fallbackPlayer.stop();
    } else {
      await _audioPlayer.stop();
    }
    _currentSongId = null;
    _usingFallback = false;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    if (_usingFallback) {
      await _fallbackPlayer.seek(position);
    } else {
      await _audioPlayer.seek(position);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _fallbackPlayer.dispose();
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
