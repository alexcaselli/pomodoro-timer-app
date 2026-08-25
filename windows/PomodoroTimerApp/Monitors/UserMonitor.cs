using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using PomodoroTimerApp.Managers;

namespace PomodoroTimerApp.Monitors
{
    public abstract class UserMonitor : IDisposable
    {
        protected List<IActivityObserver> _observers = new List<IActivityObserver>();
        protected static readonly TimeSpan WorkInactivityThreshold = TimeSpan.FromSeconds(15);
        protected static readonly TimeSpan BreakActivityThreshold = TimeSpan.FromSeconds(10);

        protected System.Timers.Timer _activityCheckTimer;
        private bool _disposed;

        public UserMonitor()
        {
            // Controllo periodico dell'attivita'
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

        /// <summary>
        /// Ferma il polling. Va chiamato quando il monitor non serve piu':
        /// senza questo il timer da 1 s continua a girare per tutta la vita del processo.
        /// </summary>
        public void Stop()
        {
            if (_activityCheckTimer != null)
            {
                _activityCheckTimer.Stop();
            }
        }

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }
            _disposed = true;

            if (_activityCheckTimer != null)
            {
                _activityCheckTimer.Stop();
                _activityCheckTimer.Dispose();
                _activityCheckTimer = null;
            }
            _observers.Clear();
            GC.SuppressFinalize(this);
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

        protected abstract void CheckActivity();

        protected void NotifyUserActive()
        {
            // Copia difensiva: un observer puo' modificare la lista mentre viene notificato.
            foreach (var observer in _observers.ToArray())
            {
                observer.OnUserActive();
            }
        }

        protected void NotifyUserInactive()
        {
            foreach (var observer in _observers.ToArray())
            {
                observer.OnUserInactive();
            }
        }

        #region Inattivita' tramite Win32 API

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
