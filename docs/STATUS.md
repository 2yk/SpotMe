# Status

Kept by the builder session ("SpotMe - Frontend (Mac Studio)"). Read by `/next`. Update it with the work.

## Now

**iPhone build 1 (build 11), branch `iphone-build-11`, not pushed.** The Designer's handoff `design/handoff/iphone-1/BUILD.md` (13 Oct): Swap on the phone first, then every approved iPhone screen in look B, with watch build 10 inside. Done so far: Today in look B (7.1–7.4, 7.6), the exercise sheet with the progress chart (7.5, 7.7), the Swap sheet (7.8) and the live sync to the watch (checked on paired simulators: Today list, a set screen with nothing logged, a break; screenshots in `design/built/iphone-1/sync/`). Start workout on the phone asks the watch to start (`startWatchApp`; the watch handles it like the complication's start link). Still to build: History and Body (8.x), Plan and Rearrange days (9.x), Settings (10.1), and the section 9 check of Swap on the owner's watch.

Phone screenshots: `Scripts/phone-shot.sh <Board> <launch args>` on the "SpotMe iPhone 16 Pro Max" simulator (its own, paired with "SpotMe Watch 46mm", so other sessions' apps stay out of the shots).

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
