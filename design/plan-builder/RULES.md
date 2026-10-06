# SpotMe plan builder · rules

Asked by Yeshu, 6 Oct 2026: "user onboarding, where we get the important information to build the workout
tailored for that particular user and his goals; then we create an amazing workout plan based on those goals."
Planner: Fable. Status: design, waiting for Yeshu's review.

The builder is a set of fixed rules that run on the phone: no account, no server, no model call. Its input
is the answers from onboarding; its output has the same shape as `plan.json`, so the app's Today, watch flow
and `ProgressionEngine` use it unchanged. Exercises come from `../exercise-db/exercises.json`.

`build_plan.py` is the reference (as `docs/engine_reference.py` is for the engine): the Swift version must
produce the same plans. `check_plan.py` is the planner's independent check of what it produces.

## What onboarding asks, and why each answer matters

| # | Question | Answers | What it changes |
|---|---|---|---|
| 1 | What are you training for? | Build muscle · Get stronger · Lose fat, keep muscle · Stay fit and healthy | Rep ranges, rests, sets |
| 2 | Anything you want more of? (optional) | Up to two of: chest, back, shoulders, arms, glutes, legs, core | Extra sets and exercises there, never trimmed |
| 3 | How long have you lifted? | New (under 6 months) · Some (6 months to 2 years) · Experienced (2 years and more) | Sets, exercise difficulty, how many days make sense |
| 4 | Which days can you train? | Two to six weekdays | The split and which day is what |
| 5 | How long is a session? | 30 · 45 · 60 · 75 minutes | How many exercises and sets fit |
| 6 | Where do you train? | Full gym · Home gym · Bodyweight and bands, each adjustable item by item | Which exercises are possible |
| 7 | Anything that hurts or has been injured? | For each of neck, shoulder, elbow, wrist, lower back, hip, knee, ankle: fine · take care · avoid | Exercises are left out or swapped for gentler ones |
| 8 | Do you run or play a sport as well? | No · Once or twice a week · Three times or more | Leg volume and extras for runners |
| 9 | How old are you? (optional) | A number | From 50: no very heavy low-rep sets, joint-friendly picks first |

Not asked, on purpose: weight and height (Health has them and the plan doesn't need them), sex (the focus
question covers what it would change), starting weights (the watch asks the first time, as it does today).

## The answers, as data

```json
{
  "goal": "muscle",
  "focus": ["arms", "back"],
  "experience": "experienced",
  "days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
  "minutes": 60,
  "equipment": ["dumbbells", "adjustable-bench", "..."],
  "injuries": {"lowerBack": "care"},
  "cardio": 2,
  "age": null
}
```

`goal`: `muscle`, `strength`, `lean`, `fit`. `experience`: `new`, `some`, `experienced`. `cardio`: 0 none,
1 once or twice a week, 2 three times or more. `equipment` uses the database's words; `bodyweight` and `wall`
are always added. `injuries` holds only the areas that are not fine: `care` or `avoid`.

Equipment presets (the item-by-item screen starts from one of these):
- **Full gym:** every word in the database's equipment vocabulary.
- **Home gym:** dumbbells, adjustable-bench, flat-bench, mat, step, resistance-band. Offered as extras:
  pull-up-bar, barbell + squat-rack + weight-plate, kettlebell, cable-machine, stability-ball.
- **Bodyweight and bands:** mat, step, resistance-band. Offered as extras: pull-up-bar, dumbbells, flat-bench.

## Step 1 · Lifting days and the split

Most days that make sense: new 4, some 5, experienced 6. If more days were picked, keep that many, chosen so
the smallest gap between two training days (counting round the week) is as large as possible; on a tie keep
the set that starts earliest in the week. Say so in the summary.

| Days | Split | Day types, in weekday order |
|---|---|---|
| 2 | Full body | Full A, Full B |
| 3 | Full body | Full A, Full B, Full C |
| 4 | Upper / Lower | Upper A, Lower A, Upper B, Lower B |
| 5 | Push / Pull / Legs + Upper / Lower | Push, Pull, Legs, Upper B, Lower B |
| 6 | Push / Pull / Legs, twice | Push, Pull, Legs, Push B, Pull B, Legs B |

## Step 2 · Slots

A day is a list of slots. A slot is a kind of movement the builder fills with one exercise.

| Slot | `pattern` | `bodyPart` | Class | Counts toward |
|---|---|---|---|---|
| squat | squat | quads | big | legs |
| single-leg | single-leg | quads | big | legs |
| hinge | hinge (hip-extension as a second choice, see Step 4) | hamstrings, glutes | big | legs |
| glute | hip-extension | glutes | small | glutes |
| leg-curl | knee-flexion | hamstrings | small | legs |
| leg-ext | knee-extension | quads | small | legs |
| calves | calf-raise | calves | small | legs |
| adductor | hip-adduction | hips | small | legs |
| press | horizontal-push | chest | big | chest |
| incline | incline-push | chest | big | chest |
| fly | chest-fly | chest | small | chest |
| overhead | vertical-push | shoulders | big | shoulders |
| lateral | lateral-raise | shoulders | small | shoulders |
| rear | rear-delt-pull | shoulders | small | shoulders |
| row | horizontal-pull | back | big | back |
| pull | vertical-pull | back | big | back |
| curl | curl | biceps | small | arms |
| triceps | triceps-extension | triceps | small | arms |
| core-brace | core-anti-extension | core | core | core |
| core-twist | core-anti-rotation, core-lateral | core | core | core |
| core-flex | core-flexion | core | core | core |

"Counts toward" is the focus area a slot belongs to (question 2) and the group its sets are added to in the
weekly summary. `glute` counts toward both glutes and legs for focus.

Day templates. The order is the order in the workout. The number is the slot's priority: 1 is never removed,
3 is removed first when time is short.

| Day type | Slots |
|---|---|
| Full A | squat 1 · press 1 · row 1 · leg-curl 2 · lateral 3 · core-brace 2 |
| Full B | hinge 1 · overhead 1 · pull 1 · single-leg 2 · curl 3 · triceps 3 · core-twist 3 |
| Full C | squat 1 · incline 1 · row 1 · hinge 2 · rear 3 · core-flex 2 |
| Upper A | press 1 · row 1 · overhead 1 · pull 1 · lateral 2 · triceps 3 · curl 3 |
| Upper B | incline 1 · pull 1 · row 1 · fly 2 · rear 2 · curl 3 · triceps 3 |
| Lower A | squat 1 · hinge 1 · single-leg 2 · leg-curl 2 · calves 3 · core-brace 2 |
| Lower B | hinge 1 · squat 1 · leg-ext 2 · leg-curl 2 · calves 3 · core-twist 2 |
| Push | press 1 · incline 1 · overhead 1 · lateral 2 · triceps 2 · triceps 3 · fly 3 |
| Pull | pull 1 · row 1 · row 2 · rear 2 · curl 2 · curl 3 · core-flex 3 |
| Legs | squat 1 · hinge 1 · single-leg 2 · leg-curl 2 · calves 2 · leg-ext 3 · core-brace 3 |
| Push B | overhead 1 · incline 1 · press 2 · lateral 2 · triceps 2 · fly 3 |
| Pull B | row 1 · pull 1 · pull 2 · rear 2 · curl 2 · curl 3 |
| Legs B | hinge 1 · squat 1 · leg-ext 2 · leg-curl 2 · calves 2 · core-twist 3 |

A day's region: Full days are both; Upper, Push, Pull and their B days are upper; Lower and Legs days are lower.

Changes to the templates, applied in this order before anything is picked:

1. **Focus.** For each focus area: every slot that counts toward it moves up one priority (3 → 2, 2 → 1) and
   is a "focus slot". And on each day that already has at least one slot counting toward that area (core: every
   day; glutes: every day with a slot counting toward legs), if the day has no slot of this kind yet, add one at priority 2 (also a focus slot) just before the first core slot, or at the end: chest → fly,
   back → row, shoulders → lateral, arms → curl on upper days that have a pull or row and triceps on upper days
   that have a press, incline or overhead (both on Full and Upper days), glutes → glute, legs → leg-ext,
   core → core-flex on every day that has no core slot. Extra sets: see Step 3.
2. **Cardio 2 (three or more runs or sport days a week).** On every day with lower-body slots: the big
   lower-body slots get one set fewer (Step 3). Each lower day (Lower A, Lower B, Legs, Legs B) that has no
   calves slot gets one at priority 2, and the first lower day of the week gets an adductor slot at priority 3;
   both go just before the first core slot, or at the end.

## Step 3 · Sets, reps and rest

Reps and rest (seconds) by goal. "First big" is the first big slot of the day.

| Slot | muscle | strength | lean | fit |
|---|---|---|---|---|
| first big | 6–10 · 150 | 4–6 · 180 | 6–10 · 120 | 8–12 · 90 |
| other big | 8–12 · 120 | 6–8 · 150 | 8–12 · 90 | 8–12 · 90 |
| small | 10–15 · 75 | 8–12 · 75 | 12–15 · 60 | 12–15 · 60 |
| core, counted in reps | 8–12 · 45 | 8–12 · 45 | 10–15 · 45 | 10–15 · 45 |
| core or any slot filled by a timed exercise | 30–45 s · 45 | the same | the same | the same |

- New lifters and anyone aged 50 or more never get 4–6: their first big slot on a strength plan is 6–8 · 150.
- A timed exercise counted per side is 20–30 s. New lifters hold 20–30 s (15–20 s per side).

Sets:

| Slot | new | some | experienced |
|---|---|---|---|
| first big of the day | 3 | 3 | 4 |
| other big | 2 | 3 | 3 |
| small | 2 | 3 | 3 |
| core | 2 | 3 | 3 |

Then, in this order: goal `strength`: first big +1, small −1. Goal `fit`: nothing above 3. Focus: +1 on the
area's small slots (for a core focus: its core slots), and on the day's first big slot when it is a focus slot. Cardio 2: −1 on big lower-body
slots. Sessions of 30 minutes: every rest is 30 seconds shorter, never under 45. Every slot ends between 2 and 4 sets; only the first big of a
strength day may have 5.

## Step 4 · Picking the exercise for a slot

Fill the days in week order and the slots in day order. For a slot, the candidates are the database
exercises where all of this holds:

1. `pattern` and `bodyPart` match the slot. (A hinge slot also takes `hip-extension` exercises, at a cost:
   see the score.)
2. Everything in `equipment` is in the user's equipment.
3. Level: new → `beginner`; some → `beginner` or `intermediate`; experienced → any. If that leaves no
   candidate, allow one level harder.
4. Injuries: for an area marked `avoid` the exercise's rating there is 0 or 1. For an area marked `care` it
   is 0, 1 or 2.
5. It is not already in this day.
6. A priority-3 slot, and the second slot of the same kind in a day, never takes a tier-3 exercise: with
   nothing better the slot is left out, without a note.

Score each candidate; the lowest score wins. On a tie the gentler exercise wins (the lower sum of its eight
injury ratings), then the id that comes first alphabetically:

| Add | When |
|---|---|
| 10 × `tier` (15 × `tier` for the day's first big slot) | always |
| 6 | for each `care` area where the exercise is rated 2 |
| 15 | it is already used on an earlier day this week |
| 10 in a big slot, 5 in a small slot | the exercise is not `logAs: weighted` (weight you can add in steps is preferred) |
| 4 | the slot is a hinge and the exercise's pattern is `hip-extension` |
| 5 | an exercise already picked today has the same `bodyPart` and the same first equipment item (two barbell chest presses in a row) |
| 4 | its level is one above what rule 3 would normally allow |
| 3 | the user is new and it needs a barbell |
| 3 | the user is 50 or older and its lower back + knee + shoulder ratings add up to 5 or more |
| −3 | the goal is `strength`, the slot is big, and `loadType` is `barbell-total` |

No candidate: leave the slot out and add a note to the summary that names the real cause. If candidates
exist when injuries are ignored: "Nothing for biceps suits your elbow, so it is left out." (the slot's plain
name, the injured areas that ruled the candidates out). Otherwise: "No calf exercise fits your equipment."

Plain names for notes: squat "squat" · single-leg "single-leg" · hinge "hip-hinge" · glute "glute" · leg-curl
"hamstring curl" · leg-ext "leg extension" · calves "calf" · adductor "inner-thigh" · press "chest press" ·
incline "incline press" · fly "chest fly" · overhead "overhead press" · lateral "side raise" · rear
"rear-shoulder" · row "row" · pull "pull-down" · curl "biceps" · triceps "triceps" · the three core slots "core".

## Step 5 · Fitting the session length

Minutes for one exercise = sets × (0.7 + rest ÷ 60); counted per side: sets × (1.2 + rest ÷ 60); timed:
sets × ((top of the range in seconds, doubled when per side) ÷ 60 + rest ÷ 60). A day = 6 (warmup) + its
exercises + 4 (cooldown). The day must not be longer than the chosen minutes + 5.

While a day is too long, do the first of these that is possible:
1. Remove the last priority-3 slot.
2. Take one set off the last slot (in day order) that has more than 2 sets and is not priority 1.
3. Remove the last priority-2 slot.
4. Take one set off the last priority-1 slot that has more than 2 sets and is not a focus slot.
5. Take one set off the last focus slot that has more than 2 sets.

When nothing is possible the day stays as it is and the summary says the session runs long.
After that, if a day is more than 5 minutes short: add one set at a time to the big slots only (never to
lower-body big slots when cardio is 2: their set was taken off on purpose), going through
them in order of priority (all priority 1 first to last, then 2, then 3) and round again, as long as the day
still fits and no big slot goes above 4 (3 for new lifters and when the goal is `fit`). A set that would not fit
is skipped. Small and core slots are never topped up.

Trimming happens after exercises are picked (Step 4), so a removed slot's exercise becomes free for later days.
Do Steps 4 and 5 one day at a time.

## Step 6 · Warmup and cooldown

Every training day starts with a tick-off item "Warmup · 6 min" (group "Warmup", display "6 min") and ends with
"Cooldown stretches" (group "Cooldown", display "4 min").

Warmup steps: upper days: "Light cardio 2–3 min" · "Arm circles · 10 each way" · "Band pull-aparts · 1 × 15"
(only with `resistance-band`, else "Wall slides · 1 × 10") · "Scapular push-ups · 1 × 10" · "Light set of your
first lift · 1 × 10 at ~50%". Lower days: "Light cardio 3 min" · "Bodyweight squats · 1 × 10" · "Hip hinges ·
1 × 10" · "Glute bridges · 1 × 10" · "Light set of your first lift · 1 × 10 at ~50%". Full days: "Light cardio
3 min" · "Bodyweight squats · 1 × 10" · "Scapular push-ups · 1 × 10" · "Glute bridges · 1 × 10" · "Light set of
your first lift · 1 × 10 at ~50%".

Cooldown note: upper "Doorway pec stretch · overhead triceps stretch · lat stretch, 30s each." Lower "Couch
stretch · hamstring stretch · calf stretch, 30s each side." Full "Doorway pec stretch · couch stretch ·
hamstring stretch, 30s each."

## Step 7 · The plan that comes out

The same shape as `Packages/RepCoachCore/.../Resources/plan.json` (read it and `Plan.swift` for the fields),
plus a `summary`:

```json
{
  "planVersion": 1,
  "deloadEveryNthWeek": 6,
  "days": [ {"key": "monday", "weekday": 2, "title": "Monday", "focus": "Push · Chest, Shoulders & Triceps", "time": "~58 min", "items": [ ... ]}, ... all seven days ... ],
  "summary": {
    "split": "Push / Pull / Legs + Upper / Lower",
    "daysPerWeek": 5,
    "minutes": 60,
    "weeklySets": {"chest": 14, "back": 18, "shoulders": 12, "arms": 14, "quads": 12, "glutesHamstrings": 14, "calves": 6, "core": 6},
    "notes": ["..."]
  }
}
```

- All seven days, Monday first. `weekday` as in `plan.json` (1 Sunday … 7 Saturday). A day without lifting has
  focus "Rest", time "Nothing planned" and one tick-off item: name "Rest day", exerciseId `rest-<key>`, group
  "Recovery", display "—", note "No lifting today. Walk, sleep and eat well."
- Day `time`: "~N min", N the day's minutes from Step 5 rounded to the nearest 5.
- Day `focus`: Full A "Full Body A · Squat, Press & Row" · Full B "Full Body B · Hinge, Overhead & Pull" · Full C
  "Full Body C · Squat, Incline & Row" · Upper A "Upper A · Press & Row" · Upper B "Upper B · Incline & Pull" ·
  Lower A "Lower A · Squat Focus" · Lower B "Lower B · Hinge Focus" · Push "Push · Chest, Shoulders & Triceps" ·
  Pull "Pull · Back & Biceps" · Legs "Legs · Quads, Hamstrings & Calves" · Push B "Push B · Shoulders & Chest" ·
  Pull B "Pull B · Rows & Biceps" · Legs B "Legs B · Hinge & Quads".
- An exercise item: `name` and `exerciseId` from the database (`exerciseId` = the database `id`), `group` = its
  `bodyPart` with a capital letter ("Chest", "Quads"; core slots "Core"), `note` = the database `cue`,
  `display` ("4 × 6–10", "3 × 30–45s", "3 × 10–15/side"), `sets`, `kind` (`weighted`, `reps` or `timed`, from
  `logAs`), `repMin`/`repMax` or `secMin`/`secMax`, `perSide`, `loadable` (reps and timed only), `increment`
  (from `incrementKg`, when it has one), `restSec`, and `sessionsAtTopToProgress: 1` for weighted items.
- `weeklySets`: sets per week by the picked exercise's `bodyPart`: chest · back · shoulders · arms (biceps,
  triceps, forearms) · quads · glutesHamstrings (glutes, hamstrings, hips) · calves · core (core, full-body).
  Always these eight keys, in this order.
- `notes`: plain sentences for the "Why this plan" screen, in this order, each only when it applies:
  1. Split: "Full body, three days: every muscle is trained three times a week." / "Upper / Lower, four days:
     every muscle is trained twice a week." / the same pattern for the others (5 days: "about twice", 6 days:
     "twice", 2 days: "twice").
  2. Days kept: "Four days to start with. More would not build faster yet, and you recover better. Friday is
     left free." (new) or "Five days is the most this plan uses; Saturday is left free." (name the dropped days).
  3. Goal: muscle "Most sets are 6 to 15 reps, close to failure: the range that builds muscle." · strength
     "The first lift of each day is heavy, 4 to 6 reps with long rests." (6 to 8 when the 4–6 rule doesn't apply)
     · lean "Same lifting as for muscle, with shorter rests. The fat loss comes from eating, the lifting keeps
     your muscle." · fit "Moderate reps and short rests: a little of everything, nothing extreme."
  4. Focus: "Extra sets for arms and back, and they are the last thing to be cut when time is short."
  5. One per injury: care "Lower back: nothing risky for it is in the plan, and gentler options were picked
     first." · avoid "Knee: nothing that loads it is in the plan."
  6. Cardio 2: "Lighter leg work, with extra calf and inner-thigh work, to leave room for your running."
  7. Age 50+: "No very heavy low-rep sets, and joint-friendly exercises first."
  8. Time: "Trimmed to fit 45 minutes: the most important lifts stayed." (when Step 5 removed or reduced
     anything) and "Tuesday runs a little over 45 minutes." (when it could not be made to fit).
  9. Missing slots: one sentence per slot kind left out, worded as in Step 4.
  10. Always last: "Weights go up by themselves: reach the top of the rep range on every set and next time adds
      one step. Every 6th week is a lighter deload week."

## Personas the reference is tested on (`personas/*.json`)

| File | Who |
|---|---|
| `yeshu.json` | muscle · focus arms, back · experienced · Mon–Fri · 60 min · full gym · lower back: care · cardio 2 |
| `starter.json` | fit · no focus · new · Mon, Wed, Fri · 45 min · full gym · no injuries · cardio 0 · age 28 |
| `home.json` | lean · focus glutes · some · Mon, Tue, Thu, Sat · 45 min · home gym, no extras · knee: care · cardio 1 |
| `strong.json` | strength · focus none · experienced · Mon, Tue, Thu, Fri · 75 min · full gym · shoulder: care · cardio 0 |
| `minimal.json` | fit · focus core · new · Tue, Sat · 30 min · bodyweight and bands, no extras · no injuries · cardio 0 |
| `senior.json` | muscle · focus legs · some · all six days Mon–Sat · 60 min · full gym · elbow: avoid, lower back: care · cardio 1 · age 55 |
