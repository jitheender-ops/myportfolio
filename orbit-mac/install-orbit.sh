#!/usr/bin/env bash
# Install Orbit (https://github.com/harsha20599/orbit) on an Apple Silicon Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/jitheender-ops/myportfolio/main/orbit-mac/install-orbit.sh | bash
#
# The release is a native arm64 build but it is only ad-hoc signed and not notarized,
# so macOS 15+ refuses to open it ("Apple could not verify Orbit...") and the old
# right-click > Open trick no longer works. This script downloads the latest release,
# unpacks it without breaking its signature, installs it to /Applications, clears the
# quarantine flag, re-signs only if the signature doesn't verify, resets a stale
# Accessibility grant from a previous install, and opens Orbit plus the settings pane.
set -euo pipefail

ZIP_URL="${ORBIT_ZIP_URL:-https://github.com/harsha20599/orbit/releases/latest/download/Orbit-macOS.zip}"
APP_DIR="${ORBIT_APP_DIR:-/Applications}"
APP="$APP_DIR/Orbit.app"
BUNDLE_ID="app.orbit.dial"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "this installer is for macOS"
[ "$(uname -m)" = "arm64" ] || warn "Orbit's macOS build is for Apple Silicon; this Mac reports $(uname -m)"
major="$(sw_vers -productVersion | cut -d. -f1)"
[ "$major" -ge 13 ] || die "Orbit needs macOS 13 or newer (this Mac has $(sw_vers -productVersion))"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

say "Downloading $ZIP_URL"
curl -fL --progress-bar -o "$tmp/Orbit-macOS.zip" "$ZIP_URL"

# ditto keeps the bundle's symlinks and extended attributes intact; some unzip tools
# flatten the symlinks, which breaks the signature and gives "Orbit is damaged".
say "Unpacking"
ditto -x -k "$tmp/Orbit-macOS.zip" "$tmp/out"
[ -d "$tmp/out/Orbit.app" ] || die "Orbit.app not found in the download"

if pgrep -x Orbit >/dev/null 2>&1; then
  say "Quitting the running Orbit"
  osascript -e 'tell application id "'"$BUNDLE_ID"'" to quit' >/dev/null 2>&1 || true
  sleep 2
  pkill -x Orbit 2>/dev/null || true
fi

had_old=0
[ -d "$APP" ] && had_old=1

# /Applications is writable for admin users; fall back to sudo otherwise
SUDO=""
if [ ! -w "$APP_DIR" ] || { [ -e "$APP" ] && [ ! -w "$APP" ]; }; then
  say "$APP_DIR needs admin rights; you may be asked for your password"
  SUDO="sudo"
fi

say "Installing to $APP"
$SUDO rm -rf "$APP"
$SUDO ditto "$tmp/out/Orbit.app" "$APP"

# Gatekeeper blocks quarantined apps that aren't notarized
$SUDO xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

resigned=0
if ! codesign --verify --deep --strict "$APP" >/dev/null 2>&1; then
  warn "signature didn't verify; re-signing locally (ad-hoc)"
  $SUDO codesign --force --deep --sign - "$APP"
  resigned=1
fi

# Every release has a new ad-hoc signature, so an Accessibility grant from an older
# install looks switched on but no longer applies. Clear it so macOS asks again.
if [ "$had_old" = 1 ] || [ "$resigned" = 1 ]; then
  say "Clearing the old Accessibility grant for Orbit"
  tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || warn "couldn't reset it; remove Orbit from the Accessibility list by hand"
fi

say "Starting Orbit"
open "$APP"
sleep 2
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true

cat <<'EOF'

Orbit is installed. It lives in the menu bar (no Dock icon). To finish:

  1. Pair your CMF Buds Pro 2 and pick them as the sound output
     (Control Center > Sound).
  2. In System Settings > Privacy & Security > Accessibility (opened for you),
     turn on Orbit. If it isn't listed, click + and add /Applications/Orbit.app.
  3. Quit and reopen Orbit (menu-bar icon > Quit, then open it from Applications).
  4. Double-press the case dial to open the wheel, turn to pick, press to choose.
     The first press sent to Spotify or Music asks for Automation permission: allow it.

Log file: ~/.orbit/orbit.log
EOF
