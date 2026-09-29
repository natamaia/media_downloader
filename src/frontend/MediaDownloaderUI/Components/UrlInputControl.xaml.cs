using System;
using System.Windows;
using System.Windows.Controls;

namespace MediaDownloaderUI.Components
{
    public partial class UrlInputControl : UserControl
    {
        public event EventHandler<string>? AnalyzeRequested;

        public UrlInputControl()
        {
            InitializeComponent();
        }

        public string GetUrl() => TxtUrl.Text.Trim();

        private void TxtUrl_GotFocus(object sender, RoutedEventArgs e)
        {
            if (TxtUrl.Text.StartsWith("Cole aqui"))
            {
                TxtUrl.Text = string.Empty;
            }
        }

        private void BtnAnalyze_Click(object sender, RoutedEventArgs e)
        {
            string url = GetUrl();
            if (string.IsNullOrEmpty(url) || url.StartsWith("Cole aqui"))
            {
                MessageBox.Show("Por favor, cole um link válido para analisar.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            AnalyzeRequested?.Invoke(this, url);
        }
    }
}
