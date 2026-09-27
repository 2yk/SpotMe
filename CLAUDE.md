# RepCoach · instructions for Claude Code

You are building a personal watchOS + iOS strength-training logger for one person (the repo owner). Read `docs/SPEC.md` fully before writing code. It is the product definition; this file is how to work.

## What already exists

- `Packages/RepCoachCore`: a Swift package with
  - `Plan.swift`: Codable plan models + `Plan.bundled()` loading `Resources/plan.json` (the real 7-day plan).
  - `ProgressionEngine.swift`: pure functions for weight/rep suggestions. **Treat its behaviour as fixed.**
  - Tests pinning both. The expected numbers come from `docs/engine_reference.py`.
- `project.yml`: XcodeGen spec for an iOS app with an embedded single-target watchOS app.
- `Apps/iOS`, `Apps/Watch`: placeholder SwiftUI apps that list the plan.

None of this has been compiled yet (it was written on a machine without Xcode). Expect small compile fixes in milestone 0; fix them without changing engine behaviour.

## Stack and rules

- Swift, SwiftUI, SwiftData, HealthKit, WatchConnectivity, Swift Charts. iOS 18 / watchOS 11 minimum.
- **No third-party dependencies.**
- All progression maths goes through `ProgressionEngine`. UI code never re-implements rounding or rules.
- To change a progression rule: edit `docs/engine_reference.py` first, run it, update the test expectations to its output, then change the Swift. Never edit expected values to make a failing test pass.
- `plan.json` is the source of the plan. Don't hand-edit exercise content; user overrides live in SwiftData (`ExerciseSettings`).
- Watch UI: large type, one primary action per screen, Digital Crown for number entry, haptics on logging and rest end. Test on the 42 mm and 46 mm simulators.
- Keep files small and focused; views in `Apps/<platform>/Views`, shared state in `Apps/<platform>/Model`.

## Commands

```bash
brew install xcodegen          # once
cd Packages/RepCoachCore && swift test && cd ../..
xcodegen generate
xcodebuild -project RepCoach.xcodeproj -scheme RepCoachWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build
xcodebuild -project RepCoach.xcodeproj -scheme RepCoach \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Use whatever simulator names `xcrun simctl list devices available` shows. If XcodeGen can't produce a working single-target watch app embedded in the iOS app, create the project in Xcode instead (File › New › Project › watchOS › App, "Watch App with New Companion iOS App"), add the local package, move the sources in, and delete `project.yml`. Say which route you took.

## Milestones (finish, build and test each before starting the next)

**0 · Build green.** `swift test` passes; both schemes build for simulators. Commit.

**1 · Persistence + history.** SwiftData models from the spec, shared between targets in the package or duplicated per target, your call. A `HistoryStore` that returns, per exerciseId, previous non-deload sessions newest first as `[[LoggedSet]]` for `ProgressionEngine.firstTarget`. Unit-test it with an in-memory container.

**2 · Watch logging flow (the core of the app).** Today list with up-next on top and finished items at the bottom; set screen with Crown entry; rest timer with next-set target and reason; timed sets; checklist items; supersets; AMRAP → volume reps; HKWorkoutSession start/end with heart rate. Verify acceptance checks 1–6 in the simulator (HealthKit parts on device).

**3 · iPhone app + sync.** Today, History with charts, Plan editor, Settings (program start date, deload toggle). WatchConnectivity as specified. Acceptance checks 7–9 on real devices.

**4 · Polish.** Body log with the waist rule, an "Up next" watch complication, CSV export of all sets from the iPhone.

## Installing on the owner's devices

Paid developer account. Set `DEVELOPMENT_TEAM` in `project.yml` (or Signing & Capabilities), enable HealthKit on both targets, run the iOS scheme on the iPhone with the watch paired. The watch app installs through the iPhone. Tell the owner if any capability needs a manual click in Xcode.

## When you finish a milestone

Report: what was built, how to try it on the watch (exact taps), test results, and anything that needs the owner's action. Keep it short.
