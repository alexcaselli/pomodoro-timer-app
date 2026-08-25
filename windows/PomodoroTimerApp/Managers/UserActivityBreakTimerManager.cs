using PomodoroTimerApp.Monitors;
using PomodoroTimerApp.PomodoroTimers;
using Microsoft.UI.Xaml.Controls;

namespace PomodoroTimerApp.Managers
{
    internal class UserActivityBreakTimerManager : UserActivityPomodoroTimerManager, IActivityObserver
    {
        private bool _pausedDueToActivity = false;

        public UserActivityBreakTimerManager(PomodoroTimer currentTimer, TextBlock inactivityStopwatchTextBlock)
            : base(currentTimer, inactivityStopwatchTextBlock, new UserActivityMonitor())
        {
            ObserveMonitor(this);
        }

        // Polarita' invertita rispetto al work: durante la pausa, usare la macchina la sospende,
        // e lasciarla stare la fa ripartire.
        public override void OnUserActive()
        {
            bool paused = _currentTimer.ClickActivityPause();
            _pausedDueToActivity = paused || _pausedDueToActivity;
            if (paused)
            {
                startActivityStopwatch();
            }
        }

        public override void OnUserInactive()
        {
            if (_pausedDueToActivity)
            {
                _currentTimer.ClickActivityResume();
                _pausedDueToActivity = false;
                stopActivityStopwatch();
            }
        }
    }
}
