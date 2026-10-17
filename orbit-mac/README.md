# Orbit on a MacBook Air (M4)

[Orbit](https://github.com/harsha20599/orbit) turns the CMF Buds Pro 2 case dial into a
controller. Its macOS release is already a native Apple Silicon build, so it runs on the
M4 as-is. It just isn't notarized, so macOS blocks it on first launch. `install-orbit.sh`
gets it past that.

## Install

Open Terminal and run:

```sh
curl -fsSL https://raw.githubusercontent.com/jitheender-ops/myportfolio/ccr-afb59e43-7jvmls/orbit-mac/install-orbit.sh | bash
```

(Once this is merged into `main`, swap `ccr-afb59e43-7jvmls` in the URL for `main`.)

The script:

1. downloads the latest `Orbit-macOS.zip` from Orbit's releases
2. unpacks it with `ditto`, which keeps the app's signature intact
3. installs it to `/Applications/Orbit.app`, replacing any older copy
4. removes the quarantine flag that triggers "Apple could not verify Orbit…"
5. re-signs the app locally (ad-hoc), but only if its signature doesn't check out
6. when updating, clears the old Accessibility grant, which a new build no longer matches
7. opens Orbit and the Accessibility settings pane

Run it again to update to a newer release.

## After installing

1. Pair the buds and pick them as the sound output (Control Center → Sound).
2. System Settings → Privacy & Security → Accessibility: turn on **Orbit**.
3. Quit Orbit from its menu-bar icon and open it again.
4. Double-press the dial to open the wheel, turn to pick a tool, press to choose.

## Doing it by hand instead

```sh
cd ~/Downloads
ditto -x -k Orbit-macOS.zip .
mv Orbit.app /Applications/
xattr -dr com.apple.quarantine /Applications/Orbit.app
open /Applications/Orbit.app
```

Or open it once, let it be blocked, then go to System Settings → Privacy & Security and
click **Open Anyway**. On macOS 15 and later, right-click → Open no longer gets past this.

## Troubleshooting

- **"Orbit is damaged and can't be opened"**: run
  `codesign --force --deep --sign - /Applications/Orbit.app`, then grant Accessibility again.
- **Turning the dial does nothing**: the buds must be the current sound output, and Orbit
  must be on in the Accessibility list. If it's on but still does nothing, remove it with
  **–**, add it back, and restart Orbit.
- **The volume slider appears on every click**: that's macOS, and apps can't hide it.
  Press-and-hold isn't available on macOS.
- Log: `~/.orbit/orbit.log` (menu-bar icon → Open log).
