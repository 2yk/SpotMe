# RepCoach · Product Spec

A personal watchOS + iOS strength logger for one user (Yeshu). It runs his v11 muscle-gain plan, logs weight and reps per set on the Apple Watch, and tells him what weight to use for the next set and the next session.

Not an App Store product. No accounts, no analytics, no third-party dependencies.

## Who and where

- Trains early morning in a commercial gym in India. Phone stays in the bag; **the watch is the only screen during a session.**
- Apple Watch + iPhone, paid Apple Developer account.
- Runs are handled by Nike Run Club and don't appear in this app. `plan.json` still lists them (as checklist items in "Run · NRC …" groups); the apps leave them out.
- Units: kg only.
- Back injury history: the plan is spine-safe. Never suggest exercises that are not in the plan.

## The plan

- Source of truth: `Packages/RepCoachCore/Sources/RepCoachCore/Resources/plan.json` (7 days, 77 items).
- Days map to weekdays (Mon = Pull A … Sat = full rest, Sun = long run + mobility + core).
- Item kinds (`ItemKind`):

| Kind | Logged as | Example |
|---|---|---|
| `checklist` | Tap done. Show `steps` or `note` | Warmup, Cooldown, Neck, Mobility |
| `weighted` | Weight + reps per set | Incline DB Press 4 × 6–10 |
| `reps` | Reps per set; weight optional if `loadable` | Hanging Leg Raise 3 × 8–12 |
| `timed` | Seconds per set (built-in timer); weight optional if `loadable` | Weighted Plank 3 × 30–45s |
| `amrap` | Reps, one set | Thursday Max-Rep Set |
| `percentOfMax` | Reps; target = 60% of today's AMRAP | Thursday Volume Sets |

- `perSide: true` means the logged reps are per side; show "/side" next to the number.
- `supersetGroup`: items sharing a group alternate A1 → B1 → rest → A2 → B2 …

## Progression rules (implemented in `ProgressionEngine`, already tested)

**A session's working weight** is the weight of its first set, or a heavier one reached during it with at least the bottom of the range (the app raised it after a set that was too light, or it was changed by hand). A heavier attempt that fell short of the range doesn't count. The rules below look at the planned number of sets.

**Starting a weighted exercise (double progression)**
1. No history → ask for a starting weight (Digital Crown), reps target = rep range.
2. Every set of the last session reached the top of the rep range without going back under its working weight (for `sessionsAtTopToProgress` sessions at the same working weight, 2 for weighted pull-ups) → **working weight + one increment**.
3. The last two sessions at this working weight both missed (a set at or under it below the range, a drop under it, or fewer sets) → **drop ~10%, at least one increment**.
4. Otherwise → **the last working weight, aim to add reps**. A raise within a session carries over to the next one.
5. Deload week (every 6th week from the program start date, or toggled manually) → half the sets (rounded up), weight × 0.85 rounded to the nearest increment. Deload sessions are saved but excluded from progression history.

**Between sets**
- Reps below the range → next set lighter: 5% per missing rep, capped at 20%, always at least one increment, rounded down to the increment.
- Reps 2+ above the top of the range and not the last set → the weight felt light, so the next set is heavier: the weight this set's effort would lift for the top of the range (Epley), rounded down to the increment; at least one increment, at most two.
- Otherwise → same weight.
- Show the reason in one short line: "6 reps, below 8 · drop to 17.5 kg", "14 reps, above 12 · up to 22.5 kg", "Top of range · stay at 20 kg" or "In range · stay at 20 kg".

**Pull-up endurance (Thursday):** volume-set reps = round(0.6 × today's max-rep set). If today's AMRAP isn't logged yet, use the last one.

**`reps` and `timed` kinds:** no automatic weight changes. When every set reaches the top of the range, show "Top of range. Add weight or make it harder next time."

Increments come from `plan.json` (DB 2.5, DB lateral 1, cables 2.5, machines 5, leg press 10, hip thrust 5, weighted pull-up 2.5). They are editable per exercise on the iPhone.

## Watch app

**Today**
- Opens on today's weekday. Crown scrolls. A small toggle reaches other days.
- Top: one big button, **Start workout**, or **Continue** with what's next once the day has started (with the running Health workout's heart rate and time above it). Nothing else is highlighted.
- Below: the open items in plan order, each with its prescription and target ("4 × 6–10 · 22.5 kg"). Finished items move to the bottom, dimmed with a checkmark (same behaviour as his web tracker).
- Tapping any open item does it now (for when a machine is busy); the workout then carries on from there. Swipe actions: Skip, and Done for checklist items.
- At the end: **Finish workout** and **Discard workout**.
- Progress: "7 / 15" in the navigation bar.

**Workout flow**
- Start workout (or Continue) opens the next open item in plan order; one already started comes first. The workout then moves through the day by itself.
- After an exercise's last set: a break as long as its rest (15 s before a checklist item) showing the next item and its target, and how the finished exercise went; when it runs out, the next item starts. +30 s, start now (the ▶ button or the ring itself), or tap the next item's name to pick another to do first (the break waits while the list is open).
- Checklist items (warmup, neck, cooldown) show their steps with Done and Skip, then move on.
- When everything is done: "All done" with Finish workout. Back always returns to Today.
- Pages, as in Apple's Workout app: swipe right for the **controls**, left for **Now Playing** (the system player: play, pause, skip, volume on the Crown, for music on the watch or the iPhone).
- Controls: **Pause/Resume**, **End** (asks Save to Health / Don't save / Keep going), **Skip** and **List** (back to Today). Under them: "Skip to …", where Skip leads.
  - Pause stops the Health workout's time and heart rate, the rest and the break; they carry on from where they stopped. Logging a set or starting a hold resumes. Today shows the workout as paused, and so does a paused Health workout picked up after a relaunch.
  - Skip moves on now: the exercise on screen keeps what's logged (it's skipped if nothing is), a checklist item is skipped, and a break ends early.

**Set screen (weighted / reps)**
- Header: "Set 2 of 4" and the rep range.
- Two rows: **weight** and **reps**, prefilled with the target, each with − and + (exactly one step per tap: the exercise increment, or 1 rep). Tap a value to focus it; the Digital Crown then moves it one step per click, with a haptic, counting from the value shown (never an in-between or re-rounded value).
- Large **Log set** button. Undo for the last logged set.
- After logging: engine `nextSet` → rest screen.

**Rest screen**
- Countdown from `restSec` (supersets: rest only after the second exercise). The ring and the time are drawn from one clock, so they always agree: 15 times a second on screen, every second in Always On.
- Shows the next set's target and the one-line reason.
- Haptics at 10 s left and at 0. Buttons: +30 s, Skip.
- The heart rate from the running workout session is shown small at the top.

**Timed sets:** Start → counts up with a haptic at `secMin` and `secMax` → Stop logs seconds.

**Checklist items:** Done or Skip in the workout; one swipe to done in the list. Warmups show their steps as a scrollable list.

**Exercise finished:** a one-line summary ("All sets 10 · next time 22.5 kg" or "Next time 20 kg · aim for more reps") on the break screen before the next item.

**Workout session (HealthKit)**
- Starts an `HKWorkoutSession` (`.traditionalStrengthTraining`, indoor) with Start workout, or when an exercise is opened, while today's session isn't finished. It keeps the app running with the wrist down, so rests and breaks end on time with their haptics.
- "Save workouts to Health" (iPhone Settings) decides what happens to it: on, Finish asks whether to save it; off, it's always thrown away and nothing reaches Health (for a session logged after the fact). With the switch off the watch never asks for Health access; the workout runs only if access was already given.
- Health access belongs to the watch app: watchOS asks on the watch the first time, and it's changed later in the iPhone's Health app (profile picture → Apps → SpotMe). If saving workouts isn't allowed, Start workout says so and where to fix it; starting by itself stays quiet. The watch reports its access to the phone, whose Settings show it.
- Keeps the app frontmost during the session, collects heart rate and energy, and saves the workout to Health when ended.
- End from Today ("Finish workout") or automatically offered when every item is done. Finishing asks whether to save the workout to Health or not; the sets are kept either way.
- **Discard workout** deletes everything logged today, on the watch and the phone, and doesn't save the Health workout.
- Must survive the wrist dropping and the screen sleeping (Always On shows the rest timer).

**Complication ("Start workout")**
- Circular, corner, rectangular and inline. Shows today's session from the plan ("Pull A · Strength & Thickness"; "Rest day" on Saturday), refreshed at midnight. The mark is drawn (watch faces drop large images), its dot in the face's accent colour.
- Tapping it opens SpotMe on today and starts the workout, as Start workout does; on a rest day it only opens the app.

## iPhone app

- **Today:** the day's card and the same list, read-mostly (useful for checking the day before training). Nothing is highlighted.
- **History:** per exercise, sessions newest first with every set. A Swift Charts line of top-set weight and estimated 1RM (Epley) over time.
- **Plan:** view all days as the user has them. Tap an exercise to rename it or change its increment, rep range, sets, rest and starting weight (a new name shows everywhere the exercise does), or remove it from the day. Swipe to remove; Edit to reorder; **Add exercise** (+) for a new one (name, logged as weight and reps, reps, timed or tick-off, section, prescription) or one from another day, which keeps its history. Added exercises go after the day's last exercise, ahead of the cooldown. "Reset Monday to the plan" and "Reset everything to the plan" keep history, and the user's own exercises stay defined (Add exercise → From the plan brings one back; a new exercise never reuses an id with history). plan.json never changes.
- **Settings:** program start date (drives deload weeks), "This week is a deload" toggle, rest timer haptics on/off, "Save workouts to Health" on/off (off: nothing reaches Health), the watch's Health access and a shortcut to the Health app.
- **Body log (optional, milestone 4):** flexed arm and waist, every 2 weeks. Warn if waist is up more than 1 inch while arms haven't changed.

## Data and sync

- SwiftData on both devices.
- Models: `WorkoutSession` (id UUID, date, weekday key, isDeload, healthKitWorkoutId?), `ExerciseLog` (session, exerciseId, order, completedAt?), `SetLog` (log, index, weight, reps, seconds?, timestamp), `ExerciseSettings` (exerciseId, overrides for name/increment/rep range/sets/rest/startWeight), `PlanEditsRecord` (the user's `PlanEdits`: each changed day's exercise order, and the exercises they created, with ids starting "custom-").
- **The watch works fully without the phone nearby.** It keeps its own store and the history it needs for targets.
- WatchConnectivity:
  - Watch → phone: each finished `WorkoutSession` (with its logs) via `transferUserInfo` (queued, delivered later). The phone de-duplicates by session UUID.
  - The watch's own application context (`WatchStatus`): its Health access, the ids of every session it has, and the ids it discarded. The phone deletes discarded sessions and never stores them again, and sends back (via `transferUserInfo`) every session the watch doesn't have, so a reinstalled watch app gets its history and today's progress back. A restored copy never overwrites a session the watch has.
  - Phone → watch: settings, exercise overrides and plan edits via `updateApplicationContext`. The watch applies them at the next session start, except the Health switch, which moves no targets and applies at once.
- Nothing is deleted automatically; only Discard workout deletes.

## Out of scope

- Running (NRC does it), social features, the App Store, iCloud accounts, pounds.

## Acceptance checks (run on a real watch before calling it done)

1. Monday: weighted pull-ups, first time → asks for weight; log 5 sets of 5 at 15 kg twice across two Mondays → the third Monday suggests 17.5 kg.
2. Incline DB Press at 22.5 kg, log 5 reps (range 6–10) → the rest screen says drop to 20 kg.
3. Finish an exercise → it moves to the bottom of Today and the next item is on top.
4. Tap a later item → it becomes "up next".
5. Thursday: log AMRAP 12 → volume sets prefill with 7 reps.
6. Friday superset: Bayesian Curl and Overhead Extension alternate, with rest after each pair.
7. Leave the phone in the bag (Bluetooth off) for a whole session → everything logs; turn Bluetooth on → the session appears in iPhone History.
8. The workout appears in the Health app as Traditional Strength Training with heart rate.
9. Set the program start date so today is week 6 → targets show deload (half sets, ~85% weight).
