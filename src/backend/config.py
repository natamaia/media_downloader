import os
from pathlib import Path
try:
    from pydantic_settings import BaseSettings
    USE_PYDANTIC_SETTINGS = True
except ImportError:
    USE_PYDANTIC_SETTINGS = False
    class BaseSettings:
        pass

import sys
import subprocess
import tempfile

# Base project path
BASE_DIR = Path(__file__).resolve().parent.parent.parent
USER_PROFILE = os.environ.get("USERPROFILE") or os.environ.get("HOME") or str(Path.home())

def get_media_dir(xdg_type: str, fallback_dir_name: str, app_subdir: str) -> str:
    """Returns the native media directory respecting XDG standard on Linux or user profile on Windows."""
    if sys.platform != "win32":
        env_key = f"XDG_{xdg_type.upper()}_DIR"
        env_val = os.environ.get(env_key)
        if env_val and os.path.isdir(env_val):
            return str(Path(env_val) / app_subdir)
        try:
            val = subprocess.check_output(["xdg-user-dir", xdg_type.upper()], text=True, stderr=subprocess.DEVNULL).strip()
            if val and os.path.isdir(val):
                return str(Path(val) / app_subdir)
        except Exception:
            pass
        home = Path.home()
        for candidate in [fallback_dir_name, fallback_dir_name.capitalize(), "Músicas" if xdg_type == "MUSIC" else "Vídeos"]:
            cand_path = home / candidate
            if cand_path.is_dir():
                return str(cand_path / app_subdir)

    return str(Path(USER_PROFILE) / fallback_dir_name / app_subdir)

# Default OS System Directories for Media
MUSIC_DIR = get_media_dir("MUSIC", "Music", "app_music")
VIDEOS_DIR = get_media_dir("VIDEOS", "Videos", "app_videos")

if sys.platform == "win32":
    TEMP_DIR = str(Path(USER_PROFILE) / "AppData" / "Local" / "Temp" / "MediaDownloader")
else:
    TEMP_DIR = str(Path(tempfile.gettempdir()) / "MediaDownloader")

class Settings(BaseSettings if USE_PYDANTIC_SETTINGS else object):
    HOST: str = "127.0.0.1"
    PORT: int = 8000
    LOG_LEVEL: str = "INFO"
    WORKER_MAX_CONCURRENCY: int = 4
    DOWNLOAD_TEMP_DIR: str = TEMP_DIR
    DOWNLOAD_MUSIC_DIR: str = MUSIC_DIR
    DOWNLOAD_VIDEOS_DIR: str = VIDEOS_DIR
    DOWNLOAD_OUTPUT_DIR: str = VIDEOS_DIR
    INTERNAL_API_KEY: str = "local_internal_secret_key_12345"

    model_config = {
        "env_file": str(BASE_DIR / ".env"),
        "env_file_encoding": "utf-8",
        "extra": "ignore"
    }

    def __init__(self, **kwargs):
        if USE_PYDANTIC_SETTINGS:
            super().__init__(**kwargs)
        else:
            for k in dir(self.__class__):
                if k.isupper() and k in os.environ:
                    val = os.environ[k]
                    curr = getattr(self, k)
                    if isinstance(curr, int):
                        try:
                            setattr(self, k, int(val))
                        except ValueError:
                            pass
                    else:
                        setattr(self, k, val)

settings = Settings()

# Ensure target system directories exist safely
try:
    os.makedirs(settings.DOWNLOAD_TEMP_DIR, exist_ok=True)
    os.makedirs(settings.DOWNLOAD_MUSIC_DIR, exist_ok=True)
    os.makedirs(settings.DOWNLOAD_VIDEOS_DIR, exist_ok=True)
except Exception:
    pass
