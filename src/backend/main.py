import logging
import uvicorn
from fastapi import FastAPI, HTTPException, status
from src.backend.config import settings
from src.backend.models import (
    InfoRequest, VideoInfoResponse, DownloadCreateRequest, DownloadProgressResponse
)
from src.backend.extractor import ExtractorService
from src.backend.orchestrator import orchestrator

logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("InternalAPI")

app = FastAPI(
    title="Media Downloader Internal API",
    description="Internal API Controller for decentralized background download workers",
    version="1.0.0"
)

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "version": "1.0.0",
        "active_workers": orchestrator.get_active_count(),
        "max_concurrency": settings.WORKER_MAX_CONCURRENCY
    }

@app.post("/api/v1/info", response_model=VideoInfoResponse)
def get_video_info(req: InfoRequest):
    try:
        return ExtractorService.extract_info(req.url)
    except Exception as e:
        logger.error(f"Erro ao obter metadados: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@app.post("/api/v1/downloads", response_model=DownloadProgressResponse, status_code=status.HTTP_201_CREATED)
def create_download(req: DownloadCreateRequest):
    try:
        return orchestrator.create_download(
            url=req.url,
            format_type=req.format_type,
            quality=req.quality,
            output_dir=req.output_dir
        )
    except Exception as e:
        logger.error(f"Erro ao criar download: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.get("/api/v1/downloads", response_model=list[DownloadProgressResponse])
def list_downloads():
    return orchestrator.list_downloads()

@app.get("/api/v1/downloads/{download_id}", response_model=DownloadProgressResponse)
def get_download(download_id: str):
    download = orchestrator.get_download(download_id)
    if not download:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Download {download_id} não encontrado."
        )
    return download

@app.post("/api/v1/downloads/{download_id}/cancel")
def cancel_download(download_id: str):
    success = orchestrator.cancel_download(download_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Download {download_id} não encontrado."
        )
    return {"download_id": download_id, "status": "CANCELLED"}

if __name__ == "__main__":
    uvicorn.run(
        "src.backend.main:app",
        host=settings.HOST,
        port=settings.PORT,
        log_level=settings.LOG_LEVEL.lower(),
        reload=False
    )
