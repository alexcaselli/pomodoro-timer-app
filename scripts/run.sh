#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/make_app.sh"
killall PomodoroTimer 2>/dev/null || true
# Always launch via `open`: running Contents/MacOS/PomodoroTimer directly bypasses
# LaunchServices and is a fast route to the UNUserNotificationCenter crash.
open "$ROOT/dist/PomodoroTimer.app"
