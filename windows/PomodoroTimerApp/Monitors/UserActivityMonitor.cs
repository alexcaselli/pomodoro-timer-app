using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace PomodoroTimerApp.Monitors
{
    public class UserActivityMonitor : UserMonitor
    {
        protected override void CheckActivity()
        {

            TimeSpan _inactivityDuration = GetInactivityDuration();

            //Debug.WriteLine("Inactivity duration: " + _inactivityDuration);

            if (_inactivityDuration > BreakActivityThreshold)
            {
                NotifyUserInactive();
            }
            else
            {
                NotifyUserActive();
            }
        }
    }
}
