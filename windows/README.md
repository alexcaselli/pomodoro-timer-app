# Pomodoro Timer — Windows

WinUI 3 / .NET 8 implementation. See the [root README](../README.md) for what the app does and
how it compares with the macOS version.

## Requirements

* Visual Studio 2022 (17.12 or later) with the **Windows App SDK** workload
* .NET 8 SDK
* Windows 10 1809 (build 17763) or later

## Build

Open `PomodoroTimerApp.sln` and build. Two launch profiles are configured:

* **MsixPackage** — runs packaged, which is required for toast notifications and for
  `ApplicationData.LocalSettings` to persist.
* **Project** — runs unpackaged, useful for quick iteration.

Target platforms: `x86`, `x64`, `ARM64`.

## Dependencies

| Package | Version |
|---|---|
| `Microsoft.WindowsAppSDK` | 1.6.250108002 |
| `Microsoft.Windows.SDK.BuildTools` | 10.0.26100.1742 |
| `Microsoft.Toolkit.Uwp.Notifications` | 7.1.3 |

## Layout

```
PomodoroTimerApp/
├── MainWindow.xaml(.cs)      the only window; owns the work/break cycle
├── PomodoroTimers/           the countdown and its State pattern
│   └── States/               Ready / Running / Paused
├── Monitors/                 idle polling via Win32 GetLastInputInfo
├── Managers/                 auto-pause policy, opposite for work and break
├── Helpers/                  window foregrounding, full screen, debug log
└── Assets/                   icons and MSIX tile artwork
```

## Packaging

MSIX packaging is enabled in the `.csproj`. Note that it currently hardcodes an
`AppxPackageDir` absolute path and a signing-certificate thumbprint from the original author's
machine; both need changing before packaging elsewhere.

## Known issues

Several defects here are fixed in the macOS implementation and are worth porting back:

1. **Leaked activity monitors.** Each manager constructs a monitor into a local variable that is
   never stored or stopped, while its 1 s timer is already running. Every tab switch, settings
   save and cycle transition leaks another one, still firing at dead objects.
2. Old timers are never disposed — only the completion handler is detached.
3. Timer durations have no minimum or maximum, so `0` and negative values are accepted.
4. The toast body is mojibake (`"Il timer di lavoro � scaduto!"`) and is the only Italian string
   in an otherwise English UI.
5. Notifications fire only at the end of work, though the app advertises both.
6. The idle stopwatch is shown on auto-pause but only hidden on stop, so it lingers after an
   auto-resume.
