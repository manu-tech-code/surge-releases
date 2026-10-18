#!/bin/bash
# Installs, or updates, Surge Downloader Manager from the latest GitHub release:
#
#   curl -fsSL https://raw.githubusercontent.com/manu-tech-code/surge-releases/HEAD/scripts/install.sh | bash
#
# It downloads the .dmg of the latest release with curl, checks that the app inside is signed
# by the project's certificate, copies it to Applications and opens it. Files fetched with curl
# aren't marked as downloaded from the internet, so macOS doesn't block the first launch the
# way it does for a browser download.
#
# Options, as environment variables:
#   SURGE_INSTALL_DIR=<folder>   install there (default /Applications, or
#                                ~/Applications if /Applications isn't writable)
#   SURGE_NO_OPEN=1              don't open the app afterwards
set -euo pipefail

REPO="manu-tech-code/surge-releases"
DMG_URL="https://github.com/$REPO/releases/latest/download/Surge.dmg"
APP_NAME="Surge.app"
BUNDLE_ID="com.amalitech.Surge"
TEAM_ID="KNK4UH42NN"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# macOS 15 or later, on Apple silicon (checked even under Rosetta).
[ "$(uname -s)" = "Darwin" ] || fail "SDM is a Mac app."
[ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = "1" ] || fail "SDM needs an Apple silicon Mac (M1 or later)."
MACOS=$(sw_vers -productVersion)
[ "${MACOS%%.*}" -ge 15 ] || fail "SDM needs macOS 15 or later; this Mac has macOS $MACOS."

DEST="${SURGE_INSTALL_DIR:-/Applications}"
if [ -z "${SURGE_INSTALL_DIR:-}" ] && [ ! -w "$DEST" ]; then DEST="$HOME/Applications"; fi
mkdir -p "$DEST" 2>/dev/null || true
[ -w "$DEST" ] || fail "Can't write to $DEST."
TARGET="$DEST/$APP_NAME"

WORK=$(mktemp -d -t surge)
MOUNT="$WORK/volume"
cleanup() {
  hdiutil detach "$MOUNT" -quiet -force >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

say "Downloading the latest Surge Downloader Manager"
curl -fL --progress-bar -o "$WORK/Surge.dmg" "$DMG_URL" || fail "The download failed. Is there a release yet at github.com/$REPO?"

say "Checking the app's signature"
hdiutil attach "$WORK/Surge.dmg" -nobrowse -readonly -noautoopen -mountpoint "$MOUNT" -quiet </dev/null \
  || fail "Couldn't open the disk image."
SRC="$MOUNT/$APP_NAME"
[ -d "$SRC" ] || fail "The disk image doesn't contain $APP_NAME."
codesign --verify --deep --strict "$SRC" >/dev/null 2>&1 || fail "The app's signature isn't valid."
SIGNATURE=$(codesign -dv "$SRC" 2>&1)
printf '%s\n' "$SIGNATURE" | grep -qx "Identifier=$BUNDLE_ID" || fail "That isn't SDM ($BUNDLE_ID)."
printf '%s\n' "$SIGNATURE" | grep -qx "TeamIdentifier=$TEAM_ID" || fail "The app isn't signed by SDM's developer."
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$SRC/Contents/Info.plist")

# Quit a copy running from where this one goes, before replacing it.
if pgrep -f "$TARGET/Contents/MacOS/" >/dev/null 2>&1; then
  say "Quitting the running copy"
  pkill -f "$TARGET/Contents/MacOS/" || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -f "$TARGET/Contents/MacOS/" >/dev/null 2>&1 || break
    sleep 0.5
  done
fi

say "Installing in $DEST"
ditto "$SRC" "$WORK/$APP_NAME"
rm -rf "$TARGET"
mv "$WORK/$APP_NAME" "$TARGET"

say "Surge Downloader Manager $VERSION is installed"
if [ -z "${SURGE_NO_OPEN:-}" ]; then
  open "$TARGET"
fi
