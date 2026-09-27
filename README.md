# RepCoach

Your v11 plan on the Apple Watch: log weight and reps per set, get the next set's weight suggested, and see when to go heavier.

## Start (on your Mac Studio)

1. Unzip this folder somewhere, e.g. `~/Projects/RepCoach`.
2. `cd ~/Projects/RepCoach && git init && git add . && git commit -m "RepCoach starter"`
3. Run `claude` in that folder and say:

   > Read CLAUDE.md and docs/SPEC.md, then do milestone 0. Stop and report when it builds and the tests pass.

4. Continue milestone by milestone ("Do milestone 1", …). Test each on the simulator or your watch before moving on.

## What's inside

| Path | What it is |
|---|---|
| `CLAUDE.md` | Working instructions for Claude Code: stack, rules, milestones |
| `docs/SPEC.md` | What the app does, screen by screen, plus acceptance checks |
| `docs/engine_reference.py` | Reference for the progression rules; run with `python3` |
| `Packages/RepCoachCore` | Plan data, progression engine and their tests |
| `project.yml` | Xcode project definition (XcodeGen) |
| `Apps/` | Placeholder iOS and watch apps |
