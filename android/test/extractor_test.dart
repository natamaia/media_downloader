import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/data/datasources/python_engine_service.dart';

void main() {
  group('PythonEngineService Provider Detection Tests', () {
    test('detects YouTube Shorts correctly', () {
      expect(
        PythonEngineService.detectProvider('https://www.youtube.com/shorts/aqz-KE-bpKQ'),
        'YouTube Shorts',
      );
      expect(
        PythonEngineService.detectProvider('https://youtube.com/shorts/3HnA9H1b6-E?feature=share'),
        'YouTube Shorts',
      );
      expect(
        PythonEngineService.detectProvider('https://m.youtube.com/shorts/xyz123abc45'),
        'YouTube Shorts',
      );
    });

    test('detects YouTube Standard and Music correctly', () {
      expect(
        PythonEngineService.detectProvider('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'YouTube',
      );
      expect(
        PythonEngineService.detectProvider('https://youtu.be/dQw4w9WgXcQ'),
        'YouTube',
      );
      expect(
        PythonEngineService.detectProvider('https://music.youtube.com/watch?v=12345'),
        'YouTube Music',
      );
    });

    test('detects Spotify, TikTok, Instagram, and Deezer', () {
      expect(
        PythonEngineService.detectProvider('https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT'),
        'Spotify',
      );
      expect(
        PythonEngineService.detectProvider('https://www.tiktok.com/@user/video/123456789'),
        'TikTok',
      );
      expect(
        PythonEngineService.detectProvider('https://www.instagram.com/reel/C3zYx_123/'),
        'Instagram',
      );
      expect(
        PythonEngineService.detectProvider('https://www.deezer.com/track/12345'),
        'Deezer',
      );
    });

    test('detects X (Twitter), Xwriter, and Telegram', () {
      expect(
        PythonEngineService.detectProvider('https://x.com/user/status/123456789'),
        'X (Twitter)',
      );
      expect(
        PythonEngineService.detectProvider('https://twitter.com/user/status/123456789'),
        'X (Twitter)',
      );
      expect(
        PythonEngineService.detectProvider('https://xwriter.io/post/123456'),
        'X (Twitter)',
      );
      expect(
        PythonEngineService.detectProvider('https://t.me/channel_name/123'),
        'Telegram',
      );
    });

    test('detects Facebook Reels, Watch, and Videos', () {
      expect(
        PythonEngineService.detectProvider('https://www.facebook.com/reel/123456789'),
        'Facebook',
      );
      expect(
        PythonEngineService.detectProvider('https://fb.watch/xyz123abc/'),
        'Facebook',
      );
      expect(
        PythonEngineService.detectProvider('https://www.facebook.com/watch/?v=123456789'),
        'Facebook',
      );
      expect(
        PythonEngineService.detectProvider('https://m.facebook.com/reel/987654321'),
        'Facebook',
      );
    });

    test('detects Course platforms, Direct Media, and Generic links', () {
      expect(
        PythonEngineService.detectProvider('https://app.hotmart.com/lesson/12345'),
        'Plataforma de Aulas',
      );
      expect(
        PythonEngineService.detectProvider('https://fast.wistia.net/embed/iframe/12345'),
        'Plataforma de Aulas',
      );
      expect(
        PythonEngineService.detectProvider('https://example.com/assets/video_aula.mp4'),
        'Vídeo Direto (MP4/HLS)',
      );
      expect(
        PythonEngineService.detectProvider('https://example.com/stream/playlist.m3u8'),
        'Vídeo Direto (MP4/HLS)',
      );
      expect(
        PythonEngineService.detectProvider('https://example.com/audio/podcast.mp3'),
        'Áudio Direto',
      );
      expect(
        PythonEngineService.detectProvider('https://minha-plataforma-ead.com/aula1'),
        'Site / Aula Web',
      );
    });
  });

  group('PythonEngineService Online Extraction Tests', () {
    test('extracts YouTube Shorts metadata', () async {
      final service = PythonEngineService();
      final meta = await service.extractOnlineMetadata('https://www.youtube.com/shorts/aqz-KE-bpKQ');
      expect(meta, isNotNull);
      expect(meta!.provider, 'YouTube Shorts');
      expect(meta.thumbnail, isNotNull);
      expect(meta.thumbnail, contains('aqz-KE-bpKQ'));
      expect(meta.qualities, contains('1080p'));
      expect(meta.audioFormats, contains('mp3_320k'));
    });

    test('extracts user YouTube video metadata correctly', () async {
      final service = PythonEngineService();
      final meta = await service.extractOnlineMetadata('https://youtu.be/HbVOA6nrVl0?is=yEUeGhN6zG4Rf7P4');
      expect(meta, isNotNull);
      expect(meta!.provider, 'YouTube');
      expect(meta.title, contains('Jeanne'));
      expect(meta.thumbnail, contains('HbVOA6nrVl0'));
    });
  });
}
