# SpotMe exercise database

236 strength exercises for swaps and additions in the app. Each one has the equipment it needs, the body
part and muscles, how hard it is on eight injury areas, and the exercises that can replace it.

Status: built and checked 6 Oct 2026, waiting for Yeshu's review. Not in the app yet.

| File | What it is |
|---|---|
| `exercises.json` | The database (built by `validate.py --merge`; never edited by hand) |
| `SCHEMA.md` | The rules: fields, word lists, the injury scale and its anchors |
| `parts/*.json` | The five source files the database is merged from. Edit these. |
| `validate.py` | Checks the rules, the two-way links and the match with `plan.json` |

## What is in it

| Body part | Exercises | | Body part | Exercises |
|---|---|---|---|---|
| Core | 42 | | Glutes | 11 |
| Back | 39 | | Hamstrings | 11 |
| Shoulders | 29 | | Hips | 8 |
| Chest | 26 | | Calves | 6 |
| Quads | 19 | | Neck | 6 |
| Triceps | 17 | | Forearms | 5 |
| Biceps | 14 | | Full body | 3 |

- All 52 exercise ids in `plan.json` are covered by 50 entries (`planIds` maps them; the two pull-up sets
  share `pull-ups`, the two overhead cable extensions share `overhead-cable-extension`).
- Every exercise has 3 to 8 alternatives, 4.7 on average, and every link goes both ways.

## How the app can use it

- Find an exercise from the plan: the entry whose `planIds` holds the plan's `exerciseId`.
- Swap options: its `alternatives`, in order, each with a short `why` to show.
- Filter by gear: an exercise is available when everything in `equipment` is.
- Filter by injury: `injury` rates each area 0 to 3. `avoidIf` lists the areas rated 3, `careIf` the areas
  rated 2, with the reason in `injuryNotes`.
- Logging: `logAs`, `perSide`, `loadable`, `loadType` and `incrementKg` match what `plan.json` uses, so a
  swapped-in exercise can be logged and progressed the same way. `loadType` says how the weight is counted,
  so a weight is never carried from one exercise to another.

## Good to know

- The injury ratings are a trainer's general judgement for standard form, not medical advice.
- The plan got no free pass. With a lower-back problem the database says avoid for three exercises in the
  current plan (Cable Crunch, Russian Twist, Ab Wheel Rollout) and take care for twelve more. Each has a
  gentler swap listed.
- 71 validator warnings remain. All say "no alternative is easier on this area", for exercises where none
  exists (every curl loads the elbow, every calf raise the ankle).
- Left out for lack of common equipment: 4-way neck machine, wrist roller, belt squat, GHD.
