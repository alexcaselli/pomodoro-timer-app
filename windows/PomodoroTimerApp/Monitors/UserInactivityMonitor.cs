using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PomodoroTimerApp.Monitors
{
    internal class UserInactivityMonitor : UserMonitor
    {

        protected override void CheckActivity()
        {

            TimeSpan _inactivityDuration = GetInactivityDuration();


            if (_inactivityDuration > WorkInactivityThreshold)
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
