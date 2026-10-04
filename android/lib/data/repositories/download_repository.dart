import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/data/datasources/python_engine_service.dart';
import 'package:mobile_app/data/models/download_item.dart';
import 'package:mobile_app/data/models/video_metadata.dart';

class DownloadRepository {
  final PythonEngineService _engineService;
  final List<DownloadItem> _inMemoryDownloads = [];
  StreamSubscription? _progressSubscription;

  DownloadRepository({
    PythonEngineService? engineService,
  }) : _engineService = engineService ?? PythonEngineService();

  Future<List<DownloadItem>> getAllDownloads() async {
    return List<DownloadItem>.from(_inMemoryDownloads);
  }

  Future<VideoMetadata?> extractMetadata(String url) async {
    return await _engineService.extractMetadata(url);
  }

  Future<String> getDownloadDirectory(String formatType) async {
    Directory? baseDir;
    try {
      if (Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final targetPath = '${baseDir?.path ?? ''}/MediaDownloader';
    final dir = Directory(targetPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return targetPath;
  }

  Future<DownloadItem> createDownload({
    required String url,
    required String title,
    required String provider,
    required String formatType,
    required String quality,
    String? thumbnailUrl,
    String? directStreamUrl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final outputDir = await getDownloadDirectory(formatType);

    final downloadId = await _engineService.startDownload(
      url: (directStreamUrl != null && directStreamUrl.isNotEmpty) ? directStreamUrl : url,
      format: formatType,
      quality: quality,
      outputDir: outputDir,
      title: title,
    );

    final newItem = DownloadItem(
      downloadId: downloadId,
      url: url,
      provider: provider,
      title: title,
      formatType: formatType,
      quality: quality,
      status: AppConstants.statusDownloading,
      thumbnailUrl: thumbnailUrl,
      createdAt: now,
      updatedAt: now,
    );

    _inMemoryDownloads.insert(0, newItem);
    return newItem;
  }

  void subscribeToProgress(void Function(DownloadItem item) onUpdate) {
    _progressSubscription?.cancel();
    _progressSubscription = _engineService.progressStream.listen((data) {
      final downloadId = data['download_id'] as String?;
      if (downloadId == null) return;

      final status = data['status'] as String? ?? AppConstants.statusDownloading;
      final progress = (data['progress_percent'] as num?)?.toDouble() ?? 0.0;
      final speed = data['download_speed'] as String? ?? '0 KB/s';
      final eta = (data['eta_seconds'] as int?) ?? 0;
      final downloaded = (data['downloaded_bytes'] as int?) ?? 0;
      final total = (data['total_bytes'] as int?) ?? 0;
      final filePath = data['file_path'] as String?;
      final errorMessage = data['error_message'] as String?;

      final index = _inMemoryDownloads.indexWhere((d) => d.downloadId == downloadId);
      if (index != -1) {
        final current = _inMemoryDownloads[index];
        final updated = current.copyWith(
          progressPercent: progress,
          downloadSpeed: speed,
          etaSeconds: eta,
          downloadedBytes: downloaded,
          totalBytes: total,
          status: status,
          filePath: filePath ?? current.filePath,
          errorMessage: errorMessage ?? current.errorMessage,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        _inMemoryDownloads[index] = updated;
        onUpdate(updated);
      }
    });
  }

  Future<bool> cancelDownload(String downloadId) async {
    final success = await _engineService.cancelDownload(downloadId);
    final index = _inMemoryDownloads.indexWhere((d) => d.downloadId == downloadId);
    if (index != -1) {
      _inMemoryDownloads[index] = _inMemoryDownloads[index].copyWith(
        status: AppConstants.statusCancelled,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
    return success;
  }

  Future<void> deleteDownload(String downloadId, {bool deleteFileFromDisk = true}) async {
    final index = _inMemoryDownloads.indexWhere((d) => d.downloadId == downloadId);
    if (index != -1) {
      final item = _inMemoryDownloads[index];
      if (deleteFileFromDisk && item.filePath != null) {
        try {
          final file = File(item.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      _inMemoryDownloads.removeAt(index);
    }
  }

  Future<void> clearCompleted() async {
    _inMemoryDownloads.removeWhere((d) => !d.isActive);
  }

  void dispose() {
    _progressSubscription?.cancel();
  }
}
