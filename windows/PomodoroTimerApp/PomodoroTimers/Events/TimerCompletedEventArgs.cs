using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PomodoroTimerApp.PomodoroTimers.Events
{

    public class TimerCompletedEventArgs : EventArgs
    {
        public int CompletedCycles { get; set; }
        public string TimerType { get; set; }
    }
}
