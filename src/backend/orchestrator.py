import os
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
            return [worker.to_response() for worker in reversed(list(self._workers.values()))]

    def cancel_download(self, download_id: str) -> bool:
        with self._lock:
            worker = self._workers.get(download_id)
            if worker:
                worker.cancel()
                logger.info(f"Worker {download_id} cancelado pelo orquestrador.")
                return True
            return False

    def delete_download(self, download_id: str) -> bool:
        with self._lock:
            worker = self._workers.get(download_id)
            if worker:
                # 1. Set status to DELETED first so callbacks don't overwrite it
                worker.status = WorkerStatus.DELETED
                worker.cancel()
                
                # 2. Attempt file cleanup if file_path is set
                if worker.file_path and os.path.exists(worker.file_path):
                    try:
                        os.remove(worker.file_path)
                        logger.info(f"Arquivo {worker.file_path} removido com sucesso do disco.")
                    except Exception as e:
                        logger.warning(f"Erro ao remover arquivo {worker.file_path}: {e}")
                
                # Also clean up any partial or temp files in output_dir matching the title
                if worker.output_dir and os.path.exists(worker.output_dir):
                    try:
                        for f in os.listdir(worker.output_dir):
                            if worker.title not in ("Iniciando...", "Aguardando...") and worker.title in f:
                                full_p = os.path.join(worker.output_dir, f)
                                if os.path.exists(full_p):
                                    os.remove(full_p)
                                    logger.info(f"Arquivo associado {full_p} removido do disco.")
                    except Exception as e:
                        logger.warning(f"Erro ao limpar arquivos associados: {e}")

                worker.file_path = None
                worker.progress_percent = 0.0
                worker.download_speed = "0 KB/s"
                worker.eta_seconds = 0
                logger.info(f"Worker {download_id} cancelado, arquivo apagado do disco e status alterado para DELETADO.")
                return True
            return False

    def clear_finished_downloads(self) -> int:
        with self._lock:
            to_delete = list(self._workers.keys())
            for download_id in to_delete:
                worker = self._workers[download_id]
                try:
                    worker.cancel()
                except Exception as e:
                    logger.warning(f"Erro ao cancelar worker {download_id}: {e}")
                del self._workers[download_id]
            logger.info(f"{len(to_delete)} tarefas limpas do histórico de downloads.")
            return len(to_delete)

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
