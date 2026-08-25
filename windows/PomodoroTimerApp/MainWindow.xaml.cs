using System;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Timers;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Navigation;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.Graphics;

// Namespace per la gestione del fullscreen
using WinRT.Interop;
using static Microsoft.UI.Win32Interop;
using Microsoft.UI.Windowing;

// Per le notifiche toast
using Microsoft.Toolkit.Uwp.Notifications; // Richiede il pacchetto NuGet Microsoft.Toolkit.Uwp.Notifications
using Windows.UI.Notifications;

using PomodoroTimerApp.Helpers;
using Microsoft.Windows.AppNotifications.Builder;
using PomodoroTimerApp.PomodoroTimers;
using PomodoroTimerApp.PomodoroTimers.Events;
using System.ComponentModel.Design;
using PomodoroTimerApp.Managers;
using System.IO;
using Microsoft.UI.Composition.SystemBackdrops;
using Windows.ApplicationModel.VoiceCommands;
using Windows.Storage;


namespace PomodoroTimerApp
{
    /// <summary>
    /// A window that can be used on its own or navigated within a Frame.
    /// </summary>
    public sealed partial class MainWindow : Window
    {
        #region Fields and Constants

        // Configuration constants
        private const double Fallback_WorkingTimerDurationMinutes = 25;
        private const double Fallback_BreakTimerDurationMinutes = 3;

        private const string WorkingTimerDurationMinutes_CompositeKey = "WorkingTimerDurationMinutes";
        private const string BreakTimerDurationMinutes_CompositeKey = "BreakTimerDurationMinutes";
        private const string Timers_CompositeKey = "TimersDurationMinutes";

        private double WorkingTimerDurationMinutes;
        private double BreakTimerDurationMinutes;
        private SizeInt32 WindowSize = new SizeInt32(720, 560);

        private WindowHelper _windowHelper;
        private ApplicationDataContainer _localConfig;

        private PomodoroTimer _currentTimer;
        private UserActivityPomodoroTimerManager _userActivityPomodoroTimerManager;

        #endregion

        public MainWindow()
        {
            this.InitializeComponent();
            _localConfig = ApplicationData.Current.LocalSettings;
            ReadAndSetLocalConfigs();

            InitializeWorkTimer();
            _windowHelper = new WindowHelper();
            AppWindow.SetIcon(Path.Combine(AppContext.BaseDirectory, "Assets\\PomodoroTimerAppIcon.ico"));
            AppWindow.Resize(WindowSize);
        }

        /// <summary>
        /// Reads and sets local configurations for timer durations.
        /// </summary>
        private void ReadAndSetLocalConfigs()
        {
            try
            {
                ApplicationDataCompositeValue composite = (ApplicationDataCompositeValue)_localConfig.Values[Timers_CompositeKey];
                if (composite != null)
                {
                    this.WorkingTimerDurationMinutes = (double)composite[WorkingTimerDurationMinutes_CompositeKey];
                    this.BreakTimerDurationMinutes = (double)composite[BreakTimerDurationMinutes_CompositeKey];
                }
                else
                {
                    this.WorkingTimerDurationMinutes = Fallback_WorkingTimerDurationMinutes;
                    this.BreakTimerDurationMinutes = Fallback_BreakTimerDurationMinutes;
                }
            }
            catch (Exception ex)
            {
                // Handle the exception as needed, for example, log the error or show a message to the user
                debugTextBlock.Text = "Error reading timer configurations: " + ex.Message;
            }
        }

        /// <summary>
        /// Writes and sets local configurations for timer durations.
        /// </summary>
        private void WriteAndSetLocalConfigs(double New_WorkingTimerDurationMinutes, double New_BreakTimerDurationMinutes)
        {
            try
            {
                ApplicationDataCompositeValue composite = new ApplicationDataCompositeValue();

                composite[WorkingTimerDurationMinutes_CompositeKey] = New_WorkingTimerDurationMinutes;
                composite[BreakTimerDurationMinutes_CompositeKey] = New_BreakTimerDurationMinutes;
                _localConfig.Values[Timers_CompositeKey] = composite;
            }
            catch (Exception ex)
            {
                // Handle the exception as needed, for example, log the error or show a message to the user
                debugTextBlock.Text = "Error saving timer configurations: " + ex.Message;
            }
        }

        /// <summary>
        /// Initializes the work timer.
        /// </summary>
        private void InitializeWorkTimer()
        {
            _currentTimer = new WorkTimer(WorkingTimerDurationMinutes, timerTextBlock, primaryButton, stopButton);
            _userActivityPomodoroTimerManager = new UserActivityWorkTimerManager(_currentTimer, inactivityStopwatchTextBlock);
            _currentTimer.TimerCompleted += OnTimerElapsed;
        }

        /// <summary>
        /// Initializes the break timer.
        /// </summary>
        private void InitializeBreakTimer()
        {
            _currentTimer = new BreakTimer(BreakTimerDurationMinutes, timerTextBlock, primaryButton, stopButton);
            _userActivityPomodoroTimerManager = new UserActivityBreakTimerManager(_currentTimer, inactivityStopwatchTextBlock);
            _currentTimer.TimerCompleted += OnTimerElapsed;
        }

        /// <summary>
        /// Stops and resets the current timer.
        /// </summary>
        private void StopAndResetTimer()
        {
            _currentTimer.ClickStop();
            _userActivityPomodoroTimerManager.stopActivityStopwatch();
            inactivityStopwatchTextBlock.Visibility = Visibility.Collapsed;
        }

        /// <summary>
        /// Handles the primary button click event to start, pause, or resume the timer.
        /// </summary>
        private void PrimaryButton_Click(object sender, RoutedEventArgs e)
        {
            _currentTimer.ClickStartPauseResume();
        }

        /// <summary>
        /// Handles the stop button click event to stop the timer and exit fullscreen mode.
        /// </summary>
        private void StopButton_Click(object sender, RoutedEventArgs e)
        {
            _currentTimer.ClickStop();
            inactivityStopwatchTextBlock.Visibility = Visibility.Collapsed;
            _windowHelper.ExitFullScreen(this);
        }

        /// <summary>
        /// Handles the settings button click event to open the settings dialog.
        /// </summary>
        private async void SettingsButton_Click(object sender, RoutedEventArgs e)
        {
            settingsContentDialog.XamlRoot = MainPage.XamlRoot;

            ContentDialogResult result = await settingsContentDialog.ShowAsync();
            if (result == ContentDialogResult.Primary)
            {
                StopAndResetTimer();
                this.WorkingTimerDurationMinutes = NumberBoxWorkTimerDuration.Value;
                this.BreakTimerDurationMinutes = NumberBoxBreakTimerDuration.Value;

                WriteAndSetLocalConfigs(NumberBoxWorkTimerDuration.Value, NumberBoxBreakTimerDuration.Value);

                if (_currentTimer is WorkTimer)
                {
                    InitializeWorkTimer();
                }
                else if (_currentTimer is BreakTimer)
                {
                    InitializeBreakTimer();
                }
            }
        }

        /// <summary>
        /// Handles the settings dialog opened event to set the initial values.
        /// </summary>
        private void SettingsContentDialog_Opened(ContentDialog sender, ContentDialogOpenedEventArgs args)
        {
            NumberBoxWorkTimerDuration.Value = WorkingTimerDurationMinutes;
            NumberBoxBreakTimerDuration.Value = BreakTimerDurationMinutes;
        }

        /// <summary>
        /// Handles the selection change event of the timer selector bar.
        /// </summary>
        private void SelectorBarTimer_SelectionChanged(SelectorBar sender, SelectorBarSelectionChangedEventArgs args)
        {
            SelectorBarItem selectedItem = sender.SelectedItem;
            int currentSelectedIndex = sender.Items.IndexOf(selectedItem);

            switch (currentSelectedIndex)
            {
                case 0:
                    if (!(_currentTimer is WorkTimer))
                    {
                        StopAndResetTimer();
                        InitializeWorkTimer();
                    }
                    break;
                case 1:
                    if (!(_currentTimer is BreakTimer))
                    {
                        StopAndResetTimer();
                        InitializeBreakTimer();
                    }
                    break;
                default:
                    break;
            }
        }

        /// <summary>
        /// Handles the timer elapsed event to switch between work and break timers.
        /// </summary>
        private void OnTimerElapsed(object? sender, TimerCompletedEventArgs e)
        {
            if (e.TimerType == "Work")
            {
                ShowToastNotification();

                Window _mainWindow = _windowHelper.LaunchAndBringToForegroundIfNeeded(this);
                _windowHelper.EnterFullScreen(_mainWindow);

                SelectorBarItemBreakTimer.IsSelected = true;

                StartPomodoroTimer("Break");
            }
            else if (e.TimerType == "Break")
            {
                _windowHelper.ExitFullScreen(this);

                SelectorBarItemWorkTimer.IsSelected = true;

                StartPomodoroTimer("Work");
            }
        }

        /// <summary>
        /// Starts the Pomodoro timer based on the specified type.
        /// </summary>
        private void StartPomodoroTimer(String TimerType)
        {
            if (_currentTimer != null)
            {
                _currentTimer.TimerCompleted -= OnTimerElapsed;
            }

            switch (TimerType)
            {
                case "Work":
                    _currentTimer = new WorkTimer(WorkingTimerDurationMinutes, timerTextBlock, primaryButton, stopButton);
                    _userActivityPomodoroTimerManager = new UserActivityWorkTimerManager(_currentTimer, inactivityStopwatchTextBlock);
                    break;
                case "Break":
                    _currentTimer = new BreakTimer(BreakTimerDurationMinutes, timerTextBlock, primaryButton, stopButton);
                    _userActivityPomodoroTimerManager = new UserActivityBreakTimerManager(_currentTimer, inactivityStopwatchTextBlock);
                    break;
                default:
                    throw new ArgumentException("Invalid timer type");
            }

            _currentTimer.TimerCompleted += OnTimerElapsed;
            _currentTimer.ClickStartPauseResume();
        }

        #region Toast Notifications

        /// <summary>
        /// Shows a toast notification to the user.
        /// </summary>
        private void ShowToastNotification()
        {
            try
            {
                var content = new ToastContentBuilder()
                    .AddArgument("action", "openWindow")
                    .SetToastScenario(ToastScenario.Reminder)
                    .AddText("Pomodoro Timer")
                    .AddText("Il timer di lavoro è scaduto! Clicca qui per avviare il break.")
                    .GetToastContent();

                var toast = new ToastNotification(content.GetXml());
                ToastNotificationManager.CreateToastNotifier().Show(toast);
            }
            catch (Exception ex)
            {
                debugTextBlock.Text = debugTextBlock.Text + ", Toast Error: " + ex.Message;
            }
        }

        #endregion
    }
}
