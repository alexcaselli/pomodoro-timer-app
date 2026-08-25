using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using PomodoroTimerApp.PomodoroTimers.Events;

namespace PomodoroTimerApp.PomodoroTimers
{
    internal class BreakTimer : PomodoroTimer
    {
        public BreakTimer(double timerDurationMinutes, TextBlock timerTextBlock, Button primaryButton, Button stopButton) : base(timerDurationMinutes, timerTextBlock, primaryButton, stopButton)
        {
        }


        public override void HandleTimerCompletion()
        {
            // Invoke the TimerCompleted event from the base class
            var args = new TimerCompletedEventArgs { TimerType = "Break" };
            OnTimerCompleted(args);
        }

        public override void StartActivityTracker()
        {
            throw new NotImplementedException();
        }

    }
}
