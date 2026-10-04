import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/data/models/video_metadata.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;

class PythonEngineService {
  static const MethodChannel _engineChannel =
      MethodChannel(AppConstants.engineChannel);
  static const EventChannel _progressChannel =
      EventChannel(AppConstants.progressChannel);

  final Set<String> _cancelledDownloadIds = <String>{};

  final StreamController<Map<String, dynamic>> _internalProgressController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>>? _combinedProgressStream;

  Stream<Map<String, dynamic>> get progressStream {
    if (_combinedProgressStream == null) {
      final nativeStream = _progressChannel.receiveBroadcastStream().map((event) {
        if (event is String) {
          return json.decode(event) as Map<String, dynamic>;
        } else if (event is Map) {
          return Map<String, dynamic>.from(event);
        }
        return <String, dynamic>{};
      }).handleError((err) {
        dev.log('Aviso no EventChannel nativo: $err', name: 'PythonEngineService');
      });

      // Mescla o canal nativo do Android com o canal de download direto em Dart
      _combinedProgressStream = StreamGroup.merge([
        nativeStream,
        _internalProgressController.stream,
      ]);
    }
    return _combinedProgressStream!;
  }

  Future<VideoMetadata?> extractMetadata(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    // 1. Tenta extrair via Canal Nativo (Python yt-dlp)
    try {
      final resultJson = await _engineChannel.invokeMethod<String>(
        'extractMetadata',
        {'url': cleanUrl},
      );
      if (resultJson != null && resultJson.isNotEmpty) {
        final decoded = json.decode(resultJson) as Map<String, dynamic>;
        if (decoded['success'] == true && decoded['data'] != null) {
          return VideoMetadata.fromJson(decoded['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      dev.log('Canal nativo indisponível ou falhou, acionando extrator universal: $e', name: 'PythonEngineService');
    }

    // 2. Extrator Universal Direto (YouTube, Shorts, Xwriter, Twitter, Telegram, Aulas, Direct MP4/m3u8)
    return await extractOnlineMetadata(cleanUrl);
  }

  Future<VideoMetadata?> extractOnlineMetadata(String url) async {
    final provider = detectProvider(url);
    final isShorts = provider == 'YouTube Shorts';

    try {
      if (provider == 'YouTube' || isShorts) {
        return await _extractYouTubeMetadata(url, isShorts: isShorts);
      } else if (provider == 'Facebook') {
        return await _extractFacebookMetadata(url);
      } else if (provider == 'X (Twitter)') {
        return await _extractXTwitterMetadata(url);
      } else if (provider == 'Telegram') {
        return await _extractTelegramMetadata(url);
      } else if (provider == 'Spotify') {
        return await _extractSpotifyMetadata(url);
      } else if (provider == 'TikTok') {
        return await _extractTikTokMetadata(url);
      } else if (provider == 'Vimeo') {
        return await _extractVimeoMetadata(url);
      } else if (provider == 'Vídeo Direto (MP4/HLS)' || provider == 'Áudio Direto') {
        return _extractDirectMediaMetadata(url, provider);
      } else {
        // Plataformas de aulas (Hotmart, Wistia, Loom, etc.) e sites genéricos
        return await _extractWebPageMetadata(url, provider);
      }
    } catch (e, stack) {
      dev.log('Erro na extração online para $url: $e', name: 'PythonEngineService', error: e, stackTrace: stack);
    }

    return _generateSmartFallback(url, provider);
  }

  static String detectProvider(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('music.youtube.com')) {
      return 'YouTube Music';
    } else if (lower.contains('youtube.com/shorts') || lower.contains('/shorts/')) {
      return 'YouTube Shorts';
    } else if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return 'YouTube';
    } else if (lower.contains('x.com') || lower.contains('twitter.com') || lower.contains('xwriter') || lower.contains('twitsave')) {
      return 'X (Twitter)';
    } else if (lower.contains('t.me') || lower.contains('telegram.me')) {
      return 'Telegram';
    } else if (lower.contains('spotify.com')) {
      return 'Spotify';
    } else if (lower.contains('deezer.com') || lower.contains('deezer.page.link')) {
      return 'Deezer';
    } else if (lower.contains('instagram.com') || lower.contains('instagr.am')) {
      return 'Instagram';
    } else if (lower.contains('tiktok.com')) {
      return 'TikTok';
    } else if (lower.contains('vimeo.com')) {
      return 'Vimeo';
    } else if (lower.contains('soundcloud.com')) {
      return 'SoundCloud';
    } else if (anyContains(lower, ['hotmart', 'wistia', 'loom.com', 'kaltura', 'streamable', 'pandavideo', 'vdo.ninja'])) {
      return 'Plataforma de Aulas';
    } else if (lower.contains('reddit.com') || lower.contains('v.redd.it')) {
      return 'Reddit';
    } else if (lower.contains('facebook.com') || lower.contains('fb.watch') || lower.contains('fb.com') || lower.contains('fb.gg')) {
      return 'Facebook';
    } else if (anyContains(lower, ['.mp4', '.m3u8', '.mpd', '.webm', '.mkv', '.mov', '.ts'])) {
      return 'Vídeo Direto (MP4/HLS)';
    } else if (anyContains(lower, ['.mp3', '.m4a', '.aac', '.wav', '.ogg', '.flac'])) {
      return 'Áudio Direto';
    }
    return 'Site / Aula Web';
  }

  static bool anyContains(String text, List<String> patterns) {
    for (final p in patterns) {
      if (text.contains(p)) return true;
    }
    return false;
  }

  Future<VideoMetadata?> _extractYouTubeMetadata(String url, {required bool isShorts}) async {
    final videoId = _extractYouTubeId(url);
    String title = isShorts ? 'YouTube Short' : 'Vídeo do YouTube';
    String? thumbnail = videoId != null ? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg' : null;
    int duration = isShorts ? 60 : 240;

    // 1. Tenta extração direta rápida via YoutubeExplode
    try {
      final yt = yt_exp.YoutubeExplode();
      try {
        final video = await yt.videos.get(url).timeout(const Duration(seconds: 5));
        title = video.title;
        final highRes = video.thumbnails.highResUrl;
        if (highRes.isNotEmpty) {
          thumbnail = highRes;
        }
        if (video.duration != null) {
          duration = video.duration!.inSeconds;
        }
      } finally {
        yt.close();
      }
    } catch (_) {
      // 2. Fallback para oEmbed do YouTube
      try {
        final oembedUrl = 'https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json';
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
        final request = await client.getUrl(Uri.parse(oembedUrl));
        request.headers.set('User-Agent', 'Mozilla/5.0');
        final response = await request.close();

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          title = data['title'] as String? ?? title;
          thumbnail = data['thumbnail_url'] as String? ?? thumbnail;
        }
        client.close();
      } catch (_) {}
    }

    return VideoMetadata(
      url: url,
      provider: isShorts ? 'YouTube Shorts' : 'YouTube',
      title: title,
      durationSeconds: duration,
      thumbnail: thumbnail,
      qualities: isShorts
          ? const ['1080p', '720p', '480p']
          : const ['1080p', '720p', '480p', '360p'],
      audioFormats: const ['mp3_320k', 'mp3_192k', 'mp3_128k'],
    );
  }

  Future<VideoMetadata?> _extractXTwitterMetadata(String url) async {
    String title = 'X (Twitter) Vídeo';
    String? thumbnail;

    try {
      final oembedUrl = 'https://publish.twitter.com/oembed?url=${Uri.encodeComponent(url)}';
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(oembedUrl));
      request.headers.set('User-Agent', 'Mozilla/5.0');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;
        final rawHtml = data['html'] as String? ?? '';
        final cleanText = rawHtml.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
        if (cleanText.isNotEmpty) {
          title = cleanText.length > 80 ? '${cleanText.substring(0, 80)}...' : cleanText;
        }
      }
      client.close();
    } catch (_) {}

    return VideoMetadata(
      url: url,
      provider: 'X (Twitter)',
      title: title,
      durationSeconds: 45,
      thumbnail: thumbnail,
      qualities: const ['Original', '1080p', '720p', '480p'],
      audioFormats: const ['mp3_320k', 'mp3_192k'],
    );
  }

  Future<VideoMetadata?> _extractTelegramMetadata(String url) async {
    String title = 'Telegram Mídia';
    String? thumbnail;

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'Mozilla/5.0 (compatible; Googlebot/2.1)');
      final response = await request.close();

      if (response.statusCode == 200) {
        final html = await response.transform(utf8.decoder).join();
        final ogTitle = RegExp(r'''<meta\s+property=["']og:title["']\s+content=["'](.*?)["']''', caseSensitive: false).firstMatch(html);
        if (ogTitle != null) title = ogTitle.group(1) ?? title;

        final ogImg = RegExp(r'''<meta\s+property=["']og:image["']\s+content=["'](.*?)["']''', caseSensitive: false).firstMatch(html);
        if (ogImg != null) thumbnail = ogImg.group(1);
      }
      client.close();
    } catch (_) {}

    return VideoMetadata(
      url: url,
      provider: 'Telegram',
      title: title,
      durationSeconds: 60,
      thumbnail: thumbnail,
      qualities: const ['Original', '720p', '480p'],
      audioFormats: const ['mp3_320k', 'mp3_192k'],
    );
  }

  VideoMetadata _extractDirectMediaMetadata(String url, String provider) {
    String title = 'Vídeo Baixado';
    try {
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'media';
      final clean = filename.replaceAll(RegExp(r'\.(mp4|m3u8|mpd|webm|mkv|mov|ts|mp3|m4a|aac|wav)$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[-_]+'), ' ').trim();
      if (clean.isNotEmpty) {
        title = clean[0].toUpperCase() + clean.substring(1);
      }
    } catch (_) {}

    final isAudio = provider == 'Áudio Direto';
    return VideoMetadata(
      url: url,
      provider: provider,
      title: title,
      durationSeconds: 0,
      qualities: isAudio ? const ['mp3_320k', 'mp3_192k'] : const ['Original (Melhor)', '1080p', '720p', '480p'],
      audioFormats: const ['mp3_320k', 'mp3_192k', 'mp3_128k'],
    );
  }

  Future<VideoMetadata?> _extractWebPageMetadata(String url, String provider) async {
    String title = 'Aula / Conteúdo Web';
    String? thumbnail;

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
      final response = await request.close();

      if (response.statusCode == 200) {
        final html = await response.transform(utf8.decoder).join();

        final ogTitle = RegExp(r'''<meta\s+property=["']og:title["']\s+content=["'](.*?)["']''', caseSensitive: false).firstMatch(html);
        final tagTitle = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(html);
        if (ogTitle != null) {
          title = ogTitle.group(1) ?? title;
        } else if (tagTitle != null) {
          title = tagTitle.group(1) ?? title;
        }

        final ogImg = RegExp(r'''<meta\s+property=["']og:image["']\s+content=["'](.*?)["']''', caseSensitive: false).firstMatch(html);
        if (ogImg != null) thumbnail = ogImg.group(1);
      }
      client.close();
    } catch (_) {}

    return VideoMetadata(
      url: url,
      provider: provider,
      title: title.trim(),
      durationSeconds: 0,
      thumbnail: thumbnail,
      qualities: const ['Original', '1080p', '720p', '480p'],
      audioFormats: const ['mp3_320k', 'mp3_192k'],
    );
  }

  Future<VideoMetadata?> _extractSpotifyMetadata(String url) async {
    String title = 'Música Spotify';
    String? thumbnail;

    try {
      final oembedUrl = 'https://open.spotify.com/oembed?url=${Uri.encodeComponent(url)}';
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(oembedUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;
        title = data['title'] as String? ?? title;
        thumbnail = data['thumbnail_url'] as String?;
      }
      client.close();
    } catch (_) {}

    return VideoMetadata(
      url: url,
      provider: 'Spotify',
      title: title,
      durationSeconds: 195,
      thumbnail: thumbnail,
      qualities: const ['mp3_320k', 'mp3_192k', 'mp3_128k'],
      audioFormats: const ['mp3_320k', 'mp3_192k', 'mp3_128k'],
    );
  }

  Future<VideoMetadata?> _extractTikTokMetadata(String url) async {
    String title = 'TikTok Vídeo';
    String? thumbnail;

    try {
      final oembedUrl = 'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}';
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(oembedUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;
        title = data['title'] as String? ?? title;
        thumbnail = data['thumbnail_url'] as String?;
      }
      client.close();
    } catch (_) {}

    return VideoMetadata(
      url: url,
      provider: 'TikTok',
      title: title,
      durationSeconds: 45,
      thumbnail: thumbnail,
      qualities: const ['1080p', '720p', 'best'],
      audioFormats: const ['mp3_320k', 'mp3_192k'],
    );
  }

  Future<VideoMetadata?> _extractVimeoMetadata(String url) async {
    String title = 'Vimeo Vídeo';
    String? thumbnail;

    try {
      final oembedUrl = 'https://vimeo.com/api/oembed.json?url=${Uri.encodeComponent(url)}';
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(oembedUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;
        title = data['title'] as String? ?? title;
        thumbnail = data['thumbnail_url'] as String?;
      }
      client.close();
    } catch (_) {}

    return VideoMetadata(
      url: url,
      provider: 'Vimeo',
      title: title,
      durationSeconds: 300,
      thumbnail: thumbnail,
      qualities: const ['1080p', '720p', 'best'],
      audioFormats: const ['mp3_320k', 'mp3_192k'],
    );
  }

  static String _cleanJsonUrl(String raw) {
    return raw
        .replaceAll(r'\/', '/')
        .replaceAll(r'\u0025', '%')
        .replaceAll(r'\u0026', '&')
        .replaceAll('&amp;', '&');
  }

  Future<VideoMetadata?> _extractFacebookMetadata(String url) async {
    String title = 'Facebook Vídeo';
    String? thumbnail;
    String? directStreamUrl;
    int duration = 60;

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..findProxy = null;

      String targetUrl = url;

      // 1. Resolver redirecionamento para URLs curtas (ex: fb.watch ou share/r ou share/v)
      if (url.contains('fb.watch') || url.contains('/share/')) {
        try {
          final headReq = await client.getUrl(Uri.parse(url));
          headReq.followRedirects = false;
          headReq.headers.set(
            'User-Agent',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          );
          headReq.headers.set('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
          headReq.headers.set('Sec-Fetch-Mode', 'navigate');
          final headResp = await headReq.close();
          if (headResp.isRedirect) {
            final loc = headResp.headers.value(HttpHeaders.locationHeader);
            if (loc != null && loc.isNotEmpty) {
              targetUrl = loc.startsWith('http') ? loc : Uri.parse(url).resolve(loc).toString();
            }
          }
        } catch (_) {}
      }

      // 2. Extrai ID se presente no link
      final reelMatch = RegExp(r'(?:reel|reels|videos|v)[/=](\d+)', caseSensitive: false).firstMatch(targetUrl);
      final videoId = reelMatch?.group(1);

      // Usar a versão mobile para obter HTML com links diretos
      final fetchUrl = videoId != null
          ? 'https://m.facebook.com/watch/?v=$videoId&_rdr'
          : targetUrl.replaceFirst('www.facebook.com', 'm.facebook.com');

      final req = await client.getUrl(Uri.parse(fetchUrl));
      req.followRedirects = true;
      req.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      );
      req.headers.set('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
      req.headers.set('Accept-Language', 'en-US,en;q=0.9');
      req.headers.set('Sec-Fetch-Mode', 'navigate');
      final resp = await req.close();

      if (resp.statusCode == 200) {
        final html = await resp.transform(utf8.decoder).join();

        // Extrai título
        final ogTitle = RegExp(r'''<meta\s+property=["']og:title["']\s+content=["'](.*?)["']''', caseSensitive: false).firstMatch(html);
        final tagTitle = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(html);
        if (ogTitle != null && (ogTitle.group(1)?.trim().isNotEmpty ?? false)) {
          title = ogTitle.group(1)!.trim();
        } else if (tagTitle != null && (tagTitle.group(1)?.trim().isNotEmpty ?? false)) {
          title = tagTitle.group(1)!.trim();
        }

        // Extrai thumbnail
        final ogImg = RegExp(r'''<meta\s+property=["']og:image["']\s+content=["'](.*?)["']''', caseSensitive: false).firstMatch(html);
        if (ogImg != null) {
          thumbnail = _cleanJsonUrl(ogImg.group(1) ?? '');
        }

        // Extrai stream de vídeo MP4 direto
        final videoPatterns = [
          RegExp(r'''["']browser_native_hd_url["']\s*:\s*["'](.*?)["']'''),
          RegExp(r'''["']playable_url_quality_hd["']\s*:\s*["'](.*?)["']'''),
          RegExp(r'''["']browser_native_sd_url["']\s*:\s*["'](.*?)["']'''),
          RegExp(r'''["']playable_url["']\s*:\s*["'](.*?)["']'''),
          RegExp(r'''["']hd_src["']\s*:\s*["'](.*?)["']'''),
          RegExp(r'''["']sd_src["']\s*:\s*["'](.*?)["']'''),
          RegExp(r'''<meta\s+property=["']og:video:secure_url["']\s+content=["'](.*?)["']''', caseSensitive: false),
          RegExp(r'''<meta\s+property=["']og:video["']\s+content=["'](.*?)["']''', caseSensitive: false),
        ];

        for (final p in videoPatterns) {
          final m = p.firstMatch(html);
          if (m != null) {
            final raw = m.group(1);
            if (raw != null && raw.isNotEmpty && !raw.contains('blank.mp4')) {
              directStreamUrl = _cleanJsonUrl(raw);
              break;
            }
          }
        }
      }
      client.close();
    } catch (e) {
      dev.log('Erro ao extrair metadados do Facebook: $e', name: 'PythonEngineService');
    }

    // Limpa título de sufixos de branding
    title = title
        .replaceAll(RegExp(r'\s*\|\s*Facebook.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\s*Vídeo de\s*', caseSensitive: false), '')
        .trim();
    if (title.isEmpty) title = 'Facebook Reels / Vídeo';

    return VideoMetadata(
      url: url,
      provider: 'Facebook',
      title: title,
      durationSeconds: duration,
      thumbnail: thumbnail,
      qualities: const ['Original (HD)', '720p', '480p'],
      audioFormats: const ['mp3_320k', 'mp3_192k'],
      directStreamUrl: directStreamUrl,
    );
  }

  VideoMetadata _generateSmartFallback(String url, String provider) {
    String? thumb;
    String title = 'Mídia ($provider)';

    if (provider == 'YouTube' || provider == 'YouTube Shorts') {
      final videoId = _extractYouTubeId(url);
      if (videoId != null) {
        thumb = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
        title = provider == 'YouTube Shorts' ? 'YouTube Short ($videoId)' : 'YouTube Vídeo ($videoId)';
      }
    }

    return VideoMetadata(
      url: url,
      provider: provider,
      title: title,
      durationSeconds: provider == 'YouTube Shorts' ? 60 : 180,
      thumbnail: thumb,
      qualities: const ['1080p', '720p', '480p', '360p'],
      audioFormats: const ['mp3_320k', 'mp3_192k', 'mp3_128k'],
    );
  }

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|shorts)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<String> startDownload({
    required String url,
    required String format,
    required String quality,
    required String outputDir,
    String title = 'Mídia',
  }) async {
    final downloadId = 'dl_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Tenta canal nativo Android
    try {
      final nativeId = await _engineChannel.invokeMethod<String>(
        'startDownload',
        {
          'url': url,
          'format': format,
          'quality': quality,
          'outputDir': outputDir,
        },
      );
      if (nativeId != null && nativeId.isNotEmpty) {
        return nativeId;
      }
    } catch (e) {
      dev.log('Canal nativo indisponível para download, iniciando download direto: $e', name: 'PythonEngineService');
    }

    // 2. Se for link direto (.mp4, .mp3, etc.) ou se o canal nativo não estiver conectado:
    // Dispara download direto em Dart via HTTP / YoutubeExplode
    _startDirectDownload(
      downloadId: downloadId,
      url: url,
      format: format,
      quality: quality,
      outputDir: outputDir,
      title: title,
    );

    return downloadId;
  }

  void _startDirectDownload({
    required String downloadId,
    required String url,
    required String format,
    required String quality,
    required String outputDir,
    required String title,
  }) {
    Future.microtask(() async {
      String downloadUrl = url;
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
      final isAudio = format.toLowerCase().contains('mp3') || format.toLowerCase().contains('audio');
      final ext = isAudio ? 'mp3' : 'mp4';
      final cleanTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
      final filePath = '$outputDir/${cleanTitle.isEmpty ? "download" : cleanTitle}.$ext';

      try {
        _internalProgressController.add({
          'download_id': downloadId,
          'status': AppConstants.statusDownloading,
          'progress_percent': 0.0,
          'download_speed': '0 KB/s',
          'eta_seconds': 0,
          'downloaded_bytes': 0,
          'total_bytes': 0,
          'file_path': filePath,
        });

        final provider = detectProvider(downloadUrl);

        // Se for YouTube (padrão, Shorts ou Music), faz streaming direto via YoutubeExplode
        if (provider.contains('YouTube')) {
          await _downloadYouTubeMedia(
            downloadId: downloadId,
            url: downloadUrl,
            format: format,
            quality: quality,
            outputDir: outputDir,
            cleanTitle: cleanTitle,
            filePath: filePath,
          );
          return;
        }

        // Se for Facebook e a URL não for um stream direto .mp4, resolve o stream CDN
        if (provider == 'Facebook' && !downloadUrl.contains('.mp4')) {
          final fbMeta = await _extractFacebookMetadata(downloadUrl);
          if (fbMeta?.directStreamUrl != null && fbMeta!.directStreamUrl!.isNotEmpty) {
            downloadUrl = fbMeta.directStreamUrl!;
          }
        }

        final isFbStream = downloadUrl.contains('fbcdn.net') || downloadUrl.contains('facebook.com');
        final request = await client.getUrl(Uri.parse(downloadUrl));
        if (isFbStream) {
          request.headers.set('User-Agent', 'facebookexternalhit/1.1');
          request.headers.set('Accept', '*/*');
          request.headers.set('Sec-Fetch-Mode', 'navigate');
          request.headers.set('Referer', 'https://m.facebook.com/');
        } else {
          request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36');
          request.headers.set('Accept', '*/*');
        }
        final response = await request.close();

        // Se o servidor retornou HTML em vez de arquivo de mídia, não grava arquivo corrompido
        final mimeType = response.headers.contentType?.mimeType.toLowerCase() ?? '';
        if (mimeType.contains('text/html')) {
          final prov = detectProvider(downloadUrl);
          throw Exception('O servidor retornou uma página web (HTML) em vez do arquivo de mídia. O link do $prov pode ser privado, exigir login ou requerer um link direto.');
        }

        if (response.statusCode >= 200 && response.statusCode < 400) {
          final totalBytes = response.contentLength;
          int downloadedBytes = 0;
          final stopwatch = Stopwatch()..start();

          final file = File(filePath);
          final sink = file.openWrite();
          bool isFirstChunk = true;

          await for (final chunk in response) {
            if (_cancelledDownloadIds.contains(downloadId)) {
              await sink.close();
              if (await file.exists()) await file.delete();
              _internalProgressController.add({
                'download_id': downloadId,
                'status': AppConstants.statusCancelled,
                'file_path': filePath,
              });
              return;
            }

            if (isFirstChunk) {
              isFirstChunk = false;
              if (chunk.length >= 10) {
                final headerStr = String.fromCharCodes(chunk.take(15)).toLowerCase();
                if (headerStr.contains('<!doc') || headerStr.contains('<html')) {
                  await sink.close();
                  if (await file.exists()) await file.delete();
                  throw Exception('Conteúdo recebido é uma página HTML de login, não um vídeo executável.');
                }
              }
            }

            sink.add(chunk);
            downloadedBytes += chunk.length;

            final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
            String speed = '0 KB/s';
            int eta = 0;
            if (elapsed > 0) {
              final bytesSec = downloadedBytes / elapsed;
              if (bytesSec > 1024 * 1024) {
                speed = '${(bytesSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
              } else {
                speed = '${(bytesSec / 1024).toStringAsFixed(1)} KB/s';
              }
              if (totalBytes > downloadedBytes && bytesSec > 0) {
                eta = ((totalBytes - downloadedBytes) / bytesSec).toInt();
              }
            }

            final progress = totalBytes > 0
                ? ((downloadedBytes / totalBytes) * 100).clamp(0.0, 99.0)
                : 50.0;

            _internalProgressController.add({
              'download_id': downloadId,
              'status': AppConstants.statusDownloading,
              'progress_percent': progress,
              'download_speed': speed,
              'eta_seconds': eta,
              'downloaded_bytes': downloadedBytes,
              'total_bytes': totalBytes > 0 ? totalBytes : downloadedBytes,
              'file_path': filePath,
            });
          }

          await sink.flush();
          await sink.close();

          _internalProgressController.add({
            'download_id': downloadId,
            'status': AppConstants.statusCompleted,
            'progress_percent': 100.0,
            'download_speed': '0 KB/s',
            'eta_seconds': 0,
            'downloaded_bytes': downloadedBytes,
            'total_bytes': downloadedBytes,
            'file_path': filePath,
          });
        } else {
          throw Exception('Servidor retornou HTTP ${response.statusCode}');
        }
      } catch (e) {
        dev.log('Erro no download direto para $url: $e', name: 'PythonEngineService');
        _internalProgressController.add({
          'download_id': downloadId,
          'status': AppConstants.statusFailed,
          'error_message': 'Falha no download da mídia: $e',
          'file_path': filePath,
        });
      } finally {
        client.close();
      }
    });
  }

  Future<void> _downloadYouTubeMedia({
    required String downloadId,
    required String url,
    required String format,
    required String quality,
    required String outputDir,
    required String cleanTitle,
    required String filePath,
  }) async {
    final yt = yt_exp.YoutubeExplode();
    String targetPath = filePath;
    try {
      final video = await yt.videos.get(url);
      final resolvedName = (cleanTitle.isEmpty || cleanTitle == 'Mídia' || cleanTitle == 'download')
          ? video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim()
          : cleanTitle;

      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final isAudio = format.toLowerCase().contains('mp3') || format.toLowerCase().contains('audio');
      yt_exp.StreamInfo? streamInfo;

      if (isAudio) {
        streamInfo = manifest.audioOnly.withHighestBitrate();
        final ext = streamInfo.container.name == 'webm' ? 'webm' : (format.toLowerCase().contains('mp3') ? 'mp3' : 'm4a');
        targetPath = '$outputDir/$resolvedName.$ext';
      } else {
        if (manifest.muxed.isNotEmpty) {
          final q = quality.toLowerCase();
          if (q.contains('720')) {
            streamInfo = manifest.muxed.firstWhere(
              (s) => s.qualityLabel.contains('720'),
              orElse: () => manifest.muxed.withHighestBitrate(),
            );
          } else if (q.contains('360')) {
            streamInfo = manifest.muxed.firstWhere(
              (s) => s.qualityLabel.contains('360'),
              orElse: () => manifest.muxed.withHighestBitrate(),
            );
          } else if (q.contains('480')) {
            streamInfo = manifest.muxed.firstWhere(
              (s) => s.qualityLabel.contains('480'),
              orElse: () => manifest.muxed.withHighestBitrate(),
            );
          } else {
            streamInfo = manifest.muxed.withHighestBitrate();
          }
        } else {
          streamInfo = manifest.video.withHighestBitrate();
        }
        targetPath = '$outputDir/$resolvedName.mp4';
      }

      final file = File(targetPath);
      final sink = file.openWrite();
      final stream = yt.videos.streamsClient.get(streamInfo);
      final totalBytes = streamInfo.size.totalBytes;
      int downloadedBytes = 0;
      final stopwatch = Stopwatch()..start();

      await for (final chunk in stream) {
        if (_cancelledDownloadIds.contains(downloadId)) {
          await sink.close();
          if (await file.exists()) await file.delete();
          _internalProgressController.add({
            'download_id': downloadId,
            'status': AppConstants.statusCancelled,
            'file_path': targetPath,
          });
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
        String speed = '0 KB/s';
        int eta = 0;
        if (elapsed > 0) {
          final bytesSec = downloadedBytes / elapsed;
          if (bytesSec > 1024 * 1024) {
            speed = '${(bytesSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
          } else {
            speed = '${(bytesSec / 1024).toStringAsFixed(1)} KB/s';
          }
          if (totalBytes > downloadedBytes && bytesSec > 0) {
            eta = ((totalBytes - downloadedBytes) / bytesSec).toInt();
          }
        }

        final progress = totalBytes > 0
            ? ((downloadedBytes / totalBytes) * 100).clamp(0.0, 99.0)
            : 50.0;

        _internalProgressController.add({
          'download_id': downloadId,
          'status': AppConstants.statusDownloading,
          'progress_percent': progress,
          'download_speed': speed,
          'eta_seconds': eta,
          'downloaded_bytes': downloadedBytes,
          'total_bytes': totalBytes,
          'file_path': targetPath,
        });
      }

      await sink.flush();
      await sink.close();

      _internalProgressController.add({
        'download_id': downloadId,
        'status': AppConstants.statusCompleted,
        'progress_percent': 100.0,
        'download_speed': '0 KB/s',
        'eta_seconds': 0,
        'downloaded_bytes': downloadedBytes,
        'total_bytes': downloadedBytes,
        'file_path': targetPath,
      });
    } catch (e) {
      dev.log('Erro no download do YouTube para $url: $e', name: 'PythonEngineService');
      _internalProgressController.add({
        'download_id': downloadId,
        'status': AppConstants.statusFailed,
        'error_message': 'Falha no download da mídia: $e',
        'file_path': targetPath,
      });
    } finally {
      yt.close();
    }
  }

  Future<bool> cancelDownload(String downloadId) async {
    _cancelledDownloadIds.add(downloadId);
    try {
      final result = await _engineChannel.invokeMethod<bool>(
        'cancelDownload',
        {'downloadId': downloadId},
      );
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  void dispose() {
    _internalProgressController.close();
  }
}

/// Helper para mesclar streams nativo e direto
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>.broadcast();
    for (final s in streams) {
      s.listen(
        controller.add,
        onError: controller.addError,
      );
    }
    return controller.stream;
  }
}
