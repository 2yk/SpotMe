# 6 · Watch build 1 · checking the build against the boards

Builder: SpotMe - Frontend (Mac Studio), branch `watch-redesign-1`. Spec: `../handoff/watch-1/BUILD.md`.
The builder commits simulator screenshots to `design/built/watch-1/` on its branch, named like the boards.
The planner compares each with `../handoff/watch-1/boards/<name>.png` side by side and answers OK or what to fix.

## Round 1 · parts A and B (6 Oct 2026, 47 screenshots)

Close to the boards throughout: colours, type, tiles, edge timer, arrows, Undo, End sheet, controls at fixed
sizes. Accepted as built:

- The system navigation bar is about 8 pt taller than drawn, so content starts at 50 pt and tiles are a
  little shorter. The title is drawn by the app beside the back button; sheets use the system close button.
- The real clock, the demo store's own numbers and exercises, Suitcase Carry on the hold boards.
- New wording on rest after a reps or timed set: "In range", "Top of range", "Below range".
- A hold with no weight shows its target seconds in a tile that is not focused.
- Complications unchanged (they already matched 6.1).

To fix (sent to the builder):

1. Today and Do next: rows are 10 pt apart, boards 4 pt. On 1.3 and 1.4 the day line, the live strip and
   Continue are spaced about 12 pt looser than drawn. On 1.6 "DONE" sits about 30 pt too far under Finish.
2. "1 sets" on a done row: "1 set".
3. Controls: a long "Skip to …" line runs off both sides of the screen; one line, cut with an ellipsis
   inside the content width.
4. Sheets: content starts under the system close button (Discard?, End workout?, Not saving to Health).
   It has to start below it.
5. Tick-off screens: the title in the content sits under the bar and is blurred at rest; start below the bar.
6. Summary and Discard?: the bottom button belongs at the bottom; summary values at 20 pt.
7. Edge timer: where the path starts (3 o'clock) and ends, the dimmed states show a dot. Draw the line as
   one group before dimming it.
8. Rest after a superset pair: the heart line is missing.
9. Try the root title ("0/15") on the clock's line; accept the system's place if it cannot move.

## Round 2 · parts A to C (6 Oct 2026, 54 screenshots)

All nine fixes from round 1 are in; the root title now sits on the clock's line. Part C passes: ramp-up
(2.13), rest after it (3.13), effort (5.8, 5.9), a waiting row (1.10), "Skipped earlier" (3.14), controls at
42 mm. The figure renderer is ported with tests against `figures/bundle/vectors.json` (its opacity column was
wrong; fixed, and a fill-opacity column added).

Left, to come with the figure screens:

1. Today rows still about 8 pt apart (Do next is right at 4 pt); Continue to the first row 16 pt, board 6 pt.
2. 1.6: "DONE" 44 pt under Finish workout; about 10 pt.
3. 3.13: heart line missing.
4. 2.13: hint row 9 pt lower than on the set screen (the Skip button's tap height).
5. 3.14: a two-line summary runs under the round buttons; it gets the lines that fit.
