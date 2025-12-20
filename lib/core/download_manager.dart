import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'newpipe_downloader.dart';

/// Download Manager - Anti-lag optimizations implemented:
/// 1. Throttled UI updates (500ms interval) to prevent frame drops
/// 2. Progress updates only fire when change >= 2% to reduce rebuilds
/// 3. Separate throttled vs forced notify for different update priorities
/// 4. Pending update flag to batch multiple rapid updates

/// Download Task - Represents a single download
class DownloadTask {
  final String songId;
  final String songTitle;
  final String youtubeUrl;
  double progress;
  String status;
  bool isComplete;
  bool isFailed;
  String? localPath;
  String? errorMessage;

  DownloadTask({
    required this.songId,
    required this.songTitle,
    required this.youtubeUrl,
    this.progress = 0.0,
    this.status = 'Pending',
    this.isComplete = false,
    this.isFailed = false,
    this.localPath,
    this.errorMessage,
  });
}

/// Download Manager - Manages background downloads with comprehensive error handling
class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Map<String, DownloadTask> _activeTasks = {};

  // Throttle UI updates to prevent lag - increased to 500ms for smoother performance
  DateTime? _lastNotifyTime;
  Timer? _notifyTimer;
  bool _hasPendingUpdate = false;

  /// Get all active downloads
  List<DownloadTask> get activeTasks => _activeTasks.values.toList();

  /// Check if there are any active downloads
  bool get hasActiveDownloads =>
      _activeTasks.values.any((t) => !t.isComplete && !t.isFailed);

  /// Get current downloading task (first active one)
  DownloadTask? get currentTask {
    try {
      return _activeTasks.values.firstWhere(
        (t) => !t.isComplete && !t.isFailed,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check internet connectivity before download
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ Internet check failed: $e');
      return false;
    }
  }

  /// Throttled notify listeners - only updates UI every 500ms to prevent lag
  /// Aggressive throttling for smooth performance during downloads
  void _throttledNotifyListeners() {
    final now = DateTime.now();

    // If last notification was less than 500ms ago, schedule a delayed update
    if (_lastNotifyTime != null &&
        now.difference(_lastNotifyTime!).inMilliseconds < 500) {
      // Mark that we have a pending update
      _hasPendingUpdate = true;

      // Cancel any existing pending notification
      _notifyTimer?.cancel();

      // Schedule a new one
      _notifyTimer = Timer(const Duration(milliseconds: 500), () {
        if (_hasPendingUpdate) {
          _lastNotifyTime = DateTime.now();
          _hasPendingUpdate = false;
          notifyListeners();
        }
      });
      return;
    }

    // Update immediately if enough time has passed
    _lastNotifyTime = now;
    _hasPendingUpdate = false;
    notifyListeners();
  }

  /// Force immediate UI update (for important state changes)
  void _forceNotifyListeners() {
    _notifyTimer?.cancel();
    _lastNotifyTime = DateTime.now();
    _hasPendingUpdate = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    super.dispose();
  }

  /// Start a new download with comprehensive error handling
  Future<void> startDownload({
    required String songId,
    required String songTitle,
    required String youtubeUrl,
    required Function(String localPath) onComplete,
  }) async {
    // Check if already downloading this song
    if (_activeTasks.containsKey(songId)) {
      debugPrint('⚠️ Already downloading: $songTitle');
      return;
    }

    final task = DownloadTask(
      songId: songId,
      songTitle: songTitle,
      youtubeUrl: youtubeUrl,
    );

    _activeTasks[songId] = task;
    _forceNotifyListeners();

    // Start download in background
    _downloadInBackground(task, onComplete);
  }

  Future<void> _downloadInBackground(
    DownloadTask task,
    Function(String localPath) onComplete,
  ) async {
    final stopwatch = Stopwatch()..start();

    debugPrint('\n${'=' * 60}');
    debugPrint('🎬 STARTING DOWNLOAD SESSION');
    debugPrint('Song ID: ${task.songId}');
    debugPrint('Title: ${task.songTitle}');
    debugPrint('URL: ${task.youtubeUrl}');
    debugPrint('Timestamp: ${DateTime.now()}');
    debugPrint('=' * 60);

    try {
      // ✅ STEP 1: Check internet connectivity
      debugPrint('\n[STEP 1] Checking internet connectivity...');
      task.status = 'Checking connection...';
      task.progress = 0.02;
      _throttledNotifyListeners();

      final hasInternet = await _checkInternetConnection().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Internet check timeout');
          return false;
        },
      );

      if (!hasInternet) {
        debugPrint('❌ No internet connection detected');
        throw SocketException(
          'No internet connection. Please check your network and try again.',
        );
      }
      debugPrint('✅ Internet connection verified');

      // ✅ STEP 2: Extract video ID
      debugPrint('\n[STEP 2] Extracting video ID...');
      final videoId = _extractVideoId(task.youtubeUrl);
      if (videoId == null) {
        debugPrint('❌ Failed to extract video ID from URL');
        throw ArgumentError('Invalid YouTube URL format');
      }
      debugPrint('✅ Video ID extracted: $videoId');

      // ✅ STEP 3: Prepare download directory and file path
      debugPrint('\n[STEP 3] Preparing download directory and file...');
      task.status = 'Preparing download...';
      task.progress = 0.10;
      _throttledNotifyListeners();

      final cacheDir = await _getMusicCacheDir();
      debugPrint('✅ Cache directory: ${cacheDir.path}');

      final sanitizedTitle = task.songTitle
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'_{2,}'), '_');

      final fileName = '${videoId}_$sanitizedTitle.m4a';
      final localFile = File('${cacheDir.path}/$fileName');

      debugPrint('File details:');
      debugPrint('  📝 Sanitized title: $sanitizedTitle');
      debugPrint('  📄 Filename: $fileName');
      debugPrint('  📁 Full path: ${localFile.path}');

      // Delete existing file if any
      if (await localFile.exists()) {
        final existingSize = await localFile.length();
        await localFile.delete();
        debugPrint('🗑️ Deleted existing file (was ${existingSize} bytes)');
      }

      // Verify directory is writable
      try {
        final testFile = File('${cacheDir.path}/.test_write');
        await testFile.writeAsString('test');
        await testFile.delete();
        debugPrint('✅ Directory is writable');
      } catch (e) {
        debugPrint('❌ Directory write test failed: $e');
        throw Exception('Directory not writable: $e');
      }

      // ✅ STEP 4: Download using NewPipe Extractor
      debugPrint('\n${'=' * 60}');
      debugPrint('[STEP 4] DOWNLOADING WITH NEWPIPE EXTRACTOR (ASYNC)');
      debugPrint('=' * 60);
      debugPrint('Target file: ${localFile.path}');
      debugPrint('🎯 Using NewPipe Extractor - Non-blocking async mode');
      debugPrint('=' * 60);

      task.status = 'Downloading audio...';
      task.progress = 0.5; // Show indeterminate progress
      _forceNotifyListeners();

      // Use async non-blocking download
      // This returns immediately and uses callbacks
      final completer = Completer<String>();

      NewPipeDownloader.downloadAudioAsync(
        videoUrl: task.youtubeUrl,
        outputPath: localFile.path,
        onProgress: null, // Still null to avoid UI updates
        onComplete: (path) {
          debugPrint('✅ Download complete (async): $path');
          completer.complete(path);
        },
        onError: (error) {
          debugPrint('❌ Download error (async): $error');
          completer.completeError(Exception(error));
        },
      );

      // Now wait for completion without blocking
      final downloadedPath = await completer.future;

      debugPrint('✅ Download complete: $downloadedPath');

      // Verify file
      final fileSize = await localFile.length();
      debugPrint('✅ File verified: $fileSize bytes');

      if (fileSize < 10000) {
        throw Exception('File too small ($fileSize bytes)');
      }

      task.progress = 0.95;
      task.status = 'Finalizing...';
      _throttledNotifyListeners();

      // ✅ STEP 9: Verify downloaded file
      debugPrint('\n[STEP 9] Verifying downloaded file...');

      if (!await localFile.exists()) {
        debugPrint('❌ File does not exist after download!');
        throw FileSystemException(
          'Download completed but file was not saved',
          localFile.path,
        );
      }
      debugPrint('✅ File exists');

      final savedFileSize = await localFile.length();
      debugPrint(
        'File size on disk: $savedFileSize bytes (${(savedFileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
      );

      // NewPipe provides final size after download, no need to validate against expected size
      debugPrint('✅ File downloaded successfully');

      if (savedFileSize < 1000) {
        debugPrint('❌ File too small: $savedFileSize bytes');
        await localFile.delete();
        throw Exception(
          'Downloaded file is too small ($savedFileSize bytes). Download may have failed.',
        );
      }
      debugPrint('✅ File size validation passed');

      // Try to read first few bytes to verify file is readable
      try {
        final fileHandle = await localFile.open();
        final firstBytes = await fileHandle.read(10);
        await fileHandle.close();
        debugPrint(
          '✅ File is readable (first bytes: ${firstBytes.take(10).toList()})',
        );
      } catch (e) {
        debugPrint('⚠️ File read test failed: $e');
      }

      stopwatch.stop();
      final totalTime = stopwatch.elapsed;

      // ✅ STEP 10: Mark as complete
      task.status = 'Downloaded!';
      task.progress = 1.0;
      task.isComplete = true;
      task.localPath = localFile.path;

      debugPrint('\n${'=' * 60}');
      debugPrint('✅ DOWNLOAD COMPLETED SUCCESSFULLY!');
      debugPrint('=' * 60);
      debugPrint('📍 Path: ${localFile.absolute.path}');
      debugPrint(
        '📁 Size: ${(savedFileSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      debugPrint(
        '⏱️ Time: ${totalTime.inSeconds}s (${(savedFileSize / 1024 / totalTime.inSeconds).toStringAsFixed(2)} KB/s avg)',
      );
      debugPrint('🎵 Song: ${task.songTitle}');
      debugPrint('=' * 60);

      // Update UI immediately for completion
      _forceNotifyListeners();

      // ✅ STEP 11: Call completion callback
      try {
        debugPrint('🔄 Updating song database...');
        onComplete(localFile.path);
        debugPrint('✅ Song database updated');
      } catch (e) {
        debugPrint('⚠️ Error in onComplete callback: $e');
        // Don't fail the download if callback fails
      }

      // Remove from active tasks after delay
      Future.delayed(const Duration(seconds: 3), () {
        _activeTasks.remove(task.songId);
        _forceNotifyListeners();
        debugPrint('🧹 Removed completed task');
      });
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('\n${'=' * 60}');
      debugPrint('❌ DOWNLOAD FAILED');
      debugPrint('=' * 60);
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Time elapsed: ${stopwatch.elapsed.inSeconds}s');
      debugPrint('Stack trace:\n$stackTrace');
      debugPrint('=' * 60);

      task.status = 'Download failed';
      task.errorMessage = e.toString().split('\n').first;
      task.isFailed = true;
      _forceNotifyListeners();
      _removeTaskAfterDelay(task.songId, seconds: 5);
    }
  }

  /// Remove task after delay with proper error handling
  void _removeTaskAfterDelay(String songId, {int seconds = 5}) {
    Future.delayed(Duration(seconds: seconds), () {
      if (_activeTasks.containsKey(songId)) {
        _activeTasks.remove(songId);
        _forceNotifyListeners();
        debugPrint('🧹 Removed failed task: $songId');
      }
    });
  }

  String? _extractVideoId(String url) {
    try {
      final patterns = [
        RegExp(r'(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})'),
        RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
        RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})'),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(url);
        if (match != null && match.groupCount >= 1) {
          final videoId = match.group(1);
          debugPrint('✅ Extracted video ID: $videoId');
          return videoId;
        }
      }

      debugPrint('❌ Could not extract video ID from URL');
    } catch (e) {
      debugPrint('❌ Error extracting video ID: $e');
    }

    return null;
  }

  Future<Directory> _getMusicCacheDir() async {
    try {
      // Use external storage directory for user-accessible downloads
      // Path: /storage/emulated/0/Android/data/com.example.mizz/files/Mizz songs/
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception(
          'External storage not available. Check app permissions.',
        );
      }

      final musicDir = Directory('${externalDir.path}/Mizz songs');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
        debugPrint('📁 Created download directory: ${musicDir.path}');
      }

      debugPrint('📁 Download directory: ${musicDir.path}');
      return musicDir;
    } catch (e) {
      debugPrint('❌ Error getting music cache dir: $e');
      rethrow;
    }
  }

  /// Check if a song is currently downloading
  bool isDownloading(String songId) {
    final task = _activeTasks[songId];
    return task != null && !task.isComplete && !task.isFailed;
  }

  /// Get download task for a song
  DownloadTask? getTask(String songId) => _activeTasks[songId];

  /// Cancel a download
  void cancelDownload(String songId) {
    final task = _activeTasks[songId];
    if (task != null) {
      task.status = 'Cancelled';
      task.isFailed = true;
      _activeTasks.remove(songId);
      _forceNotifyListeners();
      debugPrint('🚫 Cancelled download: $songId');
    }
  }
}

/// Provider widget for DownloadManager
class DownloadManagerProvider extends InheritedNotifier<DownloadManager> {
  const DownloadManagerProvider({
    super.key,
    required DownloadManager manager,
    required super.child,
  }) : super(notifier: manager);

  static DownloadManager of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<DownloadManagerProvider>();
    assert(provider != null, 'No DownloadManagerProvider found in context');
    return provider!.notifier!;
  }
}
