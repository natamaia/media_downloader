import os
from pathlib import Path
from pydantic_settings import BaseSettings

# Base project path
BASE_DIR = Path(__file__).resolve().parent.parent.parent
USER_PROFILE = os.environ.get("USERPROFILE") or str(Path.home())

# Default OS System Directories for Media
MUSIC_DIR = str(Path(USER_PROFILE) / "Music" / "app_music")
VIDEOS_DIR = str(Path(USER_PROFILE) / "Videos" / "app_videos")

class Settings(BaseSettings):
    HOST: str = "127.0.0.1"
    PORT: int = 8000
    LOG_LEVEL: str = "INFO"
    WORKER_MAX_CONCURRENCY: int = 4
    DOWNLOAD_TEMP_DIR: str = str(BASE_DIR / "downloads" / "temp")
    DOWNLOAD_MUSIC_DIR: str = MUSIC_DIR
    DOWNLOAD_VIDEOS_DIR: str = VIDEOS_DIR
    DOWNLOAD_OUTPUT_DIR: str = VIDEOS_DIR
    INTERNAL_API_KEY: str = "local_internal_secret_key_12345"

    model_config = {
        "env_file": str(BASE_DIR / ".env"),
        "env_file_encoding": "utf-8",
        "extra": "ignore"
    }

settings = Settings()

# Ensure target system directories exist
os.makedirs(settings.DOWNLOAD_TEMP_DIR, exist_ok=True)
os.makedirs(settings.DOWNLOAD_MUSIC_DIR, exist_ok=True)
os.makedirs(settings.DOWNLOAD_VIDEOS_DIR, exist_ok=True)
