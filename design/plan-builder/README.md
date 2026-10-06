# SpotMe plan builder

Turns onboarding answers into a weekly plan in the shape of `plan.json`, by fixed rules, from the exercise
database. Status: design and reference, waiting for Yeshu's review. Not in the app yet.

| File | What it is |
|---|---|
| `RULES.md` | The questions and every rule, step by step. The contract. |
| `build_plan.py` | The reference: `python3 build_plan.py --all` builds every persona and prints the plans |
| `check_plan.py` | The planner's independent check (shares no code with the builder): equipment, injuries, time, sets, schema |
| `personas/*.json` | Six sets of answers the rules are tested on |
| `plans/*.json` | What the reference builds for them |

All six plans pass the check with no errors. Known gaps: someone training with only bands and bodyweight who
is new gets a pike push-up as the overhead press (the database has no easier band press yet), and two 30-minute
sessions a week leave chest at two sets.

To change a rule: edit `RULES.md`, then `build_plan.py`, rebuild, run the check, and read the plans as a coach.
