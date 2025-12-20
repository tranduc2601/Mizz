import 'package:flutter/services.dart';

class NewPipeDownloader {
  static const platform = MethodChannel('com.example.mizz/newpipe');
  static Function(int)? _progressCallback;
  static Function(String)? _completeCallback;
  static Function(String)? _errorCallback;

  /// Initialize method channel
  static void initialize() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onProgress') {
        final progress = call.arguments as int;
        _progressCallback?.call(progress);
      } else if (call.method == 'onComplete') {
        final path = call.arguments as String;
        _completeCallback?.call(path);
        _progressCallback = null;
        _completeCallback = null;
        _errorCallback = null;
      } else if (call.method == 'onError') {
        final error = call.arguments as String;
        _errorCallback?.call(error);
        _progressCallback = null;
        _completeCallback = null;
        _errorCallback = null;
      }
    });
  }

  /// Download audio from YouTube (async, non-blocking)
  /// Returns immediately, uses callbacks for completion
  static void downloadAudioAsync({
    required String videoUrl,
    required String outputPath,
    Function(int)? onProgress,
    required Function(String path) onComplete,
    required Function(String error) onError,
  }) {
    _progressCallback = onProgress;
    _completeCallback = onComplete;
    _errorCallback = onError;

    // Fire and forget - don't await
    platform
        .invokeMethod('downloadAudio', {
          'videoUrl': videoUrl,
          'outputPath': outputPath,
        })
        .catchError((error) {
          onError(error.toString());
          _progressCallback = null;
          _completeCallback = null;
          _errorCallback = null;
        });
  }

  /// Download audio from YouTube (original blocking method - deprecated)
  /// WARNING: This blocks the main thread, use downloadAudioAsync instead
  @Deprecated('Use downloadAudioAsync instead')
  static Future<String> downloadAudio({
    required String videoUrl,
    required String outputPath,
    Function(int)? onProgress,
  }) async {
    try {
      _progressCallback = onProgress;

      final result = await platform.invokeMethod('downloadAudio', {
        'videoUrl': videoUrl,
        'outputPath': outputPath,
      });

      return result as String;
    } on PlatformException catch (e) {
      throw Exception('Download failed: ${e.message}');
    } finally {
      _progressCallback = null;
    }
  }

  /// Get video information
  static Future<Map<String, dynamic>> getVideoInfo(String videoUrl) async {
    try {
      final result = await platform.invokeMethod('getVideoInfo', {
        'videoUrl': videoUrl,
      });

      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      throw Exception('Failed to get info: ${e.message}');
    }
  }
}
