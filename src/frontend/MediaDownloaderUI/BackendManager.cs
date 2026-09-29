using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;

namespace MediaDownloaderUI
{
    public static class BackendManager
    {
        private static Process? _backendProcess;

        public static async Task EnsureBackendRunningAsync()
        {
            using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(2) };
            try
            {
                var resp = await client.GetAsync("http://127.0.0.1:8000/health");
                if (resp.IsSuccessStatusCode)
                {
                    return; // Backend is already running
                }
            }
            catch
            {
                // Backend not running, proceed to auto-launch
            }

            try
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                DirectoryInfo? dir = new DirectoryInfo(baseDir);
                string projectRoot = string.Empty;

                while (dir != null)
                {
                    if (File.Exists(Path.Combine(dir.FullName, "requirements.txt")) &&
                        Directory.Exists(Path.Combine(dir.FullName, "src", "backend")))
                    {
                        projectRoot = dir.FullName;
                        break;
                    }
                    dir = dir.Parent;
                }

                if (string.IsNullOrEmpty(projectRoot))
                {
                    projectRoot = Path.GetFullPath(Path.Combine(baseDir, "..", "..", "..", "..", ".."));
                }

                var psi = new ProcessStartInfo
                {
                    FileName = "python",
                    Arguments = "-m src.backend.main",
                    WorkingDirectory = projectRoot,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };

                _backendProcess = Process.Start(psi);

                // Wait up to 5 seconds for backend server to become responsive
                for (int i = 0; i < 10; i++)
                {
                    await Task.Delay(500);
                    try
                    {
                        var resp = await client.GetAsync("http://127.0.0.1:8000/health");
                        if (resp.IsSuccessStatusCode) break;
                    }
                    catch { }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Falha ao iniciar o processo backend automaticamente: {ex.Message}");
            }
        }

        public static void StopBackend()
        {
            try
            {
                if (_backendProcess != null && !_backendProcess.HasExited)
                {
                    _backendProcess.Kill(true);
                    _backendProcess.Dispose();
                    _backendProcess = null;
                }
            }
            catch { }
        }
    }
}
