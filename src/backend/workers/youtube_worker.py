import os
import shutil
import logging
import yt_dlp
from src.backend.models import FormatType, WorkerStatus
from src.backend.extractor import ExtractorService
from src.backend.workers.base_worker import BaseDownloadWorker

logger = logging.getLogger(__name__)

class YouTubeWorker(BaseDownloadWorker):
    """
    Dedicated worker for YouTube, YouTube Shorts, and YouTube Music.
    Handles adaptive streams, shorts redirects, audio extraction, and fallbacks.
    """
    def get_provider_name(self) -> str:
        if "music.youtube.com" in self.url.lower():
            return "YouTube Music"
        elif "youtube.com/shorts" in self.url.lower() or "/shorts/" in self.url.lower():
            return "YouTube Shorts"
        return "YouTube"

    def execute_download(self):
        target_url, provider, is_audio_override = ExtractorService.resolve_target(self.url)
        self.provider = provider
        if is_audio_override:
            self.format_type = FormatType.MP3

        out_template = os.path.join(self.output_dir, '%(title)s.%(ext)s')
        has_ffmpeg = bool(shutil.which("ffmpeg"))

        ydl_opts = {
            'outtmpl': out_template,
            'progress_hooks': [self._progress_hook],
            'quiet': True,
            'no_warnings': True,
            'nocheckcertificate': True,
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
                ydl_opts.update({
                    'format': 'bestaudio[ext=m4a]/bestaudio/best',
                })
        else:
            res_clean = self.quality.replace('p', '')
            if has_ffmpeg:
                if res_clean.isdigit():
                    height = int(res_clean)
                    ydl_opts['format'] = f'bestvideo[height<={height}][ext=mp4]+bestaudio[ext=m4a]/best[height<={height}][ext=mp4]/best'
                else:
                    ydl_opts['format'] = 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'
                ydl_opts['merge_output_format'] = 'mp4'
            else:
                if res_clean.isdigit():
                    height = int(res_clean)
                    ydl_opts['format'] = f'best[height<={height}][ext=mp4][acodec!=none]/best[height<={height}][acodec!=none]/best[ext=mp4][acodec!=none]/best[acodec!=none]/best'
                else:
                    ydl_opts['format'] = 'best[ext=mp4][acodec!=none]/best[acodec!=none]/best[ext=mp4]/best'

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(target_url, download=False)
            if info.get('_type') == 'playlist' and info.get('entries'):
                info = info['entries'][0]

            self.title = info.get('title', 'YouTube Vídeo')
            filename = ydl.prepare_filename(info)
            if self.format_type == FormatType.MP3 and has_ffmpeg:
                filename = os.path.splitext(filename)[0] + ".mp3"
            self.file_path = filename

            if os.path.exists(filename):
                logger.info(f"Arquivo '{filename}' já existe no diretório. Marcando status como EXISTS.")
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
                for ext in [".mp3", ".m4a", ".webm", ".opus", ".mp4", ".mkv"]:
                    cand = base_no_ext + ext
                    if os.path.exists(cand):
                        filename = cand
                        self.file_path = filename
                        break
