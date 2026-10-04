"""
Tests for System Configuration and Linux Paths
"""

import os
from pathlib import Path
from src.backend.config import settings, MUSIC_DIR, VIDEOS_DIR, TEMP_DIR, get_media_dir

def test_config_paths():
    assert MUSIC_DIR is not None
    assert VIDEOS_DIR is not None
    assert TEMP_DIR is not None
    assert "MediaDownloader" in TEMP_DIR

def test_target_directories_created():
    assert os.path.exists(settings.DOWNLOAD_TEMP_DIR)
    assert os.path.exists(settings.DOWNLOAD_MUSIC_DIR)
    assert os.path.exists(settings.DOWNLOAD_VIDEOS_DIR)

def test_get_media_dir():
    music = get_media_dir("MUSIC", "Music", "app_music")
    assert "app_music" in music
    videos = get_media_dir("VIDEOS", "Videos", "app_videos")
    assert "app_videos" in videos
