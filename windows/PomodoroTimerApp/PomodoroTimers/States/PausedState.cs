using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Timers;

namespace PomodoroTimerApp.PomodoroTimers.States
{
    internal class PausedState : State
    {
        public PausedState(PomodoroTimer pomodoroTimer) : base(pomodoroTimer)
        {
        }

        public override bool ActivityPause()
        {
            return false;
        }
        public override bool ActivityResume()
        {
            _timer.Resume();
            _timer.ChangeState(new RunningState(_timer));
            return true;
        }

        public override void Completed()
        {
            // Do nothing
        }


        public override void StartPauseResume()
        {
            _timer.Resume();
            _timer.ChangeState(new RunningState(_timer));
        }

        public override void Stop()
        {
            _timer.Stop();
            _timer.ChangeState(new ReadyState(_timer));
        }
    }
}
