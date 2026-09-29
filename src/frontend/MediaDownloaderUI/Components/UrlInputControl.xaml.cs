using System;
using System.Collections.Generic;
using System.IO;
using System.Windows;
using System.Windows.Controls;

namespace MediaDownloaderUI.Components
{
    public partial class UrlInputControl : UserControl
    {
        public event EventHandler<string>? AnalyzeRequested;
        public event EventHandler<(string url, string formatType, string quality)>? DownloadRequested;

        public UrlInputControl()
        {
            InitializeComponent();
            UpdateTargetDirText();
        }

        public string GetUrl() => TxtUrl.Text.Trim();

        public bool IsAudioSelected => RbMp3.IsChecked == true;

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

        public void PopulateQualities(List<string> qualities)
        {
            if (qualities == null || qualities.Count == 0) return;

            CmbQuality.Items.Clear();
            foreach (var q in qualities)
            {
                CmbQuality.Items.Add(new ComboBoxItem { Content = q });
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

        private void BtnAnalyze_Click(object sender, RoutedEventArgs e)
        {
            string url = GetUrl();
            if (string.IsNullOrEmpty(url) || url.StartsWith("Cole aqui"))
            {
                MessageBox.Show("Por favor, cole um link válido para analisar.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            AnalyzeRequested?.Invoke(this, url);
        }

        private void BtnStartDownload_Click(object sender, RoutedEventArgs e)
        {
            string url = GetUrl();
            if (string.IsNullOrEmpty(url) || url.StartsWith("Cole aqui"))
            {
                MessageBox.Show("Cole uma URL válida antes de iniciar o download.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string formatType = IsAudioSelected ? "mp3" : "mp4";
            string quality = "1080p";
            if (CmbQuality.SelectedItem is ComboBoxItem selectedItem)
            {
                quality = selectedItem.Content.ToString() ?? "1080p";
            }

            DownloadRequested?.Invoke(this, (url, formatType, quality));
        }
    }
}
