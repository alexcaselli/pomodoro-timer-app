# Pomodoro Timer

A Pomodoro timer that will not let you skip your breaks, with **native apps for Windows and
macOS** — no shared runtime, no web view. Each platform is written against its own native UI
framework, from the same behavioural spec.

| | Windows | macOS |
|---|---|---|
| Framework | WinUI 3 / .NET 8 | SwiftUI + AppKit, Swift 6 |
| Source | [`windows/`](windows/) | [`macos/`](macos/) |
| Build docs | [`windows/README.md`](windows/README.md) | [`macos/README.md`](macos/README.md) |
| Requirements | Windows 10 1809+, x86 / x64 / ARM64 | macOS 14+, Apple Silicon |

## What it does

* **Work and break timers**, 25 / 3 minutes by default and adjustable.
* **Activity-aware auto-pause** — the feature the app exists for:
  * during **work**, going idle past 15 s pauses the timer, and touching the keyboard resumes it;
  * during **break** the logic is **mirrored** — using the machine *pauses* the break, and
    leaving it alone resumes it. The break only counts down while you have genuinely stepped away.
  * while auto-paused, a stopwatch counts how long you have been gone.
* **Unignorable breaks** — when a work session ends, the app takes over the screen. You can end a
  break deliberately, but not by ignoring it.
* **Automatic cycling** — work ends and the break starts by itself; the break ends and work
  starts by itself.
* **Notifications** when a timer finishes.

### Platform differences

Neither app is a port of the other's UI; each follows its own platform's conventions.

| | Windows | macOS |
|---|---|---|
| Break takeover | window enters full screen | borderless overlay per display, above other apps' full-screen spaces |
| Menu bar / tray | — | menu bar extra with a live countdown |
| Open at login | — | via `SMAppService` |
| Notification on break end | — | yes |
| Translucency | Mica backdrop | `NSVisualEffectView`, plus Liquid Glass controls on macOS 26 |
| Packaging | MSIX | `.app` bundle assembled by a script |

The macOS app also fixes several defects carried by the original Windows implementation — leaked
activity monitors, undisposed timers, unbounded durations. They are listed in
[`macos/README.md`](macos/README.md).

## Building

**Windows** — open `windows/PomodoroTimerApp.sln` in Visual Studio 2022 and build. See
[`windows/README.md`](windows/README.md).

**macOS** — no Xcode required; the Command Line Tools are enough.

```sh
cd macos
./scripts/make_app.sh
open dist/PomodoroTimer.app
```

See [`macos/README.md`](macos/README.md) for signing, testing and troubleshooting.

## Releases

Tagged releases are published on the
[Releases page](https://github.com/alexcaselli/PomodoroTimerApp/releases).

Release notes only, for now — no prebuilt binaries. Neither platform's build is currently signed
with a distributable certificate:

* the macOS app is **ad-hoc signed and not notarized**, so a downloaded copy would be blocked by
  Gatekeeper and would need clearing by hand in System Settings › Privacy & Security;
* the Windows MSIX is signed with a **self-signed certificate**, which SmartScreen will warn about.

Building from source avoids both problems entirely, and takes under a minute on either platform.
Prebuilt binaries will be attached once proper code-signing certificates are in place — a Developer
ID for macOS, an EV or OV certificate for Windows.

## Contributing

Issues and pull requests are welcome. Please keep changes scoped to one platform per pull request
where possible, and note in the description whether the behaviour should be mirrored on the other.

The macOS project has a headless assertion harness that the build script runs as a gate:

```sh
cd macos && swift build -c release && ./.build/release/pomodoro-selfcheck
```

## License

[MIT](LICENSE).
