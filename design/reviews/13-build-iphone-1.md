# 13 · iPhone build 1 (build 11) · design check

Checked by: SpotMe - Designer, 13 Oct 2026. Branch `iphone-build-11` at c89b5b8. Screenshots in
`built/iphone-1/` (27 phone, 6 watch sync frames), compared with `handoff/iphone-1/boards/`.

## Result

**Approved for Yeshu to install and test.** Swap works on the phone and reaches the watch live: on Today, on
a set screen with nothing logged, and on a break (sync frames A4, B3, C5). Every screen has the board's
content, order and strings, and wears look B. The rest of the differences come from the demo store's data:
weights, dates, session counts, "2 go up".

Accepted departures: these are system parts, kept as the system draws them:
- the large title, about 19 pt lower than on the board
- the floating tab bar
- the status bar

Also accepted:
- no "See every chest exercise" row and no figures on the Swap rows
- "~70 min" without "· no run"
- the 15 pt swap icon on a swapped Today row
- the Ramp-up sets row in Settings, and "v11 · 72 items"
- Remove from the long-press menu, edit mode and the editor
- press-and-hold to lift a row in Rearrange days
- "Moderate" effort in volt on 8.7

## To fix on the same branch (next round; none blocks testing)

1. **7.4 is missing.** `P74-TodayDeload.png` is the Body screen. Send Today in a deload week with the body
   log due.
2. **7.3 done card:** the line under "All 15 done" should be the session's numbers, "62 min · 395 kcal ·
   Hard 7", not "Great session. Recovery starts now." (`10-look-b-today.md`).
3. **7.1–7.3 hero figure:** anchor it to the hero's bottom right (`right: 6px; bottom: -10px`, as on the
   board). Today it sits at the top and crowds "Chest & Shoulders + Core A".
4. **Inch values:** no space before ″. Write "15″", not "15 ″", on the measurement sheet (8.6) and in the
   NOW tile on 8.8.
5. **9.5 From the plan:** list exercises only. Leave out tick-off items (warmups, cooldowns, Manual Neck
   Resistance), as the board does.

## Round 2 · build 12 (`iphone-build-12` at a3870d0), 13 Oct

Screenshots in `built/iphone-2/` on that branch. All five fixes are in:
- 7.4 is Today in a deload week with the body log due.
- 7.3's done card reads "62 min · 395 kcal · Hard 7".
- The hero figure sits at the bottom right on 7.2–7.4.
- 8.6 and 8.8 write "15″" with no space.
- 9.5 lists exercises only.

`P71-Today.png` caught the launch screen instead of Today. 7.2 shows the same hero with the fix, so this
doesn't hold the build; a fresh 7.1 screenshot is asked for the record.

**Build 12 approved** for Yeshu to install.
