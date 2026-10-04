import 'package:mobile_app/core/constants/app_constants.dart';

class DownloadItem {
  final int? id;
  final String downloadId;
  final String url;
  final String provider;
  final String title;
  final String formatType; // 'mp4' or 'mp3'
  final String quality;
  final String status;
  final double progressPercent;
  final String downloadSpeed;
  final int etaSeconds;
  final int downloadedBytes;
  final int totalBytes;
  final String? filePath;
  final String? thumbnailUrl;
  final String? errorMessage;
  final int createdAt;
  final int updatedAt;

  const DownloadItem({
    this.id,
    required this.downloadId,
    required this.url,
    this.provider = 'Generic',
    required this.title,
    required this.formatType,
    required this.quality,
    this.status = AppConstants.statusPending,
    this.progressPercent = 0.0,
    this.downloadSpeed = '0 KB/s',
    this.etaSeconds = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.filePath,
    this.thumbnailUrl,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      status == AppConstants.statusPending ||
      status == AppConstants.statusExtracting ||
      status == AppConstants.statusDownloading ||
      status == AppConstants.statusConverting;

  bool get isCompleted =>
      status == AppConstants.statusCompleted ||
      status == AppConstants.statusExists;

  bool get isFailed => status == AppConstants.statusFailed;
  bool get isCancelled => status == AppConstants.statusCancelled;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'download_id': downloadId,
      'url': url,
      'provider': provider,
      'title': title,
      'format_type': formatType,
      'quality': quality,
      'status': status,
      'progress_percent': progressPercent,
      'download_speed': downloadSpeed,
      'eta_seconds': etaSeconds,
      'downloaded_bytes': downloadedBytes,
      'total_bytes': totalBytes,
      'file_path': filePath,
      'thumbnail_url': thumbnailUrl,
      'error_message': errorMessage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'] as int?,
      downloadId: map['download_id'] as String,
      url: map['url'] as String,
      provider: (map['provider'] as String?) ?? 'Generic',
      title: map['title'] as String,
      formatType: map['format_type'] as String,
      quality: map['quality'] as String,
      status: map['status'] as String,
      progressPercent: (map['progress_percent'] as num?)?.toDouble() ?? 0.0,
      downloadSpeed: (map['download_speed'] as String?) ?? '0 KB/s',
      etaSeconds: (map['eta_seconds'] as int?) ?? 0,
      downloadedBytes: (map['downloaded_bytes'] as int?) ?? 0,
      totalBytes: (map['total_bytes'] as int?) ?? 0,
      filePath: map['file_path'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      errorMessage: map['error_message'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  DownloadItem copyWith({
    int? id,
    String? downloadId,
    String? url,
    String? provider,
    String? title,
    String? formatType,
    String? quality,
    String? status,
    double? progressPercent,
    String? downloadSpeed,
    int? etaSeconds,
    int? downloadedBytes,
    int? totalBytes,
    String? filePath,
    String? thumbnailUrl,
    String? errorMessage,
    int? createdAt,
    int? updatedAt,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      downloadId: downloadId ?? this.downloadId,
      url: url ?? this.url,
      provider: provider ?? this.provider,
      title: title ?? this.title,
      formatType: formatType ?? this.formatType,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      filePath: filePath ?? this.filePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
