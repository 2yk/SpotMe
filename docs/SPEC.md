# RepCoach · Product Spec

A personal watchOS + iOS strength logger for one user (Yeshu). It runs his v11 muscle-gain plan, logs weight and reps per set on the Apple Watch, and tells him what weight to use for the next set and the next session.

Not an App Store product. No accounts, no analytics, no third-party dependencies.

## Who and where

- Trains early morning in a commercial gym in India. Phone stays in the bag; **the watch is the only screen during a session.**
- Apple Watch + iPhone, paid Apple Developer account.
- Runs are handled by Nike Run Club and don't appear in this app. `plan.json` still lists them (as checklist items in "Run · NRC …" groups); the apps leave them out.
- Units: kg only.
- Back injury history: the plan is spine-safe. **Swap** offers the exercise database's alternatives (`design/exercise-db/`, shipped as `exercises.json`), leaves out any rated 3 ("avoid") for one of the user's injury areas (`TrainingSettings.injuryAreas`, the lower back for now) and flags a 2 "Take care".

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

- One exercise per slot: Wednesday's chest slot is **Machine Chest Press** (`machine-chest-press`, the database's id), not "Machine Chest Press (or Flat Bench)". Everything stored under the old id counts as Machine Chest Press: on first launch of watch build 9 (and of the matching phone build) `IdMigration` renames the id in exercise logs, per-exercise settings, plan edits and the day's put-off and ramp-up marks (idempotent; the count is logged once, "Renamed exercise ids: 12 sets in 4 logs"). A session that arrives from a device that still has the old id is stored under the new one (`ExerciseIdRenames`). To use a different exercise for a day, use Swap.
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
- The engine still words the reason ("6 reps, below 8 · drop to 17.5 kg", "14 reps, above 12 · up to 22.5 kg", "Top of range · stay at 20 kg", "In range · stay at 20 kg"), and History and the CSV can use it. **The watch never shows it:** weights move by themselves; the rest screen only shows the next weight with an up or down arrow.

**Ramp-up sets (`ProgressionEngine.rampUps`, reference in `docs/engine_reference.py`):** one or two lighter, short sets before the first working set, so the session doesn't start cold at last time's limit. The working sets, their weight and "beat last time" are unchanged.
- A **main lift** is a weighted exercise with 2:00 or more of rest. The first main lift in the day's plan order gets two ramp-ups (50% × 8, then 75% × 4); every other main lift gets one (70% × 5). Smaller lifts get none, or one at 70% × 5 with the setting "Every weighted lift".
- Weight = today's working weight (set 1's target, the deload weight in a deload week) × the factor, rounded down to the increment. A set that rounds to zero, to no more than the one before it, or to the working weight is left out. Reps never go above the top of the rep range. No working weight yet (first time): none.
- An exercise whose logged weight is added to bodyweight (`bodyweightBase` on the plan item; the weighted pull-ups): bodyweight × 5 (weight 0), and for the day's first main lift a second at half the added weight × 3.
- Rest after a ramp-up set is 60 s (`ProgressionEngine.restAfterRampUpSec`).
- **Ramp-up sets are never counted:** not in "Set 2 of 4" or an item's status (an exercise with only ramp-ups logged is still pending), not in set counts, last-time numbers, progression history or charts. They are saved (marked) and exported.

**Pull-up endurance (Thursday):** volume-set reps = round(0.6 × today's max-rep set). If today's AMRAP isn't logged yet, use the last one.

**`reps` and `timed` kinds:** no automatic weight changes. When every set reaches the top of the range, show "Top of range. Add weight or make it harder next time."

Increments come from `plan.json` (DB 2.5, DB lateral 1, cables 2.5, machines 5, leg press 10, hip thrust 5, weighted pull-up 2.5). They are editable per exercise on the iPhone.

## Watch app

The look: one accent. Volt is what to tap and the value the Crown moves; ice means waiting (rest, break, ramp-up, an exercise put off), mint done, ember lighter than planned, red heart rate and Stop/End/Discard, amber paused. SF Rounded with tabular digits, designed for the 46 mm watch (208 × 248 pt); the 42 mm scales every size by 0.9 with one factor (`Metrics.scale`). The system's bar stays (the clock); the bar holds a short coloured title and nothing else, and the exercise's name is in the content. **Workout screens have no back button** (set, ramp-up, rest, break, holds, tick-off items, controls, All done); the controls page's **List** is the way to Today. Sheets (How, Swap, Days, End, Discard, Summary, Effort, Health alert) keep their close button. The title sits at the clock's line, 22 pt from the left; on the edge-timer screens (break, holds) it is drawn as content 26 pt from the left and 5 pt lower, clear of the line. A rest has no title. Tokens and sizes: `design/handoff/watch-1/BUILD.md`, section 3.

**Today**
- Opens on today's weekday. Crown scrolls. The day's name opens the list of days.
- Top: the day, its name and what it trains, then one big button, **Start workout**, or **Continue** with what's really next once the day has started (with the running Health workout's heart rate and time above it). A rest day (Saturday) has no button. Nothing else is highlighted.
- Below: the open items in plan order, each with its prescription on the left and today's target weight on the right ("4 × 6–10", "22.5 kg"). An up arrow in volt before the weight when today's target is above the last working weight, a down arrow in ember when it is lower or a deload; both come from the engine's own reason for the target. Finished items move to the bottom, dimmed with a check.
- Tapping any open item does it now (for when a machine is busy); the workout then carries on from there. Swipe actions: **Skip today** (drops the item for the day; its row then says "Skipped · tap to do it", and a tap reopens it and starts it), **Swap** (see below) and Done for checklist items.
- A swapped exercise's row has the swap icon before its prescription ("⇄ 3 × 8–10"), and "First time" in volt on the right when it has no history of its own.
- **Finished.** After any Finish (the End sheet, Today's Finish workout, All done) the day is finished, whatever is left. Today then shows: the day line ("WEDNESDAY · PUSH A", opens the days); a **Finished** card (a mint check, "48 min · Hard 7", or "48 min · 342 kcal" without an effort; a tap opens the summary); when items are left a neutral **Start again** button ("3 left"), then NOT DONE with the open rows in plan order (no weights), then DONE, then Discard workout. With nothing left there is no Start again. The bar title ("12/15") is mint. There is no Continue and no Finish workout.
- **Start again** (or a tap on a NOT DONE row, which starts on that row) reopens the same session: done items stay done, a new Health workout starts, the next open item opens as Start workout would, and Today is back in its running state. Finishing again saves a second Health workout (the session adds up their time, energy and average heart rate), asks the effort again starting from the first answer, and keeps the new answer. The phone gets the session again (same UUID).
- **Discard workout** after a Finish deletes today's sets, here and on the phone, and every Health workout SpotMe saved for the session (Finish saves one, Start again another), with their energy samples. Today's swaps and put-off marks go too.
- An item put off with Skip on the controls keeps its place and says "1 of 3 sets · waiting" (or "3 × 8–10 · waiting") in ice; tapping it does it now.
- At the end: **Finish workout** and **Discard workout**.
- Progress: "7/15" in the bar.

**Workout flow**
- Start workout (or Continue) opens the next open item in plan order; one already started comes first. The workout then moves through the day by itself.
- After an exercise's last set: a break as long as its rest (15 s before a checklist item) showing the next item and its target (no word on how the finished exercise went); when it runs out, the next item starts. +30 s, start now (the ▶ button or the countdown itself), tap the next item's name to pick another to do first, or tap its figure for How and Swap (the break waits while either is open). The timer runs round the edge of the screen. Undo, for the last logged set, is here and on the rest screen, between the round buttons.
- Checklist items (warmup, neck, cooldown) show their steps with Done and Skip (Skip drops it for the day), then move on.
- When everything is done and nothing waits: "All done" (with the day and the minutes, "Push A · 62 min") and Finish workout, which goes on to the effort question. There is no back button; **List**, on the controls page, returns to Today.
- Pages, as in Apple's Workout app: swipe right for the **controls**, left for **Now Playing** (the system player: play, pause, skip, volume on the Crown, for music on the watch or the iPhone). Three dots show the page.
- Controls: **Pause/Resume**, **End**, **Skip** and **List** (back to Today), four buttons of fixed size (so nothing resizes when the page first appears). Under them: "Skip to …" and, when the exercise on screen stays open, "This one stays open".
  - Pause stops the Health workout's time and heart rate. **A running rest or break never pauses:** it keeps counting and still ends with its haptic. Logging a set or starting a hold resumes the workout. Today shows the workout as paused, and so does a paused Health workout picked up after a relaunch.
  - **Skip means later.** It puts the exercise on screen off (or a tick-off item): it stays open with its logged sets, and the workout moves to the next open item. Waiting exercises come back by themselves after the last other open item that is not a tick-off item, so before the cooldown, in the order they were put off; the break before one says "Skipped earlier" and "Set 2 of 3 · 17.5 kg". During a rest between sets Skip puts the exercise off too (the rest is dropped; coming back opens the next set). From a break it starts the next item now. When the exercise on screen is the only open item, Skip is disabled. Waiting is kept for the day: it survives leaving the workout and a relaunch, and Discard workout clears it.
- **End** opens one screen: Finish, Discard workout (which asks once more) and Keep going.

**Set screen (weighted / reps)**
- Bar: "Set 2 of 4" (volt; "Max reps"; "Paused" in amber). In the content: the exercise's name (two lines at most), the rep range on the left ("6–10 reps", "10/side"), and on the right what to beat: "Last 9", the reps of the same set in the last counted session, or "First time" in volt with no history. Deload week and volume sets show nothing on the right.
- Two tiles side by side, **weight** and **reps**, prefilled with the target (one tile for reps only). Tap a tile to focus it (volt outline, volt unit); the Digital Crown then moves it one step per click (the exercise increment, or 1 rep), with a haptic, counting from the value shown (never an in-between or re-rounded value). No − or + buttons.
- Large **Log set** button.
- After logging: engine `nextSet` → rest screen.
- In a superset a line under the hint says "Superset · then <the other exercise>".

**Form figures**
- Every exercise of the plan has a small line figure that moves through its reps (`figures.json`, shipped as a resource of `RepCoachCore`, built by the designer; 50 figures, some shared; a short cue each). The user's own exercises have none, and nothing shows for them. `FigureRenderer` (`RepCoachCore/Figures`) is a port of `design/figures/figure3d.py`: it interpolates the two poses with ease in and out, turns them by yaw about the vertical axis, projects orthographically, sorts the parts far to near, dims limbs behind the body and crops one square per figure for every angle. It is pinned to the designer's golden values (`vectors.json`). A SwiftUI `Canvas` (`FigureView`) draws it.
- Set screen (and a hold's ready screen): the name block is a row, the name and hints on the left, a 42 pt button with a still of the figure on the right. A tap opens **How**: the figure moving at 125 pt, the name, one line (until the Crown has been turned there once, "Turn the Crown to look around" in ice; after that the cue), and seven dots for where in the circle it is. The Digital Crown turns the figure a full circle, smoothly, with a light haptic every 30°. It opens at the figure's opening view (`yaw`).
- Break: a figure of the next exercise moves beside its name. Always On and Reduce Motion show the still (the start pose faint under the end pose); stills under 45 pt show the end pose alone with lines 1.4 times wider.

**Ramp-up screen** (before the first working set; see Progression rules)
- Opening an exercise that has ramp-ups, with no working set logged today and its ramp-ups neither done nor skipped today, shows **Ramp-up** first: the name, "1 of 2 · not counted", one tile that is not editable ("10 kg × 8", with "WORKING WEIGHT 22.5 KG" under it; bodyweight reads "BW × 5" and "WORKING WEIGHT +15 KG"), and Done. Skip drops all ramp-ups left for the exercise today and opens set 1 with no rest.
- Done saves the set marked ramp-up (weight and reps as shown) and starts a 60 s rest (the usual rest screen, +30 and skip, no Undo). Between ramp-ups the rest says "NEXT · RAMP-UP 2 OF 2", the weight and "4 reps · not counted"; after the last it says "NEXT · SET 1 OF 4", the working weight and "Last time 10 reps". A superset pair does its ramp-ups back to back, then one rest.

**Rest screen**
- Countdown from `restSec` (supersets: rest only after the second exercise). The timer line round the edge of the screen and the time in the middle are drawn from one clock, so they always agree: 15 times a second on screen, every second in Always On (dimmed).
- No title and no reason. Shows "NEXT · SET 3 OF 4" and the next set's target (an arrow when the weight changed: ember down, volt up). The one line under it is only "Last time 10 reps" on the rest before the first working set, and "4 reps · not counted" between ramp-ups.
- Haptics at 10 s left and at 0. Round buttons: +30 s in one corner, skip in the other; Undo between them.
- The heart rate from the running workout session is shown under the time.

**Timed sets:** the ready screen has the weight (when the exercise takes one) and Start; Start counts up round the edge of the screen in volt with the target zone marked (the bottom of the range up to the top), with a haptic at `secMin` and `secMax`; the line turns mint at the top. Stop logs seconds.

**Checklist items:** Done or Skip in the workout; one swipe to done in the list. Warmups show their steps as a scrollable list; Done and Skip are at its end.

**Exercise finished:** the break before the next item (no summary line: how it went is for History).

**Swap (for today only)**
- **How** has a text button, **Swap exercise**, under the cue (for an exercise nothing has been logged on yet; ramp-ups don't count). Today's open rows have a **Swap** swipe action beside Skip today. Both open the **Swap** sheet: "Instead of Machine Chest Press", then the exercise's `alternatives` from the database in the database's order, each with its name and why, a TAKE CARE chip (ember) for a 2, nothing for a 3; and the footer "Today only. It takes these sets and reps and keeps its own weights." One tap swaps and returns to where the user was, now showing the new exercise. A swapped item also offers the plan's own exercise first, to take the swap back. Only weighted, reps and timed items are swapped, a hold for a hold; checklist items, the max-rep set and volume sets have no Swap.
- A swapped-in exercise takes the slot's sets, reps, rest, section and superset group, and its own id, name, kind, side and increment (the database's `incrementKg`). Its history, target, "Last" and "First time" come from **its own** past sessions (a swapped-in exercise that is also in the plan elsewhere has that history); nothing from the slot's exercise is mixed in. `ProgressionEngine` is unchanged: it works per exerciseId.
- For the day: tomorrow's plan shows the slot's exercise again. The swap is kept for the day like the put-off marks (it survives leaving the workout and a relaunch). Today's log of the swapped-in exercise has `slotExerciseId`, so History can say "for Machine Chest Press".
- Sync: see Data and sync.

**Effort and summary**
- After any Finish (End, Today, All done) the **Effort** sheet asks "How hard was it?" on Apple's 1 to 10 scale, moved with the Crown (a haptic click per step), starting at the last rated workout's value or 5: 1–3 Easy (mint), 4–6 Moderate (volt), 7–8 Hard (ember), 9–10 All Out (red). **Save** keeps it with the session (sent to the phone again) and, when the workout was saved to Health, writes it as the workout's effort rating (`workoutEffortScore`, related to the workout), so Fitness shows it and Training Load uses it; the watch asks for that permission once more. Closing the sheet saves the workout without an effort. With "Save workouts to Health" off the question is still asked and the answer stays in SpotMe. Discard never asks.
- Then the summary: time, sets (ramp-ups not counted), average heart rate, and the effort ("7", "EFFORT · HARD") or, without one, kcal.

**Workout session (HealthKit)**
- Starts an `HKWorkoutSession` (`.traditionalStrengthTraining`, indoor) with Start workout, or when an exercise is opened, while today's session isn't finished. It keeps the app running with the wrist down, so rests and breaks end on time with their haptics.
- "Save workouts to Health" (iPhone Settings) decides what happens to it: on, Finish asks whether to save it; off, it's always thrown away and nothing reaches Health (for a session logged after the fact). With the switch off the watch never asks for Health access; the workout runs only if access was already given.
- Health access belongs to the watch app: watchOS asks on the watch the first time, and it's changed later in the iPhone's Health app (profile picture → Apps → SpotMe). If saving workouts isn't allowed, Start workout says so and where to fix it; starting by itself stays quiet. The watch reports its access to the phone, whose Settings show it.
- Keeps the app frontmost during the session, collects heart rate and energy, and saves the workout to Health when ended.
- End from the controls or Today ("Finish workout"), or Finish when every item is done. Finishing saves the workout to Health without asking when saving is on, then asks for the effort. End also offers Discard workout.
- **Discard workout** deletes everything logged today, on the watch and the phone, and doesn't save the Health workout.
- Must survive the wrist dropping and the screen sleeping (Always On shows the rest timer).

**Complication ("Start workout")**
- Circular, corner, rectangular and inline. Shows today's session from the plan ("Pull A · Strength & Thickness"; "Rest day" on Saturday), refreshed at midnight. The mark is drawn (watch faces drop large images), its dot in the face's accent colour.
- Tapping it opens SpotMe **where it is** and never starts a second session (`OpenFromOutside`): a workout under way (a rest, a break or paused included) returns to the screen it was on, with the same clock and the same set, without changing the day on show; a finished day opens Today's Finished state, never Start again by itself; only a day with nothing started starts, as Start workout does. On a rest day it only opens the app. The app icon (and any Siri or Shortcuts entry that opens the app) opens the app as it was.

## iPhone app

- **Today:** the day's card and the same list, read-mostly (useful for checking the day before training). Nothing is highlighted.
- **History:** per exercise, sessions newest first with every set (ramp-up sets left out of set lists, counts, top-set weight and the chart). A Swift Charts line of top-set weight and estimated 1RM (Epley) over time.
- **Plan:** view all days as the user has them. Tap an exercise to rename it or change its increment, rep range, sets, rest and starting weight (a new name shows everywhere the exercise does), or remove it from the day. Swipe to remove; Edit to reorder; **Add exercise** (+) for a new one (name, logged as weight and reps, reps, timed or tick-off, section, prescription) or one from another day, which keeps its history. Added exercises go after the day's last exercise, ahead of the cooldown. "Reset Monday to the plan" and "Reset everything to the plan" keep history, and the user's own exercises stay defined (Add exercise → From the plan brings one back; a new exercise never reuses an id with history). plan.json never changes.
- **Export:** every set as a CSV file (date, time, day, exercise, set, weight, reps, seconds, deload, skipped, session, ramp-up, effort), from the share button in History or Settings → Your data, for Numbers, Excel or Google Sheets. Ramp-up sets are listed and marked "yes" in the Ramp-up column (the Set number is the order performed, ramp-ups included); Effort (1–10, blank when not given) is on every row of its session.
- **Settings:** program start date (drives deload weeks), "This week is a deload" toggle, **Ramp-up sets** (Off, Main lifts (default), Every weighted lift; footer "Lighter sets before your first working set. They aren't counted."; sent to the watch with the other settings), rest timer haptics on/off, "Save workouts to Health" on/off (off: nothing reaches Health), the watch's Health access and a shortcut to the Health app.
- **Body log:** flexed arm and waist in inches, every 2 weeks, from the Body card in History (charts of both, and every measurement; swipe to delete). Adding one starts from the last values: type them or step by ¼″. The latest is compared with the newest measurement at least 12 days older (else the one before it). **Warn if the waist is up more than 1 inch while the arms grew less than ¼″.** Once the log is in use, Today shows "Body log due" when two weeks have passed.

## Data and sync

- SwiftData on both devices.
- Models: `WorkoutSession` (id UUID, date, weekday key, isDeload, healthKitWorkoutId? (the latest Health workout), endedAt?, effort? 1–10, activeSeconds?, energyKcal?, averageHeartRate? (over every Finish of the session), savedWorkoutIdList? (every Health workout saved for it, for Discard)), `ExerciseLog` (session, exerciseId, order, completedAt?, skipped, slotExerciseId? (the plan's exercise a swapped-in one stands in for)), `SetLog` (log, index, weight, reps, seconds?, timestamp, isRampUp), `ExerciseSettings` (exerciseId, overrides for name/increment/rep range/sets/rest/startWeight), `BodyMeasurement` (id, date, arm, waist, in inches; iPhone only), `PlanEditsRecord` (the user's `PlanEdits`: each changed day's exercise order, and the exercises they created, with ids starting "custom-").
- `SetLog.index` is the order performed in the exercise, ramp-up sets included. `ExerciseLog.orderedSets` is every set (the CSV); anything that counts sets (`status`, `orderedCountedSets`, `HistoryStore`, `WorkoutSession.countedSetCount`) leaves ramp-up sets out. Both new fields are lightweight additions to the store: older stores open with no ramp-ups and no effort.
- Both new fields groups are lightweight additions to the store (optional attributes): older stores open with none of them. `SessionPayload` carries them (`slotExerciseId` per log; time, energy and average heart rate per session) and decodes older payloads without.
- **The watch works fully without the phone nearby.** It keeps its own store and the history it needs for targets.
- WatchConnectivity:
  - Watch → phone: each finished `WorkoutSession` (with its logs, each set's ramp-up mark and the session's effort) via `transferUserInfo` (queued, delivered later). The phone de-duplicates by session UUID; sending a session again replaces the phone's copy, which is how an effort given after Finish arrives. Payloads from before ramp-ups and effort decode as working sets and no effort.
  - The watch's own application context (`WatchStatus`): its Health access, the ids of every session it has, and the ids it discarded. The phone deletes discarded sessions and never stores them again, and sends back (via `transferUserInfo`) every session the watch doesn't have, so a reinstalled watch app gets its history and today's progress back. A restored copy never overwrites a session the watch has.
  - **Swaps travel both ways at once** (`SwapMarks`): the watch's swap goes to the phone, and the phone's to the watch, as a `sendMessage` when the other device is reachable, and in the application contexts (`WatchStatus.swaps`, `SyncContext.swaps`) as the fallback. A mark is (day, date, slot, exercise, time); the later mark for a slot wins on either device, taking a swap back is a mark whose exercise is the slot, and Discard takes them all back. The receiving device applies them at once, even mid-workout, to the open item wherever it is (the screen on show moves to the swapped-in exercise; a break shows the new one by itself). The iPhone's own Swap screen comes with the iPhone redesign; the phone already accepts and shows the watch's swaps, and History and the CSV name a swapped-in exercise from the database.
  - Phone → watch: settings (including the ramp-up setting and the injury areas), exercise overrides and plan edits via `updateApplicationContext`. The watch applies them at the next session start, except the Health switch, which moves no targets and applies at once.
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
