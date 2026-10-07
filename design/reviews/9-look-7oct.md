# 9 · 7 Oct, afternoon · no back button, rearranging days, and a look for the iPhone

Reviewer and planner: Fable. Builders: Opus agents. Three things Yeshu said after the morning's boards.

## 1 · The back button goes (decision y, said yes 7 Oct)

Yeshu: the back button sat on the rest timer's edge line. Design: no back button on any in-workout screen
(set, ramp-up, rest, break, holds, tick-off items, controls, All done). Back only did what the controls page's
List button does, and Apple's Workout app has none either. The bar title moves to `left: 44px; top: 24px`, in
line with Today's "0/15". On the edge-timer screens (rest, break, holds) Yeshu found the title touching the
line, so there it sits at `left: 52px; top: 34px`: drawn as content, not as the system title, 6 pt below
the clock's line and clear of the line. Also: every board now says "Machine Chest Press" (decision s). Sheets (How, Swap, Days, End, Discard, Summary, Effort) keep their close button.
Done by the planner in place on 38 boards. Spec: "Back always returns to Today" becomes "List, on the controls
page, returns to Today"; the back button is hidden on workout screens.

## 2 · Switching days in the plan

Yeshu: "What if I need to switch days in the plan?"

Found: doing another day's workout today exists (the Days sheet 1.7 on the watch, the day strip on 7.1).
Moving workouts between weekdays for good does not.

Design: **Rearrange days.** In Plan, the more menu (…) gets "Rearrange days", and the onboarding plan preview
(12.1) gets a "Change days" text button under its day row. Both open the same sheet: the seven weekdays, each
with its workout's name and a drag handle; drag a workout onto another day and the two swap places. Rest days
are workouts too ("Full Rest" has a row). Weekday names never move. History stays with the workout, not the
weekday. Spec: a plan day maps a weekday to a workout; rearranging changes the mapping only.

## 3 · The iPhone isn't attractive

Yeshu: "about iPhone app it doesn't visually attractive."

The iPhone boards so far are a utility: black, grey cards, one accent, rows of text. The watch earned its
look from constraints the phone doesn't have. Three directions are drawn for the Today screen so Yeshu can
pick one by eye; the chosen one is then applied to every iPhone board. All three keep the watch's colours and
type family, the tab bar, and 7.1's content and order (day strip, the day, the sections), so only the look
differs.

- **A · Big numbers.** The system as it is, with hierarchy: the day card becomes a hero with "Push A" at
  44 px and three large numerals under it (15 items · 70 min · 1 up); every exercise row gets its figure as
  a 56 px still in a rounded tile on the left; section labels in volt. Flat, fast, confident.
- **B · Depth.** Cards with a gentle vertical gradient and a 1 px top highlight, 28 px corners, a volt glow
  under the Start button; the hero card holds the first lift's moving figure at 170 px on the right with the
  day on the left; rows carry small figure stills; stats sit in glass-like tiles. Rich, app-store.
- **C · Editorial.** Few boxes: a 48 px day title, a row of muscle-group chips in tinted colours, the first
  lift's moving figure at 220 px centred like an illustration, then the exercises as a plain list with
  hairline separators and figure stills; the Start button floats above the tab bar as a volt capsule.
  Open, magazine-like.

A fourth is possible if none fits; Yeshu can also say which parts of each he likes.

## Decisions for Yeshu

- y · No back button on workout screens (said yes 7 Oct; recorded here).
- z · Rearrange days as a drag sheet from Plan's more menu and from the onboarding preview.
- Look · A, B or C for the iPhone (7.1A, 7.1B, 7.1C).

## Boards

### iPhone look (440 × 956: the top of Today, before the workout)

Shared rules for all three (from `2-iphone.md` unless stated): root as the phone root; no status bar, top
54 px empty; the tab bar at the bottom with Today selected; the day strip stays in each (it may be restyled
but keeps seven buttons and the Wed selection). Content: the day (WEDNESDAY, Push A, Chest & Shoulders + Core
A, ~70 min · no run, 1 goes up, 1 lighter), the primary action "Start workout" (the phone can start the
session too; the watch picks it up), then the sections WARMUP and CHEST and the start of SHOULDERS with the
sample rows (names, prescriptions, weights and tags as 7.1). Figures: stills from `figures/figure3d.py`
(`svg(fid, still=True, size=N)`) for incline-db-press, machine-chest-press, seated-db-shoulder-press,
cable-lateral-raise; the moving one (`svg(fid, size=N)`) for incline-db-press where a direction asks for it.
Colours: volt `#CCFF3D`, ice `#63D9FF`, mint `#47EBA3`, ember `#FF9442`, card `#1C1C1E`, raised `#2C2C2E`,
text 2 `#B8B8BD`, text 3 `#8E8E93`. Nothing under 12 px; targets 44 px. Each direction may add one or two
things of its own (a gradient, a glow, a chip row) but no new content, no invented numbers.

**7.1A `P71A-TodayBig.dc.html` · A · Big numbers.** Large title "Today". Day strip as 7.1. Hero card
(`#1C1C1E`, radius 28, padding 22): eyebrow "WEDNESDAY" volt; "Push A" 44 / 48 / 800; "Chest & Shoulders +
Core A" body `#B8B8BD`; `margin-top: 18px` a row of three stat blocks (no tiles, just type): "15" 34 / 38 /
800 white + "items" foot `#8E8E93`; "70" + "min"; "1" in volt + "goes up" (the up arrow 14 px before "1"). Then
the primary button "Start workout" (56 px, volt, black text 17 / 22 / 700) inside the card at the bottom.
Sections: eyebrow in volt (not grey); rows as the Row part plus a 56 × 56 tile (`#2C2C2E`, radius 16) on the
left holding the figure still at 48 px. Warmup's tile holds the clock icon 24 px `#B8B8BD` instead.

**7.1B `P71B-TodayDepth.dc.html` · B · Depth.** Large title "Today". Day strip: pills with
`background: linear-gradient(#232326, #1A1A1C)` and `box-shadow: inset 0 1px 0 rgba(255,255,255,0.08)`.
Hero card: `background: linear-gradient(170deg, #26262A, #141416)`, radius 28, the same inset highlight,
padding 22, `display: flex`: left column with eyebrow "WEDNESDAY" volt, "Push A" 36 / 40 / 800, "Chest &
Shoulders + Core A" sub `#B8B8BD`, and `margin-top: 14px` the three lines (clock, up, down) as 7.1; right:
the moving incline-db-press figure at 170 px, overflowing the card's bottom edge by 10 px is allowed
(`overflow: hidden` on the card). Under the card the primary button "Start workout" 56 px with
`box-shadow: 0 10px 30px rgba(204,255,61,0.35)`. Sections: eyebrow `#8E8E93`; the section card gets the same
gradient and highlight; rows as the Row part with a 44 px figure still on the left (no tile).

**7.1C `P71C-TodayEditorial.dc.html` · C · Editorial.** No large title "Today"; instead at `top: 102px`
the eyebrow "WEDNESDAY · 7 OCT" `#8E8E93` and "Push A" 48 / 52 / 800 white, then a chip row (`gap: 8px`):
"Chest" (volt tint `rgba(204,255,61,0.16)`, volt text), "Shoulders" (ice tint, ice text), "Core A" (mint
tint, mint text), each 28 px high, foot 700, radius 999; then "~70 min · no run · 1 up · 1 lighter" sub
`#B8B8BD`. Then the moving incline-db-press figure at 220 px centred, with a radial fade under it
(`background: radial-gradient(ellipse at 50% 100%, rgba(204,255,61,0.10), transparent 70%)`). The day strip
sits under the figure as plain text buttons (three-letter days in foot 700 `#8E8E93`, Wed in volt with a dot),
no pills. Sections: eyebrow `#8E8E93`; rows with no card: `padding: 14px 6px`, a 1 px `rgba(255,255,255,0.10)`
line between rows, the figure still at 40 px on the left, name and detail as the Row part, the weight and tag
on the right. The primary button floats: `position: absolute; left: 16px; right: 16px; bottom: 100px; height:
56px` volt capsule "Start workout" with `box-shadow: 0 8px 24px rgba(0,0,0,0.5)`; content runs under it and
the tab bar.

### Rearrange days

**9.6 `P96-RearrangeDays.dc.html` · Plan · Rearrange days** (440 × 956, sheet: "Cancel", "Rearrange days",
"Done"). A foot `#8E8E93` line `padding: 0 6px`: "Drag a workout to another day. The days keep their names."
Then one card of seven rows (Row part, 64 px): left the weekday in headline ("Monday" …); middle, `flex: 1`,
the workout in sub `#B8B8BD` ("Pull A · Strength & Thickness", "Legs · Run-Supportive", "Push A · Chest &
Shoulders + Core A", "Pull B · Pull-up Endurance", "Push B · Arms Focus + Core C", "Full Rest", "Mobility +
Core B"); right the handle icon 20 px `#8E8E93`. Show the Saturday row lifted: `transform: translateY(-6px);
box-shadow: 0 8px 24px rgba(0,0,0,0.6); background: #2C2C2E`, as if being dragged over Sunday. Footer:
"History stays with the workout, whichever day it moves to."

**12.7 `O127-ChangeDays.dc.html` · Onboarding · Change days** (440 × 956, sheet: "Cancel", "Change days",
"Done"). The same sheet with the onboarding plan's days (read `../plan-builder/` for the sample plan used on
12.1: use its weekday → workout list; if unsure, use the first test plan's). No lifted row.

Also on **12.1 `O121-Plan.dc.html`**: under the day row add a centred text button "Change days" (body, volt).
On **9.1 `P91-Plan.dc.html`**: nothing visible changes (the more menu is a system menu).

## Canvas

Under review: a new top row, title `rowlook` at `y: -4530`: "Pick a look · 7.1A, 7.1B, 7.1C · the Today
screen three ways; the one you choose is applied to every iPhone screen". Boards at `y: -4200`, x 0, 520,
1040, radius 40. A decision note `decide-look` (orange, `w: 560`, `x: 1600, y: -4200`) with y, z and the look.
9.6 at `x: 2600, y: 4144` (Plan row); 12.7 at `x: 3640, y: 10533` (onboarding plan row).
