"""
Tests for ExtractorService and Provider Detection
"""

from src.backend.extractor import ExtractorService

def test_detect_provider():
    assert ExtractorService.detect_provider("https://www.youtube.com/watch?v=dQw4w9WgXcQ") == "YouTube"
    assert ExtractorService.detect_provider("https://youtu.be/dQw4w9WgXcQ") == "YouTube"
    assert ExtractorService.detect_provider("https://www.youtube.com/shorts/abc123xyz") == "YouTube Shorts"
    assert ExtractorService.detect_provider("https://music.youtube.com/watch?v=xyz") == "YouTube Music"
    assert ExtractorService.detect_provider("https://open.spotify.com/track/12345") == "Spotify"
    assert ExtractorService.detect_provider("https://www.deezer.com/track/67890") == "Deezer"
    assert ExtractorService.detect_provider("https://www.instagram.com/reel/abc123xyz") == "Instagram"
    assert ExtractorService.detect_provider("https://www.tiktok.com/@user/video/123") == "TikTok"
    assert ExtractorService.detect_provider("https://soundcloud.com/artist/song") == "SoundCloud"
    assert ExtractorService.detect_provider("https://vimeo.com/123456") == "Vimeo"
    assert ExtractorService.detect_provider("https://x.com/user/status/123456") == "X (Twitter)"
    assert ExtractorService.detect_provider("https://xwriter.io/post/123") == "X (Twitter)"
    assert ExtractorService.detect_provider("https://t.me/channel/123") == "Telegram"
    assert ExtractorService.detect_provider("https://www.facebook.com/reel/123456789") == "Facebook"
    assert ExtractorService.detect_provider("https://fb.watch/xyz123abc/") == "Facebook"
    assert ExtractorService.detect_provider("https://www.facebook.com/watch/?v=123456789") == "Facebook"
    assert ExtractorService.detect_provider("https://example.com/file.mp4") == "Vídeo Direto (MP4/HLS)"
    assert ExtractorService.detect_provider("https://example.com/podcast.mp3") == "Áudio Direto"
    assert ExtractorService.detect_provider("https://example.com/general-page") == "Site / Aula Web"

def test_resolve_target_standard():
    url = "https://www.youtube.com/watch?v=test"
    target, provider, is_audio = ExtractorService.resolve_target(url)
    assert target == url
    assert provider == "YouTube"
    assert is_audio is False

def test_resolve_target_facebook_reel():
    url = "https://www.facebook.com/reel/9876543210"
    target, provider, is_audio = ExtractorService.resolve_target(url)
    assert "m.facebook.com/watch/?v=9876543210" in target
    assert provider == "Facebook"
    assert is_audio is False
