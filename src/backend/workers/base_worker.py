import os
import shutil
import uuid
import logging
import threading
from abc import ABC, abstractmethod
from typing import Optional, Callable
import yt_dlp
from src.backend.models import FormatType, WorkerStatus
from src.backend.config import settings

logger = logging.getLogger(__name__)

class BaseDownloadWorker(ABC):
    def __init__(
        self,
        url: str,
        format_type: FormatType,
        quality: str,
        output_dir: Optional[str] = None,
        on_update_callback: Optional[Callable[["BaseDownloadWorker"], None]] = None
    ):
        self.download_id: str = f"dl_{uuid.uuid4().hex[:8]}"
        self.url: str = url
        self.provider: str = self.get_provider_name()
        self.format_type: FormatType = format_type
        self.quality: str = quality
        if output_dir:
            self.output_dir: str = output_dir
        else:
            self.output_dir: str = settings.DOWNLOAD_MUSIC_DIR if format_type == FormatType.MP3 else settings.DOWNLOAD_VIDEOS_DIR
        self.temp_dir: str = settings.DOWNLOAD_TEMP_DIR
        self.on_update_callback = on_update_callback

        self.title: str = "Iniciando..."
        self.status: WorkerStatus = WorkerStatus.PENDING
        self.progress_percent: float = 0.0
        self.download_speed: str = "0 KB/s"
        self.eta_seconds: int = 0
        self.downloaded_bytes: int = 0
        self.total_bytes: int = 0
        self.file_path: Optional[str] = None
        self.error_message: Optional[str] = None

        self._cancelled: bool = False
        self._thread: Optional[threading.Thread] = None

    @abstractmethod
    def get_provider_name(self) -> str:
        """Returns the specific platform provider name."""
        pass

    def cancel(self):
        """Flags the worker as cancelled."""
        self._cancelled = True
        if self.status != WorkerStatus.DELETED:
            self.status = WorkerStatus.CANCELLED
        self._notify_update()

    def is_cancelled(self) -> bool:
        return self._cancelled

    def start_async(self):
        """Starts worker download in a separate daemon thread."""
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def _notify_update(self):
        if self.on_update_callback:
            try:
                self.on_update_callback(self)
            except Exception as e:
                logger.error(f"Erro no callback do worker {self.download_id}: {e}")

    def _progress_hook(self, d: dict):
        if self._cancelled:
            raise yt_dlp.utils.DownloadCancelled("Download cancelado pelo usuário.")

        status = d.get('status')
        if status == 'downloading':
            if self.status != WorkerStatus.DELETED:
                self.status = WorkerStatus.DOWNLOADING
            downloaded = d.get('downloaded_bytes', 0)
            total = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
            speed = d.get('speed', 0)
            eta = d.get('eta', 0)

            self.downloaded_bytes = downloaded
            self.total_bytes = total
            if total > 0:
                self.progress_percent = round((downloaded / total) * 100, 1)

            if speed:
                if speed > 1024 * 1024:
                    self.download_speed = f"{speed / (1024 * 1024):.2f} MB/s"
                else:
                    self.download_speed = f"{speed / 1024:.1f} KB/s"

            self.eta_seconds = int(eta) if eta else 0
            self._notify_update()

        elif status == 'finished':
            if self.status != WorkerStatus.DELETED:
                self.status = WorkerStatus.CONVERTING
                self.progress_percent = 99.0
            self._notify_update()

    def _run(self):
        try:
            self.status = WorkerStatus.EXTRACTING
            self._notify_update()

            self.execute_download()

            if not self._cancelled and self.status != WorkerStatus.DELETED:
                self.status = WorkerStatus.COMPLETED
                self.progress_percent = 100.0
                self.download_speed = "0 KB/s"
                self.eta_seconds = 0
                self._notify_update()

        except yt_dlp.utils.DownloadCancelled:
            logger.info(f"Worker {self.download_id} cancelado pelo usuário.")
            if self.status != WorkerStatus.DELETED:
                self.status = WorkerStatus.CANCELLED
            self._notify_update()
        except Exception as e:
            logger.error(f"Erro crítico no worker {self.download_id} ({self.provider}): {e}", exc_info=True)
            if not self._cancelled and self.status != WorkerStatus.DELETED:
                self.status = WorkerStatus.FAILED
                self.error_message = str(e)
                self._notify_update()

    @abstractmethod
    def execute_download(self):
        """Executes the platform-specific download and fallback handling."""
        pass
