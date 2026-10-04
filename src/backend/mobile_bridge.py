"""
mobile_bridge.py
Bridge module for embedding Python download engine in Android via Chaquopy / Native JNI.
Provides direct in-memory calls without local HTTP socket server overhead.
"""
import json
import logging
from typing import Optional, Any
from src.backend.extractor import ExtractorService
from src.backend.worker import DownloadWorker
from src.backend.models import FormatType, WorkerStatus

logger = logging.getLogger("MobileBridge")
logging.basicConfig(level=logging.INFO)

def extract_metadata_json(url: str) -> str:
    """
    Extracts video/audio metadata and returns it as a JSON string.
    Called directly by Android Kotlin via Chaquopy.
    """
    try:
        info = ExtractorService.extract_info(url)
        return json.dumps({
            "success": True,
            "data": info.model_dump()
        })
    except Exception as e:
        logger.error(f"Error extracting metadata for {url}: {e}")
        return json.dumps({
            "success": False,
            "error": str(e)
        })

class MobileDownloadManager:
    """
    Manages active download workers for the mobile application.
    """
    def __init__(self):
        self._workers = {}

    def start_download(
        self,
        url: str,
        format_type_str: str,
        quality: str,
        output_dir: str,
        progress_callback_proxy: Optional[Any] = None
    ) -> str:
        """
        Starts an asynchronous download worker.
        Dispatches progress events directly to the Kotlin callback proxy.
        """
        fmt = FormatType.MP3 if format_type_str.lower() == "mp3" else FormatType.MP4

        def on_update(worker: DownloadWorker):
            payload = {
                "download_id": worker.download_id,
                "status": worker.status.value,
                "progress_percent": worker.progress_percent,
                "download_speed": worker.download_speed,
                "eta_seconds": worker.eta_seconds,
                "downloaded_bytes": worker.downloaded_bytes,
                "total_bytes": worker.total_bytes,
                "file_path": worker.file_path,
                "error_message": worker.error_message
            }
            if progress_callback_proxy:
                try:
                    progress_callback_proxy.onProgressUpdate(json.dumps(payload))
                except Exception as ex:
                    logger.error(f"Callback proxy error: {ex}")

        worker = DownloadWorker(
            url=url,
            format_type=fmt,
            quality=quality,
            output_dir=output_dir,
            on_update_callback=on_update
        )
        self._workers[worker.download_id] = worker
        worker.start_async()
        logger.info(f"Worker {worker.download_id} started for {url}")
        return worker.download_id

    def cancel_download(self, download_id: str) -> bool:
        """Cancels an active download."""
        worker = self._workers.get(download_id)
        if worker:
            worker.cancel()
            logger.info(f"Worker {download_id} cancelled.")
            return True
        return False

    def get_download_status(self, download_id: str) -> Optional[str]:
        """Returns JSON status of a specific download."""
        worker = self._workers.get(download_id)
        if worker:
            return json.dumps(worker.to_response().model_dump())
        return None

# Singleton instance for mobile lifecycle
mobile_manager = MobileDownloadManager()
