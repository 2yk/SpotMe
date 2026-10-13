# Status

Kept by the builder session ("SpotMe - Frontend (Mac Studio)"). Read by `/next`. Update it with the work.

## Now

**iPhone build 1 (build 11) is built, on branch `iphone-build-11`, not pushed.** The Designer's handoff `design/handoff/iphone-1/BUILD.md` (13 Oct): Swap on the phone first, then every approved iPhone screen in look B, with watch build 10 inside. All of it is in: Today (7.1–7.6), the exercise sheet with the progress chart (7.5, 7.7), the Swap sheet (7.8) with the live sync to the watch (checked on paired simulators: Today list, a set screen with nothing logged, a break; frames in `design/built/iphone-1/sync/`), History as sessions with one session and one exercise (8.1–8.3, 8.7, 8.2), Body with ten points and the measurement sheet (8.4–8.6, 8.8), Plan with Rearrange days (9.1–9.6, an agent built these on `iphone-plan-settings`, merged) and Settings (10.1). Screenshots named by board are in `design/built/iphone-1/`. Tests: `swift test` 219 passed; the watch UI tests (21) passed; the iOS scheme (with the watch app) builds in Debug and Release.

Start workout on the phone asks the watch to start (`HKHealthStore.startWatchApp`; the watch handles it like the complication's start link): only a real watch can show it works.

Phone screenshots: `Scripts/phone-shot.sh <Board> <launch args>` on the "SpotMe iPhone 16 Pro Max" simulator (its own, paired with "SpotMe Watch 46mm", so other sessions' apps stay out of the shots).

## Next

1. **Edge-timer corners.** Open bug on the real Series 10 46 mm: the rest screen's edge line (`Apps/Watch/Style/EdgeTimer.swift`) is cut off at the screen corners. Build and board 3.1A match to the pixel (5 pt line, outer edge 2 pt from the frame, outer corner radius about 47 pt). Simulator screenshots are unmasked rectangles, so they can't show glass clipping, and no public watchOS API returns the display's corner radius. No guessed radius. Wait for the owner's straight-on close-up photo of the rest screen (two corners). If it is ambiguous, build a throwaway calibration screen (hairlines at 0, 2, 4.5 pt inset) as a separate build, only with the owner's OK, never merged to `main`. If the glass hides more than about 2 pt, move the whole line inward and keep the 5 pt weight and the 18% track. Does not block build 9.
2. **iPhone handoff** (look B, Today screens approved; the Swap UI on the phone). Comes from the Designer after build 9.

## Waiting

- **Build 12 (branch `iphone-build-12`, off build 11) holds the Designer's five small fixes of 13 Oct** (`design/reviews/13-build-iphone-1.md`): Today in a deload week with the body log due (7.4), the done card's line is the session's numbers (7.3), the hero figure at the hero's bottom right (7.1–7.3), inch values without a space before ″ (8.6, 8.8), and From the plan lists exercises only (9.5). Screenshots in `design/built/iphone-2/`. Approved by the Designer on 13 Oct (`design/reviews/13-build-iphone-1.md`, round 2); it comes to the owner for his install and testing, instead of build 11, which it contains.

- **The Designer's check of build 11** (the owner's rule, 13 Oct 2026: the Designer approves first, then the build comes to the owner for his device install and testing). The screenshots are in `design/built/iphone-1/` on branch `iphone-build-11`, pushed for the Designer's check on 13 Oct (the owner OK'd it, and review branches are pushed without asking from now on).
- After the Designer approves: the owner's try-out of build 11 on the phone and watch: Swap from the phone (the watch changes within a second or two), Start workout from the phone, Rearrange days (the watch's Today and complication follow), the body log keeps his arm and waist (the phone logs how many rows at first launch, `bodyMigrationReport`).
- Which build is on the owner's watch: Swap is in watch builds 9 and 10 only (swipe left on an open row in Today; the small figure on a set or break screen → How → Swap exercise).
- Nothing is pushed or merged without the owner's OK.

## Log

- 2026-10-06: watch redesign (build 7) passed the Designer's check on `watch-redesign-1`.
- 2026-10-07: merged to `main` as build 8 (`f288823`). Designer's watch-2 handoff arrived at `2d59549`; build 9 built on `watch-build-9`.
