using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Timers;

namespace PomodoroTimerApp.PomodoroTimers.States
{
    abstract class State
    {
        protected PomodoroTimer _timer;

        public State(PomodoroTimer pomodoroTimer)
        {
            _timer = pomodoroTimer;
        }
        public abstract void StartPauseResume();
        public abstract void Stop();
        public abstract void Completed();
        public abstract bool ActivityPause();
        public abstract bool ActivityResume();
    }
}
