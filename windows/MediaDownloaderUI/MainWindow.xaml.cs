using System;
using System.Collections.ObjectModel;
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
        private readonly ObservableCollection<DownloadProgress> _downloadsCollection;

        public MainWindow()
        {
            InitializeComponent();
            _apiClient = new ApiClient();
            _downloadsCollection = new ObservableCollection<DownloadProgress>();

            // Bind ObservableCollection to prevent UI re-render glitching
            LstDownloads.ItemsSource = _downloadsCollection;

            // Connect DownloadRequested event from PreviewCard
            PreviewCard.DownloadRequested += PreviewCard_DownloadRequested;

            // Polling timer for real-time progress updates
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
            await BackendManager.EnsureBackendRunningAsync();

            bool isOnline = await _apiClient.CheckHealthAsync();
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

            try
            {
                var info = await _apiClient.GetVideoInfoAsync(url);
                if (info != null)
                {
                    PreviewCard.SetInfo(info);
                }
                else
                {
                    MessageBox.Show("Não foi possível analisar o link informado. Verifique se a URL está acessível.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Warning);
                    PreviewCard.Visibility = Visibility.Collapsed;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro durante a análise: {ex.Message}", "Erro", MessageBoxButton.OK, MessageBoxImage.Error);
                PreviewCard.Visibility = Visibility.Collapsed;
            }
        }

        private async void PreviewCard_DownloadRequested(object? sender, (string formatType, string quality) args)
        {
            string url = UrlInputCard.GetUrl();
            if (string.IsNullOrEmpty(url) || url.StartsWith("Cole aqui"))
            {
                MessageBox.Show("Por favor, cole um link válido.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                var download = await _apiClient.CreateDownloadAsync(url, args.formatType, args.quality);
                if (download != null)
                {
                    RefreshDownloadsList();
                }
                else
                {
                    MessageBox.Show("Erro ao enviar tarefa para o orquestrador de workers.", "Erro", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao iniciar download: {ex.Message}", "Erro", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void PollTimer_Tick(object? sender, EventArgs e)
        {
            RefreshDownloadsList();
        }

        private async void RefreshDownloadsList()
        {
            try
            {
                var rawDownloads = await _apiClient.ListDownloadsAsync();
                var downloads = rawDownloads.AsEnumerable().Reverse().ToList();

                if (downloads.Count == 0)
                {
                    _downloadsCollection.Clear();
                }
                else
                {
                    // Map existing items by ID for fast in-place property updates
                    var existingDict = _downloadsCollection.ToDictionary(d => d.DownloadId);
                    var newIds = new HashSet<string>(downloads.Select(d => d.DownloadId));

                    // 1. Remove items no longer present in backend response
                    for (int i = _downloadsCollection.Count - 1; i >= 0; i--)
                    {
                        if (!newIds.Contains(_downloadsCollection[i].DownloadId))
                        {
                            _downloadsCollection.RemoveAt(i);
                        }
                    }

                    // 2. Add or update items in reactive order
                    for (int i = 0; i < downloads.Count; i++)
                    {
                        var newItem = downloads[i];
                        if (existingDict.TryGetValue(newItem.DownloadId, out var existingItem))
                        {
                            existingItem.CopyFrom(newItem);
                            
                            int currentIdx = _downloadsCollection.IndexOf(existingItem);
                            if (currentIdx != i && currentIdx >= 0 && i < _downloadsCollection.Count)
                            {
                                _downloadsCollection.Move(currentIdx, i);
                            }
                        }
                        else
                        {
                            if (i <= _downloadsCollection.Count)
                            {
                                _downloadsCollection.Insert(i, newItem);
                            }
                            else
                            {
                                _downloadsCollection.Add(newItem);
                            }
                        }
                    }
                }

                int activeCount = _downloadsCollection.Count(d => d.Status is "EXTRACTING" or "DOWNLOADING" or "CONVERTING");
                TxtWorkerCount.Text = $"{activeCount} Workers Ativos";
                TxtEmptyList.Visibility = (_downloadsCollection.Count == 0) ? Visibility.Visible : Visibility.Collapsed;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error updating downloads UI list: {ex.Message}");
            }
        }

        private async void BtnDelete_Click(object sender, RoutedEventArgs e)
        {
            if (sender is Button btn && btn.Tag is string downloadId)
            {
                bool success = await _apiClient.DeleteDownloadAsync(downloadId);
                if (success)
                {
                    RefreshDownloadsList();
                }
            }
        }

        private async void BtnClearDownloads_Click(object sender, RoutedEventArgs e)
        {
            // Instantly clear UI for snappy response
            _downloadsCollection.Clear();
            TxtWorkerCount.Text = "0 Workers Ativos";
            TxtEmptyList.Visibility = Visibility.Visible;

            bool success = await _apiClient.ClearDownloadsAsync();
            RefreshDownloadsList();
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            ThemeManager.UpdateNativeTitleBarTheme(this, ThemeManager.IsLightTheme);
        }

        private void Window_StateChanged(object? sender, EventArgs e)
        {
            if (BtnMaximize != null)
            {
                BtnMaximize.Content = (WindowState == WindowState.Maximized) ? "🗗" : "🗖";
            }
        }

        private void BtnMinimize_Click(object sender, RoutedEventArgs e)
        {
            SystemCommands.MinimizeWindow(this);
        }

        private void BtnMaximize_Click(object sender, RoutedEventArgs e)
        {
            if (WindowState == WindowState.Maximized)
            {
                SystemCommands.RestoreWindow(this);
            }
            else
            {
                SystemCommands.MaximizeWindow(this);
            }
        }

        private void BtnClose_Click(object sender, RoutedEventArgs e)
        {
            SystemCommands.CloseWindow(this);
        }

        private void BtnOpenFolder_Click(object sender, RoutedEventArgs e)
        {
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string targetFolder = PreviewCard.IsAudioSelected
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