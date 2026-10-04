import pytest
from src.backend.models import FormatType
from src.backend.workers import (
    WorkerFactory,
    YouTubeWorker,
    FacebookWorker,
    TwitterWorker,
    InstagramWorker,
    TikTokWorker,
    GenericWorker,
)

def test_worker_factory_dispatching():
    w_yt = WorkerFactory.create_worker("https://www.youtube.com/watch?v=dQw4w9WgXcQ", FormatType.MP4, "1080p")
    assert isinstance(w_yt, YouTubeWorker)
    assert w_yt.provider == "YouTube"

    w_shorts = WorkerFactory.create_worker("https://www.youtube.com/shorts/abc123xyz", FormatType.MP4, "720p")
    assert isinstance(w_shorts, YouTubeWorker)
    assert w_shorts.provider == "YouTube Shorts"

    w_fb = WorkerFactory.create_worker("https://www.facebook.com/share/r/1FUC7bwN2X/", FormatType.MP4, "720p")
    assert isinstance(w_fb, FacebookWorker)
    assert w_fb.provider == "Facebook"

    w_fb_reel = WorkerFactory.create_worker("https://www.facebook.com/reel/1795633708533674", FormatType.MP4, "720p")
    assert isinstance(w_fb_reel, FacebookWorker)
    assert w_fb_reel.provider == "Facebook"

    w_tw = WorkerFactory.create_worker("https://x.com/user/status/123456", FormatType.MP4, "720p")
    assert isinstance(w_tw, TwitterWorker)

    w_ig = WorkerFactory.create_worker("https://www.instagram.com/reel/abc123xyz", FormatType.MP4, "720p")
    assert isinstance(w_ig, InstagramWorker)

    w_tk = WorkerFactory.create_worker("https://www.tiktok.com/@user/video/123", FormatType.MP4, "720p")
    assert isinstance(w_tk, TikTokWorker)

    w_gen = WorkerFactory.create_worker("https://example.com/video.mp4", FormatType.MP4, "Original")
    assert isinstance(w_gen, GenericWorker)

def test_worker_initial_state():
    worker = WorkerFactory.create_worker("https://www.facebook.com/share/r/1FUC7bwN2X/", FormatType.MP4, "720p")
    assert worker.status.value == "PENDING"
    assert worker.progress_percent == 0.0
    assert worker.is_cancelled() is False
    worker.cancel()
    assert worker.is_cancelled() is True
    assert worker.status.value == "CANCELLED"
