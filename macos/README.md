# Pomodoro Timer — macOS

Native macOS (Apple Silicon) implementation in Swift 6 + SwiftUI/AppKit, ported from the
[WinUI 3 version](../windows/). See the [root README](../README.md) for what the app does and how
the two platforms differ.

**No Xcode required** — it builds with the Command Line Tools alone, via Swift Package Manager
plus a script that assembles the `.app` bundle.

## Requirements

macOS 14 or later, Apple Silicon.

## Build

```sh
./scripts/make_app.sh          # builds, runs the self-check, assembles, signs, registers
open dist/PomodoroTimer.app
```

`scripts/run.sh` does all of the above plus relaunching.

Always launch through `open` or Finder, never `dist/PomodoroTimer.app/Contents/MacOS/PomodoroTimer`
directly: running the binary outside LaunchServices leaves `UNUserNotificationCenter` without a
bundle proxy.

### Signing

The script uses the first available code-signing identity, or falls back to ad-hoc.

Ad-hoc signatures have no certificate, so the designated requirement is a bare `cdhash` that
**changes on every build** — notification permissions and the login-item registration go stale
each time you recompile. To avoid that, create a free self-signed certificate:

> Keychain Access → menu **Certificate Assistant → Create a Certificate…** → name it e.g.
> `Pomodoro Dev`, Identity Type **Self Signed Root**, Certificate Type **Code Signing** → Create.

Then either let the script find it automatically, or pin it:

```sh
SIGN_ID="Pomodoro Dev" ./scripts/make_app.sh
```

No Apple Developer account is needed. Distribution to other Macs is a different matter and does
require a Developer ID certificate plus notarization — this build is for local use.

## Testing

`swift test` is unavailable in this toolchain: XCTest and swift-testing ship with Xcode, not with
the Command Line Tools. In their place, `pomodoro-selfcheck` is a headless executable that
asserts over the ported core — the state-transition table, the deadline arithmetic, settings
clamping, and the activity-manager polarity. `make_app.sh` runs it and refuses to assemble the
bundle if it fails.

```sh
swift build -c release && ./.build/release/pomodoro-selfcheck
```

### Inspecting the UI without a screen capture

`screencapture` needs the Screen Recording permission, which a terminal session often lacks.
`ImageRenderer` draws the SwiftUI hierarchy offscreen instead, with no permission at all:

```sh
swift build -c release && ./.build/release/pomodoro-selfcheck --render /tmp/preview.png
```

`NSViewRepresentable` content does not render this way, so the translucent window material comes
out flat — everything SwiftUI draws itself is faithful.

### Liquid Glass

On macOS 26 the transport buttons and the phase picker are Liquid Glass surfaces
(`glassEffect`, `GlassEffectContainer`), with the selection a tinted glass pill that morphs
between segments. The deployment target stays at macOS 14, so every glass surface degrades to
the material it used before rather than dropping older systems.

`glassEffect` is a live compositing effect: it does not rasterise through `ImageRenderer`, so it
is the one part of the UI the offscreen renderer cannot check. If it misbehaves, turn it off
without rebuilding:

```sh
defaults write studio.visionlab.pomodorotimer debug.disableGlass -bool YES
defaults delete studio.visionlab.pomodorotimer debug.disableGlass
```

### Appearance

The window material can be swapped without rebuilding, to taste:

```sh
defaults write studio.visionlab.pomodorotimer debug.windowMaterial -int 7   # sidebar
defaults delete studio.visionlab.pomodorotimer debug.windowMaterial        # back to default
```

13 = `hudWindow` (default), 15 = `fullScreenUI`, 7 = `sidebar`, 6 = `popover`,
21 = `underWindowBackground`, 12 = `windowBackground`. Restart the app after changing it.

The app forces the dark appearance regardless of the system theme — the translucent material
only reads as dark and see-through in `darkAqua`; in the light appearance it renders as a flat
grey panel. To follow the system theme instead, delete the `NSApp.appearance` line in
`AppDelegate.swift`.

For manual testing, `scripts/debug_defaults.sh` reinterprets the duration settings as *seconds*
and lowers the idle thresholds, so a full cycle takes under a minute:

```sh
./scripts/debug_defaults.sh       # enable
./scripts/debug_defaults.sh off   # restore
```

## What macOS will not let this app block

The break overlay is deliberately *best-effort*, not kiosk mode:

| | |
|---|---|
| ✅ Covers every display, across all Spaces, instantly | `.screenSaver` level + `.canJoinAllSpaces` + `.stationary` |
| ✅ Covers other apps' full-screen windows | `.canJoinAllApplications` |
| ✅ Hides the Dock and menu bar | `.hideDock, .hideMenuBar` |
| ⚠️ Those options apply **only while this app is active** — losing focus brings the Dock back | mitigated by a rate-limited re-assert, and by `.disableProcessSwitching` at Strict |
| ❌ Mission Control, Spotlight, Notification Center | drawn above `.screenSaver` by the window server; not blockable without entitlements |
| ❌ Cmd-Q and Force Quit | **left working on purpose** — a timer that stops you shutting down your Mac is a bug |

Four escape hatches are always live at every strictness level: the **Skip break** button, **Esc**,
**⌘.**, and **⌘Q**.

## Ported from Windows

The timer core is a faithful port: the deadline-based countdown, the State pattern transition
table, and the mirrored activity-manager polarity all match the C# line for line, with the
original file names recorded in doc comments so the two trees stay diffable.

Platform replacements:

| Windows | macOS |
|---|---|
| `System.Timers.Timer(1000)` + `DispatcherQueue` | one `@MainActor` task sleeping to an absolute instant |
| Win32 `GetLastInputInfo` | `CGEventSource.secondsSinceLastEventType(.hidSystemState, …)`, no permissions needed |
| `MicaBackdrop` | `NSVisualEffectView`, plus Liquid Glass controls on macOS 26 |
| `AppWindowPresenterKind.FullScreen` on the main window | a dedicated borderless overlay window per display |
| WinRT toasts + COM activator | `UNUserNotificationCenter` |
| `LocalSettings` composite value | `UserDefaults` |
| white PNG control glyphs | SF Symbols (the originals were white-on-transparent and invisible in Light Mode) |

Bugs in the original that are **not** reproduced here:

1. **Leaked activity monitors.** Each manager constructed a monitor into a local variable that
   was never stored or stopped, while its 1 s timer was already running. Every tab switch,
   settings save and cycle transition leaked another one, still firing at dead objects.
2. Old timers were never disposed — only the completion handler was detached.
3. Durations had no minimum or maximum, so `0` and negative values were accepted.
4. The toast text was mojibake (`"Il timer di lavoro � scaduto!"`).
5. Notifications fired only at the end of work, though the README promised both.

Two original behaviours that *look* like bugs and are preserved deliberately, with the reasoning
recorded at the call sites: idle notification is **level-triggered** rather than edge-triggered,
and the idle stopwatch **stops but stays visible** after an auto-resume.

Not ported: MSIX packaging, and the `CompletedCycles` field, which the original declared but
never assigned or read.

## License

[MIT](../LICENSE).
