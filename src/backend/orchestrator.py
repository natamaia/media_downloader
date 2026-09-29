import logging
import threading
from typing import Dict, List, Optional
from src.backend.models import (
    FormatType, DownloadProgressResponse, WorkerStatus
)
from src.backend.worker import DownloadWorker
from src.backend.config import settings

logger = logging.getLogger(__name__)

class WorkerOrchestrator:
    def __init__(self, max_concurrency: int = settings.WORKER_MAX_CONCURRENCY):
        self.max_concurrency: int = max_concurrency
        self._workers: Dict[str, DownloadWorker] = {}
        self._lock: threading.Lock = threading.Lock()

    def create_download(
        self,
        url: str,
        format_type: FormatType,
        quality: str,
        output_dir: Optional[str] = None
    ) -> DownloadProgressResponse:
        """
        Instantiates a new DownloadWorker and starts execution.
        """
        with self._lock:
            worker = DownloadWorker(
                url=url,
                format_type=format_type,
                quality=quality,
                output_dir=output_dir,
                on_update_callback=self._on_worker_update
            )
            self._workers[worker.download_id] = worker
            worker.start_async()
            logger.info(f"Worker {worker.download_id} iniciado para URL: {url}")
            return worker.to_response()

    def get_download(self, download_id: str) -> Optional[DownloadProgressResponse]:
        with self._lock:
            worker = self._workers.get(download_id)
            return worker.to_response() if worker else None

    def list_downloads(self) -> List[DownloadProgressResponse]:
        with self._lock:
            return [worker.to_response() for worker in self._workers.values()]

    def cancel_download(self, download_id: str) -> bool:
        with self._lock:
            worker = self._workers.get(download_id)
            if worker:
                worker.cancel()
                logger.info(f"Worker {download_id} cancelado pelo orquestrador.")
                return True
            return False

    def get_active_count(self) -> int:
        with self._lock:
            return sum(
                1 for w in self._workers.values()
                if w.status in (WorkerStatus.EXTRACTING, WorkerStatus.DOWNLOADING, WorkerStatus.CONVERTING)
            )

    def _on_worker_update(self, worker: DownloadWorker):
        # Progress callback hook for internal event logging or websocket broadcasts
        pass

# Global Orchestrator Instance
orchestrator = WorkerOrchestrator()
