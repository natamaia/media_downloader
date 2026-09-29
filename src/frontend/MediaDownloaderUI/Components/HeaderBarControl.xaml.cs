using System.Windows.Controls;
using System.Windows.Media;

namespace MediaDownloaderUI.Components
{
    public partial class HeaderBarControl : UserControl
    {
        public HeaderBarControl()
        {
            InitializeComponent();
        }

        public void SetPaths(string musicPath, string videoPath)
        {
            TxtMusicPath.Text = musicPath;
            TxtVideoPath.Text = videoPath;
        }

        public void SetStatus(bool isOnline)
        {
            if (isOnline)
            {
                BadgeBackendStatus.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#064E3B"));
                DotStatus.Fill = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#10B981"));
                TxtStatusBackend.Text = "API Interna On-line";
                TxtStatusBackend.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#A7F3D0"));
            }
            else
            {
                BadgeBackendStatus.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#7F1D1D"));
                DotStatus.Fill = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#EF4444"));
                TxtStatusBackend.Text = "API Desconectada";
                TxtStatusBackend.Foreground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#FECACA"));
            }
        }
    }
}
