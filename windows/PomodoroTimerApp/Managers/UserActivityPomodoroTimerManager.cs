using System;
using System.Timers;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using PomodoroTimerApp.Monitors;
using PomodoroTimerApp.PomodoroTimers;

namespace PomodoroTimerApp.Managers
{
    internal abstract class UserActivityPomodoroTimerManager : IDisposable
    {
        protected PomodoroTimer _currentTimer;

        /// <summary>
        /// Il monitor e' un campo, non una variabile locale del costruttore della sottoclasse.
        /// Prima veniva creato e subito abbandonato: il suo timer da 1 s era gia' partito nel
        /// costruttore base, e nessuno lo fermava piu'. Ogni cambio modalita', salvataggio
        /// impostazioni o transizione di ciclo ne lasciava indietro un altro, che continuava a
        /// notificare oggetti ormai morti.
        /// </summary>
        private readonly UserMonitor _monitor;
        private IActivityObserver _observer;

        private Timer _inactivityStopwatchTimer;
        private TimeSpan _inactivityDuration;
        private TextBlock _inactivityStopwatchTextBlock;
        protected DispatcherQueue _dispatcherQueue;
        private bool _disposed;

        public UserActivityPomodoroTimerManager(
            PomodoroTimer currentTimer,
            TextBlock inactivityStopwatchTextBlock,
            UserMonitor monitor)
        {
            _currentTimer = currentTimer;
            _monitor = monitor;

            _inactivityStopwatchTextBlock = inactivityStopwatchTextBlock;
            _inactivityStopwatchTimer = new Timer(1000);
            _inactivityStopwatchTimer.Elapsed += OnInactivityStopwatchTimerElapsed;
            _dispatcherQueue = DispatcherQueue.GetForCurrentThread();
        }

        /// <summary>
        /// Registra il manager sul proprio monitor. Chiamato dalle sottoclassi a fine costruzione,
        /// quando i loro campi sono inizializzati e possono ricevere notifiche in sicurezza.
        /// </summary>
        protected void ObserveMonitor(IActivityObserver observer)
        {
            _observer = observer;
            _monitor.AddObserver(observer);
        }

        public abstract void OnUserActive();
        public abstract void OnUserInactive();

        protected void startActivityStopwatch()
        {
            _inactivityDuration = TimeSpan.Zero;
            _inactivityStopwatchTimer.Start();
            _dispatcherQueue.TryEnqueue(() =>
            {
                _inactivityStopwatchTextBlock.Visibility = Visibility.Visible;
            });
        }

        /// <summary>
        /// Ferma il conteggio ma lascia deliberatamente la label a schermo: dopo una ripresa
        /// automatica si continua a vedere per quanto si e' stati via. Solo lo Stop la nasconde.
        /// </summary>
        public void stopActivityStopwatch()
        {
            _inactivityStopwatchTimer.Stop();
        }

        private void OnInactivityStopwatchTimerElapsed(object sender, object e)
        {
            _inactivityDuration = _inactivityDuration.Add(TimeSpan.FromSeconds(1));
            _dispatcherQueue.TryEnqueue(() =>
            {
                _inactivityStopwatchTextBlock.Text = _inactivityDuration.ToString(@"mm\:ss");
            });
        }

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }
            _disposed = true;

            if (_monitor != null)
            {
                if (_observer != null)
                {
                    _monitor.RemoveObserver(_observer);
                    _observer = null;
                }
                _monitor.Dispose();
            }

            if (_inactivityStopwatchTimer != null)
            {
                _inactivityStopwatchTimer.Stop();
                _inactivityStopwatchTimer.Elapsed -= OnInactivityStopwatchTimerElapsed;
                _inactivityStopwatchTimer.Dispose();
                _inactivityStopwatchTimer = null;
            }

            GC.SuppressFinalize(this);
        }
    }
}
