using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace MediaDownloaderUI
{
    public class ApiClient
    {
        private readonly HttpClient _client;
        private const string BaseUrl = "http://127.0.0.1:8000";

        public ApiClient()
        {
            _client = new HttpClient { BaseAddress = new Uri(BaseUrl) };
            _client.Timeout = TimeSpan.FromSeconds(15);
        }

        public async Task<bool> CheckHealthAsync()
        {
            try
            {
                var resp = await _client.GetAsync("/health");
                return resp.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<VideoInfo?> GetVideoInfoAsync(string url)
        {
            try
            {
                var payload = new { url };
                var resp = await _client.PostAsJsonAsync("/api/v1/info", payload);
                if (resp.IsSuccessStatusCode)
                {
                    return await resp.Content.ReadFromJsonAsync<VideoInfo>();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error fetching info: {ex.Message}");
            }
            return null;
        }

        public async Task<DownloadProgress?> CreateDownloadAsync(string url, string formatType, string quality)
        {
            try
            {
                var payload = new DownloadRequest
                {
                    Url = url,
                    FormatType = formatType,
                    Quality = quality
                };
                var resp = await _client.PostAsJsonAsync("/api/v1/downloads", payload);
                if (resp.IsSuccessStatusCode)
                {
                    return await resp.Content.ReadFromJsonAsync<DownloadProgress>();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error creating download: {ex.Message}");
            }
            return null;
        }

        public async Task<List<DownloadProgress>> ListDownloadsAsync()
        {
            try
            {
                var result = await _client.GetFromJsonAsync<List<DownloadProgress>>("/api/v1/downloads");
                return result ?? new List<DownloadProgress>();
            }
            catch
            {
                return new List<DownloadProgress>();
            }
        }

        public async Task<bool> CancelDownloadAsync(string downloadId)
        {
            try
            {
                var resp = await _client.PostAsync($"/api/v1/downloads/{downloadId}/cancel", null);
                return resp.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> DeleteDownloadAsync(string downloadId)
        {
            try
            {
                var resp = await _client.DeleteAsync($"/api/v1/downloads/{downloadId}");
                return resp.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> ClearDownloadsAsync()
        {
            try
            {
                var resp = await _client.PostAsync("/api/v1/downloads/clear", null);
                return resp.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }
    }
}
