import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Model for GitHub Release information
class GithubReleaseInfo {
  final String tagName;
  final String version;
  final String body; // Changelog
  final String? apkDownloadUrl;
  final String htmlUrl;
  final DateTime publishedAt;

  GithubReleaseInfo({
    required this.tagName,
    required this.version,
    required this.body,
    this.apkDownloadUrl,
    required this.htmlUrl,
    required this.publishedAt,
  });

  factory GithubReleaseInfo.fromJson(Map<String, dynamic> json) {
    // Extract APK download URL from assets
    String? apkUrl;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
    }

    // Parse tag_name - strip leading 'v' if present
    final tagName = json['tag_name'] as String? ?? '0.0.0';
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    return GithubReleaseInfo(
      tagName: tagName,
      version: version,
      body: json['body'] as String? ?? 'No release notes available.',
      apkDownloadUrl: apkUrl,
      htmlUrl: json['html_url'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Download status enum
enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
}

/// GitHub Update Manager - Handles in-app updates via GitHub Releases
class GithubUpdateManager extends ChangeNotifier {
  // Singleton pattern
  static final GithubUpdateManager _instance = GithubUpdateManager._internal();
  factory GithubUpdateManager() => _instance;
  GithubUpdateManager._internal();

  // GitHub repository info
  static const String _owner = 'tranduc2601';
  static const String _repo = 'Mizz';
  static const String _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  // State
  bool _isCheckingUpdate = false;
  bool _isUpdateAvailable = false;
  String _currentVersion = '';
  String _latestVersion = '';
  GithubReleaseInfo? _latestRelease;
  String? _errorMessage;

  // Getters
  bool get isCheckingUpdate => _isCheckingUpdate;
  bool get isUpdateAvailable => _isUpdateAvailable;
  String get currentVersion => _currentVersion;
  String get latestVersion => _latestVersion;
  GithubReleaseInfo? get latestRelease => _latestRelease;
  String? get errorMessage => _errorMessage;

  /// Get current app version
  Future<String> getCurrentVersion() async {
    if (_currentVersion.isEmpty) {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
    }
    return _currentVersion;
  }

  /// Compare two semantic versions
  /// Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Ensure both have 3 parts
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (int i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  /// Check for updates from GitHub Releases
  Future<bool> checkForUpdate() async {
    if (_isCheckingUpdate) return _isUpdateAvailable;

    _isCheckingUpdate = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current version
      await getCurrentVersion();

      // Fetch latest release from GitHub
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _latestRelease = GithubReleaseInfo.fromJson(json);
        _latestVersion = _latestRelease!.version;

        // Compare versions
        _isUpdateAvailable = _compareVersions(_latestVersion, _currentVersion) > 0;

        debugPrint('📦 GithubUpdateManager: Current v$_currentVersion, Latest v$_latestVersion');
        debugPrint('📦 Update available: $_isUpdateAvailable');
      } else if (response.statusCode == 404) {
        _errorMessage = 'No releases found';
        _isUpdateAvailable = false;
        debugPrint('⚠️ GithubUpdateManager: No releases found (404)');
      } else if (response.statusCode == 403) {
        _errorMessage = 'API rate limit exceeded. Try again later.';
        _isUpdateAvailable = false;
        debugPrint('⚠️ GithubUpdateManager: Rate limit exceeded (403)');
      } else {
        _errorMessage = 'Failed to check for updates (HTTP ${response.statusCode})';
        _isUpdateAvailable = false;
        debugPrint('❌ GithubUpdateManager: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Network error: Unable to check for updates';
      _isUpdateAvailable = false;
      debugPrint('❌ GithubUpdateManager: Error checking update: $e');
    }

    _isCheckingUpdate = false;
    notifyListeners();
    return _isUpdateAvailable;
  }

  /// Download and install APK
  Future<void> downloadAndInstallApk({
    required Function(double progress) onProgress,
    required Function() onCompleted,
    required Function(String error) onError,
  }) async {
    if (_latestRelease?.apkDownloadUrl == null) {
      onError('No APK download URL available');
      return;
    }

    try {
      final downloadUrl = _latestRelease!.apkDownloadUrl!;
      debugPrint('📥 Downloading APK from: $downloadUrl');

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        // Get download directory
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          onError('Cannot access storage');
          return;
        }

        final filePath = '${directory.path}/mizz_update.apk';
        final file = File(filePath);

        // Delete old file if exists
        if (await file.exists()) {
          await file.delete();
        }

        // Calculate total bytes
        final totalBytes = response.contentLength;
        int receivedBytes = 0;

        // Create file stream
        final sink = file.openWrite();

        await response.listen(
          (List<int> chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;

            // Update progress
            if (totalBytes != -1) {
              final progress = receivedBytes / totalBytes;
              onProgress(progress);
            }
          },
          onDone: () async {
            await sink.close();
            onCompleted();

            // Open APK installer
            await _installApk(filePath);
          },
          onError: (error) {
            sink.close();
            onError('Download error: $error');
          },
          cancelOnError: true,
        ).asFuture();
      } else {
        onError('Download failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      onError('Download error: $e');
    }
  }

  /// Trigger APK installation
  Future<void> _installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint('❌ GithubUpdateManager: Cannot open APK: ${result.message}');
      }
    } catch (e) {
      debugPrint('❌ GithubUpdateManager: Install error: $e');
    }
  }

  /// Reset state
  void reset() {
    _isUpdateAvailable = false;
    _latestRelease = null;
    _latestVersion = '';
    _errorMessage = null;
    notifyListeners();
  }
}
