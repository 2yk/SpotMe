# 10 · The iPhone look (B · Depth) applied, screen by screen · 1: Today

Yeshu, 7 Oct: "iPhone 7.1B is ok." The look from `P71B-TodayDepth.dc.html` is the iPhone's look. It is
applied one screen group at a time (Yeshu: "one by one screen"): Today first, then History, Plan, Settings,
then onboarding. Also from the same message: the rest screen has no bar title ("Remove the rest text") and
the rest timer never pauses (3.5 dropped: Pause stops the workout clock, not a running rest).

## The parts of look B (copy these from `P71B-TodayDepth.dc.html`; they replace the plain parts of `2-iphone.md`)

- **Background:** black, with a faint wash at the top of tab screens: `position: absolute; left: 0; right: 0;
  top: 0; height: 420px; background: radial-gradient(ellipse 80% 60% at 70% 30%, rgba(204,255,61,0.06),
  rgba(204,255,61,0) 70%)` as the root's first child.
- **Card:** `border-radius: 28px; background: linear-gradient(170deg, #26262A, #141416); box-shadow: inset 0
  1px 0 rgba(255,255,255,0.08)`; padding 18 (hero 22). Section cards: `padding: 0; overflow: hidden`.
- **Row** (inside a section card): `padding: 10px 16px 10px 12px; min-height: 64px; display: flex;
  align-items: center; gap: 12px`: a 44 px figure still on the left (`figure3d.svg(fid, still=True,
  size=44)`; tick-off items get the clock icon 24 px `#B8B8BD` centred in the 44 px slot); name headline,
  detail sub `#B8B8BD`; right column as before (weight 17 / 22 / 700 with arrow, tag foot 600). Dividers
  between rows: 1 px `rgba(255,255,255,0.10)`, inset 68 px on the left. Done rows: name `#B8B8BD`, the
  figure at 60% opacity, the check 20 px mint on the right.
- **Primary button:** `height: 56px; border-radius: 999px; background: #CCFF3D; color: #000000; font 17 / 22
  / 700; box-shadow: inset 0 1px 0 rgba(255,255,255,0.5), 0 10px 30px rgba(204,255,61,0.35)`.
- **Day strip pill:** `flex: 1; height: 54px; border-radius: 14px; background: linear-gradient(#232326,
  #1A1A1C); box-shadow: inset 0 1px 0 rgba(255,255,255,0.08)`; label foot 700 `#B8B8BD` + 5 px dot.
  Selected: solid volt, black label 800, `box-shadow: inset 0 1px 0 rgba(255,255,255,0.45), 0 6px 18px
  rgba(204,255,61,0.25)`. Today unselected: volt label and dot.
- **Hero card** (Today): the card with `position: relative; overflow: hidden; padding: 22px; display: flex`:
  left column `width: 200px`: eyebrow volt, "Push A" 36 / 40 / 800, subtitle 15 / 20 / 600 `#B8B8BD`, then
  the meta lines (clock, up, down) 15 / 20 / 500 `#B8B8BD`, 4 px apart, icons 16 px; right: the moving figure
  of the day's first lift at 170 px, `position: absolute; right: 6px; bottom: -10px`, with a radial volt glow
  behind it at 10%.
- **Stat tile:** `flex: 1; border-radius: 18px; padding: 14px; background: linear-gradient(180deg,
  rgba(255,255,255,0.08), rgba(255,255,255,0.03)); box-shadow: inset 0 1px 0 rgba(255,255,255,0.10)`;
  eyebrow label, value number style, unit foot 700 `#B8B8BD`.
- **Chart:** as before (volt 3 px line, soft area), plus `filter: drop-shadow(0 0 6px rgba(204,255,61,0.55))`
  on the line.
- **Sheet:** the dimmed strip and surface as before; the surface `background: #0B0B0C`; cards inside as above.
- **Chips, eyebrows, tab bar, type scale:** unchanged from `2-iphone.md`.
- **Content gap** between groups: 14 px (not 22), so more fits above the tab bar.

## Boards (all revised in place; 440 wide)

**7.1 `P71-Today.dc.html` · Today · before the workout** (440 × 1800). `P71B-TodayDepth.dc.html` continued
to the full day: every section and row from the sample data (figure stills for every lift from
`figures/poses3d` ids; Grease the Groove and Cooldown stretches get the clock icon), the tab bar pinned at the
bottom of the board. The hero's "1 lighter" and "1 goes up" lines stay. P71B itself is kept as the reference
board for the look (moved to the Approved page as "0.2 · iPhone look").

**7.2 `P72-TodayRunning.dc.html` · part way** (440 × 956). As 7.1's top, in look B, with: a 6 px progress
track in the hero under the meta lines (`#2C2C2E`, 3/15 filled volt, radius 3) and "3 of 15 done" foot
`#B8B8BD` to its right; the primary button reads "Continue" with "Seated DB Shoulder Press · Set 2 of 3" in
13 / 18 / 700 `rgba(0,0,0,0.66)` under it (height 64); WARMUP and CHEST rows done; Seated DB Shoulder Press
detail "Set 2 of 3 · in progress" volt.

**7.3 `P73-TodayDone.dc.html` · all done** (440 × 956). Hero with the track full and "15 of 15 done"; the
button is gone; under the hero the done card: `background: linear-gradient(170deg, rgba(71,235,163,0.22),
rgba(71,235,163,0.08)); box-shadow: inset 0 1px 0 rgba(71,235,163,0.45)`, radius 28, padding 18, row: check
icon 30 px mint in a 52 px circle `rgba(71,235,163,0.18)`, then "All 15 done" title 2 and "62 min · 395
kcal · Hard 7" sub `#B8B8BD`. Then WARMUP and CHEST done rows.

**7.4 `P74-TodayDeload.dc.html` · deload week, body log due** (440 × 956). Hero with the "DELOAD WEEK" chip
(ember) beside the eyebrow and the meta lines "~70 min · no run" and (down arrow ember) "Half the sets at
85%"; the body-log card in look B: "Body log due" headline, "Measure yourself: weight, arms, waist and the
rest" sub, volt 32 px plus circle on the right; sections with the deload rows (2 × 6–10 · down 20 kg
"deload"; Machine Chest Press 2 × 8–10 · down 40 kg; Seated DB Shoulder Press 2 × 8–10 · down 15 kg).

**7.5 `P75-Exercise.dc.html` · exercise sheet** (440 × 956): the 7 Oct content (title, tiles, PROGRESS chart
card, Swap row, LAST TIME, note) in look B parts (tiles, cards, chart glow). **7.7
`P77-ExerciseFigure.dc.html`** (440 × 1080): the same with the figure card (keep the figure as it is; the card
in look B).

**7.6 `P76-TickOff.dc.html` · tick-off sheet** (440 × 956): look B card for the steps; the step numbers volt
15 / 22 / 800; a primary button "Done" at the end of the content.

**7.8 `P78-Swap.dc.html` · Swap from Today** (440 × 956): look B cards; each alternative row gets its 44 px
figure still where a pose exists in `figures/poses3d/` (db-bench-press, machine-chest-press…; rows without a
pose keep the 44 px slot empty).

**7.1A and 7.1C** move to the Backlog page as not chosen.

## Canvas

Under review: the iPhone row at `y: 0` keeps its places (7.1 is 1800 tall; 7.2–7.8 beside it). `P71B` moves to
Approved at `x: 1360, y: 5100` titled "0.2 · iPhone look (B · Depth)"; `P71A` and `P71C` to Backlog at
`x: 1600` and `2120`, `y: 0`. The `rowlook` title changes to "Chosen 7 Oct: look B. Applied to Today first;
History, Plan, Settings follow one by one." and the `decide-look` note is updated.
