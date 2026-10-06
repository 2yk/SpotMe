# 2 · iPhone redesign · review and build rules

Reviewer and planner: Fable. Builders: Opus agents. Date: 6 Oct 2026. Second priority, after the watch
(`reviews/1-watch.md`, whose colours, icons and voice this follows). Read that file's "Build rules" first:
the skeleton, the no-script and no-hole rules, the colour table and the icon table all apply here.

## What is wrong today (from the code in `Apps/iOS/Views`, build 6)

1. **The same colour noise as the watch.** Every row on Today, History and Plan starts with a 36 pt round icon
   tinted by exercise kind, and the tints repeat in charts, chips and tiles.
2. **Today hides what changed.** The phone is for checking the session the night before, but the target
   weight is grey text in a subtitle and the reason ("up 5 kg", "lighter") is one tap away in a sheet.
3. **The day card repeats itself:** weekday, the long focus line in bold, a clock line and a ring, with the
   screen title saying the day again.
4. **Rows end in chevrons everywhere**, which adds a column of grey marks and no information.
5. **Charts use a different colour per exercise kind**, so the same line is green on one screen and blue on the next.

## The direction

- One accent, the watch's rule: volt for the thing to tap and the value that moved up. Mint done, ember
  lighter or a warning, red destructive, ice not used on the phone. Charts: volt for the main series, white at
  60% (dashed) for the second.
- Rows are text first: name, prescription, and on the right the target weight with its arrow and a one-word tag.
- Today opens with the session and what is different about it today ("1 goes up · 1 lighter").
- System furniture stays system: large titles, the tab bar, forms, sheets, steppers and switches. Only their
  colours follow the palette.

Behaviour changes Yeshu has to agree to: **(g)** Today's card shows the count of exercises going up and going
lighter today (from the engine's tags). **(h)** Row chevrons and kind icons go. Everything else is layout and colour.

## Build rules for phone boards

- A phone board is 440 × 956 px = iPhone 16 Pro Max. **1 pt = 1 px.** Long screens may be taller (the board
  list gives the height); never clip content to fit.
- Root: `position: relative; width: 440px; height: 956px; box-sizing: border-box; background: #000000; overflow: hidden; color: #FFFFFF; font-family: ui-rounded, 'SF Pro Rounded', 'Nunito', system-ui, sans-serif; font-variant-numeric: tabular-nums`. `$preview` matches the board size.
- No status bar and no home indicator: leave the top 54 px empty.
- Nothing smaller than 12 px (tab-bar labels are 10 px, as iOS draws them). Tap targets 44 px or more; a switch, stepper or capsule inside a 52 px form row counts as the row.
- A tall board ends 22 px after its last content, plus the tab bar when the screen has one. If the height in the board list leaves more than about 60 px empty or cuts content, say so in your report with the height it needs.

### Type (size / line-height / weight)

| Role | Style | Where |
|---|---|---|
| large title | 34 / 41 / 800 | Screen title |
| title | 28 / 34 / 800 | Day name on the Today card, sheet headings |
| title 2 | 22 / 28 / 700 | Card headlines ("41 this week") |
| number | 24 / 28 / 700 | Stat tiles |
| headline | 17 / 22 / 600 | Row names, nav titles |
| body | 17 / 22 / 500 | Form labels, notes |
| sub | 15 / 20 / 500 | Row details |
| foot | 13 / 18 / 500 | Footers, tags, axis labels |
| eyebrow | 12 / 16 / 800, letter-spacing 0.06em, uppercase | Section titles, tile labels |

Colours: the watch table. Text 2 `#B8B8BD`, text 3 `#8E8E93`, card `#1C1C1E`, raised `#2C2C2E`, line `rgba(255,255,255,0.10)`.

### Parts

**Screen with a large title** (tabs): optional toolbar icons at `top: 58px` (24 px icons, volt, 44 px buttons, `left: 12px` or `right: 12px`), the title at `left: 20px; top: 102px`, and the scrolling content column at `left: 16px; right: 16px; top: 158px; display: flex; flex-direction: column; gap: 22px`, running under the tab bar.

**Pushed screen:** back button at `left: 8px; top: 58px` (44 px, back icon 24 px volt), title centred at `top: 69px` in headline style, content column from `top: 114px`, groups 22 px apart. The tab bar stays, with the tab the screen belongs to selected.

**Sheet:** the root shows a strip of the dimmed screen behind (`top: 0; height: 64px; background: #0E0E10`), then the sheet surface: `position: absolute; left: 0; right: 0; top: 64px; bottom: 0; background: #000000; border-radius: 28px 28px 0 0; box-shadow: inset 0 1px 0 rgba(255,255,255,0.14)`. Inside: a grabber (36 × 5, `#48484A`, centred, `top: 8px`), a bar at `top: 20px; height: 44px` with the left action ("Cancel", body style, volt, `left: 20px`), the title centred in headline style, the right action (17 / 22 / 700 volt, `right: 20px`), then the content column from `top: 76px`, `left: 16px; right: 16px`. A sheet with no actions has only a close button on the right: a 44 px button holding a 30 px `#2C2C2E` circle with the close icon 16 px `#B8B8BD`.

**Tab bar** (every tab screen; last child of the root):
```html
<div style="position: absolute; left: 0; right: 0; bottom: 0; height: 84px; box-sizing: border-box; padding: 8px 8px 0; background: rgba(18,18,20,0.96); box-shadow: inset 0 1px 0 rgba(255,255,255,0.10); display: flex; justify-content: space-around; align-items: flex-start">…four tabs…</div>
```
A tab: `<button style="width: 88px; height: 50px; display: flex; flex-direction: column; align-items: center; gap: 3px; font-size: 10px; line-height: 12px; font-weight: 700; color: #8E8E93">` holding a 26 px icon and its name; the selected one is `#CCFF3D`. Tabs: Today (bolt), History (chart), Plan (plan), Settings (gear).

| Icon | Path (24 viewBox) |
|---|---|
| bolt | `M13 2L4.5 13.5H11l-1 8.5 8.5-11.5H12z` (filled) |
| chart | `M4 19h16M6 15l4-5 3 3 5-7` (stroke) |
| plan | `M6 3.5h12a1.5 1.5 0 0 1 1.5 1.5v14a1.5 1.5 0 0 1-1.5 1.5H6A1.5 1.5 0 0 1 4.5 19V5A1.5 1.5 0 0 1 6 3.5zM8.5 8.5h7M8.5 12h7M8.5 15.5h4` (stroke, width 2) |
| gear | `M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1` (stroke, width 2) |
| share | `M12 15V3.5M7.5 8L12 3.5 16.5 8M5 12v7.5h14V12` (stroke, width 2) |
| plus | `M12 5v14M5 12h14` (stroke) |
| more | `M5.5 12h.01M12 12h.01M18.5 12h.01` (stroke, width 3) |
| clock | `M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2` (stroke, width 2) |
| warning | `M12 3.5l9.5 16.5h-19zM12 10v4.5M12 17.5h.01` (stroke, width 2) |
| handle | `M5 9h14M5 15h14` (stroke, width 2) |
| minus | `M6 12h12` (stroke) |
Other icons come from the watch table (back, close, check, up, down, trash, heart, list).

**Day strip:** a row of seven buttons, `gap: 6px`, each `flex: 1; height: 54px; border-radius: 14px; background: #1C1C1E`, a column: the three-letter day (foot style, weight 700, `#B8B8BD`) and a 5 px dot under it (transparent unless it is today). Selected: volt fill, black text and dot. Today when not selected: volt text and dot.

**Card:** `background: #1C1C1E; border-radius: 24px; padding: 18px`.

**Section:** an eyebrow in `#8E8E93` (`padding-left: 6px; margin-bottom: 8px`) and a card with `padding: 0; overflow: hidden` holding rows separated by a 1 px `rgba(255,255,255,0.10)` line inset 16 px on the left.

**Row** (a `<button>`, `padding: 12px 16px; min-height: 60px; display: flex; align-items: center; gap: 12px`): left column (`flex: 1; min-width: 0`): name in headline style, detail in sub style `#B8B8BD`. Right column, right-aligned: the weight (17 / 22 / 700, with the up or down arrow 16 px before it as on the watch) and under it the tag in foot style weight 600: "+5 kg" volt, "lighter" ember, "+reps" `#8E8E93`, "deload" ember, "set weight" volt. Done rows: name `#B8B8BD`, and the right column is the check icon 20 px mint. No kind icons, no chevrons.

**Stat tile:** `flex: 1; background: #1C1C1E` (inside a card: `#2C2C2E`); `border-radius: 18px; padding: 14px`; eyebrow label, then the value in number style with the unit in foot style weight 700 `#B8B8BD` after it.

**Chip:** as on the watch at 12 px ("DELOAD WEEK" ember, "DUE" volt, "EDITED" raised fill with white text, "ADDED" volt).

**Form group** (Settings, editors, sheets): an eyebrow header, a card with `padding: 0`, rows 52 px high (`padding: 0 16px`, body style, label left, value right: white when the user can change it here, volt when it differs from the plan, `#B8B8BD` for read-only information), inset lines, and a footer in foot style `#8E8E93` (`padding: 8px 16px 0`). Destructive rows are red text. Action rows are volt text.
- Switch: 51 × 31 capsule, on `#CCFF3D`, off `#39393D`, with a 27 px white knob.
- Stepper: 94 × 32 capsule `#2C2C2E` split by a 1 px `rgba(255,255,255,0.16)` line, minus and plus icons 18 px white. Values before steppers sit in a 36 px right-aligned slot so the steppers line up.
- Segmented control: 36 px high capsule `#1C1C1E` with two equal halves, the selected half `#3A3A3C`, labels 13 / 18 / 600.
- Text field: a 52 px row; typed text white, placeholder `#8E8E93`.

**Charts** are inline `<svg>` with exact numbers from the sample data. Axis labels foot style `#8E8E93`; grid lines `rgba(255,255,255,0.08)`; main series volt, 3 px, round caps and joins, with 4 px dots; second series `rgba(255,255,255,0.6)`, 2 px, `stroke-dasharray="4 5"`.

## Sample data (matches the watch boards)

Today is Wednesday 7 Oct 2026 · Push A · Chest & Shoulders + Core A · "~70 min · no run". Program started
Mon 7 Sep 2026: week 5, next deload in 1 week. 22 sessions logged.

Today's sections and rows (name · detail · right side):
- WARMUP: "Warmup · 7 min" (that is its name) · detail "7 min" · nothing on the right
- CHEST: Incline DB Press · 4 × 6–10 · 22.5 kg, "+reps" | Machine Chest Press (or Flat Bench) · 3 × 8–10 · up 45 kg, "+5 kg"
- SHOULDERS: Seated DB Shoulder Press · 3 × 8–10 · 17.5 kg, "+reps" | Cable Lateral Raise · 4 × 12–15 · 7.5 kg, "+reps"
- TRICEPS · 2/3 OF ARM SIZE: Overhead Cable Extension · 3 × 10–12 · down 17.5 kg, "lighter" | Rope Pushdown · 3 × 12–15 · 22.5 kg, "+reps"
- CORE A · VISIBLE ABS: Hanging Leg Raise · 3 × 8–12 | Cable Crunch · 3 × 12–15 · 30 kg | Bicycle Crunch · 3 × 20 | Hanging Knee-to-Elbow Twist · 3 × 8/side | Russian Twist (weighted) · 3 × 20 · 5 kg | Toe Touches · 3 × 15
- OPTIONAL · ANYTIME TODAY: Grease the Groove · 4–5 × 40%
- COOLDOWN: Cooldown stretches · 5 min

Incline DB Press history (Wednesdays): 9 Sep 20 × 10, 9, 8, 8 · 16 Sep 20 × 10, 10, 10, 10 · 23 Sep 22.5 × 9, 8, 8, 7 ·
30 Sep 22.5 × 10, 9, 8, 8. Top set 22.5 kg, best e1RM 30 kg (per session: 26.67, 26.67, 29.25, 30), 4 sessions.
Sets per week (week starting): 7 Sep 98 · 14 Sep 104 · 21 Sep 101 · 28 Sep 108 · 5 Oct 41 (this week).
Body: 8 Sep arm 14.25″ waist 32″ · 22 Sep 14.25″, 32.25″ · 6 Oct 14.5″, 32.25″. Change since 22 Sep: arm +0.25″, waist ±0″.

## Boards (file · canvas title)

### 7 · Today

**7.1 `P71-Today.dc.html` · Today · before the workout** (440 × 1800). Large title "Today", tab bar (Today selected) pinned at the bottom of the board. Content: day strip (Wed selected and today); day card: eyebrow "WEDNESDAY" volt, "Push A" title, "Chest & Shoulders + Core A" body `#B8B8BD`, then a row `margin-top: 12px; gap: 14px` in sub style `#B8B8BD`: clock icon 16 px + "~70 min · no run"; up arrow 16 px volt + "1 goes up"; down arrow 16 px ember + "1 lighter". No ring. Then every section from the sample data.

**7.2 `P72-TodayRunning.dc.html` · Today · part way** (440 × 956). As 7.1 scrolled to the top, but the day card has a progress line under the first row: a 6 px track `#2C2C2E` with 3/15 filled volt, and "3 of 15 done" in foot style on the right of the meta row instead of "1 lighter". WARMUP and CHEST rows are done ("Done", "4 sets · 22.5 kg", "3 sets · 45 kg"); Seated DB Shoulder Press detail is "Set 2 of 3 · in progress" in volt.

**7.3 `P73-TodayDone.dc.html` · Today · all done** (440 × 956). Under the day card (progress line full, "15 of 15 done") a card with `background: rgba(71,235,163,0.14); box-shadow: inset 0 0 0 1px rgba(71,235,163,0.5)`: check icon 30 px mint in a 52 px circle, "All 15 done" title 2, "Great session. Recovery starts now." sub `#B8B8BD`. Then the WARMUP and CHEST sections with done rows.

**7.4 `P74-TodayDeload.dc.html` · Today · deload week, body log due** (440 × 956). Day card with a "DELOAD WEEK" chip beside the weekday eyebrow; meta row: clock + "~70 min · no run", down arrow ember + "Half the sets at 85%". Under it the body-log card (row, `gap: 14px`): "Body log due" headline, "Measure your flexed arm and waist" sub `#B8B8BD`, and a volt 32 px circle with a black plus icon on the right. Then sections with deload targets: Incline DB Press · 2 × 6–10 · down 20 kg, "deload"; Machine Chest Press (or Flat Bench) · 2 × 8–10 · down 40 kg, "deload"; Seated DB Shoulder Press · 2 × 8–10 · down 15 kg, "deload".

**7.5 `P75-Exercise.dc.html` · exercise sheet** (440 × 956, sheet, close icon button on the right, no title). Content `gap: 16px`: eyebrow "CHEST" `#8E8E93`; "Machine Chest Press (or Flat Bench)" title; three stat tiles: SETS 3 · REPS 8–10 · WEIGHT 45 kg (value volt, with the up arrow 18 px); "Every set hit the top of the range last time. Up 5 kg." sub `#B8B8BD`; note card (body): "Machine lets you push close to failure safely. Feet planted."; card "LAST TIME" eyebrow with "Wed 30 Sep" foot `#8E8E93` on the right, then "40 kg × 10, 10, 10" headline.

**7.6 `P76-TickOff.dc.html` · tick-off sheet** (440 × 956, sheet). Eyebrow "WARMUP"; "Warmup · 7 min" title; a card with the six steps from the watch board 4.5, each a row: number in 15 / 22 / 800 volt (20 px wide) and the step in body style.

### 8 · History

**8.1 `P81-History.dc.html` · History** (440 × 1424). Large title "History", share icon top right, tab bar (History selected). Cards:
- Sets per week: eyebrow "SETS PER WEEK" volt; "41 this week" title 2; "22 sessions" sub `#B8B8BD` right; a bar chart 120 px high of the five weeks (bars `#3A3A3C`, the last one volt, 6 px corner radius, bar width 62% of the slot), labels "7 Sep", "14 Sep", "21 Sep", "28 Sep", "5 Oct" under the bars.
- Body: eyebrow "BODY" volt; two stat tiles (raised): ARM "14.5″" with "+0.25″" in mint foot 700 under it; WAIST "32.25″" with "±0″" `#B8B8BD`; "Since 22 Sep" foot `#8E8E93`.
- Sections by day, rows: name, last session's sets as the detail, and on the right a sparkline (56 × 26 svg, volt, 2 px) and a change in foot 700 volt. MONDAY: Weighted Pull-ups · 15 kg × 5, 5, 5, 5, 4 · "+2.5" | Chest-Supported DB Row · 25 kg × 10, 10, 9, 8 · "+2.5" | Close-Grip Lat Pulldown · 45 kg × 12, 11, 10. TUESDAY: Leg Press · 120 kg × 12, 12, 11, 10 · "+10" | Hip Thrust · 60 kg × 12, 10, 10, 9 | Lying Hamstring Curl · 35 kg × 12, 11, 10. WEDNESDAY: Incline DB Press · 22.5 kg × 10, 9, 8, 8 · "+2.5" | Machine Chest Press (or Flat Bench) · 40 kg × 10, 10, 10 · "+5".

**8.2 `P82-ExerciseHistory.dc.html` · one exercise** (440 × 1200). Pushed, title "Incline DB Press". Three stat tiles: TOP SET 22.5 kg (volt) · BEST E1RM 30 kg · SESSIONS 4. Chart card: legend (a 16 px volt line + "Top set", a dashed white line + "Est. 1RM", foot 600 `#B8B8BD`); a 220 px line chart, y axis 18 to 32 kg with labels at 20, 24, 28, 32 on the left, x labels "9 Sep", "16 Sep", "23 Sep", "30 Sep"; top set series 20, 20, 22.5, 22.5 with a soft volt area under it (`rgba(204,255,61,0.18)` fading to 0); e1RM series 26.67, 26.67, 29.25, 30. Eyebrow "SESSIONS". Session cards (`border-radius: 20px; padding: 16px`): date headline + "4 sets" foot `#8E8E93` right; under it capsules (`background: #2C2C2E; padding: 7px 14px; border-radius: 999px`, sub 600) for each set: "22.5 × 10", "22.5 × 9", "22.5 × 8", "22.5 × 8" (Wed 30 Sep); "22.5 × 9", "22.5 × 8", "22.5 × 8", "22.5 × 7" (Wed 23 Sep); "20 × 10" four times (Wed 16 Sep); "20 × 10", "20 × 9", "20 × 8", "20 × 8" (Wed 9 Sep).

**8.3 `P83-HistoryEmpty.dc.html` · History · nothing yet** (440 × 956). Large title, tab bar. The body card in its empty state: eyebrow "BODY" volt, a "START" chip (volt) right, text sub `#B8B8BD`: "Measure your flexed arm and your waist every two weeks. SpotMe warns you if your waist grows while your arms don't." Then centred: the mark 76 px, "No sessions yet" title 2, "Log a workout on your watch. Finished sessions show up here once they sync." body `#B8B8BD`.

**8.4 `P84-Body.dc.html` · Body** (440 × 1100). Pushed, title "Body", plus icon right. A card with two line charts 120 px high, each under an eyebrow: "FLEXED ARM" (volt line: 14.25, 14.25, 14.5) and "WAIST" (white 60% line: 32, 32.25, 32.25), x labels "8 Sep", "22 Sep", "6 Oct". Form group "EVERY TWO WEEKS" with three rows: "6 Oct 2026" left, right "Arm 14.5″" volt and "Waist 32.25″" `#B8B8BD` (sub 600, `gap: 12px`); "22 Sep 2026" 14.25″, 32.25″; "8 Sep 2026" 14.25″, 32″. Footer: "Arm: flexed, at its widest. Waist: at the navel, relaxed. Same time of day each time, ideally before breakfast."

**8.5 `P85-BodyWarning.dc.html` · Body · waist warning** (440 × 956). As 8.4 with a first card `background: rgba(255,148,66,0.14)`: warning icon 20 px ember + text foot 600 ember (15 / 20): "Waist +1.25″ since 22 Sep while your arms haven't grown. That's likely more fat than muscle: trim calories a little." The newest row reads 6 Oct 2026 · Arm 14.25″ · Waist 33.5″ and the charts end at those values.

**8.6 `P86-Measurement.dc.html` · new measurement** (440 × 956, sheet: "Cancel", "Measurement", "Save"). One form group: Date · "6 Oct 2026" in a raised capsule; Flexed arm · "14.5" white + "″" `#B8B8BD` + stepper; Waist · "32.25" + "″" + stepper. Footer: "Arm: flexed, at its widest. Waist: at the navel, relaxed. Type a number, or step by a quarter inch."

### 9 · Plan

**9.1 `P91-Plan.dc.html` · Plan · a day** (440 × 1400). Large title "Plan"; toolbar: more icon left; plus icon and "Edit" (body, volt) right; tab bar (Plan selected). Day strip (Wed). "Push A · Chest & Shoulders + Core A" title 2 (two lines) and clock + "~70 min · no run" sub `#B8B8BD`, `padding: 0 6px`. Sections as on Today, rows: name; detail "4 × 6–10 · +2.5 kg · 2:30 rest"; right side only a chip where needed: Incline DB Press "EDITED" (its detail reads "5 × 6–10 · +2.5 kg · 2:30 rest"). Details: Warmup "7 min"; Machine Chest Press "3 × 8–10 · +5 kg · 2:30 rest"; Seated DB Shoulder Press "3 × 8–10 · +2.5 kg · 2:30 rest"; Cable Lateral Raise "4 × 12–15 · +2.5 kg · 1:15 rest"; Overhead Cable Extension "3 × 10–12 · +2.5 kg · 1:15 rest"; Rope Pushdown "3 × 12–15 · +2.5 kg · 1:15 rest"; Hanging Leg Raise "3 × 8–12 · 0:45 rest"; Cable Crunch "3 × 12–15 · 0:45 rest"; then, in the TRICEPS section after Rope Pushdown, an added one: "Close-Grip Push-up" "3 × 8–12 · 1:30 rest" with an "ADDED" chip. After the sections a card with one action row: plus icon in volt + "Add exercise" volt headline; footer "Wednesday is changed from the plan. Its history is kept either way." Stop the list after CORE A's first two rows if space runs out; the footer must be visible.

**9.2 `P92-PlanEdit.dc.html` · Plan · reorder** (440 × 956). Toolbar right: plus icon and "Done" (17 / 22 / 700 volt). Eyebrow "DRAG TO REORDER". One card, rows: a 24 px red circle with a white minus icon on the left, then name and detail (the detail starts with the section: "Chest · 5 × 6–10 · +2.5 kg · 2:30 rest"), and the handle icon 22 px `#8E8E93` on the right. Rows: Warmup · 7 min ("Warmup · 7 min"), Incline DB Press, Machine Chest Press (or Flat Bench), Seated DB Shoulder Press, Cable Lateral Raise, Overhead Cable Extension, Rope Pushdown, Close-Grip Push-up.

**9.3 `P93-Editor.dc.html` · exercise editor** (440 × 1120). Pushed, title "Incline DB Press". Header: eyebrow "CHEST" `#8E8E93`, "Incline DB Press" title 2, note sub `#B8B8BD`: "30° bench. Deep stretch at bottom, drive up. Main chest builder." Form groups: NAME (text field "Incline DB Press"); PRESCRIPTION: Sets · "plan 4" foot `#8E8E93` + "5" volt 600 + stepper | Reps, low · "6" + stepper | Reps, high · "10" + stepper | Rest · "2:30" + stepper; WEIGHT: Increment · "2.5 kg" + chevron-down 14 px | Start weight · "Not set" + stepper; footer "The increment is the smallest jump available. The start weight is only used the first time, before there's any history."; a group with "Reset to plan" (red) and footer "History is kept. The watch picks up changes before its next session."; a group with "Remove from Wednesday" (red) and footer "Its history is kept, and you can add it back with Add exercise."

**9.4 `P94-AddNew.dc.html` · add exercise · new** (440 × 956, sheet: "Cancel", "Add to Wednesday", "Add"). Segmented control: "New exercise" selected, "From the plan". Group: text field "Close-Grip Push-up"; Logged as · "Reps" + chevron-down; text field "Triceps · 2/3 of Arm Size"; footer "Reps each set, with optional added weight." Group PRESCRIPTION: Sets · "3" + stepper | Reps, low · "8" + stepper | Reps, high · "12" + stepper | Rest · "1:30" + stepper | Per side · switch off | Can add weight · switch off.

**9.5 `P95-AddFromPlan.dc.html` · add exercise · from the plan** (440 × 956, sheet: "Cancel", "Add to Wednesday", no right action). Segmented: "From the plan" selected. A group with the text field placeholder "Search". A group of rows (name headline, detail foot `#B8B8BD`): Weighted Pull-ups · "Monday · 5 × 3–5" | Chest-Supported DB Row · "Monday · 4 × 8–10" | Close-Grip Lat Pulldown · "Monday · 3 × 10–12" | Face Pulls · "Monday · 3 × 12–15" | Incline DB Curl · "Monday · 3 × 8–12" | Hammer Curl · "Monday · 3 × 10–12" | Leg Press · "Tuesday · 4 × 8–12". Footer: "It keeps its history and its prescription, and a change to either shows on every day it's on."

### 10 · Settings

**10.1 `P101-Settings.dc.html` · Settings** (440 × 1424). Large title "Settings", tab bar (Settings selected) at the bottom of the board. Form groups:
- PROGRAM: Deload every 6th week · switch on | Program start · "7 Sep 2026" in a raised capsule | This week is a deload · switch off. Footer "Week 5 of the program. Next deload in 1 week."
- APPLE HEALTH: Save workouts to Health · switch on | Watch access · "Allowed" mint | "Open the Health app" volt. Footer "Start workout on the watch records a strength training workout with your heart rate and saves it to Health when you finish. To change it: Health app → your profile picture → Apps → SpotMe."
- WATCH: Apple Watch · "Connected" mint | Last session in · "yesterday" | Rest timer haptics · switch on | "Send plan to watch" volt. Footer "Sessions arrive after Finish workout on the watch, even if the phone was out of range. Rest haptics: a tap at 10 seconds left and another when rest is over."
- YOUR DATA: "Export all sets" volt with the share icon 20 px. Footer "A CSV file with every set from 22 sessions, for Numbers, Excel or Google Sheets."
- ABOUT: Plan · "v11 · 77 items" | App · "1.0". Under it, centred, the mark 30 px and "SpotMe" 24 / 28 / 800, `gap: 10px`, `margin-top: 28px`.
No row icons: labels only (the share icon sits at the right end of the Export row).

## How the planner checks a board

As for the watch: `python3 render.py check <files>` prints ok, then the planner looks at the picture.

## Round 1 result (6 Oct 2026)

All 18 iPhone boards built, checked and looked at by the planner; on the canvas under Under review.
Final heights: 7.1 1800 · 8.1 1424 · 8.2 1088 · 8.4 956 · 9.1 1927 · 9.3 1120 · 10.1 1424; the rest 956.
Accepted departures: set capsules on 8.2 are four equal widths; chart eyebrows on Body are grey; on Body rows
only a value that moved is coloured (arm up volt, waist up ember); the value slot before a stepper is 60 px on
8.6; 9.1's title breaks before "+ Core A"; 9.2 has no more-icon.
