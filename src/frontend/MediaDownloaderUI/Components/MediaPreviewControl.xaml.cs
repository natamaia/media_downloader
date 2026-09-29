using System;
using System.Linq;
using System.Windows.Controls;
using System.Windows.Media.Imaging;

namespace MediaDownloaderUI.Components
{
    public partial class MediaPreviewControl : UserControl
    {
        public MediaPreviewControl()
        {
            InitializeComponent();
        }

        public void SetLoading(string message = "Analisando metadados do link...")
        {
            TxtPreviewTitle.Text = message;
            TxtProviderName.Text = "Analisando";
            TxtPreviewDetails.Text = "Aguarde enquanto os detalhes do link são extraídos...";
            ImgThumbnail.Source = null;
        }

        public void SetInfo(VideoInfo info)
        {
            TxtPreviewTitle.Text = info.Title;
            TxtProviderName.Text = info.Provider;
            TxtPreviewDetails.Text = $"Duração: {TimeSpan.FromSeconds(info.DurationSeconds):mm\\:ss} | Qualidades: {string.Join(", ", info.Qualities.Take(4))}";

            if (!string.IsNullOrEmpty(info.Thumbnail))
            {
                try
                {
                    ImgThumbnail.Source = new BitmapImage(new Uri(info.Thumbnail));
                }
                catch { }
            }
        }
    }
}
