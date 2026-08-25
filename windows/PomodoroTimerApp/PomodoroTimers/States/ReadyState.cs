using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Timers;

namespace PomodoroTimerApp.PomodoroTimers.States
{
    internal class ReadyState : State
    {
        public ReadyState(PomodoroTimer pomodoroTimer) : base(pomodoroTimer)
        {
        }

        public override void Completed()
        {
            // Do nothing
        }
        public override bool ActivityPause()
        {
            return false;
        }
        public override bool ActivityResume()
        {
            return false;
        }

        public override void StartPauseResume()
        {
            _timer.Start();
            _timer.ChangeState(new RunningState(_timer));
        }
        public override void Stop()
        {
            // Do nothing
        }
    }
}