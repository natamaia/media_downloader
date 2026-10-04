using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;

namespace MediaDownloaderUI.Components
{
    public partial class MediaPreviewControl : UserControl
    {
        public event EventHandler<(string formatType, string quality)>? DownloadRequested;
        private VideoInfo? _currentInfo;

        private readonly List<string> _audioQualities = new()
        {
            "320 kbps (Alta)",
            "256 kbps",
            "192 kbps (Média)",
            "128 kbps (Baixa)"
        };

        private readonly List<string> _defaultVideoQualities = new()
        {
            "1080p (FHD)",
            "720p (HD)",
            "480p (SD)",
            "360p"
        };

        private List<string> _extractedVideoQualities = new();

        public MediaPreviewControl()
        {
            InitializeComponent();
            UpdateQualitiesForFormat();
            UpdateTargetDirText();
        }

        public bool IsAudioSelected => RbMp3?.IsChecked == true;

        public void SetLoading(string message = "Analisando metadados do link...")
        {
            TxtPreviewTitle.Text = message;
            TxtProviderName.Text = "Analisando";
            TxtPreviewDetails.Text = "Aguarde enquanto os detalhes do link são extraídos...";
            ImgThumbnail.Source = null;
            BtnStartDownload.IsEnabled = false;
        }

        public void SetInfo(VideoInfo info)
        {
            _currentInfo = info;
            TxtPreviewTitle.Text = info.Title;
            TxtProviderName.Text = info.Provider;
            TxtPreviewDetails.Text = $"Duração: {TimeSpan.FromSeconds(info.DurationSeconds):mm\\:ss} | Qualidades: {string.Join(", ", info.Qualities.Take(4))}";
            BtnStartDownload.IsEnabled = true;

            // Safe async image loading without UI thread freezing
            if (!string.IsNullOrEmpty(info.Thumbnail))
            {
                try
                {
                    var bitmap = new BitmapImage();
                    bitmap.BeginInit();
                    bitmap.UriSource = new Uri(info.Thumbnail, UriKind.Absolute);
                    bitmap.CacheOption = BitmapCacheOption.OnLoad;
                    bitmap.CreateOptions = BitmapCreateOptions.IgnoreColorProfile;
                    bitmap.EndInit();
                    ImgThumbnail.Source = bitmap;
                }
                catch
                {
                    ImgThumbnail.Source = null;
                }
            }

            _extractedVideoQualities = info.Qualities ?? new List<string>();

            // Auto-detect audio vs video provider to toggle MP3/MP4 selection automatically
            bool isAudioProvider = info.Provider is "Spotify" or "Deezer" or "YouTube Music" or "SoundCloud";
            SetSelectedFormat(isAudioProvider);
        }

        public void SetSelectedFormat(bool isAudio)
        {
            if (isAudio)
            {
                if (RbMp3 != null) RbMp3.IsChecked = true;
                if (RbMp4 != null) RbMp4.IsChecked = false;
            }
            else
            {
                if (RbMp4 != null) RbMp4.IsChecked = true;
                if (RbMp3 != null) RbMp3.IsChecked = false;
            }
            UpdateQualitiesForFormat();
            UpdateTargetDirText();
        }

        private void Format_Checked(object sender, RoutedEventArgs e)
        {
            UpdateQualitiesForFormat();
            UpdateTargetDirText();
        }

        private void UpdateQualitiesForFormat()
        {
            if (CmbQuality == null) return;

            if (IsAudioSelected)
            {
                CmbQuality.ItemsSource = _audioQualities;
            }
            else
            {
                CmbQuality.ItemsSource = (_extractedVideoQualities.Count > 0)
                    ? _extractedVideoQualities
                    : _defaultVideoQualities;
            }

            if (CmbQuality.Items.Count > 0)
            {
                CmbQuality.SelectedIndex = 0;
            }
        }

        private void UpdateTargetDirText()
        {
            if (TxtCurrentTargetDir == null) return;

            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            if (IsAudioSelected)
            {
                TxtCurrentTargetDir.Text = $"Pasta destino: {Path.Combine(userProfile, "Music", "app_music")}";
            }
            else
            {
                TxtCurrentTargetDir.Text = $"Pasta destino: {Path.Combine(userProfile, "Videos", "app_videos")}";
            }
        }

        private void BtnStartDownload_Click(object sender, RoutedEventArgs e)
        {
            string formatType = IsAudioSelected ? "mp3" : "mp4";
            string rawQualityStr = CmbQuality.SelectedItem as string ?? (IsAudioSelected ? "320k" : "1080p");
            
            // Clean up display strings (e.g. "320 kbps (Alta)" -> "320k", "1080p (FHD)" -> "1080p")
            string quality = rawQualityStr.Split(' ')[0];

            DownloadRequested?.Invoke(this, (formatType, quality));
        }
    }
}
