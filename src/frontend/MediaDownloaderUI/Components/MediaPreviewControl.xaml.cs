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

        public MediaPreviewControl()
        {
            InitializeComponent();
            UpdateTargetDirText();
        }

        public bool IsAudioSelected => RbMp3.IsChecked == true;

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

            // Populate quality dropdown
            PopulateQualities(info.Qualities);

            // Auto-detect audio vs video provider to toggle MP3/MP4 selection automatically
            bool isAudioProvider = info.Provider is "Spotify" or "Deezer" or "YouTube Music" or "SoundCloud";
            SetSelectedFormat(isAudioProvider);
        }

        public void SetSelectedFormat(bool isAudio)
        {
            if (isAudio)
            {
                RbMp3.IsChecked = true;
                RbMp4.IsChecked = false;
            }
            else
            {
                RbMp4.IsChecked = true;
                RbMp3.IsChecked = false;
            }
            UpdateTargetDirText();
        }

        private void PopulateQualities(List<string> qualities)
        {
            if (qualities == null || qualities.Count == 0) return;

            CmbQuality.Items.Clear();
            foreach (var q in qualities)
            {
                var item = new ComboBoxItem { Content = q };
                item.SetResourceReference(Control.ForegroundProperty, "TextPrimaryBrush");
                item.SetResourceReference(Control.BackgroundProperty, "CardBackgroundBrush");
                CmbQuality.Items.Add(item);
            }
            CmbQuality.SelectedIndex = 0;
        }

        private void Format_Checked(object sender, RoutedEventArgs e)
        {
            UpdateTargetDirText();
        }

        private void UpdateTargetDirText()
        {
            if (TxtCurrentTargetDir == null) return;

            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            if (RbMp3 != null && RbMp3.IsChecked == true)
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
            string quality = "1080p";
            if (CmbQuality.SelectedItem is ComboBoxItem selectedItem)
            {
                quality = selectedItem.Content.ToString() ?? "1080p";
            }

            DownloadRequested?.Invoke(this, (formatType, quality));
        }
    }
}
