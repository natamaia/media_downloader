using System;
using System.Diagnostics;
using System.Linq;
using System.Windows;
using Microsoft.Win32;

namespace MediaDownloaderUI
{
    public static class ThemeManager
    {
        public static bool IsLightTheme { get; private set; }

        public static void InitializeTheme()
        {
            bool isSystemLight = DetectWindowsSystemLightTheme();
            ApplyTheme(isSystemLight);
        }

        public static bool DetectWindowsSystemLightTheme()
        {
            try
            {
                using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
                if (key != null)
                {
                    object? registryValue = key.GetValue("AppsUseLightTheme");
                    if (registryValue is int val)
                    {
                        return val == 1; // 1 = Light Mode, 0 = Dark Mode
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error reading Windows Theme Registry: {ex.Message}");
            }
            return false; // Default to Dark Mode
        }

        public static void ToggleTheme()
        {
            ApplyTheme(!IsLightTheme);
        }

        public static void ApplyTheme(bool isLight)
        {
            IsLightTheme = isLight;
            string themeUri = isLight
                ? "pack://application:,,,/MediaDownloaderUI;component/Themes/LightTheme.xaml"
                : "pack://application:,,,/MediaDownloaderUI;component/Themes/DarkTheme.xaml";

            try
            {
                var newThemeDict = new ResourceDictionary { Source = new Uri(themeUri, UriKind.Absolute) };

                var appDicts = Application.Current.Resources.MergedDictionaries;
                var existingTheme = appDicts.FirstOrDefault(d => d.Source != null && (d.Source.OriginalString.Contains("DarkTheme") || d.Source.OriginalString.Contains("LightTheme")));

                if (existingTheme != null)
                {
                    appDicts.Remove(existingTheme);
                }

                appDicts.Add(newThemeDict);
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to apply theme dict ({themeUri}): {ex.Message}");
            }
        }
    }
}
