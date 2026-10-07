#!/bin/bash
# Screenshots of the watch boards from the demo store, named like the boards (design/built/watch-1/).
#   WATCH_DD=<derived data> Scripts/watch-boards.sh <46|42> [part...]     parts: a (Today, set, rest, break), b (hold, tick-offs, controls, end, summary), c (waiting, ramp-ups, effort), d (figures), e (finished, swap), f (the 42 mm boards)
# Each line is: board, then the launch arguments that drive the demo app to that board's state.
set -e
size=${1:-46}; shift || true
parts=${*:-a}
# The boards of the parts before the figures are drawn without one (design 2.1A, 3.8): `-figures NO`.
FIG=(-figures NO)
shot() { "$(dirname "$0")/watch-shot.sh" "$size" "$@" "${FIG[@]}"; }

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
c)
  shot W110-TodayWaiting -day wednesday -fresh YES -screen running-waiting
  shot W213-RampUp -day wednesday -fresh YES -running YES -screen item -item incline-db-press
  shot W313-RestRampUp -day wednesday -fresh YES -running YES -screen item -item incline-db-press -ramps 2 -left 42 -of 60
  shot W315-RestBetweenRampUps -day wednesday -fresh YES -running YES -screen item -item incline-db-press -ramps 1 -left 42 -of 60
  shot W314-BreakBack -day wednesday -fresh YES -screen break-back -left 27 -of 45
  shot W58-Effort -day wednesday -screen effort
  shot W59-SummaryEffort -day wednesday -screen summary-effort
  ;;
e)
  shot W111-TodayFinished -day wednesday -fresh YES -screen finished
  shot W112-TodayFinishedAll -day wednesday -fresh YES -screen finished-all
  shot W113-TodaySwapped -day wednesday -fresh YES -screen swapped
  shot W216-Swap -day wednesday -fresh YES -screen swap
  shot W51-Controls -day wednesday -screen controls-break -left 115 -of 150
  ;;
d)
  FIG=()
  shot W211-SetFigure -day wednesday -screen set
  shot W212-How -day wednesday -screen how -turned YES
  shot W214-HowTurn -day wednesday -screen how -turned NO
  shot W312-BreakFigure -day wednesday -screen next -left 115 -of 150
  shot W215-HowSwap -day wednesday -fresh YES -screen how -item machine-chest-press -turned YES
  ;;
esac
done
