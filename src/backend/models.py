from enum import Enum
from typing import List, Optional
try:
    from pydantic import BaseModel, Field
except ImportError:
    class BaseModel:
        def __init__(self, **kwargs):
            for k in dir(self.__class__):
                if not k.startswith('_') and not callable(getattr(self.__class__, k)):
                    val = getattr(self.__class__, k)
                    if isinstance(val, list):
                        setattr(self, k, list(val))
                    elif isinstance(val, dict):
                        setattr(self, k, dict(val))
                    else:
                        setattr(self, k, val)
            for k, v in kwargs.items():
                setattr(self, k, v)

        def dict(self, *args, **kwargs):
            return {k: v for k, v in self.__dict__.items() if not k.startswith('_')}

        def model_dump(self, *args, **kwargs):
            return self.dict()

    def Field(default=None, description=None, **kwargs):
        return default

class FormatType(str, Enum):
    MP4 = "mp4"
    MP3 = "mp3"

class WorkerStatus(str, Enum):
    PENDING = "PENDING"
    EXTRACTING = "EXTRACTING"
    DOWNLOADING = "DOWNLOADING"
    CONVERTING = "CONVERTING"
    COMPLETED = "COMPLETED"
    EXISTS = "EXISTS"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"
    DELETED = "DELETED"

class InfoRequest(BaseModel):
    url: str = Field(..., description="Target URL for video/audio extraction")

class QualityOption(BaseModel):
    id: str
    label: str
    height: Optional[int] = None
    ext: str = "mp4"

class VideoInfoResponse(BaseModel):
    url: str
    provider: str = "Generic"
    title: str
    duration_seconds: int = 0
    thumbnail: Optional[str] = None
    qualities: List[str] = []
    audio_formats: List[str] = ["mp3_320k", "mp3_192k", "mp3_128k"]

class DownloadCreateRequest(BaseModel):
    url: str
    format_type: FormatType = FormatType.MP4
    quality: str = "1080p"  # e.g. "1080p", "720p", "best", "mp3_320k"
    output_dir: Optional[str] = None

class DownloadProgressResponse(BaseModel):
    download_id: str
    url: str
    provider: str = "Generic"
    title: str = "Aguardando..."
    format_type: FormatType
    quality: str
    status: WorkerStatus
    progress_percent: float = 0.0
    download_speed: str = "0 KB/s"
    eta_seconds: int = 0
    downloaded_bytes: int = 0
    total_bytes: int = 0
    file_path: Optional[str] = None
    error_message: Optional[str] = None
