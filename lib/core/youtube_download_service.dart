import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';

/// YouTube Download Service - Downloads YouTube audio to local MP3 file
/// For faster playback on subsequent plays
class YouTubeDownloadService {
  static final YouTubeDownloadService _instance =
      YouTubeDownloadService._internal();
  factory YouTubeDownloadService() => _instance;
  YouTubeDownloadService._internal();

  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  /// Check if a URL is a YouTube URL
  bool isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  /// Extract video ID from YouTube URL
  String? extractVideoId(String url) {
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

  /// Get the directory for storing downloaded music
  Future<Directory> _getMusicCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${appDir.path}/music_cache');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  /// Download YouTube audio to local file
  /// Returns the local file path on success, null on failure
  /// [onProgress] callback receives progress from 0.0 to 1.0
  Future<String?> downloadYouTubeAudio(
    String youtubeUrl, {
    required String songTitle,
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    try {
      final videoId = extractVideoId(youtubeUrl);
      if (videoId == null) {
        onStatus?.call('Invalid YouTube URL');
        return null;
      }

      onStatus?.call('Getting video info...');
      onProgress?.call(0.05);

      // Get video info
      final video = await _youtubeExplode.videos.get(youtubeUrl);
      debugPrint('📹 Video: ${video.title}');

      onStatus?.call('Finding audio stream...');
      onProgress?.call(0.1);

      // Get stream manifest
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(
        video.id,
      );

      // Prefer MP4/M4A streams for better compatibility
      AudioOnlyStreamInfo? audioStream;
      String extension = 'm4a';

      try {
        audioStream = manifest.audioOnly.firstWhere(
          (stream) =>
              stream.container.name.toLowerCase() == 'mp4' ||
              stream.container.name.toLowerCase() == 'm4a',
        );
        extension = 'm4a';
        debugPrint('✅ Found MP4/M4A audio stream');
      } catch (e) {
        debugPrint('⚠️ No MP4/M4A stream, using highest bitrate');
        audioStream = manifest.audioOnly.withHighestBitrate();
        extension = audioStream.container.name.toLowerCase();
      }

      onStatus?.call('Downloading audio...');
      onProgress?.call(0.15);

      // Create file path
      final cacheDir = await _getMusicCacheDir();
      // Sanitize filename
      final sanitizedTitle = songTitle
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName = '${videoId}_$sanitizedTitle.$extension';
      final localFile = File('${cacheDir.path}/$fileName');

      // Delete if exists
      if (await localFile.exists()) {
        await localFile.delete();
      }

      // Download stream
      final stream = _youtubeExplode.videos.streamsClient.get(audioStream);
      final fileStream = localFile.openWrite();
      final totalBytes = audioStream.size.totalBytes;
      int downloadedBytes = 0;

      await for (final chunk in stream) {
        fileStream.add(chunk);
        downloadedBytes += chunk.length;

        // Calculate progress (15% to 95%)
        final downloadProgress = downloadedBytes / totalBytes;
        onProgress?.call(0.15 + downloadProgress * 0.8);
      }

      await fileStream.flush();
      await fileStream.close();

      onStatus?.call('Download complete!');
      onProgress?.call(1.0);

      debugPrint('✅ Downloaded: ${localFile.path}');
      debugPrint(
        '📁 File size: ${(downloadedBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      return localFile.path;
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      onStatus?.call('Download failed: $e');
      return null;
    }
  }

  /// Check if a local file exists for a video ID
  Future<String?> getExistingLocalFile(String youtubeUrl) async {
    try {
      final videoId = extractVideoId(youtubeUrl);
      if (videoId == null) return null;

      final cacheDir = await _getMusicCacheDir();
      final files = await cacheDir.list().toList();

      for (final file in files) {
        if (file is File && file.path.contains(videoId)) {
          if (await file.exists()) {
            return file.path;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete cached file for a video
  Future<void> deleteCachedFile(String youtubeUrl) async {
    try {
      final videoId = extractVideoId(youtubeUrl);
      if (videoId == null) return;

      final cacheDir = await _getMusicCacheDir();
      final files = await cacheDir.list().toList();

      for (final file in files) {
        if (file is File && file.path.contains(videoId)) {
          await file.delete();
          debugPrint('🗑️ Deleted cached file: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to delete cached file: $e');
    }
  }

  /// Get total cache size in MB
  Future<double> getCacheSizeMB() async {
    try {
      final cacheDir = await _getMusicCacheDir();
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

  /// Clear all cached music
  Future<void> clearCache() async {
    try {
      final cacheDir = await _getMusicCacheDir();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      debugPrint('🗑️ Music cache cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear cache: $e');
    }
  }

  void dispose() {
    _youtubeExplode.close();
  }
}
