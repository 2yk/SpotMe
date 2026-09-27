# RepCoach · Product Spec

A personal watchOS + iOS strength logger for one user (Yeshu). It runs his v11 muscle-gain plan, logs weight and reps per set on the Apple Watch, and tells him what weight to use for the next set and the next session.

Not an App Store product. No accounts, no analytics, no third-party dependencies.

## Who and where

- Trains early morning in a commercial gym in India. Phone stays in the bag; **the watch is the only screen during a session.**
- Apple Watch + iPhone, paid Apple Developer account.
- Runs are handled by Nike Run Club. In this app, runs are just checklist items.
- Units: kg only.
- Back injury history: the plan is spine-safe. Never suggest exercises that are not in the plan.

## The plan

- Source of truth: `Packages/RepCoachCore/Sources/RepCoachCore/Resources/plan.json` (7 days, 77 items).
- Days map to weekdays (Mon = Pull A … Sat = full rest, Sun = long run + mobility + core).
- Item kinds (`ItemKind`):

| Kind | Logged as | Example |
|---|---|---|
| `checklist` | Tap done. Show `steps` or `note` | Recovery Run, Warmup, Cooldown, Neck |
| `weighted` | Weight + reps per set | Incline DB Press 4 × 6–10 |
| `reps` | Reps per set; weight optional if `loadable` | Hanging Leg Raise 3 × 8–12 |
| `timed` | Seconds per set (built-in timer); weight optional if `loadable` | Weighted Plank 3 × 30–45s |
| `amrap` | Reps, one set | Thursday Max-Rep Set |
| `percentOfMax` | Reps; target = 60% of today's AMRAP | Thursday Volume Sets |

- `perSide: true` means the logged reps are per side; show "/side" next to the number.
- `supersetGroup`: items sharing a group alternate A1 → B1 → rest → A2 → B2 …

## Progression rules (implemented in `ProgressionEngine`, already tested)

**Starting a weighted exercise (double progression)**
1. No history → ask for a starting weight (Digital Crown), reps target = rep range.
2. Every set of the last session hit the top of the rep range at the same weight (for `sessionsAtTopToProgress` sessions, 2 for weighted pull-ups) → **add one increment**.
3. The last two sessions at this weight both missed (a set under the range, a mid-session drop, or fewer sets) → **drop ~10%, at least one increment**.
4. Otherwise → **same weight, aim to add reps**.
5. Deload week (every 6th week from the program start date, or toggled manually) → half the sets (rounded up), weight × 0.85 rounded to the nearest increment. Deload sessions are saved but excluded from progression history.

**Between sets**
- Reps below the range → next set lighter: 5% per missing rep, capped at 20%, always at least one increment, rounded down to the increment.
- Reps 3+ above the top of the range and not the last set → next set one increment heavier.
- Otherwise → same weight.
- Show the reason in one short line, e.g. "6 reps, below 8 · drop to 17.5 kg" or "Too light · 22.5 kg next".

**Pull-up endurance (Thursday):** volume-set reps = round(0.6 × today's max-rep set). If today's AMRAP isn't logged yet, use the last one.

**`reps` and `timed` kinds:** no automatic weight changes. When every set reaches the top of the range, show "Top of range. Add weight or make it harder next time."

Increments come from `plan.json` (DB 2.5, DB lateral 1, cables 2.5, machines 5, leg press 10, hip thrust 5, weighted pull-up 2.5). They are editable per exercise on the iPhone.

## Watch app

**Today**
- Opens on today's weekday. Crown scrolls. A small toggle reaches other days.
- Top: "Up next" card with the item name, the prescription and today's target weight (e.g. "4 × 6–10 · 22.5 kg · +reps").
- Below: remaining items in order. Finished items move to the bottom, dimmed with a checkmark (same behaviour as his web tracker).
- Tapping any remaining item makes it "up next" (for when a machine is busy). Swipe action: Skip.
- Progress: "7 / 15" in the navigation bar.

**Set screen (weighted / reps)**
- Header: "Set 2 of 4" and the rep range.
- Two big values: **weight** and **reps**, prefilled with the target. Tap a value to focus it; the Digital Crown changes it (weight by the exercise increment, reps by 1). Haptic click per step.
- Large **Log set** button. Undo for the last logged set.
- After logging: engine `nextSet` → rest screen.

**Rest screen**
- Countdown from `restSec` (supersets: rest only after the second exercise).
- Shows the next set's target and the one-line reason.
- Haptics at 10 s left and at 0. Buttons: +30 s, Skip.
- The heart rate from the running workout session is shown small at the top.

**Timed sets:** Start → counts up with a haptic at `secMin` and `secMax` → Stop logs seconds.

**Checklist items:** one tap to done. Warmups show their steps as a scrollable list.

**Exercise finished:** a one-line summary ("All sets 10 · next time 22.5 kg" or "Same weight next time · aim for more reps"), then back to Today.

**Workout session (HealthKit)**
- Starts an `HKWorkoutSession` (`.traditionalStrengthTraining`, indoor) when the first set of the day is logged, or from a Start button.
- Keeps the app frontmost during the session, collects heart rate and energy, and saves the workout to Health when ended.
- End from Today ("Finish workout") or automatically offered when every item is done.
- Must survive the wrist dropping and the screen sleeping (Always On shows the rest timer).

## iPhone app

- **Today:** same list, read-mostly (useful for checking the day before training).
- **History:** per exercise, sessions newest first with every set. A Swift Charts line of top-set weight and estimated 1RM (Epley) over time.
- **Plan:** view all days; edit per exercise: increment, rep range, sets, rest, starting weight. "Reset to bundled plan" keeps history.
- **Settings:** program start date (drives deload weeks), "This week is a deload" toggle, rest timer haptics on/off.
- **Body log (optional, milestone 4):** flexed arm and waist, every 2 weeks. Warn if waist is up more than 1 inch while arms haven't changed.

## Data and sync

- SwiftData on both devices.
- Models: `WorkoutSession` (id UUID, date, weekday key, isDeload, healthKitWorkoutId?), `ExerciseLog` (session, exerciseId, order, completedAt?), `SetLog` (log, index, weight, reps, seconds?, timestamp), `ExerciseSettings` (exerciseId, overrides for increment/rep range/sets/rest/startWeight).
- **The watch works fully without the phone nearby.** It keeps its own store and the history it needs for targets.
- WatchConnectivity:
  - Watch → phone: each finished `WorkoutSession` (with its logs) via `transferUserInfo` (queued, delivered later). The phone de-duplicates by session UUID.
  - Phone → watch: plan overrides and settings via `updateApplicationContext`. The watch applies them at the next session start.
- Nothing is deleted automatically.

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
