# 5 · Yeshu's notes of 6 Oct · review and build rules

Reviewer and planner: Fable. Builders: Opus agents. Yeshu's five points after looking at the canvas, what was
found in the code, and what is designed for each. Watch boards follow `1-watch.md`; figures follow
`../figures/FIGURES.md`.

## 3 · Options chosen

Yeshu: "I like your recommendations of 2.1A & 3.1A." The set screen is 2.1A (side by side) and the rest screen
is 3.1A (timer round the edge). 2.1B and 3.1B move to the Backlog page as not chosen. This picks the options;
it is not yet a yes to build.

## 1 · Ramp-up sets

Yeshu: last time 20 kg × 12 was the limit; the next session should not start cold at 20 kg but build up to it.

Today the engine sets the working weight for set 1 (the same 20 kg, or one step more if every set reached
the top) and the first set is already at that weight. What is missing is the build-up before it. The design
adds **ramp-up sets**: one or two lighter, short sets before the first working set. The working sets, their
weight and the "beat last time" comparison stay exactly as they are, because climbing through the working sets
themselves would put the heaviest set last, when you are tired, and make sessions impossible to compare.

Proposed rule (new engine function: it goes into `docs/engine_reference.py` and its tests first, as the repo
rules say; nothing here changes existing engine behaviour):

- Ramp-up weight = working weight × factor, rounded down to the exercise's increment.
- The first main lift of the day (the first weighted exercise whose rest is 2:00 or longer): two ramp-ups,
  50% × 8 reps and 75% × 4 reps. Other main lifts: one, 70% × 5. Smaller lifts: none by default.
- A ramp-up whose weight rounds to zero, or to the same as the one before it or the working weight, is left out.
- No ramp-ups the first time an exercise is done (no working weight yet). In a deload week they are worked
  out from the deload weight.
- Ramp-ups are tapped off, not entered. They do not count as sets, never feed progression, and are saved with
  the session marked as ramp-up so History and the CSV can leave them out.
- Rest after a ramp-up: 60 seconds, with the usual +30 and skip.
- iPhone Settings, Program: "Ramp-up sets" with Off · Main lifts (default) · Every weighted lift (the smaller
  lifts then get one at 70% × 5).

Examples with the plan's numbers: Incline DB Press at 22.5 kg → 10 kg × 8, then 15 kg × 4, then Set 1 at 22.5.
The 20 kg × 12 case with 2.5 kg steps → 10 kg × 8, 15 kg × 4, then Set 1 at 20 kg with "Last 12" beside it.

## 2 · Effort after a workout

Found: no build in the repo asks for effort or has the permission for it; the watch asks Health for workouts
only (`HealthWorkout.shareTypes`). So this is new, not a regression in SpotMe's code.

Design: after Finish the watch asks "How hard was it?" on Apple's 1 to 10 scale (1–3 Easy, 4–6 Moderate, 7–8
Hard, 9–10 All Out), turned with the Crown. It is saved with the workout as its effort rating, so Fitness
shows it and Training Load counts it, and kept in SpotMe's session too. Health then needs one more permission,
"Workout Effort" (write), which the watch asks for once. Skipping the question saves the workout without one.
With "Save workouts to Health" off the question is still asked and the answer stays in SpotMe.

## 4 · Skip means "later"

Found: Skip in the controls marks the exercise finished (done if it has sets, skipped if not). Getting it back
needs a swipe on the Done list, which nobody finds. Separately, the controls page sizes its buttons from the
measured screen height, which is wrong for one frame on first appearance: the icons draw small, then grow.

Design:
- **Skip (controls) jumps to the next open exercise and leaves this one open.** Sets already logged stay. The
  workout comes back to it after the last other exercise, or sooner if it is tapped in Today.
- Dropping an exercise for the day is a different act: swipe it in Today ("Skip today"), or Finish.
- A row skipped for the day says "Skipped · tap to do it", and a tap reopens it.
- The redesigned controls (5.1) use fixed sizes, so nothing resizes on first appearance.

## 5 · Turning a figure

Yeshu: "can we rotate them to see all side angles?" Yes, if a pose stores depth as well: three numbers per
point instead of two. The same figure can then be drawn from any angle, turned with the Digital Crown on the
watch and with a finger on the iPhone. Proof of concept: three figures in `../figures/poses3d/`, drawn by
`../figures/figure3d.py`. See "Turning a figure" in `FIGURES.md`.

## Boards

Sample moment unless said: Wednesday, Push A, as in `1-watch.md`.

**2.13 `W213-RampUp.dc.html` · Ramp-up set** (watch, from `W24-SetReps.dc.html`). Top-bar title "Ramp-up" in
ice. Name "Incline DB Press". Hint row: left "1 of 2 · not counted" in detail style `#B8B8BD`; right a text
button "Skip" in detail style white 600 (`aria-label="Skip the ramp-up"`, at least 60 px high by padding).
One wide tile, not focused (card fill, hairline, not a button): "10 kg × 8" on one line at 64 / 68 / 700 white,
and under it the eyebrow "WORKING WEIGHT 22.5 KG" in `#8E8E93`. Primary button "Done". Page dots.

**3.13 `W313-RestRampUp.dc.html` · Rest · after the last ramp-up** (watch, from `W31A-RestEdge.dc.html`). 70%
left, "0:42". Heart 104. Eyebrow "NEXT · SET 1 OF 4". "22.5 kg" white, no arrow. Reason line: "Last time 10
reps". No Undo button (a ramp-up is not logged); +30 and skip stay.

**5.8 `W58-Effort.dc.html` · Effort** (watch, sheet top bar: close icon, title "Effort" in volt, no page dots).
Fitted column, centred: "How hard was it?" in row style (30 / 34 / 600); then (`margin-top: 6px`) the number "7"
at 96 / 100 / 800 white with the word "Hard" under it in 30 / 34 / 700 ember; then (`margin-top: 12px`) a row of
ten segments (`gap: 4px`, each `flex: 1; height: 10px; border-radius: 5px`): the first seven filled, the rest
`#2C2C2E`; fill colours by band: segments 1–3 mint, 4–6 volt, 7–8 ember, 9–10 red. Under the bar
(`margin-top: 6px`) eyebrow `#8E8E93` "TURN THE CROWN". Spacer. Primary button "Save".

**5.9 `W59-SummaryEffort.dc.html` · Summary with effort** (watch, from `W56-Summary.dc.html`). The same, with
the fourth tile changed from kcal to effort: value "7" in ember, label "EFFORT · HARD".

**5.10 `W510-ControlsSkip.dc.html` · Controls · Skip means later** (watch, from `W51-Controls.dc.html`). The
four buttons 80 px high. Under the grid two centred lines in small style: "Skip to Cable Lateral Raise" in
`#B8B8BD`, and "This one stays open" in `#8E8E93` (each one line).

**1.10 `W110-TodayWaiting.dc.html` · Today · one waiting** (watch, from `W13-TodayRunning.dc.html`). Bar "3/15".
Continue button's second line "Cable Lateral Raise". Rows: Seated DB Shoulder Press with the detail "1 of 3 sets
· waiting" in ice and "17.5 kg" on the right; then Cable Lateral Raise "4 × 12–15" / "7.5 kg" (cut by the edge).

**3.14 `W314-BreakBack.dc.html` · Break · back to a waiting one** (watch, from `W38-Break.dc.html`). 60% left,
"0:27". Above the name (`margin-top: 6px`) an eyebrow "SKIPPED EARLIER" in ice; the name "Seated DB Shoulder
Press" with its chevron; target "Set 2 of 3 · " + "17.5 kg"; summary neutral: check + "Logged". If it does not
fit, set the countdown at 80 / 80.

**13.2 `F132-Turn.dc.html` · Turning a figure** (1280 × 820, `border-radius: 0`, background `#0B0B0C`, padding
40; the same heading style as `F131-Figures.dc.html`: the mark + "Turning a figure", and on the right "3 of 247
· proof of concept"). Three rows, one per figure in `../figures/poses3d/` (Incline DB Press, Bulgarian Split
Squat, Pull-ups), each a card (`background: #000000; border-radius: 24px; padding: 14px 18px`), a row
`gap: 18px; align-items: center`: first the turning figure at 196 px (the SVG from `figure3d.py` that turns
through a full circle while it moves) with the exercise name under it in 17 / 22 / 600; then six stills at 132 px
of the end pose seen from 0°, 60°, 120°, 180°, 240° and 300°, each with its angle under it in eyebrow style
`#8E8E93`. This board may be put together with a short script. `$preview` 1280 × 820.

**2.14 `W214-HowTurn.dc.html` · How · turn it** (watch, from `W212-How.dc.html`). The figure is the 3D
incline-db-press seen from 40° (moving, not turning). Under the name, in place of the cue, one line in 22 / 28 /
600 ice: "Turn the Crown to look around". Under it a row of seven 8 px dots (`gap: 6px`), the third volt, the
others `#3A3A3C` (where you are in the turn).

## Round 1 result (6 Oct 2026)

All nine boards built, checked and looked at by the planner; on the canvas under Under review, in the row
"From your notes of 6 Oct". 13.2 is 1280 × 940 (three rows of 252 px did not fit 820). 2.1B and 3.1B are on the
Backlog page. To pass on to the Mac builder with the first approved batch: the controls page must not size its
buttons from measured height (fixed sizes, as board 5.1), which removes the small-then-normal icons on first
appearance.

## Approved, 6 Oct 2026

Yeshu approved all watch designs "based on your recommendations" and named the builder: SpotMe - Frontend
(Mac Studio). The build spec is `../handoff/watch-1/BUILD.md`; it is the reference from here on. Points it
settles beyond the text above:

- Ramp-up reps never go above the top of the rep range. An exercise whose weight is added to bodyweight
  (weighted pull-ups) ramps up at bodyweight × 5, plus half the added weight × 3 when it is the first main
  lift. The rule and its vectors are in `../handoff/watch-1/rampup_reference.py`.
- Skip puts an exercise off; it comes back before the cooldown. Skip during a rest puts it off too.
- How is one screen: the Crown hint shows until he has turned a figure once, then the cue.
- Every exercise in the plan gets a figure, and every one turns (one renderer in the app, not two).
- To tell Yeshu: the plan's warmups already end with a light set of the first lift ("1 × 10 at ~50%"),
  which is the first ramp-up twice over. The ramp-up screen has Skip; the warmup step can go later.
