"""
worker.py
Fachada para o sistema de workers especializados.
Instancia dinamicamente o worker específico por plataforma (YouTubeWorker, FacebookWorker, etc.)
via WorkerFactory.
"""

from typing import Optional, Callable
from src.backend.models import FormatType, WorkerStatus, DownloadProgressResponse
from src.backend.workers.base_worker import BaseDownloadWorker
from src.backend.workers.factory import WorkerFactory
from src.backend.workers.youtube_worker import YouTubeWorker
from src.backend.workers.facebook_worker import FacebookWorker
from src.backend.workers.twitter_worker import TwitterWorker
from src.backend.workers.instagram_worker import InstagramWorker
from src.backend.workers.tiktok_worker import TikTokWorker
from src.backend.workers.generic_worker import GenericWorker

class DownloadWorker(BaseDownloadWorker):
    """
    Classe de compatibilidade que despacha dinamicamente para o worker específico
    da plataforma utilizando o WorkerFactory.
    """
    def __new__(
        cls,
        url: str,
        format_type: FormatType,
        quality: str,
        output_dir: Optional[str] = None,
        on_update_callback: Optional[Callable[[BaseDownloadWorker], None]] = None
    ) -> BaseDownloadWorker:
        return WorkerFactory.create_worker(
            url=url,
            format_type=format_type,
            quality=quality,
            output_dir=output_dir,
            on_update_callback=on_update_callback
        )

    def get_provider_name(self) -> str:
        return "Generic"

    def execute_download(self):
        pass

__all__ = [
    "DownloadWorker",
    "BaseDownloadWorker",
    "WorkerFactory",
    "YouTubeWorker",
    "FacebookWorker",
    "TwitterWorker",
    "InstagramWorker",
    "TikTokWorker",
    "GenericWorker",
    "FormatType",
    "WorkerStatus",
    "DownloadProgressResponse",
]
