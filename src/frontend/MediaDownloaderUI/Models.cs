using System.Collections.Generic;
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

    public class DownloadProgress
    {
        [JsonPropertyName("download_id")]
        public string DownloadId { get; set; } = string.Empty;

        [JsonPropertyName("url")]
        public string Url { get; set; } = string.Empty;

        [JsonPropertyName("provider")]
        public string Provider { get; set; } = "Generic";

        [JsonPropertyName("title")]
        public string Title { get; set; } = "Aguardando...";

        [JsonPropertyName("format_type")]
        public string FormatType { get; set; } = "mp4";

        [JsonPropertyName("quality")]
        public string Quality { get; set; } = "1080p";

        [JsonPropertyName("status")]
        public string Status { get; set; } = "PENDING";

        [JsonPropertyName("progress_percent")]
        public double ProgressPercent { get; set; }

        [JsonPropertyName("download_speed")]
        public string DownloadSpeed { get; set; } = "0 KB/s";

        [JsonPropertyName("eta_seconds")]
        public int EtaSeconds { get; set; }

        [JsonPropertyName("file_path")]
        public string? FilePath { get; set; }

        [JsonPropertyName("error_message")]
        public string? ErrorMessage { get; set; }

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
    }
}
