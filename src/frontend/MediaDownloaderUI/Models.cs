using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.Json.Serialization;

namespace MediaDownloaderUI
{
    public class VideoInfo
    {
        [JsonPropertyName("url")]
        public string Url { get; set; } = string.Empty;

        [JsonPropertyName("provider")]
        public string Provider { get; set; } = "Generic";

        [JsonPropertyName("title")]
        public string Title { get; set; } = string.Empty;

        [JsonPropertyName("duration_seconds")]
        public int DurationSeconds { get; set; }

        [JsonPropertyName("thumbnail")]
        public string? Thumbnail { get; set; }

        [JsonPropertyName("qualities")]
        public List<string> Qualities { get; set; } = new();

        [JsonPropertyName("audio_formats")]
        public List<string> AudioFormats { get; set; } = new();
    }

    public class DownloadRequest
    {
        [JsonPropertyName("url")]
        public string Url { get; set; } = string.Empty;

        [JsonPropertyName("format_type")]
        public string FormatType { get; set; } = "mp4";

        [JsonPropertyName("quality")]
        public string Quality { get; set; } = "1080p";

        [JsonPropertyName("output_dir")]
        public string? OutputDir { get; set; }
    }

    public class DownloadProgress : INotifyPropertyChanged
    {
        private string _downloadId = string.Empty;
        private string _url = string.Empty;
        private string _provider = "Generic";
        private string _title = "Aguardando...";
        private string _formatType = "mp4";
        private string _quality = "1080p";
        private string _status = "PENDING";
        private double _progressPercent;
        private string _downloadSpeed = "0 KB/s";
        private int _etaSeconds;
        private string? _filePath;
        private string? _errorMessage;

        public event PropertyChangedEventHandler? PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        [JsonPropertyName("download_id")]
        public string DownloadId
        {
            get => _downloadId;
            set { if (_downloadId != value) { _downloadId = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("url")]
        public string Url
        {
            get => _url;
            set { if (_url != value) { _url = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("provider")]
        public string Provider
        {
            get => _provider;
            set { if (_provider != value) { _provider = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("title")]
        public string Title
        {
            get => _title;
            set { if (_title != value) { _title = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("format_type")]
        public string FormatType
        {
            get => _formatType;
            set { if (_formatType != value) { _formatType = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("quality")]
        public string Quality
        {
            get => _quality;
            set { if (_quality != value) { _quality = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("status")]
        public string Status
        {
            get => _status;
            set
            {
                if (_status != value)
                {
                    _status = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(DisplayStatus));
                    OnPropertyChanged(nameof(IsDeleted));
                }
            }
        }

        [JsonPropertyName("progress_percent")]
        public double ProgressPercent
        {
            get => _progressPercent;
            set { if (_progressPercent != value) { _progressPercent = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("download_speed")]
        public string DownloadSpeed
        {
            get => _downloadSpeed;
            set { if (_downloadSpeed != value) { _downloadSpeed = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("eta_seconds")]
        public int EtaSeconds
        {
            get => _etaSeconds;
            set { if (_etaSeconds != value) { _etaSeconds = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("file_path")]
        public string? FilePath
        {
            get => _filePath;
            set { if (_filePath != value) { _filePath = value; OnPropertyChanged(); } }
        }

        [JsonPropertyName("error_message")]
        public string? ErrorMessage
        {
            get => _errorMessage;
            set { if (_errorMessage != value) { _errorMessage = value; OnPropertyChanged(); } }
        }

        [JsonIgnore]
        public string DisplayStatus => Status switch
        {
            "PENDING" => "PENDENTE",
            "EXTRACTING" => "ANALISANDO",
            "DOWNLOADING" => "BAIXANDO",
            "CONVERTING" => "CONVERTENDO",
            "COMPLETED" => "CONCLUÍDO",
            "FAILED" => "ERRO",
            "CANCELLED" => "CANCELADO",
            "DELETED" => "DELETADO",
            _ => Status
        };

        [JsonIgnore]
        public bool IsDeleted => Status == "DELETED";

        public void CopyFrom(DownloadProgress other)
        {
            Url = other.Url;
            Provider = other.Provider;
            Title = other.Title;
            FormatType = other.FormatType;
            Quality = other.Quality;
            Status = other.Status;
            ProgressPercent = other.ProgressPercent;
            DownloadSpeed = other.DownloadSpeed;
            EtaSeconds = other.EtaSeconds;
            FilePath = other.FilePath;
            ErrorMessage = other.ErrorMessage;
        }
    }
}
