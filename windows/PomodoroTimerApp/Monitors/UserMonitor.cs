using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using PomodoroTimerApp.Managers;

namespace PomodoroTimerApp.Monitors
{
    public abstract class UserMonitor
    {
        protected List<IActivityObserver> _observers = new List<IActivityObserver>();
        protected static readonly TimeSpan WorkInactivityThreshold = TimeSpan.FromSeconds(15);
        protected static readonly TimeSpan BreakActivityThreshold = TimeSpan.FromSeconds(10);

        protected System.Timers.Timer _activityCheckTimer;

        public UserMonitor()
        {

            // Controllo periodico dell'attività
            ScheduleActivityCheck();
        }


        protected void ScheduleActivityCheck()
        {
            _activityCheckTimer = new System.Timers.Timer(1000);
            _activityCheckTimer.Elapsed += (sender, e) => CheckActivity();
            _activityCheckTimer.AutoReset = true;
            _activityCheckTimer.Start();
        }

        public void AddObserver(IActivityObserver observer)
        {
            _observers.Add(observer);
        }

        public void RemoveObserver(IActivityObserver observer)
        {
            _observers.Remove(observer);
        }



        protected TimeSpan GetInactivityDuration()
        {
            var lastInputInfo = new LASTINPUTINFO
            {
                cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO))
            };

            if (!GetLastInputInfo(ref lastInputInfo))
            {
                return TimeSpan.Zero;
            }

            uint idleTimeMillis = (uint)Environment.TickCount - lastInputInfo.dwTime;
            return TimeSpan.FromMilliseconds(idleTimeMillis);
        }
        //public void UpdateActivity()
        //{
        //    TimeSpan _inactivityDuration = DateTime.Now - _lastActivityTime;
        //    bool wasInactive = _inactivityDuration > WorkInactivityThreshold;
        //    _lastActivityTime = DateTime.Now;

        //    if (wasInactive)
        //    {
        //        NotifyUserActive();
        //    }
        //}

        protected abstract void CheckActivity();



        protected void NotifyUserActive()
        {
            foreach (var observer in _observers)
            {
                observer.OnUserActive();
            }
        }

        protected void NotifyUserInactive()
        {
            foreach (var observer in _observers)
            {
                observer.OnUserInactive();
            }
        }

        #region Inattività tramite Win32 API

        [StructLayout(LayoutKind.Sequential)]
        protected struct LASTINPUTINFO
        {
            public uint cbSize;
            public uint dwTime;
        }

        [DllImport("user32.dll")]
        protected static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
        #endregion
    }
}

