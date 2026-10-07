# 7 · Yeshu's notes of 7 Oct · review and build rules

Reviewer and planner: Fable. Builders: Opus agents. Yeshu's three points after his first real session on build
8, what was found, and what is designed for each. Watch boards follow `1-watch.md` (parts, type, colours) and
reuse the markup of the boards named "from".

## 1 · The rest timer's edge line is cut at the corners

Found: a build problem, not a design one. The handoff says the line follows the display's own corner shape,
inset 4.5 pt; on the real 46 mm watch the corners clip it, so the path's radius is smaller than the screen's.
Simulator screenshots did not show it. Sent to SpotMe - Frontend (Mac Studio) on 7 Oct with a request for a
photo from the real watch. No board.

## 2 · Finish with items left

Yeshu: he left the last core items, finished the workout, and the watch kept showing Continue; at the end of
the list the only way out was Discard. "Technically today's workout is done, now there should be option to
start again."

Found: a design gap. The boards cover Finish when everything is done (1.6, 5.5) and End mid-workout (5.3), and
the spec says the Health workout runs "while today's session isn't finished", but nothing says what Today
shows after a Finish that leaves items open. The build kept the running state.

Design: **a Finished state for Today.**

- After any Finish the day is finished. Today shows a Finished card (time, effort; tap it for the summary,
  5.6 / 5.9), then what is left under NOT DONE, then DONE. No Continue, no Finish.
- **Start again** (neutral button under the card, only when something is left) picks up the open items in
  the same session: done items stay done, the next open item opens as Start workout would, and the Today
  running state (1.3) is back. Tapping a NOT DONE row does the same, starting on that row. Health gets a
  second workout for the second part; the first is already saved and stays. Finishing again asks the
  effort again, starting from the first answer; the new answer is kept with the session and written to the
  second Health workout.
- Discard workout stays at the very end of the list after a Finish. It deletes today's sets and the
  workout(s) SpotMe wrote to Health today.
- The "Up next" complication shows "Done" while the day is finished and the next open item again after
  Start again.
- Spec lines to add: Today's finished state; Start again; Discard after Finish deletes the Health workouts.

## 3 · "Machine Chest Press (or Flat Bench)" is two exercises in one

Yeshu: "It should be one workout and if I want to switch the workout then there should be option. One day if
I did machine and another day if I do flat bench then how will my weight get tracked properly."

Found: `plan.json` has one slot, name "Machine Chest Press (or Flat Bench)", id
`machine-chest-press-or-flat-bench`, so machine and bench sets feed the same history and the same suggestion.
The exercise database already lists Machine Chest Press with six alternatives, and the onboarding design
(12.4) already has a Swap sheet for the iPhone. The backlog has "workout alternatives" since 1 Oct.

Design: **one exercise per slot, and Swap.**

- The slot becomes **Machine Chest Press** (id `machine-chest-press`, the database's id). History logged under
  the old id becomes Machine Chest Press history, once, on first launch of the build that renames it.
- **Swap** replaces today's exercise with one that trains the same thing. Where: the How sheet (2.12, reached
  from the figure button on the set screen and the name on the break screen) gets a Swap button; Today rows
  get a Swap swipe action beside Skip today. The Swap sheet lists the exercise's `alternatives` from
  `../exercise-db/exercises.json`, in the database's order, leaving out any rated 3 (avoid) for Yeshu's
  injury areas and chipping any rated 2 TAKE CARE, exactly as 12.4 does. One tap swaps and returns to where
  you were.
- The swapped-in exercise takes the slot's sets, reps and rest, and brings **its own history, suggestion and
  increment** (`incrementKg` from the database). The first time it is 2.3 (First time); after that the
  engine works from its own sessions. Nothing from the slot's other exercise is mixed in.
- A swap on the watch is for today. The plan keeps Machine Chest Press; tomorrow's Push A shows it again. To
  change the plan for good: the iPhone's Plan editor (9.x) and the exercise screen (7.5) get Swap in the
  iPhone round, using the 12.4 sheet. Not drawn now (watch first).
- Rules the engine already has stay; nothing new in `ProgressionEngine`. The change is in the plan data, the
  slot → exercise mapping in the session, and the id migration.

## Decisions for Yeshu

- r · After Finish with items left, Today shows Finished with what is left; Start again picks them up in the
  same session, Health gets a second workout, effort is asked again.
- s · The slot becomes Machine Chest Press alone, and everything logged under the old name counts as Machine
  Chest Press. (Say if most of those sessions were on the bench instead.)
- t · A swap on the watch is for today only. Changing the plan for good is an iPhone job (comes with the
  iPhone round).
- u · The swap list is the database's alternatives for the exercise, the same list onboarding uses.

## Boards

Watch, 46 mm, 416 × 496, `border-radius: 96px`, page Under review. Canvas row title: "Review next · 7 Oct:
Finished, and Swap (1.11–1.13, 2.15, 2.16)". The data: Wednesday, Push A, "Chest & Shoulders + Core A", 15
items (1 Warmup · 7 min, 2 Incline DB Press 4 × 6–10 22.5 kg, 3 Machine Chest Press 3 × 8–10 45 kg, 4 Seated
DB Shoulder Press 3 × 8–10 17.5 kg, 5 Cable Lateral Raise 4 × 12–15 7.5 kg, 6 Overhead Cable Extension 3 ×
10–12 17.5 kg, 7 Rope Pushdown 3 × 12–15 22.5 kg, 8 Hanging Leg Raise 3 × 8–12, 9 Cable Crunch 3 × 12–15,
10 Bicycle Crunch 3 × 20, 11 Hanging Knee-to-Elbow Twist 3 × 8/side, 12 Russian Twist (weighted) 3 × 20,
13 Toe Touches 3 × 15, 14 Grease the Groove 4–5 × 40%, 15 Cooldown stretches 5 min). Clock "10:09".

**1.11 `W111-TodayFinished.dc.html` · Today · finished, 3 left** (from `W110-TodayWaiting.dc.html`). Bar title
"12/15" in mint `#47EBA3` (the day is finished), clock. Column `top: 84px; gap: 12px`:
1. The day button exactly as W110 ("WEDNESDAY · PUSH A" eyebrow in volt, chevron, same negative margins).
2. Finished card: `<button>` in row-card style (`padding: 14px 20px 16px; border-radius: 34px; background:
   #1C1C1E`) laid out `display: flex; align-items: center; gap: 14px`: a 52 px circle
   `rgba(71,235,163,0.16)` holding the check icon 30 px mint (`flex-shrink: 0`); then a column: "Finished"
   in row style white; under it "48 min · Hard 7" in detail style `#B8B8BD`.
3. Start again: neutral button `background: #2C2C2E`, height 108, `border-radius: 44px`, a centred column
   `gap: 0`: "Start again" in button style white; under it "3 left" 22 / 26 / 700 `#B8B8BD`.
4. Eyebrow "NOT DONE" (`padding: 10px 12px 2px`), then rows (`gap: 8px`) in the open row style (name white
   600, detail `#B8B8BD`, no weight): 11 Hanging Knee-to-Elbow Twist "3 × 8/side"; 12 Russian Twist
   (weighted) "3 × 20", cut by the screen edge. (Off screen: 13 Toe Touches, then eyebrow DONE and the done
   rows as 1.5, then the red Discard workout text button.)

**1.12 `W112-TodayFinishedAll.dc.html` · Today · finished, all done** (from 1.11). Bar "15/15" in mint. Day
button; Finished card with "62 min · Hard 7"; no Start again; eyebrow "DONE" (`padding: 10px 12px 2px`); done
rows exactly in the style of `W15-TodayEnd.dc.html` (name `#B8B8BD` 500, detail `#8E8E93`, check 26 px mint
on the right): Warmup · 7 min "Done"; Incline DB Press "4 sets · 22.5 kg"; Machine Chest Press "3 sets · 45
kg" (cut by the screen edge).

**1.13 `W113-TodaySwapped.dc.html` · Today · a swapped exercise** (from `W12-TodayList.dc.html`, the list
scrolled, with its fade). The rows in plan order from Incline DB Press (under the fade, as the first row of 1.2
is), then in Machine Chest Press's place: name "DB Bench Press"; detail row left: the swap icon 20 px `#8E8E93`
then "3 × 8–10" in detail style; right: "First time" in detail style, weight 700, volt (no weight is known yet;
the same words as 2.3). Then Seated DB Shoulder Press, Cable Lateral Raise, Overhead Cable Extension (cut).

**2.15 `W215-HowSwap.dc.html` · How · with Swap** (from `W212-How.dc.html`). The same sheet (close icon, "How"
in volt, clock, column from `top: 70px`), with a longer cue and one more item: the figure is machine-chest-press
at 250 px (moving, made with `figures/figure3d.py`'s `svg`, as the gallery board is); name "Machine Chest
Press" in row style; cue in 22 / 28 / 500 `#B8B8BD`, centred, `padding: 0 24px`, three lines: "Handles at
mid-chest, feet planted. Push close to failure safely; control the way back."; then `margin-top: 16px` a text
button (no fill, height 60, 26 / 30 / 600, white, centred, `gap: 8px`): the swap icon 24 px + "Swap exercise".
The sheet scrolls; the board shows its top, so the button's label is just above the screen edge and the button
box is cut by it. (A scrolled view was tried and dropped: it hid the figure's movement.)

**2.16 `W216-Swap.dc.html` · Swap** (sheet, from `W310-BreakPick.dc.html`). Close icon, title "Swap" in volt,
clock. Column `top: 84px; gap: 8px`: a line in small style `#8E8E93`, weight 500, `padding: 0 12px`:
"Instead of Machine Chest Press"; then rows in the open row style, each a column `gap: 2px`: the alternative's
name in row style white and under it its `why` in 22 / 28 / 500 `#B8B8BD` (two lines allowed): DB Bench Press
"Free weights, deeper stretch, same flat press"; Smith Machine Bench Press "Fixed bar path when the machine is
taken"; Barbell Bench Press "Classic flat press, heaviest loading" (cut by the screen edge). No chips: none of
the six is rated 2 or 3 for the lower back. Off screen: Standing Cable Chest Press, DB Floor Press, Push-Up,
then a footer in small style `#8E8E93`: "Today only. It takes these sets and reps and keeps its own weights."

Icons: swap `M7 7h11l-3-3M17 17H6l3 3` (from `3-onboarding.md`), stroke as the icon table in `1-watch.md`.

## Canvas

New row on the Under review page, above the iPhone row: title note `row7oct` at `y: -1630`, boards at
`y: -1300`, `x` 0, 496, 992, 1488, 1984 (order 1.11, 1.12, 1.13, 2.15, 2.16), `radius: 96`. A decision note
(orange, `w: 560`, `x: 2600, y: -1300`) with r–u in Yeshu's words as the other decision notes do. The
existing row7 title stays where it is.
