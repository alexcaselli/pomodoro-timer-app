#!/usr/bin/env bash
# Shrinks the timers so a full work -> break -> work cycle can be exercised in under a minute.
# Every key here is a no-op unless set. Run with `off` to clear them all.
set -euo pipefail
D=studio.visionlab.pomodorotimer

if [[ "${1:-on}" == "off" ]]; then
  for k in debug.durationUnitSeconds debug.workInactivityThreshold \
           debug.breakActivityThreshold debug.showDebugLabel; do
    defaults delete "$D" "$k" 2>/dev/null || true
  done
  echo "debug overrides cleared"
else
  defaults write "$D" debug.durationUnitSeconds -bool YES   # "minutes" are read as SECONDS
  defaults write "$D" debug.workInactivityThreshold -float 3
  defaults write "$D" debug.breakActivityThreshold -float 2
  defaults write "$D" debug.showDebugLabel -bool YES
  echo "debug overrides set — restart the app"
fi
defaults read "$D" 2>/dev/null || true
