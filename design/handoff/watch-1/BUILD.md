# SpotMe · watch build 1 · design handoff

From: SpotMe - Designer (the session in `design/` on the server). To: SpotMe - Frontend (Mac Studio).
Approved by Yeshu on 6 Oct 2026: "all approved for now for watch designs based on your recommendations …
go and build the app with new designs now."

## 1 · Scope

**In:** the whole watch app redrawn (boards 0, 1.1–6.1), and four new things from Yeshu's notes: ramp-up
sets, effort after a workout, Skip that means "later", and a moving form figure per exercise that turns with
the Crown. Plus one bug he reported (section 10).

**iPhone:** not redesigned in this build. It only gets what the watch features need (section 11).

**Not in this build** (still under review, do not start): the iPhone redesign (7.1–10.1), onboarding and
the plan builder (11, 12, board 1.9), the exercise database and swapping exercises.

The app's rules still hold: no third-party code, all progression maths through `ProgressionEngine`, rule
changes go into `docs/engine_reference.py` first, `plan.json` content is not hand-edited. You own everything
outside `design/`, including `docs/SPEC.md`: please update the spec where this handoff changes behaviour
(sections 5 to 11 list every change).

## 2 · Where the design is

| What | Where |
|---|---|
| A picture of every approved board, 416 × 496 px (the 46 mm screen at 2×) | `design/handoff/watch-1/boards/<board>.png` |
| The exact layout of every board (sizes, colours, strings) | `design/reviews/1-watch.md`, `4-figures.md`, `5-feedback-6oct.md` |
| The boards as HTML | `design/canvas/project/<board>.dc.html` |
| Ramp-up rule, runnable, with test vectors | `design/handoff/watch-1/rampup_reference.py` |
| Figure format and reference renderer | `design/figures/FIGURES.md`, `design/figures/figure3d.py` |
| Canvas (Yeshu's view) | https://claude.ai/artifact/5zqv25yapNuDwotbEqNvwQ, page Approved |

How to read them:

- **The picture is the reference.** Where a review's text and the picture differ, the picture wins (each
  review ends with "Round 1 result", the accepted departures).
- **Reviews give px; the app is pt. 1 pt = 2 px.** Halve every number. The tables in section 3 are already in pt.
- The pictures were drawn on a server without Apple's fonts, in Nunito. The app uses SF Rounded, so letter
  shapes differ; sizes, weights, positions and colours must not.
- Every board draws a top bar (back button, short title, clock). **Keep the system navigation bar and clock**:
  the boards only show what goes in it. What matters is the title's text and colour, and that nothing else is
  in the bar (no exercise name, no Undo).
- Sample moment on almost every board: Wednesday, Push A, 15 items, clock 10:09, workout at 24:10, heart 128.
  The table is in `1-watch.md`, "Sample data".

## 3 · Design system, in pt

**One accent.** Volt is the thing to tap and the value the Crown moves. Other colours only say a state.
There is no colour per kind of exercise any more: remove `Theme.violet` and every per-kind tint, kind badge,
round kind icon and tinted screen background.

| Name | Hex | Means |
|---|---|---|
| volt | `#CCFF3D` | Primary button, focused value, top-bar title, going up |
| ice | `#63D9FF` | Waiting: rest, break, ramp-up, an exercise put off for later |
| mint | `#47EBA3` | Done |
| ember | `#FF9442` | Lighter than planned, deload |
| red | `#FF4569` | Heart rate; Stop, End, Discard |
| amber | `#FFD133` | Paused |
| text / text 2 / text 3 | `#FFFFFF` / `#B8B8BD` / `#8E8E93` | Main, supporting, units and hints |
| card / raised | `#1C1C1E` / `#2C2C2E` | Rows and tiles / round and neutral buttons |
| line | white at 10% | Tile outline |

Tinted fill = the colour at 16% (18% on the controls page). Text on a volt, mint, amber or red fill is black.

Type: SF Rounded, tabular digits everywhere. Size / line height / weight, in pt:

| Role | Style | Where |
|---|---|---|
| timer | 54 / 52 / heavy | Rest countdown, hold time |
| value | 36 / 38 / bold | Weight and reps tiles (28 / 30 when 5 or more characters) |
| value wide | 48 / 50 / bold | A single full-width tile |
| next value | 28 / 30 / bold | Next weight on rest |
| title xl | 20 / 22 / heavy | Day name, "All 15 done" |
| title | 17 / 19 / bold | Exercise name on a screen, two lines at most |
| button | 17 / 20 / bold | Primary button |
| row | 15 / 17 / semibold | Row name |
| bar | 15 / 18 / bold | Top-bar title |
| detail | 12 / 15 / medium | Prescriptions, reasons |
| small | 11 / 14 / semibold | Summaries, hints |
| eyebrow | 10 / 12 / heavy, +6% tracking, capitals | Labels, units |

Nothing under 10 pt. Numbers never wrap. Tap targets 30 pt or more.

Parts, in pt (details and exact markup in `1-watch.md`, "Parts"):

- Screen 208 × 248. Content column: 8 from each side, starts 42 from the top, ends 15 above the bottom.
- Primary button: full width, 44 high, capsule, volt, black label. One per screen, always last.
  Neutral button: raised fill, white label, 38 high. Stop and Discard: red fill, black label.
  Text button: no fill, 30 high, 13 / 15 / semibold.
- Value tile: card fill, corner 17, 1 pt line. Focused (the Crown moves it): volt at 16% fill, 2 pt volt
  outline, unit in volt. Exactly one tile is focused.
- List row: card, corner 17, padding 7 / 10 / 8; name in row style; under it the prescription on the left
  (detail, text 2) and the target weight on the right (13 / 15 / bold, white).
- Round buttons on rest and break: 38 across, raised, 18 from the side, 17 from the bottom. Undo between them.
- Page dots (controls · workout · Now Playing): 5 pt, 4 apart, 5 from the bottom, 10 on screens with the
  edge timer.
- **Edge timer:** a 5 pt line that follows the screen's edge, inset 4.5 pt (use the display's own corner
  shape, not a guessed radius). Track: the colour at 18%. What is left is drawn solid, ends at top centre,
  and its start runs away clockwise as time passes. Rest and break: ice. A hold counts up in volt from top
  centre, with the target zone (bottom to top of the range) at 38% volt, and turns mint at the top.
  Drawn from the same clock as the digits.
- Icons: the paths are in `1-watch.md`, "Icons". SF Symbols that look the same are fine
  (`chevron.left`, `xmark`, `arrow.up`, `arrow.down`, `checkmark`, `arrow.uturn.backward`, `list.bullet`,
  `trash`, `play.fill`, `pause.fill`, `forward.end.fill`, `heart.fill`).

**Sizes.** Boards are the 46 mm watch. On 42 mm scale every size by 0.9 with one factor in the theme; do
not make a second layout. Check both.

## 4 · The boards

`Std` = pushed bar with a short title, page dots. File = `boards/<name>.png`.

| # | File | Screen | Today's view |
|---|---|---|---|
| 0 | Main | Style sheet (reference only) | `Theme.swift` |
| 1.1 | W11-TodayStart | Today before the workout | `TodayView` |
| 1.2 | W12-TodayList | The list, scrolled: arrows on rows | `ItemRow` |
| 1.3 | W13-TodayRunning | Workout running: heart, time, Continue | `TodayView` |
| 1.4 | W14-TodayPaused | Paused | `TodayView` |
| 1.5 | W15-TodayEnd | End of the list: Done rows, Finish, Discard | `TodayView` |
| 1.6 | W16-TodayAllDone | All done | `TodayView` |
| 1.7 | W17-Days | Days | `DayPickerView` |
| 1.8 | W18-RestDay | Rest day, no button | `TodayView` |
| 1.10 | W110-TodayWaiting | One exercise waiting (section 7) | `TodayView`, `ItemRow` |
| 2.1A | W21A-SetTiles | **The set screen** | `SetView` |
| 2.2 | W22-SetWeight | Crown on weight | `SetView` |
| 2.3 | W23-SetFirst | First time, asks a weight | `SetView` |
| 2.4 | W24-SetReps | Reps only | `SetView` |
| 2.5 | W25-SetSide | Per side, optional weight | `SetView` |
| 2.6 | W26-SetMax | Max reps | `SetView` |
| 2.7 | W27-SetVolume | Volume sets | `SetView` |
| 2.8 | W28-SetSuperset | Superset | `SetView` |
| 2.9 | W29-SetPaused | Paused | `SetView` |
| 2.10 | W210-SetDeload | Deload week | `SetView` |
| 2.11 | W211-SetFigure | Set screen with the figure (section 9). This is 2.1A when a figure exists | `SetView` |
| 2.12 | W212-How | How: moving figure and cue (section 9) | new |
| 2.13 | W213-RampUp | Ramp-up set (section 8) | new |
| 2.14 | W214-HowTurn | How, turning with the Crown (section 9) | new |
| 3.1A | W31A-RestEdge | **The rest screen** | `RestView`, `CountdownRing` |
| 3.2 | W32-RestDrop | Next set lighter | `RestView` |
| 3.3 | W33-RestUp | Next set heavier | `RestView` |
| 3.4 | W34-RestReps | Reps exercise | `RestView` |
| 3.5 | W35-RestPaused | Paused | `RestView` |
| 3.6 | W36-RestSuperset | After a superset pair | `RestView` |
| 3.7 | W37-RestAlwaysOn | Wrist down | `RestView` |
| 3.8 | W38-Break | Break before the next exercise | `NextUpView` |
| 3.9 | W39-BreakChecklist | Break before a tick-off item | `NextUpView` |
| 3.10 | W310-BreakPick | Do another next | `NextUpView` |
| 3.11 | W311-BreakMax | After the max-rep set | `NextUpView` |
| 3.12 | W312-BreakFigure | Break with the figure (section 9). This is 3.8 when a figure exists | `NextUpView` |
| 3.13 | W313-RestRampUp | Rest after the last ramp-up (section 8) | `RestView` |
| 3.14 | W314-BreakBack | Break before going back to a waiting exercise (section 7) | `NextUpView` |
| 4.1 | W41-HoldReady | Hold, ready | `HoldView` |
| 4.2–4.4 | W42-HoldRunning, W43-HoldInRange, W44-HoldTop | Holding: under, in range, top | `HoldView` |
| 4.5, 4.6 | W45-ChecklistSteps, W46-ChecklistEnd | Tick-off item with steps | `ChecklistView` |
| 4.7 | W47-ChecklistNote | Tick-off item with a note | `ChecklistView` |
| 5.1 | W51-Controls | Controls. Layout superseded by 5.10 | `WorkoutControls` |
| 5.2 | W52-ControlsPaused | Controls, paused (use 5.10's sizes) | `WorkoutControls` |
| 5.3 | W53-End | End workout? | `TodayView` dialogs |
| 5.4 | W54-Discard | Discard workout? | `TodayView` dialogs |
| 5.5 | W55-AllDone | All done, in the workout | `WorkoutViews` |
| 5.6 | W56-Summary | Summary without effort | `WorkoutViews` |
| 5.7 | W57-HealthAlert | Not saving to Health | `TodayView` |
| 5.8 | W58-Effort | Effort (section 6) | new |
| 5.9 | W59-SummaryEffort | Summary with effort (section 6) | `WorkoutViews` |
| 5.10 | W510-ControlsSkip | **The controls page** (section 7) | `WorkoutControls` |
| 6.1 | W61-Complications | Complications | `Apps/Widgets` |
| 13.1, 13.2 | F131-Figures, F132-Turn | Figure galleries (reference only) | |

## 5 · Behaviour that changes with the redesign (Yeshu's yes to a–f)

a. **"Last 9".** The set screen shows the reps of the same set in the last counted session, right of the
   rep range. No history: "First time" in volt. Deload week or volume sets: nothing on the right.
b. **Undo moves** from the set screen's bar to the rest and break screens, bottom centre between the round
   buttons. It does what it does today.
c. **Today rows** lose the round kind icons. The target weight sits on the right. An up arrow in volt before
   it when today's target is above the last working weight, a down arrow in ember when it is lower or a
   deload. Both come from what the engine already returns (its tag); no new maths.
d. **A rest day** (Saturday) has no Start workout button.
e. **End workout?** is one screen with Finish, Discard workout and Keep going, no scrolling system dialog.
   Discard asks once more (5.4).
f. **"Back to list"** under All done goes away; Back is there.

The break screen's name is a button (opens "Do next", 3.10) and the round play button starts now, as today.
On rest, the reason is the part of the engine's line before " · " ("5 reps, below 6").

## 6 · Effort after a workout (new)

Yeshu wants to be asked how hard the workout was, and to see it in Fitness. Nothing in the repo does this
today, and the watch only has permission to write workouts.

- After any Finish (End sheet, Today, All done), before the summary: the **Effort** sheet (5.8). The Crown
  moves 1 to 10, starting at the last workout's value, or 5. Words and colours: 1–3 Easy (mint), 4–6
  Moderate (volt), 7–8 Hard (ember), 9–10 All Out (red). A haptic click per step.
- **Save** stores it. Closing the sheet saves the workout without an effort. Then the summary: with an
  effort the fourth tile reads it ("7", "EFFORT · HARD", 5.9) in place of kcal; without, kcal as 5.6.
- Health: save it as the workout's effort rating so the Fitness app shows it and Training Load uses it. As
  far as I know that is a `workoutEffortScore` quantity sample in `HKUnit.appleEffortScore()`, attached with
  `HKHealthStore.relateWorkoutEffortSample(_:with:activity:)`, and it needs write access to that type, so the
  watch will ask once more. Please check the current SDK; you know it better than I do. If the write is
  refused, keep the value in SpotMe and say nothing.
- "Save workouts to Health" off: still ask; the value stays in SpotMe.
- Discard never asks.
- Data: the session gains an optional effort (1–10). It syncs to the phone and gets a CSV column.
- **Check on Yeshu's real watch** that the effort shows on the workout in Fitness. This is the thing he
  asked for.

## 7 · Skip means "later" (changed)

Today Skip on the controls marks the exercise finished, and he cannot start it again. New rule:

- **Skip on the controls page puts the exercise on screen off for later.** It stays open, its logged sets
  stay, and the workout moves to the next open item. It is "waiting".
- The workout comes back to waiting exercises by itself: after the last other open item that is not a
  tick-off item, so before the cooldown. In the order they were put off.
- During a rest between sets, Skip puts the exercise off too (the rest is dropped; coming back opens the
  next set). During a break it starts the next item now, as today. On a tick-off item it puts that off.
- When the one on screen is the only open item, Skip is disabled.
- Controls (5.10): four buttons at **fixed sizes** (40 pt high), and two lines under them:
  "Skip to Cable Lateral Raise" and "This one stays open".
- Today (1.10): a waiting row keeps its place in the open list. Its detail is in ice: "1 of 3 sets ·
  waiting", or "3 × 8–10 · waiting" with nothing logged. Tapping it does it now. Continue names what is
  really next.
- The break before going back to one (3.14) has the eyebrow "SKIPPED EARLIER" in ice and the target
  "Set 2 of 3 · 17.5 kg".
- Dropping an exercise for the day is a different act: the swipe on a Today row, now labelled **Skip today**,
  and the Skip button on a tick-off screen. Such a row says "Skipped · tap to do it" and a tap reopens it
  and starts it.
- Finish with exercises still waiting works as it does today with open ones: what is logged is kept.
- Waiting survives leaving the workout and relaunching the app, for that day.
- "All done" only when nothing is open or waiting.

## 8 · Ramp-up sets (new engine function)

Yeshu: last time 20 kg × 12 was his limit; the next session should not start cold at 20 kg. The working
sets, their weight, and "beat last time" stay exactly as they are. What is added is one or two lighter,
short sets before the first working set.

The rule, with vectors: `rampup_reference.py` in this folder. Put it into `docs/engine_reference.py` first,
pin the tests to its output, then write the Swift, as the repo rules say. In short:

- Main lift = a weighted exercise whose rest is 2:00 or more. The first one in the day's order gets two
  ramp-ups (50% × 8, 75% × 4); other main lifts get one (70% × 5). Smaller lifts get none, or one at
  70% × 5 with the setting "Every weighted lift".
- Weight = today's working weight × factor, rounded down to the increment. One that rounds to zero, to the
  one before it, or to the working weight is left out. Reps never go above the top of the rep range.
- No working weight yet (first time): none. Deload week: worked out from the deload weight.
- An exercise whose weight is added to bodyweight (weighted pull-ups; this needs a flag on the item, yours
  to add): bodyweight × 5, and for the first main lift a second at half the added weight × 3.

On the watch:

- Opening an exercise that has ramp-ups, with no working set logged today and the ramp-ups neither done nor
  skipped today, shows the **Ramp-up** screen first (2.13): title "Ramp-up" in ice, the name, "1 of 2 · not
  counted", one tile that is not editable ("10 kg × 8", under it "WORKING WEIGHT 22.5 KG"), and Done.
  Bodyweight reads "BW × 5" with "WORKING WEIGHT +15 KG".
- **Done** starts a 60 s rest (the usual rest screen, +30 and skip, no Undo). Between two ramp-ups it says
  "NEXT · RAMP-UP 2 OF 2", "15 kg", "4 reps · not counted". After the last (3.13): "NEXT · SET 1 OF 4", the
  working weight, and "Last time 10 reps" (set 1 of the last counted session).
- **Skip** on the ramp-up screen drops all ramp-ups left for this exercise and opens set 1 with no rest.
- A superset in "Every weighted lift": both ramp-ups back to back, then one 60 s rest.
- Ramp-ups are saved as sets marked ramp-up, with the weight and reps shown. They are never counted: not
  in "Set 2 of 4", not in the summary's sets, not in "Last", not in progression history, not in charts.
  The CSV gets a column for the mark.
- Setting (iPhone, Settings, Program): **Ramp-up sets**: Off · Main lifts (default) · Every weighted lift.
  Footer: "Lighter sets before your first working set. They aren't counted." It reaches the watch like the
  other settings.

## 9 · Form figures that turn (new)

Yeshu googles exercises mid-workout. Each exercise gets a small moving line figure, drawn by the app from
two poses, and the Crown turns it to any side.

**This part arrives in two drops.** Build everything else first. Drop 2 is a message from me when it is
pushed: the final figure format with every kind of load, the complete "3D format" section in `FIGURES.md`,
and `design/figures/bundle/figures.json` with a figure for every exercise in the plan, keyed by `exerciseId`.
Until then `figure3d.py` and the three poses in `design/figures/poses3d/` show the idea; the load vocabulary
will grow, so do not port the renderer before drop 2.

What to build then:

- A renderer in shared Swift code: pose file + time + yaw in, a draw list out (lines with a width and a
  colour, filled circles, filled polygons), drawn in a SwiftUI `Canvas`. It is a straight port of
  `figure3d.py`: interpolate the two poses with ease in and out, turn by yaw about the vertical axis,
  orthographic projection, sort far to near, dim limbs behind the body, one square crop per figure for all
  angles. Unit-test the projection and the order against values I will give in drop 2.
- **Set screen (2.11):** when the exercise has a figure, the name block becomes a row: name and hints on the
  left, a 42 pt rounded button on the right with the still figure. A tap opens How. No figure: 2.1A as is.
- **How (2.12 and 2.14 are one screen):** a sheet. The moving figure at 125 pt, the name, then one line:
  until he has ever turned the Crown here, "Turn the Crown to look around" in ice; after that the cue (two
  lines, from the bundle). The Crown turns the figure, a full circle, smoothly, with light haptic detents.
  Seven dots under the text show where in the circle he is. It opens at the figure's usual view.
- **Break (3.12):** when the next exercise has a figure it moves at 62 pt left of the name.
- Always On and Reduce Motion: the still (end pose). Stills under 45 pt: end pose only, lines 1.4 × wider.
- Exercises he added himself have no figure; nothing shows.

## 10 · The bug Yeshu reported

"First time when I open this controls screen icons show small and then they resize to normal size."
`WorkoutControls` sizes its buttons from `GeometryReader`'s height, which is wrong for the first frame.
Board 5.10 uses fixed sizes (section 7). Please confirm it is gone on his watch, not only in the simulator.

## 11 · iPhone, only what the watch needs

No visual redesign. In the app as it looks today:

- Settings, Program: the **Ramp-up sets** row (section 8), synced to the watch.
- Store and sync the new data: the ramp-up mark on a set, the effort on a session.
- History: ramp-up sets are left out of set lists, set counts, top-set weight and the 1RM chart.
- CSV: columns for ramp-up and effort.

## 12 · What I need back

1. **A first reply now**, so Yeshu knows it landed: queued or started, and your rough order of work.
   Questions any time; reply to the session this message came from.
2. Work in the order that suits the code. My suggestion: (A) theme, parts, Today, set, rest, break;
   (B) holds, tick-offs, controls, end, summary, complications, and a–f; (C) Skip means later, ramp-ups,
   effort; (D) figures after drop 2.
3. **Screenshots after each part**, before moving far ahead: the 46 mm simulator, the demo store, one PNG
   per board, named like the board (`W21A-SetTiles.png`), in the same state and with the same sample data
   as the board. `ScreenScript` already drives the app to a screen; please extend it for the new states.
   Commit them under `design/built/watch-1/` on your branch and push; tell me the branch. I compare each
   one with its board and answer OK or what to fix. Add the same set at 42 mm for the set, rest, break and
   controls screens.
4. If the demo store cannot produce a board's exact number, keep the engine's number and tell me which.
5. If a board cannot be built as drawn in SwiftUI on watchOS, say so before working around it.
6. At the end: tests green, the spec updated, the build number, and how Yeshu gets it on his watch. He
   asked to be told when it is done, and I pass that on only after the screenshots pass.
