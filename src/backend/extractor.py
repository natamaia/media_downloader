import logging
from typing import Dict, Any, List
import yt_dlp
from src.backend.models import VideoInfoResponse

logger = logging.getLogger(__name__)

class ExtractorService:
    @staticmethod
    def extract_info(url: str) -> VideoInfoResponse:
        """
        Extracts video metadata and supported resolution/format options
        without downloading the actual file payload.
        """
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'extract_flat': False,
        }

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info: Dict[str, Any] = ydl.extract_info(url, download=False)

            title = info.get('title', 'Vídeo sem título')
            duration = int(info.get('duration') or 0)
            thumbnail = info.get('thumbnail')

            # Parse video formats to collect unique qualities (resolutions)
            formats = info.get('formats', [])
            heights = set()
            for fmt in formats:
                h = fmt.get('height')
                vcodec = fmt.get('vcodec')
                if h and vcodec and vcodec != 'none':
                    heights.add(h)

            sorted_heights = sorted(list(heights), reverse=True)
            qualities: List[str] = [f"{h}p" for h in sorted_heights]
            if not qualities:
                qualities = ["best", "720p", "360p"]

            audio_formats = ["mp3_320k", "mp3_192k", "mp3_128k"]

            return VideoInfoResponse(
                url=url,
                title=title,
                duration_seconds=duration,
                thumbnail=thumbnail,
                qualities=qualities,
                audio_formats=audio_formats
            )
        except Exception as e:
            logger.error(f"Erro ao extrair metadados para URL {url}: {str(e)}")
            raise RuntimeError(f"Falha ao obter dados do link: {str(e)}")
