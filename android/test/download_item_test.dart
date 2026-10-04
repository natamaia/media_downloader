import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/data/models/download_item.dart';

void main() {
  group('DownloadItem Model Tests', () {
    test('serialization to Map and from Map', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = DownloadItem(
        downloadId: 'dl_test_123',
        url: 'https://youtube.com/watch?v=dQw4w9WgXcQ',
        provider: 'YouTube',
        title: 'Never Gonna Give You Up',
        formatType: AppConstants.formatMp4,
        quality: '1080p',
        status: AppConstants.statusDownloading,
        progressPercent: 45.5,
        downloadSpeed: '3.2 MB/s',
        etaSeconds: 40,
        downloadedBytes: 15000000,
        totalBytes: 30000000,
        filePath: '/storage/emulated/0/MediaDownloader/video.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toMap();
      expect(map['download_id'], 'dl_test_123');
      expect(map['status'], AppConstants.statusDownloading);
      expect(map['progress_percent'], 45.5);

      final restored = DownloadItem.fromMap(map);
      expect(restored.downloadId, item.downloadId);
      expect(restored.url, item.url);
      expect(restored.provider, item.provider);
      expect(restored.title, item.title);
      expect(restored.formatType, item.formatType);
      expect(restored.quality, item.quality);
      expect(restored.status, item.status);
      expect(restored.progressPercent, item.progressPercent);
      expect(restored.downloadSpeed, item.downloadSpeed);
      expect(restored.isActive, isTrue);
      expect(restored.isCompleted, isFalse);
    });

    test('state flags (isActive, isCompleted, isFailed, isCancelled)', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final base = DownloadItem(
        downloadId: 'dl_test_flags',
        url: 'https://example.com',
        title: 'Test',
        formatType: 'mp3',
        quality: '320k',
        createdAt: now,
        updatedAt: now,
      );

      expect(base.copyWith(status: AppConstants.statusPending).isActive, isTrue);
      expect(base.copyWith(status: AppConstants.statusDownloading).isActive, isTrue);
      expect(base.copyWith(status: AppConstants.statusConverting).isActive, isTrue);
      expect(base.copyWith(status: AppConstants.statusCompleted).isActive, isFalse);
      expect(base.copyWith(status: AppConstants.statusCompleted).isCompleted, isTrue);
      expect(base.copyWith(status: AppConstants.statusExists).isCompleted, isTrue);
      expect(base.copyWith(status: AppConstants.statusFailed).isFailed, isTrue);
      expect(base.copyWith(status: AppConstants.statusCancelled).isCancelled, isTrue);
    });

    test('mutable list operations work without unmodifiable list error', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = DownloadItem(
        downloadId: 'dl_test_mut',
        url: 'https://example.com',
        title: 'Test',
        formatType: 'mp3',
        quality: '320k',
        createdAt: now,
        updatedAt: now,
      );

      final list = <DownloadItem>[];
      expect(() => list.insert(0, item), returnsNormally);
      final copy = List<DownloadItem>.from(list);
      expect(() => copy.insert(0, item), returnsNormally);
      expect(copy.length, 2);
    });
  });
}
