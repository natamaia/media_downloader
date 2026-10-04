import os
import shutil
import logging
import urllib.request
import yt_dlp
from src.backend.models import FormatType, WorkerStatus
from src.backend.extractor import ExtractorService
from src.backend.workers.base_worker import BaseDownloadWorker

logger = logging.getLogger(__name__)

class GenericWorker(BaseDownloadWorker):
    """
    Worker for Spotify, Deezer, SoundCloud, Vimeo, course platforms (Hotmart, Wistia, etc.),
    and direct media URLs (.mp4, .m3u8, .mp3).
    """
    def get_provider_name(self) -> str:
        return ExtractorService.detect_provider(self.url)

    def execute_download(self):
        target_url, provider, is_audio_override = ExtractorService.resolve_target(self.url)
        self.provider = provider
        if is_audio_override:
            self.format_type = FormatType.MP3

        out_template = os.path.join(self.output_dir, '%(title)s.%(ext)s')
        has_ffmpeg = bool(shutil.which("ffmpeg"))

        # Se for link direto de arquivo (.mp4, .mp3, etc.)
        if any(self.url.lower().endswith(ext) or f"{ext}?" in self.url.lower() for ext in [".mp4", ".mp3", ".m4a", ".webm"]):
            self._download_direct_file(self.url)
            return

        ydl_opts = {
            'outtmpl': out_template,
            'progress_hooks': [self._progress_hook],
            'quiet': True,
            'no_warnings': True,
            'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        }

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
                ydl_opts['format'] = 'bestaudio/best'
        else:
            ydl_opts['format'] = 'best[ext=mp4][acodec!=none]/best[acodec!=none]/best'

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(target_url, download=False)
            if info.get('_type') == 'playlist' and info.get('entries'):
                info = info['entries'][0]

            self.title = info.get('title', 'Mídia Web')
            filename = ydl.prepare_filename(info)
            if self.format_type == FormatType.MP3 and has_ffmpeg:
                filename = os.path.splitext(filename)[0] + ".mp3"
            self.file_path = filename

            if os.path.exists(filename):
                if not self._cancelled and self.status != WorkerStatus.DELETED:
                    self.status = WorkerStatus.EXISTS
                    self.progress_percent = 100.0
                    self.error_message = "Arquivo já existente no diretório de destino."
                    self._notify_update()
                return

            ydl.download([target_url])

    def _download_direct_file(self, url: str):
        """Baixa arquivo direto via HTTP stream com progresso."""
        parsed_path = urllib.parse.urlparse(url).path
        base_name = os.path.basename(parsed_path) or "download"
        if "." not in base_name:
            ext = "mp3" if self.format_type == FormatType.MP3 else "mp4"
            base_name = f"{base_name}.{ext}"

        filename = os.path.join(self.output_dir, base_name)
        self.file_path = filename
        self.title = os.path.splitext(base_name)[0]

        req = urllib.request.Request(
            url,
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                'Accept': '*/*',
            }
        )

        with urllib.request.urlopen(req, timeout=30) as resp:
            total_bytes = int(resp.headers.get('Content-Length') or 0)
            self.total_bytes = total_bytes
            downloaded = 0

            with open(filename, 'wb') as f_out:
                while not self._cancelled:
                    chunk = resp.read(65536)
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
