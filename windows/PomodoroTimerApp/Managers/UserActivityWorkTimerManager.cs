using PomodoroTimerApp.Monitors;
using PomodoroTimerApp.PomodoroTimers;
using Microsoft.UI.Xaml.Controls;

namespace PomodoroTimerApp.Managers
{
    internal class UserActivityWorkTimerManager : UserActivityPomodoroTimerManager, IActivityObserver
    {
        private bool _pausedDueToInactivity = false;

        public UserActivityWorkTimerManager(PomodoroTimer currentTimer, TextBlock inactivityStopwatchTextBlock)
            : base(currentTimer, inactivityStopwatchTextBlock, new UserInactivityMonitor())
        {
            ObserveMonitor(this);
        }

        public override void OnUserActive()
        {
            // Se il timer era stato messo in pausa per inattivita', riavvialo.
            // Il flag impedisce di calpestare una pausa decisa dall'utente.
            if (_pausedDueToInactivity)
            {
                _currentTimer.ClickActivityResume();
                _pausedDueToInactivity = false;
                stopActivityStopwatch();
            }
        }

        public override void OnUserInactive()
        {
            // Metti in pausa il timer e segna che e' stato fatto per inattivita'
            bool paused = _currentTimer.ClickActivityPause();
            _pausedDueToInactivity = paused || _pausedDueToInactivity;
            if (paused)
            {
                startActivityStopwatch();
            }
        }
    }
}
