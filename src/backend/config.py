import os
from pathlib import Path
from pydantic_settings import BaseSettings

# Base project path
BASE_DIR = Path(__file__).resolve().parent.parent.parent

class Settings(BaseSettings):
    HOST: str = "127.0.0.1"
    PORT: int = 8000
    LOG_LEVEL: str = "INFO"
    WORKER_MAX_CONCURRENCY: int = 4
    DOWNLOAD_TEMP_DIR: str = str(BASE_DIR / "downloads" / "temp")
    DOWNLOAD_OUTPUT_DIR: str = str(BASE_DIR / "downloads" / "output")
    INTERNAL_API_KEY: str = "local_internal_secret_key_12345"

    model_config = {
        "env_file": str(BASE_DIR / ".env"),
        "env_file_encoding": "utf-8",
        "extra": "ignore"
    }

settings = Settings()

# Ensure directories exist
os.makedirs(settings.DOWNLOAD_TEMP_DIR, exist_ok=True)
os.makedirs(settings.DOWNLOAD_OUTPUT_DIR, exist_ok=True)
