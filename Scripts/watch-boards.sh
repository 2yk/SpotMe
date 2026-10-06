#!/bin/bash
# Screenshots of the watch boards from the demo store, named like the boards (design/built/watch-1/).
#   WATCH_DD=<derived data> Scripts/watch-boards.sh <46|42> [part...]     parts: a (Today, set, rest, break), b (hold, tick-offs, controls, end, summary)
# Each line is: board, then the launch arguments that drive the demo app to that board's state.
set -e
size=${1:-46}; shift || true
parts=${*:-a}
shot() { "$(dirname "$0")/watch-shot.sh" "$size" "$@"; }

for part in $parts; do
case $part in
a)
  shot W11-TodayStart -day wednesday -fresh YES
  shot W12-TodayList -day wednesday -fresh YES -screen list
  shot W13-TodayRunning -day wednesday -fresh YES -screen running
  shot W14-TodayPaused -day wednesday -fresh YES -screen running-paused
  shot W15-TodayEnd -day wednesday -fresh YES -screen running-end
  shot W16-TodayAllDone -day wednesday -screen alldone
  shot W17-Days -day wednesday -screen days
  shot W18-RestDay -day saturday -fresh YES
  shot W21A-SetTiles -day wednesday -screen set
  shot W22-SetWeight -day wednesday -screen set -focus weight
  shot W23-SetFirst -day wednesday -weeks 0 -screen firsttime
  shot W24-SetReps -day wednesday -screen item -item hanging-leg-raise
  shot W25-SetSide -day sunday -screen item -item pallof-press
  shot W26-SetMax -day thursday -fresh YES -screen amrap
  shot W27-SetVolume -day thursday -fresh YES -screen volume-set
  shot W28-SetSuperset -day friday -screen superset
  shot W29-SetPaused -day wednesday -screen paused-set
  shot W210-SetDeload -day wednesday -fresh YES -deload YES -screen item -item incline-db-press
  shot W31A-RestEdge -day wednesday -screen rest -left 108 -of 150
  shot W32-RestDrop -day wednesday -screen rest -left 120 -of 150
  shot W33-RestUp -day wednesday -running YES -screen item -item cable-lateral-raise -log 1 -reps 17 -left 27 -of 45
  shot W34-RestReps -day wednesday -running YES -screen item -item hanging-leg-raise -log 1 -reps 10 -left 20 -of 45
  shot W35-RestPaused -day wednesday -screen paused-rest
  shot W36-RestSuperset -day friday -screen superset-rest -left 52 -of 75
  shot W37-RestAlwaysOn -day wednesday -screen rest -left 108 -of 150 -dim YES
  shot W38-Break -day wednesday -screen next -left 115 -of 150
  shot W39-BreakChecklist -day wednesday -screen break-checklist -left 9 -of 15
  shot W310-BreakPick -day wednesday -screen next-picker
  shot W311-BreakMax -day thursday -fresh YES -screen volume -left 71 -of 80
  ;;
b)
  shot W41-HoldReady -day sunday -screen item -item weighted-plank
  shot W42-HoldRunning -day sunday -screen hold -elapsed 18
  shot W43-HoldInRange -day sunday -screen hold -elapsed 37
  shot W44-HoldTop -day sunday -screen hold -elapsed 45
  shot W45-ChecklistSteps -day wednesday -fresh YES -screen checklist
  shot W46-ChecklistEnd -day wednesday -fresh YES -screen checklist-end
  shot W47-ChecklistNote -day monday -fresh YES -screen item -item manual-neck-resistance
  shot W510-ControlsSkip -day wednesday -screen controls
  shot W52-ControlsPaused -day wednesday -screen paused
  shot W53-End -day wednesday -screen finish-dialog
  shot W54-Discard -day wednesday -screen discard
  shot W55-AllDone -day wednesday -screen alldone-screen
  shot W56-Summary -day wednesday -screen summary
  shot W57-HealthAlert -day wednesday -screen start-denied
  shot W61-Complications -day wednesday -screen complications
  ;;
esac
done
