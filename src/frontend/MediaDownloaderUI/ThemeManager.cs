using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using Microsoft.Win32;

namespace MediaDownloaderUI
{
    public static class ThemeManager
    {
        public static bool IsLightTheme { get; private set; }

        [DllImport("dwmapi.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
        private static extern void DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int pvAttribute, int cbAttribute);

        private const int DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19;
        private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;

        public static void InitializeTheme(Window? mainWindow = null)
        {
            bool isSystemLight = DetectWindowsSystemLightTheme();
            ApplyTheme(isSystemLight, mainWindow);
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

        public static void ToggleTheme(Window? mainWindow = null)
        {
            ApplyTheme(!IsLightTheme, mainWindow);
        }

        public static void ApplyTheme(bool isLight, Window? mainWindow = null)
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

                if (mainWindow != null)
                {
                    UpdateNativeTitleBarTheme(mainWindow, isLight);
                }
                else if (Application.Current?.MainWindow != null)
                {
                    UpdateNativeTitleBarTheme(Application.Current.MainWindow, isLight);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to apply theme dict ({themeFile}): {ex.Message}");
            }
        }

        public static void UpdateNativeTitleBarTheme(Window window, bool isLight)
        {
            try
            {
                var hwnd = new WindowInteropHelper(window).Handle;
                if (hwnd == IntPtr.Zero) return;

                int useDarkMode = isLight ? 0 : 1;
                try
                {
                    DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, ref useDarkMode, sizeof(int));
                }
                catch
                {
                    DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1, ref useDarkMode, sizeof(int));
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error setting DWM title bar theme: {ex.Message}");
            }
        }
    }
}
