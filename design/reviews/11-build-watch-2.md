# 11 · Watch build 2 (build 9) · design check

The builder committed simulator screenshots to `design/built/watch-2/` (68 PNGs) on 7 Oct 2026, branch
`watch-build-9`, merged to main at bbba61d. The planner compared each with `handoff/watch-2/boards/<name>.png`.

## Result: passed, 7 Oct 2026

Matches within a point or two: 1.11, 1.12, 1.13 (Finished, Start again, a swapped row); 2.15, 2.16 (How with
Swap, the Swap sheet); every rest and break board without reason text and without a bar title on rest
(3.1A–3.14, the new 3.15 between ramp-ups); 5.5; every set, hold, tick-off and controls board without a back
button; the 12 redrawn figures on 2.11, 2.12, 2.15; the 42 mm set (set, rest, break, controls, break with
figure, Finished).

Section 8a (the complication never starts a second session): `W81-TapRunning-before/after` show the same rest
and set (2:29 → 2:24, set 4 of 4) after going home and tapping the complication. Passed.

`W62-ComplicationStates` (Start workout · Up next · Done, the builder's sketch): accepted; drawn as board
6.2 from the screenshot.

Edge-timer corners: unchanged, still waiting for Yeshu's photo.

## For the next build (not blocking)

1. How sheet (2.12, 2.15): the name is smaller than row style (should be 15 pt, weight 600) and the cue
   smaller than 11 pt; the sheet shows page dots, which the board does not have. If the dots are the
   figure's turn pages, say so and I'll draw them; otherwise hide them.
2. Break (3.8): "Machine Chest Press" wraps to two lines where the board fits it on one (title style 17 pt,
   `padding: 0 28px` → 14 pt sides). Check the horizontal padding of the name button.
3. Figure bundle: the plan-id mapping now has both chest press ids; drop the old-id fallback whenever
   convenient.

Boards 1.11–1.13, 2.15, 2.16, 6.2 and the revised rest/break/All done boards move to Live · Watch.
