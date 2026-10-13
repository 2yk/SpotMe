# Status

Kept by the builder session ("SpotMe - Frontend (Mac Studio)"). Read by `/next`. Update it with the work.

## Now

**Build 13 = plan 12 and a figure for every swap, on branch `plan-12-build-13`** (the Designer's handoff `design/handoff/plan-12/BUILD.md`, 13 Oct). It is built on `iphone-build-12`, not on `main`, because `main` doesn't hold the iPhone builds yet: merging build 13 merges build 12 with it. In it:

- **Plan v12** (`plan.json` and `exercises.json` from the handoff): Friday Legs B, Saturday Push B, Sunday Full Rest, Wednesday opens with Barbell Bench Press, Thursday has Seated Cable Row, Tuesday Weighted Plank (3 × 30–45s, Core). Plan 11's Long Run + Mobility + Core B left the week. Tests that pinned plan 11's days now pin plan 12's (day keys, item counts, Full Rest on Sunday, the bench leads Wednesday's ramp-up roles); no engine rule or engine expectation changed.
- **Day keys moved, and what was stored under them follows** (`PlanKeyMigration`; SPEC, "A plan day maps a weekday to a workout"). A "friday" session of Push B's exercises becomes "saturday" and a "saturday" session of Full Rest becomes "sunday", judged by what was logged, so it is safe to repeat and to run on a session from a device still on plan 11. Plan 11's Sunday sessions keep "sunday", and History calls them "Long Run + Mobility + Core B". `PlanEdits.planKeys` (none = 11) moves edited lists with their workout, replaces the Copenhagen plank and the single-arm row in place, puts the barbell bench ahead of the incline press on an edited Wednesday, drops other removed exercises and resets a Rearrange days mapping made on plan 11. `friday-warmup` and `friday-cooldown` are renamed `saturday-…` (`ExerciseIdRenames`). It runs at launch on both devices and on each session or plan the other device sends; the counts are logged and kept in `planKeyMigrationReport`.
- **Figures by database id.** `Resources/figures.json` is the Designer's bundle (180 figures under 192 ids, 226 KB; decoding takes about 50 ms on the Mac in a Debug test, once, on first use). A swapped-in item already carries its database id, so every figure lookup finds its figure, and `FigureLibrary.figure(forExercise:)` also tries the database's other ids for the same exercise. The Swap sheet's rows show each choice's 44 pt still. Tests: every plan lift and every Swap choice has a figure. The four stability-ball figures draw as round discs.
- **Checks.** `swift test` 233 passed; the watch UI tests (21) passed on "SpotMe Watch 46mm"; the iOS scheme (with the watch app) builds in Debug and Release. Screenshots named by board are in `design/built/plan-12/`: watch 46 and 42 mm, phone, and `sync/` (a watch set screen follows a swap made on the phone to Machine Lateral Raise, which had no figure before).
- Debug only: `-swapTo <database id>` on both demos swaps the `-item` before the screen opens. `Scripts/watch-boards.sh` uses plan 12's days.

Start workout on the phone asks the watch to start (`HKHealthStore.startWatchApp`): only a real watch can show it works.

Phone screenshots: `Scripts/phone-shot.sh <Board> <launch args>` on the "SpotMe iPhone 16 Pro Max" simulator (its own, paired with "SpotMe Watch 46mm", so other sessions' apps stay out of the shots). A paired sync check needs `-sync YES` on both apps (the demo keeps sync off otherwise). A "Watch 42" simulator (Series 12, 42 mm) was made on 13 Oct for the 42 mm boards.

## Next

1. **Edge-timer corners.** Open bug on the real Series 10 46 mm: the rest screen's edge line (`Apps/Watch/Style/EdgeTimer.swift`) is cut off at the screen corners. Build and board 3.1A match to the pixel (5 pt line, outer edge 2 pt from the frame, outer corner radius about 47 pt). Simulator screenshots are unmasked rectangles, so they can't show glass clipping, and no public watchOS API returns the display's corner radius. No guessed radius. Wait for the owner's straight-on close-up photo of the rest screen (two corners). If it is ambiguous, build a throwaway calibration screen (hairlines at 0, 2, 4.5 pt inset) as a separate build, only with the owner's OK, never merged to `main`. If the glass hides more than about 2 pt, move the whole line inward and keep the 5 pt weight and the 18% track.
2. **Small, not blocking** (the Designer, 13 Oct): Plan rows say "/side" where the plan's display says "/leg" (Reverse Lunge, Bulgarian split squat); it predates build 13. Wants a look at `Format` and the Plan row text, and the Designer's word on which one it should be.

## Waiting

- **The owner's OK to install build 13 on his devices.** The Designer approved it on 13 Oct (`design/reviews/14-build-plan-12.md`, ae8cbe3), which is the owner's rule satisfied for asking him, not his OK to release: it migrates his real store, so it waits for his word. Branch `plan-12-build-13` is pushed for the check; nothing is merged.
- **The owner's try-out of build 12**, installed on his iPhone on 13 Oct (Release, SpotMe 1.0 (12), `devicectl device install app`; the embedded watch app installs through the iPhone's Watch app, not confirmed from here). Build 13 contains it. He tries: Swap from the phone (the watch changes within a second or two), Start workout from the phone, Rearrange days (the watch's Today and complication follow), the body log keeps his arm and waist (`bodyMigrationReport`).
- After build 13 is on his devices: read `planKeyMigrationReport` (and the "Moved workout keys" log line) to tell the Designer what was moved, edited, dropped or reset in his real store. Nothing could be checked from here: his data is on the devices.
- Which build is on the owner's watch: Swap is in watch builds 9 and 10 only (swipe left on an open row in Today; the small figure on a set or break screen → How → Swap exercise).
- Nothing is merged to `main`, and `main` is never pushed, without the owner's OK.

## Log

- 2026-10-06: watch redesign (build 7) passed the Designer's check on `watch-redesign-1`.
- 2026-10-07: merged to `main` as build 8 (`f288823`). Designer's watch-2 handoff arrived at `2d59549`; build 9 built on `watch-build-9`.
- 2026-10-13: iPhone builds 11 and 12 passed the Designer's check (`design/reviews/13-build-iphone-1.md`); build 12 installed on the owner's iPhone. The plan 12 handoff arrived (5544406, figures a9cdf40); build 13 built on `plan-12-build-13`.
