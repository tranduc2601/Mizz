import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Model chứa thông tin phiên bản
class AppVersionInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String? releaseNotes;
  final bool forceUpdate;

  AppVersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.releaseNotes,
    this.forceUpdate = false,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      version: json['version'] ?? '1.0.0',
      buildNumber: json['build_number'] ?? 1,
      downloadUrl: json['download_url'] ?? '',
      releaseNotes: json['release_notes'],
      forceUpdate: json['force_update'] ?? false,
    );
  }
}

/// Trạng thái download
enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
}

/// UpdateManager - Quản lý cập nhật ứng dụng OTA
class UpdateManager {
  // Singleton pattern
  static final UpdateManager _instance = UpdateManager._internal();
  factory UpdateManager() => _instance;
  UpdateManager._internal();

  /// URL đến file JSON chứa thông tin phiên bản mới nhất
  /// Bạn có thể thay đổi URL này thành GitHub raw file hoặc API endpoint của bạn
  /// Ví dụ GitHub: https://raw.githubusercontent.com/username/repo/main/version.json
  String _versionCheckUrl = '';

  /// Thiết lập URL kiểm tra phiên bản
  void setVersionCheckUrl(String url) {
    _versionCheckUrl = url;
  }

  /// Lấy thông tin phiên bản hiện tại của ứng dụng
  Future<PackageInfo> getCurrentVersion() async {
    return await PackageInfo.fromPlatform();
  }

  /// Kiểm tra có bản cập nhật mới không
  Future<AppVersionInfo?> checkForUpdate() async {
    try {
      if (_versionCheckUrl.isEmpty) {
        debugPrint('UpdateManager: Version check URL chưa được thiết lập');
        return null;
      }

      final response = await http.get(Uri.parse(_versionCheckUrl));
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final latestVersion = AppVersionInfo.fromJson(jsonData);
        
        // Lấy phiên bản hiện tại
        final currentVersion = await getCurrentVersion();
        
        // So sánh phiên bản
        if (_isNewerVersion(latestVersion.version, currentVersion.version) ||
            latestVersion.buildNumber > int.parse(currentVersion.buildNumber)) {
          return latestVersion;
        }
      }
      return null;
    } catch (e) {
      debugPrint('UpdateManager: Lỗi kiểm tra cập nhật: $e');
      return null;
    }
  }

  /// So sánh 2 phiên bản (ví dụ: 1.0.1 > 1.0.0)
  bool _isNewerVersion(String newVersion, String currentVersion) {
    List<int> newParts = newVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Đảm bảo cả hai có cùng độ dài
    while (newParts.length < 3) newParts.add(0);
    while (currentParts.length < 3) currentParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (newParts[i] > currentParts[i]) return true;
      if (newParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  /// Tải file APK và cài đặt
  Future<void> downloadAndInstallApk(
    String downloadUrl, {
    required Function(double progress) onProgress,
    required Function() onCompleted,
    required Function(String error) onError,
  }) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        // Lấy thư mục tải về
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          onError('Không thể truy cập bộ nhớ');
          return;
        }

        final filePath = '${directory.path}/app_update.apk';
        final file = File(filePath);

        // Xóa file cũ nếu tồn tại
        if (await file.exists()) {
          await file.delete();
        }

        // Tính tổng kích thước file
        final totalBytes = response.contentLength;
        int receivedBytes = 0;

        // Tạo stream để ghi file
        final sink = file.openWrite();

        await response.listen(
          (List<int> chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            
            // Cập nhật tiến trình
            if (totalBytes != -1) {
              final progress = receivedBytes / totalBytes;
              onProgress(progress);
            }
          },
          onDone: () async {
            await sink.close();
            onCompleted();
            
            // Mở file APK để cài đặt
            await _installApk(filePath);
          },
          onError: (error) {
            sink.close();
            onError('Lỗi tải file: $error');
          },
          cancelOnError: true,
        ).asFuture();
      } else {
        onError('Lỗi tải file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      onError('Lỗi tải file: $e');
    }
  }

  /// Kích hoạt trình cài đặt APK
  Future<void> _installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint('UpdateManager: Không thể mở file APK: ${result.message}');
      }
    } catch (e) {
      debugPrint('UpdateManager: Lỗi cài đặt APK: $e');
    }
  }

  /// Hiển thị dialog cập nhật
  Future<void> showUpdateDialog(
    BuildContext context, {
    required AppVersionInfo versionInfo,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !versionInfo.forceUpdate,
      builder: (BuildContext context) {
        return UpdateDialog(
          versionInfo: versionInfo,
          onUpdate: () async {
            Navigator.of(context).pop();
            _showDownloadDialog(context, versionInfo.downloadUrl);
          },
          onLater: versionInfo.forceUpdate
              ? null
              : () {
                  Navigator.of(context).pop();
                },
        );
      },
    );
  }

  /// Hiển thị dialog tải xuống với progress bar
  void _showDownloadDialog(BuildContext context, String downloadUrl) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return DownloadProgressDialog(
          downloadUrl: downloadUrl,
          updateManager: this,
        );
      },
    );
  }

  /// Kiểm tra và hiển thị dialog nếu có bản cập nhật
  Future<void> checkAndShowUpdateDialog(BuildContext context) async {
    final versionInfo = await checkForUpdate();
    if (versionInfo != null && context.mounted) {
      await showUpdateDialog(context, versionInfo: versionInfo);
    }
  }
}

/// Dialog thông báo có bản cập nhật mới
class UpdateDialog extends StatelessWidget {
  final AppVersionInfo versionInfo;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    required this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Cập nhật mới'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.new_releases, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Phiên bản v${versionInfo.version}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (versionInfo.releaseNotes != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Có gì mới:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              versionInfo.releaseNotes!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
          if (versionInfo.forceUpdate) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đây là bản cập nhật bắt buộc',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onLater != null)
          TextButton(
            onPressed: onLater,
            child: const Text('Để sau'),
          ),
        ElevatedButton.icon(
          onPressed: onUpdate,
          icon: const Icon(Icons.download),
          label: const Text('Cập nhật ngay'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Dialog hiển thị tiến trình tải xuống
class DownloadProgressDialog extends StatefulWidget {
  final String downloadUrl;
  final UpdateManager updateManager;

  const DownloadProgressDialog({
    super.key,
    required this.downloadUrl,
    required this.updateManager,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0;
  DownloadStatus _status = DownloadStatus.idle;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() {
    setState(() {
      _status = DownloadStatus.downloading;
    });

    widget.updateManager.downloadAndInstallApk(
      widget.downloadUrl,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }
      },
      onCompleted: () {
        if (mounted) {
          setState(() {
            _status = DownloadStatus.completed;
          });
          // Đóng dialog sau khi hoàn thành
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _status = DownloadStatus.failed;
            _errorMessage = error;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          if (_status == DownloadStatus.downloading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else if (_status == DownloadStatus.completed)
            const Icon(Icons.check_circle, color: Colors.green, size: 28)
          else if (_status == DownloadStatus.failed)
            const Icon(Icons.error, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Text(_getTitle()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_status == DownloadStatus.downloading) ...[
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng không đóng ứng dụng...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
          if (_status == DownloadStatus.completed) ...[
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Đang mở trình cài đặt...',
              style: TextStyle(fontSize: 16),
            ),
          ],
          if (_status == DownloadStatus.failed) ...[
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        if (_status == DownloadStatus.failed) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            child: const Text('Thử lại'),
          ),
        ],
      ],
    );
  }

  String _getTitle() {
    switch (_status) {
      case DownloadStatus.downloading:
        return 'Đang tải xuống...';
      case DownloadStatus.completed:
        return 'Hoàn thành!';
      case DownloadStatus.failed:
        return 'Lỗi';
      default:
        return 'Tải xuống';
    }
  }
}
