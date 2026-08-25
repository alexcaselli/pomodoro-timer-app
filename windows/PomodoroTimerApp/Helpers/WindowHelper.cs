using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using Windows.UI.Input.Preview.Injection;
using WinRT.Interop;

namespace PomodoroTimerApp.Helpers
{
    public class WindowHelper
    {
        private const uint SWP_NOMOVE = 0x0002;
        private const uint SWP_NOSIZE = 0x0001;
        private const uint SWP_SHOWWINDOW = 0x0040;
        private const uint SWP_NOACTIVATE = 0x0010;
        private const int SW_MINIMIZE = 6;
        private const int SW_RESTORE = 9;
        private static readonly IntPtr HWND_TOP = IntPtr.Zero;

        private IOHelper IOHelper = new IOHelper();


        [DllImport("user32.dll")]
        private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        [DllImport("user32.dll")]
        private static extern bool IsIconic(IntPtr hWnd);


        /// <summary>
        /// Restituisce l'istanza corrente di AppWindow.
        /// </summary>
        static public AppWindow GetAppWindow(Window window)
        {
            IntPtr hWnd = WindowNative.GetWindowHandle(window);
            WindowId wndId = Win32Interop.GetWindowIdFromWindow(hWnd);
            return AppWindow.GetFromWindowId(wndId);
        }

        public bool ShowWindowInForeground(Window window)
        {
            var hwnd = WindowNative.GetWindowHandle(window);

            IOHelper.PushLogLine($"DEBUG ------------- MainWindow is iconic: {IsIconic(hwnd)}");

            // Minimize the window if it is not already minimized
            if (!IsIconic(hwnd))
            {
                ShowWindow(hwnd, SW_MINIMIZE);
            }

            // Restore the window
            ShowWindow(hwnd, SW_RESTORE);

            // Bring the window to the foreground
            bool bVisible = IsWindowVisible(hwnd);
            IntPtr foregroundHwnd = GetForegroundWindow();

            IOHelper.PushLogLine($"DEBUG ------------- Window is visible: {bVisible}");
            IOHelper.PushLogLine($"DEBUG ------------- MainWindow is not the foreground window: {hwnd != foregroundHwnd}");
            

            bool bSetWindowPos = SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0,
                SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);

            IOHelper.PushLogLine($"DEBUG ------------- Window position has been set: {bSetWindowPos}");

            try
            {

                bool bForeground = SetForegroundWindow(hwnd);
                IOHelper.PushLogLine($"DEBUG ------------- SetForegroundWindow result: {bForeground}");
                return bForeground;
            }
            catch (Exception e)
            {
                IOHelper.PushLogLine($"DEBUG ------------- Exception: {e.Message}");
                IOHelper.WriteDebugLogs();
                return false;
            }
        }

        // Inside the LaunchAndBringToForegroundIfNeeded method
        public Window LaunchAndBringToForegroundIfNeeded(Window m_window)
        {
            bool bForeground = false;

            if (m_window == null)
            {
                IOHelper.PushLogLine("DEBUG ------------- Window is null");
                m_window = new MainWindow();
                m_window.Activate();

                // Additionally we show using our helper, since if activated via a toast, it doesn't
                // activate the window correctly
                //bForeground = ShowWindowInForeground(m_window);
            }
            else
            {
                IOHelper.PushLogLine("DEBUG ------------- Window is not null");

                var hwnd = WindowNative.GetWindowHandle(m_window);
                var foregroundHwnd = GetForegroundWindow();

                if (hwnd != foregroundHwnd)
                {
                    IOHelper.PushLogLine("DEBUG ------------- MainWindow is not the foreground window");
                    bForeground = ShowWindowInForeground(m_window);
                    IOHelper.PushLogLine($"DEBUG ------------- Window shown in foreground: {bForeground}");
                }
                else
                {
                    IOHelper.PushLogLine("DEBUG ------------- MainWindow is the foreground window");
                    bForeground = true;
                }
                
                if (!bForeground)
                {


                    //IOHelper.PushLogLine("DEBUG ------------- Old Window Closed.");


                    //var nhWnd = WindowNative.GetWindowHandle(new_m_window);
                    //bForeground = SetForegroundWindow(nhWnd);

                    //IOHelper.PushLogLine($"DEBUG ------------- New window shown in foreground: {bForeground}");

                    //m_window.Close();
                    //m_window = new_m_window;



                }
            }

            // log bForeground
            IOHelper.WriteDebugLogs();


            return m_window;
        }




        /// <summary>
        /// Mette la finestra in modalità fullscreen.
        /// </summary>
        public void EnterFullScreen(Window m_window)
        {
            AppWindow appWindow = GetAppWindow(m_window);
            appWindow.SetPresenter(AppWindowPresenterKind.FullScreen);
        }

        public void ExitFullScreen(Window m_window)
        {
            AppWindow appWindow = GetAppWindow(m_window);
            appWindow.SetPresenter(AppWindowPresenterKind.Overlapped);
        }



    }
}
