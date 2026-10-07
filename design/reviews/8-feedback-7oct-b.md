# 8 · Yeshu's nine notes of 7 Oct · review and build rules

Reviewer and planner: Fable. Builders: Opus agents. Yeshu's notes after looking at the canvas on 7 Oct (the
7 Oct boards from `7-feedback-7oct.md` and the iPhone round from `2-iphone.md`), what was found, and what is
designed for each. Watch boards follow `1-watch.md`; iPhone boards follow `2-iphone.md` (parts, type, sample
data); figures follow `../figures/FIGURES.md`.

## 1 · 2.15: the figure is wrong and the sheet is tight

Yeshu: "very close to edges … Pole should be on back, isn't it?"

Found: the machine-chest-press figure drew the machine's frame in front of the lifter and the levers from a
pivot overhead; a chest press has the backrest and frame behind and the handles in front. The shoulder press
machine figure had the same fault. The How sheet put a 250 px figure, a three-line cue and a button on a
496 px screen, so everything touched the edges.

Design: the figure is redrawn (frame and pivots behind the backrest, levers coming forward to handles at
mid-chest). On the How sheet the figure is 200 px when the cue runs to three lines, so the column
(figure, name, cue, Swap) fits with the Swap button whole and clear of the bottom. 2.15 is rebuilt that way.

## 2 · No reason text on rest

Yeshu: "we do not need to explain why SpotMe app is increasing or decreasing the weights. It should happen
automatically, so during rest periods do not show that text."

Design: the rest screen shows the countdown, heart rate, NEXT · SET n OF m and the next weight with its arrow.
The reason line ("In range", "5 reps, below 6", "17 reps, above 15") is gone. The break screen loses the
"how the finished exercise went" line as well ("All sets 10 · next time 25 kg", "Aim for 15 reps on every
set", "Logged", "12 reps · volume sets of 7"), and All done (5.5) loses its last-exercise line and shows
"Push A · 62 min" under the title, as 1.6 does. The arrows stay: they say up or down without explaining.
Kept: "Last time 10 reps" on the rest before the first working set (3.13); it is information, not a reason.

Boards edited in place (they were live as build 8): 3.1A, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.11, 3.12,
3.14, 5.5. They move to Under review until built, then back to Live · Watch. Spec: the rest and break
descriptions lose their reason lines; `ProgressionEngine` still produces them (History and the CSV keep
them).

## 3 · 7.7 and every helper figure

Yeshu: "In 7.7, user is below the table … review all the helper screens so that it doesn't look bad."

Found: incline-db-press had the backrest pad drawn above the body. An audit of all 50 (`figures/`, sheets in
the session's scratch) found 12 to fix: machine-chest-press, incline-db-press, machine-shoulder-press (frame
in front), l-sit (read as sitting on a stool), bicycle-crunch (no visible movement), russian-twist (plate on
the chin), side-plank-with-reach (read as a two-arm plank), superman-hold (too flat to read), and four small
ones (chest-supported-db-row legs, reverse-pec-deck pad covering the torso, band-assisted-pull-ups hanging
off vertical, hanging-leg-raise bar ending at the hands). All 12 are redrawn through their authoring scripts;
the bundle and golden vectors are rebuilt; boards 2.11, 2.12, 2.14, 2.15, 3.12, 7.7, 13.1, 13.3 are
re-rendered where they show a changed figure. Yeshu sees the sheet of all 50 (13.3) before the builder gets
drop 3.

## 4 · Swap from the iPhone, during the workout

Yeshu: "During workout, we shall have option to swap the workout and it instantly sync with watch."

Design: the exercise sheet on the iPhone (7.5, opened from any open row on Today, before or during the
workout) gets a **Swap exercise** row. It opens the Swap sheet (7.8, the onboarding Swap sheet 12.4 with
today's wording). Picking one swaps it for today, on the phone and on the watch at once: the phone sends the
swap over the live connection (`sendMessage` when the watch is reachable, the application context as the
fallback), and the watch applies it to the open item wherever it is, including on a break or on Today. The
watch's own Swap (2.15, 2.16) tells the phone the same way. Decision t stays: for today only; the Plan editor
changes the plan for good (its Swap comes with 9.3 in the next step; not drawn now).

## 5 · A progress chart on every exercise

Design: the exercise sheet (7.5) gets a chart card under the stat tiles: the top set per session over the
last eight sessions, the reps of that set written above each point, in the style of 8.2's chart. Tapping the
card opens the exercise's History (8.2). The one-line reason under the tiles goes (note 2 applies on the
phone too); the tag on the Today row ("+5 kg", "lighter") and the arrow in the tile stay.

## 6 · History as sessions

Yeshu: "we do not need to show the workouts but just simple push a done, cal, time etc info is better instead
of long list of workouts."

Design: History keeps the week card and the body card, and the sections by weekday go. In their place a
SESSIONS list, newest first: the day's name, the date with the time, calories and effort, and whether it was
finished. Tapping a session opens it (8.7, new): the watch's summary numbers and every exercise's sets.

## 7 · More stats

Noted for later: hours trained, calories, weeks on the program, progress over the month. Not drawn now.

## 8 · Body: all points, simpler

Yeshu: "we shall check all the points not just arm & waist. We can show in simpler way instead of these cards."

Design: ten points, all optional: Weight (kg) and, in inches, Neck, Shoulders, Chest, Arm (flexed), Forearm,
Waist, Hips, Thigh, Calf. Body (8.4) becomes one list: a row per point with its latest value and the change
since the last measurement; no charts at the top. Tapping a row opens that point's chart and its
measurements (8.8, new). The measurement sheet (8.6) has all ten, grouped, each with a stepper; a point left
blank stays blank. The waist rule stays and keeps its warning card (8.5): waist up while the arm hasn't grown.
The body card on History shows the three that matter most (weight, arm, waist). Spec: the body log's fields
grow from two to ten; the rule is unchanged.

## 9 · Plan: no Edited or Added

Yeshu: "I don't think in plan we need to show edited or added … there is nothing to show edited or added."

Design: the EDITED and ADDED chips and the footer "Wednesday is changed from the plan" go from 9.1 and 9.2.
The plan is the user's; every exercise is simply in it.

## Decisions for Yeshu

- v · The break screen also loses its result line, and All done its last-exercise line (note 2 taken to the
  whole workout). The watch still says up or down with the arrow.
- w · Ten body points: weight, neck, shoulders, chest, arm, forearm, waist, hips, thigh, calf. Fewer if you
  want.
- x · Swap from the iPhone is for today only, like the watch (t). The Plan editor changes it for good.

## Boards

### Watch (46 mm, 416 × 496, `border-radius: 96px`)

**2.15 `W215-HowSwap.dc.html` · How · with Swap** (rebuilt). As the 7 Oct rule but: the figure is the
redrawn machine-chest-press at 200 px (`figure3d.svg(..., size=200)`); column from `top: 70px`; name,
three-line cue, `margin-top: 14px` the Swap text button. The button must be whole with at least 24 px under
it.

**3.1A–3.7, 3.8, 3.9, 3.11, 3.12, 3.14, 5.5**: edited in place as in note 2 (done by the planner; no builder
step).

### iPhone (440 wide, 1 pt = 1 px, parts from `2-iphone.md`)

Sample data as `2-iphone.md`, with these additions. The chest slot is now "Machine Chest Press" everywhere
(decision s). Sessions, newest first (day name · date · time · kcal · effort · result):
- Push A · Wed 7 Oct · 48 min · 342 kcal · Hard 7 · 12 of 15
- Legs · Tue 6 Oct · 58 min · 410 kcal · Hard 8 · done
- Pull A · Mon 5 Oct · 66 min · 388 kcal · Moderate 6 · done
- Mobility + Core B · Sun 4 Oct · 34 min · 150 kcal · Easy 3 · done
- Push B · Fri 2 Oct · 71 min · 420 kcal · Hard 7 · done
- Pull B · Thu 1 Oct · 63 min · 360 kcal · Moderate 6 · done
- Push A · Wed 30 Sep · 62 min · 395 kcal · Hard 7 · done
Body, measured 6 Oct (change since 22 Sep): Weight 72.4 kg (+0.3) · Neck 15″ (±0) · Shoulders 46″ (+0.25) ·
Chest 38.5″ (+0.25) · Arm 14.5″ (+0.25) · Forearm 11.5″ (±0) · Waist 32.25″ (±0) · Hips 37″ (±0) · Thigh 22″
(+0.25) · Calf 14.5″ (±0). Arm history: 8 Sep 14.25, 22 Sep 14.25, 6 Oct 14.5.
Machine Chest Press sessions (Wednesdays): 9 Sep 35 × 10, 10, 9 · 16 Sep 35 × 10, 10, 10 · 23 Sep 40 × 10, 9,
8 · 30 Sep 40 × 10, 10, 10. Target today 45 kg (up).

**7.5 `P75-Exercise.dc.html` · exercise sheet** (revised, 440 × 1100, sheet, close icon right, no title).
Content `gap: 16px`: eyebrow "CHEST" `#8E8E93`; "Machine Chest Press" title; three stat tiles SETS 3 · REPS
8–10 · WEIGHT 45 kg (value volt with the up arrow 18 px). No reason sentence. Then a chart card (a `<button>`
in card style): header row with eyebrow "PROGRESS" volt and "Last 4 sessions" foot `#8E8E93` right; a 160 px
line chart in the 8.2 style: y axis 30 to 50 with labels 35, 40, 45 at the left, x labels "9 Sep", "16 Sep",
"23 Sep", "30 Sep"; the top-set series 35, 35, 40, 40 in volt with the soft area under it; above each dot the
reps of that top set in foot 700 white: "10", "10", "10", "10"; no second series, no legend. Then a card with
one action row: swap icon 22 px volt + "Swap exercise" headline volt, and under it in sub `#B8B8BD` "For today.
Your watch changes with it."; then the LAST TIME card ("Wed 30 Sep" right, "40 kg × 10, 10, 10"); then the
note card "Machine lets you push close to failure safely. Feet planted."

**7.7 `P77-ExerciseFigure.dc.html`** (re-rendered): the same board with the redrawn incline-db-press figure.
No other change.

**7.8 `P78-Swap.dc.html` · Swap · from Today** (new, 440 × 956, sheet with the close button). Built from
`O124-Swap.dc.html`: eyebrow "SWAP · TODAY" `#8E8E93`; "Machine Chest Press" title; "3 × 8–10 · 2:30 rest" sub.
Section "SAME MOVEMENT, YOUR EQUIPMENT" with the six alternatives from the database in order (DB Bench Press,
Smith Machine Bench Press, Barbell Bench Press, Standing Cable Chest Press, DB Floor Press, Push-Up), each: name
headline, `why` sub `#B8B8BD`; no chips (none is rated 2 or 3 for the lower back). Then the action row card
"See every chest exercise" volt. Footer foot `#8E8E93`: "For today only. It takes these sets and reps and keeps
its own history. Your watch updates right away."

**8.1 `P81-History.dc.html` · History** (revised, 440 × 1424). Large title, share icon, tab bar. Cards:
- Sets per week, as before.
- Body: eyebrow "BODY" volt; three stat tiles (raised): WEIGHT "72.4" with unit "kg" and "+0.3" mint under it;
  ARM "14.5″" with "+0.25″" mint; WAIST "32.25″" with "±0″" `#B8B8BD`; "Measured 6 Oct" foot `#8E8E93`.
- Eyebrow "SESSIONS" and one card of rows (the Row part), newest first, from the sample list: name in
  headline ("Push A"); detail in sub `#B8B8BD` "Wed 7 Oct · 48 min · 342 kcal · Hard 7"; on the right, for a
  finished session the check icon 20 px mint, for a partial one "12 of 15" foot 700 `#B8B8BD`. Seven rows.
  Below the card a foot `#8E8E93` line: "22 sessions since 7 Sep".

**8.7 `P87-Session.dc.html` · one session** (new, 440 × 1300). Pushed, title "Push A"; under the title bar
the content from `top: 114px`: "Wed 7 Oct 2026 · 12 of 15 done" sub `#B8B8BD`, `padding: 0 6px`. Four stat
tiles in a 2 × 2 grid (`gap: 10px`): TIME "48:12" · SETS "29" · AVG BPM "124" (value red) · EFFORT "7" with
"Hard" in foot 700 ember under it. Then a card per exercise in the plan's order (`border-radius: 20px;
padding: 16px`): name headline + its weight foot `#8E8E93` right ("22.5 kg"); under it capsules as 8.2
("22.5 × 10", "22.5 × 9", "22.5 × 8", "22.5 × 8"). Show: Incline DB Press (4 capsules) · Machine Chest Press
45 kg ("45 × 9", "45 × 8", "45 × 8") · Seated DB Shoulder Press 17.5 kg ("17.5 × 10", "17.5 × 9", "17.5 ×
8") · Cable Lateral Raise 7.5 kg (four "7.5 × 15") · Overhead Cable Extension 17.5 kg ("17.5 × 12", "17.5 ×
11", "17.5 × 10") · Rope Pushdown 22.5 kg (three "22.5 × 15") · Hanging Leg Raise ("12", "10", "10") · Cable
Crunch 30 kg ("30 × 15", "30 × 15", "30 × 14") · Bicycle Crunch (three "20"). Then eyebrow "NOT DONE" and a
card with three dim rows (name `#B8B8BD`, no right side): Hanging Knee-to-Elbow Twist, Russian Twist
(weighted), Toe Touches. Tick-off items (Warmup, Grease the Groove, Cooldown) are left out of this screen.

**8.4 `P84-Body.dc.html` · Body** (revised, 440 × 1000). Pushed, title "Body", plus icon right. Content: a
foot `#8E8E93` line `padding: 0 6px`: "Measured 6 Oct · change since 22 Sep". One card of ten rows (Row part,
60 px): name headline left ("Weight", "Neck", "Shoulders", "Chest", "Arm (flexed)", "Forearm", "Waist",
"Hips", "Thigh", "Calf"); right column: the value 17 / 22 / 700 white with its unit ("72.4 kg", "15″"), and
under it the change in foot 700: "+0.3", "+0.25″" in mint; "±0″" in `#8E8E93`; a waist increase would be
ember. Rows are buttons (they open 8.8). Footer foot `#8E8E93`: "Every two weeks, same time of day, before
breakfast. Arm flexed at its widest; waist at the navel, relaxed."

**8.5 `P85-BodyWarning.dc.html`** (revised): as the new 8.4 with the warning card first, as before: "Waist
+1.25″ since 22 Sep while your arms haven't grown. That's likely more fat than muscle: trim calories a little."
Waist row: "33.5″" with "+1.25″" ember; Arm row "14.25″" "±0″".

**8.6 `P86-Measurement.dc.html` · new measurement** (revised, 440 × 1200, sheet: "Cancel", "Measurement",
"Save"). Form groups: (no header) Date · "6 Oct 2026" capsule; "WEIGHT": Weight · "72.4" + "kg" + stepper;
"UPPER BODY": Neck, Shoulders, Chest, Arm (flexed), Forearm; "CORE": Waist, Hips; "LEGS": Thigh, Calf; each
row value + "″" + stepper, values from the sample. Footer: "Fill in what you measured; leave the rest blank.
Type a number, or step by a quarter inch (weight by 0.1 kg)."

**8.8 `P88-BodyPoint.dc.html` · one point** (new, 440 × 956). Pushed, title "Arm (flexed)". Stat tiles: NOW
"14.5″" (volt) · SINCE 8 SEP "+0.25″" · MEASURED "3". Chart card: a 200 px line chart, y 14 to 15 with labels
14, 14.5, 15; x "8 Sep", "22 Sep", "6 Oct"; series 14.25, 14.25, 14.5 in volt with the soft area. Then a card
of three rows: "6 Oct 2026" · "14.5″" (volt 700 right); "22 Sep 2026" · "14.25″"; "8 Sep 2026" · "14.25″".

**9.1 `P91-Plan.dc.html` · Plan · a day** (revised): no chips; the Close-Grip Push-up row stays as an ordinary
row; the footer line under "Add exercise" goes; the chest row reads "Machine Chest Press". **9.2
`P92-PlanEdit.dc.html`**: the same two chips and footer go.

**8.3 `P83-HistoryEmpty.dc.html`** (revised text): the body card's sentence becomes "Measure yourself every two
weeks: weight, arms, waist and the rest. SpotMe warns you if your waist grows while your arms don't."

## Canvas

Under review page. The 7 Oct row (`y: -1300`) grows: 2.15 is rebuilt in place. New row above it, title
`row7octb` at `y: -2630`: "Revised 7 Oct · rest and break without the reason line (3.1A–3.14, 5.5)" with the 13
edited watch boards at `y: -2300`, x from 0 in 496 steps (the first eight), and a second line at `y: -1800`
for the rest; they come back to Live · Watch when built. The iPhone rows keep their places; new iPhone boards
7.8, 8.7, 8.8 go at the end of their rows (7.8 at `x: 3640`, 8.7 at `x: 3120` in the History row, 8.8 at
`x: 3640` in the History row); move the `decide-phone` note right to `x: 4160`. A decision note `decide-7octb`
(orange, `w: 560`) at `x: 4160, y: -2300` with v–x.
