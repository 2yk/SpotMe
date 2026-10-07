# Status

Kept by the builder session ("SpotMe - Frontend (Mac Studio)"). Read by `/next`. Update it with the work.

## Now

**Watch build 9 passed the Designer's check** (7 Oct, `design/reviews/11-build-watch-2.md`) and is on `main` (`bbba61d`); the owner installs it from Xcode (`xcodegen generate`, run the RepCoach scheme with the watch paired; if Xcode complains about the App Group `group.com.yeshu.RepCoach`, add App Groups on the RepCoachWatch and RepCoachWidgets targets).

**Build 10 (branch `watch-build-10`, not pushed)** holds the Designer's three small notes from that check: the How sheet's name at full row size, the break's short name on one line with 14 pt sides, and the old-id figure fallback dropped (the bundle has both ids). Screenshots of the three screens are in `design/built/watch-3/`. The How sheet shows its hint and the seven turn dots only while the Crown turns (Designer, 7 Oct); at rest it shows the cue. Waits for more notes before it is worth a push.

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
