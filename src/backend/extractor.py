import re
import logging
from typing import Dict, Any, List, Tuple
import urllib.request
import json
import yt_dlp
from src.backend.models import VideoInfoResponse

logger = logging.getLogger(__name__)

class ExtractorService:
    @staticmethod
    def detect_provider(url: str) -> str:
        url_lower = url.lower()
        if "music.youtube.com" in url_lower:
            return "YouTube Music"
        elif "youtube.com" in url_lower or "youtu.be" in url_lower:
            return "YouTube"
        elif "instagram.com" in url_lower or "instagr.am" in url_lower:
            return "Instagram"
        elif "spotify.com" in url_lower:
            return "Spotify"
        elif "deezer.com" in url_lower or "deezer.page.link" in url_lower:
            return "Deezer"
        elif "soundcloud.com" in url_lower:
            return "SoundCloud"
        elif "tiktok.com" in url_lower:
            return "TikTok"
        elif "vimeo.com" in url_lower:
            return "Vimeo"
        return "Generic"

    @staticmethod
    def _fetch_oembed_metadata(url: str, provider: str) -> Tuple[str, str, str]:
        """
        Fetches oEmbed metadata for Spotify/Deezer to construct search queries.
        Returns tuple of (title, thumbnail, search_query).
        """
        oembed_url = None
        if provider == "Spotify":
            oembed_url = f"https://open.spotify.com/oembed?url={url}"
        elif provider == "Deezer":
            oembed_url = f"https://api.deezer.com/oembed?url={url}"

        if oembed_url:
            try:
                req = urllib.request.Request(oembed_url, headers={'User-Agent': 'Mozilla/5.0'})
                with urllib.request.urlopen(req, timeout=5) as resp:
                    data = json.loads(resp.read().decode('utf-8'))
                    title = data.get('title', 'Música Desconhecida')
                    thumbnail = data.get('thumbnail_url')
                    author = data.get('author_name', '')
                    search_query = f"ytsearch1:{title} {author}".strip()
                    return title, thumbnail, search_query
            except Exception as e:
                logger.warning(f"Falha oEmbed para {provider}: {e}")

        # Fallback query
        clean_url = re.sub(r'https?://[^/]+/', '', url).replace('-', ' ')
        return f"{provider} Track", None, f"ytsearch1:{clean_url}"

    @classmethod
    def resolve_target(cls, url: str) -> Tuple[str, str, bool]:
        """
        Resolves input URL to (target_url, provider_name, is_audio_only).
        """
        provider = cls.detect_provider(url)
        if provider in ("Spotify", "Deezer"):
            _, _, search_query = cls._fetch_oembed_metadata(url, provider)
            return search_query, provider, True
        return url, provider, False

    @classmethod
    def extract_info(cls, url: str) -> VideoInfoResponse:
        """
        Extracts video/audio metadata and supported resolution/format options
        from YouTube, Instagram, Spotify, Deezer, TikTok and 1000+ supported hosts.
        """
        provider = cls.detect_provider(url)
        target_url = url

        if provider in ("Spotify", "Deezer"):
            title, thumbnail, search_query = cls._fetch_oembed_metadata(url, provider)
            target_url = search_query

        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'extract_flat': False,
            'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        }

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info: Dict[str, Any] = ydl.extract_info(target_url, download=False)

            # If ytsearch result, pick first entry
            if info.get('_type') == 'playlist' and info.get('entries'):
                info = info['entries'][0]

            title = info.get('title', 'Conteúdo Mídia')
            duration = int(info.get('duration') or 0)
            thumbnail = info.get('thumbnail') or (thumbnail if provider in ("Spotify", "Deezer") else None)

            # Parse video formats for unique resolutions
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

            # If provider is Spotify, Deezer or YT Music, default audio formats first
            if provider in ("Spotify", "Deezer", "YouTube Music"):
                qualities = ["mp3_320k", "mp3_192k", "mp3_128k"] + qualities

            return VideoInfoResponse(
                url=url,
                provider=provider,
                title=title,
                duration_seconds=duration,
                thumbnail=thumbnail,
                qualities=qualities,
                audio_formats=audio_formats
            )
        except Exception as e:
            logger.error(f"Erro ao extrair metadados para {provider} URL {url}: {str(e)}")
            raise RuntimeError(f"Falha ao obter dados do link ({provider}): {str(e)}")
