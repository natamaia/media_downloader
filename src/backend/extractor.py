import re
import os
import logging
from typing import Dict, Any, List, Tuple, Optional
import urllib.request
import urllib.parse
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
        elif "youtube.com/shorts" in url_lower or "/shorts/" in url_lower:
            return "YouTube Shorts"
        elif "youtube.com" in url_lower or "youtu.be" in url_lower:
            return "YouTube"
        elif "x.com" in url_lower or "twitter.com" in url_lower or "xwriter" in url_lower or "twitsave" in url_lower:
            return "X (Twitter)"
        elif "t.me" in url_lower or "telegram.me" in url_lower:
            return "Telegram"
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
        elif any(course in url_lower for course in ["hotmart", "wistia", "loom.com", "kaltura", "streamable", "pandavideo", "vdo.ninja"]):
            return "Plataforma de Aulas"
        elif "reddit.com" in url_lower or "v.redd.it" in url_lower:
            return "Reddit"
        elif any(fb in url_lower for fb in ["facebook.com", "fb.watch", "fb.com", "fb.gg"]):
            return "Facebook"
        elif any(url_lower.endswith(ext) or f"{ext}?" in url_lower for ext in [".mp4", ".m3u8", ".mpd", ".webm", ".mkv", ".mov", ".ts"]):
            return "Vídeo Direto (MP4/HLS)"
        elif any(url_lower.endswith(ext) or f"{ext}?" in url_lower for ext in [".mp3", ".m4a", ".aac", ".wav", ".ogg", ".flac"]):
            return "Áudio Direto"
        return "Site / Aula Web"

    @staticmethod
    def _fetch_oembed_metadata(url: str, provider: str) -> Tuple[str, Optional[str], str]:
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
        elif provider == "Áudio Direto":
            return url, provider, True
        elif provider == "Facebook":
            reel_match = re.search(r'(?:reel|reels|videos|v)[/=](\d+)', url)
            if reel_match:
                video_id = reel_match.group(1)
                return f"https://m.facebook.com/watch/?v={video_id}&_rdr", provider, False
            return url, provider, False
        return url, provider, False

    @classmethod
    def _extract_direct_or_web_metadata(cls, url: str, provider: str) -> VideoInfoResponse:
        """
        Fallback extraction for direct media files (.mp4, .m3u8, .mp3),
        course platforms, and web pages with OpenGraph or HTML5 video tags.
        """
        if not url.startswith(('http://', 'https://')):
            raise ValueError(f"URL inválida: '{url}' não é um endereço HTTP/HTTPS válido.")

        title = "Vídeo Web"
        thumbnail = None
        is_audio = provider == "Áudio Direto"

        # Tenta extrair título a partir do nome do arquivo na URL
        parsed = urllib.parse.urlparse(url)
        path_name = os.path.basename(parsed.path)
        if path_name:
            clean_name = os.path.splitext(path_name)[0]
            clean_name = re.sub(r'[-_]+', ' ', clean_name).strip()
            if len(clean_name) >= 3:
                title = clean_name.capitalize()

        # Se for uma página web genérica ou plataforma de aula, tenta ler as tags OpenGraph
        if not any(url.lower().endswith(ext) for ext in [".mp4", ".mp3", ".m4a", ".webm", ".mkv"]):
            try:
                req = urllib.request.Request(
                    url,
                    headers={
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
                    }
                )
                with urllib.request.urlopen(req, timeout=5) as resp:
                    html_content = resp.read(65536).decode('utf-8', errors='ignore')

                    og_title = re.search(r'<meta\s+property=["\']og:title["\']\s+content=["\'](.*?)["\']', html_content, re.IGNORECASE)
                    if not og_title:
                        og_title = re.search(r'<title>(.*?)</title>', html_content, re.IGNORECASE)
                    if og_title and og_title.group(1).strip():
                        title = og_title.group(1).strip()

                    og_img = re.search(r'<meta\s+property=["\']og:image["\']\s+content=["\'](.*?)["\']', html_content, re.IGNORECASE)
                    if og_img and og_img.group(1).strip():
                        thumbnail = og_img.group(1).strip()
            except Exception as e:
                logger.debug(f"Aviso ao consultar metadados HTML: {e}")

        qualities = ["Original", "1080p", "720p", "480p"]
        audio_formats = ["mp3_320k", "mp3_192k", "mp3_128k"]

        if is_audio:
            qualities = audio_formats

        return VideoInfoResponse(
            url=url,
            provider=provider,
            title=title,
            duration_seconds=0,
            thumbnail=thumbnail,
            qualities=qualities,
            audio_formats=audio_formats
        )

    @classmethod
    def extract_info(cls, url: str) -> VideoInfoResponse:
        """
        Extracts video/audio metadata and supported resolution/format options
        from YouTube, Shorts, X/Twitter, Instagram, Spotify, Deezer, TikTok,
        course platforms, direct media and 1800+ hosts.
        """
        provider = cls.detect_provider(url)
        target_url = url

        if provider in ("Spotify", "Deezer"):
            title, thumbnail, search_query = cls._fetch_oembed_metadata(url, provider)
            target_url = search_query

        # Configuração do yt-dlp com headers de navegador e tratamento para páginas genéricas
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'extract_flat': False,
            'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'referer': target_url,
        }

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info: Dict[str, Any] = ydl.extract_info(target_url, download=False)

            # Se for playlist / busca, pega o primeiro item
            if info.get('_type') == 'playlist' and info.get('entries'):
                info = info['entries'][0]

            title = info.get('title') or 'Conteúdo Mídia'
            duration = int(info.get('duration') or 0)
            thumbnail = info.get('thumbnail') or (thumbnail if provider in ("Spotify", "Deezer") else None)

            # Resoluções disponíveis
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
                qualities = ["Original", "1080p", "720p", "480p"]

            audio_formats = ["mp3_320k", "mp3_192k", "mp3_128k"]

            if provider in ("Spotify", "Deezer", "YouTube Music", "Áudio Direto"):
                qualities = audio_formats + qualities

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
            logger.warning(f"yt-dlp falhou para {provider} URL {url} ({e}). Acionando extrator universal direto...")
            # Fallback para arquivos diretos (.mp4, .m3u8, .mp3), sites de aula e links bloqueados por 403
            try:
                return cls._extract_direct_or_web_metadata(url, provider)
            except Exception as e_fallback:
                logger.error(f"Erro em todos os extratores para {url}: {e_fallback}")
                raise RuntimeError(f"Falha ao obter dados do link ({provider}): {str(e)}")
