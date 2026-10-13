# SpotMe · iPhone build 1 · design handoff

From: SpotMe - Designer (the session in `design/` on the server). To: SpotMe - Frontend (Mac Studio).
Asked for by Yeshu on 13 Oct 2026: "get frontend complete all the latest designs so that I can test the app
further. Right now everything seems to work fine except Workout swap in watch and iOS app."

## 1 · Scope

**In:**
1. **Swap on the iPhone** (boards 7.5, 7.8; decision x). Yeshu can't swap on the phone at all today. This
   is the part he is waiting for, so build it first (section 3).
2. **Every approved iPhone screen** in look B: Today (7.1–7.8), History and Body (8.1–8.8), Plan with
   Rearrange days (9.1–9.6), Settings (10.1). Sections 4–8.
3. **Watch build 10 passed** the design check on 13 Oct: the How sheet at row size, hint and dots only
   while turning (2.12, 2.14, 2.15) and the break's short name (3.8) match their boards. Ship it in this build.
4. **Watch Swap: Yeshu can't find it** (section 9).

**Not in:** onboarding (1.9, 11.1–12.7, still under review), "more stats", and a permanent swap from the
Plan editor (not drawn yet). Nothing in `ProgressionEngine` changes. Keep `plan.json` as it is.

The repo's rules hold: no third-party code; all maths through `ProgressionEngine`. You own `docs/SPEC.md`:
update it where this handoff changes behaviour. Each section says what changes.

## 2 · Where the design is

| What | Where |
|---|---|
| A picture of every board, 440 px wide = iPhone 16 Pro Max at 1 pt = 1 px | `design/handoff/iphone-1/boards/<board>.png` (24 files) |
| The look (B · Depth): reference board and its parts | `boards/P71B-TodayDepth.png`; the parts list in `design/reviews/10-look-b-today.md` |
| The layout rules and sample data | `design/reviews/2-iphone.md` (parts, type, icons, sample data), `8-feedback-7oct-b.md` (Swap, progress chart, sessions, body points, Plan without chips), `9-look-7oct.md` (Rearrange days), `10-look-b-today.md` (Today in look B) |
| The boards as HTML (exact numbers) | `design/canvas/project/P*.dc.html` |
| Figures (the stills on rows, the moving figure in the hero and on 7.7) | the bundle you already ship on the watch (`design/handoff/watch-2/figures/`) |
| Swap alternatives | `ExerciseDatabase` in RepCoachCore (already built for the watch) |

Compare your screenshots with the PNGs the way the watch builds were checked: same strings, same places,
same sizes within a point or two.

## 3 · Swap on the iPhone (7.5, 7.8; decisions t, x) · first

- **The exercise sheet (7.5)** opens from any open row on Today, before or during the workout. It shows
  the eyebrow, the name, the three tiles and a **PROGRESS** chart card. The card shows the top set per
  session for the last 8 sessions, with each top set's reps above its dot. Tapping the card opens that
  exercise's History (8.2). Under it is a card with one row: the swap icon and **Swap exercise**, with
  "For today. Your watch changes with it." Then LAST TIME, then the note. There is no reason sentence.
  With a figure it is 7.7: the moving figure card on top.
- **Swap exercise** shows only where the watch would allow it: `today.canSwap(item)`. That means a
  weighted, reps or timed slot that has alternatives and no counted sets yet. Otherwise the row isn't there.
- **The Swap sheet (7.8)** has a close button and the eyebrow "SWAP · TODAY". It shows the current name,
  then its prescription and rest. Below that is a section "SAME MOVEMENT, YOUR EQUIPMENT" with
  `today.swapChoices(for:)` in order: name and `why`, plus a "TAKE CARE" chip where the choice is rated 2.
  A swapped item has the plan's own exercise first, "Back to the plan's exercise". The footer reads
  "For today only. It takes these sets and reps and keeps its own history. Your watch updates right away."
  The action row "See every chest exercise" may be left out of this build if it needs a new screen.
- **One tap swaps** and returns to the exercise sheet, now showing the new exercise. Today's row shows the
  new name with the 20 px swap icon before its prescription, as on the watch (1.13).
- **Sync:** `PhoneSync.swapsMade()` already sends the marks both ways. Check it against a watch on a
  break, on Today and on a set screen with nothing logged yet. The watch must show the new exercise within
  a second or two while reachable. When the watch isn't reachable, it must pick up the swap on its next
  launch.
- Spec: "Swap for today from the iPhone's exercise sheet, live to the watch".

## 4 · Look B everywhere

Today's boards (7.1–7.8) are drawn in look B. History, Plan and Settings (8.x, 9.x, 10.1) are approved for
**content and layout** but drawn in the plain parts of `2-iphone.md`. Build them with the strings, order,
sizes and spacing of their boards, but wear look B's parts from `10-look-b-today.md`:

- gradient cards with the 1 px top highlight and 28 px corners
- glass stat tiles
- chart lines with the volt glow
- the volt wash at the top of tab screens
- sheet surface `#0B0B0C`
- the 14 px gap between groups
- the primary button with its glow

Form groups (Settings, the editors, the measurement sheet) keep their rows, switches and steppers inside
look B cards. Plan rows get the 44 px figure still on the left like Today's rows. History's session rows
and Body's point rows don't. When I check, I will look at layout and strings against these boards and at
the surfaces against 7.x.

## 5 · Today (7.1–7.6)

As drawn in `10-look-b-today.md`:

- The hero has the day, "1 goes up · 1 lighter" from the engine's tags (decision g), and the first lift's
  moving figure.
- The primary button reads Start workout, then Continue with the item and set while running, and is gone
  once all is done.
- Rows show figure stills, weights with arrows and tags. There are no kind icons and no chevrons (h).
- 7.4 covers the deload week and the body-log card. 7.6 is the tick-off sheet.
- Start workout on the phone starts the session; the watch picks it up as now.
- If the phone can't start the watch session, say so and keep the button opening the watch's flow.

## 6 · History and Body (8.1–8.8; decision w)

- **History (8.1):** the sets-per-week card and a body card with three tiles: weight, arm and waist. Then
  SESSIONS, newest first. Each row has the day's name and "date · min · kcal · Effort n". On the right is
  a mint check when finished, "12 of 15" when partial. The sections by weekday are gone. Empty state: 8.3.
- **One session (8.7, new):** a 2 × 2 grid of tiles: TIME, SETS, AVG BPM in red, and EFFORT with its word.
  Then a card per exercise in plan order with set capsules, then NOT DONE. Tick-off items are left out.
  If the phone doesn't receive kcal, average heart rate or effort for a session yet, add them to what the
  watch sends at Finish.
- **One exercise (8.2):** as drawn. It is reached from 7.5's chart and from 8.7's exercise cards.
- **Body (8.4, 8.5):** ten optional points: Weight in kg, and Neck, Shoulders, Chest, Arm (flexed),
  Forearm, Waist, Hips, Thigh and Calf in inches. It is one list with the latest value and the change.
  Arm up is mint and waist up is ember. 8.5 is the waist warning, and its rule is unchanged.
- **One point (8.8):** tiles, chart and the measurements of one point.
- **New measurement (8.6):** all ten, grouped, each with a stepper: 0.25″, or 0.1 kg for weight. Blank
  stays blank.
- **Model:** `BodyMeasurement` grows from arm and waist to ten optional fields. Migrate Yeshu's existing
  rows so that arm and waist keep their values and the rest are nil. Tell me how many rows moved.
- Spec: the body log has ten fields; History lists sessions.

## 7 · Plan (9.1–9.6; decision z)

- **Plan (9.1, 9.2):** the day strip, then the day's title. Rows show "4 × 6–10 · +2.5 kg · 2:30 rest".
  There are no EDITED or ADDED chips and no "changed from the plan" footer. Edit mode (9.2) has delete
  circles and handles.
- **Editor and Add (9.3–9.5):** as drawn.
- **Rearrange days (9.6):** the more menu (…) gets "Rearrange days". The sheet lists seven weekdays, each
  with its workout and a handle. Dragging a workout onto another day swaps the two. Rest days move too.
  Weekday names never move, and history stays with the workout. The watch gets the new mapping like any
  other plan edit.
- Spec: a plan day maps a weekday to a workout, and rearranging changes the mapping only.

## 8 · Settings (10.1)

These groups, as drawn: PROGRAM, APPLE HEALTH, WATCH, YOUR DATA (the CSV export) and ABOUT. The rows
have no icons.

## 9 · Watch: Yeshu can't find Swap

Yeshu said on 13 Oct that he doesn't see swap options on the watch. Build 9 and 10 have it in two places:

- swipe left on an open row in Today
- tap the small figure on a set or break screen to open How, then **Swap exercise**

Both disappear once the item has a counted set. Please:

1. Confirm which build is on his watch. If it is older than build 9, Swap simply isn't there.
2. Check that both entry points show on his device with the real store, not only with the demo store.
   For example, is `ExerciseDatabase.shared` non-nil in the watch app's bundle on device?

Don't change the watch design here. If the entry points work and he still can't find them, I'll draw a
more visible one for him to approve.

## 10 · What I need back

- A branch off `main` for build 11, iPhone plus watch build 10.
- **Swap first:** as soon as 7.5, 7.8 and the live sync work, send me their screenshots and a 20-second
  screen recording or a written check of a swap made on the phone showing up on the watch. I check them
  and Yeshu can install that build early. Then the rest.
- iPhone screenshots on the iPhone 16 Pro Max simulator, named by board. Tall boards should be stitched
  or shown as several screenshots.
- The body migration count, and the answer to section 9.
- Anything in the rules you couldn't follow, with what you did instead.

I compare each screenshot with its board before anything goes to Yeshu's phone. He installs from Xcode.
Tell me what he must click, if anything: new capabilities or permissions.
