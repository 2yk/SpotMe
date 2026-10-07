#!/bin/bash
# One screenshot of the watch app from the demo store, for comparing with a design board.
#   Scripts/watch-shot.sh <46|42> <BoardName> [launch arguments]
#   Scripts/watch-shot.sh 46 W21A-SetTiles -day wednesday -screen set
# Needs a build of RepCoachWatch for the simulator: set WATCH_DD to its -derivedDataPath (default ./build/dd).
# The PNG is 416 × 496 at 46 mm, the same as the boards, and goes to design/built/watch-1/<BoardName>.png
# (42 mm: <BoardName>-42.png); WATCH_OUT=design/built/watch-2 puts them elsewhere.
set -e
size=$1; board=$2; shift 2
case $size in
  46) device="Apple Watch Series 12 (46mm)"; suffix="" ;;
  42) device="Watch 42"; suffix="-42" ;;
  *) echo "size must be 46 or 42"; exit 1 ;;
esac
udid=$(xcrun simctl list devices available | grep -F "$device (" | head -1 | grep -o '[0-9A-F-]\{36\}')
app="${WATCH_DD:-build/dd}/Build/Products/Debug-watchsimulator/RepCoachWatch.app"
out="${WATCH_OUT:-design/built/watch-2}"
mkdir -p "$out"
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" >/dev/null 2>&1 || true
# WATCH_INSTALL=1: put the build on the simulator first (once per build and size).
[ -n "$WATCH_INSTALL" ] && xcrun simctl install "$udid" "$app"
xcrun simctl terminate "$udid" com.yeshu.RepCoach.watchkitapp >/dev/null 2>&1 || true
xcrun simctl launch "$udid" com.yeshu.RepCoach.watchkitapp -demo YES "$@" >/dev/null
sleep "${WATCH_WAIT:-4}"
# simctl io sometimes hangs on a screenshot: give each try 15 s and try again.
for try in 1 2 3; do
  perl -e 'alarm 15; exec @ARGV' xcrun simctl io "$udid" screenshot "$out/$board$suffix.png" >/dev/null 2>&1 && break
  sleep 2
done
echo "$out/$board$suffix.png"
