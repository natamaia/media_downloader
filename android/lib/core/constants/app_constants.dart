class AppConstants {
  static const String appName = 'MediaDownloader Pro';
  static const String appVersion = '1.0.0';
  static const String authorName = 'natamaia';
  static const String repoName = 'natamaia/media_downloader';
  static const String repoUrl = 'https://github.com/natamaia/media_downloader';

  // Platform Channel Names
  static const String engineChannel = 'com.mediadownloader/engine';
  static const String progressChannel = 'com.mediadownloader/progress';

  // Supported formats
  static const String formatMp4 = 'mp4';
  static const String formatMp3 = 'mp3';

  // Download statuses
  static const String statusPending = 'PENDING';
  static const String statusExtracting = 'EXTRACTING';
  static const String statusDownloading = 'DOWNLOADING';
  static const String statusConverting = 'CONVERTING';
  static const String statusCompleted = 'COMPLETED';
  static const String statusExists = 'EXISTS';
  static const String statusFailed = 'FAILED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusDeleted = 'DELETED';
}
