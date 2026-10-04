using System;
using System.Windows;

namespace MediaDownloaderUI
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);
            try
            {
                ThemeManager.InitializeTheme();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Startup Theme Init Error: {ex.Message}");
            }
        }
    }
}
