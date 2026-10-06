# 4 · Form figures on screen · build rules

Planner: Fable. Date: 6 Oct 2026. Asked by Yeshu: "dynamic artwork to show which workout is which; most of the
time I need to google it during workouts". What a figure is and how it is drawn: `../figures/FIGURES.md`.
Twelve figures exist as a proof of concept (`../figures/poses/`); the app would carry one per exercise.

Where a figure appears, in order of how much it helps:
1. **Watch, break before an exercise:** the moment you walk to the next station. The figure sits beside its name.
2. **Watch, set screen:** a small still beside the name; a tap opens "How" with the moving figure and the cue.
3. **iPhone, exercise sheet:** the moving figure on top, for checking the plan the night before.
4. Later, once every exercise has one: swap lists and the plan screens.

Boards follow `1-watch.md` (watch) and `2-iphone.md` (iPhone). A figure is pasted into a board as the inline
SVG that `../figures/figure.py` prints: `python3 -c "import sys; sys.path.insert(0, '/home/yk/hermes/work/spotme/design/figures'); from figure import svg; print(svg('incline-db-press', size=260))"`
(add `still=True` for the still version). Paste it unchanged: it has no ids, classes or styles.
In Always On and with Reduce Motion the app shows the still.

## Boards

**13.1 `F131-Figures.dc.html` · the twelve figures** (1280 × 900, `border-radius: 0`, background `#0B0B0C`,
padding 40). Heading: the mark 40 px + "Form figures" title xl style of the watch (40 / 44 / 800), and on the
same line, right-aligned, "12 of 247 · proof of concept" in 20 / 24 / 800 eyebrow style `#8E8E93`. Then a grid of
six columns and two rows (`gap: 20px 16px`): each cell a card (`background: #000000; border-radius: 24px; padding:
12px 8px 14px`, centred column) holding the moving figure at 168 px and under it the exercise's name from the
database in 17 / 22 / 600 white, centred, two lines allowed. Order: Incline DB Press, Chest-Supported DB Row,
Close-Grip Lat Pulldown, Pull-ups, Cable Lateral Raise, Rope Pushdown, Bayesian Cable Curl, Leg Press, Bulgarian
Split Squat, Hip Thrust, Hanging Leg Raise, Plank. Under the grid (`margin-top: 28px`) an eyebrow "AT WATCH SIZE,
STILL" and a row of the twelve stills at 72 px, `gap: 18px`, in the same order. This board may be put together
with a short script, since its content is the renderer's output. `$preview` 1280 × 900.

**2.11 `W211-SetFigure.dc.html` · Set · with a figure** (watch). `W21A-SetTiles.dc.html` with one change: the
name block becomes a row (`display: flex; align-items: center; gap: 10px; padding: 0 8px`): on the left, in a
column, the name and under it the hint row's two parts stacked ("6–10 reps", then "Last 9" as in W21A but
left-aligned); on the right a `<button aria-label="How to do it">` 84 × 84, `border-radius: 22px; background:
#1C1C1E`, holding the still figure of incline-db-press at 76 px. Tiles and Log set exactly as W21A.

**2.12 `W212-How.dc.html` · How** (watch, sheet: close icon, title "How" in volt, no page dots). Centred column
from `top: 70px`: the moving figure of incline-db-press at 250 px; "Incline DB Press" in row style (30 / 34 /
600) directly under it; the cue in 22 / 28 / 500 `#B8B8BD`, centred, two lines, `padding: 0 24px`: "30° bench.
Deep stretch at bottom, drive up."

**3.12 `W312-BreakFigure.dc.html` · Break · with a figure** (watch). `W38-Break.dc.html` (edge timer at 77%,
"1:55", buttons, Undo, dots) with the middle rebuilt: the countdown at 72 / 72 / 800; under it (`margin-top:
8px`) a row `padding: 0 30px; gap: 14px; align-items: center`: the moving figure of close-grip-lat-pulldown at
124 px on the left; on the right, left-aligned, a button with the name "Close-Grip Lat Pulldown" in 28 / 32 / 700
(three lines allowed) and the chevron-down after the last word, and under it "3 × 10–12 · " in `#B8B8BD` and "45
kg" white 700 (24 / 30). Under the row (`margin-top: 6px`) the summary line as on W38, volt: check + "All sets 10
· next time 27.5 kg".

**7.7 `P77-ExerciseFigure.dc.html` · exercise sheet with a figure** (iPhone, 440 × 956, sheet with the close
button, as `P75-Exercise.dc.html`). Content `gap: 16px`: a card (`background: #1C1C1E; border-radius: 24px;
height: 236px`, centred) with the moving figure of incline-db-press at 220 px; eyebrow "CHEST" `#8E8E93`;
"Incline DB Press" title; three stat tiles: SETS 4 · REPS 6–10 · WEIGHT 22.5 kg (white, no arrow); "Same weight
as last time. Aim to beat its reps." sub `#B8B8BD`; note card: "30° bench. Deep stretch at bottom, drive up. Main
chest builder."; card "LAST TIME" with "Wed 30 Sep" on the right and "22.5 kg × 10, 9, 8, 8".

## Round 1 result (6 Oct 2026)

Five boards built, checked and looked at by the planner; on the canvas under Under review. 13.1 is 1280 × 780.
Every figure is at the size given above; none had to shrink.
