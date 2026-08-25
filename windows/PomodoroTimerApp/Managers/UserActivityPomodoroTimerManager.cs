using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using PomodoroTimerApp.PomodoroTimers;
using System.Timers;
using Microsoft.UI.Dispatching;

namespace PomodoroTimerApp.Managers
{
    internal abstract class UserActivityPomodoroTimerManager
    {
        protected PomodoroTimer _currentTimer;


        private Timer _inactivityStopwatchTimer;
        private TimeSpan _inactivityDuration;
        private TextBlock _inactivityStopwatchTextBlock;
        protected DispatcherQueue _dispatcherQueue;

        public UserActivityPomodoroTimerManager(PomodoroTimer currentTimer, TextBlock inactivityStopwatchTextBlock)
        {
            _currentTimer = currentTimer;

            _inactivityStopwatchTextBlock = inactivityStopwatchTextBlock;
            _inactivityStopwatchTimer = new Timer(1000);
            _inactivityStopwatchTimer.Elapsed += OnInactivityStopwatchTimerElapsed;
            _dispatcherQueue = DispatcherQueue.GetForCurrentThread();
        }
        public abstract void OnUserActive();
        public abstract void OnUserInactive();

        protected void startActivityStopwatch()
        {
            _inactivityDuration = TimeSpan.Zero;
            _inactivityStopwatchTimer.Start();
            _dispatcherQueue.TryEnqueue(() =>
            {
                _inactivityStopwatchTextBlock.Visibility = Visibility.Visible;
            });
            
            
        }

        public void stopActivityStopwatch()
        {
            _inactivityStopwatchTimer.Stop();

        }
        private void OnInactivityStopwatchTimerElapsed(object sender, object e)
        {
            _inactivityDuration = _inactivityDuration.Add(TimeSpan.FromSeconds(1));
            _dispatcherQueue.TryEnqueue(() =>
            {
                _inactivityStopwatchTextBlock.Text = _inactivityDuration.ToString(@"mm\:ss");
            });
            
        }
    }
}
