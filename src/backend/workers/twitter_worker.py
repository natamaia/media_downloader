import os
import shutil
import logging
import yt_dlp
from src.backend.models import FormatType, WorkerStatus
from src.backend.workers.base_worker import BaseDownloadWorker

logger = logging.getLogger(__name__)

class TwitterWorker(BaseDownloadWorker):
    """
    Dedicated worker for X (Twitter), Xwriter, and TwitSave.
    """
    def get_provider_name(self) -> str:
        return "X (Twitter)"

    def execute_download(self):
        target_url = self.url
        # Normaliza domínios alternativos para x.com ou twitter.com
        if "xwriter" in target_url:
            target_url = target_url.replace("xwriter.io", "x.com")

        out_template = os.path.join(self.output_dir, '%(title)s.%(ext)s')
        has_ffmpeg = bool(shutil.which("ffmpeg"))

        ydl_opts = {
            'outtmpl': out_template,
            'progress_hooks': [self._progress_hook],
            'quiet': True,
            'no_warnings': True,
            'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        }

        if self.format_type == FormatType.MP3:
            if has_ffmpeg:
                ydl_opts.update({
                    'format': 'bestaudio/best',
                    'postprocessors': [{
                        'key': 'FFmpegExtractAudio',
                        'preferredcodec': 'mp3',
                        'preferredquality': '320',
                    }],
                })
            else:
                ydl_opts['format'] = 'bestaudio/best'
        else:
            ydl_opts['format'] = 'best[ext=mp4][acodec!=none]/best[acodec!=none]/best'

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(target_url, download=False)
            self.title = info.get('title', 'X_Post')
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
