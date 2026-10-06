# 3 · Onboarding and the plan it builds · review and build rules

Reviewer and planner: Fable. Builders: Opus agents. Date: 6 Oct 2026. Asked by Yeshu: "user onboarding, where
we get the important information to build the workout tailored for that particular user and his goals; then we
create an amazing workout plan based on those goals."

The questions and the rules that turn answers into a plan are in `../plan-builder/RULES.md`. This file is how
the screens look. Boards are iPhone boards: everything in `2-iphone.md` under "Build rules for phone boards",
"Type" and "Parts" applies (and through it the skeleton, colours and icons of `1-watch.md`).

## The shape of onboarding

- One question per screen, answered with a tap. Eight question screens, under a minute in total.
- Every screen says in one line why the question matters, so nothing feels like a form.
- Nothing is typed. Nothing is asked that the plan doesn't use.
- The plan is shown before it is accepted, with its reasons, and any exercise can be swapped there.
- The watch only says "set up on your iPhone" until a plan exists.

The sample person on every board is Yeshu: build muscle · more arms and back · experienced · Monday to Friday ·
60 minutes · full gym · lower back: take care · runs three times or more · age not given.

## Parts for onboarding screens (440 × 956, no tab bar)

**Top row** at `top: 58px; height: 44px`: back button on the left (`left: 8px`, 44 px, back icon 24 px volt; none
on the first screen); the progress bar centred: eight segments in a row, `gap: 4px`, each 26 × 4 px with
`border-radius: 2px`, done and current ones `#CCFF3D`, the rest `#2C2C2E`; on optional questions a "Skip" text
button on the right (`right: 20px`, body style, `#B8B8BD`).

**Question block** at `left: 20px; right: 20px; top: 122px`: the question in title style (28 / 34 / 800), then
`margin-top: 8px` the reason in sub style (15 / 20 / 500, `#B8B8BD`).

**Option card** (single choice): a `<button>`, `width: 100%; min-height: 76px; border-radius: 20px; background:
#1C1C1E; padding: 14px 18px; display: flex; align-items: center; gap: 12px`; left column: name in headline style
(17 / 22 / 600), one line in sub style `#B8B8BD` under it. Selected: `background: rgba(204,255,61,0.10);
box-shadow: inset 0 0 0 2px #CCFF3D` and on the right the check icon 22 px volt. Cards stack with `gap: 10px`,
starting 24 px under the question block (`left: 16px; right: 16px`).

**Primary button** pinned at `left: 16px; right: 16px; bottom: 34px; height: 56px; border-radius: 28px;
background: #CCFF3D; color: #000000`, label 17 / 22 / 700. Disabled: `background: #2C2C2E; color: #8E8E93`.

New icons (24 viewBox, stroke as in the icon tables): swap `M7 7h11l-3-3M17 17H6l3 3` · watch
`M8 6.5h8a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2zM9 6.5l.6-3.5h4.8l.6 3.5M9 17.5l.6 3.5h4.8l.6-3.5`
(width 2).

## Boards

### 11 · Onboarding: the questions

**11.1 `O111-Welcome.dc.html` · Welcome.** No top row. Centred column from `top: 200px`: the mark 96 px; "SpotMe"
large title (`margin-top: 20px`); "A plan built around you" title 2 `#B8B8BD` (`margin-top: 6px`). Then
(`margin-top: 44px`, `padding: 0 36px`, column `gap: 18px`, left-aligned) three lines, each a row `gap: 14px`: check
icon 22 px volt + body text white: "Eight quick questions, a tap each" · "A plan for your goal, your gym and your
body" · "Your watch tells you what to lift, set by set". Primary button "Build my plan". Above it, centred
(`bottom: 106px`), foot style `#8E8E93`: "About a minute. You can change everything later."

**11.2 `O112-Goal.dc.html` · Goal.** Progress 1 of 8. Question "What are you training for?" Reason "It sets your
reps, your rests and how much you do." Cards: "Build muscle" / "Bigger and stronger-looking. Most sets 6 to 15
reps." (selected) · "Get stronger" / "Lift heavier. The first lift each day is heavy." · "Lose fat, keep muscle" /
"The same lifting with shorter rests. Food does the rest." · "Stay fit and healthy" / "A bit of everything,
nothing extreme." Primary "Continue".

**11.3 `O113-Focus.dc.html` · Focus.** Progress 2 of 8, back, "Skip". Question "Anything you want more of?" Reason
"Pick up to two, or none. They get extra sets and are never cut for time." A grid of seven pills, two columns,
`gap: 10px`: each a `<button>` 64 px high, `border-radius: 20px`, `#1C1C1E`, label headline style centred; selected
as the option card (tint, 2 px volt outline, no check). Order: Chest, Back (selected), Shoulders, Arms (selected),
Glutes, Legs, Core (the seventh alone in the left column). Under the grid, foot style `#8E8E93`: "2 of 2 picked".
Primary "Continue".

**11.4 `O114-Experience.dc.html` · Experience.** Progress 3 of 8. Question "How long have you lifted?" Reason "Be
honest: it sets how hard the exercises are and how many days make sense." Cards: "New to it" / "Under 6 months, or
back after a long break." · "Some experience" / "6 months to 2 years of regular lifting." · "Experienced" / "2
years or more. You know the main lifts." (selected). Primary "Continue".

**11.5 `O115-Days.dc.html` · Days.** Progress 4 of 8. Question "Which days can you train?" Reason "Two to six.
SpotMe picks the split that fits them." A row of seven day buttons (`left: 16px; right: 16px`, `gap: 6px`, each
`flex: 1; height: 72px; border-radius: 16px; background: #1C1C1E`, the three-letter day in 15 / 20 / 700): Mon to
Fri selected (volt fill, black text), Sat and Sun not (`#B8B8BD`). Under it (`margin-top: 20px`) a card: eyebrow
"5 DAYS A WEEK" volt; "Push / Pull / Legs + Upper / Lower" headline, two lines allowed; "Every muscle about twice
a week." sub `#B8B8BD`. Primary "Continue".

**11.6 `O116-Minutes.dc.html` · Session length.** Progress 5 of 8. Question "How long is a session?" Reason
"Warmup included. Shorter sessions keep the most important lifts." A 2 × 2 grid `gap: 10px` of buttons 120 px
high, `border-radius: 24px`, `#1C1C1E`, centred column: the number at 40 / 44 / 800, "MIN" eyebrow `#8E8E93`, and a
caption in foot style `#B8B8BD`: 30 "The essentials" · 45 "A solid session" · 60 "A full session" (selected: tint,
volt outline, the number volt) · 75 "Everything". Primary "Continue".

**11.7 `O117-Place.dc.html` · Where.** Progress 6 of 8. Question "Where do you train?" Reason "So every exercise
is one you can actually do." Cards: "A full gym" / "Machines, cables, barbells and dumbbells." (selected) · "Home
gym" / "Dumbbells and a bench, maybe more." · "Bodyweight and bands" / "No weights needed." Under the cards
(`margin-top: 16px`) an action row card (form row, 52 px): "Adjust the equipment list" volt on the left, "Everything on" `#B8B8BD` on the right. Primary "Continue".

**11.8 `O118-Equipment.dc.html` · Equipment list** (440 × 1500, sheet: no left action, title "Your equipment",
right action "Done"). First a line in sub style `#B8B8BD` (`padding: 0 6px`): "Everything a full gym has is on.
Turn off what yours doesn't have." Then form groups whose rows end in a switch: FREE WEIGHTS: Dumbbells · Barbell
and squat rack · EZ bar · Kettlebells · Weight plates | BENCHES AND BARS: Flat bench · Adjustable bench · Pull-up
bar · Dip bars | CABLES: Cable machine · Cable crossover · Lat pulldown · Seated row | MACHINES: Leg press · Leg
extension · Leg curl · Chest press · Shoulder press · Smith machine · Hack squat (off) | SMALL KIT: Resistance
bands · Stability ball (off) · Ab wheel (off). All switches on except the three marked off.

**11.9 `O119-Injuries.dc.html` · Injuries.** Progress 7 of 8. Question "Anything that hurts, or has been
injured?" Reason "Take care: an old or mild problem. Avoid: it hurts now." One card (`padding: 0`) with eight rows
60 px high (`padding: 0 12px 0 16px`): the area in body style on the left; on the right a three-part control
(190 × 36, `border-radius: 10px`, `background: #2C2C2E`, three equal segments, labels 13 / 18 / 600 `#B8B8BD`: "Fine",
"Care", "Avoid"). The chosen segment is a filled inner capsule (`border-radius: 8px`, 2 px inset): Fine `#48484A`
with white text; Care `#FF9442` with black text; Avoid `#FF4569` with black text. Rows: Neck, Shoulder, Elbow, Wrist
(all Fine), Lower back (Care), Hip, Knee, Ankle (Fine). Footer under the card, foot style `#8E8E93`: "General
guidance, not medical advice. If something hurts, stop and see a professional." Primary "Continue".

**11.10 `O1110-AboutYou.dc.html` · Running and age.** Progress 8 of 8. Question "Two last things". No reason
line. Eyebrow "DO YOU RUN OR PLAY A SPORT AS WELL?" then three option cards without second lines (min-height
56): "No" · "Once or twice a week" · "Three times or more" (selected). Then (`margin-top: 26px`) eyebrow "YOUR AGE
(OPTIONAL)", a form row card: "Age" left, "Not set" `#B8B8BD` and a stepper right; footer foot style `#8E8E93`:
"From 50 the plan skips very heavy low-rep sets." Primary "See my answers".

**11.11 `O1111-Answers.dc.html` · Your answers.** Top row with back only (no progress bar). Question block: "Your
answers" title, "Tap a line to change it." reason. One form group card, rows (label body white, value body
`#B8B8BD`, right-aligned): Goal · Build muscle | More of · Arms, back | Experience · Experienced | Days · Mon to
Fri | Session · 60 min | Equipment · Full gym | Take care · Lower back | Running or sport · 3 times or more | Age ·
Not set. Primary "Build my plan".

**11.12 `O1112-Building.dc.html` · Building.** No top row. Centred column from `top: 250px`: the mark 72 px;
"Building your plan" title (`margin-top: 24px`). Then (`margin-top: 36px`, `padding: 0 48px`, column `gap: 20px`,
left-aligned) four step rows `gap: 14px`: a 24 px status mark and the step in body style. "Choosing your split"
(done: check icon volt, text `#B8B8BD`) · "Picking exercises for your gym" (done) · "Checking them against your
lower back" (now: a 22 px ring, 3 px stroke `#2C2C2E` with a volt quarter arc, text white) · "Fitting it into 60
minutes" (waiting: a 22 px ring `#2C2C2E`, text `#8E8E93`). No button.

**1.9 `W19-Setup.dc.html` · Watch · before a plan exists** (watch board, 416 × 496, rules of `1-watch.md`). Root
top bar with the clock only. Centred column from `top: 110px`: the mark 96 px; "Set up on your iPhone" title style
(34 / 38 / 700), centred, two lines (`margin-top: 18px`, `padding: 0 24px`); "Open SpotMe there to build your plan."
detail style `#B8B8BD`, centred (`margin-top: 10px`, `padding: 0 28px`). No button.

### 12 · The plan (built from `../plan-builder/plans/yeshu.json`: every name, number and sentence comes from that file)

**12.1 `O121-Plan.dc.html` · Your plan** (440 × 1500; set the height the content needs). No top row. "Your plan"
large title at `top: 102px`. Content column from `top: 158px`, `gap: 22px`:
- Summary card: eyebrow in volt = `summary.split` in capitals; title = "{daysPerWeek} days · about {minutes} min";
  then chips (`display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px`), each 13 / 18 / 600 white on `#2C2C2E`,
  `padding: 5px 12px; border-radius: 999px`: "Build muscle" · "More arms and back" · "Lower back: take care" ·
  "Runs 3+ a week".
- Section "YOUR WEEK": one card, a row per day, Monday to Sunday. Training day row (`padding: 13px 16px`):
  left a 44 px column with the three-letter day in eyebrow style volt; then the part of `focus` before " · " in
  headline style and under it the part after " · " in sub style `#B8B8BD`; on the right, right-aligned, the
  number of exercises (not counting warmup and cooldown) as "7 lifts" in sub style white and the day's `time`
  under it in foot style `#8E8E93`. Rest day row (44 px high): the day in eyebrow style `#8E8E93` and "Rest" in sub
  style `#8E8E93`.
- Section "WHY THIS PLAN": a card with the first three `summary.notes` as paragraphs in sub style white
  (`gap: 10px`), then an action row "Read all the reasons" volt.
- Pinned at the bottom of the board: a bar (`height: 128px; background: rgba(18,18,20,0.96); box-shadow: inset 0 1px 0
  rgba(255,255,255,0.10)`) holding the primary button "Start with this plan" (`top: 14px`) and under it a centred
  text button "Change my answers" (body style, `#B8B8BD`). The content column ends 22 px above this bar.

**12.2 `O122-Day.dc.html` · One day** (the plan's first training day; height as needed, about 1100). Pushed
screen, title = the weekday, no tab bar. Header (`padding: 0 6px`): `focus` in title 2 style (two lines allowed);
clock icon 16 px + `time` + " · N lifts" in sub style `#B8B8BD`. Then sections by `group` in plan order (as Today on
7.1): rows with the name, the detail "`display` · m:ss rest" (tick-off items show their `display` only), and on
the right of every lift a 44 px swap button (swap icon 20 px, `#B8B8BD`). No weights: none are known yet. After the
last section a footer in foot style `#8E8E93`: "Swap any exercise. SpotMe offers ones that train the same thing
with your equipment."

**12.3 `O123-Why.dc.html` · Why this plan** (height as needed, about 1250). Pushed screen, title "Why this
plan". (a) Card "SETS PER WEEK" (eyebrow volt): one row per group of `summary.weeklySets`, in its order, labelled Chest,
Back, Shoulders, Arms, Quads, Glutes and hams, Calves, Core: the name in sub style white (112 px column), a bar
(`height: 10px; border-radius: 5px`) whose length is the sets ÷ the largest value × the space available, volt for
the focus groups (arms, back) and `#48484A` for the others, and the number in sub 600 white at the right end.
Under the rows, foot style `#8E8E93`: "Arms and back are your focus." (b) A card per note in `summary.notes`, in order: the note in body style
white (`padding: 16px`, `border-radius: 20px`); the last note (how weights go up) has the up arrow icon 20 px volt
before it and a volt 1 px inset outline.

**12.4 `O124-Swap.dc.html` · Swap an exercise** (440 × 956, sheet with the close button). Use the first lift of
the first training day in the plan. Eyebrow "SWAP" `#8E8E93`; its name in title style; its detail (`display` ·
rest) in sub style `#B8B8BD`. Section "SAME MOVEMENT, YOUR EQUIPMENT": a card of rows built from that exercise's
`alternatives` in `../exercise-db/exercises.json`, in order, leaving out any whose lower-back rating is 3: name in
headline style; the alternative's `why` in sub style `#B8B8BD`; and, only where its lower-back rating is 2, on the
right a chip "TAKE CARE" in ember (black text). Then an action row card: "See every chest exercise" volt (use the
exercise's body part). Footer foot style `#8E8E93`: "The new exercise takes this one's place, sets and reps. It
starts its own history."

**12.5 `O125-Ready.dc.html` · Ready** (440 × 956). No top row. Centred column from `top: 190px`: a 96 px circle
`rgba(204,255,61,0.16)` with the check icon 44 px volt; "You're set" large title (`margin-top: 22px`); "Your plan
is on its way to your watch." body `#B8B8BD`, centred. Then a card (`margin-top: 32px`, rows `padding: 14px 16px`,
`gap: 14px`, icon 22 px volt + text body white): watch icon + "Open SpotMe on your watch and tap Start workout." ·
up icon + "The first time, you pick the weight for each lift. After that SpotMe suggests it." · heart icon (red) +
"The watch will ask to save workouts and read your heart rate." Primary "Go to today".

**12.6 `O126-Rebuild.dc.html` · Rebuild later** (440 × 956). The Settings screen (large title, tab bar with
Settings selected) scrolled to the top, with a new first form group "PLAN": Your plan · "Push / Pull / Legs +
Upper / Lower" (value in foot size so it fits) | Built for · "Muscle · 5 days · 60 min" | "Rebuild my plan" volt.
Footer: "Answer the questions again for a new plan. Your history is kept, and exercises that stay keep their
weights." Under it the PROGRAM group from board 10.1, cut by the tab bar. Over everything a dimming layer
(`rgba(0,0,0,0.5)`) and, pinned to the bottom (`left: 10px; right: 10px; bottom: 34px`), an action sheet: a card
(`border-radius: 16px; background: #2C2C2E`, centred text) with "Replace your plan?" foot 600 `#B8B8BD` and under it
"Your history is kept." foot `#8E8E93` (`padding: 14px`), a 1 px line, and "Rebuild my plan" in 20 / 25 / 500 volt
(row 58 px); 8 px under it a second card with "Cancel" in 20 / 25 / 600 white (row 58 px).

## Round 1 result (6 Oct 2026)

All 19 boards built, checked and looked at by the planner; on the canvas under Under review.
Final heights: 11.8 1658 · 12.1 1225 · 12.2 1021 · 12.3 1148; the rest 956. Accepted departures: 11.2's card
lines were shortened to stay on one line ("Bigger, fuller muscles. Mostly 6 to 15 reps." and "Same lifting,
shorter rests. Food does the rest."); 11.7's action row reads "Everything on"; 11.12's step list is a centred
block; 12.3's name column is 128 px; 12.4 shows no TAKE CARE chip because no alternative of that exercise is
rated 2 for the lower back; 12.6 also shows the Apple Health group under the sheet.
The plan on 12.1 to 12.4 is `plan-builder/plans/yeshu.json`, built by the reference from the answers on 11.11.
