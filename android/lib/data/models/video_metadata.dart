class VideoMetadata {
  final String url;
  final String provider;
  final String title;
  final int durationSeconds;
  final String? thumbnail;
  final List<String> qualities;
  final List<String> audioFormats;
  final String? directStreamUrl;

  const VideoMetadata({
    required this.url,
    required this.provider,
    required this.title,
    this.durationSeconds = 0,
    this.thumbnail,
    this.qualities = const ['best', '1080p', '720p', '480p', '360p'],
    this.audioFormats = const ['mp3_320k', 'mp3_192k', 'mp3_128k'],
    this.directStreamUrl,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      url: (json['url'] as String?) ?? '',
      provider: (json['provider'] as String?) ?? 'Generic',
      title: (json['title'] as String?) ?? 'Mídia',
      durationSeconds: (json['duration_seconds'] as int?) ?? 0,
      thumbnail: json['thumbnail'] as String?,
      qualities: (json['qualities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['best', '1080p', '720p', '480p', '360p'],
      audioFormats: (json['audio_formats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['mp3_320k', 'mp3_192k', 'mp3_128k'],
      directStreamUrl: json['direct_stream_url'] as String?,
    );
  }
}
