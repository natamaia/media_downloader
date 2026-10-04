import os
import re
import shutil
import logging
import urllib.request
import yt_dlp
from src.backend.models import FormatType, WorkerStatus
from src.backend.workers.base_worker import BaseDownloadWorker

logger = logging.getLogger(__name__)

class FacebookWorker(BaseDownloadWorker):
    """
    Dedicated worker for Facebook, Facebook Reels, Facebook Shorts, and fb.watch.
    Handles redirect resolution, progressive HD/SD stream selection, and direct CDN fallback.
    """
    def get_provider_name(self) -> str:
        return "Facebook"

    def execute_download(self):
        target_url = self.url
        out_template = os.path.join(self.output_dir, '%(title)s.%(ext)s')
        has_ffmpeg = bool(shutil.which("ffmpeg"))

        # 1. Trata redirecionamentos de links curtos de compartilhamento (fb.watch, share/r, share/v)
        if "fb.watch" in target_url or "/share/" in target_url:
            try:
                req = urllib.request.Request(
                    target_url,
                    headers={
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                        'Sec-Fetch-Mode': 'navigate',
                    }
                )
                with urllib.request.urlopen(req, timeout=10) as resp:
                    target_url = resp.geturl()
            except Exception as e:
                logger.warning(f"Aviso ao resolver redirecionamento do Facebook: {e}")

        # 2. Converte reel/reels para watch URL para compatibilidade máxima com yt-dlp
        reel_match = re.search(r'(?:reel|reels|videos|v)[/=](\d+)', target_url)
        video_id = reel_match.group(1) if reel_match else None
        if video_id:
            target_url = f"https://m.facebook.com/watch/?v={video_id}&_rdr"

        ydl_opts = {
            'outtmpl': out_template,
            'progress_hooks': [self._progress_hook],
            'quiet': True,
            'no_warnings': True,
            'nocheckcertificate': True,
            'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'referer': 'https://m.facebook.com/',
        }

        # Formatos: prioriza MP4 progressivo com áudio embutido (HD ou SD)
        if self.format_type == FormatType.MP3:
            bitrate = "320"
            if "192" in self.quality:
                bitrate = "192"
            elif "128" in self.quality:
                bitrate = "128"

            if has_ffmpeg:
                ydl_opts.update({
                    'format': 'bestaudio/best',
                    'postprocessors': [{
                        'key': 'FFmpegExtractAudio',
                        'preferredcodec': 'mp3',
                        'preferredquality': bitrate,
                    }],
                })
            else:
                ydl_opts.update({
                    'format': 'bestaudio[ext=m4a]/bestaudio/best',
                })
        else:
            # Garante que vídeo tenha áudio embutido (hd/sd progressivo)
            ydl_opts['format'] = 'hd/sd/best[ext=mp4][acodec!=none]/best[acodec!=none]/best[ext=mp4]/best'
            if has_ffmpeg:
                ydl_opts['merge_output_format'] = 'mp4'

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(target_url, download=False)
                if info.get('_type') == 'playlist' and info.get('entries'):
                    info = info['entries'][0]

                raw_title = info.get('title') or f"Facebook_Reel_{video_id or 'video'}"
                # Limpa título de poluição visual
                clean_title = re.sub(r'[\s|]*Facebook.*$', '', raw_title, flags=re.IGNORECASE).strip()
                if len(clean_title) > 80:
                    clean_title = clean_title[:77] + "..."
                self.title = clean_title or "Facebook Vídeo"

                filename = ydl.prepare_filename(info)
                if self.format_type == FormatType.MP3 and has_ffmpeg:
                    filename = os.path.splitext(filename)[0] + ".mp3"
                self.file_path = filename

                if os.path.exists(filename):
                    logger.info(f"Arquivo '{filename}' já existe no diretório.")
                    if not self._cancelled and self.status != WorkerStatus.DELETED:
                        self.status = WorkerStatus.EXISTS
                        self.progress_percent = 100.0
                        self.download_speed = "0 KB/s"
                        self.eta_seconds = 0
                        self.error_message = "Arquivo já existente no diretório de destino."
                        self._notify_update()
                    return

                ydl.download([target_url])

                if not os.path.exists(filename):
                    base_no_ext = os.path.splitext(filename)[0]
                    for ext in [".mp4", ".mp3", ".m4a", ".webm", ".mkv"]:
                        cand = base_no_ext + ext
                        if os.path.exists(cand):
                            self.file_path = cand
                            break

        except Exception as e_ytdlp:
            logger.warning(f"yt-dlp falhou para Facebook ({e_ytdlp}). Acionando fallback direto de CDN do Facebook...")
            self._download_facebook_cdn_fallback(video_id, target_url)

    def _download_facebook_cdn_fallback(self, video_id: str | None, watch_url: str):
        """Fallback: obtém fluxo HD/SD direto da página mobile e baixa via CDN com cabeçalhos autorizados."""
        fetch_url = watch_url
        if video_id:
            fetch_url = f"https://m.facebook.com/watch/?v={video_id}&_rdr"

        req = urllib.request.Request(
            fetch_url,
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.9',
            }
        )

        with urllib.request.urlopen(req, timeout=12) as resp:
            html = resp.read().decode('utf-8', errors='ignore')

        # Procura link direto de vídeo MP4 na página
        patterns = [
            r'\"browser_native_hd_url\"\s*:\s*\"(.*?)\"',
            r'\"playable_url_quality_hd\"\s*:\s*\"(.*?)\"',
            r'\"browser_native_sd_url\"\s*:\s*\"(.*?)\"',
            r'\"playable_url\"\s*:\s*\"(.*?)\"',
            r'\"hd_src\"\s*:\s*\"(.*?)\"',
            r'\"sd_src\"\s*:\s*\"(.*?)\"',
        ]

        stream_url = None
        for p in patterns:
            m = re.search(p, html)
            if m:
                raw = m.group(1).replace(r'\/', '/').replace('&amp;', '&')
                if raw and "blank.mp4" not in raw:
                    stream_url = raw
                    break

        if not stream_url:
            raise RuntimeError("Não foi possível localizar o fluxo direto de vídeo do Facebook. O vídeo pode ser privado ou exigir login.")

        # Título limpo
        title = f"Facebook_Reel_{video_id or 'video'}"
        title_match = re.search(r'<meta\s+property=["\']og:title["\']\s+content=["\'](.*?)["\']', html, re.IGNORECASE)
        if title_match and title_match.group(1).strip():
            raw_title = title_match.group(1).strip()
            title = re.sub(r'[\s|]*Facebook.*$', '', raw_title, flags=re.IGNORECASE).strip()
            title = re.sub(r'[\\/*?:"<>|]', '_', title)[:60]

        self.title = title
        filename = os.path.join(self.output_dir, f"{title}.mp4")
        self.file_path = filename

        # Baixa diretamente da CDN usando facebookexternalhit para autorização de token
        cdn_req = urllib.request.Request(
            stream_url,
            headers={
                'User-Agent': 'facebookexternalhit/1.1',
                'Accept': '*/*',
                'Sec-Fetch-Mode': 'navigate',
            }
        )

        with urllib.request.urlopen(cdn_req, timeout=20) as cdn_resp:
            total_bytes = int(cdn_resp.headers.get('Content-Length') or 0)
            self.total_bytes = total_bytes
            downloaded = 0

            with open(filename, 'wb') as f_out:
                while not self._cancelled:
                    chunk = cdn_resp.read(65536)
                    if not chunk:
                        break
                    f_out.write(chunk)
                    downloaded += len(chunk)
                    self.downloaded_bytes = downloaded
                    if total_bytes > 0:
                        self.progress_percent = round((downloaded / total_bytes) * 100, 1)
                    self._notify_update()

            if self._cancelled:
                if os.path.exists(filename):
                    os.remove(filename)
                raise yt_dlp.utils.DownloadCancelled("Download cancelado pelo usuário.")
