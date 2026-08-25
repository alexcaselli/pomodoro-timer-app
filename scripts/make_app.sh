#!/usr/bin/env bash
# Assembles PomodoroTimer.app from the SwiftPM build. Requires only Command Line Tools.
set -euo pipefail

APP_NAME="PomodoroTimer"
BUNDLE_ID="${BUNDLE_ID:-studio.visionlab.pomodorotimer}"
VERSION="${VERSION:-1.0.0}"
BUILD="${BUILD:-1}"
CONFIG="${CONFIG:-release}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

# --- signing identity -------------------------------------------------------
# A self-signed "Code Signing" certificate from Keychain Access gives a designated
# requirement that is STABLE across rebuilds, so notification permissions and the
# SMAppService login-item registration survive recompilation. Ad-hoc ("-") re-keys the
# app on every build and those approvals silently reset.
if [[ -n "${SIGN_ID:-}" ]]; then
  IDENTITY="$SIGN_ID"
elif IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
                 | sed -n 's/.*"\(.*\)"/\1/p' | head -1)" && [[ -n "$IDENTITY" ]]; then
  :
else
  IDENTITY="-"
fi
[[ "$IDENTITY" == "-" ]] && echo "!! no signing identity found — falling back to ad-hoc" >&2

echo "==> build ($CONFIG)"
swift build -c "$CONFIG" --package-path "$ROOT" --product "$APP_NAME"

echo "==> self-check"
swift build -c "$CONFIG" --package-path "$ROOT" --product pomodoro-selfcheck
# Never hardcode .build/release: SwiftPM may use a triple-qualified dir.
BIN_DIR="$(swift build -c "$CONFIG" --package-path "$ROOT" --show-bin-path)"
[[ -x "$BIN_DIR/$APP_NAME" ]] || { echo "no binary at $BIN_DIR/$APP_NAME" >&2; exit 1; }
"$BIN_DIR/pomodoro-selfcheck" || { echo "self-check FAILED" >&2; exit 1; }

echo "==> assemble"
rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RES"
cp "$BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

sed -e "s|@APP_NAME@|$APP_NAME|g" \
    -e "s|@BUNDLE_ID@|$BUNDLE_ID|g" \
    -e "s|@VERSION@|$VERSION|g" \
    -e "s|@BUILD@|$BUILD|g" \
    "$ROOT/Packaging/Info.plist" > "$CONTENTS/Info.plist"
plutil -lint "$CONTENTS/Info.plist" >/dev/null   # a malformed plist reads as "app is damaged"
printf 'APPL????' > "$CONTENTS/PkgInfo"

echo "==> icon"
SRC="$ROOT/Packaging/AppIcon-source.png"
if [[ -f "$SRC" ]]; then
  ICONSET="$DIST/AppIcon.iconset"
  rm -rf "$ICONSET"; mkdir -p "$ICONSET"
  # iconutil accepts ONLY these ten names; anything else -> "Invalid Iconset".
  for spec in 16:icon_16x16 32:icon_16x16@2x 32:icon_32x32 64:icon_32x32@2x \
              128:icon_128x128 256:icon_128x128@2x 256:icon_256x256 512:icon_256x256@2x \
              512:icon_512x512 1024:icon_512x512@2x; do
    px="${spec%%:*}"; name="${spec##*:}"
    sips -s format png -z "$px" "$px" "$SRC" --out "$ICONSET/$name.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$RES/AppIcon.icns"
  rm -rf "$ICONSET"
else
  echo "!! $SRC missing — app will show a generic icon" >&2
fi

echo "==> sign ($IDENTITY)"
# Quarantine xattrs on copied files invalidate the seal, so strip them BEFORE signing.
xattr -cr "$APP"
# --deep is deprecated since macOS 13 and pointless here: one binary, no nested code.
codesign --force --sign "$IDENTITY" --identifier "$BUNDLE_ID" --timestamp=none "$APP"
codesign --verify --strict --verbose=2 "$APP"

echo "==> register with LaunchServices"
# Required for UNUserNotificationCenter to find a bundle proxy and for Login Items.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

echo "==> $APP"
