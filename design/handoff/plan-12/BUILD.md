# SpotMe · plan 12 and a figure for every swap · handoff

From: SpotMe - Designer. To: SpotMe - Frontend (Mac Studio). Asked by Yeshu on 13 Oct 2026, with "Send final
instructions to frontend":

> Tuesday: instead of the current plank, a weighted plank. Wednesday (Push A): Barbell Bench Press first, Incline
> DB Press second. Thursday: Single-Arm Cable Row → both arms. Friday: move Push B to Saturday and put a new Leg
> day on Friday. Sunday: rest day, nothing. Monday and Saturday: OK. And make sure every replacement workout
> (swap) has its image; a few are missing.

No new screens: the approved boards already show whatever the plan holds. Nothing in `ProgressionEngine` changes.

## 1 · The plan: version 12

Replace `Packages/RepCoachCore/Sources/RepCoachCore/Resources/plan.json` with `design/handoff/plan-12/plan.json`
(written from v11 by script; only what is below differs).

| Day | v11 | v12 |
|---|---|---|
| Mon | Recovery Run + Pull A | unchanged |
| Tue | Legs · Run-Supportive, ends with Copenhagen Plank 2 × 20s/side | Copenhagen Plank → **Weighted Plank** 3 × 30–45s (loadable, as Sunday's was), in its own group "Core" |
| Wed | Push A: Incline DB Press first | **Barbell Bench Press** 4 × 5–8, +2.5 kg, 3:00 rest, first; Incline DB Press second; the rest unchanged. Time "~80 min · no run" |
| Thu | Single-Arm Cable Row 3 × 10–12/side | **Seated Cable Row** (both arms, V-handle) 3 × 10–12, +2.5 kg, 1:30 rest |
| Fri | Tempo Run + Push B | **Legs B · Strength + Posterior Chain**, no run, ~55 min (below) |
| Sat | Full Rest | **Tempo Run + Push B**, exactly as Friday's was |
| Sun | Long Run + Mobility + Core B | **Full Rest** (Nothing Structured, Eat + Sleep) |

Friday · Legs B (spine-safe like the rest of the plan: nothing loads the lower back above "take care"):
Warmup 7 min · Hack Squat 4 × 6–10 (+5 kg, 2:30) · Reverse Lunge (DBs) 3 × 8–10/leg (+2.5, 2:00) · Seated Leg Curl
3 × 10–12 (+5, 1:15) · Cable Pull-Through 3 × 12–15 (+2.5, 1:15) · Seated Calf Raise 4 × 12–15 (+5, 1:15) ·
Tibialis Raise 2 × 15–20 (reps, 0:45) · Cooldown 5 min.

Ids and history:
- History is keyed on `exerciseId`, so every unchanged lift keeps its history. New ids (`barbell-bench-press`,
  `seated-cable-row`, `hack-squat`, `reverse-lunge`, `seated-leg-curl`, `cable-pull-through`,
  `seated-calf-raise`, `tibialis-raise`) start fresh; the watch asks the first weight as it does today.
- Push B's warmup and cooldown ids become `saturday-warmup` / `saturday-cooldown`; Legs B's are `legs-b-warmup` /
  `legs-b-cooldown`.
- **Day keys move:** key `friday` was Push B and is now Legs B; Push B is now `saturday`; `sunday` is Full Rest.
  Anything stored by day key must keep Push B's past sessions as Push B: finished sessions in History (8.1, 8.7),
  an unfinished session, the Rearrange days mapping, plan edits per day. If Yeshu saved a Rearrange days mapping,
  reset it to the plan's and tell me. Plan edits on items that still exist stay; edits on removed items
  (Copenhagen Plank, Single-Arm Cable Row, Sunday's items) are dropped: tell me if any existed.
- Long Run, the Sunday mobility and Core B leave the week, at Yeshu's word ("Sunday: rest day, nothing").
- Update what pins v11 (`PlanTests` expects 11; Settings will read "v12 · n items") and `docs/SPEC.md`'s week.

## 2 · The exercise database

Copy `design/exercise-db/exercises.json` to `Resources/exercises.json`. The only change: the eight new lifts have
their own `planIds`, so Swap finds their alternatives. Removed exercises keep their `planIds` (history uses them).

## 3 · A figure for every swap (landed 13 Oct)

Today 46 of the exercises a swap can offer have a figure; 130 don't, and the figure bundle is keyed only by plan id,
so a swapped item never shows one. Both are being fixed:

- **Bundle shape (no change to the format):** `figures.json`'s `exercises` map now lists every database exercise
  that has a figure under its **database id**, plus plan exercises under their plan ids as before.
- **App change, do it now:** wherever a figure is looked up for an item (Today rows and hero, 7.5 / 7.7, the watch's
  How and set screens, the Plan rows), use the swapped-to database id when the item is swapped today, else the
  plan's `exerciseId`. The Swap sheet (7.8) rows show each alternative's 44 px still by its database id. Without
  a figure the slot stays empty, as now.
- **The figures:** 130 new ones, checked (all alternatives of the v12 plan's lifts, except those rated "avoid" for
  the lower back, which Swap never offers, plus the eight new lifts). Copy `design/figures/bundle/figures.json` to
  `Resources/figures.json`: 180 figures under 192 ids, 226 KB. No new load types: everything is drawn with the
  parts `FigureRenderer` already has, so the Swift side needs no renderer change. Tell me if any figure draws
  differently from `figure3d.py`.

## 4 · What I need back

A branch off `main` (build 13), iPhone and watch. Screenshots: watch Today for Friday (Legs B) and Wednesday
(Barbell Bench first, its figure in the hero on the phone); iPhone Plan for Friday, Saturday and Sunday; Tuesday's
Weighted Plank row; a swap on the phone to an exercise that had no figure before (7.8 with stills, then 7.7), and
the watch's How after it. Plus: what moved by day key, and any plan edits or mapping that were dropped or reset.
