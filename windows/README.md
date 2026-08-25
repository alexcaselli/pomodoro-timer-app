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

## Fixed defects

These were found while porting to macOS and have since been fixed here too:

1. **Leaked activity monitors.** Each manager constructed a monitor into a local variable that
   was never stored or stopped, while its 1 s timer was already running. Every tab switch,
   settings save and cycle transition leaked another one, still firing at dead objects. The
   monitor is now a field, `UserMonitor` is `IDisposable`, and the manager unregisters and
   disposes it.
2. **Timers were never disposed** — `StartPomodoroTimer` only detached the completion handler,
   leaving the 1 s countdown running. `PomodoroTimer` is now `IDisposable`, everything goes
   through a single `DisposeCurrentTimerAndManager()`, and the window disposes on close.
3. **Durations had no bounds**, so `0` and negative values were accepted and produced a timer
   that expired instantly, forever. The `NumberBox` controls now carry `Minimum`/`Maximum` and
   `ValidationMode`, and an empty field (which yields `NaN`) falls back to the current value.
4. **A partial or corrupt settings composite left the durations at 0**, because the `catch` in
   `ReadAndSetLocalConfigs` did not apply the fallbacks. It does now.
5. **The toast body was mojibake** (`"Il timer di lavoro � scaduto!"`) and the only Italian
   string in an otherwise English UI.
6. **Notifications fired only at the end of work**, though the app advertises both. Break
   completion now notifies as well.

Note on the work duration's `Minimum="5"`: it is a multiple of `SmallChange`, deliberately.
With `Minimum="1"` and a step of 5, walking down from 25 reaches 5, then 0 clamps to 1, and
every step up afterwards lands on 6, 11, 16 — the original 25 becomes unreachable. The macOS app
allows a 1-minute work timer because its stepper snaps to the step's lattice; WinUI's `NumberBox`
has no equivalent, so the bound is aligned to the step instead.

One original behaviour that *looks* like a bug is kept on purpose, in both apps: the idle
stopwatch stops counting but stays on screen after an auto-resume, so you can still see how long
you were away.

## Not verified

The fixes above were written on macOS, where WinUI 3 cannot be compiled. **They have not been
built or run** — please compile in Visual Studio before trusting them.
