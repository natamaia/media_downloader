import logging
from typing import Optional, Callable
from src.backend.models import FormatType
from src.backend.extractor import ExtractorService
from src.backend.workers.base_worker import BaseDownloadWorker
from src.backend.workers.youtube_worker import YouTubeWorker
from src.backend.workers.facebook_worker import FacebookWorker
from src.backend.workers.twitter_worker import TwitterWorker
from src.backend.workers.instagram_worker import InstagramWorker
from src.backend.workers.tiktok_worker import TikTokWorker
from src.backend.workers.generic_worker import GenericWorker

logger = logging.getLogger(__name__)

class WorkerFactory:
    """
    Factory that instantiates the dedicated platform worker based on the detected URL provider.
    """
    @staticmethod
    def create_worker(
        url: str,
        format_type: FormatType,
        quality: str,
        output_dir: Optional[str] = None,
        on_update_callback: Optional[Callable[[BaseDownloadWorker], None]] = None
    ) -> BaseDownloadWorker:
        provider = ExtractorService.detect_provider(url)

        if provider in ("YouTube", "YouTube Shorts", "YouTube Music"):
            logger.info(f"Instanciando YouTubeWorker para URL: {url}")
            return YouTubeWorker(
                url=url,
                format_type=format_type,
                quality=quality,
                output_dir=output_dir,
                on_update_callback=on_update_callback
            )
        elif provider == "Facebook":
            logger.info(f"Instanciando FacebookWorker para URL: {url}")
            return FacebookWorker(
                url=url,
                format_type=format_type,
                quality=quality,
                output_dir=output_dir,
                on_update_callback=on_update_callback
            )
        elif provider == "X (Twitter)":
            logger.info(f"Instanciando TwitterWorker para URL: {url}")
            return TwitterWorker(
                url=url,
                format_type=format_type,
                quality=quality,
                output_dir=output_dir,
                on_update_callback=on_update_callback
            )
        elif provider == "Instagram":
            logger.info(f"Instanciando InstagramWorker para URL: {url}")
            return InstagramWorker(
                url=url,
                format_type=format_type,
                quality=quality,
                output_dir=output_dir,
                on_update_callback=on_update_callback
            )
        elif provider == "TikTok":
            logger.info(f"Instanciando TikTokWorker para URL: {url}")
            return TikTokWorker(
                url=url,
                format_type=format_type,
                quality=quality,
                output_dir=output_dir,
                on_update_callback=on_update_callback
            )
        else:
            logger.info(f"Instanciando GenericWorker ({provider}) para URL: {url}")
            return GenericWorker(
                url=url,
                format_type=format_type,
                quality=quality,
                output_dir=output_dir,
                on_update_callback=on_update_callback
            )
