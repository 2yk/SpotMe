# SpotMe exercise database · rules for builders

One JSON file of strength exercises the app can offer as swaps or additions. Each exercise says what
equipment it needs, the body part it trains, how hard it is on each injury area, and which other
exercises can replace it. The planner (Fable) wrote these rules; `validate.py` enforces them.

Scope: exercises you log with sets (weight and reps, reps, or seconds) in a commercial gym. No cardio,
stretching, warmups or mobility drills. Kilograms only.

## Files

- `parts/<part>.json`: one JSON array per builder (chest-triceps, back-neck, shoulders-arms, legs, core).
- `validate.py`: `python3 validate.py parts/<part>.json` checks one part; `--check` checks all parts together; `--merge`
  checks everything and writes `exercises.json`. Never edit `exercises.json` by hand.

## One exercise

```json
{
  "id": "chest-supported-db-row",
  "name": "Chest-Supported DB Row",
  "aliases": ["Incline Dumbbell Row", "Prone Dumbbell Row"],
  "planIds": ["chest-supported-db-row"],
  "bodyPart": "back",
  "primaryMuscles": ["upper-back", "lats"],
  "secondaryMuscles": ["rear-delts", "biceps"],
  "pattern": "horizontal-pull",
  "equipment": ["dumbbells", "adjustable-bench"],
  "logAs": "weighted",
  "perSide": false,
  "loadType": "per-dumbbell",
  "incrementKg": 2.5,
  "level": "beginner",
  "cue": "Chest on a 30–45° bench. Pause a second at the top and squeeze the blades.",
  "injury": {"neck": 1, "shoulder": 1, "elbow": 1, "wrist": 1, "lowerBack": 0, "hip": 0, "knee": 0, "ankle": 0},
  "injuryNotes": {},
  "alternatives": [
    {"id": "seated-cable-row", "why": "Same pull on a cable; sit tall, light back work"},
    {"id": "machine-row", "why": "Chest pad too; use it when the benches are taken"}
  ]
}
```

| Field | Rule |
|---|---|
| `id` | kebab-case, unique. For an exercise in Yeshu's plan use the id given in the table below. |
| `name` | Title Case as a gym-goer would say it, max 34 characters, unique. "DB" for dumbbell, as the plan does. |
| `aliases` | 0–4 other common names. |
| `planIds` | The `exerciseId`s in `plan.json` this is. `[]` when it is not in the plan. |
| `bodyPart` | The one part it mainly trains (vocabulary below). |
| `primaryMuscles` | 1–3 from the muscle vocabulary, main mover first. |
| `secondaryMuscles` | 0–4, none repeated from primary. |
| `pattern` | One movement pattern (vocabulary below). |
| `equipment` | Everything needed, all at once (vocabulary below). `["bodyweight"]` alone when nothing is needed. Never mix `bodyweight` with other items. For a `loadable` exercise list only what the unloaded version needs (a plank is `["mat"]`, chin-ups `["pull-up-bar"]`), unless the weight is the exercise (a carry needs its dumbbell). |
| `attachment` | Optional, cable work only: the handle that is needed. |
| `logAs` | `weighted` (weight + reps every set), `reps` (reps only) or `timed` (seconds). |
| `perSide` | `true` when reps or seconds are counted per side. |
| `loadable` | Only for `reps` and `timed`: `true` when weight can be added. Leave it out for `weighted`. |
| `loadType` | How the logged weight is counted (vocabulary below). `bodyweight` when no weight is ever logged. |
| `incrementKg` | Smallest sensible jump. Needed when `logAs` is `weighted` or `loadable` is true, otherwise leave out. Dumbbells 2.5 (1 for raises and other small-muscle isolation), barbell 2.5, cables 2.5, selectorised machines 5, leg press 10, hip thrust 5, added weight on a belt 2.5. |
| `level` | `beginner`, `intermediate` or `advanced` (skill and strength needed to do it well). |
| `cue` | One or two short sentences on setup and form, max 110 characters, the plan's voice ("Elbows to ribs."). Angles with the degree sign ("30° bench"). |
| `injury` | All eight areas, each 0–3 (scale below). |
| `injuryNotes` | A short reason (max 70 characters) for every area rated 2 or 3. Optional for 1. None for 0. |
| `alternatives` | 3–8 swaps, best first (rules below). |

## Injury scale

Rate how much the exercise stresses the area for someone whose problem is in that area. The app turns
3 into "avoid" and 2 into "take care", so be honest and consistent: the anchors matter more than
instinct. Rate the standard form with a normal working weight, not sloppy form.

- **0 · none.** The area is not loaded and does not move under load. (Leg extension for the shoulder.)
- **1 · low.** The area works lightly, or is supported or held neutral. Fine with an old or mild problem.
- **2 · take care.** The area carries real load or moves through a loaded range. With a current or
  recurring problem: only pain-free, lighter, shorter range.
- **3 · avoid.** The area is the main load-bearer, or is loaded in the position that injures it.

Anchors (use these exact ratings, and rate neighbours relative to them):

| Area | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| `lowerBack` | Chest-supported row, leg extension, lying leg curl, machine chest press | Lat pulldown, seated cable row sitting tall, standing cable curl, dead bug, bird-dog, hanging leg raise with no swing | Leg press, hip thrust, standing overhead press, unsupported one-arm DB row, plank, back extension to neutral, Bulgarian split squat | Barbell back squat, deadlift, Romanian deadlift, bent-over barbell row, good morning, weighted sit-up, weighted Russian twist, ab wheel rollout |
| `neck` | Leg press, leg curl | Most pressing and pulling | Shrugs, upright row, crunches with hands behind the head, behind-the-neck work at light load | Neck bridges, behind-the-neck barbell press, heavy neck harness work |
| `shoulder` | Leg work on machines, curls with arms at the sides (1 at most) | Rows, pulldowns to the front, pushdowns, landmine press | Bench press, overhead press, dips to parallel, lateral raise, pull-ups, flyes | Behind-the-neck press or pulldown, upright row above the chest, deep dips, wide-grip bench to the neck |
| `elbow` | Leg machines, planks on forearms | Rows, presses | Curls, pushdowns, pull-ups, chin-ups, dips | Skull crushers, heavy close-grip pressing, straight-bar preacher curl at full stretch |
| `wrist` | Machines with pads, leg work | Neutral-grip dumbbell and cable work | Straight-bar curls and presses, push-ups on flat hands, front-rack holds | Wrist curls, wrist roller, handstand work, heavy straight-bar reverse curls |
| `hip` | Upper-body work seated or lying | Calf raises, leg extension, leg curl | Squats, lunges, leg press, hip thrust, hanging leg raise | Deep squats, wide sumo work, Copenhagen plank, heavy hip adduction and abduction, deep Bulgarian split squat |
| `knee` | Upper-body work, hip thrust (1 at most) | Leg curl, Romanian deadlift, glute bridge | Leg press, squats to parallel, lunges, step-ups | Leg extension with heavy load, sissy squat, deep hack squat, jump work, pistol squat |
| `ankle` | Seated and lying work | Leg press, leg curl, hip thrust | Squats, lunges, carries | Calf raises (it is the target), jumps, deep-knee-over-toe squats |

If the target of the exercise is the injured area itself (calf raise for the ankle, wrist curl for the
wrist), that is a 3. The one exception is light rehab-style work on that area, done with a band, bodyweight
or a very light cable or dumbbell (rotator-cuff rotations, neck isometrics, band abduction, tibialis raise):
that is a 2.

## Alternatives

A swap is something Yeshu could do in the same slot of the workout: same main muscle, same or a
close movement pattern, ideally the same `logAs`.

- 3–8 per exercise, closest swap first.
- At least one that needs different equipment (for when the machine is taken).
- When an area is rated 2 or 3, include at least one swap rated lower on that area if one exists, and say so
  in its `why` ("Chest on a pad, nothing on the lower back").
- Links go both ways: if A lists B, B lists A.
- `why`: max 48 characters, plain words, what differs or why it is a good swap. No trailing full stop.
- Never link an exercise to itself. Links across parts are welcome when the swap is real; they are checked at merge.

## Vocabularies (use these exact strings; if something is truly missing, say so in your report and use the closest)

**bodyPart:** chest, back, shoulders, biceps, triceps, forearms, core, glutes, quads, hamstrings, calves, hips, neck, full-body

**muscles:** upper-chest, mid-chest, lower-chest, serratus, lats, upper-back, upper-traps, lower-traps,
rear-delts, front-delts, side-delts, rotator-cuff, biceps, brachialis, brachioradialis, forearm-flexors,
forearm-extensors, triceps, triceps-long-head, abs, lower-abs, obliques, deep-core, spinal-erectors, glutes,
glute-med, quads, hamstrings, adductors, hip-flexors, calves, soleus, tibialis, neck-flexors, neck-extensors, grip

(`upper-back` = rhomboids and mid traps.)

**pattern:** horizontal-push, incline-push, decline-push, vertical-push, chest-fly, dip, horizontal-pull,
vertical-pull, straight-arm-pull, rear-delt-pull, lateral-raise, front-raise, shrug, curl, triceps-extension,
wrist-work, squat, single-leg, hinge, hip-extension, knee-flexion, knee-extension, calf-raise, hip-abduction,
hip-adduction, hip-flexion, core-flexion, core-anti-extension, core-anti-rotation, core-rotation, core-lateral,
core-extension, carry, hang, neck-work, shoulder-rotation, tibialis-raise

**equipment:** bodyweight, dumbbells, barbell, ez-bar, weight-plate, kettlebell, flat-bench, adjustable-bench,
squat-rack, smith-machine, cable-machine, cable-crossover, lat-pulldown-machine, seated-row-machine,
row-machine, t-bar-row, pull-up-bar, assisted-pull-up-machine, dip-bars, dip-belt, resistance-band,
chest-press-machine, incline-press-machine, shoulder-press-machine, pec-deck, lateral-raise-machine,
leg-press-machine, hack-squat-machine, leg-extension-machine, lying-leg-curl-machine, seated-leg-curl-machine,
standing-calf-machine, seated-calf-machine, hip-thrust-machine, glute-kickback-machine, hip-abduction-machine,
hip-adduction-machine, preacher-bench, preacher-curl-machine, biceps-curl-machine, triceps-machine, dip-machine, decline-bench,
back-extension-bench, ab-crunch-machine, captains-chair, ab-wheel, medicine-ball, stability-ball,
suspension-trainer, landmine, trap-bar, step, mat, wall, neck-harness

(`cable-machine` = one adjustable pulley; `cable-crossover` = two pulleys used together. `row-machine` =
chest-supported plate or stack row. `mat` only when the exercise is done lying or kneeling on the floor.)

**attachment:** rope, straight-bar, ez-bar-attachment, v-handle, d-handle, lat-bar, ankle-strap, dual-d-handles

**loadType:** per-dumbbell, barbell-total, stack, plates, added, bodyweight, band, single-weight

(`barbell-total` includes the bar. Smith machine work is always `plates`: its bar weight differs from gym to gym. `plates` = plate-loaded machine, plates only. `added` = bodyweight plus a
belt, vest or held weight. `single-weight` = one dumbbell, kettlebell, plate or ball held.)

**level:** beginner, intermediate, advanced

**logAs:** weighted, reps, timed

## Yeshu's plan: ids and who owns them

Every plan exercise must be in the database, under exactly this id, with these `planIds`.

| Database id | planIds | Part |
|---|---|---|
| incline-db-press | incline-db-press | chest-triceps |
| machine-chest-press | machine-chest-press-or-flat-bench | chest-triceps |
| db-bench-press | db-bench-press | chest-triceps |
| low-to-high-cable-fly | low-to-high-cable-fly | chest-triceps |
| overhead-cable-extension | overhead-cable-extension, cable-overhead-extension | chest-triceps |
| rope-pushdown | rope-pushdown | chest-triceps |
| ez-bar-skull-crusher | ez-bar-skull-crusher | chest-triceps |
| weighted-pull-ups | weighted-pull-ups | back-neck |
| pull-ups | max-rep-set, volume-sets | back-neck |
| band-assisted-pull-ups | band-assisted-pull-ups | back-neck |
| chest-supported-db-row | chest-supported-db-row | back-neck |
| close-grip-lat-pulldown | close-grip-lat-pulldown | back-neck |
| single-arm-cable-row | single-arm-cable-row | back-neck |
| straight-arm-pulldown | straight-arm-pulldown | back-neck |
| face-pulls | face-pulls | shoulders-arms |
| reverse-pec-deck | reverse-pec-deck | shoulders-arms |
| seated-db-shoulder-press | seated-db-shoulder-press | shoulders-arms |
| machine-shoulder-press | machine-shoulder-press | shoulders-arms |
| cable-lateral-raise | cable-lateral-raise | shoulders-arms |
| db-lateral-raise | db-lateral-raise | shoulders-arms |
| incline-db-curl | incline-db-curl | shoulders-arms |
| hammer-curl | hammer-curl | shoulders-arms |
| preacher-curl | preacher-curl | shoulders-arms |
| cable-curl | cable-curl-drop-set | shoulders-arms |
| bayesian-cable-curl | bayesian-cable-curl | shoulders-arms |
| leg-press | leg-press | legs |
| bulgarian-split-squat | bulgarian-split-squat-dbs | legs |
| hip-thrust | hip-thrust | legs |
| lying-hamstring-curl | lying-hamstring-curl | legs |
| leg-extension | leg-extension | legs |
| standing-calf-raise | standing-calf-raise | legs |
| copenhagen-plank | copenhagen-plank | legs |
| glute-bridge | glute-bridge-with-hold | legs |
| hanging-leg-raise | hanging-leg-raise | core |
| cable-crunch | cable-crunch | core |
| bicycle-crunch | bicycle-crunch | core |
| hanging-knee-to-elbow-twist | hanging-knee-to-elbow-twist | core |
| russian-twist | russian-twist-weighted | core |
| toe-touches | toe-touches | core |
| dead-bug | dead-bug | core |
| bird-dog | bird-dog | core |
| bird-dog-plank | bird-dog-plank-hybrid | core |
| superman-hold | superman-hold | core |
| hollow-body-hold | hollow-body-hold | core |
| pallof-press | pallof-press | core |
| suitcase-carry | suitcase-carry | core |
| ab-wheel-rollout | ab-wheel-rollout-knees | core |
| plank | weighted-plank | core |
| side-plank-with-reach | side-plank-with-reach | core |
| l-sit | l-sit-progression | core |

For a plan exercise, keep `logAs`, `perSide`, `loadable` and `incrementKg` (where the plan gives one) the same as `plan.json`
(`../../Packages/RepCoachCore/Sources/RepCoachCore/Resources/plan.json`; `amrap` and `percentOfMax` are `reps`),
and base `cue` on the plan's note. Rate its injury impact as honestly as any other exercise: the plan gets
no free pass.

## Parts: who builds what

Each part is one builder. Stay inside your list of body parts; the "also yours / not yours" lines settle the
exercises that could sit in two places, so nothing is built twice. Counts are a guide: cover what a
well-equipped commercial gym offers and what people actually do, common variants included, without padding.

| Part file | bodyPart values | About | Must include (besides the plan table) |
|---|---|---|---|
| `chest-triceps.json` | chest, triceps | 40–45 | Barbell, dumbbell, Smith and machine presses flat, incline and decline; push-up variants; dips (one entry, chest) and bench dips; cable, dumbbell and machine flyes; pushdowns, overhead and lying extensions, kickbacks, close-grip bench, triceps machine, diamond push-up |
| `back-neck.json` | back, neck | 40–45 | Pull-up and chin-up variants, assisted machine; pulldown variants; DB pullover; rows of every kind (cable, machine, dumbbell, barbell, T-bar, inverted, Smith); shrugs; rack pull; back extension; dead hang and scapular pull-up; 5–6 neck exercises that are logged with sets (plate, harness, band, isometric holds) |
| `shoulders-arms.json` | shoulders, biceps, forearms | 45–50 | Overhead presses (dumbbell, barbell, machine, Smith, Arnold, landmine, pike push-up); lateral, front and rear raises on dumbbells, cables and machines; face pulls, band pull-apart, upright row, rotator-cuff rotations, Y-raise; every common curl; reverse curl, wrist curls, plate pinch |
| `legs.json` | quads, hamstrings, glutes, calves, hips | 50–55 | Squats (back, front, goblet, Smith, hack, bodyweight, pistol), leg press and single-leg press, lunges, split squats, step-up, wall sit, sissy squat; deadlift, trap-bar deadlift, Romanian deadlifts, single-leg RDL, good morning, kettlebell swing, cable pull-through, Nordic curl, leg curls; hip thrusts, bridges, kickbacks, abduction and adduction work, banded walks; calf raises of every kind, tibialis raise |
| `core.json` | core, full-body | 40–45 | Crunch and leg-raise families (floor, hanging, captain's chair, machine, decline); planks and side planks, rollouts, body saw, stir-the-pot; woodchops, landmine rotation, Pallof variants; dead bug and bird-dog family; side bend; farmer's and other carries (full-body); toes-to-bar, dragon flag, V-up, mountain climber |
