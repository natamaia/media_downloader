import os
import uuid
import logging
import threading
from typing import Optional, Callable
import yt_dlp
from src.backend.models import (
    FormatType, WorkerStatus, DownloadProgressResponse
)
from src.backend.config import settings
from src.backend.extractor import ExtractorService

logger = logging.getLogger(__name__)

class DownloadWorker:
    def __init__(
        self,
        url: str,
        format_type: FormatType,
        quality: str,
        output_dir: Optional[str] = None,
        on_update_callback: Optional[Callable[["DownloadWorker"], None]] = None
    ):
        self.download_id: str = f"dl_{uuid.uuid4().hex[:8]}"
        self.url: str = url
        self.provider: str = ExtractorService.detect_provider(url)
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

    def cancel(self):
        """Flags the worker as cancelled."""
        self._cancelled = True
        if self.status != WorkerStatus.DELETED:
            self.status = WorkerStatus.CANCELLED
        self._notify_update()

    def is_cancelled(self) -> bool:
        return self._cancelled

    def start_async(self):
        """Starts worker download in a separate thread."""
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

            target_url, provider, is_audio_override = ExtractorService.resolve_target(self.url)
            self.provider = provider
            if is_audio_override:
                self.format_type = FormatType.MP3

            out_template = os.path.join(self.output_dir, '%(title)s.%(ext)s')

            ydl_opts = {
                'outtmpl': out_template,
                'progress_hooks': [self._progress_hook],
                'quiet': True,
                'no_warnings': True,
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            }

            if self.format_type == FormatType.MP3:
                bitrate = "320"
                if "192" in self.quality:
                    bitrate = "192"
                elif "128" in self.quality:
                    bitrate = "128"

                ydl_opts.update({
                    'format': 'bestaudio/best',
                    'postprocessors': [{
                        'key': 'FFmpegExtractAudio',
                        'preferredcodec': 'mp3',
                        'preferredquality': bitrate,
                    }],
                })
            else:
                res_clean = self.quality.replace('p', '')
                if res_clean.isdigit():
                    height = int(res_clean)
                    ydl_opts['format'] = f'bestvideo[height<={height}][ext=mp4]+bestaudio[ext=m4a]/best[height<={height}][ext=mp4]/best'
                else:
                    ydl_opts['format'] = 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'

                ydl_opts['merge_output_format'] = 'mp4'

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(target_url, download=False)
                if info.get('_type') == 'playlist' and info.get('entries'):
                    info = info['entries'][0]
                self.title = info.get('title', 'Sem título')
                filename = ydl.prepare_filename(info)
                if self.format_type == FormatType.MP3:
                    filename = os.path.splitext(filename)[0] + ".mp3"
                self.file_path = filename

                # Pre-download file existence check
                if os.path.exists(filename):
                    logger.info(f"Arquivo '{filename}' já existe no diretório. Marcando status como EXISTS.")
                    if not self._cancelled and self.status != WorkerStatus.DELETED:
                        self.status = WorkerStatus.EXISTS
                        self.progress_percent = 100.0
                        self.download_speed = "0 KB/s"
                        self.eta_seconds = 0
                        self.error_message = "Arquivo já existente no diretório de destino."
                        self._notify_update()
                    return

                # Perform actual download if file does not exist
                ydl.download([target_url])

            if not self._cancelled and self.status != WorkerStatus.DELETED:
                self.status = WorkerStatus.COMPLETED
                self.progress_percent = 100.0
                self._notify_update()

        except yt_dlp.utils.DownloadCancelled:
            if self.status != WorkerStatus.DELETED:
                self.status = WorkerStatus.CANCELLED
            self._notify_update()
        except Exception as e:
            if not self._cancelled and self.status != WorkerStatus.DELETED:
                err_str = str(e)
                logger.error(f"Erro no worker {self.download_id}: {err_str}")

                if "already exists" in err_str.lower() or "file exists" in err_str.lower():
                    self.status = WorkerStatus.EXISTS
                    self.progress_percent = 100.0
                    self.error_message = "Arquivo já existente no diretório."
                else:
                    self.status = WorkerStatus.FAILED
                    clean_msg = err_str.replace("ERROR: ", "").replace("[generic]", "").strip()
                    self.error_message = clean_msg if clean_msg else "Falha durante o download da mídia."

                self._notify_update()

    def to_response(self) -> DownloadProgressResponse:
        return DownloadProgressResponse(
            download_id=self.download_id,
            url=self.url,
            provider=self.provider,
            title=self.title,
            format_type=self.format_type,
            quality=self.quality,
            status=self.status,
            progress_percent=self.progress_percent,
            download_speed=self.download_speed,
            eta_seconds=self.eta_seconds,
            downloaded_bytes=self.downloaded_bytes,
            total_bytes=self.total_bytes,
            file_path=self.file_path,
            error_message=self.error_message
        )
