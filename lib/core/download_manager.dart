import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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

  DownloadTask({
    required this.songId,
    required this.songTitle,
    required this.youtubeUrl,
    this.progress = 0.0,
    this.status = 'Pending',
    this.isComplete = false,
    this.isFailed = false,
    this.localPath,
  });
}

/// Download Manager - Manages background downloads with notifications
class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Map<String, DownloadTask> _activeTasks = {};
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

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

  /// Start a new download
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
    notifyListeners();

    // Start download in background
    _downloadInBackground(task, onComplete);
  }

  Future<void> _downloadInBackground(
    DownloadTask task,
    Function(String localPath) onComplete,
  ) async {
    try {
      task.status = 'Getting video info...';
      task.progress = 0.05;
      notifyListeners();

      final videoId = _extractVideoId(task.youtubeUrl);
      if (videoId == null) {
        task.status = 'Invalid URL';
        task.isFailed = true;
        notifyListeners();
        return;
      }

      // Get video info
      final video = await _youtubeExplode.videos.get(task.youtubeUrl);
      debugPrint('📹 Video: ${video.title}');

      task.status = 'Finding audio stream...';
      task.progress = 0.1;
      notifyListeners();

      // Get stream manifest
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(
        video.id,
      );

      // Get the best audio stream - prefer lower bitrate for faster download
      // Sort by bitrate and pick a balanced option
      final audioStreams = manifest.audioOnly.toList();
      audioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));

      AudioOnlyStreamInfo? audioStream;
      String extension = 'm4a';

      // Try to find a medium quality MP4/M4A stream (faster download)
      for (final stream in audioStreams) {
        if (stream.container.name.toLowerCase() == 'mp4' ||
            stream.container.name.toLowerCase() == 'm4a') {
          audioStream = stream;
          extension = 'm4a';
          break;
        }
      }

      // Fallback to any available stream
      audioStream ??= audioStreams.isNotEmpty
          ? audioStreams.first
          : manifest.audioOnly.withHighestBitrate();

      extension = audioStream.container.name.toLowerCase();

      task.status = 'Downloading...';
      task.progress = 0.15;
      notifyListeners();

      // Create file path
      final cacheDir = await _getMusicCacheDir();
      final sanitizedTitle = task.songTitle
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName = '${videoId}_$sanitizedTitle.$extension';
      final localFile = File('${cacheDir.path}/$fileName');

      // Delete if exists
      if (await localFile.exists()) {
        await localFile.delete();
      }

      // Use direct HTTP download for faster speeds
      final streamUrl = audioStream.url;
      final response = await http.Client().send(http.Request('GET', streamUrl));

      final totalBytes = audioStream.size.totalBytes;
      int downloadedBytes = 0;
      final fileStream = localFile.openWrite();

      await for (final chunk in response.stream) {
        fileStream.add(chunk);
        downloadedBytes += chunk.length;

        // Update progress (15% to 95%)
        final downloadProgress = downloadedBytes / totalBytes;
        task.progress = 0.15 + downloadProgress * 0.8;
        task.status = 'Downloading... ${(task.progress * 100).toInt()}%';
        notifyListeners();
      }

      await fileStream.flush();
      await fileStream.close();

      task.status = 'Complete!';
      task.progress = 1.0;
      task.isComplete = true;
      task.localPath = localFile.path;
      notifyListeners();

      debugPrint('✅ Downloaded: ${localFile.path}');
      debugPrint(
        '📁 File size: ${(downloadedBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Notify completion
      onComplete(localFile.path);

      // Remove from active tasks after a delay
      Future.delayed(const Duration(seconds: 3), () {
        _activeTasks.remove(task.songId);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      task.status = 'Failed: ${e.toString().split('\n').first}';
      task.isFailed = true;
      notifyListeners();

      // Remove failed task after delay
      Future.delayed(const Duration(seconds: 5), () {
        _activeTasks.remove(task.songId);
        notifyListeners();
      });
    }
  }

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

  Future<Directory> _getMusicCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${appDir.path}/music_cache');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  /// Cancel a download
  void cancelDownload(String songId) {
    _activeTasks.remove(songId);
    notifyListeners();
  }

  void dispose() {
    _youtubeExplode.close();
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
    return provider!.notifier!;
  }
}
