using System;
using System.Diagnostics;
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
            string themeFile = isLight ? "Themes/LightTheme.xaml" : "Themes/DarkTheme.xaml";

            try
            {
                var newThemeDict = new ResourceDictionary { Source = new Uri(themeFile, UriKind.Relative) };
                
                if (Application.Current != null)
                {
                    var appDicts = Application.Current.Resources.MergedDictionaries;
                    appDicts.Clear();
                    appDicts.Add(newThemeDict);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to apply theme dict ({themeFile}): {ex.Message}");
            }
        }
    }
}
