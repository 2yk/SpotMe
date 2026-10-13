#!/bin/bash
# One screenshot of the phone app from the demo store, for comparing with a design board.
#   Scripts/phone-shot.sh <BoardName> [launch arguments]
#   Scripts/phone-shot.sh P75-Exercise -day wednesday -screen detail -item machine-chest-press
# Needs a build of RepCoach for the simulator: PHONE_DD is its -derivedDataPath (default ./build/dd-ios).
# The PNG is scaled to 440 px wide, the boards' width (1 pt = 1 px on the iPhone 16 Pro Max), and goes to
# design/built/iphone-1/<BoardName>.png; PHONE_OUT=design/built/iphone-2 puts them elsewhere.
set -e
board=$1; shift
# A simulator of its own (xcrun simctl create "SpotMe iPhone 16 Pro Max" …) keeps other sessions' apps out of the shots.
device="${PHONE_DEVICE:-SpotMe iPhone 16 Pro Max}"
udid=$(xcrun simctl list devices available | grep -E "^ +$device \(" | head -1 | grep -o '[0-9A-F-]\{36\}')
app="${PHONE_DD:-build/dd-ios}/Build/Products/Debug-iphonesimulator/RepCoach.app"
out="${PHONE_OUT:-design/built/iphone-1}"
mkdir -p "$out"
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" >/dev/null 2>&1 || true
# Dark status bar clock like the boards: 9:41, full bars.
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 >/dev/null 2>&1 || true
# PHONE_INSTALL=1: put the build on the simulator first (once per build).
[ -n "$PHONE_INSTALL" ] && xcrun simctl install "$udid" "$app"
xcrun simctl terminate "$udid" com.yeshu.RepCoach >/dev/null 2>&1 || true
xcrun simctl launch "$udid" com.yeshu.RepCoach -demo YES "$@" >/dev/null
sleep "${PHONE_WAIT:-3}"
raw="$out/.raw-$board.png"
for try in 1 2 3; do
  perl -e 'alarm 15; exec @ARGV' xcrun simctl io "$udid" screenshot "$raw" >/dev/null 2>&1 && break
  sleep 2
done
sips --resampleWidth 440 "$raw" --out "$out/$board.png" >/dev/null
rm -f "$raw"
echo "$out/$board.png"
