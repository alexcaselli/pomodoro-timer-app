using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PomodoroTimerApp.Managers
{
    public interface IActivityObserver
    {
        void OnUserActive();
        void OnUserInactive();
    }
}
