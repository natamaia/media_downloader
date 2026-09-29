using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;
using System.Windows.Threading;

namespace MediaDownloaderUI
{
    public partial class MainWindow : Window
    {
        private readonly ApiClient _apiClient;
        private readonly DispatcherTimer _pollTimer;
        private VideoInfo? _currentInfo;

        public MainWindow()
        {
            InitializeComponent();
            _apiClient = new ApiClient();

            // Set default OS paths text
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string musicPath = Path.Combine(userProfile, "Music", "app_music");
            string videosPath = Path.Combine(userProfile, "Videos", "app_videos");

            TxtMusicPath.Text = musicPath;
            TxtVideoPath.Text = videosPath;

            UpdateTargetDirText();

            // Timer for periodic progress updates from backend API
            _pollTimer = new DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(1)
            };
            _pollTimer.Tick += PollTimer_Tick;

            // Handle window closing to clean up background processes
            this.Closed += MainWindow_Closed;

            // Auto-start backend & check health on startup
            InitBackendAndHealthAsync();
        }

        private async void InitBackendAndHealthAsync()
        {
            // 1. Ensure backend API server process is running automatically
            await BackendManager.EnsureBackendRunningAsync();

            // 2. Check health status and update UI badge
            bool isOnline = await _apiClient.CheckHealthAsync();
            if (isOnline)
            {
                BadgeBackendStatus.Background = System.Windows.Media.Brushes.DarkGreen;
                DotStatus.Fill = System.Windows.Media.Brushes.SpringGreen;
                TxtStatusBackend.Text = "API Interna On-line";
                _pollTimer.Start();
            }
            else
            {
                BadgeBackendStatus.Background = System.Windows.Media.Brushes.DarkRed;
                DotStatus.Fill = System.Windows.Media.Brushes.OrangeRed;
                TxtStatusBackend.Text = "API Desconectada";
            }
        }

        private void MainWindow_Closed(object? sender, EventArgs e)
        {
            _pollTimer.Stop();
            BackendManager.StopBackend();
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

        private async void BtnAnalyze_Click(object sender, RoutedEventArgs e)
        {
            string url = TxtUrl.Text.Trim();
            if (string.IsNullOrEmpty(url) || url.StartsWith("Cole aqui"))
            {
                MessageBox.Show("Por favor, cole um link válido para analisar.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            TxtPreviewTitle.Text = "Analisando metadados do link...";
            CardPreview.Visibility = Visibility.Visible;

            var info = await _apiClient.GetVideoInfoAsync(url);
            if (info != null)
            {
                _currentInfo = info;
                TxtPreviewTitle.Text = info.Title;
                TxtProviderName.Text = info.Provider;
                TxtPreviewDuration.Text = $"Duração: {TimeSpan.FromSeconds(info.DurationSeconds):mm\\:ss} | Formatos disponíveis: {string.Join(", ", info.Qualities.Take(4))}";

                if (!string.IsNullOrEmpty(info.Thumbnail))
                {
                    try
                    {
                        ImgThumbnail.Source = new BitmapImage(new Uri(info.Thumbnail));
                    }
                    catch { }
                }

                // Populate quality combo if items exist
                if (info.Qualities.Count > 0)
                {
                    CmbQuality.Items.Clear();
                    foreach (var q in info.Qualities)
                    {
                        CmbQuality.Items.Add(new ComboBoxItem { Content = q });
                    }
                    CmbQuality.SelectedIndex = 0;
                }
            }
            else
            {
                MessageBox.Show("Não foi possível analisar o link informado. Verifique se a URL está acessível.", "Erro", MessageBoxButton.OK, MessageBoxImage.Error);
                CardPreview.Visibility = Visibility.Collapsed;
            }
        }

        private async void BtnStartDownload_Click(object sender, RoutedEventArgs e)
        {
            string url = TxtUrl.Text.Trim();
            if (string.IsNullOrEmpty(url) || url.StartsWith("Cole aqui"))
            {
                MessageBox.Show("Cole uma URL válida antes de iniciar o download.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string formatType = (RbMp3.IsChecked == true) ? "mp3" : "mp4";
            string quality = "1080p";
            if (CmbQuality.SelectedItem is ComboBoxItem selectedItem)
            {
                quality = selectedItem.Content.ToString() ?? "1080p";
            }

            var download = await _apiClient.CreateDownloadAsync(url, formatType, quality);
            if (download != null)
            {
                RefreshDownloadsList();
            }
            else
            {
                MessageBox.Show("Erro ao enviar tarefa para o orquestrador de workers.", "Erro", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void PollTimer_Tick(object? sender, EventArgs e)
        {
            RefreshDownloadsList();
        }

        private async void RefreshDownloadsList()
        {
            var downloads = await _apiClient.ListDownloadsAsync();
            LstDownloads.ItemsSource = downloads;

            int activeCount = downloads.Count(d => d.Status == "EXTRACTING" || d.Status == "DOWNLOADING" || d.Status == "CONVERTING");
            TxtWorkerCount.Text = $"{activeCount} Workers Ativos";
            TxtEmptyList.Visibility = (downloads.Count == 0) ? Visibility.Visible : Visibility.Collapsed;
        }

        private async void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            if (sender is Button btn && btn.Tag is string downloadId)
            {
                bool success = await _apiClient.CancelDownloadAsync(downloadId);
                if (success)
                {
                    RefreshDownloadsList();
                }
            }
        }

        private void BtnOpenFolder_Click(object sender, RoutedEventArgs e)
        {
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string targetFolder = (RbMp3.IsChecked == true)
                ? Path.Combine(userProfile, "Music", "app_music")
                : Path.Combine(userProfile, "Videos", "app_videos");

            if (sender is Button btn && btn.Tag is string filePath && !string.IsNullOrEmpty(filePath))
            {
                if (File.Exists(filePath))
                {
                    Process.Start("explorer.exe", $"/select,\"{filePath}\"");
                    return;
                }
            }

            if (!Directory.Exists(targetFolder))
            {
                Directory.CreateDirectory(targetFolder);
            }
            Process.Start("explorer.exe", targetFolder);
        }
    }
}