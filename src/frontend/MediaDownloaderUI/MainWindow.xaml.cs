using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;

namespace MediaDownloaderUI
{
    public partial class MainWindow : Window
    {
        private readonly ApiClient _apiClient;
        private readonly DispatcherTimer _pollTimer;

        public MainWindow()
        {
            InitializeComponent();
            _apiClient = new ApiClient();

            // Set OS System paths in Header Component
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string musicPath = Path.Combine(userProfile, "Music", "app_music");
            string videosPath = Path.Combine(userProfile, "Videos", "app_videos");
            HeaderControl.SetPaths(musicPath, videosPath);

            // Timer for progress polling from backend API
            _pollTimer = new DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(1)
            };
            _pollTimer.Tick += PollTimer_Tick;

            this.Closed += MainWindow_Closed;

            // Non-blocking auto-start backend
            InitBackendAndHealthAsync();
        }

        private async void InitBackendAndHealthAsync()
        {
            // Non-blocking start of Python backend server
            await BackendManager.EnsureBackendRunningAsync();

            bool isOnline = await _apiClient.CheckHealthAsync();
            HeaderControl.SetStatus(isOnline);

            if (isOnline)
            {
                _pollTimer.Start();
            }
        }

        private void MainWindow_Closed(object? sender, EventArgs e)
        {
            _pollTimer.Stop();
            BackendManager.StopBackend();
        }

        private async void UrlInputCard_AnalyzeRequested(object? sender, string url)
        {
            PreviewCard.Visibility = Visibility.Visible;
            PreviewCard.SetLoading();

            var info = await _apiClient.GetVideoInfoAsync(url);
            if (info != null)
            {
                PreviewCard.SetInfo(info);
                UrlInputCard.PopulateQualities(info.Qualities);

                // Auto-detect audio vs video provider to toggle MP3/MP4 selection automatically
                bool isAudioProvider = info.Provider is "Spotify" or "Deezer" or "YouTube Music" or "SoundCloud";
                UrlInputCard.SetSelectedFormat(isAudioProvider);
            }
            else
            {
                MessageBox.Show("Não foi possível analisar o link informado. Verifique a URL.", "Erro", MessageBoxButton.OK, MessageBoxImage.Error);
                PreviewCard.Visibility = Visibility.Collapsed;
            }
        }

        private async void UrlInputCard_DownloadRequested(object? sender, (string url, string formatType, string quality) args)
        {
            var download = await _apiClient.CreateDownloadAsync(args.url, args.formatType, args.quality);
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
            string targetFolder = UrlInputCard.IsAudioSelected
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