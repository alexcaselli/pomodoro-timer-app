using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PomodoroTimerApp.Helpers
{
    public class IOHelper
    {
        static String _filename = "debug_logs.txt";
        private String loglines;

        public IOHelper()
        {
            loglines = "";
        }

        async public static void CreateFile()
        {
            // Create sample file; replace if exists.
            Windows.Storage.StorageFolder storageFolder =
                Windows.Storage.ApplicationData.Current.LocalFolder;
            Windows.Storage.StorageFile sampleFile =
                await storageFolder.CreateFileAsync(_filename,
                    Windows.Storage.CreationCollisionOption.ReplaceExisting);
        }

        async public void WriteDebugLogs()
        {

            Windows.Storage.StorageFolder storageFolder =
                Windows.Storage.ApplicationData.Current.LocalFolder;
            Windows.Storage.StorageFile sampleFile =
                await storageFolder.GetFileAsync(_filename);

            await Windows.Storage.FileIO.AppendTextAsync(sampleFile, loglines);
            FlushLogLines();
        }

        public void PushLogLine(String log)
        {
            DateTime localDate = DateTime.Now;
            log = localDate.ToString("dd/MM/yyyy HH:mm:ss.fff") + " - " + log + "\n";
            Debug.WriteLine(log);

            loglines += log;
        }

        private void FlushLogLines()
        {
            loglines = "";
        }



    }
}
