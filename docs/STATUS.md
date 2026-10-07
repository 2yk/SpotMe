# Status

Kept by the builder session ("SpotMe - Frontend (Mac Studio)"). Read by `/next`. Update it with the work.

## Now

**Watch build 9** is built on branch `watch-build-9` (from `design/handoff/watch-2/BUILD.md`, sections 1–9 including 8a) and waits for the Designer's check of the screenshots in `design/built/watch-2/` (every board at 46 mm; set, rest, break, controls, Today finished and the break with a figure at 42 mm; `W81-TapRunning-before/after` is the complication check; `W62-ComplicationStates` the complication's new states). Package tests, both schemes and the watch UI tests pass. Not pushed yet (ask the owner first). After the Designer's OK the owner installs it from Xcode.

Build 9 notes for the Designer, where the build differs from the handoff:
- The break's figure opens How (so Swap reaches the break); the name still opens "Do next".
- A swapped item's Swap sheet lists the plan's own exercise first ("Back to the plan's exercise"), to take the swap back.
- With the Swap button the figure is always 100 pt (200 px), not only for a three-line cue: with a two-line cue and 125 pt the button ran off the screen. The shipped cue for Machine Chest Press (`figures.json`) is "Handles at mid-chest. Press out, control the way back."
- `figures.json`'s `exercises` still keys the figure under `machine-chest-press-or-flat-bench`; the code maps the old id, so nothing breaks, but the next drop should key it `machine-chest-press`.
- The complication shows the session's state (Start workout, "Up next" with the next item, "Done") through an app group, `group.com.yeshu.RepCoach`, on the watch app and the complication. No board draws it; `W62` is the first sketch. Tapping it follows `OpenFromOutside` (decided in Core, with tests).
- Between ramp-ups the rest still says "4 reps · not counted" (information, not a reason).
- While the workout is paused, a running rest shows "Paused" in amber in place of the heart rate.
- Swap is offered only for an exercise nothing has been logged on (ramp-ups don't count).
- The session also keeps time, energy and average heart rate (for the Finished card and the phone's History), and every Health workout saved for it (for Discard).
- Not shot: 3.5 (withdrawn) and `F133-PlanFigures` (the Designer's own sheet).

## Next

1. **Edge-timer corners.** Open bug on the real Series 10 46 mm: the rest screen's edge line (`Apps/Watch/Style/EdgeTimer.swift`) is cut off at the screen corners. Build and board 3.1A match to the pixel (5 pt line, outer edge 2 pt from the frame, outer corner radius about 47 pt). Simulator screenshots are unmasked rectangles, so they can't show glass clipping, and no public watchOS API returns the display's corner radius. No guessed radius. Wait for the owner's straight-on close-up photo of the rest screen (two corners). If it is ambiguous, build a throwaway calibration screen (hairlines at 0, 2, 4.5 pt inset) as a separate build, only with the owner's OK, never merged to `main`. If the glass hides more than about 2 pt, move the whole line inward and keep the 5 pt weight and the 18% track. Does not block build 9.
2. **iPhone handoff** (look B, Today screens approved; the Swap UI on the phone). Comes from the Designer after build 9.

## Waiting

- The owner's edge-timer photo.
- The owner's check on the real watch: the effort shows on the workout in Fitness (the watch asks for that Health permission once more), and the controls page icons no longer start small and grow.
- Nothing is pushed or merged without the owner's OK.

## Log

- 2026-10-06: watch redesign (build 7) passed the Designer's check on `watch-redesign-1`.
- 2026-10-07: merged to `main` as build 8 (`f288823`). Designer's watch-2 handoff arrived at `2d59549`; build 9 built on `watch-build-9`.
