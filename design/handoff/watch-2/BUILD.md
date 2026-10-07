# SpotMe · watch build 2 · design handoff

From: SpotMe - Designer (the session in `design/` on the server). To: SpotMe - Frontend (Mac Studio).
Approved by Yeshu on 7 Oct 2026 ("approved all, pass it to frontend") after his first real session on build 8.

## 1 · Scope

**In (watch only):**
1. Today after Finish with items left: a Finished state and **Start again** (boards 1.11, 1.12).
2. One exercise per plan slot: "Machine Chest Press (or Flat Bench)" becomes **Machine Chest Press**, with
   an id migration (section 5).
3. **Swap** an exercise for today, from the How sheet and by swipe on Today (boards 1.13, 2.15, 2.16).
4. Every in-workout screen: **no back button**, **no reason text** on rest and break, **no "Rest" title**,
   the **rest never pauses** (section 3; 38 boards re-rendered).
5. **Figures drop 3:** 12 of the 50 figures redrawn after an audit (section 7).
6. The **edge timer's corners** on the real watch: still waiting for Yeshu's photo (section 8).

**Not in this build:** the iPhone (look B is chosen and the Today screens are approved, but they come as
their own handoff after this one); onboarding; rearranging days. Nothing on the iPhone changes here except
what the watch needs to keep syncing (section 6).

The repo's rules hold: no third-party code, progression maths through `ProgressionEngine` (nothing in it
changes in this build), `plan.json` content not hand-edited except the one rename in section 5. You own
`docs/SPEC.md`: please update it where this handoff changes behaviour (each section says what).

## 2 · Where the design is

| What | Where |
|---|---|
| A picture of every board in this build, 416 × 496 px (46 mm at 2×) | `design/handoff/watch-2/boards/<board>.png` (42 files) and `F133-PlanFigures.png` (all 50 figures) |
| The exact layout rules | `design/reviews/7-feedback-7oct.md` (Finished, Swap), `8-feedback-7oct-b.md` (no reasons, figures), `9-look-7oct.md` (no back button, title position), `10-look-b-today.md` (no Rest title, rest never pauses); everything else as `1-watch.md`, `4-figures.md`, `5-feedback-6oct.md` |
| The boards as HTML | `design/canvas/project/<board>.dc.html` |
| The figure bundle and golden vectors (replace the ones from drop 2) | `design/handoff/watch-2/figures/figures.json`, `vectors.json` (copies of `design/figures/bundle/`) |
| The exercise database (alternatives for Swap) | `design/exercise-db/exercises.json`, schema in `SCHEMA.md` |

Compare your screenshots with the PNGs the way build 1 was checked (`design/reviews/6-build-watch-1.md`):
same strings, same places, same sizes within a point or two.

## 3 · Every in-workout screen (boards 2.1A–2.14, 3.1A–3.14, 4.1–4.7, 5.1, 5.2, 5.5, 5.10)

- **No back button** on any workout screen: set, ramp-up, rest, break, holds, tick-off items, controls, All
  done. `navigationBarBackButtonHidden`. Getting to Today is the controls page's List button (already there).
  Sheets (How, Swap, Days, End, Discard, Summary, Effort, Health alert) keep their close button.
- **Bar title** on screens that keep one ("Set 2 of 4", "Ramp-up", "Next", "Warmup"): at the clock's line,
  left 22 pt (44 px), as Today's "0/15". On the **edge-timer screens** (rest, break, holds) it is drawn as
  content, not as the navigation title, at left 26 pt, top 17 pt (52 / 34 px), so it clears the line: 3 pt
  lower than the clock's line. If the system title can't be moved, draw a plain Text there and leave the
  navigation title empty.
- **Rest screens have no title at all** ("Rest" is gone): countdown, heart rate, NEXT · SET n OF m, the next
  weight with its arrow. Break screens keep "Next" in ice; holds keep "Set n of m" in volt.
- **No reason text.** The rest screen's reason line ("In range", "5 reps, below 6", "17 reps, above 15") is
  gone. The break screen's result line ("All sets 10 · next time 25 kg", "Aim for 15 reps on every set",
  "Logged", "12 reps · volume sets of 7") is gone. All done (5.5) loses its last-exercise lines and shows
  "Push A · 62 min" under "All 15 done", like 1.6. The up/down arrows stay. Kept: "Last time 10 reps" on the
  rest before the first working set (3.13). The engine still produces the reason strings; History and the
  CSV keep using them.
- **The rest never pauses.** Pause (controls) stops the workout clock and the heart-rate line as now, but a
  running rest or break countdown keeps counting and still ends with its haptic. Board 3.5 (paused rest) is
  withdrawn. The set screen's paused state (2.9), Today paused (1.4) and controls paused (5.2) stay.
- Spec: "Back always returns to Today" → "List, on the controls page, returns to Today". Rest/break
  descriptions lose their reason lines. Pause: "the rest timer keeps running".

## 4 · Finished with items left · Start again (boards 1.11, 1.12; decision r)

What happened: Yeshu finished with the last core items open; Today kept showing Continue, and the only way
out at the end of the list was Discard.

- After any Finish (End sheet, Today's Finish workout, All done) **the day is finished**. Today shows:
  1. the day button as on 1.3 (eyebrow "WEDNESDAY · PUSH A" + chevron, opens Days);
  2. a **Finished card** (row-card style; a 52 px mint-tinted circle with the check, "Finished" row style,
     "48 min · Hard 7" detail; without an effort: "48 min · 342 kcal"). Tapping it opens the summary sheet
     (5.6 / 5.9).
  3. when items are left: a neutral button **Start again** (108 px, two lines: "Start again", "3 left"),
     then eyebrow NOT DONE and the open rows in plan order (open row style, no weight), then eyebrow DONE and
     the done rows as 1.5, then the red Discard workout text button;
  4. when nothing is left (1.12): no Start again; DONE rows; Discard workout at the end.
  The bar title ("12/15", "15/15") is mint while the day is finished. No Continue, no Finish.
- **Start again** (or tapping a NOT DONE row) reopens the same session: done items stay done; a new
  `HKWorkoutSession` starts; the next open item (or the tapped one) opens as Start workout would; Today is
  back in its running state (1.3). The "Up next" complication shows "Done" while finished and the next open
  item after Start again.
- **Finishing again** saves the second Health workout and asks the effort again, starting from the first
  answer; the new answer replaces the session's effort and is written to the second workout. The phone gets
  the session again (same UUID, as today).
- **Discard workout** after a Finish deletes today's sets and every workout SpotMe wrote to Health today
  (they are the app's own samples), as the Discard sheet (5.4) already says.
- Spec: add the finished state, Start again, and "Discard after Finish deletes the Health workouts".

## 5 · One exercise per slot (decision s)

- `plan.json`: the Wednesday slot's `name` becomes "Machine Chest Press" and its `exerciseId`
  `machine-chest-press` (the database's id). The note stays. This is the one hand-edit allowed in this
  build; keep the engine tests' fixtures in step.
- **Migration, once, on first launch of this build, on both devices:** every stored set, session log,
  `ExerciseSettings` row and waiting/skip mark with `exerciseId == "machine-chest-press-or-flat-bench"`
  becomes `machine-chest-press`. Yeshu's existing history counts as Machine Chest Press. Idempotent; a
  reinstalled watch that receives old sessions from the phone maps them on receipt too.
- Every board that showed the old name now reads "Machine Chest Press" (1.1, 1.2, 1.5, 3.8 and the iPhone).

## 6 · Swap for today (boards 1.13, 2.15, 2.16; decisions t, u)

- **Where:** the How sheet (2.12, from the figure button on the set screen and the name on the break screen)
  gets a text button **Swap exercise** under the cue (swap icon + label, white). Today rows get a swipe
  action **Swap** beside Skip today. Both open the **Swap sheet** (2.16): title "Swap" in volt; a line
  "Instead of Machine Chest Press" (small style, grey); then the exercise's `alternatives` from
  `design/exercise-db/exercises.json` in the database's order, each a row: name (row style) and its `why`
  (22 / 28 / 500 grey, two lines allowed). Leave out any alternative whose rating for one of the user's
  injury areas is 3; show a TAKE CARE chip (ember) for a 2. Yeshu's injury area is the lower back (none of
  the six chest alternatives are 2 or 3). Footer at the end: "Today only. It takes these sets and reps and
  keeps its own weights." One tap swaps and returns to the screen the user came from, now showing the new
  exercise. On the How sheet the figure is 200 px when the cue runs to three lines (2.15).
- **What a swap is:** today's session item keeps the slot's sets, reps, rest, kind and group, but its
  `exerciseId` becomes the alternative's id (the database id) and its name the alternative's name. The
  increment comes from the database's `incrementKg`, `perSide` from the database. Its history, suggestion
  and "Last" come from **its own** previous sessions (none → First time, 2.3). Nothing from the slot's other
  exercise is mixed in. The engine is untouched: it already works per exerciseId.
- **For today only.** Tomorrow's Push A shows Machine Chest Press again. The swap is kept for the day like
  the waiting marks (survives leaving the workout and a relaunch; Discard clears it).
- **Today shows a swapped item** (1.13) with the swap icon (20 px, grey) before its prescription and "First
  time" in volt on the right when it has no history.
- **Sync:** the swap travels with the session (the item's exerciseId and name are in the logs already; add
  the slot it stands in, `slotExerciseId`, so History can say "for Machine Chest Press"). The phone's
  History and CSV show the swapped-in exercise by its own name. The phone also needs to **accept a swap from
  the watch mid-workout and, later, send one** (the iPhone's Swap UI comes with the iPhone handoff; build
  the message both ways now: `sendMessage` when reachable, application context as the fallback, applied to
  the open item wherever the other device is, including on a break or on Today).
- **Plan slots without database alternatives** (checklist items, tick-offs): no Swap button, no swipe.
- Spec: add Swap; the line "never suggest exercises that are not in the plan" is replaced by "Swap offers
  the database's alternatives".

## 7 · Figures drop 3 (boards 2.11, 2.12, 2.14, 2.15, 3.12, 13.3)

Yeshu found two wrong figures on his watch (the lifter under the incline bench; the chest press machine's
frame in front of him). An audit of all 50 found 12 to redraw: machine-chest-press, incline-db-press,
machine-shoulder-press, l-sit, bicycle-crunch, russian-twist, side-plank-with-reach, superman-hold,
chest-supported-db-row, reverse-pec-deck, band-assisted-pull-ups, hanging-leg-raise. Replace the bundle and
the golden vectors with `handoff/watch-2/figures/` and re-run the renderer's tests against the new
`vectors.json` (the format is unchanged; only pose data moved). `F133-PlanFigures.png` shows all 50 as they
should look at their opening view.

## 8 · The edge timer's corners

Build and board match; the real glass cuts the line's corners. We still need Yeshu's straight-on photo
(asked twice; it is in his to-dos). When it lands: if the glass hides more than about 2 pt, move the whole
line in rather than thinning it; 5 pt weight and the 18% track stay. If the photo is ambiguous, your
calibration build is fine, as a separate build only, with Yeshu's OK. Don't block build 9 on this.

## 9 · What I need back

- Branch off `main`, build **9**. Screenshots at 46 mm of every board in `boards/`, named by board, plus the
  set, rest, break and controls screens at 42 mm. Rest and break from a real run so the title position and
  the edge line are the device's.
- A note on the migration: how many sets moved on Yeshu's phone and watch (log it once).
- Anything in the rules you couldn't follow, with what you did instead.

I compare each screenshot with its board before anything goes to Yeshu's wrist. He wants to install this
build himself from Xcode once it passes; tell me what he must click for it (new permissions, capabilities).
