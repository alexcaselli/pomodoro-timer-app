using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Timers;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using PomodoroTimerApp.PomodoroTimers.States;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml.Controls;
using PomodoroTimerApp.Helpers;
using PomodoroTimerApp.PomodoroTimers.Events;
using Microsoft.UI.Xaml.Media.Imaging;

namespace PomodoroTimerApp.PomodoroTimers
{

    internal abstract class PomodoroTimer
    {
        protected State _state;
        protected double _timerDurationMinutes;
        protected Timer _timer;

        // Tempo
        protected DateTime _endTime;
        protected TimeSpan _remainingTime;

        // UI
        protected TextBlock _timerTextBlock;
        protected const string TimerFormat = @"mm\:ss";
        protected const string ZeroTime = "00:00";
        protected Button _primaryButton;
        protected Button _stopButton;
        protected const int ButtonImageContentSize = 32;
        protected Uri StopIcon = new Uri("ms-appx:///Assets/ControlIcons/stop_icon.png");
        protected Uri StopIconDisabled = new Uri("ms-appx:///Assets/ControlIcons/stop_icon__disabled.png");
        protected Uri PlayIcon = new Uri("ms-appx:///Assets/ControlIcons/play_icon.png");
        protected Uri PauseIcon = new Uri("ms-appx:///Assets/ControlIcons/pause_icon.png");
        protected DispatcherQueue _dispatcherQueue;

        // Events
        public event EventHandler<TimerCompletedEventArgs> TimerCompleted;

        //Debug
        private IOHelper _ioHelper;

        public PomodoroTimer(double timerDurationMinutes, TextBlock timerTextBlock, Button primaryButton, Button stopButton)
        {
            _timerDurationMinutes = timerDurationMinutes;
            _timerTextBlock = timerTextBlock;
            _primaryButton = primaryButton;
            _stopButton = stopButton;
            _dispatcherQueue = DispatcherQueue.GetForCurrentThread();
            _ioHelper = new IOHelper();

            // Timer (ogni 1 secondo)
            _timer = new Timer(1000);
            _timer.Elapsed += Elapsed;
            this.Init();
            this.ChangeState(new ReadyState(this));
        }
        public void ChangeState(State state)
        {
            _state = state;
        }

        public void Init()
        {
            _remainingTime = TimeSpan.FromMinutes(_timerDurationMinutes);
            _timerTextBlock.Text = _remainingTime.ToString(TimerFormat);
            SetPrimaryButtonImage(PlayIcon);
            _stopButton.IsEnabled = false;
            SetStopButtonImage(_stopButton.IsEnabled);

        }

        public void ClickStartPauseResume()
        {
            _state.StartPauseResume();
        }

        public bool ClickActivityPause()
        {
            return _state.ActivityPause();
        }

        public bool ClickActivityResume()
        {
            return _state.ActivityResume();
        }

        public void ClickStop(){
            _state.Stop();
        }

        public abstract void StartActivityTracker();
        //protected void OnTimerElapsed(object? sender, ElapsedEventArgs e)
        //{
        //    _state.Elapsed(sender, e);
        //}

        public void Pause()
        {
            _timer.Stop();
            _remainingTime = _endTime - DateTime.Now;
            _dispatcherQueue.TryEnqueue(() =>
            {
                SetPrimaryButtonImage(PlayIcon);
            });
        }
        public void Resume()
        {
            this.Start();
        }
        public void Stop()
        {
            _timer.Stop();
            this.Init();
        }
        public void Start()
        {
            _endTime = DateTime.Now.Add(_remainingTime);
            _timer.Start();
            _dispatcherQueue.TryEnqueue(() =>
            {
                SetPrimaryButtonImage(PauseIcon);
                _stopButton.IsEnabled = true;
                SetStopButtonImage(_stopButton.IsEnabled);

            });
            
            //StartActivityTracker();
        }
        public void Elapsed(object? sender, ElapsedEventArgs e)
        {
            _remainingTime = _endTime - DateTime.Now;
            if (_remainingTime <= TimeSpan.Zero)
            {
                _timer.Stop();
                _remainingTime = TimeSpan.Zero;
                _dispatcherQueue.TryEnqueue(() =>
                {
                    _timerTextBlock.Text = ZeroTime;
                    // Gestione della fine del timer e avvio del break
                    _state.Completed();
                });
                return;
            }

            // Aggiornamento dell’interfaccia
            _dispatcherQueue.TryEnqueue(() =>
                _timerTextBlock.Text = _remainingTime.ToString(TimerFormat));
        }

        public abstract void HandleTimerCompletion();

        // Metodo protetto per sollevare l'evento di completamento
        protected virtual void OnTimerCompleted(TimerCompletedEventArgs e)
        {
            TimerCompleted?.Invoke(this, e);
        }
        private void SetPrimaryButtonImage(Uri iconUri)
        {
            BitmapImage bitmapImage;


            bitmapImage = new BitmapImage(iconUri);

            _primaryButton.Content = new ImageIcon
            {
                Source = bitmapImage,
                Width = ButtonImageContentSize,
                Height = ButtonImageContentSize
            };
        }
        private void SetStopButtonImage(bool enabled)
        {
            BitmapImage bitmapImage;
            
            if (enabled)
            {
                bitmapImage = new BitmapImage(StopIcon);
            } else
            {
                bitmapImage = new BitmapImage(StopIconDisabled);
            }
            _stopButton.Content = new ImageIcon
            {
                Source = bitmapImage,
                Width = ButtonImageContentSize,
                Height = ButtonImageContentSize
            };
        }



    }
}
