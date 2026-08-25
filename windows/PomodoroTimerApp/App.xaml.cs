using System;
using Microsoft.UI.Xaml;
using Windows.ApplicationModel.Activation;
using WinRT.Interop;
using System.Runtime.InteropServices;
using Microsoft.Toolkit.Uwp.Notifications;
using Windows.Foundation.Collections;
using System.Windows;
using Windows.UI.Core;
using Microsoft.Windows.AppLifecycle;
using Microsoft.Windows.AppNotifications;
using Microsoft.UI.Dispatching;
using System.Diagnostics;
using PomodoroTimerApp.Helpers;
using Windows.Storage;



// To learn more about WinUI, the WinUI project structure,
// and more about our project templates, see: http://aka.ms/winui-project-info.

namespace PomodoroTimerApp
{
    /// <summary>
    /// Provides application-specific behavior to supplement the default Application class.
    /// </summary>
    public partial class App : Application
    {
        /// <summary>
        /// Riferimento statico all'istanza principale di MainWindow.
        /// </summary>
        public static Window? m_window;
        public static DispatcherQueue DispatcherQueue { get; private set; }
        private static WindowHelper? windowHelper;
        /// <summary>
        /// Initializes the singleton application object.  This is the first line of authored code
        /// executed, and as such is the logical equivalent of main() or WinMain().
        /// </summary>
        public App()
        {
            this.InitializeComponent();
            IOHelper.CreateFile();

        }




        /// <summary>
        /// Invoked when the application is launched.
        /// </summary>
        /// <param name="args">Details about the launch request and process.</param>
        protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
        {

            windowHelper = new WindowHelper();
            Debug.WriteLine($"New windowHelper created");
            // Get the app-level dispatcher
            DispatcherQueue = global::Microsoft.UI.Dispatching.DispatcherQueue.GetForCurrentThread();

            // Register for toast activation. Requires Microsoft.Toolkit.Uwp.Notifications NuGet package version 7.0 or greater
            ToastNotificationManagerCompat.OnActivated += ToastNotificationManagerCompat_OnActivated;
            Debug.WriteLine($"Registered ToastNotificationManagerCompat for toast activation.");

            // If we weren't launched by an app, launch our window like normal.
            // Otherwise if launched by a toast, our OnActivated callback will be triggered
            if (!ToastNotificationManagerCompat.WasCurrentProcessToastActivated())
            {
                Debug.WriteLine("DEBUG ------------- Was NOT Current Process Toast Activated.");
                m_window = windowHelper.LaunchAndBringToForegroundIfNeeded(m_window);
            }

            

        }



        private void ToastNotificationManagerCompat_OnActivated(ToastNotificationActivatedEventArgsCompat e)
        {
            var dispatcherQueue = m_window?.DispatcherQueue ?? App.DispatcherQueue;

            Debug.WriteLine("DEBUG ------------- Toast Notification Callback Received.");

            dispatcherQueue.TryEnqueue(delegate
            {
                var args = ToastArguments.Parse(e.Argument);

                switch (args["action"])
                {
                    case "openWindow":
                        m_window = windowHelper.LaunchAndBringToForegroundIfNeeded(m_window);
                        windowHelper.EnterFullScreen(m_window);
                        break;
                }
            });
        }





    }
}