using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.UI.Xaml.Controls;
using PomodoroTimerApp.Monitors;
using PomodoroTimerApp.PomodoroTimers;

namespace PomodoroTimerApp.Managers
{
    internal class UserActivityBreakTimerManager : UserActivityPomodoroTimerManager, IActivityObserver
    {
        private bool _pausedDueToActivity = false;

        public UserActivityBreakTimerManager(PomodoroTimer currentTimer, TextBlock inactivityStopwatchTextBlock)
            : base(currentTimer, inactivityStopwatchTextBlock)
        {

            // Registrazione come observer
            var monitor = new UserActivityMonitor();
            monitor.AddObserver(this);
        }

        public override void OnUserActive()
        {
            // Metti in pausa il timer e segna che è stato fatto per inattività
            bool paused = _currentTimer.ClickActivityPause();
            _pausedDueToActivity = paused || _pausedDueToActivity;
            if (paused)
            {
                startActivityStopwatch();
            }

        }

        public override void OnUserInactive()
        {
            // Se il timer era stato messo in pausa per attività, riavvialo
            if (_pausedDueToActivity)
            {
                _currentTimer.ClickActivityResume();
                _pausedDueToActivity = false;
                stopActivityStopwatch();
            }

        }
    }
}
