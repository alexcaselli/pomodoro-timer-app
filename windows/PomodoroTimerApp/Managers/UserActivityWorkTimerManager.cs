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
    internal class UserActivityWorkTimerManager : UserActivityPomodoroTimerManager, IActivityObserver
    {
        private bool _pausedDueToInactivity = false;

        public UserActivityWorkTimerManager(PomodoroTimer currentTimer, TextBlock inactivityStopwatchTextBlock)
            : base(currentTimer, inactivityStopwatchTextBlock)
        {

            // Registrazione come observer
            var monitor = new UserInactivityMonitor();
            monitor.AddObserver(this);
        }


        public override void OnUserActive()
        {
            // Se il timer era stato messo in pausa per inattività, riavvialo
            if (_pausedDueToInactivity)
            {
                _currentTimer.ClickActivityResume();
                _pausedDueToInactivity = false;
                stopActivityStopwatch();
            }
        }

        public override void OnUserInactive()
        {
            // Metti in pausa il timer e segna che è stato fatto per inattività
            bool paused = _currentTimer.ClickActivityPause();
            _pausedDueToInactivity = paused || _pausedDueToInactivity;
            if (paused)
            {
                startActivityStopwatch();
            }
        }
    }
}
