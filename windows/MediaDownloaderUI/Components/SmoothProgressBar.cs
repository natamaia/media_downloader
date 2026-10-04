using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Animation;

namespace MediaDownloaderUI.Components
{
    public class SmoothProgressBar : ProgressBar
    {
        public static readonly DependencyProperty SmoothValueProperty =
            DependencyProperty.Register(
                nameof(SmoothValue),
                typeof(double),
                typeof(SmoothProgressBar),
                new PropertyMetadata(0.0, OnSmoothValueChanged));

        public double SmoothValue
        {
            get => (double)GetValue(SmoothValueProperty);
            set => SetValue(SmoothValueProperty, value);
        }

        private static void OnSmoothValueChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is SmoothProgressBar bar)
            {
                double targetValue = (double)e.NewValue;
                bar.AnimateTo(targetValue);
            }
        }

        private void AnimateTo(double targetValue)
        {
            var animation = new DoubleAnimation
            {
                To = targetValue,
                Duration = TimeSpan.FromMilliseconds(350),
                EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
            };
            BeginAnimation(ValueProperty, animation);
        }
    }
}
