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

        public static Task EnsureBackendRunningAsync()
        {
            return Task.Run(async () =>
            {
                using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(2) };
                try
                {
                    var resp = await client.GetAsync("http://127.0.0.1:8000/health");
                    if (resp.IsSuccessStatusCode)
                    {
                        return; // Backend is already active
                    }
                }
                catch
                {
                    // Proceed to launch backend process
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

                    // Try python or py executable
                    string pythonCmd = "python";

                    var psi = new ProcessStartInfo
                    {
                        FileName = pythonCmd,
                        Arguments = "-m src.backend.main",
                        WorkingDirectory = projectRoot,
                        CreateNoWindow = true,
                        UseShellExecute = false
                    };

                    _backendProcess = Process.Start(psi);

                    // Poll up to 6 seconds for backend startup
                    for (int i = 0; i < 12; i++)
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
                    Debug.WriteLine($"Backend auto-start warning: {ex.Message}");
                }
            });
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
