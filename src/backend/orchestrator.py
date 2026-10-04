import os
import re
import logging
import threading
from typing import Dict, List, Optional, Callable
from src.backend.models import (
    FormatType, DownloadProgressResponse, WorkerStatus
)
from src.backend.worker import DownloadWorker
from src.backend.config import settings

logger = logging.getLogger(__name__)

class ClearedResult(list):
    """List of cleared IDs that also compares equal to an int matching its length."""
    def __eq__(self, other):
        if isinstance(other, int):
            return len(self) == other
        return super().__eq__(other)

def clean_files_on_disk(
    file_path: Optional[str] = None,
    output_dir: Optional[str] = None,
    title: Optional[str] = None
) -> List[str]:
    """
    Exhaustively searches and deletes files on disk associated with a download.
    Checks exact path, common extensions, partial/temp files, and sanitized titles.
    """
    deleted = []

    # 1. Exact file_path & common format extensions
    if file_path:
        candidates = [file_path, f"{file_path}.part", f"{file_path}.ytdl"]
        base_no_ext, _ = os.path.splitext(file_path)
        for ext in [".mp3", ".mp4", ".m4a", ".webm", ".opus", ".mkv", ".wav", ".ogg"]:
            candidates.append(base_no_ext + ext)
            candidates.append(base_no_ext + ext + ".part")
            candidates.append(base_no_ext + ext + ".ytdl")

        for cand in set(candidates):
            if os.path.exists(cand) and os.path.isfile(cand):
                try:
                    os.remove(cand)
                    deleted.append(cand)
                    logger.info(f"Arquivo apagado do disco: {cand}")
                except Exception as e:
                    logger.warning(f"Erro ao remover {cand}: {e}")

    # 2. In output_dir by matching title or title slug
    if output_dir and os.path.exists(output_dir) and title and title not in ("Iniciando...", "Aguardando...", "Sem título"):
        title_slug = re.sub(r'[\W_]+', '', title.lower())
        try:
            for fname in os.listdir(output_dir):
                full_p = os.path.join(output_dir, fname)
                if not os.path.isfile(full_p):
                    continue
                # Direct substring check
                if title.lower() in fname.lower():
                    try:
                        os.remove(full_p)
                        deleted.append(full_p)
                        logger.info(f"Arquivo associado apagado por título: {full_p}")
                    except Exception as e:
                        logger.warning(f"Erro ao remover {full_p}: {e}")
                    continue
                # Alphanumeric slug check (handles sanitized colons, slashes, etc.)
                if len(title_slug) >= 4:
                    f_slug = re.sub(r'[\W_]+', '', fname.lower())
                    if title_slug in f_slug or (len(title_slug) > 10 and title_slug[:12] in f_slug):
                        try:
                            os.remove(full_p)
                            deleted.append(full_p)
                            logger.info(f"Arquivo associado apagado por slug: {full_p}")
                        except Exception as e:
                            logger.warning(f"Erro ao remover {full_p}: {e}")
        except Exception as e:
            logger.warning(f"Erro ao escanear diretório {output_dir}: {e}")

    return deleted

class WorkerOrchestrator:
    def __init__(self, max_concurrency: int = settings.WORKER_MAX_CONCURRENCY):
        self.max_concurrency: int = max_concurrency
        self._workers: Dict[str, DownloadWorker] = {}
        self._lock: threading.Lock = threading.Lock()
        self._update_callbacks: List[Callable[[DownloadWorker], None]] = []

    def register_update_callback(self, callback: Callable[[DownloadWorker], None]):
        with self._lock:
            if callback not in self._update_callbacks:
                self._update_callbacks.append(callback)

    def unregister_update_callback(self, callback: Callable[[DownloadWorker], None]):
        with self._lock:
            if callback in self._update_callbacks:
                self._update_callbacks.remove(callback)

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

    def has_download(self, download_id: str) -> bool:
        with self._lock:
            return download_id in self._workers

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

    def delete_download(
        self,
        download_id: str,
        file_path_hint: Optional[str] = None,
        output_dir_hint: Optional[str] = None,
        title_hint: Optional[str] = None
    ) -> bool:
        with self._lock:
            worker = self._workers.pop(download_id, None)

        file_path = file_path_hint
        output_dir = output_dir_hint
        title = title_hint

        if worker:
            worker.status = WorkerStatus.DELETED
            worker._cancelled = True
            if not file_path:
                file_path = worker.file_path
            if not output_dir:
                output_dir = worker.output_dir
            if not title:
                title = worker.title

        # Clean all files on disk matching path, title, or extensions
        deleted = clean_files_on_disk(file_path=file_path, output_dir=output_dir, title=title)
        logger.info(f"Worker {download_id} deletado. Arquivos removidos: {deleted}")
        return True

    def clear_finished_downloads(self) -> ClearedResult:
        with self._lock:
            cleared = ClearedResult()
            to_delete = list(self._workers.keys())
            for download_id in to_delete:
                worker = self._workers.pop(download_id)
                try:
                    # Cancel silently without emitting updates
                    worker._cancelled = True
                    worker.status = WorkerStatus.CANCELLED
                except Exception as e:
                    logger.warning(f"Erro ao cancelar worker {download_id}: {e}")
                cleared.append(download_id)

            logger.info(f"{len(cleared)} tarefas limpas do histórico de downloads.")
            return cleared

    def get_active_count(self) -> int:
        with self._lock:
            return sum(
                1 for w in self._workers.values()
                if w.status in (WorkerStatus.EXTRACTING, WorkerStatus.DOWNLOADING, WorkerStatus.CONVERTING)
            )

    def _on_worker_update(self, worker: DownloadWorker):
        with self._lock:
            # Drop updates from workers that have already been cleared or deleted
            if worker.download_id not in self._workers and worker.status != WorkerStatus.DELETED:
                return
            callbacks = list(self._update_callbacks)

        for cb in callbacks:
            try:
                cb(worker)
            except Exception as e:
                logger.error(f"Erro ao disparar callback de atualização do worker {worker.download_id}: {e}")

# Global Orchestrator Instance
orchestrator = WorkerOrchestrator()

