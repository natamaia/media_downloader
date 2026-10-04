using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media.Animation;

namespace MediaDownloaderUI.Components
{
    public class SmoothScrollViewer : ScrollViewer
    {
        private double _targetOffset;
        private bool _isAnimating;

        public static readonly DependencyProperty AnimatedVerticalOffsetProperty =
            DependencyProperty.Register(
                nameof(AnimatedVerticalOffset),
                typeof(double),
                typeof(SmoothScrollViewer),
                new PropertyMetadata(0.0, OnAnimatedVerticalOffsetChanged));

        public double AnimatedVerticalOffset
        {
            get => (double)GetValue(AnimatedVerticalOffsetProperty);
            set => SetValue(AnimatedVerticalOffsetProperty, value);
        }

        private static void OnAnimatedVerticalOffsetChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is SmoothScrollViewer scrollViewer)
            {
                scrollViewer.ScrollToVerticalOffset((double)e.NewValue);
            }
        }

        protected override void OnPreviewMouseWheel(MouseWheelEventArgs e)
        {
            if (ScrollableHeight <= 0)
            {
                base.OnPreviewMouseWheel(e);
                return;
            }

            e.Handled = true;

            if (!_isAnimating)
            {
                _targetOffset = VerticalOffset;
            }

            double delta = -e.Delta * 0.75;
            _targetOffset = Math.Max(0, Math.Min(ScrollableHeight, _targetOffset + delta));
            _isAnimating = true;

            var animation = new DoubleAnimation
            {
                From = VerticalOffset,
                To = _targetOffset,
                Duration = TimeSpan.FromMilliseconds(280),
                EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
            };

            animation.Completed += (s, ev) => _isAnimating = false;
            BeginAnimation(AnimatedVerticalOffsetProperty, animation);
        }
    }
}
